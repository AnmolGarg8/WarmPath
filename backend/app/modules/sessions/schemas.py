import uuid
from datetime import datetime
from pydantic import BaseModel


class RequestCreate(BaseModel):
    giver_id: uuid.UUID
    intro_message: str
    target_slot_id: str | None = None


class MessageCreate(BaseModel):
    content: str


class DeviceTokenRegister(BaseModel):
    token: str
    platform: str  # android | ios | web
