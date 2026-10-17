import uuid
import secrets
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy import select, update, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.errors import AppError
from app.core.ports import ports
from app.core.redis import get_redis
from app.core.events import event_bus, RequestCreatedPayload, RequestAcceptedPayload, RequestDeclinedPayload, SessionStartedPayload, SessionCompletedPayload, SessionNoShowPayload
from app.modules.sessions.models import MentorshipRequest, CallSession, ThreadMessage, DeviceToken

def mask_contact_info(text: str) -> str:
    # Mask email addresses
    email_pattern = r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+'
    masked = re.sub(email_pattern, "[email protected]", text)
    # Mask phone numbers (10 digits or with separators)
    phone_pattern = r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'
    masked = re.sub(phone_pattern, "[phone number redacted]", masked)
    return masked

class SessionsService:
    @staticmethod
    async def create_request(
        session: AsyncSession,
        student_id: uuid.UUID,
        giver_id: uuid.UUID,
        kind: str,
        intent_text: str,
        slot_start: Optional[datetime],
        idempotency_key: Optional[str] = None
    ) -> MentorshipRequest:
        # Check idempotency
        if idempotency_key:
            stmt = select(MentorshipRequest).where(MentorshipRequest.idempotency_key == idempotency_key)
            existing = (await session.execute(stmt)).scalar_one_or_none()
            if existing:
                return existing

        s_str, g_str = str(student_id), str(giver_id)

        # 1. Check student verification and rate limit / trust
        trust_can = await ports.trust.can(s_str, "send_request")
        if not trust_can.get("allowed"):
            raise AppError(code="trust_denied", message=trust_can.get("reason", "Student cannot send requests"), status_code=403)

        # 2. Check blocks
        is_blocked = await ports.trust.is_blocked(s_str, g_str)
        if is_blocked:
            raise AppError(code="communication_blocked", message="Communication between parties is blocked", status_code=403)

        # 3. Check giver capacity and verification
        presence_map = await ports.presence.status([g_str])
        giver_presence = presence_map.get(g_str, {})
        capacity_left = giver_presence.get("capacity_left", 0)
        if capacity_left <= 0:
            raise AppError(code="giver_at_capacity", message="Giver has no remaining weekly session capacity", status_code=400)

        # 4. Check CreditsPort access & plan rules
        access = await ports.credits.can_access(s_str, g_str)
        if not access.get("allowed"):
            raise AppError(code="plan_access_denied", message=access.get("reason", "Cannot access this giver with current plan"), status_code=403)

        plan = access.get("plan", "Campus")
        cost = access.get("cost", 0)
        is_cross_college = cost > 0

        # Plan priority mapping
        priority_map = {"Premium": 3, "High": 2, "Standard": 1, "Campus": 1}
        priority = priority_map.get(plan, 1)

        # Booking horizon checks
        now = datetime.now(timezone.utc)
        if kind == "instant":
            if not giver_presence.get("online"):
                raise AppError(code="giver_not_online", message="Giver is not currently online for instant connect", status_code=400)
            slot_start = now
        elif kind == "booked":
            if not slot_start:
                raise AppError(code="slot_required", message="slot_start is required for booked sessions", status_code=400)
            
            # Check horizon
            horizon_days = 3
            if plan == "High":
                horizon_days = 14
            elif plan == "Premium":
                horizon_days = 30
            
            if slot_start < now or slot_start > now + timedelta(days=horizon_days):
                raise AppError(code="outside_booking_horizon", message=f"Booking date exceeds the {horizon_days}-day horizon for your plan", status_code=400)

            # Check that giver doesn't already have an accepted session at slot_start
            slot_stmt = select(CallSession).where(
                CallSession.giver_id == giver_id,
                CallSession.scheduled_at == slot_start,
                CallSession.status.in_(["scheduled", "in_progress"])
            )
            conflict = (await session.execute(slot_stmt)).scalar_one_or_none()
            if conflict:
                raise AppError(code="slot_already_booked", message="This slot is already booked for the giver", status_code=409)

        # 5. Scan intent_text with SafetyPort
        scan = await ports.safety.scan_text(intent_text, s_str, context="request_intent")
        action = scan.get("action", "allow")
        if action == "block":
            raise AppError(code="intent_blocked", message="Intent text flagged by safety filters", status_code=400)

        # 6. Reserve credit if cost > 0
        req_id = uuid.uuid4()
        if cost > 0:
            await ports.credits.reserve(s_str, str(req_id), g_str)

        req = MentorshipRequest(
            id=req_id,
            student_id=student_id,
            giver_id=giver_id,
            kind=kind,
            intent_text=mask_contact_info(intent_text),
            slot_start=slot_start,
            status="pending",
            priority=priority,
            plan_name=plan,
            is_cross_college=is_cross_college,
            idempotency_key=idempotency_key
        )
        session.add(req)
        await session.flush()

        # Publish event
        await event_bus.publish(
            session,
            "request.created",
            RequestCreatedPayload(
                request_id=str(req.id),
                student_id=s_str,
                giver_id=g_str,
                is_cross_college=is_cross_college
            )
        )
        await session.commit()
        await session.refresh(req)

        # Notify giver via Redis realtime
        await SessionsService.notify_user(g_str, {
            "type": "new_request",
            "request_id": str(req.id),
            "student_id": s_str,
            "kind": kind
        })

        return req

    @staticmethod
    async def accept_request(session: AsyncSession, request_id: uuid.UUID, giver_id: uuid.UUID) -> CallSession:
        # Row lock mentorship_requests
        stmt = select(MentorshipRequest).where(
            MentorshipRequest.id == request_id,
            MentorshipRequest.giver_id == giver_id
        ).with_for_update()
        result = await session.execute(stmt)
        req = result.scalar_one_or_none()

        if not req:
            raise AppError(code="request_not_found", message="Request not found", status_code=404)
        if req.status != "pending":
            raise AppError(code="invalid_request_state", message=f"Request is already {req.status}", status_code=400)

        # Check capacity
        presence_map = await ports.presence.status([str(giver_id)])
        giver_presence = presence_map.get(str(giver_id), {})
        if giver_presence.get("capacity_left", 0) <= 0:
            raise AppError(code="giver_at_capacity", message="Capacity limit reached", status_code=400)

        now = datetime.now(timezone.utc)
        scheduled_at = now if req.kind == "instant" else (req.slot_start or now)

        # Generate unique Jitsi room URL
        random_room = f"wp-{secrets.token_urlsafe(16)}"
        room_url = f"{settings.JITSI_BASE_URL.rstrip('/')}/{random_room}"

        call_session = CallSession(
            id=uuid.uuid4(),
            request_id=req.id,
            student_id=req.student_id,
            giver_id=req.giver_id,
            scheduled_at=scheduled_at,
            duration_minutes=20,
            room_url=room_url,
            status="scheduled"
        )
        session.add(call_session)
        req.status = "accepted"
        await session.flush()

        await event_bus.publish(
            session,
            "request.accepted",
            RequestAcceptedPayload(
                request_id=str(req.id),
                giver_id=str(req.giver_id),
                slot_time=scheduled_at
            )
        )
        await session.commit()
        await session.refresh(call_session)

        # Realtime notify student
        await SessionsService.notify_user(str(req.student_id), {
            "type": "request_accepted",
            "request_id": str(req.id),
            "session_id": str(call_session.id),
            "room_url": room_url
        })

        return call_session

    @staticmethod
    async def decline_request(session: AsyncSession, request_id: uuid.UUID, giver_id: uuid.UUID, reason: Optional[str] = None) -> MentorshipRequest:
        stmt = select(MentorshipRequest).where(
            MentorshipRequest.id == request_id,
            MentorshipRequest.giver_id == giver_id
        ).with_for_update()
        req = (await session.execute(stmt)).scalar_one_or_none()
        if not req:
            raise AppError(code="request_not_found", message="Request not found", status_code=404)
        if req.status != "pending":
            raise AppError(code="invalid_request_state", message=f"Request is already {req.status}", status_code=400)

        req.status = "declined"
        req.decline_reason = reason

        # Release credit
        await ports.credits.release(str(req.id))

        await event_bus.publish(
            session,
            "request.declined",
            RequestDeclinedPayload(
                request_id=str(req.id),
                giver_id=str(req.giver_id),
                reason=reason
            )
        )
        await session.commit()
        await session.refresh(req)

        await SessionsService.notify_user(str(req.student_id), {
            "type": "request_declined",
            "request_id": str(req.id),
            "reason": reason
        })
        return req

    @staticmethod
    async def send_message(session: AsyncSession, request_id: uuid.UUID, sender_id: uuid.UUID, content: str) -> ThreadMessage:
        stmt = select(MentorshipRequest).where(MentorshipRequest.id == request_id)
        req = (await session.execute(stmt)).scalar_one_or_none()
        if not req:
            raise AppError(code="request_not_found", message="Request not found", status_code=404)

        s_id, g_id = req.student_id, req.giver_id
        if sender_id not in (s_id, g_id):
            raise AppError(code="not_a_participant", message="You are not a participant in this request", status_code=403)

        # Scan text with SafetyPort
        scan = await ports.safety.scan_text(content, str(sender_id), context="message")
        action = scan.get("action", "allow")
        flags = scan.get("flags", [])

        if action == "block":
            raise AppError(code="message_blocked", message="Message blocked by trust and safety filters", status_code=400)

        masked_content = mask_contact_info(content)
        msg = ThreadMessage(
            id=uuid.uuid4(),
            request_id=request_id,
            sender_id=sender_id,
            content=masked_content,
            safety_action=action,
            flags=flags
        )
        session.add(msg)
        await session.commit()
        await session.refresh(msg)

        recipient_id = str(g_id) if sender_id == s_id else str(s_id)
        await SessionsService.notify_user(recipient_id, {
            "type": "new_message",
            "request_id": str(request_id),
            "sender_id": str(sender_id),
            "content": masked_content
        })

        return msg

    @staticmethod
    async def join_session(session: AsyncSession, session_id: uuid.UUID, user_id: uuid.UUID) -> CallSession:
        stmt = select(CallSession).where(CallSession.id == session_id).with_for_update()
        call = (await session.execute(stmt)).scalar_one_or_none()
        if not call:
            raise AppError(code="session_not_found", message="Session not found", status_code=404)

        now = datetime.now(timezone.utc)
        if user_id == call.student_id:
            if not call.student_joined_at:
                call.student_joined_at = now
        elif user_id == call.giver_id:
            if not call.giver_joined_at:
                call.giver_joined_at = now
        else:
            raise AppError(code="unauthorized", message="User not in this session", status_code=403)

        if call.status == "scheduled":
            call.status = "in_progress"

        await session.commit()
        await session.refresh(call)
        return call

    @staticmethod
    async def leave_session(session: AsyncSession, session_id: uuid.UUID, user_id: uuid.UUID) -> CallSession:
        stmt = select(CallSession).where(CallSession.id == session_id).with_for_update()
        call = (await session.execute(stmt)).scalar_one_or_none()
        if not call:
            raise AppError(code="session_not_found", message="Session not found", status_code=404)

        now = datetime.now(timezone.utc)
        if user_id == call.student_id:
            call.student_left_at = now
        elif user_id == call.giver_id:
            call.giver_left_at = now

        # Evaluate completion: both sides joined and overlap >= 5 minutes
        if call.student_joined_at and call.giver_joined_at:
            s_join = call.student_joined_at
            g_join = call.giver_joined_at
            s_leave = call.student_left_at or now
            g_leave = call.giver_left_at or now

            overlap_start = max(s_join, g_join)
            overlap_end = min(s_leave, g_leave)
            if overlap_end > overlap_start:
                overlap_mins = (overlap_end - overlap_start).total_seconds() / 60.0
                if overlap_mins >= 5.0:
                    call.status = "completed"
                    await event_bus.publish(
                        session,
                        "session.completed",
                        SessionCompletedPayload(
                            session_id=str(call.id),
                            duration_minutes=overlap_mins
                        )
                    )

        await session.commit()
        await session.refresh(call)
        return call

    @staticmethod
    async def notify_user(user_id: str, data: Dict[str, Any]):
        try:
            r = await get_redis()
            chan = f"realtime:inbox:{user_id}"
            import json
            await r.publish(chan, json.dumps(data))
        except Exception:
            pass
