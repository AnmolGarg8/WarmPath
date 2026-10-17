"""
FastAPI router for credits endpoints.
Owner: M4
Endpoints:
  - GET /plans
  - GET /me/subscription
  - GET /me/wallet
  - GET /me/earnings
  - POST /me/cashout
  - POST /me/donate-credits
  - GET /sponsored-seats
  - POST /admin/sponsored-seats
"""

import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Header, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import decode_token
from app.modules.credits.models import Plan, SponsoredSeat
from app.modules.credits.schemas import (
    AdminSponsoredSeatRequest,
    AdminSponsoredSeatResponse,
    CashoutRequest,
    CashoutResponse,
    DonateCreditsRequest,
    DonateCreditsResponse,
    EarningsResponse,
    PlanResponse,
    PlansListResponse,
    SponsoredSeatInfo,
    SponsoredSeatsEligibilityResponse,
    SubscriptionResponse,
    WalletResponse,
)
from app.modules.credits.service import CreditsService

router = APIRouter(tags=["credits"])


async def get_current_user_id(
    authorization: Optional[str] = Header(None),
    x_user_id: Optional[str] = Header(None),
) -> str:
    """Resolve current user ID from JWT bearer token or X-User-Id header."""
    if authorization and authorization.startswith("Bearer "):
        token = authorization[len("Bearer "):]
        payload = decode_token(token)
        return payload.get("sub", "")
    if x_user_id:
        return x_user_id
    # Default deterministic mock user ID for local tests/development
    return "00000000-0000-0000-0000-000000000001"


@router.get("/plans", response_model=PlansListResponse, summary="List subscription plans and credit allowances")
async def get_plans(db: AsyncSession = Depends(get_db)):
    """Return all active plans with plain-language feature lines."""
    await CreditsService.seed_plans_if_empty(db)
    result = await db.execute(select(Plan).where(Plan.active.is_(True)).order_by(Plan.priority.asc()))
    plans = result.scalars().all()
    return PlansListResponse(
        plans=[
            PlanResponse(
                id=p.id,
                code=p.code,
                name=p.name,
                price_inr=p.price_inr,
                credits_per_month=p.credits_per_month,
                reach_bands=p.reach_bands or [],
                booking_horizon_days=p.booking_horizon_days,
                priority=p.priority,
                features=p.features or [],
                active=p.active,
            )
            for p in plans
        ]
    )


@router.get("/me/subscription", response_model=SubscriptionResponse, summary="Get authenticated user active subscription")
async def get_me_subscription(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Return authenticated user's active plan, period, credits left and renewal date."""
    sub_data = await CreditsService.get_subscription(db, user_id)
    return SubscriptionResponse(**sub_data)


@router.get("/me/wallet", response_model=WalletResponse, summary="Get credit balance and transaction history")
async def get_me_wallet(
    cursor: Optional[str] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Return paid credits, affinity credits, and cursor-paginated ledger entries."""
    wallet_data = await CreditsService.get_wallet(db, user_id=user_id, cursor=cursor, limit=limit)
    return WalletResponse(**wallet_data)


@router.get("/me/earnings", response_model=EarningsResponse, summary="Get earned credits and cashout availability")
async def get_me_earnings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Return giver earnings breakdown (cashable, escrowed in window, and paid out)."""
    earnings_data = await CreditsService.get_earnings(db, user_id)
    return EarningsResponse(**earnings_data)


@router.post("/me/cashout", response_model=CashoutResponse, summary="Request cashout for earned session credits")
async def post_me_cashout(
    req: CashoutRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Initiate cashout of earned session funds to UPI ID."""
    async with db.begin():
        payout = await CreditsService.cashout(
            session=db,
            user_id=user_id,
            amount_inr=req.amount_inr,
            upi_id=req.upi_id,
        )
    return CashoutResponse(payout_id=str(payout.id), status=payout.status)


@router.post("/me/donate-credits", response_model=DonateCreditsResponse, summary="Donate earned credits to scholarship pool")
async def post_me_donate_credits(
    req: DonateCreditsRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Donate earned credits to subsidized student scholarship pool."""
    async with db.begin():
        donated = await CreditsService.donate_credits(
            session=db,
            user_id=user_id,
            credits_to_donate=req.credits,
        )
    return DonateCreditsResponse(donated_credits=donated)


@router.get("/sponsored-seats", response_model=SponsoredSeatsEligibilityResponse, summary="Check sponsored seat availability")
async def get_sponsored_seats(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Check if student qualifies for or holds sponsored seats."""
    try:
        u_uid = uuid.UUID(user_id) if isinstance(user_id, str) else user_id
    except ValueError:
        u_uid = uuid.uuid4()

    res = await db.execute(select(SponsoredSeat).where(SponsoredSeat.student_id == u_uid))
    seats = res.scalars().all()
    eligible = len(seats) > 0
    seat_type = seats[0].plan_tier if eligible else None
    return SponsoredSeatsEligibilityResponse(
        eligible=eligible,
        seat_type=seat_type,
        seats=[
            SponsoredSeatInfo(
                id=str(s.id),
                institution_id=s.institution_id,
                student_id=str(s.student_id),
                plan_tier=s.plan_tier,
                sponsor_name=s.sponsor_name,
                funded_by=s.funded_by,
                created_at=s.created_at,
            )
            for s in seats
        ],
    )


@router.post("/admin/sponsored-seats", response_model=AdminSponsoredSeatResponse, summary="Allocate sponsored seats for institution")
async def post_admin_sponsored_seats(
    req: AdminSponsoredSeatRequest,
    db: AsyncSession = Depends(get_db),
):
    """Grant a plan to a student funded by sponsor, institution budget or scholarship pool."""
    async with db.begin():
        seat = await CreditsService.allocate_sponsored_seat(
            session=db,
            student_id=req.student_id,
            plan_tier=req.plan_tier,
            sponsor_name=req.sponsor_name,
            funded_by=req.funded_by or "scholarship_pool",
        )
    return AdminSponsoredSeatResponse(
        success=True,
        message=f"Sponsored seat '{req.plan_tier}' allocated successfully (ID: {seat.id})",
    )
