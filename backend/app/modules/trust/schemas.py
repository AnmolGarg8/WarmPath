import uuid
from datetime import datetime
from pydantic import BaseModel


class ReportCreateRequest(BaseModel):
    offender_id: uuid.UUID
    category: str
    description: str


class BlockCreateRequest(BaseModel):
    user_id: uuid.UUID
    reason: str | None = None


class ResolveModerationRequest(BaseModel):
    decision: str  # dismiss | warn | restrict | ban
    notes: str | None = None


class VerificationDecisionRequest(BaseModel):
    decision: str  # approved | rejected
    rejection_reason: str | None = None
