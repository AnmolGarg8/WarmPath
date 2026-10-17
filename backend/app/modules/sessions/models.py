import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint, Boolean
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship
from app.core.db import Base

class MentorshipRequest(Base):
    __tablename__ = "mentorship_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    giver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    kind = Column(String(20), nullable=False)  # "instant" or "booked"
    intent_text = Column(Text, nullable=False)
    slot_start = Column(DateTime(timezone=True), nullable=True)
    status = Column(String(20), nullable=False, default="pending", index=True)  # pending, accepted, declined, expired, cancelled
    priority = Column(Integer, nullable=False, default=1)  # Premium=3, High=2, Standard=1
    plan_name = Column(String(50), nullable=True)
    is_cross_college = Column(Boolean, nullable=False, default=False)
    decline_reason = Column(Text, nullable=True)
    idempotency_key = Column(String(255), nullable=True, unique=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    student = relationship("User", foreign_keys=[student_id])
    giver = relationship("User", foreign_keys=[giver_id])
    session = relationship("CallSession", back_populates="request", uselist=False)
    messages = relationship("ThreadMessage", back_populates="request", cascade="all, delete-orphan")

class CallSession(Base):
    __tablename__ = "call_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    request_id = Column(UUID(as_uuid=True), ForeignKey("mentorship_requests.id"), nullable=False, unique=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    giver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    scheduled_at = Column(DateTime(timezone=True), nullable=False)
    duration_minutes = Column(Integer, nullable=False, default=20)
    room_url = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False, default="scheduled", index=True)  # scheduled, in_progress, completed, no_show, cancelled
    student_joined_at = Column(DateTime(timezone=True), nullable=True)
    student_left_at = Column(DateTime(timezone=True), nullable=True)
    giver_joined_at = Column(DateTime(timezone=True), nullable=True)
    giver_left_at = Column(DateTime(timezone=True), nullable=True)
    no_show_party = Column(String(20), nullable=True)  # student or giver
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    request = relationship("MentorshipRequest", back_populates="session")
    student = relationship("User", foreign_keys=[student_id])
    giver = relationship("User", foreign_keys=[giver_id])

    __table_args__ = (
        UniqueConstraint("giver_id", "scheduled_at", name="uq_giver_scheduled_slot"),
    )

class ThreadMessage(Base):
    __tablename__ = "thread_messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    request_id = Column(UUID(as_uuid=True), ForeignKey("mentorship_requests.id"), nullable=False, index=True)
    sender_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    safety_action = Column(String(20), nullable=False, default="allow")  # allow, warn, review, block
    flags = Column(JSONB, nullable=False, default=list)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    request = relationship("MentorshipRequest", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])

class DeviceToken(Base):
    __tablename__ = "device_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    fcm_token = Column(String(512), nullable=False, unique=True)
    platform = Column(String(20), nullable=True)  # android, ios, web
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", foreign_keys=[user_id])
