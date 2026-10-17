"""
SQLAlchemy models for payments module.
Owner: M4
Tables: subscriptions, payment_events, payout_requests, giver_earnings_read_model, razorpay_plan_mappings
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    CHAR,
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


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID(), nullable=False, index=True)
    plan_code = Column(String(50), nullable=False)
    razorpay_subscription_id = Column(String(100), unique=True, index=True, nullable=False)
    razorpay_plan_id = Column(String(100), nullable=True)
    status = Column(String(50), nullable=False, default="created")  # created, authenticated, active, cancelled, halted, past_due
    current_period_start = Column(DateTime(timezone=True), nullable=True)
    current_period_end = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class PaymentEvent(Base):
    __tablename__ = "payment_events"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    event_id = Column(String(100), unique=True, index=True, nullable=False)
    event_type = Column(String(100), nullable=False, index=True)
    payload = Column(postgresql.JSONB().with_variant(JSON(), "sqlite"), nullable=False)
    received_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    processed_at = Column(DateTime(timezone=True), nullable=True)


class PayoutRequest(Base):
    __tablename__ = "payments_payout_requests"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID(), nullable=False, index=True)
    amount_inr = Column(Float, nullable=False)
    upi_id = Column(String(255), nullable=True)
    status = Column(String(50), nullable=False, default="requested")  # requested, approved, paid, rejected
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    processed_at = Column(DateTime(timezone=True), nullable=True)


class GiverEarningsReadModel(Base):
    __tablename__ = "giver_earnings_read_model"

    user_id = Column(GUID(), primary_key=True)
    available_earnings_inr = Column(Float, nullable=False, default=0.0)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )


class RazorpayPlanMapping(Base):
    __tablename__ = "razorpay_plan_mappings"

    plan_code = Column(String(50), primary_key=True)
    razorpay_plan_id = Column(String(100), nullable=False)
    price_inr = Column(Integer, nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
