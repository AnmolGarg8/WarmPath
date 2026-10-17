import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


# --- Giver Profile Schemas ---

class GiverProfileCreateUpdate(BaseModel):
    offers: List[str] = Field(
        default_factory=list,
        description="Help types offered: resume_review, mock_interview, referral_advice, career_guidance, project_feedback, domain_talk",
    )
    topics: List[str] = Field(default_factory=list)
    skills: List[Dict[str, Any]] = Field(default_factory=list)
    domains: List[str] = Field(default_factory=list)
    company: Optional[str] = Field(None, max_length=255)
    role_title: Optional[str] = Field(None, max_length=255)
    bio: Optional[str] = Field(None, max_length=2000)
    languages: List[str] = Field(default_factory=lambda: ["English"])
    weekly_capacity: int = Field(default=3, ge=1, le=20)
    institution_id: Optional[int] = None
    department: Optional[str] = Field(None, max_length=100)
    batch: Optional[int] = None
    societies: List[str] = Field(default_factory=list)


class GiverProfileResponse(BaseModel):
    user_id: uuid.UUID
    offers: List[str]
    topics: List[str]
    skills: List[Dict[str, Any]]
    domains: List[str]
    company: Optional[str] = None
    role_title: Optional[str] = None
    bio: Optional[str] = None
    languages: List[str]
    weekly_capacity: int
    institution_id: Optional[int] = None
    department: Optional[str] = None
    batch: Optional[int] = None
    societies: List[str]
    has_embedding: bool
    response_stats: Dict[str, Any]
    created_at: datetime
    updated_at: datetime


# --- Scoring & Explainability Schemas ---

class ScoreComponents(BaseModel):
    expertise_fit: float = Field(..., ge=0.0, le=1.0)
    intent_fit: float = Field(..., ge=0.0, le=1.0)
    affinity: float = Field(..., ge=0.0, le=1.0)
    availability: float = Field(..., ge=0.0, le=1.0)
    rating: float = Field(..., ge=0.0, le=1.0)
    response_odds: float = Field(..., ge=0.0, le=1.0)
    cold_start_boost: float = Field(default=0.0, ge=0.0)
    total_score: float = Field(..., ge=0.0, le=1.0)


class RatingSummary(BaseModel):
    band: str = "Rising"
    smoothed_avg: float = 4.0
    total_sessions: int = 0
    completion_rate: float = 1.0


class AvailabilitySummary(BaseModel):
    online: bool = False
    capacity_left: int = 3


# --- Public Giver Card & Feed Schemas ---

class GiverPublicCard(BaseModel):
    id: uuid.UUID
    full_name: str
    headline: str
    company: Optional[str] = None
    role_title: Optional[str] = None
    bio: Optional[str] = None
    offers: List[str] = Field(default_factory=list)
    topics: List[str] = Field(default_factory=list)
    skills: List[Dict[str, Any]] = Field(default_factory=list)
    domains: List[str] = Field(default_factory=list)
    languages: List[str] = Field(default_factory=list)
    badges: List[str] = Field(default_factory=list)
    band: str = "Rising"
    rating_summary: RatingSummary
    availability_summary: AvailabilitySummary
    why_lines: List[str] = Field(default_factory=list)


class RecommendationItem(BaseModel):
    giver: GiverPublicCard
    score_components: ScoreComponents
    why_lines: List[str] = Field(default_factory=list)
    locked: bool = False
    lock_reason: Optional[str] = None


class RecommendationsResponse(BaseModel):
    items: List[RecommendationItem]
    next_cursor: Optional[str] = None
    scope: str
    locked: bool = False
    lock_reason: Optional[str] = None
