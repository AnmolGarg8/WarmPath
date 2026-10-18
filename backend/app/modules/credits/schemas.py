"""
Pydantic schemas for credits module.
Owner: M4
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class PlanResponse(BaseModel):
    id: int
    code: str
    name: str
    price_inr: int
    credits_per_month: int
    reach_bands: List[str]
    booking_horizon_days: int
    priority: int
    features: List[str]
    active: bool


class PlansListResponse(BaseModel):
    plans: List[PlanResponse]


class SubscriptionResponse(BaseModel):
    plan_tier: str
    status: str
    renews_at: Optional[datetime] = None
    period_start: Optional[datetime] = None
    period_end: Optional[datetime] = None
    credits_remaining: int = 0


class LedgerEntryResponse(BaseModel):
    id: str
    txn_id: str
    amount_credits: int
    amount_inr: float
    direction: str
    reason: str
    plain_reason: str
    ref_type: str
    ref_id: str
    created_at: datetime


class WalletResponse(BaseModel):
    available_credits: int
    affinity_credits: int
    items: List[LedgerEntryResponse] = []
    next_cursor: Optional[str] = None


class EarningsResponse(BaseModel):
    cashable_balance_inr: float
    held_in_escrow_inr: float
    paid_out_inr: float
    total_earned_inr: float
    by_band_payout_share: Dict[str, float]


class CashoutRequest(BaseModel):
    amount_inr: float = Field(..., gt=0)
    upi_id: str = Field(..., min_length=3)


class CashoutResponse(BaseModel):
    payout_id: str
    status: str


class DonateCreditsRequest(BaseModel):
    credits: int = Field(..., gt=0)


class DonateCreditsResponse(BaseModel):
    donated_credits: int


class SponsoredSeatInfo(BaseModel):
    id: str
    institution_id: Optional[int] = None
    student_id: Optional[str] = None
    plan_tier: str
    sponsor_name: Optional[str] = None
    funded_by: str
    created_at: datetime
    status: str = "available"
    credits_granted: int = 1
    credits_remaining: int = 1
    can_claim: bool = False


class ClaimSponsoredSeatResponse(BaseModel):
    success: bool
    message: str
    credits_granted: int


class SponsoredSeatsEligibilityResponse(BaseModel):
    eligible: bool
    seat_type: Optional[str] = None
    seats: List[SponsoredSeatInfo] = []


class AdminSponsoredSeatRequest(BaseModel):
    student_id: str
    plan_tier: str
    sponsor_name: Optional[str] = None
    funded_by: Optional[str] = "scholarship_pool"


class AdminSponsoredSeatResponse(BaseModel):
    success: bool
    message: str
