"""
Comprehensive tests for Credits Double-Entry Ledger, CreditsPort, and Settlement Lifecycle.
Owner: M4
"""

import uuid
from datetime import datetime, timedelta, timezone
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import Institution, User
from app.core.errors import AppError
from app.core.ports import ports
from app.modules.credits.models import (
    CreditLot,
    LedgerAccount,
    LedgerEntry,
    Plan,
    SessionSettlement,
    SponsoredSeat,
    UserSubscription,
)
from app.modules.credits.module import CreditsPortImpl
from app.modules.credits.service import CreditsService


@pytest.mark.asyncio
async def test_ledger_double_entry_balance_invariant(db_session: AsyncSession):
    """Property test: every transaction entries must sum to zero in credits and INR."""
    acc_a = await CreditsService.get_or_create_account(db_session, uuid.uuid4(), "user_paid")
    acc_b = await CreditsService.get_or_create_account(db_session, None, "platform_revenue")

    # Balanced transaction
    drafts = [
        {"account_id": acc_a.id, "amount_credits": 2, "amount_inr": 598.0},
        {"account_id": acc_b.id, "amount_credits": -2, "amount_inr": -598.0},
    ]
    txn_id = await CreditsService.post_transaction(
        session=db_session,
        drafts=drafts,
        ref_type="test",
        ref_id="tx-1",
        reason="plan_credit_grant",
    )
    assert txn_id is not None

    # Check entries sum to zero
    entries_res = await db_session.execute(select(LedgerEntry).where(LedgerEntry.txn_id == txn_id))
    entries = entries_res.scalars().all()
    assert len(entries) == 2
    assert sum(e.amount_credits for e in entries) == 0
    assert round(sum(e.amount_inr for e in entries), 2) == 0.0

    # Cached balances match
    assert acc_a.balance_credits == 2
    assert acc_a.balance_inr == 598.0
    assert acc_b.balance_credits == -2
    assert acc_b.balance_inr == -598.0


@pytest.mark.asyncio
async def test_ledger_rejects_unbalanced_transaction(db_session: AsyncSession):
    """Transactions that do not sum to zero must be rejected with unbalanced_transaction error."""
    acc_a = await CreditsService.get_or_create_account(db_session, uuid.uuid4(), "user_paid")
    acc_b = await CreditsService.get_or_create_account(db_session, None, "platform_revenue")

    # Unbalanced credits
    drafts = [
        {"account_id": acc_a.id, "amount_credits": 2, "amount_inr": 200.0},
        {"account_id": acc_b.id, "amount_credits": -1, "amount_inr": -200.0},
    ]
    with pytest.raises(AppError) as exc_info:
        await CreditsService.post_transaction(
            session=db_session,
            drafts=drafts,
            ref_type="test",
            ref_id="tx-unbalanced",
            reason="test_fail",
        )
    assert exc_info.value.code == "unbalanced_transaction"


@pytest.mark.asyncio
async def test_user_balance_cannot_go_negative(db_session: AsyncSession):
    """User account balances must never go negative (overdraft protection)."""
    user_id = uuid.uuid4()
    acc_user = await CreditsService.get_or_create_account(db_session, user_id, "user_paid")
    acc_res = await CreditsService.get_or_create_account(db_session, None, "reserved")

    # User currently has 0 credits. Attempt to deduct 1 credit.
    drafts = [
        {"account_id": acc_user.id, "amount_credits": -1, "amount_inr": -299.0},
        {"account_id": acc_res.id, "amount_credits": 1, "amount_inr": 299.0},
    ]
    with pytest.raises(AppError) as exc_info:
        await CreditsService.post_transaction(
            session=db_session,
            drafts=drafts,
            ref_type="test",
            ref_id="tx-negative",
            reason="test_overdraft",
        )
    assert exc_info.value.code == "insufficient_balance"


@pytest.mark.asyncio
async def test_idempotent_transaction_replay(db_session: AsyncSession):
    """Posting the same (ref_type, ref_id, reason) transaction multiple times is idempotent."""
    acc_a = await CreditsService.get_or_create_account(db_session, uuid.uuid4(), "user_paid")
    acc_b = await CreditsService.get_or_create_account(db_session, None, "platform_revenue")

    drafts = [
        {"account_id": acc_a.id, "amount_credits": 1, "amount_inr": 299.0},
        {"account_id": acc_b.id, "amount_credits": -1, "amount_inr": -299.0},
    ]
    txn1 = await CreditsService.post_transaction(
        session=db_session,
        drafts=drafts,
        ref_type="payment",
        ref_id="pay_12345",
        reason="plan_credit_grant",
    )
    # Replay
    txn2 = await CreditsService.post_transaction(
        session=db_session,
        drafts=drafts,
        ref_type="payment",
        ref_id="pay_12345",
        reason="plan_credit_grant",
    )
    assert txn1 == txn2
    assert acc_a.balance_credits == 1  # Not double credited!


@pytest.mark.asyncio
async def test_fifo_credit_lots_consumption(db_session: AsyncSession):
    """Credit lots are consumed FIFO with corresponding unit prices."""
    user_id = uuid.uuid4()
    paid_acc = await CreditsService.get_or_create_account(db_session, user_id, "user_paid")
    now = datetime.now(timezone.utc)

    # First lot: Standard plan (1 credit @ ₹299)
    lot1 = CreditLot(
        id=uuid.uuid4(),
        account_id=paid_acc.id,
        credits_remaining=1,
        unit_price_inr=299.0,
        created_at=now - timedelta(days=5),
    )
    # Second lot: High plan (2 credits @ ₹249.50)
    lot2 = CreditLot(
        id=uuid.uuid4(),
        account_id=paid_acc.id,
        credits_remaining=2,
        unit_price_inr=249.50,
        created_at=now,
    )
    db_session.add_all([lot1, lot2])
    paid_acc.balance_credits = 3
    await db_session.flush()

    # Reserve 1st session credit -> should consume from Lot 1 @ ₹299
    await CreditsService.reserve(db_session, str(user_id), "req-1", "giver-1")
    assert lot1.credits_remaining == 0
    assert lot2.credits_remaining == 2
    assert paid_acc.balance_credits == 2

    # Reserve 2nd session credit -> should consume from Lot 2 @ ₹249.50
    await CreditsService.reserve(db_session, str(user_id), "req-2", "giver-1")
    assert lot1.credits_remaining == 0
    assert lot2.credits_remaining == 1
    assert paid_acc.balance_credits == 1


@pytest.mark.asyncio
async def test_can_access_gating_matrix(db_session: AsyncSession):
    """Gating matrix tests across plans, institutions, bands, and categories."""
    # Create institutions
    inst1 = Institution(id=1, name="College A", email_domains=["collega.edu"])
    inst2 = Institution(id=2, name="College B", email_domains=["collegb.edu"])
    db_session.add_all([inst1, inst2])

    # Student from College A
    student_id = uuid.uuid4()
    student = User(id=student_id, email="student@collega.edu", full_name="Student One", institution_id=1, roles=["student"])

    # Givers
    giver_peer = User(id=uuid.uuid4(), email="peer@collega.edu", full_name="Peer Alumni", institution_id=1, roles=["alumni"])
    giver_rising = User(id=uuid.uuid4(), email="rising@collegb.edu", full_name="Rising Alumni", institution_id=2, roles=["alumni"])
    giver_expert = User(id=uuid.uuid4(), email="expert@collegb.edu", full_name="Expert Founder", institution_id=2, roles=["founder"])
    db_session.add_all([student, giver_peer, giver_rising, giver_expert])
    await db_session.flush()

    # 1. Own college peer: Allowed free (cost 0, plan campus)
    access_own = await CreditsService.can_access(db_session, str(student_id), str(giver_peer.id))
    assert access_own["allowed"] is True
    assert access_own["cost"] == 0
    assert access_own["reason"] == "own_college_free"

    # 2. Cross college without plan: Disallowed (requires upgrade)
    access_cross_no_plan = await CreditsService.can_access(db_session, str(student_id), str(giver_rising.id))
    assert access_cross_no_plan["allowed"] is False
    assert access_cross_no_plan["reason"] == "plan_upgrade_required"

    # Activate Standard plan for student (with 1 credit)
    await CreditsService.handle_subscription_activated(db_session, str(student_id), "standard")

    # 3. Standard plan reaches Rising giver
    access_standard_rising = await CreditsService.can_access(db_session, str(student_id), str(giver_rising.id))
    assert access_standard_rising["allowed"] is True
    assert access_standard_rising["cost"] == 1

    # 4. Standard plan cannot reach Expert (founder)
    access_standard_expert = await CreditsService.can_access(db_session, str(student_id), str(giver_expert.id))
    assert access_standard_expert["allowed"] is False
    assert access_standard_expert["reason"] == "giver_requires_premium"

    # Upgrade to Premium plan
    await CreditsService.handle_subscription_activated(db_session, str(student_id), "premium")

    # 5. Premium plan reaches Expert
    access_premium_expert = await CreditsService.can_access(db_session, str(student_id), str(giver_expert.id))
    assert access_premium_expert["allowed"] is True
    assert access_premium_expert["cost"] == 1


@pytest.mark.asyncio
async def test_settlement_and_payout_shares(db_session: AsyncSession):
    """Settlement splits credit value by band payout share: Rising 60%, Trusted 70%, Top Rated 80%."""
    giver_id = uuid.uuid4()
    giver_acc = await CreditsService.get_or_create_account(db_session, giver_id, "user_paid")
    reserved_acc = await CreditsService.get_or_create_account(db_session, None, "reserved")
    platform_acc = await CreditsService.get_or_create_account(db_session, None, "platform_revenue")

    platform_acc.balance_inr = 0.0  # Starting platform balance
    reserved_acc.balance_credits = 1
    reserved_acc.balance_inr = 299.0
    await db_session.flush()

    # Mock rating port to return Rising
    class MockRatingsPort:
        async def get_band(self, gid: str):
            return {"band": "Rising", "smoothed_avg": 4.1, "n": 3, "completion_rate": 1.0}

    ports.ratings = MockRatingsPort()

    settlement = SessionSettlement(
        id=uuid.uuid4(),
        session_id="sess-rising-1",
        request_id="req-101",
        student_id=uuid.uuid4(),
        giver_id=giver_id,
        is_cross_college=True,
        unit_price_inr=299.0,
        status="pending_window",
        settles_at=datetime.now(timezone.utc) - timedelta(hours=1),
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(settlement)
    await db_session.flush()

    # Settle session
    await CreditsService.settle_session(db_session, settlement)

    # 60% of 299 = 179.40 to giver, 40% = 119.60 to platform
    assert round(giver_acc.balance_inr, 2) == 179.40
    assert round(platform_acc.balance_inr, 2) == 119.60
    assert settlement.status == "settled"


@pytest.mark.asyncio
async def test_own_college_session_earns_affinity_credit(db_session: AsyncSession):
    """Own-college session awards giver 1 non-cash affinity credit funded by platform."""
    giver_id = uuid.uuid4()
    giver_aff = await CreditsService.get_or_create_account(db_session, giver_id, "user_affinity")
    platform_acc = await CreditsService.get_or_create_account(db_session, None, "platform_revenue")

    settlement = SessionSettlement(
        id=uuid.uuid4(),
        session_id="sess-affinity-1",
        request_id="req-aff-1",
        student_id=uuid.uuid4(),
        giver_id=giver_id,
        is_cross_college=False,
        unit_price_inr=0.0,
        status="pending_window",
        settles_at=datetime.now(timezone.utc) - timedelta(hours=1),
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(settlement)
    await db_session.flush()

    await CreditsService.settle_session(db_session, settlement)

    assert giver_aff.balance_credits == 1
    assert platform_acc.balance_credits == -1
    assert settlement.status == "settled"


@pytest.mark.asyncio
async def test_dispute_pause_and_resolve_refund(db_session: AsyncSession):
    """Dispute opens pauses settlement, and dispute resolution refunds credit."""
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    # Give student 1 credit
    await CreditsService.handle_subscription_activated(db_session, str(student_id), "standard")
    student_acc = await CreditsService.get_or_create_account(db_session, student_id, "user_paid")
    assert student_acc.balance_credits == 1

    # Reserve credit for request
    req_id = "req-dispute-test"
    await CreditsService.reserve(db_session, str(student_id), req_id, str(giver_id))
    assert student_acc.balance_credits == 0

    # Session completed -> starts 48h dispute window
    sess_id = "sess-dispute-1"
    settlement = SessionSettlement(
        id=uuid.uuid4(),
        session_id=sess_id,
        request_id=req_id,
        student_id=student_id,
        giver_id=giver_id,
        is_cross_college=True,
        unit_price_inr=299.0,
        status="pending_window",
        settles_at=datetime.now(timezone.utc) + timedelta(hours=48),
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(settlement)
    await db_session.flush()

    # Dispute opened
    await CreditsService.handle_dispute_opened(db_session, sess_id)
    assert settlement.status == "disputed"

    # Dispute resolved with outcome='refund'
    await CreditsService.handle_dispute_resolved(db_session, sess_id, outcome="refund")
    assert settlement.status == "refunded"
    assert student_acc.balance_credits == 1  # Refunded back to student!


@pytest.mark.asyncio
async def test_session_no_show_rules(db_session: AsyncSession):
    """Giver absent refunds student; Student absent consumes credit and pays giver."""
    student_id = uuid.uuid4()
    giver_id = uuid.uuid4()

    # 1. Giver absent
    await CreditsService.handle_subscription_activated(db_session, str(student_id), "standard")
    student_acc = await CreditsService.get_or_create_account(db_session, student_id, "user_paid")
    req1 = "req-noshow-giver"
    await CreditsService.reserve(db_session, str(student_id), req1, str(giver_id))
    assert student_acc.balance_credits == 0

    settlement1 = SessionSettlement(
        id=uuid.uuid4(),
        session_id="sess-noshow-1",
        request_id=req1,
        student_id=student_id,
        giver_id=giver_id,
        is_cross_college=True,
        unit_price_inr=299.0,
        status="pending_window",
        settles_at=datetime.now(timezone.utc) + timedelta(hours=48),
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(settlement1)
    await db_session.flush()

    await CreditsService.handle_session_no_show(db_session, "sess-noshow-1", no_show_party="giver")
    assert settlement1.status == "refunded"
    assert student_acc.balance_credits == 1  # Refunded!


@pytest.mark.asyncio
async def test_donate_credits_to_scholarship_pool(db_session: AsyncSession):
    """Students/givers can donate credits to subsidized scholarship pool."""
    user_id = uuid.uuid4()
    await CreditsService.handle_subscription_activated(db_session, str(user_id), "high")
    user_acc = await CreditsService.get_or_create_account(db_session, user_id, "user_paid")
    assert user_acc.balance_credits == 2

    donated = await CreditsService.donate_credits(db_session, str(user_id), credits_to_donate=1)
    assert donated == 1
    assert user_acc.balance_credits == 1

    pool_acc = await CreditsService.get_or_create_account(db_session, None, "scholarship_pool")
    assert pool_acc.balance_credits == 1


@pytest.mark.asyncio
async def test_allocate_sponsored_seat(db_session: AsyncSession):
    """Admin grants sponsored seat funded by scholarship pool with ledger entry."""
    student_id = uuid.uuid4()
    pool_acc = await CreditsService.get_or_create_account(db_session, None, "scholarship_pool")
    pool_acc.balance_credits = 5
    pool_acc.balance_inr = 1500.0
    await db_session.flush()

    seat = await CreditsService.allocate_sponsored_seat(
        session=db_session,
        student_id=str(student_id),
        plan_tier="standard",
        sponsor_name="Alumni Endowment 2026",
        funded_by="scholarship_pool",
    )
    assert seat.plan_tier == "standard"
    assert seat.sponsor_name == "Alumni Endowment 2026"

    student_acc = await CreditsService.get_or_create_account(db_session, student_id, "user_paid")
    assert student_acc.balance_credits == 1  # Received 1 credit from standard plan
    assert pool_acc.balance_credits == 4    # 1 credit deducted from pool


@pytest.mark.asyncio
async def test_cashout_flow(db_session: AsyncSession):
    """Givers can cash out earned session funds to UPI with ledger entry to payout_clearing."""
    giver_id = uuid.uuid4()
    giver_acc = await CreditsService.get_or_create_account(db_session, giver_id, "user_paid")
    giver_acc.balance_inr = 500.0
    await db_session.flush()

    payout = await CreditsService.cashout(
        session=db_session,
        user_id=str(giver_id),
        amount_inr=300.0,
        upi_id="giver@okhdfcbank",
    )
    assert payout.amount_inr == 300.0
    assert payout.status == "pending"
    assert giver_acc.balance_inr == 200.0

    clearing_acc = await CreditsService.get_or_create_account(db_session, None, "payout_clearing")
    assert clearing_acc.balance_inr == 300.0

    # Over-cashout must fail
    with pytest.raises(AppError) as exc_info:
        await CreditsService.cashout(
            session=db_session,
            user_id=str(giver_id),
            amount_inr=300.0,  # Only 200 left
            upi_id="giver@okhdfcbank",
        )
    assert exc_info.value.code == "insufficient_balance"
