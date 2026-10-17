from datetime import datetime
from typing import Any, List, Optional
from pydantic import BaseModel, Field

class RequestCreate(BaseModel):
    giver_id: str
    kind: str = Field(..., description="instant or booked")
    intent_text: str = Field(..., min_length=5, max_length=2000)
    slot_start: Optional[datetime] = None

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

class DeviceTokenCreate(BaseModel):
    fcm_token: str
    platform: Optional[str] = "android"

class DeviceTokenResponse(BaseModel):
    status: str
