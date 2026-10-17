import uuid
from typing import Any, Callable, Coroutine
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.models_base import OutboxEvent

# Typed Event Payloads
class UserVerifiedEvent(BaseModel):
    user_id: uuid.UUID
    institution_id: uuid.UUID
    verified_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))

class TrustLevelChangedEvent(BaseModel):
    user_id: uuid.UUID
    old_level: str
    new_level: str
    reason: str

class ResumeParsedEvent(BaseModel):
    user_id: uuid.UUID
    skills: list[str]
    experience_years: float | None = None

class ProfileUpdatedEvent(BaseModel):
    user_id: uuid.UUID
    updated_fields: list[str]

class GiverProfileUpdatedEvent(BaseModel):
    giver_id: uuid.UUID
    domains: list[str]
    capacity_weekly: int

class RequestCreatedEvent(BaseModel):
    request_id: uuid.UUID
    student_id: uuid.UUID
    giver_id: uuid.UUID
    priority: int

class RequestAcceptedEvent(BaseModel):
    request_id: uuid.UUID
    giver_id: uuid.UUID
    student_id: uuid.UUID

class RequestDeclinedEvent(BaseModel):
    request_id: uuid.UUID
    reason: str | None = None

class SessionBookedEvent(BaseModel):
    session_id: uuid.UUID
    request_id: uuid.UUID
    slot_start: datetime

class SessionStartedEvent(BaseModel):
    session_id: uuid.UUID
    started_at: datetime

class SessionCompletedEvent(BaseModel):
    session_id: uuid.UUID
    duration_minutes: float

class SessionNoShowEvent(BaseModel):
    session_id: uuid.UUID
    no_show_party: str  # student | giver

class RatingSubmittedEvent(BaseModel):
    session_id: uuid.UUID
    giver_id: uuid.UUID
    student_id: uuid.UUID
    rating: int

class BandChangedEvent(BaseModel):
    giver_id: uuid.UUID
    old_band: str
    new_band: str
    smoothed_avg: float

class CreditsReservedEvent(BaseModel):
    request_id: uuid.UUID
    student_id: uuid.UUID
    giver_id: uuid.UUID
    amount: int

class CreditsReleasedEvent(BaseModel):
    request_id: uuid.UUID
    giver_id: uuid.UUID
    amount: int

class CreditsRefundedEvent(BaseModel):
    request_id: uuid.UUID
    student_id: uuid.UUID
    reason: str

class PaymentCapturedEvent(BaseModel):
    payment_id: str
    user_id: uuid.UUID
    amount_inr: int

class SubscriptionActivatedEvent(BaseModel):
    subscription_id: str
    user_id: uuid.UUID
    plan_tier: str

class SubscriptionCancelledEvent(BaseModel):
    subscription_id: str
    user_id: uuid.UUID

class ReportFiledEvent(BaseModel):
    report_id: uuid.UUID
    reporter_id: uuid.UUID
    offender_id: uuid.UUID
    category: str

class DisputeOpenedEvent(BaseModel):
    dispute_id: uuid.UUID
    session_id: uuid.UUID
    initiated_by: uuid.UUID
    reason: str

class DisputeResolvedEvent(BaseModel):
    dispute_id: uuid.UUID
    session_id: uuid.UUID
    outcome: str


class EventBus:
    def __init__(self):
        self._subscribers: dict[str, list[Callable[[dict[str, Any]], Coroutine[Any, Any, None]]]] = {}

    def subscribe(self, topic: str, handler: Callable[[dict[str, Any]], Coroutine[Any, Any, None]]):
        if topic not in self._subscribers:
            self._subscribers[topic] = []
        self._subscribers[topic].append(handler)

    async def publish(self, session: AsyncSession, topic: str, payload: BaseModel | dict[str, Any]) -> uuid.UUID:
        data = payload.model_dump(mode="json") if isinstance(payload, BaseModel) else payload
        event = OutboxEvent(
            topic=topic,
            payload=data,
            status="pending",
        )
        session.add(event)
        # Flush inside caller transaction so event gets an ID and is atomically persisted with state change
        await session.flush()
        return event.id

    async def dispatch_in_memory(self, topic: str, payload: dict[str, Any]):
        handlers = self._subscribers.get(topic, [])
        for handler in handlers:
            await handler(payload)


# Singleton event bus instance
event_bus = EventBus()
