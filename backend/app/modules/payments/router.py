"""
FastAPI router for payments module.
Owner: M4
Endpoints:
  - POST /subscriptions
  - POST /subscriptions/cancel
  - POST /webhooks/razorpay
  - POST /payouts/request
  - POST /admin/payouts/{id}/approve
"""

from contextlib import asynccontextmanager
from typing import Optional
from fastapi import APIRouter, Depends, Header, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import decode_token
from app.modules.payments.schemas import (
    ApprovePayoutResponse,
    CancelSubscriptionRequest,
    CancelSubscriptionResponse,
    CreateSubscriptionRequest,
    CreateSubscriptionResponse,
    PayoutRequestInput,
    PayoutRequestResponse,
    WebhookResponse,
)
from app.modules.payments.service import PaymentsService

router = APIRouter(tags=["payments"])


@asynccontextmanager
async def transaction_scope(db: AsyncSession):
    """Safely scope transaction whether session already has an autobegun transaction or not."""
    if db.in_transaction():
        yield db
        await db.commit()
    else:
        async with db.begin():
            yield db


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
    return "00000000-0000-0000-0000-000000000001"


@router.post(
    "/subscriptions",
    response_model=CreateSubscriptionResponse,
    summary="Create checkout subscription in Razorpay test mode",
)
async def post_subscriptions(
    req: CreateSubscriptionRequest,
    idempotency_key: Optional[str] = Header(None, alias="Idempotency-Key"),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Initiate a Razorpay test-mode subscription checkout order."""
    if not idempotency_key or not idempotency_key.strip():
        raise AppError(
            code="idempotency_key_required",
            message="Idempotency-Key header is required",
            status_code=status.HTTP_400_BAD_REQUEST,
        )

    plan_code = req.resolved_plan()
    async with transaction_scope(db):
        res = await PaymentsService.create_subscription(
            session=db,
            user_id=user_id,
            plan_code=plan_code,
            idempotency_key=idempotency_key,
        )
    return CreateSubscriptionResponse(**res)


@router.post(
    "/subscriptions/cancel",
    response_model=CancelSubscriptionResponse,
    summary="Cancel current active subscription",
)
async def post_subscriptions_cancel(
    req: CancelSubscriptionRequest = CancelSubscriptionRequest(),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Cancel active subscription at period end or immediately."""
    async with transaction_scope(db):
        res = await PaymentsService.cancel_subscription(
            session=db,
            user_id=user_id,
            at_period_end=req.at_period_end,
        )
    return CancelSubscriptionResponse(**res)


@router.post(
    "/webhooks/razorpay",
    response_model=WebhookResponse,
    summary="Handle Razorpay payment and refund webhooks",
)
async def post_webhooks_razorpay(
    request: Request,
    x_razorpay_signature: Optional[str] = Header(None, alias="X-Razorpay-Signature"),
    db: AsyncSession = Depends(get_db),
):
    """Process inbound Razorpay webhooks with HMAC-SHA256 signature verification."""
    raw_body = await request.body()
    async with transaction_scope(db):
        res = await PaymentsService.handle_webhook(
            session=db,
            raw_body=raw_body,
            signature=x_razorpay_signature,
        )
    return WebhookResponse(**res)


@router.post(
    "/me/cashout",
    response_model=PayoutRequestResponse,
    summary="Request cashout simulation for verified giver",
)
@router.post(
    "/payouts/request",
    response_model=PayoutRequestResponse,
    summary="Request cashout simulation for verified giver",
)
async def post_payouts_request(
    req: PayoutRequestInput,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    """Request payout from available giver earnings in test mode."""
    async with transaction_scope(db):
        payout = await PaymentsService.request_payout(
            session=db,
            user_id=user_id,
            amount_inr=req.amount_inr,
            upi_id=req.upi_id,
        )
    return PayoutRequestResponse(
        payout_id=str(payout.id),
        status=payout.status,
        amount_inr=payout.amount_inr,
        message="Payout request recorded. In test mode, funds are simulated upon approval.",
        test_mode=True,
    )


@router.post(
    "/admin/payouts/{id}/approve",
    response_model=ApprovePayoutResponse,
    summary="Admin approves test mode payout request",
)
async def post_admin_payouts_approve(
    id: str,
    db: AsyncSession = Depends(get_db),
):
    """Admin simulates payout disbursement in test mode."""
    async with transaction_scope(db):
        payout = await PaymentsService.approve_payout(db, payout_id=id)
    return ApprovePayoutResponse(
        success=True,
        status=payout.status,
        test_mode=True,
    )
