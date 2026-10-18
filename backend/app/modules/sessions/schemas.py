from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field

class RequestCreate(BaseModel):
    giver_id: str
    kind: str = Field(..., description="instant or booked")
    intent_text: str = Field(..., min_length=5, max_length=2000)
    slot_start: Optional[datetime] = None

class CounterpartSummary(BaseModel):
    id: str
    display_name: str
    headline: Optional[str] = None
    avatar_url: Optional[str] = None
    role: Optional[str] = None  # "Giver" or "Student"
    badges: List[str] = []
    band: Optional[str] = None

class RequestResponse(BaseModel):
    id: str
    student_id: str
    giver_id: str
    kind: str
    intent_text: str
    slot_start: Optional[datetime] = None
    status: str
    priority: int
    plan_name: Optional[str] = None
    is_cross_college: bool
    created_at: datetime
    counterpart: Optional[CounterpartSummary] = None
    giver_earnings_text: Optional[str] = None

class DeclineRequest(BaseModel):
    reason: Optional[str] = None

class SlotItem(BaseModel):
    slot_start: datetime
    slot_end: datetime
    available: bool

class MessageCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=5000)

class MessageResponse(BaseModel):
    id: str
    request_id: str
    sender_id: str
    content: str
    safety_action: str
    flags: List[str] = []
    created_at: datetime

class SessionResponse(BaseModel):
    id: str
    request_id: str
    student_id: str
    giver_id: str
    scheduled_at: datetime
    duration_minutes: int
    room_url: str
    status: str
    student_joined_at: Optional[datetime] = None
    giver_joined_at: Optional[datetime] = None
    no_show_party: Optional[str] = None
    counterpart: Optional[CounterpartSummary] = None
    topic: Optional[str] = None
    student_rating_stars: Optional[int] = None
    giver_rated_quality: Optional[bool] = False

class DeviceTokenCreate(BaseModel):
    fcm_token: str
    platform: Optional[str] = "android"

class DeviceTokenResponse(BaseModel):
    status: str
