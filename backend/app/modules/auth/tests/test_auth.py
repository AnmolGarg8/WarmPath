"""
backend/app/modules/auth/tests/test_auth.py - Comprehensive tests for Auth & Verification module.
"""

import json

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.redis as core_redis
from app.core.db import Institution, OutboxEvent
from app.modules.auth.models import ApprovedMember


@pytest.mark.asyncio
async def test_domain_rejection(async_client: AsyncClient, db_session: AsyncSession):
    # Setup institution if not exists
    inst_res = await db_session.execute(select(Institution).where(Institution.name == "Vivekananda Institute"))
    inst = inst_res.scalar_one_or_none()
    if not inst:
        inst = Institution(
            name="Vivekananda Institute",
            short_name="VIPS",
            city="Delhi",
            email_domains=["vips.edu"],
        )
        db_session.add(inst)
        await db_session.commit()

    # Attempt to request OTP for an unknown/unsupported email domain
    res = await async_client.post("/auth/request-otp", json={"email": "hacker@randommail.org"})
    assert res.status_code == 422
    data = res.json()
    assert data["error"]["code"] == "institution_not_supported"


@pytest.mark.asyncio
async def test_full_otp_and_login_flow(async_client: AsyncClient, db_session: AsyncSession):
    # Ensure institution exists
    inst_res = await db_session.execute(select(Institution).where(Institution.name == "Vivekananda Institute"))
    inst = inst_res.scalar_one_or_none()
    if not inst:
        inst = Institution(name="Vivekananda Institute", short_name="VIPS", city="Delhi", email_domains=["vips.edu"])
        db_session.add(inst)
        await db_session.commit()

    test_email = "student1@vips.edu"

    # 1. Request OTP
    req_res = await async_client.post("/auth/request-otp", json={"email": test_email})
    assert req_res.status_code == 200
    req_data = req_res.json()
    assert req_data["email"] == test_email
    assert "code" not in req_data  # OTP must never be returned!

    # 2. Extract code from Redis state (for testing)
    r = await core_redis.get_redis()
    raw_otp = await r.get(f"otp:{test_email}")
    assert raw_otp is not None
    otp_info = json.loads(raw_otp)
    assert "salt" in otp_info
    assert "hash" in otp_info

    # In our test environment, test with an OTP code by creating a known candidate
    salt = otp_info["salt"]
    test_code = "654321"
    import hashlib
    otp_info["hash"] = hashlib.sha256(f"{salt}:{test_code}".encode()).hexdigest()
    await r.set(f"otp:{test_email}", json.dumps(otp_info), ex=600)

    # 3. Verify OTP
    ver_res = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": test_code})
    assert ver_res.status_code == 200
    auth_data = ver_res.json()

    assert "access_token" in auth_data
    assert "refresh_token" in auth_data
    assert auth_data["is_new"] is True
    assert auth_data["user"]["email"] == test_email
    assert auth_data["user"]["verification_level"] == "email_only"
    assert auth_data["user"]["trust_level"] == "new"

    # Verify OTP was deleted from Redis after success
    assert await r.get(f"otp:{test_email}") is None


@pytest.mark.asyncio
async def test_wrong_code_attempts(async_client: AsyncClient, db_session: AsyncSession):
    test_email = "student_attempts@vips.edu"

    # Request OTP
    await async_client.post("/auth/request-otp", json={"email": test_email})

    # Try invalid code 5 times
    for i in range(1, 5):
        res = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": "000000"})
        assert res.status_code == 400
        data = res.json()
        assert data["error"]["code"] == "invalid_otp"

    # 5th failed attempt: returns max attempts or invalid
    res = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": "000000"})
    assert res.status_code in [400, 429]

    # Subsequent attempt after max attempts
    res_after = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": "000000"})
    assert res_after.status_code in [400, 429]


@pytest.mark.asyncio
async def test_rate_limits(async_client: AsyncClient, db_session: AsyncSession):
    test_email = "ratelimit_user@vips.edu"

    # 3 successful requests allowed per hour
    for _ in range(3):
        res = await async_client.post("/auth/request-otp", json={"email": test_email})
        assert res.status_code == 200

    # 4th request must be rejected with 429
    res = await async_client.post("/auth/request-otp", json={"email": test_email})
    assert res.status_code == 429
    assert res.json()["error"]["code"] == "rate_limit_exceeded"


@pytest.mark.asyncio
async def test_refresh_rotation_and_reuse_detection(async_client: AsyncClient, db_session: AsyncSession):
    test_email = "refresh_user@vips.edu"

    # Request and login
    await async_client.post("/auth/request-otp", json={"email": test_email})
    r = await core_redis.get_redis()
    raw_otp = await r.get(f"otp:{test_email}")
    otp_info = json.loads(raw_otp)
    salt = otp_info["salt"]
    test_code = "123456"
    import hashlib
    otp_info["hash"] = hashlib.sha256(f"{salt}:{test_code}".encode()).hexdigest()
    await r.set(f"otp:{test_email}", json.dumps(otp_info), ex=600)

    login_res = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": test_code})
    refresh_token_1 = login_res.json()["refresh_token"]

    # 1. Normal Refresh -> returns new access token and rotated refresh token
    ref_res = await async_client.post("/auth/refresh", json={"refresh_token": refresh_token_1})
    assert ref_res.status_code == 200
    ref_data = ref_res.json()
    refresh_token_2 = ref_data["refresh_token"]
    assert refresh_token_2 != refresh_token_1

    # 2. Token Reuse Attempt! Using refresh_token_1 again
    reuse_res = await async_client.post("/auth/refresh", json={"refresh_token": refresh_token_1})
    assert reuse_res.status_code == 401
    assert reuse_res.json()["error"]["code"] == "token_reuse_detected"

    # 3. Whole family revoked! refresh_token_2 is now also revoked
    revoked_res = await async_client.post("/auth/refresh", json={"refresh_token": refresh_token_2})
    assert revoked_res.status_code == 401


@pytest.mark.asyncio
async def test_approved_list_matching(async_client: AsyncClient, db_session: AsyncSession):
    # Pre-seed approved member
    inst_res = await db_session.execute(select(Institution).where(Institution.name == "Vivekananda Institute"))
    inst = inst_res.scalar_one()

    approved = ApprovedMember(
        institution_id=inst.id,
        email="approved_alum@vips.edu",
        full_name="Tanush Alum",
        role="alumnus",
        batch="2022",
        department="Computer Science",
    )
    db_session.add(approved)
    await db_session.commit()

    # Request and login
    await async_client.post("/auth/request-otp", json={"email": "approved_alum@vips.edu"})
    r = await core_redis.get_redis()
    raw = await r.get("otp:approved_alum@vips.edu")
    otp_info = json.loads(raw)
    salt = otp_info["salt"]
    test_code = "777888"
    import hashlib
    otp_info["hash"] = hashlib.sha256(f"{salt}:{test_code}".encode()).hexdigest()
    await r.set("otp:approved_alum@vips.edu", json.dumps(otp_info), ex=600)

    ver_res = await async_client.post("/auth/verify-otp", json={"email": "approved_alum@vips.edu", "code": test_code})
    assert ver_res.status_code == 200
    user_data = ver_res.json()["user"]

    # Assert automatic verification and badges
    assert user_data["verification_level"] == "verified"
    assert "alumnus" in user_data["roles"]
    assert "Verified Alumnus" in user_data["badges"]

    # Verify event published to outbox
    outbox_res = await db_session.execute(
        select(OutboxEvent).where(OutboxEvent.topic == "user.verified")
    )
    outbox_events = outbox_res.scalars().all()
    assert len(outbox_events) > 0


@pytest.mark.asyncio
async def test_verification_request_lifecycle(async_client: AsyncClient, db_session: AsyncSession):
    test_email = "student_verify_req@vips.edu"

    # Login
    await async_client.post("/auth/request-otp", json={"email": test_email})
    r = await core_redis.get_redis()
    raw = await r.get(f"otp:{test_email}")
    otp_info = json.loads(raw)
    salt = otp_info["salt"]
    test_code = "111222"
    import hashlib
    otp_info["hash"] = hashlib.sha256(f"{salt}:{test_code}".encode()).hexdigest()
    await r.set(f"otp:{test_email}", json.dumps(otp_info), ex=600)

    login_res = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": test_code})
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Submit verification request
    submit_res = await async_client.post(
        "/verification/submit",
        json={
            "kind": "alumnus",
            "evidence_text": "Graduated in 2023 with B.Tech degree, roll number 04517702020.",
            "evidence_urls": ["https://example.com/degree.pdf"],
        },
        headers=headers,
    )
    assert submit_res.status_code == 201
    assert submit_res.json()["status"] == "pending"

    # 2. Check status
    status_res = await async_client.get("/verification/status", headers=headers)
    assert status_res.status_code == 200
    status_data = status_res.json()
    assert len(status_data["pending_requests"]) == 1
    assert status_data["pending_requests"][0]["kind"] == "alumnus"


@pytest.mark.asyncio
async def test_me_profile_and_dpdp_delete_and_export(async_client: AsyncClient, db_session: AsyncSession):
    test_email = "profile_user@vips.edu"

    # Login
    await async_client.post("/auth/request-otp", json={"email": test_email})
    r = await core_redis.get_redis()
    raw = await r.get(f"otp:{test_email}")
    otp_info = json.loads(raw)
    salt = otp_info["salt"]
    test_code = "999000"
    import hashlib
    otp_info["hash"] = hashlib.sha256(f"{salt}:{test_code}".encode()).hexdigest()
    await r.set(f"otp:{test_email}", json.dumps(otp_info), ex=600)

    login_res = await async_client.post("/auth/verify-otp", json={"email": test_email, "code": test_code})
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. GET /me
    me_res = await async_client.get("/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == test_email

    # 2. PATCH /me
    patch_res = await async_client.patch(
        "/me",
        json={"display_name": "Anmol Dev", "headline": "Software Engineer & Builder"},
        headers=headers,
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["display_name"] == "Anmol Dev"
    assert patch_res.json()["headline"] == "Software Engineer & Builder"

    # 3. GET /me/data-export
    export_res = await async_client.get("/me/data-export", headers=headers)
    assert export_res.status_code == 200
    export_data = export_res.json()
    assert export_data["user"]["email"] == test_email
    assert "exported_at" in export_data

    # 4. DELETE /me
    del_res = await async_client.delete("/me", headers=headers)
    assert del_res.status_code == 200

    # 5. Subsequent request must be rejected with 401
    post_del_res = await async_client.get("/me", headers=headers)
    assert post_del_res.status_code == 401
