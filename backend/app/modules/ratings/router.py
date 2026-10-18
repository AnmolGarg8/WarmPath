import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import decode_token
from app.core.config import settings
from app.modules.sessions.models import CallSession
from app.modules.ratings.models import (
    SessionRating,
    RequestQualityRating,
    GiverBandProfile,
    SessionDispute
)
from app.modules.ratings.schemas import (
    StudentRatingCreate,
    StudentRatingResponse,
    RequestQualityCreate,
    RequestQualityResponse,
    DisputeCreate,
    DisputeResponse,
    DisputeResolveRequest,
    RatingSummaryResponse,
    MeBandResponse
)
from app.modules.ratings.service import RatingsService

router = APIRouter(tags=["ratings"])

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise AppError(code="unauthorized", message="Authentication required", status_code=status.HTTP_401_UNAUTHORIZED)
    token = authorization.split(" ")[1]
    payload = decode_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise AppError(code="unauthorized", message="Invalid authentication token", status_code=status.HTTP_401_UNAUTHORIZED)
    return user_id

@router.post("/sessions/{id}/rating", response_model=StudentRatingResponse, summary="Rate session")
async def post_session_rating(
    id: str,
    data: StudentRatingCreate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    s_uid = uuid.UUID(user_id)
    session_uid = uuid.UUID(id)

    # Validate against actual session
    call = (await db.execute(select(CallSession).where(CallSession.id == session_uid))).scalar_one_or_none()
    if call:
        if call.student_id != s_uid:
            raise AppError(code="unauthorized", message="Only the student in this session can submit a rating", status_code=403)
        if call.status != "completed":
            raise AppError(code="session_not_completed", message="Session must be completed before rating", status_code=400)
        
        now = datetime.now(timezone.utc)
        completed_time = call.student_left_at or call.scheduled_at
        if completed_time.tzinfo is None:
            completed_time = completed_time.replace(tzinfo=timezone.utc)
        if now - completed_time > timedelta(days=14):
            raise AppError(code="rating_window_expired", message="Ratings must be submitted within 14 days of session completion", status_code=400)

        giver_uid = call.giver_id
    else:
        giver_uid = uuid.uuid4()

    rating = await RatingsService.submit_student_rating(
        session=db,
        session_id=session_uid,
        student_id=s_uid,
        giver_id=giver_uid,
        stars=data.stars,
        reason=data.reason,
        tags=data.tags
    )
    return StudentRatingResponse(
        id=str(rating.id),
        session_id=str(rating.session_id),
        student_id=str(rating.student_id),
        giver_id=str(rating.giver_id),
        stars=rating.stars,
        reason=rating.reason,
        tags=rating.tags,
        created_at=rating.created_at
    )

@router.post("/sessions/{id}/request-quality", response_model=RequestQualityResponse, summary="Rate request quality")
async def post_request_quality(
    id: str,
    data: RequestQualityCreate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    g_uid = uuid.UUID(user_id)
    session_uid = uuid.UUID(id)

    call = (await db.execute(select(CallSession).where(CallSession.id == session_uid))).scalar_one_or_none()
    if call:
        if call.giver_id != g_uid:
            raise AppError(code="unauthorized", message="Only the giver in this session can rate request quality", status_code=403)
        student_uid = call.student_id
    else:
        student_uid = uuid.uuid4()

    rq = await RatingsService.submit_request_quality(
        session=db,
        session_id=session_uid,
        giver_id=g_uid,
        student_id=student_uid,
        stars=data.stars,
        note=data.note
    )
    return RequestQualityResponse(
        id=str(rq.id),
        session_id=str(rq.session_id),
        stars=rq.stars,
        note=rq.note,
        created_at=rq.created_at
    )

@router.post("/sessions/{id}/dispute", response_model=DisputeResponse, summary="Open dispute")
async def post_dispute(
    id: str,
    data: DisputeCreate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    dispute = await RatingsService.open_dispute(
        session=db,
        session_id=uuid.UUID(id),
        user_id=uuid.UUID(user_id),
        reason=data.reason,
        details=data.details
    )
    return DisputeResponse(
        id=str(dispute.id),
        session_id=str(dispute.session_id),
        opened_by_user_id=str(dispute.opened_by_user_id),
        reason=dispute.reason,
        details=dispute.details,
        status=dispute.status,
        decision=dispute.decision,
        resolution_note=dispute.resolution_note,
        created_at=dispute.created_at,
        resolved_at=dispute.resolved_at
    )

@router.get("/givers/{id}/rating-summary", response_model=RatingSummaryResponse, summary="Giver rating summary")
async def get_rating_summary(
    id: str,
    db: AsyncSession = Depends(get_db)
):
    g_uid = uuid.UUID(id)
    profile = await RatingsService.get_or_create_profile(db, g_uid)

    # Compute star distribution
    dist_stmt = select(SessionRating.stars, func.count(SessionRating.id)).where(
        SessionRating.giver_id == g_uid
    ).group_by(SessionRating.stars)
    dist_res = await db.execute(dist_stmt)
    dist = {f"{s}_stars": c for s, c in dist_res.all()}
    for s in range(1, 6):
        dist.setdefault(f"{s}_stars", 0)

    # Recent reviews (safety approved only)
    rev_stmt = select(SessionRating).where(
        SessionRating.giver_id == g_uid,
        SessionRating.safety_approved == True,
        SessionRating.reason != None
    ).order_by(desc(SessionRating.created_at)).limit(10)
    revs = (await db.execute(rev_stmt)).scalars().all()

    return RatingSummaryResponse(
        giver_id=id,
        current_band=profile.current_band,
        smoothed_average=profile.smoothed_average,
        rated_sessions_count=profile.rated_sessions_count,
        completion_rate=profile.completion_rate,
        distribution=dist,
        recent_reviews=[{"stars": r.stars, "reason": r.reason, "created_at": r.created_at.isoformat()} for r in revs]
    )

@router.get("/me/band", response_model=MeBandResponse, summary="Giver band details & progress")
async def get_me_band(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    g_uid = uuid.UUID(user_id)
    profile = await RatingsService.get_or_create_profile(db, g_uid)

    share_map = {
        "Rising": settings.PAYOUT_SHARE_RISING,
        "Trusted": settings.PAYOUT_SHARE_TRUSTED,
        "Top Rated": settings.PAYOUT_SHARE_TOP_RATED
    }
    payout_share = share_map.get(profile.current_band, 0.60)

    # Calculate requirements for next band in plain language
    if profile.current_band == "Rising":
        next_band = "Trusted"
        notes = "Needs at least 5 rated sessions with smoothed rating >= 4.2."
    elif profile.current_band == "Trusted":
        next_band = "Top Rated"
        notes = "Needs at least 10 rated sessions, smoothed rating >= 4.6, and completion rate >= 90%."
    else:
        next_band = None
        notes = "You are currently at the highest tier: Top Rated (80% payout share)."

    return MeBandResponse(
        giver_id=user_id,
        current_band=profile.current_band,
        smoothed_average=profile.smoothed_average,
        rated_sessions_count=profile.rated_sessions_count,
        completion_rate=profile.completion_rate,
        payout_share=payout_share,
        next_band=next_band,
        progress_notes=notes
    )

@router.get("/admin/disputes", response_model=List[DisputeResponse], summary="List disputes")
async def list_disputes(
    status: Optional[str] = Query("open"),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    stmt = select(SessionDispute)
    if status:
        stmt = stmt.where(SessionDispute.status == status)
    stmt = stmt.order_by(desc(SessionDispute.created_at))
    items = (await db.execute(stmt)).scalars().all()
    return [
        DisputeResponse(
            id=str(d.id),
            session_id=str(d.session_id),
            opened_by_user_id=str(d.opened_by_user_id),
            reason=d.reason,
            details=d.details,
            status=d.status,
            decision=d.decision,
            resolution_note=d.resolution_note,
            created_at=d.created_at,
            resolved_at=d.resolved_at
        ) for d in items
    ]

@router.post("/admin/disputes/{id}/resolve", response_model=DisputeResponse, summary="Resolve dispute")
async def resolve_dispute(
    id: str,
    data: DisputeResolveRequest,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    dispute = await RatingsService.resolve_dispute(
        session=db,
        dispute_id=uuid.UUID(id),
        moderator_id=uuid.UUID(user_id),
        decision=data.decision,
        note=data.note
    )
    return DisputeResponse(
        id=str(dispute.id),
        session_id=str(dispute.session_id),
        opened_by_user_id=str(dispute.opened_by_user_id),
        reason=dispute.reason,
        details=dispute.details,
        status=dispute.status,
        decision=dispute.decision,
        resolution_note=dispute.resolution_note,
        created_at=dispute.created_at,
        resolved_at=dispute.resolved_at
    )
