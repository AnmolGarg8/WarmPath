import uuid
from typing import Any, Dict
from app.modules.ratings.router import router as ROUTER
from app.modules.ratings.service import RatingsService
from app.core.db import async_session_maker
from app.core.ports import RatingsPort

class ConcreteRatingsPort(RatingsPort):
    async def get_band(self, giver_id: str) -> Dict[str, Any]:
        async with async_session_maker() as session:
            profile = await RatingsService.get_or_create_profile(session, uuid.UUID(giver_id))
            return {
                "band": profile.current_band,
                "smoothed_avg": profile.smoothed_average,
                "n": profile.rated_sessions_count,
                "completion_rate": profile.completion_rate
            }

def register_events(bus):
    async def on_session_completed(payload: Any):
        giver_id = getattr(payload, "giver_id", None)
        if giver_id:
            async with async_session_maker() as session:
                profile = await RatingsService.get_or_create_profile(session, uuid.UUID(str(giver_id)))
                profile.completed_sessions_count += 1
                profile.total_booked_sessions_count += 1
                await session.commit()
                await RatingsService.recompute_giver_band(session, uuid.UUID(str(giver_id)))

    async def on_session_no_show(payload: Any):
        giver_id = getattr(payload, "giver_id", None)
        party = getattr(payload, "no_show_party", None)
        if giver_id and party == "giver":
            async with async_session_maker() as session:
                profile = await RatingsService.get_or_create_profile(session, uuid.UUID(str(giver_id)))
                profile.giver_no_show_count += 1
                profile.total_booked_sessions_count += 1
                await session.commit()
                await RatingsService.recompute_giver_band(session, uuid.UUID(str(giver_id)))

    bus.subscribe("session.completed", on_session_completed)
    bus.subscribe("session.no_show", on_session_no_show)

def register_ports(registry):
    registry.ratings = ConcreteRatingsPort()
