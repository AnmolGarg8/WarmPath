from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

class StudentRatingCreate(BaseModel):
    stars: int = Field(..., ge=1, le=5)
    reason: Optional[str] = Field(None, max_length=1000)
    tags: List[str] = Field(default_factory=list)

class StudentRatingResponse(BaseModel):
    id: str
    session_id: str
    student_id: str
    giver_id: str
    stars: int
    reason: Optional[str] = None
    tags: List[str] = []
    created_at: datetime

class RequestQualityCreate(BaseModel):
    stars: int = Field(..., ge=1, le=5)
    note: Optional[str] = Field(None, max_length=1000)

class RequestQualityResponse(BaseModel):
    id: str
    session_id: str
    stars: int
    note: Optional[str] = None
    created_at: datetime

class DisputeCreate(BaseModel):
    reason: str = Field(..., description="no_show, low_effort, abusive, other")
    details: str = Field(..., min_length=10, max_length=2000)

class DisputeResponse(BaseModel):
    id: str
    session_id: str
    opened_by_user_id: str
    reason: str
    details: str
    status: str
    decision: Optional[str] = None
    resolution_note: Optional[str] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None

class DisputeResolveRequest(BaseModel):
    decision: str = Field(..., description="refund, partial_payout, full_payout, restrict_giver, dismiss")
    note: Optional[str] = Field(None, max_length=1000)

class RatingSummaryResponse(BaseModel):
    giver_id: str
    current_band: str
    smoothed_average: float
    rated_sessions_count: int
    completion_rate: float
    distribution: Dict[str, int]
    recent_reviews: List[Dict[str, Any]]

class MeBandResponse(BaseModel):
    giver_id: str
    current_band: str
    smoothed_average: float
    rated_sessions_count: int
    completion_rate: float
    payout_share: float
    next_band: Optional[str] = None
    progress_notes: str
