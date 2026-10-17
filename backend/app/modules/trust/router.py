"""
backend/app/modules/trust/router.py - Trust, Safety, Reports, Blocks, and Moderation Endpoints.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import User, get_db
from app.core.deps import get_current_user, require_role
from app.modules.trust.schemas import (
    ApprovedMembersUploadResponse,
    AuditLogResponse,
    BlockResponse,
    CreateBlockRequest,
    CreateReportRequest,
    MeTrustResponse,
    ModerationQueueResponse,
    ReportResponse,
    ResolveModerationRequest,
    ResolveModerationResponse,
    UnblockResponse,
    VerificationDecideRequest,
    VerificationDecideResponse,
    VerificationQueueResponse,
)
from app.modules.trust.service import TrustService

router = APIRouter(tags=["trust"])


# --- User Reports & Blocks ---

@router.post(
    "/reports",
    response_model=ReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a report against a user, message, or session",
)
async def post_reports(
    payload: CreateReportRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.create_report(current_user, payload, db)


@router.post(
    "/blocks",
    response_model=BlockResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Block a user from contacting or booking",
)
async def post_blocks(
    payload: CreateBlockRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.create_block(current_user, payload, db)


@router.delete(
    "/blocks/{user_id}",
    response_model=UnblockResponse,
    summary="Unblock a previously blocked user",
)
async def delete_blocks_user_id(
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await TrustService.delete_block(current_user, user_id, db)
    return UnblockResponse(
        message="User unblocked successfully.",
        unblocked_user_id=user_id,
    )


@router.get(
    "/me/trust",
    response_model=MeTrustResponse,
    summary="Retrieve current private trust score and safety limits",
)
async def get_me_trust(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.get_me_trust(current_user, db)


# --- Moderation & Verification Administration ---

@router.get(
    "/admin/moderation/queue",
    response_model=ModerationQueueResponse,
    summary="List pending moderation reports",
)
async def get_admin_moderation_queue(
    status: str | None = Query(None, description="Filter by status: pending, resolved, dismissed"),
    type: str | None = Query(None, description="Filter by type: report, flagged_message, restricted_account"),
    cursor: str | None = Query(None, description="Pagination cursor"),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_role("moderator", "institution_admin", "platform_admin")),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.get_moderation_queue(current_user, status, type, cursor, limit, db)


@router.post(
    "/admin/moderation/{id}/resolve",
    response_model=ResolveModerationResponse,
    summary="Resolve a moderation report",
)
async def post_admin_moderation_id_resolve(
    id: UUID,
    payload: ResolveModerationRequest,
    current_user: User = Depends(require_role("moderator", "institution_admin", "platform_admin")),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.resolve_moderation(id, payload.decision, payload.note, current_user, db)


@router.get(
    "/admin/verification/queue",
    response_model=VerificationQueueResponse,
    summary="List pending verification submissions",
)
async def get_admin_verification_queue(
    cursor: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_role("moderator", "institution_admin", "platform_admin")),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.get_verification_queue(current_user, cursor, limit, db)


@router.post(
    "/admin/verification/{id}/decide",
    response_model=VerificationDecideResponse,
    summary="Approve or reject a verification request",
)
async def post_admin_verification_id_decide(
    id: UUID,
    payload: VerificationDecideRequest,
    current_user: User = Depends(require_role("moderator", "institution_admin", "platform_admin")),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.decide_verification(id, payload.decision, payload.badge, payload.note, current_user, db)


@router.post(
    "/admin/approved-members/upload",
    response_model=ApprovedMembersUploadResponse,
    summary="Upload institutional roster CSV",
)
async def post_admin_approved_members_upload(
    file: UploadFile = File(...),
    institution_id: int | None = Form(None),
    current_user: User = Depends(require_role("institution_admin", "platform_admin")),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.upload_approved_members(file, current_user, institution_id, db)


@router.get(
    "/admin/audit-log",
    response_model=AuditLogResponse,
    summary="Retrieve security audit trail",
)
async def get_admin_audit_log(
    action: str | None = Query(None),
    actor_id: UUID | None = Query(None),
    target_id: str | None = Query(None),
    cursor: str | None = Query(None),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(require_role("moderator", "institution_admin", "platform_admin")),
    db: AsyncSession = Depends(get_db),
):
    return await TrustService.get_audit_log(current_user, action, actor_id, target_id, cursor, limit, db)
