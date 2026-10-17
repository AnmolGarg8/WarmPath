"""
backend/app/core/events.py - Transactional Outbox Event Bus & Typed Event Payloads.
Topics defined in PROJECT_CONTEXT Section 6.
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Callable, Coroutine, Dict, List, Optional
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import OutboxEvent

# --- Typed Event Payloads ---

class BaseEventPayload(BaseModel):
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class UserVerifiedPayload(BaseEventPayload):
    user_id: str
    institution_id: int
    role: str


class TrustLevelChangedPayload(BaseEventPayload):
    user_id: str
    old_level: str
    new_level: str
    reason: Optional[str] = None


class ResumeParsedPayload(BaseEventPayload):
    user_id: str
    skills_count: int
    projects_count: int


class ProfileUpdatedPayload(BaseEventPayload):
    user_id: str
    updated_fields: List[str]


class GiverProfileUpdatedPayload(BaseEventPayload):
    giver_id: str
    weekly_capacity: int
    topics: List[str]


class RequestCreatedPayload(BaseEventPayload):
    request_id: str
    student_id: str
    giver_id: str
    is_cross_college: bool


class RequestAcceptedPayload(BaseEventPayload):
    request_id: str
    giver_id: str
    slot_time: Optional[datetime] = None


class RequestDeclinedPayload(BaseEventPayload):
    request_id: str
    giver_id: str
    reason: Optional[str] = None


class SessionBookedPayload(BaseEventPayload):
    session_id: str
    request_id: str
    student_id: str
    giver_id: str
    scheduled_at: datetime


class SessionStartedPayload(BaseEventPayload):
    session_id: str
    room_id: str


class SessionCompletedPayload(BaseEventPayload):
    session_id: str
    duration_minutes: float


class SessionNoShowPayload(BaseEventPayload):
    session_id: str
    no_show_party: str  # "student" or "giver"


class RatingSubmittedPayload(BaseEventPayload):
    session_id: str
    giver_id: str
    student_id: str
    rating: int


class BandChangedPayload(BaseEventPayload):
    giver_id: str
    old_band: str
    new_band: str
    smoothed_average: float


class CreditsReservedPayload(BaseEventPayload):
    request_id: str
    student_id: str
    credits: int


class CreditsReleasedPayload(BaseEventPayload):
    request_id: str
    giver_id: str
    credits: int


class CreditsRefundedPayload(BaseEventPayload):
    request_id: str
    student_id: str
    reason: str


class PaymentCapturedPayload(BaseEventPayload):
    payment_id: str
    user_id: str
    amount_inr: int
    credits_issued: int


class SubscriptionActivatedPayload(BaseEventPayload):
    subscription_id: str
    user_id: str
    plan: str


class SubscriptionCancelledPayload(BaseEventPayload):
    subscription_id: str
    user_id: str


class ReportFiledPayload(BaseEventPayload):
    report_id: str
    reporter_id: str
    reported_user_id: str
    reason: str


class DisputeOpenedPayload(BaseEventPayload):
    dispute_id: str
    session_id: str
    opened_by_user_id: str
    reason: str


class DisputeResolvedPayload(BaseEventPayload):
    dispute_id: str
    outcome: str
    resolved_by: str


# --- Event Bus & Outbox Publisher ---

class EventBus:
    def __init__(self):
        self._subscribers: Dict[str, List[Callable[[BaseEventPayload], Coroutine[Any, Any, None]]]] = {}

    def subscribe(self, topic: str, handler: Callable[[BaseEventPayload], Coroutine[Any, Any, None]]):
        if topic not in self._subscribers:
            self._subscribers[topic] = []
        self._subscribers[topic].append(handler)

    async def publish(self, session: AsyncSession, topic: str, payload: BaseModel) -> OutboxEvent:
        """
        Stores event in outbox_events inside the active database transaction.
        """
        event = OutboxEvent(
            id=uuid.uuid4(),
            topic=topic,
            payload=payload.model_dump(mode="json"),
            status="pending",
            created_at=datetime.now(timezone.utc),
        )
        session.add(event)
        return event


event_bus = EventBus()
