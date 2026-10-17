import uuid
from typing import Protocol, runtime_checkable, Any
from app.core.errors import PortNotReady


@runtime_checkable
class SafetyPort(Protocol):
    async def scan_text(self, text: str, sender_id: uuid.UUID, context: dict[str, Any] | None = None) -> dict[str, Any]:
        """Returns {'flags': list[str], 'action': 'allow' | 'warn' | 'block' | 'review'}"""
        ...


@runtime_checkable
class TrustPort(Protocol):
    async def get_level(self, user_id: uuid.UUID) -> str:
        """Returns trust level: 'new' | 'verified' | 'established' | 'restricted'"""
        ...

    async def can(self, user_id: uuid.UUID, action: str) -> dict[str, Any]:
        """Returns {'allowed': bool, 'reason': str}"""
        ...


@runtime_checkable
class CreditsPort(Protocol):
    async def can_access(self, student_id: uuid.UUID, giver_id: uuid.UUID) -> dict[str, Any]:
        """Returns {'allowed': bool, 'reason': str, 'plan': str, 'cost': int}"""
        ...

    async def reserve(self, student_id: uuid.UUID, request_id: uuid.UUID, giver_id: uuid.UUID) -> None:
        ...

    async def release(self, request_id: uuid.UUID) -> None:
        ...

    async def refund(self, request_id: uuid.UUID, reason: str) -> None:
        ...


@runtime_checkable
class RatingsPort(Protocol):
    async def get_band(self, giver_id: uuid.UUID) -> dict[str, Any]:
        """Returns {'band': str, 'smoothed_avg': float, 'n': int, 'completion_rate': float}"""
        ...


@runtime_checkable
class PresencePort(Protocol):
    async def status(self, user_ids: list[uuid.UUID]) -> dict[str, Any]:
        """Returns mapping {user_id_str: {'online': bool, 'capacity_left': int}}"""
        ...


@runtime_checkable
class MatchingPort(Protocol):
    async def explain(self, student_id: uuid.UUID, giver_id: uuid.UUID) -> list[str]:
        """Returns why-lines list"""
        ...


# Fail-closed Default Stubs
class StubSafetyPort(SafetyPort):
    async def scan_text(self, text: str, sender_id: uuid.UUID, context: dict[str, Any] | None = None) -> dict[str, Any]:
        raise PortNotReady("SafetyPort")


class StubTrustPort(TrustPort):
    async def get_level(self, user_id: uuid.UUID) -> str:
        raise PortNotReady("TrustPort")

    async def can(self, user_id: uuid.UUID, action: str) -> dict[str, Any]:
        raise PortNotReady("TrustPort")


class StubCreditsPort(CreditsPort):
    async def can_access(self, student_id: uuid.UUID, giver_id: uuid.UUID) -> dict[str, Any]:
        raise PortNotReady("CreditsPort")

    async def reserve(self, student_id: uuid.UUID, request_id: uuid.UUID, giver_id: uuid.UUID) -> None:
        raise PortNotReady("CreditsPort")

    async def release(self, request_id: uuid.UUID) -> None:
        raise PortNotReady("CreditsPort")

    async def refund(self, request_id: uuid.UUID, reason: str) -> None:
        raise PortNotReady("CreditsPort")


class StubRatingsPort(RatingsPort):
    async def get_band(self, giver_id: uuid.UUID) -> dict[str, Any]:
        raise PortNotReady("RatingsPort")


class StubPresencePort(PresencePort):
    async def status(self, user_ids: list[uuid.UUID]) -> dict[str, Any]:
        raise PortNotReady("PresencePort")


class StubMatchingPort(MatchingPort):
    async def explain(self, student_id: uuid.UUID, giver_id: uuid.UUID) -> list[str]:
        raise PortNotReady("MatchingPort")


class PortRegistry:
    def __init__(self):
        self.safety: SafetyPort = StubSafetyPort()
        self.trust: TrustPort = StubTrustPort()
        self.credits: CreditsPort = StubCreditsPort()
        self.ratings: RatingsPort = StubRatingsPort()
        self.presence: PresencePort = StubPresencePort()
        self.matching: MatchingPort = StubMatchingPort()

    def register_safety(self, port: SafetyPort):
        self.safety = port

    def register_trust(self, port: TrustPort):
        self.trust = port

    def register_credits(self, port: CreditsPort):
        self.credits = port

    def register_ratings(self, port: RatingsPort):
        self.ratings = port

    def register_presence(self, port: PresencePort):
        self.presence = port

    def register_matching(self, port: MatchingPort):
        self.matching = port


port_registry = PortRegistry()
