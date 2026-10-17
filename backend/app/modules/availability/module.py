from fastapi import APIRouter
from app.core.events import EventBus
from app.core.ports import PortRegistry
from app.modules.availability.router import router

ROUTER: APIRouter = router


def register_events(bus: EventBus) -> None:
    pass


def register_ports(registry: PortRegistry) -> None:
    pass
