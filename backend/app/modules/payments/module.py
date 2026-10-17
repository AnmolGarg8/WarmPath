"""
Module descriptor for 'payments'.
Owner: M4
"""

from app.core.db import async_session_maker
from app.core.events import CreditsReleasedPayload, EventBus
from app.core.ports import PortRegistry
from app.modules.payments.router import router as ROUTER
from app.modules.payments.service import PaymentsService


async def on_credits_released(payload: CreditsReleasedPayload) -> None:
    """When credits/earnings are released to giver, update the payments read model."""
    if payload.giver_id:
        async with async_session_maker() as session:
            async with session.begin():
                # 1 credit typically equivalent to standard share
                await PaymentsService.update_giver_earnings_cache(
                    session=session,
                    user_id=payload.giver_id,
                    amount_delta_inr=float(payload.credits * 179.40),
                )


def register_events(bus: EventBus) -> None:
    """Register outbox event handlers for payments."""
    bus.subscribe("credits.released", on_credits_released)


def register_ports(registry: PortRegistry) -> None:
    """Register synchronous ports implemented by payments if any."""
    pass
