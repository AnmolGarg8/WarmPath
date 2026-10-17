import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

# --- Giver Profile Schemas ---

class GiverProfileCreateUpdate(BaseModel):
    offers: list[str] = Field(
        default_factory=list,
        description="Help types offered: resume_review, mock_interview, referral_advice, career_guidance, project_feedback, domain_talk",
    )
    topics: list[str] = Field(default_factory=list)
    skills: list[dict[str, Any]] = Field(default_factory=list)
    domains: list[str] = Field(default_factory=list)
    company: str | None = Field(None, max_length=255)
    role_title: str | None = Field(None, max_length=255)
    bio: str | None = Field(None, max_length=2000)
    languages: list[str] = Field(default_factory=lambda: ["English"])
    weekly_capacity: int = Field(default=3, ge=1, le=20)
    institution_id: int | None = None
    department: str | None = Field(None, max_length=100)
    batch: int | None = None
    societies: list[str] = Field(default_factory=list)


class GiverProfileResponse(BaseModel):
    user_id: uuid.UUID
    offers: list[str]
    topics: list[str]
    skills: list[dict[str, Any]]
    domains: list[str]
    company: str | None = None
    role_title: str | None = None
    bio: str | None = None
    languages: list[str]
    weekly_capacity: int
    institution_id: int | None = None
    department: str | None = None
    batch: int | None = None
    societies: list[str]
    has_embedding: bool
    response_stats: dict[str, Any]
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
    company: str | None = None
    role_title: str | None = None
    bio: str | None = None
    offers: list[str] = Field(default_factory=list)
    topics: list[str] = Field(default_factory=list)
    skills: list[dict[str, Any]] = Field(default_factory=list)
    domains: list[str] = Field(default_factory=list)
    languages: list[str] = Field(default_factory=list)
    badges: list[str] = Field(default_factory=list)
    band: str = "Rising"
    rating_summary: RatingSummary
    availability_summary: AvailabilitySummary
    why_lines: list[str] = Field(default_factory=list)


class RecommendationItem(BaseModel):
    giver: GiverPublicCard
    score_components: ScoreComponents
    why_lines: list[str] = Field(default_factory=list)
    locked: bool = False
    lock_reason: str | None = None


class RecommendationsResponse(BaseModel):
    items: list[RecommendationItem]
    next_cursor: str | None = None
    scope: str
    locked: bool = False
    lock_reason: str | None = None
