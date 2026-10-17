"""
SQLAlchemy models for institution reporting and read models.
Owner: M4
Tables:
  - institution_event_logs
  - institution_user_read_model
  - institution_request_records
  - institution_session_records
  - institution_skill_gap_records
  - institution_safety_records
  - institution_seats_records
  - institution_access_reach_records
  - institution_seat_grants
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    CHAR,
    Boolean,
    Column,
    DateTime,
    Float,
    Integer,
    JSON,
    String,
    Text,
)
from sqlalchemy.dialects import postgresql
from sqlalchemy.types import TypeDecorator

from app.core.db import Base


class GUID(TypeDecorator):
    """Platform-independent GUID type.
    Uses PostgreSQL's UUID(as_uuid=True), otherwise uses CHAR(36).
    """

    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(postgresql.UUID(as_uuid=True))
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        if not isinstance(value, uuid.UUID):
            return uuid.UUID(str(value))
        return value


class InstitutionEventLog(Base):
    """Tracks processed event IDs for replay idempotency."""
    __tablename__ = "institution_event_logs"

    event_id = Column(String(100), primary_key=True)
    topic = Column(String(100), nullable=False)
    received_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    processed_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class InstitutionUserReadModel(Base):
    """Lightweight user-to-institution lookup populated from outbox events."""
    __tablename__ = "institution_user_read_model"

    user_id = Column(GUID(), primary_key=True)
    institution_id = Column(Integer, nullable=False, index=True)
    role = Column(String(50), nullable=False, default="student")
    skills = Column(postgresql.JSONB().with_variant(JSON(), "sqlite"), nullable=False, default=list)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class InstitutionRequestRecord(Base):
    """Reporting read model for mentorship requests."""
    __tablename__ = "institution_request_records"

    request_id = Column(GUID(), primary_key=True)
    student_id = Column(GUID(), nullable=False, index=True)
    giver_id = Column(GUID(), nullable=False, index=True)
    student_institution_id = Column(Integer, nullable=False, index=True)
    giver_institution_id = Column(Integer, nullable=False, index=True)
    is_cross_college = Column(Boolean, nullable=False, default=False)
    status = Column(String(50), nullable=False, default="posted")  # posted, accepted, declined, expired, completed
    first_response_seconds = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    responded_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)


class InstitutionSessionRecord(Base):
    """Reporting read model for mentorship sessions."""
    __tablename__ = "institution_session_records"

    session_id = Column(GUID(), primary_key=True)
    request_id = Column(GUID(), nullable=True)
    student_id = Column(GUID(), nullable=False, index=True)
    giver_id = Column(GUID(), nullable=False, index=True)
    student_institution_id = Column(Integer, nullable=False, index=True)
    giver_institution_id = Column(Integer, nullable=False, index=True)
    is_cross_college = Column(Boolean, nullable=False, default=False)
    status = Column(String(50), nullable=False, default="booked")  # booked, completed, no_show_student, no_show_giver
    duration_minutes = Column(Float, nullable=False, default=0.0)
    rating = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)


class InstitutionSkillGapRecord(Base):
    """Reporting read model for student skill demand vs alumni supply."""
    __tablename__ = "institution_skill_gap_records"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    institution_id = Column(Integer, nullable=False, index=True)
    skill_name = Column(String(100), nullable=False, index=True)
    category = Column(String(50), nullable=False, default="skill")  # skill, domain
    demand_count = Column(Integer, nullable=False, default=0)
    supply_count = Column(Integer, nullable=False, default=0)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class InstitutionSafetyRecord(Base):
    """Reporting read model for safety incidents, reports, and disputes."""
    __tablename__ = "institution_safety_records"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    institution_id = Column(Integer, nullable=False, index=True)
    incident_type = Column(String(50), nullable=False)  # report, dispute, scam_blocked
    reference_id = Column(String(100), nullable=False, index=True)
    status = Column(String(50), nullable=False, default="opened")  # opened, resolved, dismissed
    opened_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False, index=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resolution_time_hours = Column(Float, nullable=True)


class InstitutionSeatsRecord(Base):
    """Reporting read model for institutional budget, seats, and scholarship pool."""
    __tablename__ = "institution_seats_records"

    institution_id = Column(Integer, primary_key=True)
    sponsored_seats_granted = Column(Integer, nullable=False, default=0)
    total_budget_inr = Column(Float, nullable=False, default=50000.0)
    remaining_budget_inr = Column(Float, nullable=False, default=50000.0)
    scholarship_pool_balance = Column(Float, nullable=False, default=15000.0)
    donations_count = Column(Integer, nullable=False, default=0)
    donations_amount_inr = Column(Float, nullable=False, default=0.0)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class InstitutionAccessReachRecord(Base):
    """Reporting read model for aggregated inter-college access reach."""
    __tablename__ = "institution_access_reach_records"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    student_institution_id = Column(Integer, nullable=False, index=True)
    giver_institution_id = Column(Integer, nullable=False, index=True)
    session_count = Column(Integer, nullable=False, default=0)
    student_count = Column(Integer, nullable=False, default=0)
    giver_count = Column(Integer, nullable=False, default=0)
    last_activity_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class InstitutionSeatGrant(Base):
    """Log of individual sponsored seat grants (with masked email for privacy)."""
    __tablename__ = "institution_seat_grants"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    institution_id = Column(Integer, nullable=False, index=True)
    student_id = Column(GUID(), nullable=True)
    student_email_masked = Column(String(255), nullable=False)
    plan_code = Column(String(50), nullable=False, default="standard")
    funding_source = Column(String(100), nullable=False, default="Institution Budget")
    granted_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
