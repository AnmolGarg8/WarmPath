"""
SQLAlchemy models for credits module.
Owner: M4
Tables: plans, ledger_accounts, ledger_entries, credit_lots, session_settlements, user_subscriptions, sponsored_seats, payout_requests
"""

import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Boolean,
    CHAR,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Text,
)
from sqlalchemy.dialects import postgresql
from sqlalchemy.orm import relationship
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


class Plan(Base):
    __tablename__ = "plans"

    id = Column(Integer, primary_key=True, autoincrement=True)
    code = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    price_inr = Column(Integer, nullable=False, default=0)
    credits_per_month = Column(Integer, nullable=False, default=0)
    reach_bands = Column(postgresql.ARRAY(String).with_variant(JSON(), "sqlite"), nullable=False, default=list)
    booking_horizon_days = Column(Integer, nullable=False, default=3)
    priority = Column(Integer, nullable=False, default=0)
    features = Column(postgresql.JSONB().with_variant(JSON(), "sqlite"), nullable=False, default=list)
    active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class LedgerAccount(Base):
    __tablename__ = "ledger_accounts"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    owner_user_id = Column(GUID(), nullable=True, index=True)
    kind = Column(String(50), nullable=False, index=True)  # user_paid, user_affinity, platform_revenue, reserved, scholarship_pool, payout_clearing
    balance_credits = Column(Integer, nullable=False, default=0)
    balance_inr = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    entries = relationship("LedgerEntry", back_populates="account")
    lots = relationship("CreditLot", back_populates="account")


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    txn_id = Column(GUID(), nullable=False, index=True)
    account_id = Column(
        GUID(),
        ForeignKey("ledger_accounts.id"),
        nullable=False,
        index=True,
    )
    amount_credits = Column(Integer, nullable=False, default=0)
    amount_inr = Column(Float, nullable=False, default=0.0)
    direction = Column(String(10), nullable=False)  # credit or debit
    reason = Column(String(100), nullable=False)
    ref_type = Column(String(50), nullable=False, index=True)
    ref_id = Column(String(100), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    account = relationship("LedgerAccount", back_populates="entries")


class CreditLot(Base):
    __tablename__ = "credit_lots"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    account_id = Column(
        GUID(),
        ForeignKey("ledger_accounts.id"),
        nullable=False,
        index=True,
    )
    credits_remaining = Column(Integer, nullable=False, default=0)
    unit_price_inr = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)

    account = relationship("LedgerAccount", back_populates="lots")


class SessionSettlement(Base):
    __tablename__ = "session_settlements"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    session_id = Column(String(100), nullable=False, unique=True, index=True)
    request_id = Column(String(100), nullable=True, index=True)
    student_id = Column(GUID(), nullable=False)
    giver_id = Column(GUID(), nullable=False)
    is_cross_college = Column(Boolean, nullable=False, default=True)
    unit_price_inr = Column(Float, nullable=False, default=0.0)
    status = Column(String(50), nullable=False, default="pending_window", index=True)  # pending_window, disputed, settled, refunded
    settles_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    settled_at = Column(DateTime(timezone=True), nullable=True)


class UserSubscription(Base):
    __tablename__ = "user_subscriptions"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID(), nullable=False, index=True)
    plan_code = Column(String(50), nullable=False, default="campus")
    status = Column(String(50), nullable=False, default="active")  # active, cancelled, past_due
    period_start = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    period_end = Column(DateTime(timezone=True), nullable=False)
    renews_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class SponsoredSeat(Base):
    __tablename__ = "sponsored_seats"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    institution_id = Column(Integer, nullable=True, index=True)
    student_id = Column(GUID(), nullable=False, index=True)
    plan_tier = Column(String(50), nullable=False)
    sponsor_name = Column(String(255), nullable=True)
    funded_by = Column(String(50), nullable=False, default="scholarship_pool")  # sponsor, institution_budget, scholarship_pool
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)


class PayoutRequest(Base):
    __tablename__ = "payout_requests"

    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID(), nullable=False, index=True)
    amount_inr = Column(Float, nullable=False)
    upi_id = Column(String(255), nullable=False)
    status = Column(String(50), nullable=False, default="pending")  # pending, processed, failed
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
