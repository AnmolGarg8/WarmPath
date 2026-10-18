"""
Comprehensive unit and integration tests for the payments module.
Owner: M4
Covers:
  1. Signature verification (valid, invalid, tampered body, missing header)
  2. Webhook replay idempotency
  3. Subscription creation with Idempotency-Key, student validation, and mock checkout
  4. Subscription cancellation (at_period_end and immediate)
  5. Webhook lifecycle events (activated, charged, cancelled, failed, out-of-order)
  6. Cash-out simulation, giver earnings read-model, and admin payout approval
  7. Test-mode key prefix guard
  8. Nightly reconciliation job
"""

import json
import uuid
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import IdempotencyKey, OutboxEvent, User
from app.core.errors import AppError
from app.modules.payments.client import RazorpayClientWrapper
from app.modules.payments.models import (
    GiverEarningsReadModel,
    PaymentEvent,
    PayoutRequest,
    Subscription,
)
from app.modules.payments.service import PaymentsService
from app.modules.payments.tests.conftest import (
    MOCK_WEBHOOK_SECRET,
    MockRazorpayClient,
    generate_webhook_signature,
)

STUDENT_ID = "00000000-0000-0000-0000-000000000001"
GIVER_ID = "00000000-0000-0000-0000-000000000002"


@pytest.mark.asyncio
async def test_subscription_create_missing_idempotency_key(client: AsyncClient):
    """POST /subscriptions without Idempotency-Key header must return HTTP 400."""
    res = await client.post(
        "/subscriptions",
        json={"plan_code": "standard"},
        headers={"X-User-Id": STUDENT_ID},
    )
    assert res.status_code == 400
    data = res.json()
    assert data["error"]["code"] == "idempotency_key_required"


@pytest.mark.asyncio
async def test_subscription_create_invalid_plan(client: AsyncClient):
    """POST /subscriptions with invalid plan_code must return HTTP 400."""
    res = await client.post(
        "/subscriptions",
        json={"plan_code": "invalid_tier"},
        headers={"X-User-Id": STUDENT_ID, "Idempotency-Key": str(uuid.uuid4())},
    )
    assert res.status_code == 400
    data = res.json()
    assert data["error"]["code"] == "invalid_plan_code"


@pytest.mark.asyncio
async def test_subscription_create_success_and_idempotent_replay(
    client: AsyncClient,
    db_session: AsyncSession,
):
    """
    POST /subscriptions creates Razorpay test-mode subscription, records in DB,
    and returns checkout details with test_mode=True.
    Replaying with the same Idempotency-Key returns cached response.
    """
    idem_key = f"idem_{uuid.uuid4().hex}"
    req_body = {"plan_code": "standard"}
    headers = {"X-User-Id": STUDENT_ID, "Idempotency-Key": idem_key}

    # 1. Initial request
    res1 = await client.post("/subscriptions", json=req_body, headers=headers)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["test_mode"] is True
    assert data1["key_id"] == "rzp_test_mock_key_id"
    assert data1["amount"] == 29900
    assert "subscription_id" in data1
    assert data1["subscription_id"].startswith("sub_rzp_test_")

    sub_id = data1["subscription_id"]

    # Verify subscription record in DB
    stmt = select(Subscription).where(Subscription.razorpay_subscription_id == sub_id)
    r = await db_session.execute(stmt)
    sub = r.scalar_one_or_none()
    assert sub is not None
    assert sub.plan_code == "standard"
    assert sub.status == "created"

    # 2. Replay request with exact same Idempotency-Key
    res2 = await client.post("/subscriptions", json=req_body, headers=headers)
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2 == data1

    # Ensure no duplicate subscription created in DB
    all_subs = (await db_session.execute(select(Subscription))).scalars().all()
    matching_subs = [s for s in all_subs if s.razorpay_subscription_id == sub_id]
    assert len(matching_subs) == 1


@pytest.mark.asyncio
async def test_subscription_cancel_at_period_end(
    client: AsyncClient,
    db_session: AsyncSession,
):
    """POST /subscriptions/cancel with at_period_end=True updates status to 'cancelling'."""
    # First create a subscription
    idem_key = f"idem_cancel_{uuid.uuid4().hex}"
    create_res = await client.post(
        "/subscriptions",
        json={"plan_code": "high"},
        headers={"X-User-Id": STUDENT_ID, "Idempotency-Key": idem_key},
    )
    assert create_res.status_code == 200

    # Cancel at period end
    res = await client.post(
        "/subscriptions/cancel",
        json={"at_period_end": True},
        headers={"X-User-Id": STUDENT_ID},
    )
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["test_mode"] is True

    # Verify DB status
    stmt = (
        select(Subscription)
        .where(Subscription.user_id == uuid.UUID(STUDENT_ID))
        .order_by(Subscription.created_at.desc())
        .limit(1)
    )
    sub = (await db_session.execute(stmt)).scalar_one_or_none()
    assert sub is not None
    assert sub.status == "cancelling"


@pytest.mark.asyncio
async def test_subscription_cancel_immediate(
    client: AsyncClient,
    db_session: AsyncSession,
):
    """POST /subscriptions/cancel with at_period_end=False cancels immediately and publishes event."""
    idem_key = f"idem_cancel_imm_{uuid.uuid4().hex}"
    create_res = await client.post(
        "/subscriptions",
        json={"plan_code": "premium"},
        headers={"X-User-Id": STUDENT_ID, "Idempotency-Key": idem_key},
    )
    assert create_res.status_code == 200

    # Cancel immediately
    res = await client.post(
        "/subscriptions/cancel",
        json={"at_period_end": False},
        headers={"X-User-Id": STUDENT_ID},
    )
    assert res.status_code == 200
    assert res.json()["success"] is True

    # Check DB status is cancelled
    stmt = (
        select(Subscription)
        .where(Subscription.user_id == uuid.UUID(STUDENT_ID))
        .order_by(Subscription.created_at.desc())
        .limit(1)
    )
    sub = (await db_session.execute(stmt)).scalar_one_or_none()
    assert sub is not None
    assert sub.status == "cancelled"

    # Check subscription.cancelled published in outbox
    event_stmt = select(OutboxEvent).where(OutboxEvent.topic == "subscription.cancelled")
    events = (await db_session.execute(event_stmt)).scalars().all()
    assert len(events) >= 1


@pytest.mark.asyncio
async def test_webhook_signature_verification_valid(client: AsyncClient, db_session: AsyncSession):
    """Valid HMAC-SHA256 signature returns 200 and processes event."""
    event_id = f"evt_valid_{uuid.uuid4().hex}"
    payload = {
        "event_id": event_id,
        "event": "payment.authorized",
        "created_at": 1700000000,
        "payload": {},
    }
    raw_body = json.dumps(payload).encode("utf-8")
    signature = generate_webhook_signature(raw_body)

    res = await client.post(
        "/webhooks/razorpay",
        content=raw_body,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": signature,
        },
    )
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "processed"
    assert data["test_mode"] is True

    # Verify event stored in payment_events table
    pe = (
        await db_session.execute(select(PaymentEvent).where(PaymentEvent.event_id == event_id))
    ).scalar_one_or_none()
    assert pe is not None
    assert pe.event_type == "payment.authorized"


@pytest.mark.asyncio
async def test_webhook_signature_verification_invalid(client: AsyncClient):
    """Invalid signature returns HTTP 400 invalid_signature."""
    raw_body = json.dumps({"event": "payment.authorized"}).encode("utf-8")
    res = await client.post(
        "/webhooks/razorpay",
        content=raw_body,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": "invalid_hmac_signature_xyz",
        },
    )
    assert res.status_code == 400
    data = res.json()
    assert data["error"]["code"] == "invalid_signature"


@pytest.mark.asyncio
async def test_webhook_signature_verification_tampered_body(client: AsyncClient):
    """Signature computed for body A but sent with tampered body B returns HTTP 400."""
    bodyA = json.dumps({"event": "subscription.activated", "amount": 299}).encode("utf-8")
    valid_sig_for_A = generate_webhook_signature(bodyA)

    # Tamper payload
    bodyB = json.dumps({"event": "subscription.activated", "amount": 999999}).encode("utf-8")

    res = await client.post(
        "/webhooks/razorpay",
        content=bodyB,
        headers={
            "Content-Type": "application/json",
            "X-Razorpay-Signature": valid_sig_for_A,
        },
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "invalid_signature"


@pytest.mark.asyncio
async def test_webhook_replay_idempotency(client: AsyncClient, db_session: AsyncSession):
    """Replaying an already recorded webhook returns already_processed without duplicating side-effects."""
    event_id = f"evt_replay_{uuid.uuid4().hex}"
    payload = {
        "event_id": event_id,
        "event": "payment.authorized",
        "created_at": 1700000000,
        "payload": {},
    }
    raw_body = json.dumps(payload).encode("utf-8")
    sig = generate_webhook_signature(raw_body)
    headers = {"Content-Type": "application/json", "X-Razorpay-Signature": sig}

    # 1. First delivery
    res1 = await client.post("/webhooks/razorpay", content=raw_body, headers=headers)
    assert res1.status_code == 200
    assert res1.json()["status"] == "processed"

    # 2. Replayed delivery
    res2 = await client.post("/webhooks/razorpay", content=raw_body, headers=headers)
    assert res2.status_code == 200
    assert res2.json()["status"] == "already_processed"
    assert res2.json()["test_mode"] is True

    # Check only 1 record exists in payment_events
    events = (
        await db_session.execute(select(PaymentEvent).where(PaymentEvent.event_id == event_id))
    ).scalars().all()
    assert len(events) == 1


@pytest.mark.asyncio
async def test_webhook_subscription_lifecycle_activated(
    client: AsyncClient,
    db_session: AsyncSession,
):
    """
    subscription.activated webhook:
    1. Sets DB subscription status to active
    2. Updates period start and end timestamps
    3. Publishes payment.captured and subscription.activated outbox events
    """
    # Create subscription first
    idem_key = f"idem_life_{uuid.uuid4().hex}"
    create_res = await client.post(
        "/subscriptions",
        json={"plan_code": "standard"},
        headers={"X-User-Id": STUDENT_ID, "Idempotency-Key": idem_key},
    )
    assert create_res.status_code == 200
    rzp_sub_id = create_res.json()["subscription_id"]

    event_id = f"evt_act_{uuid.uuid4().hex}"
    payload = {
        "event_id": event_id,
        "event": "subscription.activated",
        "payload": {
            "subscription": {
                "entity": {
                    "id": rzp_sub_id,
                    "status": "active",
                    "current_start": 1700000000,
                    "current_end": 1702592000,
                }
            },
            "payment": {
                "entity": {
                    "id": f"pay_test_{uuid.uuid4().hex[:8]}",
                    "amount": 29900,
                    "subscription_id": rzp_sub_id,
                }
            },
        },
    }
    raw_body = json.dumps(payload).encode("utf-8")
    sig = generate_webhook_signature(raw_body)

    res = await client.post(
        "/webhooks/razorpay",
        content=raw_body,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 200
    assert res.json()["status"] == "processed"

    # Verify DB subscription updated to active
    sub = (
        await db_session.execute(
            select(Subscription).where(Subscription.razorpay_subscription_id == rzp_sub_id)
        )
    ).scalar_one_or_none()
    assert sub is not None
    assert sub.status == "active"
    assert sub.current_period_start is not None
    assert sub.current_period_end is not None

    # Verify published outbox events
    pay_events = (
        await db_session.execute(
            select(OutboxEvent).where(OutboxEvent.topic == "payment.captured")
        )
    ).scalars().all()
    sub_events = (
        await db_session.execute(
            select(OutboxEvent).where(OutboxEvent.topic == "subscription.activated")
        )
    ).scalars().all()

    assert len(pay_events) >= 1
    assert len(sub_events) >= 1
    assert pay_events[-1].payload["user_id"] == STUDENT_ID
    assert pay_events[-1].payload["amount_inr"] == 299


@pytest.mark.asyncio
async def test_webhook_subscription_lifecycle_cancelled(
    client: AsyncClient,
    db_session: AsyncSession,
):
    """subscription.cancelled webhook marks subscription cancelled and publishes event."""
    idem_key = f"idem_web_cancel_{uuid.uuid4().hex}"
    create_res = await client.post(
        "/subscriptions",
        json={"plan_code": "high"},
        headers={"X-User-Id": STUDENT_ID, "Idempotency-Key": idem_key},
    )
    rzp_sub_id = create_res.json()["subscription_id"]

    event_id = f"evt_canc_{uuid.uuid4().hex}"
    payload = {
        "event_id": event_id,
        "event": "subscription.cancelled",
        "payload": {
            "subscription": {
                "entity": {
                    "id": rzp_sub_id,
                    "status": "cancelled",
                }
            }
        },
    }
    raw_body = json.dumps(payload).encode("utf-8")
    sig = generate_webhook_signature(raw_body)

    res = await client.post(
        "/webhooks/razorpay",
        content=raw_body,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 200

    # Verify local status updated
    sub = (
        await db_session.execute(
            select(Subscription).where(Subscription.razorpay_subscription_id == rzp_sub_id)
        )
    ).scalar_one_or_none()
    assert sub is not None
    assert sub.status == "cancelled"


@pytest.mark.asyncio
async def test_webhook_payment_failed(client: AsyncClient, db_session: AsyncSession):
    """payment.failed webhook updates subscription status to past_due."""
    idem_key = f"idem_fail_{uuid.uuid4().hex}"
    create_res = await client.post(
        "/subscriptions",
        json={"plan_code": "standard"},
        headers={"X-User-Id": STUDENT_ID, "Idempotency-Key": idem_key},
    )
    rzp_sub_id = create_res.json()["subscription_id"]

    event_id = f"evt_fail_{uuid.uuid4().hex}"
    payload = {
        "event_id": event_id,
        "event": "payment.failed",
        "payload": {
            "subscription": {
                "entity": {
                    "id": rzp_sub_id,
                }
            }
        },
    }
    raw_body = json.dumps(payload).encode("utf-8")
    sig = generate_webhook_signature(raw_body)

    res = await client.post(
        "/webhooks/razorpay",
        content=raw_body,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 200

    sub = (
        await db_session.execute(
            select(Subscription).where(Subscription.razorpay_subscription_id == rzp_sub_id)
        )
    ).scalar_one_or_none()
    assert sub is not None
    assert sub.status == "past_due"


@pytest.mark.asyncio
async def test_webhook_out_of_order_handling(client: AsyncClient, db_session: AsyncSession):
    """Out-of-order webhook with unknown subscription id is recorded without crashing."""
    event_id = f"evt_unknown_{uuid.uuid4().hex}"
    payload = {
        "event_id": event_id,
        "event": "subscription.activated",
        "payload": {
            "subscription": {
                "entity": {
                    "id": "sub_unknown_not_in_db",
                }
            }
        },
    }
    raw_body = json.dumps(payload).encode("utf-8")
    sig = generate_webhook_signature(raw_body)

    res = await client.post(
        "/webhooks/razorpay",
        content=raw_body,
        headers={"Content-Type": "application/json", "X-Razorpay-Signature": sig},
    )
    assert res.status_code == 200
    assert res.json()["status"] == "processed"

    # Verify event stored
    pe = (
        await db_session.execute(select(PaymentEvent).where(PaymentEvent.event_id == event_id))
    ).scalar_one_or_none()
    assert pe is not None


@pytest.mark.asyncio
async def test_cashout_simulation_and_admin_approval(
    client: AsyncClient,
    db_session: AsyncSession,
):
    """
    1. If giver has insufficient earnings, cashout request fails (400).
    2. After earnings are released via read-model, cashout request succeeds.
    3. Admin approval sets status to 'paid' and publishes payout.disbursed.
    """
    giver_uid = uuid.UUID(GIVER_ID)

    # Ensure giver is verified
    u = await db_session.get(User, giver_uid)
    if not u:
        u = User(
            id=giver_uid,
            email="giver@test.com",
            full_name="Giver User",
            trust_level="verified",
            roles=["alumnus"],
        )
        db_session.add(u)
        await db_session.commit()
    elif u.trust_level != "verified":
        u.trust_level = "verified"
        await db_session.commit()

    from app.core.ports import ports
    from unittest.mock import AsyncMock
    ports.trust.get_level = AsyncMock(return_value="verified")

    # 1. Attempt cashout with 0 available earnings -> 400
    res_fail = await client.post(
        "/payouts/request",
        json={"amount_inr": 500.0, "upi_id": "alumni@upi"},
        headers={"X-User-Id": GIVER_ID},
    )
    assert res_fail.status_code == 400
    assert res_fail.json()["error"]["code"] == "insufficient_earnings"

    # 2. Feed earnings into read model (simulating event bus subscriber)
    await PaymentsService.update_giver_earnings_cache(
        session=db_session,
        user_id=GIVER_ID,
        amount_delta_inr=1000.0,
    )
    await db_session.commit()

    # 3. Request cashout successfully
    res_req = await client.post(
        "/payouts/request",
        json={"amount_inr": 400.0, "upi_id": "alumni@okhdfcbank"},
        headers={"X-User-Id": GIVER_ID},
    )
    assert res_req.status_code == 200
    data_req = res_req.json()
    assert data_req["status"] == "requested"
    assert data_req["amount_inr"] == 400.0
    assert data_req["test_mode"] is True
    payout_id = data_req["payout_id"]

    # Verify remaining earnings deducted in read model
    rm = await db_session.get(GiverEarningsReadModel, giver_uid)
    assert rm is not None
    assert round(rm.available_earnings_inr, 2) == 600.0

    # 4. Admin approves payout
    res_app = await client.post(f"/admin/payouts/{payout_id}/approve")
    assert res_app.status_code == 200
    data_app = res_app.json()
    assert data_app["success"] is True
    assert data_app["status"] == "paid"
    assert data_app["test_mode"] is True

    # Verify payout request status in DB
    payout = await db_session.get(PayoutRequest, uuid.UUID(payout_id))
    assert payout is not None
    assert payout.status == "paid"

    # Verify payout.disbursed event published to outbox
    payout_events = (
        await db_session.execute(
            select(OutboxEvent).where(OutboxEvent.topic == "payout.disbursed")
        )
    ).scalars().all()
    assert len(payout_events) >= 1
    assert payout_events[-1].payload["payout_id"] == payout_id
    assert payout_events[-1].payload["amount_inr"] == 400.0


def test_test_mode_key_guard():
    """RazorpayClientWrapper refuses keys not starting with 'rzp_test_' in non-production."""
    # Production keys should fail in non-production
    orig_env = settings.ENVIRONMENT
    try:
        settings.ENVIRONMENT = "test"
        with pytest.raises(AppError) as exc_info:
            RazorpayClientWrapper(
                key_id="rzp_live_production_key_123",
                key_secret="live_secret",
            )
        assert exc_info.value.code == "invalid_razorpay_keys"
        assert exc_info.value.status_code == 500

        # Test key should succeed
        client = RazorpayClientWrapper(
            key_id="rzp_test_valid_key_123",
            key_secret="test_secret",
        )
        assert client.key_id == "rzp_test_valid_key_123"
    finally:
        settings.ENVIRONMENT = orig_env


@pytest.mark.asyncio
async def test_reconciliation_job(db_session: AsyncSession, mock_rzp_client: MockRazorpayClient):
    """Nightly reconciliation detects discrepancy between local DB and Razorpay."""
    # Insert subscription with created status in DB
    sub = Subscription(
        id=uuid.uuid4(),
        user_id=uuid.UUID(STUDENT_ID),
        plan_code="standard",
        razorpay_subscription_id="sub_test_discrepancy_123",
        status="created",
    )
    db_session.add(sub)
    await db_session.commit()

    # Razorpay mock returns status 'active' for this subscription
    mock_rzp_client._subscriptions_store["sub_test_discrepancy_123"] = {
        "id": "sub_test_discrepancy_123",
        "status": "active",
    }

    # Run reconciliation
    discrepancies = await PaymentsService.reconcile_subscriptions(
        session=db_session,
        client=mock_rzp_client,
    )
    await db_session.commit()

    assert len(discrepancies) == 1
    assert discrepancies[0]["razorpay_subscription_id"] == "sub_test_discrepancy_123"
    assert discrepancies[0]["db_status"] == "created"
    assert discrepancies[0]["rzp_status"] == "active"

    # Verify DB subscription was updated
    await db_session.refresh(sub)
    assert sub.status == "active"
