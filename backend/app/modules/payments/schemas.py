from pydantic import BaseModel


class SubscriptionCreateRequest(BaseModel):
    plan_tier: str  # Standard | High | Premium


class SubscriptionCancelRequest(BaseModel):
    reason: str | None = None
