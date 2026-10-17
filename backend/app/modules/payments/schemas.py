"""
Pydantic schemas for payments module.
Owner: M4
"""

from typing import Any, Dict, Optional
from pydantic import BaseModel, Field


class CreateSubscriptionRequest(BaseModel):
    plan_code: Optional[str] = None
    plan_tier: Optional[str] = None

    def resolved_plan(self) -> str:
        code = self.plan_code or self.plan_tier
        if not code:
            raise ValueError("Either plan_code or plan_tier must be provided")
        return code.lower().strip()


class CreateSubscriptionResponse(BaseModel):
    subscription_id: str
    order_id: str
    key_id: str
    amount: int
    currency: str = "INR"
    test_mode: bool = True


class CancelSubscriptionRequest(BaseModel):
    at_period_end: bool = True


class CancelSubscriptionResponse(BaseModel):
    success: bool = True
    message: str = "Subscription cancellation requested"
    test_mode: bool = True


class WebhookResponse(BaseModel):
    status: str
    test_mode: bool = True


class PayoutRequestInput(BaseModel):
    amount_inr: float = Field(..., gt=0)
    upi_id: Optional[str] = "alumni@upi"


class PayoutRequestResponse(BaseModel):
    payout_id: str
    status: str
    amount_inr: float
    message: str
    test_mode: bool = True


class ApprovePayoutResponse(BaseModel):
    success: bool
    status: str
    test_mode: bool = True


class PayoutDisbursedPayload(BaseModel):
    payout_id: str
    user_id: str
    amount_inr: float
    status: str = "paid"
