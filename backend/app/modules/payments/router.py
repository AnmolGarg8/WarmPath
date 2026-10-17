from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["payments"])


@router.post("/subscriptions")
async def create_subscription():
    raise ModuleNotImplemented("POST /subscriptions")


@router.post("/subscriptions/cancel")
async def cancel_subscription():
    raise ModuleNotImplemented("POST /subscriptions/cancel")


@router.post("/webhooks/razorpay")
async def handle_razorpay_webhook():
    raise ModuleNotImplemented("POST /webhooks/razorpay")
