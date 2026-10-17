import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, Float, Boolean
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship
from app.core.db import Base

class SessionRating(Base):
    __tablename__ = "session_ratings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    giver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    stars = Column(Integer, nullable=False)  # 1 to 5
    reason = Column(Text, nullable=True)
    tags = Column(JSONB, nullable=False, default=list)
    weight = Column(Float, nullable=False, default=1.0)  # 0.0 to 1.0 (integrity down-weighting)
    is_suspicious = Column(Boolean, nullable=False, default=False)
    suspicion_flags = Column(JSONB, nullable=False, default=list)
    safety_approved = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    student = relationship("User", foreign_keys=[student_id])
    giver = relationship("User", foreign_keys=[giver_id])

class RequestQualityRating(Base):
    __tablename__ = "request_quality_ratings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    giver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    stars = Column(Integer, nullable=False)  # 1 to 5
    note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

class GiverBandProfile(Base):
    __tablename__ = "giver_band_profiles"

    giver_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    current_band = Column(String(20), nullable=False, default="Rising")  # Rising, Trusted, Top Rated
    smoothed_average = Column(Float, nullable=False, default=4.0)
    rated_sessions_count = Column(Integer, nullable=False, default=0)
    completed_sessions_count = Column(Integer, nullable=False, default=0)
    total_booked_sessions_count = Column(Integer, nullable=False, default=0)
    giver_no_show_count = Column(Integer, nullable=False, default=0)
    completion_rate = Column(Float, nullable=False, default=1.0)
    last_band_change = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    giver = relationship("User", foreign_keys=[giver_id])

class SessionDispute(Base):
    __tablename__ = "session_disputes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(UUID(as_uuid=True), nullable=False, unique=True, index=True)
    opened_by_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    reason = Column(String(50), nullable=False)  # no_show, low_effort, abusive, other
    details = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="open")  # open, resolved, dismissed
    decision = Column(String(50), nullable=True)  # refund, partial_payout, full_payout, restrict_giver, dismiss
    resolution_note = Column(Text, nullable=True)
    resolved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    opened_by = relationship("User", foreign_keys=[opened_by_user_id])
