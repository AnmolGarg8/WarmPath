from datetime import UTC, datetime

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID

try:
    from pgvector.sqlalchemy import Vector
except ImportError:
    from sqlalchemy.types import UserDefinedType

    class Vector(UserDefinedType):
        """Fallback for environments without pgvector installed."""
        def __init__(self, dim: int = 768):
            self.dim = dim

        def get_col_spec(self, **kw) -> str:
            return f"vector({self.dim})"

from app.core.db import Base


def utc_now() -> datetime:
    return datetime.now(UTC)


class GiverProfile(Base):
    __tablename__ = "giver_profiles"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    offers = Column(JSONB, nullable=False, default=list)  # resume review, mock interview, referral advice, etc.
    topics = Column(ARRAY(String), nullable=False, default=list)
    skills = Column(JSONB, nullable=False, default=list)  # [{"name": "...", "category": "..."}]
    domains = Column(ARRAY(String), nullable=False, default=list)
    company = Column(String(255), nullable=True)
    role_title = Column(String(255), nullable=True)
    bio = Column(Text, nullable=True)
    languages = Column(ARRAY(String), nullable=False, default=lambda: ["English"])
    embedding = Column(Vector(768), nullable=True)
    response_stats = Column(
        JSONB,
        nullable=False,
        default=lambda: {
            "acceptance_rate": 0.95,
            "median_response_minutes": 60,
            "total_sessions": 0,
        },
    )
    weekly_capacity = Column(Integer, nullable=False, default=3)
    institution_id = Column(Integer, nullable=True)
    department = Column(String(100), nullable=True)
    batch = Column(Integer, nullable=True)
    societies = Column(ARRAY(String), nullable=False, default=list)
    daily_impressions_date = Column(DateTime(timezone=True), nullable=True)
    daily_impressions_count = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)


class StudentMatchProfile(Base):
    """
    Local matching projection populated from profile.updated outbox events.
    Enforces privacy by storing only non-raw shared matching signals.
    """
    __tablename__ = "student_match_profiles"

    user_id = Column(UUID(as_uuid=True), primary_key=True)
    institution_id = Column(Integer, nullable=True)
    department = Column(String(100), nullable=True)
    batch = Column(Integer, nullable=True)
    societies = Column(ARRAY(String), nullable=False, default=list)
    skills = Column(JSONB, nullable=False, default=list)
    domains = Column(ARRAY(String), nullable=False, default=list)
    profile_embedding = Column(Vector(768), nullable=True)
    intent_goal = Column(Text, nullable=True)
    intent_roles = Column(ARRAY(String), nullable=False, default=list)
    intent_domains = Column(ARRAY(String), nullable=False, default=list)
    intent_help_type = Column(String(100), nullable=True)
    intent_embedding = Column(Vector(768), nullable=True)
    profile_version = Column(Integer, nullable=False, default=1)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, nullable=False)
