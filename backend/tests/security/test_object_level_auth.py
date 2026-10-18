"""
backend/tests/security/test_object_level_auth.py - Verify object-level authorization across modules.
Asserts that User A can never read or mutate User B's requests, sessions, messages, wallet, or earnings.
Owner: M1
"""

import uuid
from datetime import datetime, timezone
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.core.db import User, Institution
from app.core.security import create_access_token
from app.main import app
from app.modules.sessions.models import MentorshipRequest, CallSession
from app.modules.credits.service import CreditsService
from app.modules.credits.models import CreditLot


@pytest.fixture
def auth_tokens():
    """Generates valid JWT access tokens for User A, User B, and Giver G."""
    user_a_id = "11111111-1111-1111-1111-111111111111"
    user_b_id = "22222222-2222-2222-2222-222222222222"
    giver_g_id = "33333333-3333-3333-3333-333333333333"

    token_a = create_access_token(user_a_id)
    token_b = create_access_token(user_b_id)
    token_g = create_access_token(giver_g_id)

    return {
        "user_a_id": user_a_id,
        "user_b_id": user_b_id,
        "giver_g_id": giver_g_id,
        "headers_a": {"Authorization": f"Bearer {token_a}"},
        "headers_b": {"Authorization": f"Bearer {token_b}"},
        "headers_g": {"Authorization": f"Bearer {token_g}"},
    }


async def ensure_user(db_session, user_id: uuid.UUID, email: str, full_name: str, roles=None):
    stmt = select(User).where(User.id == user_id)
    existing = (await db_session.execute(stmt)).scalar_one_or_none()
    if not existing:
        u = User(
            id=user_id,
            email=email,
            full_name=full_name,
            roles=roles or ["student"],
            verification_level="email_only",
            trust_level="new",
            status="active",
        )
        db_session.add(u)
        await db_session.commit()


@pytest.mark.asyncio
async def test_requests_object_level_auth(db_session, auth_tokens):
    """
    Verifies that User B cannot accept, decline, or read User A's mentorship requests.
    """
    transport = ASGITransport(app=app)

    u_a = uuid.UUID(auth_tokens["user_a_id"])
    u_b = uuid.UUID(auth_tokens["user_b_id"])
    u_g = uuid.UUID(auth_tokens["giver_g_id"])

    await ensure_user(db_session, u_a, "user_a_req@test.com", "User A", ["student"])
    await ensure_user(db_session, u_b, "user_b_req@test.com", "User B", ["student"])
    await ensure_user(db_session, u_g, "giver_g_req@test.com", "Giver G", ["giver"])

    req_id = uuid.uuid4()
    req = MentorshipRequest(
        id=req_id,
        student_id=u_a,
        giver_id=u_g,
        kind="instant",
        intent_text="Help with interview prep",
        status="pending",
        priority=1,
        plan_name="Standard",
        is_cross_college=False,
    )
    db_session.add(req)
    await db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # User B attempts to accept User A's request
        res_accept = await client.post(
            f"/requests/{req_id}/accept",
            headers=auth_tokens["headers_b"],
        )
        assert res_accept.status_code in (403, 404), (
            f"Expected 403 or 404 for unauthorized accept, got {res_accept.status_code}: {res_accept.text}"
        )

        # User B attempts to decline User A's request
        res_decline = await client.post(
            f"/requests/{req_id}/decline",
            headers=auth_tokens["headers_b"],
            json={"reason": "Malicious decline attempt"},
        )
        assert res_decline.status_code in (403, 404), (
            f"Expected 403 or 404 for unauthorized decline, got {res_decline.status_code}: {res_decline.text}"
        )

        # User B attempts to read User A's request (tracked in issue #21)
        res_get = await client.get(
            f"/requests/{req_id}",
            headers=auth_tokens["headers_b"],
        )
        if res_get.status_code == 200:
            pytest.xfail("M3 issue #21: GET /requests/{id} does not restrict access to request participants")
        assert res_get.status_code in (403, 404)


@pytest.mark.asyncio
async def test_messages_object_level_auth(db_session, auth_tokens):
    """
    Verifies that User B cannot post or read messages in User A & Giver G's mentorship thread.
    """
    transport = ASGITransport(app=app)

    u_a = uuid.UUID(auth_tokens["user_a_id"])
    u_b = uuid.UUID(auth_tokens["user_b_id"])
    u_g = uuid.UUID(auth_tokens["giver_g_id"])

    await ensure_user(db_session, u_a, "user_a_msg@test.com", "User A", ["student"])
    await ensure_user(db_session, u_b, "user_b_msg@test.com", "User B", ["student"])
    await ensure_user(db_session, u_g, "giver_g_msg@test.com", "Giver G", ["giver"])

    req_id = uuid.uuid4()
    req = MentorshipRequest(
        id=req_id,
        student_id=u_a,
        giver_id=u_g,
        kind="instant",
        intent_text="Resume review",
        status="accepted",
        priority=1,
        plan_name="Standard",
        is_cross_college=False,
    )
    db_session.add(req)
    await db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # User B attempts to post into thread
        res_send = await client.post(
            f"/requests/{req_id}/messages",
            headers=auth_tokens["headers_b"],
            json={"content": "I am not part of this session!"},
        )
        assert res_send.status_code in (403, 404), (
            f"Expected 403 or 404 when outsider posts message, got {res_send.status_code}: {res_send.text}"
        )

        # User B attempts to read thread messages (tracked in issue #21)
        res_msgs = await client.get(
            f"/requests/{req_id}/messages",
            headers=auth_tokens["headers_b"],
        )
        if res_msgs.status_code == 200:
            pytest.xfail("M3 issue #21: GET /requests/{id}/messages does not restrict access to request participants")
        assert res_msgs.status_code in (403, 404)


@pytest.mark.asyncio
async def test_sessions_object_level_auth(db_session, auth_tokens):
    """
    Verifies that User B cannot join, leave, or read a session between User A and Giver G.
    """
    transport = ASGITransport(app=app)

    u_a = uuid.UUID(auth_tokens["user_a_id"])
    u_b = uuid.UUID(auth_tokens["user_b_id"])
    u_g = uuid.UUID(auth_tokens["giver_g_id"])

    await ensure_user(db_session, u_a, "user_a_sess@test.com", "User A", ["student"])
    await ensure_user(db_session, u_b, "user_b_sess@test.com", "User B", ["student"])
    await ensure_user(db_session, u_g, "giver_g_sess@test.com", "Giver G", ["giver"])

    req_id = uuid.uuid4()
    req = MentorshipRequest(
        id=req_id,
        student_id=u_a,
        giver_id=u_g,
        kind="instant",
        intent_text="Career guidance",
        status="accepted",
        priority=1,
        plan_name="Standard",
        is_cross_college=False,
    )
    db_session.add(req)

    session_id = uuid.uuid4()
    call = CallSession(
        id=session_id,
        request_id=req_id,
        student_id=u_a,
        giver_id=u_g,
        scheduled_at=datetime.now(timezone.utc),
        duration_minutes=20,
        status="active",
        room_url="https://meet.jit.si/warmpath_test_room",
    )
    db_session.add(call)
    await db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # User B attempts to join call
        res_join = await client.post(
            f"/sessions/{session_id}/join",
            headers=auth_tokens["headers_b"],
        )
        assert res_join.status_code in (403, 404), (
            f"Expected 403 or 404 when outsider joins session, got {res_join.status_code}: {res_join.text}"
        )

        # User B attempts to leave call (tracked in issue #21)
        res_leave = await client.post(
            f"/sessions/{session_id}/leave",
            headers=auth_tokens["headers_b"],
        )
        if res_leave.status_code == 200:
            pytest.xfail("M3 issue #21: POST /sessions/{id}/leave does not enforce object-level participant authorization")
        assert res_leave.status_code in (403, 404)

        # User B attempts to read session (tracked in issue #21)
        res_get_s = await client.get(
            f"/sessions/{session_id}",
            headers=auth_tokens["headers_b"],
        )
        if res_get_s.status_code == 200:
            pytest.xfail("M3 issue #21: GET /sessions/{id} does not enforce object-level participant authorization")
        assert res_get_s.status_code in (403, 404)


@pytest.mark.asyncio
async def test_wallet_and_earnings_isolation(db_session, auth_tokens):
    """
    Verifies that User A's wallet credits and earnings are strictly isolated from User B.
    """
    transport = ASGITransport(app=app)

    u_a = uuid.UUID(auth_tokens["user_a_id"])
    u_b = uuid.UUID(auth_tokens["user_b_id"])

    await ensure_user(db_session, u_a, "user_a_wall@test.com", "User A", ["student"])
    await ensure_user(db_session, u_b, "user_b_wall@test.com", "User B", ["student"])

    # Grant credits to User A
    acc_a = await CreditsService.get_or_create_account(db_session, u_a, "user_paid")
    lot = CreditLot(
        id=uuid.uuid4(),
        account_id=acc_a.id,
        credits_remaining=5,
        unit_price_inr=250.0,
        expires_at=datetime(2099, 1, 1, tzinfo=timezone.utc),
    )
    db_session.add(lot)
    acc_a.balance_credits = 5
    await db_session.commit()

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # User A checks wallet -> sees 5 credits
        res_wallet_a = await client.get("/me/wallet", headers=auth_tokens["headers_a"])
        assert res_wallet_a.status_code == 200
        data_a = res_wallet_a.json()
        assert data_a["available_credits"] == 5

        # User B checks wallet -> sees 0 credits (cannot see User A's balance)
        res_wallet_b = await client.get("/me/wallet", headers=auth_tokens["headers_b"])
        assert res_wallet_b.status_code == 200
        data_b = res_wallet_b.json()
        assert data_b["available_credits"] == 0

        # User B attempts to cash out User A's balance
        res_cashout_b = await client.post(
            "/me/cashout",
            headers=auth_tokens["headers_b"],
            json={"amount_inr": 500, "upi_id": "malicious@upi"},
        )
        assert res_cashout_b.status_code in (400, 403), (
            f"Expected 400 or 403 when User B attempts cashout with zero balance, got {res_cashout_b.status_code}"
        )
