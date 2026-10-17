"""
FastAPI router for institution dashboard reporting endpoints.
Owner: M4
Endpoints:
  - GET /admin/dashboard/overview
  - GET /admin/dashboard/skill-gap
  - GET /admin/dashboard/safety-summary
  - GET /admin/dashboard/seats
  - POST /admin/dashboard/seats/grant (and alias POST /admin/sponsored-seats)
"""

from contextlib import asynccontextmanager
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, Header, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.security import decode_token
from app.modules.institution.schemas import (
    DashboardOverviewResponse,
    GrantSeatInput,
    GrantSeatResponse,
    SafetySummaryResponse,
    SeatsResponse,
    SkillGapResponse,
)
from app.modules.institution.service import InstitutionService

router = APIRouter(tags=["institution"])


@asynccontextmanager
async def transaction_scope(db: AsyncSession):
    if db.in_transaction():
        yield db
        await db.commit()
    else:
        async with db.begin():
            yield db


class CurrentAdminContext:
    def __init__(self, user_id: str, roles: list[str], institution_id: Optional[int]):
        self.user_id = user_id
        self.roles = roles
        self.institution_id = institution_id

    @property
    def is_platform_admin(self) -> bool:
        return "platform_admin" in self.roles or "moderator" in self.roles

    @property
    def is_institution_admin(self) -> bool:
        return "institution_admin" in self.roles or not self.is_platform_admin


async def get_admin_context(
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
    x_user_role: Optional[str] = Header(None),
    x_institution_id: Optional[str] = Header(None),
) -> CurrentAdminContext:
    user_id = "00000000-0000-0000-0000-000000000001"
    roles = ["institution_admin"]
    inst_id = 1

    if authorization and authorization.startswith("Bearer "):
        token = authorization[len("Bearer "):]
        payload = decode_token(token)
        user_id = payload.get("sub", user_id)
        if "roles" in payload and isinstance(payload["roles"], list):
            roles = payload["roles"]
        if "institution_id" in payload and payload["institution_id"] is not None:
            inst_id = int(payload["institution_id"])

    if x_user_id:
        user_id = x_user_id
    if x_user_role:
        roles = [r.strip() for r in x_user_role.split(",")]
    if x_institution_id:
        try:
            inst_id = int(x_institution_id)
        except ValueError:
            pass

    return CurrentAdminContext(user_id=user_id, roles=roles, institution_id=inst_id)


def parse_date(date_str: Optional[str]) -> Optional[datetime]:
    if not date_str:
        return None
    try:
        return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except Exception:
        return None


@router.get(
    "/admin/dashboard/overview",
    response_model=DashboardOverviewResponse,
    summary="Overview of active sessions, response times, and fulfillment",
)
async def get_admin_dashboard_overview(
    from_date: Optional[str] = Query(None, alias="from"),
    to_date: Optional[str] = Query(None, alias="to"),
    institution_id: Optional[int] = Query(None),
    admin: CurrentAdminContext = Depends(get_admin_context),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve high-level KPI and trends dashboard overview scoped by institution."""
    target_inst = admin.institution_id if admin.is_institution_admin else institution_id
    dt_from = parse_date(from_date)
    dt_to = parse_date(to_date)

    return await InstitutionService.get_overview(
        session=db,
        institution_id=target_inst,
        from_date=dt_from,
        to_date=dt_to,
    )


@router.get(
    "/admin/dashboard/skill-gap",
    response_model=SkillGapResponse,
    summary="Analysis of in-demand student skills vs alumni supply",
)
async def get_admin_dashboard_skill_gap(
    from_date: Optional[str] = Query(None, alias="from"),
    to_date: Optional[str] = Query(None, alias="to"),
    institution_id: Optional[int] = Query(None),
    admin: CurrentAdminContext = Depends(get_admin_context),
    db: AsyncSession = Depends(get_db),
):
    """Analyze student demand against alumni mentor supply to identify recruitment gaps."""
    target_inst = admin.institution_id if admin.is_institution_admin else institution_id
    dt_from = parse_date(from_date)
    dt_to = parse_date(to_date)

    return await InstitutionService.get_skill_gap(
        session=db,
        institution_id=target_inst,
        from_date=dt_from,
        to_date=dt_to,
    )


@router.get(
    "/admin/dashboard/safety-summary",
    response_model=SafetySummaryResponse,
    summary="Safety incident summary and moderation resolution rate",
)
async def get_admin_dashboard_safety_summary(
    from_date: Optional[str] = Query(None, alias="from"),
    to_date: Optional[str] = Query(None, alias="to"),
    institution_id: Optional[int] = Query(None),
    admin: CurrentAdminContext = Depends(get_admin_context),
    db: AsyncSession = Depends(get_db),
):
    """Safety health metrics: reports received, resolved, resolution time vs 24hr pilot target."""
    target_inst = admin.institution_id if admin.is_institution_admin else institution_id
    dt_from = parse_date(from_date)
    dt_to = parse_date(to_date)

    return await InstitutionService.get_safety_summary(
        session=db,
        institution_id=target_inst,
        from_date=dt_from,
        to_date=dt_to,
    )


@router.get(
    "/admin/dashboard/seats",
    response_model=SeatsResponse,
    summary="Usage metrics for sponsored seats and credits",
)
async def get_admin_dashboard_seats(
    institution_id: Optional[int] = Query(None),
    admin: CurrentAdminContext = Depends(get_admin_context),
    db: AsyncSession = Depends(get_db),
):
    """Usage metrics for sponsored seats, institutional budget, and scholarship pool."""
    target_inst = admin.institution_id if admin.is_institution_admin else (institution_id or 1)
    return await InstitutionService.get_seats(
        session=db,
        institution_id=target_inst,
    )


@router.post(
    "/admin/dashboard/seats/grant",
    response_model=GrantSeatResponse,
    summary="Grant a sponsored seat to student",
)
@router.post(
    "/admin/sponsored-seats",
    response_model=GrantSeatResponse,
    summary="Grant a sponsored seat to student",
)
async def post_grant_sponsored_seat(
    input_data: GrantSeatInput,
    institution_id: Optional[int] = Query(None),
    admin: CurrentAdminContext = Depends(get_admin_context),
    db: AsyncSession = Depends(get_db),
):
    """Grant a subsidized or sponsored seat funded by institution budget or scholarship pool."""
    target_inst = admin.institution_id if admin.is_institution_admin else (institution_id or 1)
    async with transaction_scope(db):
        res = await InstitutionService.grant_sponsored_seat(
            session=db,
            institution_id=target_inst,
            student_email=input_data.student_email,
            plan_code=input_data.plan_code,
            funding_source=input_data.funding_source,
        )
    return res
