"""
backend/app/modules/auth/models.py - Database models for authentication, verification, and tokens.
"""

import uuid
from datetime import UTC, datetime

from sqlalchemy import (
    ARRAY,
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.core.db import Base


class ApprovedMember(Base):
    __tablename__ = "approved_members"

    id = Column(Integer, primary_key=True, autoincrement=True)
    institution_id = Column(Integer, ForeignKey("institutions.id"), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # 'student', 'alumnus', 'faculty'
    batch = Column(String(50), nullable=True)
    department = Column(String(100), nullable=True)
    claimed_by_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(UTC), nullable=False)

    institution = relationship("Institution")
    claimed_by = relationship("User")


class VerificationRequest(Base):
    __tablename__ = "verification_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    kind = Column(String(50), nullable=False)  # 'alumnus', 'employer', 'expert', 'faculty'
    evidence_text = Column(Text, nullable=False)
    evidence_urls = Column(ARRAY(String), nullable=True)
    company_name = Column(String(255), nullable=True)
    company_registration = Column(String(255), nullable=True)
    status = Column(String(50), default="pending", nullable=False, index=True)  # 'pending', 'approved', 'rejected'
    decided_by = Column(UUID(as_uuid=True), nullable=True)
    decision_reason = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(UTC), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC), nullable=False)

    user = relationship("User")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    family_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    token_hash = Column(String(255), nullable=False, index=True)
    is_revoked = Column(Boolean, default=False, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(UTC), nullable=False)

    user = relationship("User")
