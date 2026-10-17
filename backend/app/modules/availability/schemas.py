from datetime import date, datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field, field_validator
import re

class TimeWindow(BaseModel):
    weekday: int = Field(..., ge=0, le=6, description="0=Monday, 6=Sunday")
    start_time: str = Field(..., description="HH:MM format, e.g. 09:00")
    end_time: str = Field(..., description="HH:MM format, e.g. 17:00")

    @field_validator("start_time", "end_time")
    @classmethod
    def validate_time_format(cls, v: str) -> str:
        if not re.match(r"^([01]?[0-9]|2[0-3]):[0-5][0-9]$", v):
            raise ValueError("Time must be in HH:MM format")
        return v

class AvailabilityUpdate(BaseModel):
    weekly_capacity: int = Field(..., ge=0, le=100, description="Max session capacity per week")
    timezone: str = Field("UTC", description="IANA timezone name, e.g. Asia/Kolkata")
    windows: List[TimeWindow] = Field(default_factory=list)

class AvailabilityResponse(BaseModel):
    user_id: str
    weekly_capacity: int
    timezone: str
    windows: List[TimeWindow]
    used_this_week: int = 0
    capacity_left: int = 0
    updated_at: Optional[datetime] = None

class OnlineRequest(BaseModel):
    minutes: int = Field(..., ge=5, le=120, description="Duration in minutes to stay open for instant connect")

class OnlineResponse(BaseModel):
    user_id: str
    online_now: bool
    expires_at: Optional[datetime] = None
    remaining_seconds: int = 0

class PresenceStatus(BaseModel):
    user_id: str
    online_now: bool
    capacity_left: int
    next_window_start: Optional[str] = None
