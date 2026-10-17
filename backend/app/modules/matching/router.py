import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import decode_token
from app.modules.matching.schemas import (
    GiverProfileCreateUpdate,
    GiverProfileResponse,
    GiverPublicCard,
    RecommendationsResponse,
)
from app.modules.matching.service import MatchingService

router = APIRouter(tags=["matching"])


async def get_current_user_id(request: Request) -> uuid.UUID:
    """Extracts authenticated user UUID from Authorization Bearer token or X-User-Id."""
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split(" ", 1)[1].strip()
        try:
            payload = decode_token(token)
            return uuid.UUID(payload.get("sub"))
        except Exception:
            raise AppError(code="unauthorized", message="Invalid or expired token", status_code=401)

    x_user_id = request.headers.get("X-User-Id")
    if x_user_id:
        try:
            return uuid.UUID(x_user_id)
        except ValueError:
            raise AppError(code="invalid_user_id", message="Invalid X-User-Id header", status_code=400)

    raise AppError(code="unauthorized", message="Authentication required", status_code=401)


async def get_optional_user_id(request: Request) -> Optional[uuid.UUID]:
    """Extracts optional authenticated user UUID if present."""
    try:
        return await get_current_user_id(request)
    except Exception:
        return None


@router.put(
    "/me/giver-profile",
    summary="Update own giver mentorship profile and topics",
    response_model=GiverProfileResponse,
)
async def put_me_giver_profile(
    body: GiverProfileCreateUpdate,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    user_id = await get_current_user_id(request)
    service = MatchingService(db)
    profile = await service.update_giver_profile(user_id, body)

    return GiverProfileResponse(
        user_id=profile.user_id,
        offers=profile.offers or [],
        topics=profile.topics or [],
        skills=profile.skills or [],
        domains=profile.domains or [],
        company=profile.company,
        role_title=profile.role_title,
        bio=profile.bio,
        languages=profile.languages or ["English"],
        weekly_capacity=profile.weekly_capacity,
        institution_id=profile.institution_id,
        department=profile.department,
        batch=profile.batch,
        societies=profile.societies or [],
        has_embedding=profile.embedding is not None,
        response_stats=profile.response_stats or {},
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


@router.get(
    "/me/giver-profile",
    summary="Retrieve own giver mentorship profile",
    response_model=GiverProfileResponse,
)
async def get_me_giver_profile(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    user_id = await get_current_user_id(request)
    service = MatchingService(db)
    profile = await service.get_giver_profile(user_id)

    return GiverProfileResponse(
        user_id=profile.user_id,
        offers=profile.offers or [],
        topics=profile.topics or [],
        skills=profile.skills or [],
        domains=profile.domains or [],
        company=profile.company,
        role_title=profile.role_title,
        bio=profile.bio,
        languages=profile.languages or ["English"],
        weekly_capacity=profile.weekly_capacity,
        institution_id=profile.institution_id,
        department=profile.department,
        batch=profile.batch,
        societies=profile.societies or [],
        has_embedding=profile.embedding is not None,
        response_stats=profile.response_stats or {},
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


@router.get(
    "/recommendations",
    summary="Get ranked mentor recommendations for student",
    response_model=RecommendationsResponse,
)
async def get_recommendations(
    request: Request,
    scope: str = Query("own_college", regex="^(own_college|cross_college|experts)$"),
    limit: int = Query(10, ge=1, le=50),
    cursor: Optional[str] = Query(None),
    filter_domain: Optional[str] = Query(None),
    filter_help_type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    student_id = await get_current_user_id(request)
    service = MatchingService(db)
    return await service.get_recommendations(
        student_id=student_id,
        scope=scope,
        limit=limit,
        cursor=cursor,
        filter_domain=filter_domain,
        filter_help_type=filter_help_type,
    )


@router.get(
    "/givers/{id}",
    summary="View giver mentorship profile",
    response_model=GiverPublicCard,
)
async def get_givers_id(
    id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    requesting_student_id = await get_optional_user_id(request)
    service = MatchingService(db)
    return await service.get_giver_public_card(
        giver_id=id, requesting_student_id=requesting_student_id
    )
