import uuid
from pydantic import BaseModel


class GiverProfileUpdate(BaseModel):
    headline: str
    bio: str | None = None
    expertise_domains: list[str] = []
    capacity_weekly: int = 2


class GiverPublicResponse(BaseModel):
    id: uuid.UUID
    full_name: str
    headline: str
    institution_id: uuid.UUID | None = None
    band: str
    smoothed_rating: float
    expertise_domains: list[str] = []
