from fastapi import APIRouter, WebSocket, Request, Response
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["payments"])

@router.post("/subscriptions", summary="Create checkout subscription in Razorpay test mode")
async def post_subscriptions():
    raise ModuleNotImplemented("/subscriptions")

@router.post("/subscriptions/cancel", summary="Cancel current active subscription")
async def post_subscriptions_cancel():
    raise ModuleNotImplemented("/subscriptions/cancel")

@router.post("/webhooks/razorpay", summary="Handle Razorpay payment and refund webhooks")
async def post_webhooks_razorpay():
    raise ModuleNotImplemented("/webhooks/razorpay")
