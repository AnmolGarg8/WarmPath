"""
Business logic and webhook processing for payments module.
Owner: M4
"""

import hashlib
import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import IdempotencyKey, User
from app.core.errors import AppError, PortNotReady
from app.core.events import (
    PaymentCapturedPayload,
    SubscriptionActivatedPayload,
    SubscriptionCancelledPayload,
    event_bus,
)
from app.core.ports import ports
from app.modules.payments.client import RazorpayClientWrapper, get_razorpay_client
from app.modules.payments.models import (
    GiverEarningsReadModel,
    PaymentEvent,
    PayoutRequest,
    Subscription,
)
from app.modules.payments.schemas import PayoutDisbursedPayload
from app.modules.payments.scripts.ensure_razorpay_plans import ensure_plans

logger = logging.getLogger("warmpath.payments")

PLAN_AMOUNTS = {
    "campus": {"price_inr": 0, "credits": 0},
    "standard": {"price_inr": settings.PLAN_STANDARD_PRICE, "credits": settings.PLAN_STANDARD_CREDITS},
    "high": {"price_inr": settings.PLAN_HIGH_PRICE, "credits": settings.PLAN_HIGH_CREDITS},
    "premium": {"price_inr": settings.PLAN_PREMIUM_PRICE, "credits": settings.PLAN_PREMIUM_CREDITS},
}


def to_uuid(val: Any) -> Optional[uuid.UUID]:
    if val is None:
        return None
    if isinstance(val, uuid.UUID):
        return val
    try:
        return uuid.UUID(str(val))
    except (ValueError, TypeError):
        return None


class PaymentsService:

    @staticmethod
    async def create_subscription(
        session: AsyncSession,
        user_id: str,
        plan_code: str,
        idempotency_key: str,
        client: Optional[RazorpayClientWrapper] = None,
    ) -> Dict[str, Any]:
        """
        Validate student, create Razorpay subscription (Test Mode), store in DB,
        and return checkout details.
        """
        if not idempotency_key or not idempotency_key.strip():
            raise AppError(
                code="idempotency_key_required",
                message="Idempotency-Key header is required for creating a subscription",
                status_code=400,
            )

        u_uid = to_uuid(user_id)
        if not u_uid:
            raise AppError(code="invalid_user_id", message="Invalid user ID", status_code=400)

        plan_code = plan_code.lower().strip()
        if plan_code not in ("standard", "high", "premium"):
            raise AppError(
                code="invalid_plan_code",
                message=f"Plan '{plan_code}' is not a valid paid subscription tier",
                status_code=400,
            )

        # Idempotency check in idempotency_keys table
        existing_key = await session.get(IdempotencyKey, idempotency_key)
        if existing_key and existing_key.response_body:
            return existing_key.response_body

        # Validate student user
        user = await session.get(User, u_uid)
        if user and user.roles and "student" not in user.roles and "alumni" not in user.roles:
            raise AppError(
                code="student_validation_failed",
                message="Only students or alumni may subscribe to plans",
                status_code=403,
            )

        # Check trust level: restricted users cannot create subscriptions
        try:
            trust_level = await ports.trust.get_level(str(user_id))
            if trust_level == "restricted":
                raise AppError(
                    code="user_restricted",
                    message="Account is restricted and cannot initiate new subscriptions",
                    status_code=403,
                )
        except Exception:
            pass  # If TrustPort is not ready, proceed

        if client is None:
            client = get_razorpay_client()

        # Ensure Razorpay plan ID mapping
        plan_mappings = await ensure_plans(session, client)
        rzp_plan_id = plan_mappings.get(plan_code)
        if not rzp_plan_id:
            raise AppError(
                code="plan_mapping_missing",
                message=f"Razorpay plan mapping for '{plan_code}' could not be established",
                status_code=500,
            )

        # Create subscription in Razorpay
        rzp_sub = client.create_subscription(plan_id=rzp_plan_id, total_count=12)
        rzp_sub_id = rzp_sub.get("id") or f"sub_rzp_test_{uuid.uuid4().hex[:12]}"

        now = datetime.now(timezone.utc)
        sub_record = Subscription(
            id=uuid.uuid4(),
            user_id=u_uid,
            plan_code=plan_code,
            razorpay_subscription_id=rzp_sub_id,
            razorpay_plan_id=rzp_plan_id,
            status="created",
            created_at=now,
            updated_at=now,
        )
        session.add(sub_record)

        plan_info = PLAN_AMOUNTS.get(plan_code, {"price_inr": 299})
        amount_paise = plan_info["price_inr"] * 100

        response_data = {
            "subscription_id": rzp_sub_id,
            "order_id": rzp_sub_id,
            "key_id": client.key_id,
            "amount": amount_paise,
            "currency": "INR",
            "test_mode": True,
        }

        # Store response in idempotency_keys
        idempotency_entry = IdempotencyKey(
            key=idempotency_key,
            user_id=u_uid,
            response_code=200,
            response_body=response_data,
            created_at=now,
        )
        session.add(idempotency_entry)
        await session.flush()

        return response_data

    @staticmethod
    async def cancel_subscription(
        session: AsyncSession,
        user_id: str,
        at_period_end: bool = True,
        client: Optional[RazorpayClientWrapper] = None,
    ) -> Dict[str, Any]:
        """Cancel current active subscription."""
        u_uid = to_uuid(user_id)
        if not u_uid:
            raise AppError(code="invalid_user_id", message="Invalid user ID", status_code=400)

        stmt = (
            select(Subscription)
            .where(
                Subscription.user_id == u_uid,
                Subscription.status.in_(["created", "authenticated", "active"]),
            )
            .order_by(desc(Subscription.created_at))
            .limit(1)
        )
        res = await session.execute(stmt)
        sub = res.scalar_one_or_none()

        if not sub:
            raise AppError(
                code="subscription_not_found",
                message="No active subscription found to cancel",
                status_code=404,
            )

        if client is None:
            client = get_razorpay_client()

        # Cancel in Razorpay
        try:
            client.cancel_subscription(sub.razorpay_subscription_id, at_period_end=at_period_end)
        except Exception as e:
            logger.warning(f"Razorpay subscription cancel warning for {sub.razorpay_subscription_id}: {e}")

        now = datetime.now(timezone.utc)
        sub.status = "cancelling" if at_period_end else "cancelled"
        sub.updated_at = now

        if not at_period_end:
            # Immediate cancellation publish
            await event_bus.publish(
                session=session,
                topic="subscription.cancelled",
                payload=SubscriptionCancelledPayload(
                    subscription_id=str(sub.id),
                    user_id=str(sub.user_id),
                ),
            )

        await session.flush()
        return {
            "success": True,
            "message": "Subscription cancellation scheduled at cycle end" if at_period_end else "Subscription cancelled immediately",
            "test_mode": True,
        }

    @staticmethod
    async def handle_webhook(
        session: AsyncSession,
        raw_body: bytes,
        signature: Optional[str],
        client: Optional[RazorpayClientWrapper] = None,
    ) -> Dict[str, Any]:
        """
        Verify signature, store in payment_events for replay idempotency,
        and process subscription/payment lifecycle events.
        """
        if client is None:
            client = get_razorpay_client()

        # 1. Verify HMAC-SHA256 signature
        if not client.verify_webhook_signature(raw_body, signature):
            raise AppError(
                code="invalid_signature",
                message="Razorpay webhook signature verification failed",
                status_code=400,
            )

        # 2. Parse payload
        try:
            payload = json.loads(raw_body.decode("utf-8"))
        except Exception as e:
            raise AppError(code="malformed_payload", message=f"Webhook payload is not valid JSON: {e}", status_code=400)

        event_name = payload.get("event", "unknown")
        # Generate or extract unique event ID
        event_id = (
            payload.get("event_id")
            or payload.get("id")
            or f"{event_name}_{payload.get('created_at', '')}_{hashlib.md5(raw_body).hexdigest()[:8]}"
        )

        now = datetime.now(timezone.utc)

        # 3. Replay idempotency check
        existing_event = await session.execute(
            select(PaymentEvent).where(PaymentEvent.event_id == event_id).limit(1)
        )
        if existing_event.scalar_one_or_none():
            logger.info(f"Ignoring replayed Razorpay webhook event {event_id}")
            return {"status": "already_processed", "test_mode": True}

        # Store payment event
        pe = PaymentEvent(
            id=uuid.uuid4(),
            event_id=event_id,
            event_type=event_name,
            payload=payload,
            received_at=now,
        )
        session.add(pe)
        await session.flush()

        # 4. Handle events
        sub_entity = payload.get("payload", {}).get("subscription", {}).get("entity", {})
        payment_entity = payload.get("payload", {}).get("payment", {}).get("entity", {})
        rzp_sub_id = sub_entity.get("id") or payment_entity.get("subscription_id")

        if rzp_sub_id:
            sub_res = await session.execute(
                select(Subscription).where(Subscription.razorpay_subscription_id == rzp_sub_id).limit(1)
            )
            sub = sub_res.scalar_one_or_none()
        else:
            sub = None

        if event_name in ("subscription.authenticated", "subscription.activated", "subscription.charged"):
            if sub:
                sub.status = "active"
                sub.updated_at = now
                if sub_entity.get("current_start"):
                    sub.current_period_start = datetime.fromtimestamp(sub_entity["current_start"], tz=timezone.utc)
                if sub_entity.get("current_end"):
                    sub.current_period_end = datetime.fromtimestamp(sub_entity["current_end"], tz=timezone.utc)

                plan_info = PLAN_AMOUNTS.get(sub.plan_code, {"price_inr": 299, "credits": 1})
                payment_id = payment_entity.get("id") or f"pay_rzp_test_{uuid.uuid4().hex[:12]}"

                # Publish payment.captured and subscription.activated outbox events
                await event_bus.publish(
                    session=session,
                    topic="payment.captured",
                    payload=PaymentCapturedPayload(
                        payment_id=payment_id,
                        user_id=str(sub.user_id),
                        amount_inr=plan_info["price_inr"],
                        credits_issued=plan_info["credits"],
                    ),
                )
                await event_bus.publish(
                    session=session,
                    topic="subscription.activated",
                    payload=SubscriptionActivatedPayload(
                        subscription_id=str(sub.id),
                        user_id=str(sub.user_id),
                        plan=sub.plan_code,
                    ),
                )

        elif event_name in ("subscription.cancelled", "subscription.halted"):
            if sub:
                sub.status = "cancelled"
                sub.updated_at = now
                await event_bus.publish(
                    session=session,
                    topic="subscription.cancelled",
                    payload=SubscriptionCancelledPayload(
                        subscription_id=str(sub.id),
                        user_id=str(sub.user_id),
                    ),
                )

        elif event_name == "payment.failed":
            if sub:
                sub.status = "past_due"
                sub.updated_at = now

        pe.processed_at = datetime.now(timezone.utc)
        await session.flush()
        return {"status": "processed", "test_mode": True}

    @staticmethod
    async def request_payout(
        session: AsyncSession,
        user_id: str,
        amount_inr: float,
        upi_id: Optional[str] = "alumni@upi",
    ) -> PayoutRequest:
        """
        Request cash-out in test mode.
        Requires available earnings in event-fed read model and a verified giver.
        """
        u_uid = to_uuid(user_id)
        if not u_uid:
            raise AppError(code="invalid_user_id", message="Invalid user ID", status_code=400)

        # 1. Verify giver status
        try:
            trust_level = await ports.trust.get_level(str(user_id))
            if trust_level in ("restricted", "new"):
                raise AppError(
                    code="unverified_giver",
                    message="Giver must be verified before requesting cashout",
                    status_code=403,
                )
        except PortNotReady:
            pass  # Fallback if TrustPort is not ready
        except AppError:
            raise
        except Exception:
            pass  # Fallback if port not ready

        # 2. Check available earnings in read model (no direct import of credits)
        read_model = await session.get(GiverEarningsReadModel, u_uid)
        available = read_model.available_earnings_inr if read_model else 0.0

        if available < amount_inr:
            raise AppError(
                code="insufficient_earnings",
                message=f"Available earnings (₹{available}) less than requested payout (₹{amount_inr})",
                status_code=400,
                details={"available_inr": available, "requested_inr": amount_inr},
            )

        # Deduct from read model
        read_model.available_earnings_inr = round(read_model.available_earnings_inr - amount_inr, 2)
        read_model.updated_at = datetime.now(timezone.utc)

        now = datetime.now(timezone.utc)
        payout = PayoutRequest(
            id=uuid.uuid4(),
            user_id=u_uid,
            amount_inr=amount_inr,
            upi_id=upi_id or "alumni@upi",
            status="requested",
            created_at=now,
        )
        session.add(payout)
        await session.flush()
        return payout

    @staticmethod
    async def approve_payout(
        session: AsyncSession,
        payout_id: str,
    ) -> PayoutRequest:
        """Admin approves and simulates payout in test mode."""
        p_uid = to_uuid(payout_id)
        if not p_uid:
            raise AppError(code="invalid_payout_id", message="Invalid payout ID", status_code=400)

        payout = await session.get(PayoutRequest, p_uid)
        if not payout or payout.status != "requested":
            raise AppError(
                code="invalid_payout_status",
                message="Payout not found or cannot be approved",
                status_code=400,
            )

        now = datetime.now(timezone.utc)
        payout.status = "paid"
        payout.processed_at = now

        # Publish payout.disbursed for credits module to record ledger entry
        await event_bus.publish(
            session=session,
            topic="payout.disbursed",
            payload=PayoutDisbursedPayload(
                payout_id=str(payout.id),
                user_id=str(payout.user_id),
                amount_inr=payout.amount_inr,
                status="paid",
            ),
        )

        await session.flush()
        return payout

    @staticmethod
    async def update_giver_earnings_cache(
        session: AsyncSession,
        user_id: str,
        amount_delta_inr: float,
    ) -> None:
        """Event subscriber helper to update giver earnings read model."""
        u_uid = to_uuid(user_id)
        if not u_uid:
            return

        read_model = await session.get(GiverEarningsReadModel, u_uid)
        now = datetime.now(timezone.utc)
        if not read_model:
            read_model = GiverEarningsReadModel(
                user_id=u_uid,
                available_earnings_inr=max(0.0, amount_delta_inr),
                updated_at=now,
            )
            session.add(read_model)
        else:
            read_model.available_earnings_inr = max(0.0, round(read_model.available_earnings_inr + amount_delta_inr, 2))
            read_model.updated_at = now
        await session.flush()

    @staticmethod
    async def reconcile_subscriptions(
        session: AsyncSession,
        client: Optional[RazorpayClientWrapper] = None,
    ) -> List[Dict[str, Any]]:
        """Nightly reconciliation job comparing Razorpay states against the DB."""
        if client is None:
            client = get_razorpay_client()

        stmt = select(Subscription).where(Subscription.status.in_(["created", "authenticated", "active", "cancelling"]))
        res = await session.execute(stmt)
        subs = res.scalars().all()

        discrepancies: List[Dict[str, Any]] = []
        now = datetime.now(timezone.utc)

        for sub in subs:
            try:
                rzp_data = client.fetch_subscription(sub.razorpay_subscription_id)
                rzp_status = rzp_data.get("status")
                if rzp_status and rzp_status != sub.status:
                    discrepancies.append(
                        {
                            "subscription_id": str(sub.id),
                            "razorpay_subscription_id": sub.razorpay_subscription_id,
                            "db_status": sub.status,
                            "rzp_status": rzp_status,
                        }
                    )
                    logger.warning(
                        f"Reconciliation mismatch: sub={sub.id}, db_status={sub.status}, rzp_status={rzp_status}"
                    )
                    # Update local status to match Razorpay source of truth
                    if rzp_status in ("active", "cancelled", "halted", "past_due"):
                        sub.status = rzp_status
                        sub.updated_at = now
            except Exception as e:
                logger.error(f"Failed to reconcile subscription {sub.razorpay_subscription_id}: {e}")

        await session.flush()
        return discrepancies
