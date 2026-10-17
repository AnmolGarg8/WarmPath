"""
Module descriptor for 'credits'.
Owner: M4
Registers CreditsPort implementation and outbox event handlers.
"""

from typing import Any, Dict
from app.core.db import async_session_maker
from app.core.events import (
    DisputeOpenedPayload,
    DisputeResolvedPayload,
    EventBus,
    SessionCompletedPayload,
    SessionNoShowPayload,
    SubscriptionActivatedPayload,
    SubscriptionCancelledPayload,
)
from app.core.ports import CreditsPort, PortRegistry
from app.modules.credits.router import router as ROUTER
from app.modules.credits.service import CreditsService


class CreditsPortImpl(CreditsPort):
    """Concrete implementation of CreditsPort Protocol."""

    async def can_access(self, student_id: str, giver_id: str) -> Dict[str, Any]:
        async with async_session_maker() as session:
            return await CreditsService.can_access(session, student_id, giver_id)

    async def reserve(self, student_id: str, request_id: str, giver_id: str) -> None:
        async with async_session_maker() as session, session.begin():
            await CreditsService.reserve(session, student_id, request_id, giver_id)

    async def release(self, request_id: str) -> None:
        async with async_session_maker() as session, session.begin():
            await CreditsService.release(session, request_id)

    async def refund(self, request_id: str, reason: str) -> None:
        async with async_session_maker() as session, session.begin():
            await CreditsService.refund(session, request_id, reason)


async def on_session_completed(payload: SessionCompletedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await CreditsService.handle_session_completed(
            session,
            session_id=payload.session_id,
            duration_minutes=payload.duration_minutes,
        )


async def on_dispute_opened(payload: DisputeOpenedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await CreditsService.handle_dispute_opened(session, session_id=payload.session_id)


async def on_dispute_resolved(payload: DisputeResolvedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await CreditsService.handle_dispute_resolved(
            session,
            session_id=getattr(payload, "session_id", payload.dispute_id),
            outcome=payload.outcome,
        )


async def on_session_no_show(payload: SessionNoShowPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await CreditsService.handle_session_no_show(
            session,
            session_id=payload.session_id,
            no_show_party=payload.no_show_party,
        )


async def on_subscription_activated(payload: SubscriptionActivatedPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await CreditsService.handle_subscription_activated(
            session,
            user_id=payload.user_id,
            plan_code=payload.plan,
        )


async def on_subscription_cancelled(payload: SubscriptionCancelledPayload) -> None:
    async with async_session_maker() as session, session.begin():
        await CreditsService.handle_subscription_cancelled(
            session,
            user_id=payload.user_id,
        )


def register_events(bus: EventBus) -> None:
    """Register outbox event handlers for credits."""
    bus.subscribe("session.completed", on_session_completed)
    bus.subscribe("dispute.opened", on_dispute_opened)
    bus.subscribe("dispute.resolved", on_dispute_resolved)
    bus.subscribe("session.no_show", on_session_no_show)
    bus.subscribe("subscription.activated", on_subscription_activated)
    bus.subscribe("subscription.cancelled", on_subscription_cancelled)


def register_ports(registry: PortRegistry) -> None:
    """Register synchronous ports implemented by credits."""
    registry.credits = CreditsPortImpl()
