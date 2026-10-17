import uuid
from datetime import datetime, timezone, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import select, or_, and_, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import decode_token
from app.modules.sessions.models import MentorshipRequest, CallSession, ThreadMessage, DeviceToken
from app.modules.sessions.schemas import (
    RequestCreate,
    RequestResponse,
    DeclineRequest,
    SlotItem,
    MessageCreate,
    MessageResponse,
    SessionResponse,
    DeviceTokenCreate,
    DeviceTokenResponse
)
from app.modules.sessions.service import SessionsService

router = APIRouter(tags=["sessions"])

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise AppError(code="unauthorized", message="Authentication required", status_code=status.HTTP_401_UNAUTHORIZED)
    token = authorization.split(" ")[1]
    payload = decode_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise AppError(code="unauthorized", message="Invalid authentication token", status_code=status.HTTP_401_UNAUTHORIZED)
    return user_id

@router.post("/requests", response_model=RequestResponse, summary="Submit mentorship request")
async def create_request(
    data: RequestCreate,
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key"),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    req = await SessionsService.create_request(
        session=db,
        student_id=uuid.UUID(user_id),
        giver_id=uuid.UUID(data.giver_id),
        kind=data.kind,
        intent_text=data.intent_text,
        slot_start=data.slot_start,
        idempotency_key=idempotency_key
    )
    return RequestResponse(
        id=str(req.id),
        student_id=str(req.student_id),
        giver_id=str(req.giver_id),
        kind=req.kind,
        intent_text=req.intent_text,
        slot_start=req.slot_start,
        status=req.status,
        priority=req.priority,
        plan_name=req.plan_name,
        is_cross_college=req.is_cross_college,
        created_at=req.created_at
    )

@router.get("/requests", response_model=List[RequestResponse], summary="List mentorship requests")
async def list_requests(
    box: str = Query("incoming", description="incoming or outgoing"),
    status: Optional[str] = Query(None),
    cursor: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    query = select(MentorshipRequest)
    if box == "incoming":
        query = query.where(MentorshipRequest.giver_id == uid)
    else:
        query = query.where(MentorshipRequest.student_id == uid)

    if status:
        query = query.where(MentorshipRequest.status == status)

    # Order by priority DESC, created_at DESC
    query = query.order_by(desc(MentorshipRequest.priority), desc(MentorshipRequest.created_at)).limit(50)
    res = await db.execute(query)
    items = res.scalars().all()
    return [
        RequestResponse(
            id=str(r.id),
            student_id=str(r.student_id),
            giver_id=str(r.giver_id),
            kind=r.kind,
            intent_text=r.intent_text,
            slot_start=r.slot_start,
            status=r.status,
            priority=r.priority,
            plan_name=r.plan_name,
            is_cross_college=r.is_cross_college,
            created_at=r.created_at
        ) for r in items
    ]

@router.get("/requests/{id}", response_model=RequestResponse, summary="Get request details")
async def get_request(
    id: str,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    stmt = select(MentorshipRequest).where(MentorshipRequest.id == uuid.UUID(id))
    req = (await db.execute(stmt)).scalar_one_or_none()
    if not req:
        raise AppError(code="request_not_found", message="Request not found", status_code=404)
    return RequestResponse(
        id=str(req.id),
        student_id=str(req.student_id),
        giver_id=str(req.giver_id),
        kind=req.kind,
        intent_text=req.intent_text,
        slot_start=req.slot_start,
        status=req.status,
        priority=req.priority,
        plan_name=req.plan_name,
        is_cross_college=req.is_cross_college,
        created_at=req.created_at
    )

@router.post("/requests/{id}/accept", response_model=SessionResponse, summary="Accept mentorship request")
async def accept_request(
    id: str,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    session = await SessionsService.accept_request(db, uuid.UUID(id), uuid.UUID(user_id))
    return SessionResponse(
        id=str(session.id),
        request_id=str(session.request_id),
        student_id=str(session.student_id),
        giver_id=str(session.giver_id),
        scheduled_at=session.scheduled_at,
        duration_minutes=session.duration_minutes,
        room_url=session.room_url,
        status=session.status,
        student_joined_at=session.student_joined_at,
        giver_joined_at=session.giver_joined_at,
        no_show_party=session.no_show_party
    )

@router.post("/requests/{id}/decline", response_model=RequestResponse, summary="Decline mentorship request")
async def decline_request(
    id: str,
    data: DeclineRequest,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    req = await SessionsService.decline_request(db, uuid.UUID(id), uuid.UUID(user_id), data.reason)
    return RequestResponse(
        id=str(req.id),
        student_id=str(req.student_id),
        giver_id=str(req.giver_id),
        kind=req.kind,
        intent_text=req.intent_text,
        slot_start=req.slot_start,
        status=req.status,
        priority=req.priority,
        plan_name=req.plan_name,
        is_cross_college=req.is_cross_college,
        created_at=req.created_at
    )

@router.get("/givers/{id}/slots", response_model=List[SlotItem], summary="Get open booking slots for a giver")
async def get_giver_slots(
    id: str,
    from_date: Optional[str] = Query(None, alias="from"),
    to_date: Optional[str] = Query(None, alias="to"),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    now = datetime.now(timezone.utc)
    slots = []
    # Return sample 20-min slots for upcoming windows
    for i in range(1, 4):
        st = now.replace(minute=0, second=0, microsecond=0) + timedelta(hours=i*2)
        slots.append(SlotItem(slot_start=st, slot_end=st + timedelta(minutes=20), available=True))
    return slots

@router.post("/requests/{id}/messages", response_model=MessageResponse, summary="Send message in thread")
async def send_message(
    id: str,
    data: MessageCreate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    msg = await SessionsService.send_message(db, uuid.UUID(id), uuid.UUID(user_id), data.content)
    return MessageResponse(
        id=str(msg.id),
        request_id=str(msg.request_id),
        sender_id=str(msg.sender_id),
        content=msg.content,
        safety_action=msg.safety_action,
        flags=msg.flags,
        created_at=msg.created_at
    )

@router.get("/requests/{id}/messages", response_model=List[MessageResponse], summary="Get thread messages")
async def get_messages(
    id: str,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    stmt = select(ThreadMessage).where(ThreadMessage.request_id == uuid.UUID(id)).order_by(ThreadMessage.created_at)
    res = await db.execute(stmt)
    items = res.scalars().all()
    return [
        MessageResponse(
            id=str(m.id),
            request_id=str(m.request_id),
            sender_id=str(m.sender_id),
            content=m.content,
            safety_action=m.safety_action,
            flags=m.flags,
            created_at=m.created_at
        ) for m in items
    ]

@router.post("/sessions/{id}/join", response_model=SessionResponse, summary="Join session call")
async def join_session(
    id: str,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    session = await SessionsService.join_session(db, uuid.UUID(id), uuid.UUID(user_id))
    return SessionResponse(
        id=str(session.id),
        request_id=str(session.request_id),
        student_id=str(session.student_id),
        giver_id=str(session.giver_id),
        scheduled_at=session.scheduled_at,
        duration_minutes=session.duration_minutes,
        room_url=session.room_url,
        status=session.status,
        student_joined_at=session.student_joined_at,
        giver_joined_at=session.giver_joined_at,
        no_show_party=session.no_show_party
    )

@router.post("/sessions/{id}/leave", response_model=SessionResponse, summary="Leave session call")
async def leave_session(
    id: str,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    session = await SessionsService.leave_session(db, uuid.UUID(id), uuid.UUID(user_id))
    return SessionResponse(
        id=str(session.id),
        request_id=str(session.request_id),
        student_id=str(session.student_id),
        giver_id=str(session.giver_id),
        scheduled_at=session.scheduled_at,
        duration_minutes=session.duration_minutes,
        room_url=session.room_url,
        status=session.status,
        student_joined_at=session.student_joined_at,
        giver_joined_at=session.giver_joined_at,
        no_show_party=session.no_show_party
    )

@router.get("/sessions/{id}", response_model=SessionResponse, summary="Get session details")
async def get_session(
    id: str,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    stmt = select(CallSession).where(CallSession.id == uuid.UUID(id))
    s = (await db.execute(stmt)).scalar_one_or_none()
    if not s:
        raise AppError(code="session_not_found", message="Session not found", status_code=404)
    return SessionResponse(
        id=str(s.id),
        request_id=str(s.request_id),
        student_id=str(s.student_id),
        giver_id=str(s.giver_id),
        scheduled_at=s.scheduled_at,
        duration_minutes=s.duration_minutes,
        room_url=s.room_url,
        status=s.status,
        student_joined_at=s.student_joined_at,
        giver_joined_at=s.giver_joined_at,
        no_show_party=s.no_show_party
    )

@router.get("/me/sessions", response_model=List[SessionResponse], summary="List my sessions")
async def list_my_sessions(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    stmt = select(CallSession).where(or_(CallSession.student_id == uid, CallSession.giver_id == uid)).order_by(desc(CallSession.scheduled_at))
    items = (await db.execute(stmt)).scalars().all()
    return [
        SessionResponse(
            id=str(s.id),
            request_id=str(s.request_id),
            student_id=str(s.student_id),
            giver_id=str(s.giver_id),
            scheduled_at=s.scheduled_at,
            duration_minutes=s.duration_minutes,
            room_url=s.room_url,
            status=s.status,
            student_joined_at=s.student_joined_at,
            giver_joined_at=s.giver_joined_at,
            no_show_party=s.no_show_party
        ) for s in items
    ]

@router.post("/notifications/devices", response_model=DeviceTokenResponse, summary="Register device for push notifications")
async def register_device(
    data: DeviceTokenCreate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    stmt = select(DeviceToken).where(DeviceToken.fcm_token == data.fcm_token)
    dt = (await db.execute(stmt)).scalar_one_or_none()
    if not dt:
        dt = DeviceToken(
            id=uuid.uuid4(),
            user_id=uid,
            fcm_token=data.fcm_token,
            platform=data.platform
        )
        db.add(dt)
    else:
        dt.user_id = uid
        dt.platform = data.platform
    await db.commit()
    return DeviceTokenResponse(status="registered")
