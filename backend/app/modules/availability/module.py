import uuid
from typing import Any, Dict, List
from app.modules.availability.router import router as ROUTER
from app.modules.availability.service import AvailabilityService
from app.core.db import async_session_maker
from app.core.ports import PresencePort

class ConcretePresencePort(PresencePort):
    async def status(self, user_ids: List[str]) -> Dict[str, Any]:
        async with async_session_maker() as session:
            statuses = await AvailabilityService.get_presence_status(session, user_ids)
            result = {}
            for s in statuses:
                result[s["user_id"]] = {
                    "online": s["online_now"],
                    "capacity_left": s["capacity_left"]
                }
            return result

def register_events(bus):
    async def on_request_accepted(payload: Any):
        giver_id = getattr(payload, "giver_id", None)
        if giver_id:
            async with async_session_maker() as session:
                avail = await AvailabilityService.get_or_create_availability(session, uuid.UUID(str(giver_id)))
                await AvailabilityService.increment_capacity_usage(session, uuid.UUID(str(giver_id)), avail.timezone, 1)

    async def on_session_no_show(payload: Any):
        party = getattr(payload, "no_show_party", None)
        giver_id = getattr(payload, "giver_id", None)
        if party == "giver" and giver_id:
            async with async_session_maker() as session:
                await AvailabilityService.get_or_create_availability(session, uuid.UUID(str(giver_id)))
                # Giver no-show penalizes them (does not free up capacity or restores per domain rules)
                pass

    async def on_credits_refunded(payload: Any):
        giver_id = getattr(payload, "giver_id", None)
        if giver_id:
            async with async_session_maker() as session:
                avail = await AvailabilityService.get_or_create_availability(session, uuid.UUID(str(giver_id)))
                await AvailabilityService.decrement_capacity_usage(session, uuid.UUID(str(giver_id)), avail.timezone, 1)

    bus.subscribe("request.accepted", on_request_accepted)
    bus.subscribe("session.no_show", on_session_no_show)
    bus.subscribe("credits.refunded", on_credits_refunded)

def register_ports(registry):
    registry.presence = ConcretePresencePort()
