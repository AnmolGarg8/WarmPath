from pydantic import BaseModel, Field


class RatingSubmitRequest(BaseModel):
    score: int = Field(ge=1, le=5)
    feedback: str | None = None


class RequestQualityRequest(BaseModel):
    clarity_score: int = Field(ge=1, le=5)
    preparation_score: int = Field(ge=1, le=5)


class DisputeCreateRequest(BaseModel):
    reason: str
    details: str


class DisputeResolveRequest(BaseModel):
    outcome: str  # release_to_giver | refund_to_student | split
    notes: str | None = None
