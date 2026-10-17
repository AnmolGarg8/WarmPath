"""
backend/app/modules/trust/tests/test_trust.py - Comprehensive tests for Trust & Safety module.
"""

import io
from datetime import UTC, datetime
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.redis as core_redis
from app.core.db import ApprovedMember, Institution, OutboxEvent, User, VerificationRequest
from app.core.security import create_access_token
from app.modules.trust.models import AuditLog, Report
from app.modules.trust.service import (
    SafetyServiceImpl,
    TrustFactors,
    TrustServiceImpl,
    compute_trust_level,
)

# --- 1. Scam Rules Table & Benign Message Tests ---

@pytest.mark.asyncio
async def test_scam_rules_table_and_benign_messages():
    scanner = SafetyServiceImpl()
    sender_id = str(uuid4())

    # Scam & Malicious Samples (Must be blocked or warned)
    scam_test_cases = [
        ("Please pay the registration fee to confirm your referral.", "block", "fee_fraud"),
        ("Send the r e g i s t r a t i o n   f e e to HR account immediately.", "block", "fee_fraud"),
        ("A refundable s-e-c-u-r-i-t-y  d-e-p-o-s-i-t of 2000 is required.", "block", "fee_fraud"),
        ("You must pay to get the job offer letter.", "block", "fee_fraud"),
        ("Connect on w.h.a.t.s.a.p.p at 9876543210 for offline talks.", "warn", "off_platform_contact"),
        ("Reach out on t.me/fakechannel right now.", "warn", "off_platform_contact"),
        ("Download details here: bit.ly/freejobdeal", "warn", "shortened_link"),
    ]

    for text, expected_action, expected_flag in scam_test_cases:
        result = await scanner.scan_text(text, sender_id, context="chat")
        assert result["action"] == expected_action, f"Failed for text: {text}"
        assert expected_flag in result["flags"], f"Missing flag {expected_flag} for text: {text}"

    # Benign Samples (Must pass cleanly with action='allow' and no flags)
    benign_test_cases = [
        "Hi Anmol, excited to connect about your software engineering experience at VIPS!",
        "Can you share how you prepared for backend system design interviews?",
        "Here is my open-source project on GitHub: https://github.com/warmpath/warmpath",
        "Looking forward to our scheduled mentoring call tomorrow at 5 PM.",
        "Could you recommend good resources to learn distributed systems with PostgreSQL?",
    ]

    for text in benign_test_cases:
        result = await scanner.scan_text(text, sender_id, context="chat")
        assert result["action"] == "allow", f"Benign message was incorrectly flagged: {text}"
        assert len(result["flags"]) == 0, f"Unexpected flags for benign message: {text}"


# --- 2. Trust Level Pure Computation Table Tests ---

def test_trust_level_computation_table():
    test_cases = [
        # factors, expected_level
        (TrustFactors(verification_level="email_only"), "new"),
        (TrustFactors(verification_level="verified", account_age_days=5, completed_sessions=2), "verified"),
        (
            TrustFactors(
                verification_level="verified",
                account_age_days=15,
                completed_sessions=6,
                total_sessions=6,
                upheld_reports=0,
            ),
            "established",
        ),
        (
            TrustFactors(
                verification_level="verified",
                account_age_days=20,
                completed_sessions=6,
                total_sessions=10,  # 60% completion rate (< 90%)
                upheld_reports=0,
            ),
            "verified",
        ),
        (
            TrustFactors(
                verification_level="verified",
                account_age_days=30,
                completed_sessions=10,
                total_sessions=10,
                upheld_reports=2,  # 2 upheld reports -> restricted
            ),
            "restricted",
        ),
        (
            TrustFactors(
                verification_level="verified",
                is_admin_restricted=True,
            ),
            "restricted",
        ),
    ]

    for factors, expected in test_cases:
        assert compute_trust_level(factors) == expected


# --- 3. Daily Limit Enforcement & TrustPort Tests ---

@pytest.mark.asyncio
async def test_daily_limit_and_trust_port(db_session: AsyncSession):
    from tests.conftest import test_session_maker
    trust_port = TrustServiceImpl(test_session_maker)

    # Create new test user
    test_user = User(
        id=uuid4(),
        email="trust_limit_user@vips.edu",
        full_name="Limit Tester",
        verification_level="email_only",
        trust_level="new",
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add(test_user)
    await db_session.commit()

    user_id_str = str(test_user.id)

    # 1. get_level
    level = await trust_port.get_level(user_id_str)
    assert level == "new"

    # 2. Daily requests limit (3 for 'new')
    r = await core_redis.get_redis()
    today_utc = datetime.now(UTC).strftime("%Y-%m-%d")
    key = f"ratelimit:requests:{user_id_str}:{today_utc}"

    # First request: allowed
    can_res_1 = await trust_port.can(user_id_str, "send_request")
    assert can_res_1["allowed"] is True

    # Simulate 3 requests made
    await r.set(key, 3)

    # 4th request: blocked by daily limit
    can_res_limit = await trust_port.can(user_id_str, "send_request")
    assert can_res_limit["allowed"] is False
    assert "Daily request limit" in can_res_limit["reason"]

    # 3. Message review on restricted account
    test_user.trust_level = "restricted"
    await db_session.commit()

    can_msg = await trust_port.can(user_id_str, "send_message")
    assert can_msg["allowed"] is True
    assert can_msg["reviewed_first"] is True

    # 4. Post opportunity
    can_post = await trust_port.can(user_id_str, "post_opportunity")
    assert can_post["allowed"] is False


# --- 4. Blocks & TrustPort.is_blocked Tests ---

@pytest.mark.asyncio
async def test_blocks_and_trust_port_is_blocked(async_client: AsyncClient, db_session: AsyncSession):
    user_a = User(
        id=uuid4(),
        email="user_a@vips.edu",
        full_name="User A",
        status="active",
        created_at=datetime.now(UTC),
    )
    user_b = User(
        id=uuid4(),
        email="user_b@vips.edu",
        full_name="User B",
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add_all([user_a, user_b])
    await db_session.commit()

    token_a = create_access_token(str(user_a.id))
    headers_a = {"Authorization": f"Bearer {token_a}"}

    from tests.conftest import test_session_maker
    trust_port = TrustServiceImpl(test_session_maker)

    # Initial state: not blocked
    assert await trust_port.is_blocked(str(user_a.id), str(user_b.id)) is False

    # Cannot block self
    self_res = await async_client.post(
        "/blocks",
        json={"blocked_user_id": str(user_a.id)},
        headers=headers_a,
    )
    assert self_res.status_code == 400

    # User A blocks User B
    block_res = await async_client.post(
        "/blocks",
        json={"blocked_user_id": str(user_b.id), "reason": "Spam outreach"},
        headers=headers_a,
    )
    assert block_res.status_code == 201

    # Both directions are blocked
    assert await trust_port.is_blocked(str(user_a.id), str(user_b.id)) is True
    assert await trust_port.is_blocked(str(user_b.id), str(user_a.id)) is True

    # User A unblocks User B
    unblock_res = await async_client.delete(f"/blocks/{user_b.id}", headers=headers_a)
    assert unblock_res.status_code == 200

    # Now not blocked
    assert await trust_port.is_blocked(str(user_a.id), str(user_b.id)) is False


# --- 5. Reports & Auto-Restriction Flow Tests ---

@pytest.mark.asyncio
async def test_reports_and_auto_restriction_flow(async_client: AsyncClient, db_session: AsyncSession):
    reporter = User(
        id=uuid4(),
        email="reporter@vips.edu",
        full_name="Reporter User",
        status="active",
        created_at=datetime.now(UTC),
    )
    target = User(
        id=uuid4(),
        email="bad_actor@vips.edu",
        full_name="Suspicious Actor",
        trust_level="new",
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add_all([reporter, target])
    await db_session.commit()

    token = create_access_token(str(reporter.id))
    headers = {"Authorization": f"Bearer {token}"}

    # Submit 2 reports
    for i in range(2):
        res = await async_client.post(
            "/reports",
            json={
                "target_user_id": str(target.id),
                "reason": "scam",
                "details": f"Attempt {i+1} to solicit money off-platform",
            },
            headers=headers,
        )
        assert res.status_code == 201

    await db_session.refresh(target)
    assert target.trust_level == "new"

    # 3rd report triggers automatic restriction!
    res_3 = await async_client.post(
        "/reports",
        json={
            "target_user_id": str(target.id),
            "reason": "scam",
            "details": "Attempt 3: asking for registration fee",
        },
        headers=headers,
    )
    assert res_3.status_code == 201

    await db_session.refresh(target)
    assert target.trust_level == "restricted"
    assert target.status == "restricted"

    # Verify audit log entry and outbox events
    audit_res = await db_session.execute(
        select(AuditLog).where(
            AuditLog.target_id == str(target.id),
            AuditLog.action == "user.auto_restricted",
        )
    )
    audit = audit_res.scalar_one_or_none()
    assert audit is not None


# --- 6. GET /me/trust Endpoint Tests ---

@pytest.mark.asyncio
async def test_get_me_trust(async_client: AsyncClient, db_session: AsyncSession):
    user = User(
        id=uuid4(),
        email="me_trust@vips.edu",
        full_name="Trust Me",
        verification_level="verified",
        trust_level="verified",
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add(user)
    await db_session.commit()

    token = create_access_token(str(user.id))
    headers = {"Authorization": f"Bearer {token}"}

    res = await async_client.get("/me/trust", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["trust_level"] == "verified"
    assert data["requests_per_day_limit"] == 10
    assert data["can_post_jobs"] is True
    assert data["messages_reviewed_first"] is False


# --- 7. Moderation Queue & Resolution with Audit Log Tests ---

@pytest.mark.asyncio
async def test_moderation_queue_and_resolution(async_client: AsyncClient, db_session: AsyncSession):
    # Setup moderator and target
    moderator = User(
        id=uuid4(),
        email="mod@warmpath.internal",
        full_name="Moderator One",
        roles=["moderator"],
        status="active",
        created_at=datetime.now(UTC),
    )
    reported = User(
        id=uuid4(),
        email="reported_student@vips.edu",
        full_name="Reported Student",
        trust_level="verified",
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add_all([moderator, reported])
    await db_session.commit()

    mod_token = create_access_token(str(moderator.id))
    headers = {"Authorization": f"Bearer {mod_token}"}

    # Create report in DB
    rep = Report(
        id=uuid4(),
        reporter_id=moderator.id,
        target_user_id=reported.id,
        reason="fee_fraud",
        details="Asked for deposit in chat",
        status="pending",
        created_at=datetime.now(UTC),
    )
    db_session.add(rep)
    await db_session.commit()

    # 1. List moderation queue
    queue_res = await async_client.get("/admin/moderation/queue", headers=headers)
    assert queue_res.status_code == 200
    items = queue_res.json()["items"]
    assert any(i["id"] == str(rep.id) for i in items)

    # 2. Resolve moderation: restrict target
    resolve_res = await async_client.post(
        f"/admin/moderation/{rep.id}/resolve",
        json={"decision": "restrict", "note": "Confirmed money solicitation"},
        headers=headers,
    )
    assert resolve_res.status_code == 200

    await db_session.refresh(reported)
    assert reported.trust_level == "restricted"

    # 3. Check audit log
    audit_res = await async_client.get(
        f"/admin/audit-log?target_id={rep.id}",
        headers=headers,
    )
    assert audit_res.status_code == 200
    audit_items = audit_res.json()["items"]
    assert len(audit_items) > 0
    assert audit_items[0]["action"] == "moderation.resolve"


# --- 8. Verification Queue & Decision Tests ---

@pytest.mark.asyncio
async def test_verification_queue_and_decision(async_client: AsyncClient, db_session: AsyncSession):
    inst_res = await db_session.execute(select(Institution).where(Institution.name == "Vivekananda Institute"))
    inst = inst_res.scalar_one()

    admin = User(
        id=uuid4(),
        email="inst_admin@vips.edu",
        full_name="Institution Admin",
        institution_id=inst.id,
        roles=["institution_admin"],
        status="active",
        created_at=datetime.now(UTC),
    )
    applicant = User(
        id=uuid4(),
        email="applicant@vips.edu",
        full_name="Applicant Alum",
        institution_id=inst.id,
        verification_level="email_only",
        roles=["student"],
        badges=[],
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add_all([admin, applicant])
    await db_session.commit()

    req = VerificationRequest(
        user_id=applicant.id,
        kind="alumnus",
        evidence_text="Degree certificate batch 2022",
        evidence_urls=["https://vips.edu/degree.pdf"],
        status="pending",
        created_at=datetime.now(UTC),
    )
    db_session.add(req)
    await db_session.commit()

    admin_token = create_access_token(str(admin.id))
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Fetch verification queue
    queue_res = await async_client.get("/admin/verification/queue", headers=headers)
    assert queue_res.status_code == 200
    items = queue_res.json()["items"]
    assert any(i["id"] == str(req.id) for i in items)

    # 2. Decide verification: approve
    decide_res = await async_client.post(
        f"/admin/verification/{req.id}/decide",
        json={"decision": "approve", "badge": "Verified Alumnus", "note": "Verified against registrar"},
        headers=headers,
    )
    assert decide_res.status_code == 200

    await db_session.refresh(applicant)
    assert applicant.verification_level == "verified"
    assert "Verified Alumnus" in applicant.badges

    # Check user.verified event published
    event_res = await db_session.execute(
        select(OutboxEvent).where(OutboxEvent.topic == "user.verified")
    )
    assert len(event_res.scalars().all()) > 0


# --- 9. Approved Members CSV Upload Tests ---

@pytest.mark.asyncio
async def test_approved_members_csv_upload(async_client: AsyncClient, db_session: AsyncSession):
    inst_res = await db_session.execute(select(Institution).where(Institution.name == "Vivekananda Institute"))
    inst = inst_res.scalar_one()

    admin = User(
        id=uuid4(),
        email="super_admin@warmpath.internal",
        full_name="Super Admin",
        roles=["platform_admin"],
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add(admin)
    await db_session.commit()

    token = create_access_token(str(admin.id))
    headers = {"Authorization": f"Bearer {token}"}

    csv_data = (
        b"full_name,email,role,batch,department\n"
        b"Sneha Sinha,sneha_upload@vips.edu,student,2024,IT\n"
        b"Ayush Ghanshala,ayush_upload@vips.edu,alumnus,2021,CSE\n"
    )

    files = {"file": ("roster.csv", io.BytesIO(csv_data), "text/csv")}
    data = {"institution_id": str(inst.id)}

    upload_res = await async_client.post(
        "/admin/approved-members/upload",
        files=files,
        data=data,
        headers=headers,
    )
    assert upload_res.status_code == 200
    report = upload_res.json()
    assert report["total_rows"] == 2
    assert report["inserted"] == 2
    assert report["duplicates_skipped"] == 0

    # Verify members inserted in DB
    mem_res = await db_session.execute(
        select(ApprovedMember).where(ApprovedMember.email == "sneha_upload@vips.edu")
    )
    assert mem_res.scalar_one_or_none() is not None


# --- 10. Role Scoping & Authorization Tests ---

@pytest.mark.asyncio
async def test_role_scoping_and_forbidden_access(async_client: AsyncClient, db_session: AsyncSession):
    student = User(
        id=uuid4(),
        email="plain_student@vips.edu",
        full_name="Plain Student",
        roles=["student"],
        status="active",
        created_at=datetime.now(UTC),
    )
    db_session.add(student)
    await db_session.commit()

    token = create_access_token(str(student.id))
    headers = {"Authorization": f"Bearer {token}"}

    # Student denied access to admin queue
    res = await async_client.get("/admin/moderation/queue", headers=headers)
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "insufficient_role"
