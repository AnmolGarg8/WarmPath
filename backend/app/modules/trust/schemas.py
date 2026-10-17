"""
backend/app/modules/trust/schemas.py - Request and response schemas for Trust & Safety module.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID
from pydantic import BaseModel, ConfigDict, Field


# --- Reports ---

class CreateReportRequest(BaseModel):
    target_user_id: Optional[UUID] = None
    message_id: Optional[str] = None
    request_id: Optional[str] = None
    reason: str = Field(..., min_length=2, max_length=100)
    details: Optional[str] = Field(None, max_length=2000)


class ReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    reporter_id: UUID
    target_user_id: Optional[UUID] = None
    message_id: Optional[str] = None
    request_id: Optional[str] = None
    reason: str
    details: Optional[str] = None
    status: str
    resolution_decision: Optional[str] = None
    resolution_note: Optional[str] = None
    resolved_by_id: Optional[UUID] = None
    resolved_at: Optional[datetime] = None
    created_at: datetime


# --- Blocks ---

class CreateBlockRequest(BaseModel):
    blocked_user_id: UUID
    reason: Optional[str] = Field(None, max_length=255)


class BlockResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    blocker_id: UUID
    blocked_id: UUID
    reason: Optional[str] = None
    created_at: datetime


class UnblockResponse(BaseModel):
    message: str
    unblocked_user_id: UUID


# --- Trust & Limits ---

class MeTrustResponse(BaseModel):
    trust_level: str
    verification_level: str
    requests_per_day_limit: int
    requests_per_day_remaining: int
    can_post_jobs: bool
    can_host_session: bool
    messages_reviewed_first: bool
    limits: Dict[str, Any]


# --- Moderation Queue ---

class ModerationItem(BaseModel):
    id: str
    type: str  # "report", "flagged_message", "restricted_account"
    status: str
    severity: str
    reporter_id: Optional[str] = None
    target_user_id: Optional[str] = None
    target_user_email: Optional[str] = None
    reason: Optional[str] = None
    details: Optional[str] = None
    created_at: datetime


class ModerationQueueResponse(BaseModel):
    items: List[ModerationItem]
    next_cursor: Optional[str] = None


class ResolveModerationRequest(BaseModel):
    decision: str = Field(..., pattern="^(dismiss|warn|restrict|suspend|ban)$")
    note: str = Field(..., min_length=1, max_length=1000)


class ResolveModerationResponse(BaseModel):
    report_id: str
    decision: str
    note: str
    resolved_by: str
    resolved_at: datetime


# --- Verification Queue ---

class VerificationQueueItem(BaseModel):
    id: UUID
    user_id: str
    user_email: str
    user_full_name: str
    kind: str
    evidence_text: str
    evidence_urls: List[str]
    company_name: Optional[str] = None
    company_registration: Optional[str] = None
    status: str
    created_at: datetime


class VerificationQueueResponse(BaseModel):
    items: List[VerificationQueueItem]
    next_cursor: Optional[str] = None


class VerificationDecideRequest(BaseModel):
    decision: str = Field(..., pattern="^(approve|reject)$")
    badge: Optional[str] = None
    note: Optional[str] = None


class VerificationDecideResponse(BaseModel):
    request_id: UUID
    decision: str
    badge_assigned: Optional[str] = None
    note: Optional[str] = None


# --- Approved Members Upload ---

class ApprovedMembersUploadResponse(BaseModel):
    total_rows: int
    inserted: int
    duplicates_skipped: int
    errors: List[str]


# --- Audit Log ---

class AuditLogItem(BaseModel):
    id: str
    actor_id: str
    actor_email: str
    action: str
    target_type: str
    target_id: str
    institution_id: Optional[int] = None
    details: Dict[str, Any]
    created_at: datetime


class AuditLogResponse(BaseModel):
    items: List[AuditLogItem]
    next_cursor: Optional[str] = None
