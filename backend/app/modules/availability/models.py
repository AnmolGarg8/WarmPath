from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Date, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship
from app.core.db import Base

class Availability(Base):
    __tablename__ = "availability"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    weekly_capacity = Column(Integer, nullable=False, default=5)
    timezone = Column(String(50), nullable=False, default="UTC")
    windows = Column(JSONB, nullable=False, default=list)  # list of {weekday: int (0=Mon..6=Sun), start_time: "HH:MM", end_time: "HH:MM"}
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", foreign_keys=[user_id])

class CapacityUsage(Base):
    __tablename__ = "capacity_usage"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    week_start = Column(Date, nullable=False, index=True)  # Monday date of the week in giver's timezone
    used = Column(Integer, nullable=False, default=0)

    user = relationship("User", foreign_keys=[user_id])
