"""
Pydantic schemas for institution dashboard endpoints.
Owner: M4
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class AccessReachItem(BaseModel):
    student_institution_id: int
    giver_institution_id: int
    session_count: int
    student_count: int
    giver_count: int
    last_activity_at: Optional[datetime] = None


class DashboardOverviewResponse(BaseModel):
    requests_posted: int
    requests_fulfilled: int
    requests_declined: int
    requests_expired: int
    fulfillment_rate: float
    average_first_response_hours: float
    sessions_completed: int
    average_rating: float
    active_givers: int
    active_students: int
    repeat_givers: int
    sponsored_seat_usage: int
    cross_college_share: float
    own_college_share: float
    access_reach: List[AccessReachItem] = []
    cached: bool = False
    from_date: Optional[str] = None
    to_date: Optional[str] = None


class SkillGapItem(BaseModel):
    skill: str
    category: str = "skill"
    demand_count: int
    supply_count: int
    gap_score: int
    status: str  # critical_gap, moderate_gap, balanced, surplus
    recommendation: str


class SkillGapResponse(BaseModel):
    items: List[SkillGapItem]
    total_demand: int
    total_supply: int
    critical_gaps_count: int
    cached: bool = False


class SafetySummaryResponse(BaseModel):
    reports_received: int
    reports_resolved: int
    resolution_rate: float
    average_resolution_hours: float
    target_resolution_hours: float = 24.0
    scam_messages_blocked: int
    disputes_opened: int
    disputes_resolved: int
    status: str  # on_track, attention_needed
    cached: bool = False


class SeatGrantItem(BaseModel):
    id: str
    student_email_masked: str
    plan_code: str
    funding_source: str
    granted_at: datetime


class SeatsResponse(BaseModel):
    sponsored_seats_granted: int
    total_budget_inr: float
    remaining_budget_inr: float
    scholarship_pool_balance: float
    donations_count: int
    donations_amount_inr: float
    recent_grants: List[SeatGrantItem] = []
    cached: bool = False


class GrantSeatInput(BaseModel):
    student_email: str
    plan_code: str = "standard"
    funding_source: str = "Institution Budget"  # Institution Budget, Scholarship Pool, Corporate CSR


class GrantSeatResponse(BaseModel):
    success: bool
    grant_id: str
    student_email_masked: str
    plan_code: str
    funding_source: str
    remaining_budget_inr: float
