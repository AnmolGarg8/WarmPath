"""
backend/app/modules/trust/schemas.py - Request and response schemas for Trust & Safety module.
"""

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

# --- Reports ---

class CreateReportRequest(BaseModel):
    target_user_id: UUID | None = None
    message_id: str | None = None
    request_id: str | None = None
    reason: str = Field(..., min_length=2, max_length=100)
    details: str | None = Field(None, max_length=2000)


class ReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    reporter_id: UUID
    target_user_id: UUID | None = None
    message_id: str | None = None
    request_id: str | None = None
    reason: str
    details: str | None = None
    status: str
    resolution_decision: str | None = None
    resolution_note: str | None = None
    resolved_by_id: UUID | None = None
    resolved_at: datetime | None = None
    created_at: datetime


# --- Blocks ---

class CreateBlockRequest(BaseModel):
    blocked_user_id: UUID
    reason: str | None = Field(None, max_length=255)


class BlockResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    blocker_id: UUID
    blocked_id: UUID
    reason: str | None = None
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
    limits: dict[str, Any]


# --- Moderation Queue ---

class ModerationItem(BaseModel):
    id: str
    type: str  # "report", "flagged_message", "restricted_account"
    status: str
    severity: str
    reporter_id: str | None = None
    target_user_id: str | None = None
    target_user_email: str | None = None
    reason: str | None = None
    details: str | None = None
    created_at: datetime


class ModerationQueueResponse(BaseModel):
    items: list[ModerationItem]
    next_cursor: str | None = None


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
    evidence_urls: list[str]
    company_name: str | None = None
    company_registration: str | None = None
    status: str
    created_at: datetime


class VerificationQueueResponse(BaseModel):
    items: list[VerificationQueueItem]
    next_cursor: str | None = None


class VerificationDecideRequest(BaseModel):
    decision: str = Field(..., pattern="^(approve|reject)$")
    badge: str | None = None
    note: str | None = None


class VerificationDecideResponse(BaseModel):
    request_id: UUID
    decision: str
    badge_assigned: str | None = None
    note: str | None = None


# --- Approved Members Upload ---

class ApprovedMembersUploadResponse(BaseModel):
    total_rows: int
    inserted: int
    duplicates_skipped: int
    errors: list[str]


# --- Audit Log ---

class AuditLogItem(BaseModel):
    id: str
    actor_id: str
    actor_email: str
    action: str
    target_type: str
    target_id: str
    institution_id: int | None = None
    details: dict[str, Any]
    created_at: datetime


class AuditLogResponse(BaseModel):
    items: list[AuditLogItem]
    next_cursor: str | None = None
