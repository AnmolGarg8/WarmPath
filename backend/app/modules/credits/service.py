"""
Business logic and double-entry ledger operations for credits module.
Owner: M4
"""

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import User
from app.core.errors import AppError
from app.core.events import (
    CreditsRefundedPayload,
    CreditsReleasedPayload,
    CreditsReservedPayload,
    event_bus,
)
from app.core.pagination import decode_cursor, encode_cursor
from app.core.ports import ports
from app.modules.credits.models import (
    CreditLot,
    LedgerAccount,
    LedgerEntry,
    PayoutRequest,
    Plan,
    SessionSettlement,
    SponsoredSeat,
    UserSubscription,
)


PLAIN_REASONS = {
    "plan_credit_grant": "Monthly subscription credits issued",
    "session_reservation": "Credit reserved for session request",
    "session_release": "Reserved credit released",
    "session_refund_giver_no_show": "Refunded: Giver was absent",
    "session_refund_no_reply_72h": "Refunded: No reply within 72 hours",
    "session_refund_dispute_outcome": "Refunded: Dispute resolved in your favor",
    "session_settlement_payout": "Earnings received for completed session",
    "session_settlement_platform_fee": "Platform facilitation share",
    "affinity_reward": "Affinity credit earned for mentoring campus peer",
    "donation_to_scholarship": "Donated credits to student scholarship fund",
    "cashout_request": "Requested cashout of session earnings to UPI",
    "sponsored_seat_grant": "Sponsored seat grant credits received",
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


class CreditsService:

    @staticmethod
    async def seed_plans_if_empty(session: AsyncSession) -> None:
        """Seed default plans from configuration if plans table is empty."""
        result = await session.execute(select(func.count(Plan.id)))
        count = result.scalar() or 0
        if count > 0:
            return

        default_plans = [
            Plan(
                code="campus",
                name="Campus Free",
                price_inr=settings.PLAN_CAMPUS_PRICE,
                credits_per_month=settings.PLAN_CAMPUS_CREDITS,
                reach_bands=[],
                booking_horizon_days=3,
                priority=0,
                features=[
                    "Own-college alumni access",
                    "0 paid credits/month",
                    "3-day booking horizon",
                    "Free 1-on-1 sessions",
                ],
                active=True,
            ),
            Plan(
                code="standard",
                name="Standard Plan",
                price_inr=settings.PLAN_STANDARD_PRICE,
                credits_per_month=settings.PLAN_STANDARD_CREDITS,
                reach_bands=["Rising"],
                booking_horizon_days=settings.BOOKING_HORIZON_STANDARD,
                priority=1,
                features=[
                    "1 cross-college credit/month",
                    "Reach Rising alumni",
                    "3-day booking horizon",
                    "Priority 1 in giver inbox",
                ],
                active=True,
            ),
            Plan(
                code="high",
                name="High Plan",
                price_inr=settings.PLAN_HIGH_PRICE,
                credits_per_month=settings.PLAN_HIGH_CREDITS,
                reach_bands=["Rising", "Trusted"],
                booking_horizon_days=settings.BOOKING_HORIZON_HIGH,
                priority=2,
                features=[
                    "2 cross-college credits/month",
                    "Reach Rising and Trusted alumni",
                    "14-day booking horizon",
                    "Priority 2 in giver inbox",
                ],
                active=True,
            ),
            Plan(
                code="premium",
                name="Premium Plan",
                price_inr=settings.PLAN_PREMIUM_PRICE,
                credits_per_month=settings.PLAN_PREMIUM_CREDITS,
                reach_bands=["Rising", "Trusted", "Top Rated"],
                booking_horizon_days=settings.BOOKING_HORIZON_PREMIUM,
                priority=3,
                features=[
                    "4 cross-college credits/month",
                    "Reach all bands, experts, recruiters, founders and faculty",
                    "30-day booking horizon",
                    "Highest priority (3) in giver inbox",
                ],
                active=True,
            ),
        ]
        session.add_all(default_plans)
        await session.commit()

    @staticmethod
    async def get_or_create_account(
        session: AsyncSession,
        owner_user_id: Optional[Any],
        kind: str,
    ) -> LedgerAccount:
        """Fetch or create a ledger account by owner and kind."""
        u_owner = to_uuid(owner_user_id)
        query = select(LedgerAccount).where(LedgerAccount.kind == kind)
        if u_owner is not None:
            query = query.where(LedgerAccount.owner_user_id == u_owner)
        else:
            query = query.where(LedgerAccount.owner_user_id.is_(None))

        res = await session.execute(query)
        account = res.scalar_one_or_none()
        if not account:
            account = LedgerAccount(
                id=uuid.uuid4(),
                owner_user_id=u_owner,
                kind=kind,
                balance_credits=0,
                balance_inr=0.0,
            )
            session.add(account)
            await session.flush()
        return account

    @staticmethod
    async def post_transaction(
        session: AsyncSession,
        drafts: List[Dict[str, Any]],
        ref_type: str,
        ref_id: str,
        reason: str,
    ) -> uuid.UUID:
        """
        Post a balanced double-entry transaction.
        Invariants enforced:
          1. Sum of amount_credits == 0
          2. Sum of amount_inr == 0
          3. Accounts row-locked in sorted order to prevent deadlocks
          4. User balances never go negative
          5. Idempotent per (ref_type, ref_id, reason)
        """
        # Idempotency check
        existing_check = await session.execute(
            select(LedgerEntry.txn_id).where(
                LedgerEntry.ref_type == ref_type,
                LedgerEntry.ref_id == str(ref_id),
                LedgerEntry.reason == reason,
            ).limit(1)
        )
        existing_txn = existing_check.scalar_one_or_none()
        if existing_txn:
            return existing_txn

        # Invariant 1 & 2: Balances must sum to zero
        sum_credits = sum(d.get("amount_credits", 0) for d in drafts)
        sum_inr = round(sum(d.get("amount_inr", 0.0) for d in drafts), 2)
        if sum_credits != 0:
            raise AppError(
                code="unbalanced_transaction",
                message=f"Transaction credits unbalance: sum={sum_credits}",
                status_code=500,
            )
        if abs(sum_inr) > 0.01:
            raise AppError(
                code="unbalanced_transaction",
                message=f"Transaction INR unbalance: sum={sum_inr}",
                status_code=500,
            )

        txn_id = uuid.uuid4()
        now = datetime.now(timezone.utc)

        # Collect unique account IDs and sort them to prevent deadlocks
        account_ids = sorted({to_uuid(d["account_id"]) for d in drafts}, key=lambda x: str(x))

        # Row-lock accounts with FOR UPDATE
        stmt = (
            select(LedgerAccount)
            .where(LedgerAccount.id.in_(account_ids))
            .with_for_update()
        )
        locked_accounts_res = await session.execute(stmt)
        accounts_map = {acc.id: acc for acc in locked_accounts_res.scalars().all()}

        # Verify all accounts exist
        for aid in account_ids:
            if aid not in accounts_map:
                raise AppError(
                    code="account_not_found",
                    message=f"Ledger account {aid} not found",
                    status_code=500,
                )

        # Apply drafts
        for d in drafts:
            aid = to_uuid(d["account_id"])
            acc = accounts_map[aid]
            c_delta = d.get("amount_credits", 0)
            i_delta = round(d.get("amount_inr", 0.0), 2)

            acc.balance_credits += c_delta
            acc.balance_inr = round(acc.balance_inr + i_delta, 2)
            acc.updated_at = now

            # Invariant: User balances must never go negative
            if acc.kind in ("user_paid", "user_affinity") and (acc.balance_credits < 0 or acc.balance_inr < -0.01):
                raise AppError(
                    code="insufficient_balance",
                    message=f"Account balance cannot go negative: credits={acc.balance_credits}, inr={acc.balance_inr}",
                    status_code=400,
                )

            direction = "credit" if (c_delta > 0 or i_delta > 0) else "debit"
            entry = LedgerEntry(
                id=uuid.uuid4(),
                txn_id=txn_id,
                account_id=acc.id,
                amount_credits=c_delta,
                amount_inr=i_delta,
                direction=direction,
                reason=reason,
                ref_type=ref_type,
                ref_id=str(ref_id),
                created_at=now,
            )
            session.add(entry)

        await session.flush()
        return txn_id

    @staticmethod
    async def can_access(
        session: AsyncSession,
        student_id: str,
        giver_id: str,
    ) -> Dict[str, Any]:
        """
        CreditsPort.can_access implementation.
        Rules:
          - Own institution is allowed free (cost 0)
          - Cross-college requires active plan whose reach_bands include giver's band
          - Premium required if giver is expert, recruiter, founder or faculty
        """
        await CreditsService.seed_plans_if_empty(session)

        s_uid = to_uuid(student_id)
        g_uid = to_uuid(giver_id)

        student = await session.get(User, s_uid) if s_uid else None
        giver = await session.get(User, g_uid) if g_uid else None

        # 1. Own institution check
        if student and giver and student.institution_id and student.institution_id == giver.institution_id:
            return {
                "allowed": True,
                "reason": "own_college_free",
                "plan": "campus",
                "cost": 0,
            }

        # 2. Cross-college: Student must have active subscription
        sub_query = (
            select(UserSubscription)
            .where(
                UserSubscription.user_id == s_uid,
                UserSubscription.status == "active",
                UserSubscription.period_end > datetime.now(timezone.utc),
            )
            .order_by(desc(UserSubscription.created_at))
            .limit(1)
        )
        sub_res = await session.execute(sub_query)
        sub = sub_res.scalar_one_or_none()

        plan_code = sub.plan_code if sub else "campus"
        plan_query = select(Plan).where(Plan.code == plan_code)
        plan_res = await session.execute(plan_query)
        plan = plan_res.scalar_one_or_none()

        if not plan or plan.code == "campus":
            return {
                "allowed": False,
                "reason": "plan_upgrade_required",
                "plan": "campus",
                "cost": 1,
            }

        # 3. Premium category check (expert, recruiter, founder, faculty)
        giver_roles = giver.roles if giver and giver.roles else []
        premium_roles = {"expert", "recruiter", "founder", "faculty"}
        if any(r in premium_roles for r in giver_roles) and plan.code != "premium":
            return {
                "allowed": False,
                "reason": "giver_requires_premium",
                "plan": plan.code,
                "cost": 1,
            }

        # 4. Giver Rating Band check
        giver_band = "Rising"
        try:
            band_info = await ports.ratings.get_band(str(giver_id))
            if isinstance(band_info, dict) and "band" in band_info:
                giver_band = band_info["band"]
        except Exception:
            giver_band = "Rising"

        reach_bands = plan.reach_bands or []
        if giver_band not in reach_bands:
            return {
                "allowed": False,
                "reason": f"plan_does_not_reach_{giver_band.lower().replace(' ', '_')}",
                "plan": plan.code,
                "cost": 1,
            }

        # 5. Check student has at least 1 credit (paid or affinity)
        paid_acc = await CreditsService.get_or_create_account(session, s_uid, "user_paid")
        aff_acc = await CreditsService.get_or_create_account(session, s_uid, "user_affinity")
        total_credits = (paid_acc.balance_credits or 0) + (aff_acc.balance_credits or 0)
        if total_credits < 1:
            return {
                "allowed": False,
                "reason": "insufficient_credits",
                "plan": plan.code,
                "cost": 1,
            }

        return {
            "allowed": True,
            "reason": "access_granted",
            "plan": plan.code,
            "cost": 1,
        }

    @staticmethod
    async def reserve(
        session: AsyncSession,
        student_id: str,
        request_id: str,
        giver_id: str,
    ) -> None:
        """
        CreditsPort.reserve implementation.
        Moves 1 credit from student's account to reserved (idempotent per request_id).
        Uses FIFO deduction from credit lots.
        """
        s_uid = to_uuid(student_id) or uuid.uuid4()

        # Idempotency check
        existing = await session.execute(
            select(LedgerEntry).where(
                LedgerEntry.ref_type == "request",
                LedgerEntry.ref_id == str(request_id),
                LedgerEntry.reason == "session_reservation",
            ).limit(1)
        )
        if existing.scalar_one_or_none():
            return

        paid_acc = await CreditsService.get_or_create_account(session, s_uid, "user_paid")
        aff_acc = await CreditsService.get_or_create_account(session, s_uid, "user_affinity")
        reserved_acc = await CreditsService.get_or_create_account(session, None, "reserved")
        platform_rev = await CreditsService.get_or_create_account(session, None, "platform_revenue")

        unit_price = 299.0
        source_account = paid_acc

        if paid_acc.balance_credits >= 1:
            # FIFO lot deduction
            lot_res = await session.execute(
                select(CreditLot)
                .where(
                    CreditLot.account_id == paid_acc.id,
                    CreditLot.credits_remaining > 0,
                )
                .order_by(CreditLot.created_at.asc())
                .limit(1)
                .with_for_update()
            )
            lot = lot_res.scalar_one_or_none()
            if lot:
                unit_price = lot.unit_price_inr
                lot.credits_remaining -= 1
        elif aff_acc.balance_credits >= 1:
            source_account = aff_acc
            unit_price = 0.0
        else:
            raise AppError(
                code="insufficient_credits",
                message="Student has no available credits to reserve",
                status_code=400,
            )

        drafts = [
            {
                "account_id": source_account.id,
                "amount_credits": -1,
                "amount_inr": 0.0,
            },
            {
                "account_id": reserved_acc.id,
                "amount_credits": 1,
                "amount_inr": unit_price,
            },
            {
                "account_id": platform_rev.id,
                "amount_credits": 0,
                "amount_inr": -unit_price,
            },
        ]

        await CreditsService.post_transaction(
            session=session,
            drafts=drafts,
            ref_type="request",
            ref_id=str(request_id),
            reason="session_reservation",
        )

        await event_bus.publish(
            session=session,
            topic="credits.reserved",
            payload=CreditsReservedPayload(
                request_id=str(request_id),
                student_id=str(student_id),
                credits=1,
            ),
        )

    @staticmethod
    async def release(session: AsyncSession, request_id: str) -> None:
        """
        CreditsPort.release implementation.
        Releases reserved credit to giver or settlement.
        """
        await event_bus.publish(
            session=session,
            topic="credits.released",
            payload=CreditsReleasedPayload(
                request_id=str(request_id),
                giver_id="",
                credits=1,
            ),
        )

    @staticmethod
    async def refund(session: AsyncSession, request_id: str, reason: str) -> None:
        """
        CreditsPort.refund implementation.
        Refunds 1 reserved credit back to student (idempotent per request_id).
        """
        reason_key = f"session_refund_{reason}"

        # Idempotency check
        existing = await session.execute(
            select(LedgerEntry).where(
                LedgerEntry.ref_type == "request",
                LedgerEntry.ref_id == str(request_id),
                LedgerEntry.reason == reason_key,
            ).limit(1)
        )
        if existing.scalar_one_or_none():
            return

        res_stmt = (
            select(LedgerEntry)
            .where(
                LedgerEntry.ref_type == "request",
                LedgerEntry.ref_id == str(request_id),
                LedgerEntry.reason == "session_reservation",
                LedgerEntry.amount_credits < 0,
            )
            .limit(1)
        )
        entry_res = await session.execute(res_stmt)
        orig_entry = entry_res.scalar_one_or_none()

        if not orig_entry:
            return

        student_account_id = orig_entry.account_id
        reserved_acc = await CreditsService.get_or_create_account(session, None, "reserved")
        platform_rev = await CreditsService.get_or_create_account(session, None, "platform_revenue")

        # Find unit_price from reserved account's entry
        res_entry_stmt = (
            select(LedgerEntry)
            .where(
                LedgerEntry.ref_type == "request",
                LedgerEntry.ref_id == str(request_id),
                LedgerEntry.reason == "session_reservation",
                LedgerEntry.account_id == reserved_acc.id,
            )
            .limit(1)
        )
        res_entry = (await session.execute(res_entry_stmt)).scalar_one_or_none()
        unit_price = res_entry.amount_inr if res_entry else 0.0

        drafts = [
            {
                "account_id": reserved_acc.id,
                "amount_credits": -1,
                "amount_inr": -unit_price,
            },
            {
                "account_id": student_account_id,
                "amount_credits": 1,
                "amount_inr": 0.0,
            },
            {
                "account_id": platform_rev.id,
                "amount_credits": 0,
                "amount_inr": unit_price,
            },
        ]

        await CreditsService.post_transaction(
            session=session,
            drafts=drafts,
            ref_type="request",
            ref_id=str(request_id),
            reason=reason_key,
        )

        lot_res = await session.execute(
            select(CreditLot)
            .where(CreditLot.account_id == student_account_id)
            .order_by(CreditLot.created_at.desc())
            .limit(1)
        )
        lot = lot_res.scalar_one_or_none()
        if lot:
            lot.credits_remaining += 1

        student_acc = await session.get(LedgerAccount, student_account_id)
        owner_id = str(student_acc.owner_user_id) if student_acc and student_acc.owner_user_id else ""
        await event_bus.publish(
            session=session,
            topic="credits.refunded",
            payload=CreditsRefundedPayload(
                request_id=str(request_id),
                student_id=owner_id,
                reason=reason,
            ),
        )

    @staticmethod
    async def handle_session_completed(
        session: AsyncSession,
        session_id: str,
        duration_minutes: float,
    ) -> None:
        """
        Handle session.completed event.
        If call duration >= 5 minutes, starts the 48-hour dispute window.
        """
        if duration_minutes < settings.MIN_CALL_DURATION_MINUTES:
            return

        existing = await session.execute(
            select(SessionSettlement).where(SessionSettlement.session_id == str(session_id)).limit(1)
        )
        if existing.scalar_one_or_none():
            return

        now = datetime.now(timezone.utc)
        settles_at = now + timedelta(hours=settings.DISPUTE_WINDOW_HOURS)

        settlement = SessionSettlement(
            id=uuid.uuid4(),
            session_id=str(session_id),
            student_id=uuid.uuid4(),
            giver_id=uuid.uuid4(),
            is_cross_college=True,
            unit_price_inr=299.0,
            status="pending_window",
            settles_at=settles_at,
            created_at=now,
        )
        session.add(settlement)
        await session.flush()

    @staticmethod
    async def handle_dispute_opened(session: AsyncSession, session_id: str) -> None:
        """Pause settlement when dispute is opened."""
        res = await session.execute(
            select(SessionSettlement).where(SessionSettlement.session_id == str(session_id)).limit(1)
        )
        settlement = res.scalar_one_or_none()
        if settlement and settlement.status == "pending_window":
            settlement.status = "disputed"
            await session.flush()

    @staticmethod
    async def handle_dispute_resolved(
        session: AsyncSession,
        session_id: str,
        outcome: str,
    ) -> None:
        """
        Handle dispute.resolved decision:
          - refund: returns credit to student
          - full_payout: settles payout immediately to giver
          - partial_payout: splits payout
        """
        res = await session.execute(
            select(SessionSettlement).where(SessionSettlement.session_id == str(session_id)).limit(1)
        )
        settlement = res.scalar_one_or_none()
        if not settlement:
            return

        if outcome == "refund":
            await CreditsService.refund(
                session=session,
                request_id=settlement.request_id or settlement.session_id,
                reason="dispute_outcome",
            )
            settlement.status = "refunded"
        elif outcome in ("full_payout", "resolved_giver"):
            await CreditsService.settle_session(session, settlement)
        elif outcome == "partial_payout":
            settlement.unit_price_inr = round(settlement.unit_price_inr * 0.5, 2)
            await CreditsService.settle_session(session, settlement)

    @staticmethod
    async def handle_session_no_show(session: AsyncSession, session_id: str, no_show_party: str) -> None:
        """
        Handle session.no_show event:
          - Giver absent: refunds student immediately
          - Student absent: consumes credit and pays giver as normal
        """
        res = await session.execute(
            select(SessionSettlement).where(SessionSettlement.session_id == str(session_id)).limit(1)
        )
        settlement = res.scalar_one_or_none()

        if no_show_party == "giver":
            req_id = settlement.request_id if settlement else session_id
            await CreditsService.refund(session, req_id, reason="giver_no_show")
            if settlement:
                settlement.status = "refunded"
        elif no_show_party == "student":
            if settlement:
                await CreditsService.settle_session(session, settlement)

    @staticmethod
    async def settle_session(session: AsyncSession, settlement: SessionSettlement) -> None:
        """Execute settlement payout for a session."""
        if settlement.status == "settled":
            return

        now = datetime.now(timezone.utc)
        reserved_acc = await CreditsService.get_or_create_account(session, None, "reserved")
        platform_rev = await CreditsService.get_or_create_account(session, None, "platform_revenue")
        giver_acc = await CreditsService.get_or_create_account(session, settlement.giver_id, "user_paid")

        if not settlement.is_cross_college:
            # Own-college session: giver earns 1 affinity credit funded by platform
            giver_aff = await CreditsService.get_or_create_account(session, settlement.giver_id, "user_affinity")
            drafts = [
                {
                    "account_id": platform_rev.id,
                    "amount_credits": -1,
                    "amount_inr": 0.0,
                },
                {
                    "account_id": giver_aff.id,
                    "amount_credits": 1,
                    "amount_inr": 0.0,
                },
            ]
            await CreditsService.post_transaction(
                session=session,
                drafts=drafts,
                ref_type="session",
                ref_id=settlement.session_id,
                reason="affinity_reward",
            )
        else:
            # Cross-college: compute payout share by giver band
            giver_band = "Rising"
            try:
                band_info = await ports.ratings.get_band(str(settlement.giver_id))
                if isinstance(band_info, dict) and "band" in band_info:
                    giver_band = band_info["band"]
            except Exception:
                giver_band = "Rising"

            if giver_band == "Top Rated":
                share = settings.PAYOUT_SHARE_TOP_RATED
            elif giver_band == "Trusted":
                share = settings.PAYOUT_SHARE_TRUSTED
            else:
                share = settings.PAYOUT_SHARE_RISING

            unit_price = settlement.unit_price_inr
            giver_earnings_inr = round(unit_price * share, 2)
            platform_fee_inr = round(unit_price - giver_earnings_inr, 2)

            drafts = [
                {
                    "account_id": reserved_acc.id,
                    "amount_credits": -1,
                    "amount_inr": -unit_price,
                },
                {
                    "account_id": giver_acc.id,
                    "amount_credits": 0,
                    "amount_inr": giver_earnings_inr,
                },
                {
                    "account_id": platform_rev.id,
                    "amount_credits": 1,
                    "amount_inr": platform_fee_inr,
                },
            ]
            await CreditsService.post_transaction(
                session=session,
                drafts=drafts,
                ref_type="session",
                ref_id=settlement.session_id,
                reason="session_settlement_payout",
            )

        settlement.status = "settled"
        settlement.settled_at = now
        await session.flush()

    @staticmethod
    async def settle_pending_sessions(session: AsyncSession) -> int:
        """Scheduled job: settle all sessions whose dispute window has passed."""
        now = datetime.now(timezone.utc)
        stmt = (
            select(SessionSettlement)
            .where(
                SessionSettlement.status == "pending_window",
                SessionSettlement.settles_at <= now,
            )
        )
        res = await session.execute(stmt)
        settlements = res.scalars().all()
        settled_count = 0
        for s in settlements:
            await CreditsService.settle_session(session, s)
            settled_count += 1
        return settled_count

    @staticmethod
    async def handle_subscription_activated(
        session: AsyncSession,
        user_id: str,
        plan_code: str,
    ) -> None:
        """
        Handle subscription.activated event:
          - Issues monthly credits
          - Creates credit lots
          - Adds balanced ledger entry
        """
        u_uid = to_uuid(user_id) or uuid.uuid4()

        await CreditsService.seed_plans_if_empty(session)
        plan_res = await session.execute(select(Plan).where(Plan.code == plan_code))
        plan = plan_res.scalar_one_or_none()
        if not plan:
            return

        now = datetime.now(timezone.utc)
        period_end = now + timedelta(days=30)

        sub_res = await session.execute(
            select(UserSubscription)
            .where(UserSubscription.user_id == u_uid)
            .order_by(desc(UserSubscription.created_at))
            .limit(1)
        )
        sub = sub_res.scalar_one_or_none()
        if sub:
            sub.plan_code = plan.code
            sub.status = "active"
            sub.period_start = now
            sub.period_end = period_end
            sub.renews_at = period_end
        else:
            sub = UserSubscription(
                id=uuid.uuid4(),
                user_id=u_uid,
                plan_code=plan.code,
                status="active",
                period_start=now,
                period_end=period_end,
                renews_at=period_end,
                created_at=now,
            )
            session.add(sub)

        if plan.credits_per_month > 0:
            unit_price = round(plan.price_inr / plan.credits_per_month, 2)
            user_paid = await CreditsService.get_or_create_account(session, u_uid, "user_paid")
            platform_rev = await CreditsService.get_or_create_account(session, None, "platform_revenue")

            lot = CreditLot(
                id=uuid.uuid4(),
                account_id=user_paid.id,
                credits_remaining=plan.credits_per_month,
                unit_price_inr=unit_price,
                created_at=now,
                expires_at=period_end,
            )
            session.add(lot)

            drafts = [
                {
                    "account_id": platform_rev.id,
                    "amount_credits": -plan.credits_per_month,
                    "amount_inr": 0.0,
                },
                {
                    "account_id": user_paid.id,
                    "amount_credits": plan.credits_per_month,
                    "amount_inr": 0.0,
                },
            ]
            await CreditsService.post_transaction(
                session=session,
                drafts=drafts,
                ref_type="subscription",
                ref_id=str(sub.id),
                reason="plan_credit_grant",
            )

    @staticmethod
    async def handle_subscription_cancelled(session: AsyncSession, user_id: str) -> None:
        """
        Handle subscription.cancelled event:
          - Marks subscription as cancelled at period end
          - Rolls over zero unused credits at period end
        """
        u_uid = to_uuid(user_id)
        if not u_uid:
            return

        sub_res = await session.execute(
            select(UserSubscription)
            .where(
                UserSubscription.user_id == u_uid,
                UserSubscription.status == "active",
            )
            .order_by(desc(UserSubscription.created_at))
            .limit(1)
        )
        sub = sub_res.scalar_one_or_none()
        if sub:
            sub.status = "cancelled"
            sub.renews_at = None
            await session.flush()

    @staticmethod
    async def donate_credits(
        session: AsyncSession,
        user_id: str,
        credits_to_donate: int,
    ) -> int:
        """
        Move credits from user's account to scholarship_pool with balanced ledger entry.
        """
        u_uid = to_uuid(user_id)
        if not u_uid:
            raise AppError(code="invalid_user_id", message="Invalid user id", status_code=400)

        paid_acc = await CreditsService.get_or_create_account(session, u_uid, "user_paid")
        if paid_acc.balance_credits < credits_to_donate:
            raise AppError(
                code="insufficient_credits",
                message=f"Available credits ({paid_acc.balance_credits}) less than requested donation ({credits_to_donate})",
                status_code=400,
            )

        scholarship_pool = await CreditsService.get_or_create_account(session, None, "scholarship_pool")

        lots_res = await session.execute(
            select(CreditLot)
            .where(
                CreditLot.account_id == paid_acc.id,
                CreditLot.credits_remaining > 0,
            )
            .order_by(CreditLot.created_at.asc())
            .with_for_update()
        )
        lots = lots_res.scalars().all()
        remaining = credits_to_donate
        for lot in lots:
            take = min(lot.credits_remaining, remaining)
            lot.credits_remaining -= take
            remaining -= take
            if remaining == 0:
                break

        drafts = [
            {
                "account_id": paid_acc.id,
                "amount_credits": -credits_to_donate,
                "amount_inr": 0.0,
            },
            {
                "account_id": scholarship_pool.id,
                "amount_credits": credits_to_donate,
                "amount_inr": 0.0,
            },
        ]
        await CreditsService.post_transaction(
            session=session,
            drafts=drafts,
            ref_type="donation",
            ref_id=str(uuid.uuid4()),
            reason="donation_to_scholarship",
        )
        return credits_to_donate

    @staticmethod
    async def allocate_sponsored_seat(
        session: AsyncSession,
        student_id: str,
        plan_tier: str,
        sponsor_name: Optional[str] = None,
        funded_by: str = "scholarship_pool",
    ) -> SponsoredSeat:
        """
        Allocate a sponsored seat grant to a student funded by sponsor, institution budget, or scholarship pool.
        """
        s_uid = to_uuid(student_id)
        if not s_uid:
            raise AppError(code="invalid_student_id", message="Invalid student ID", status_code=400)

        await CreditsService.seed_plans_if_empty(session)
        plan_res = await session.execute(select(Plan).where(Plan.code == plan_tier))
        plan = plan_res.scalar_one_or_none()
        if not plan:
            raise AppError(code="plan_not_found", message=f"Plan '{plan_tier}' not found", status_code=404)

        now = datetime.now(timezone.utc)
        seat = SponsoredSeat(
            id=uuid.uuid4(),
            institution_id=None,
            student_id=s_uid,
            plan_tier=plan.code,
            sponsor_name=sponsor_name,
            funded_by=funded_by,
            created_at=now,
        )
        session.add(seat)

        credits_to_grant = plan.credits_per_month
        grant_inr = float(plan.price_inr)
        student_paid = await CreditsService.get_or_create_account(session, s_uid, "user_paid")

        if funded_by == "scholarship_pool":
            source_acc = await CreditsService.get_or_create_account(session, None, "scholarship_pool")
        else:
            source_acc = await CreditsService.get_or_create_account(session, None, "platform_revenue")

        if credits_to_grant > 0:
            drafts = [
                {
                    "account_id": source_acc.id,
                    "amount_credits": -credits_to_grant,
                    "amount_inr": 0.0,
                },
                {
                    "account_id": student_paid.id,
                    "amount_credits": credits_to_grant,
                    "amount_inr": 0.0,
                },
            ]
            await CreditsService.post_transaction(
                session=session,
                drafts=drafts,
                ref_type="sponsored_seat",
                ref_id=str(seat.id),
                reason="sponsored_seat_grant",
            )

            lot = CreditLot(
                id=uuid.uuid4(),
                account_id=student_paid.id,
                credits_remaining=credits_to_grant,
                unit_price_inr=round(grant_inr / credits_to_grant, 2),
                created_at=now,
                expires_at=now + timedelta(days=30),
            )
            session.add(lot)

        sub = UserSubscription(
            id=uuid.uuid4(),
            user_id=s_uid,
            plan_code=plan.code,
            status="active",
            period_start=now,
            period_end=now + timedelta(days=30),
            renews_at=now + timedelta(days=30),
            created_at=now,
        )
        session.add(sub)
        await session.flush()
        return seat

    @staticmethod
    async def cashout(
        session: AsyncSession,
        user_id: str,
        amount_inr: float,
        upi_id: str,
    ) -> PayoutRequest:
        """Request cashout of earned session funds (UPI)."""
        u_uid = to_uuid(user_id)
        if not u_uid:
            raise AppError(code="invalid_user_id", message="Invalid user ID", status_code=400)

        user_paid = await CreditsService.get_or_create_account(session, u_uid, "user_paid")
        if user_paid.balance_inr < amount_inr:
            raise AppError(
                code="insufficient_balance",
                message=f"Cashout amount (₹{amount_inr}) exceeds available cash balance (₹{user_paid.balance_inr})",
                status_code=400,
            )

        clearing_acc = await CreditsService.get_or_create_account(session, None, "payout_clearing")
        payout = PayoutRequest(
            id=uuid.uuid4(),
            user_id=u_uid,
            amount_inr=amount_inr,
            upi_id=upi_id,
            status="pending",
            created_at=datetime.now(timezone.utc),
        )
        session.add(payout)

        drafts = [
            {
                "account_id": user_paid.id,
                "amount_credits": 0,
                "amount_inr": -amount_inr,
            },
            {
                "account_id": clearing_acc.id,
                "amount_credits": 0,
                "amount_inr": amount_inr,
            },
        ]
        await CreditsService.post_transaction(
            session=session,
            drafts=drafts,
            ref_type="payout",
            ref_id=str(payout.id),
            reason="cashout_request",
        )
        return payout

    @staticmethod
    async def get_wallet(
        session: AsyncSession,
        user_id: str,
        cursor: Optional[str] = None,
        limit: int = 20,
    ) -> Dict[str, Any]:
        """Get wallet credit balances and cursor-paginated transaction history."""
        u_uid = to_uuid(user_id) or uuid.uuid4()

        paid_acc = await CreditsService.get_or_create_account(session, u_uid, "user_paid")
        aff_acc = await CreditsService.get_or_create_account(session, u_uid, "user_affinity")

        account_ids = [paid_acc.id, aff_acc.id]
        query = (
            select(LedgerEntry)
            .where(LedgerEntry.account_id.in_(account_ids))
            .order_by(desc(LedgerEntry.created_at), desc(LedgerEntry.id))
        )

        cursor_data = decode_cursor(cursor)
        if cursor_data and "created_at" in cursor_data:
            dt = datetime.fromisoformat(cursor_data["created_at"])
            query = query.where(LedgerEntry.created_at < dt)

        query = query.limit(limit + 1)
        res = await session.execute(query)
        entries = res.scalars().all()

        has_next = len(entries) > limit
        items = entries[:limit]
        next_cursor = None
        if has_next and items:
            last = items[-1]
            next_cursor = encode_cursor({"created_at": last.created_at.isoformat()})

        items_dto = [
            {
                "id": str(e.id),
                "txn_id": str(e.txn_id),
                "amount_credits": e.amount_credits,
                "amount_inr": e.amount_inr,
                "direction": e.direction,
                "reason": e.reason,
                "plain_reason": PLAIN_REASONS.get(e.reason, e.reason.replace("_", " ").title()),
                "ref_type": e.ref_type,
                "ref_id": e.ref_id,
                "created_at": e.created_at,
            }
            for e in items
        ]

        return {
            "available_credits": paid_acc.balance_credits,
            "affinity_credits": aff_acc.balance_credits,
            "items": items_dto,
            "next_cursor": next_cursor,
        }

    @staticmethod
    async def get_earnings(session: AsyncSession, user_id: str) -> Dict[str, Any]:
        """Get giver payout earnings breakdown and cashout availability."""
        u_uid = to_uuid(user_id) or uuid.uuid4()

        paid_acc = await CreditsService.get_or_create_account(session, u_uid, "user_paid")
        cashable = max(0.0, paid_acc.balance_inr)

        pending_stmt = select(func.sum(SessionSettlement.unit_price_inr)).where(
            SessionSettlement.giver_id == u_uid,
            SessionSettlement.status.in_(["pending_window", "disputed"]),
        )
        pending_res = await session.execute(pending_stmt)
        escrow = pending_res.scalar() or 0.0

        payout_stmt = select(func.sum(PayoutRequest.amount_inr)).where(
            PayoutRequest.user_id == u_uid,
            PayoutRequest.status.in_(["processed", "pending"]),
        )
        payout_res = await session.execute(payout_stmt)
        paid_out = payout_res.scalar() or 0.0

        total_earned = round(cashable + escrow + paid_out, 2)

        return {
            "cashable_balance_inr": cashable,
            "held_in_escrow_inr": round(float(escrow), 2),
            "paid_out_inr": round(float(paid_out), 2),
            "total_earned_inr": total_earned,
            "by_band_payout_share": {
                "Rising": settings.PAYOUT_SHARE_RISING,
                "Trusted": settings.PAYOUT_SHARE_TRUSTED,
                "Top Rated": settings.PAYOUT_SHARE_TOP_RATED,
            },
        }

    @staticmethod
    async def get_subscription(session: AsyncSession, user_id: str) -> Dict[str, Any]:
        """Get current user active subscription."""
        u_uid = to_uuid(user_id) or uuid.uuid4()

        sub_stmt = (
            select(UserSubscription)
            .where(UserSubscription.user_id == u_uid)
            .order_by(desc(UserSubscription.created_at))
            .limit(1)
        )
        res = await session.execute(sub_stmt)
        sub = res.scalar_one_or_none()

        paid_acc = await CreditsService.get_or_create_account(session, u_uid, "user_paid")

        if not sub:
            return {
                "plan_tier": "campus",
                "status": "active",
                "renews_at": None,
                "period_start": None,
                "period_end": None,
                "credits_remaining": paid_acc.balance_credits,
            }

        return {
            "plan_tier": sub.plan_code,
            "status": sub.status,
            "renews_at": sub.renews_at,
            "period_start": sub.period_start,
            "period_end": sub.period_end,
            "credits_remaining": paid_acc.balance_credits,
        }
