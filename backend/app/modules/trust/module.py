"""
Module descriptor for 'trust'
Owner: M1
"""

from uuid import UUID
from sqlalchemy import select

from app.core.db import User, async_session_maker
from app.core.events import (
    BaseEventPayload,
    EventBus,
    ReportFiledPayload,
    TrustLevelChangedPayload,
    UserVerifiedPayload,
    event_bus,
)
from app.core.ports import PortRegistry
from app.modules.trust.router import router as ROUTER
from app.modules.trust.service import (
    SafetyServiceImpl,
    TrustFactors,
    TrustServiceImpl,
    compute_trust_level,
)


def register_ports(registry: PortRegistry):
    """Register synchronous ports implemented by trust."""
    registry.trust = TrustServiceImpl()
    registry.safety = SafetyServiceImpl()


async def _recompute_user_trust(user_id_str: str, reason: str = "Event recomputation"):
    """Internal helper to recompute trust level upon outbox events."""
    try:
        u_id = UUID(user_id_str)
        async with async_session_maker() as session:
            user_res = await session.execute(select(User).where(User.id == u_id))
            user = user_res.scalar_one_or_none()
            if not user or user.status == "deleted":
                return

            # Pure trust computation
            new_level = compute_trust_level(
                TrustFactors(
                    verification_level=user.verification_level,
                    is_admin_restricted=(user.status == "restricted"),
                )
            )

            if new_level != user.trust_level:
                old_level = user.trust_level
                user.trust_level = new_level
                await session.commit()

                await event_bus.publish(
                    session,
                    "trust.level_changed",
                    TrustLevelChangedPayload(
                        user_id=str(user.id),
                        old_level=old_level,
                        new_level=new_level,
                        reason=reason,
                    ),
                )
                await session.commit()
    except Exception:
        pass


async def handle_user_verified(payload: BaseEventPayload):
    if isinstance(payload, UserVerifiedPayload) or hasattr(payload, "user_id"):
        await _recompute_user_trust(payload.user_id, "user.verified event")


async def handle_report_filed(payload: BaseEventPayload):
    reported_user_id = getattr(payload, "reported_user_id", None)
    if reported_user_id:
        await _recompute_user_trust(reported_user_id, "report.filed event")


async def handle_session_event(payload: BaseEventPayload):
    student_id = getattr(payload, "student_id", None)
    giver_id = getattr(payload, "giver_id", None)
    if student_id:
        await _recompute_user_trust(student_id, "session event")
    if giver_id:
        await _recompute_user_trust(giver_id, "session event")


def register_events(bus: EventBus):
    """Register outbox event handlers for trust."""
    bus.subscribe("user.verified", handle_user_verified)
    bus.subscribe("report.filed", handle_report_filed)
    bus.subscribe("session.completed", handle_session_event)
    bus.subscribe("session.no_show", handle_session_event)
    bus.subscribe("dispute.resolved", handle_session_event)
    bus.subscribe("rating.submitted", handle_session_event)
