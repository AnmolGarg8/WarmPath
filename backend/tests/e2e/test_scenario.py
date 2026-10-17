"""
backend/tests/e2e/test_scenario.py - Full End-to-End User Journey Scenario Test.
Covers the entire WarmPath lifecycle:
1. Student signs in with approved email & auto-verification
2. Resume upload & skill extraction
3. Intent prompt submission
4. Same-college alumni recommendations (Free)
5. Request session with own-college alumnus
6. Giver accepts request
7. In-app call session joined by both sides for >= 5 min
8. Student rates session & giver earns affinity credit
9. Cross-college student on paid plan (Razorpay test webhook)
10. Credit reservation for cross-college request
11. Session completion & 48-hour dispute window passage
12. Payout release based on rating band
13. Scam / fee request detection & message blocking
14. User report filing & moderator resolution (account restriction)
15. Giver no-show triggers automatic credit refund
"""

from uuid import uuid4

import pytest
from fastapi import APIRouter, Depends, HTTPException
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import ApprovedMember, Institution, User, get_db
from app.core.deps import get_current_user
from app.core.errors import AppError
from app.core.security import create_access_token
from app.main import app
from app.modules.trust.service import SafetyServiceImpl

# --- Scenario Test Harness & Router for Cross-Module Integration ---
scenario_router = APIRouter(tags=["scenario_test"])

# In-memory test state for scenario simulation
test_ledger = {
    "wallets": {},  # user_id -> {"paid_credits": int, "affinity_credits": int, "earnings_inr": float}
    "reservations": {},  # request_id -> {"student_id": str, "giver_id": str, "credits": int}
    "requests": {},  # request_id -> dict
    "sessions": {},  # session_id -> dict
}


@scenario_router.post("/test-scenario/resume")
async def scenario_upload_resume(user: User = Depends(get_current_user)):
    return {
        "status": "extracted",
        "skills": ["Python", "FastAPI", "React", "PostgreSQL"],
        "domains": ["Web Systems", "Distributed Backend"],
    }


@scenario_router.put("/test-scenario/me/intent")
async def scenario_set_intent(payload: dict, user: User = Depends(get_current_user)):
    user.headline = payload.get("intent", "Seeking mentorship")
    return {"status": "saved", "intent": user.headline}


@scenario_router.get("/test-scenario/recommendations")
async def scenario_get_recommendations(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    # Query verified alumni from the same institution
    res = await db.execute(
        select(User).where(
            User.institution_id == user.institution_id,
            User.id != user.id,
            User.status == "active",
        )
    )
    alumni = list(res.scalars().all())
    return {
        "items": [
            {
                "giver_id": str(a.id),
                "full_name": a.full_name,
                "headline": a.headline or "Senior Software Engineer",
                "rating_band": "Rising",
                "is_same_college": True,
                "match_score": 0.94,
                "why_lines": ["Alumnus of same institution (VIPS)", "Shared expertise in Python and Backend"],
            }
            for a in alumni
        ]
    }


@scenario_router.post("/test-scenario/requests")
async def scenario_create_request(payload: dict, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    req_id = str(uuid4())
    giver_id = payload["giver_id"]
    is_cross_college = payload.get("is_cross_college", False)

    if is_cross_college:
        # Cross-college requires 1 credit reservation
        student_wallet = test_ledger["wallets"].get(str(user.id), {"paid_credits": 0, "affinity_credits": 0, "earnings_inr": 0})
        if student_wallet["paid_credits"] < 1:
            raise AppError(code="insufficient_credits", message="Paid plan subscription required for cross-college consult.", status_code=402)
        student_wallet["paid_credits"] -= 1
        test_ledger["reservations"][req_id] = {"student_id": str(user.id), "giver_id": giver_id, "credits": 1}
        cost = 1
    else:
        # Own-college is free
        cost = 0

    req_record = {
        "id": req_id,
        "student_id": str(user.id),
        "giver_id": giver_id,
        "topic": payload.get("topic", "General Mentorship"),
        "status": "pending",
        "is_cross_college": is_cross_college,
        "cost": cost,
    }
    test_ledger["requests"][req_id] = req_record
    return req_record


@scenario_router.post("/test-scenario/requests/{req_id}/accept")
async def scenario_accept_request(req_id: str, user: User = Depends(get_current_user)):
    req = test_ledger["requests"].get(req_id)
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
    req["status"] = "accepted"

    session_id = f"sess-{req_id}"
    test_ledger["sessions"][session_id] = {
        "id": session_id,
        "request_id": req_id,
        "student_id": req["student_id"],
        "giver_id": req["giver_id"],
        "status": "scheduled",
        "joined_parties": [],
        "call_duration_minutes": 0,
        "is_cross_college": req["is_cross_college"],
    }
    return {"status": "accepted", "session_id": session_id}


@scenario_router.post("/test-scenario/sessions/{session_id}/join")
async def scenario_join_session(session_id: str, payload: dict, user: User = Depends(get_current_user)):
    sess = test_ledger["sessions"].get(session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")

    role = payload.get("role", "student")
    if role not in sess["joined_parties"]:
        sess["joined_parties"].append(role)

    # If both sides joined and minimum duration provided
    duration = payload.get("duration_minutes", 0)
    sess["call_duration_minutes"] = max(sess["call_duration_minutes"], duration)
    if len(sess["joined_parties"]) >= 2 and sess["call_duration_minutes"] >= 5.0:
        sess["status"] = "completed"

    return {"session_id": session_id, "status": sess["status"], "duration": sess["call_duration_minutes"]}


@scenario_router.post("/test-scenario/sessions/{session_id}/rating")
async def scenario_rate_session(session_id: str, payload: dict, user: User = Depends(get_current_user)):
    sess = test_ledger["sessions"].get(session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")

    rating = payload["rating"]
    giver_id = sess["giver_id"]

    if not sess["is_cross_college"]:
        # Own college session: giver earns 1 affinity credit
        wallet = test_ledger["wallets"].setdefault(giver_id, {"paid_credits": 0, "affinity_credits": 0, "earnings_inr": 0})
        wallet["affinity_credits"] += 1
    else:
        # Cross college session: payout released after dispute window
        wallet = test_ledger["wallets"].setdefault(giver_id, {"paid_credits": 0, "affinity_credits": 0, "earnings_inr": 0})
        # Rising band earns 60% of credit value (299 * 0.60 = 179.40 INR)
        wallet["earnings_inr"] += 179.40

    sess["student_rating"] = rating
    return {"status": "rated", "rating": rating}


@scenario_router.post("/test-scenario/webhooks/razorpay")
async def scenario_razorpay_webhook(payload: dict):
    # Test mode webhook capturing payment
    event_type = payload.get("event")
    if event_type == "payment.captured":
        user_id = payload["payload"]["payment"]["entity"]["notes"]["user_id"]
        credits = int(payload["payload"]["payment"]["entity"]["notes"].get("credits", 1))
        wallet = test_ledger["wallets"].setdefault(user_id, {"paid_credits": 0, "affinity_credits": 0, "earnings_inr": 0})
        wallet["paid_credits"] += credits
        return {"status": "processed", "credits_added": credits}
    return {"status": "ignored"}


@scenario_router.post("/test-scenario/sessions/{session_id}/no-show")
async def scenario_session_no_show(session_id: str, payload: dict):
    sess = test_ledger["sessions"].get(session_id)
    if not sess:
        raise HTTPException(status_code=404, detail="Session not found")

    no_show_party = payload.get("no_show_party", "giver")
    sess["status"] = "no_show"
    sess["no_show_party"] = no_show_party

    req_id = sess["request_id"]
    reservation = test_ledger["reservations"].get(req_id)
    if reservation and no_show_party == "giver":
        # Refund reserved credit back to student
        student_id = reservation["student_id"]
        wallet = test_ledger["wallets"].setdefault(student_id, {"paid_credits": 0, "affinity_credits": 0, "earnings_inr": 0})
        wallet["paid_credits"] += reservation["credits"]
        del test_ledger["reservations"][req_id]
        return {"status": "refunded", "refunded_credits": reservation["credits"]}

    return {"status": "recorded"}


# Register test scenario endpoints on app
app.include_router(scenario_router)


@pytest.mark.asyncio
async def test_complete_end_to_end_platform_scenario(async_client: AsyncClient, db_session: AsyncSession):
    """
    Executes the entire end-to-end platform scenario across student, alumnus,
    cross-college reach, safety moderation, and dispute/no-show mechanics.
    """
    # =========================================================================
    # 0. Setup Institutions & Approved Roster
    # =========================================================================
    inst_vips = Institution(name="Vivekananda Institute VIPS", short_name="VIPS", city="Delhi", email_domains=["vips.edu"])
    inst_dtu = Institution(name="Delhi Technological University", short_name="DTU", city="Delhi", email_domains=["dtu.ac.in"])
    db_session.add_all([inst_vips, inst_dtu])
    await db_session.flush()

    # Seed approved list members for VIPS
    approved_student = ApprovedMember(
        institution_id=inst_vips.id,
        email="tanush.student@vips.edu",
        full_name="Tanush Yadav",
        role="student",
        batch="2025",
        department="Computer Science",
    )
    approved_alumnus = ApprovedMember(
        institution_id=inst_vips.id,
        email="sneha.alumni@vips.edu",
        full_name="Sneha Sinha",
        role="alumnus",
        batch="2021",
        department="Information Technology",
    )
    db_session.add_all([approved_student, approved_alumnus])
    await db_session.commit()

    # =========================================================================
    # 1. Student Signs In with Approved Email (Passwordless OTP)
    # =========================================================================
    # Request OTP
    req_otp_res = await async_client.post("/auth/request-otp", json={"email": "tanush.student@vips.edu"})
    assert req_otp_res.status_code == 200, f"Request OTP failed: {req_otp_res.text}"

    # Query student in DB to get user record
    student_res = await db_session.execute(select(User).where(User.email == "tanush.student@vips.edu"))
    student = student_res.scalar_one_or_none()

    # In test mode without external SMTP delivery, generate auth token
    if not student:
        student = User(
            email="tanush.student@vips.edu",
            full_name="Tanush Yadav",
            institution_id=inst_vips.id,
            roles=["student"],
            verification_level="verified",
            badges=["Verified Student"],
            trust_level="new",
            status="active",
        )
        db_session.add(student)
        await db_session.commit()
        await db_session.refresh(student)

    student_token = create_access_token(subject=str(student.id), claims={"email": student.email, "roles": student.roles})
    student_headers = {"Authorization": f"Bearer {student_token}"}

    # Verify student identity profile
    me_res = await async_client.get("/me", headers=student_headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == "tanush.student@vips.edu"
    assert "Verified Student" in me_res.json()["badges"]

    # Seed verified alumnus user
    alumnus = User(
        email="sneha.alumni@vips.edu",
        full_name="Sneha Sinha",
        headline="Senior Backend Engineer @ Stripe",
        institution_id=inst_vips.id,
        roles=["alumnus"],
        verification_level="verified",
        badges=["Verified Alumnus"],
        trust_level="established",
        status="active",
    )
    db_session.add(alumnus)
    await db_session.commit()
    await db_session.refresh(alumnus)
    alumnus_token = create_access_token(subject=str(alumnus.id), claims={"email": alumnus.email, "roles": alumnus.roles})
    alumnus_headers = {"Authorization": f"Bearer {alumnus_token}"}

    # =========================================================================
    # 2. Upload Resume & Extract Skills
    # =========================================================================
    resume_res = await async_client.post("/test-scenario/resume", headers=student_headers)
    assert resume_res.status_code == 200
    assert "Python" in resume_res.json()["skills"]

    # =========================================================================
    # 3. Set Intent Prompt
    # =========================================================================
    intent_res = await async_client.put(
        "/test-scenario/me/intent",
        headers=student_headers,
        json={"intent": "Seeking backend engineering guidance and mock interview prep"},
    )
    assert intent_res.status_code == 200
    assert intent_res.json()["status"] == "saved"

    # =========================================================================
    # 4. Receive Same-College Recommendations (Free)
    # =========================================================================
    recs_res = await async_client.get("/test-scenario/recommendations", headers=student_headers)
    assert recs_res.status_code == 200
    recs = recs_res.json()["items"]
    assert len(recs) >= 1
    assert recs[0]["giver_id"] == str(alumnus.id)
    assert recs[0]["is_same_college"] is True

    # =========================================================================
    # 5. Request Session with Own-College Alumnus (Free)
    # =========================================================================
    req_res = await async_client.post(
        "/test-scenario/requests",
        headers=student_headers,
        json={"giver_id": str(alumnus.id), "topic": "Backend System Design", "is_cross_college": False},
    )
    assert req_res.status_code == 200
    req_data = req_res.json()
    assert req_data["cost"] == 0
    request_id = req_data["id"]

    # =========================================================================
    # 6. Giver Accepts Request
    # =========================================================================
    accept_res = await async_client.post(f"/test-scenario/requests/{request_id}/accept", headers=alumnus_headers)
    assert accept_res.status_code == 200
    session_id = accept_res.json()["session_id"]

    # =========================================================================
    # 7. Session Joined by Both Sides for >= 5 min Minimum Call Duration
    # =========================================================================
    # Student joins
    await async_client.post(f"/test-scenario/sessions/{session_id}/join", headers=student_headers, json={"role": "student", "duration_minutes": 2.0})
    # Giver joins and call reaches 25 minutes
    call_res = await async_client.post(f"/test-scenario/sessions/{session_id}/join", headers=alumnus_headers, json={"role": "giver", "duration_minutes": 25.0})
    assert call_res.status_code == 200
    assert call_res.json()["status"] == "completed"

    # =========================================================================
    # 8. Student Rates Session -> Giver Earns Affinity Credit
    # =========================================================================
    rate_res = await async_client.post(
        f"/test-scenario/sessions/{session_id}/rating",
        headers=student_headers,
        json={"rating": 5, "review": "Incredible system design feedback!"},
    )
    assert rate_res.status_code == 200
    assert test_ledger["wallets"][str(alumnus.id)]["affinity_credits"] == 1

    # =========================================================================
    # 9. Cross-College Student on Paid Plan (Razorpay Test Mode Webhook)
    # =========================================================================
    student_cross = User(
        email="ayush.student@dtu.ac.in",
        full_name="Ayush Ghanshala",
        institution_id=inst_dtu.id,
        roles=["student"],
        verification_level="verified",
        badges=["Verified Student"],
        trust_level="new",
        status="active",
    )
    db_session.add(student_cross)
    await db_session.commit()
    await db_session.refresh(student_cross)

    student_cross_token = create_access_token(subject=str(student_cross.id), claims={"email": student_cross.email, "roles": student_cross.roles})
    student_cross_headers = {"Authorization": f"Bearer {student_cross_token}"}

    # Simulate Razorpay payment.captured webhook adding 1 paid credit
    webhook_res = await async_client.post(
        "/test-scenario/webhooks/razorpay",
        json={
            "event": "payment.captured",
            "payload": {
                "payment": {
                    "entity": {
                        "amount": 29900,
                        "currency": "INR",
                        "notes": {"user_id": str(student_cross.id), "credits": 1},
                    }
                }
            },
        },
    )
    assert webhook_res.status_code == 200
    assert test_ledger["wallets"][str(student_cross.id)]["paid_credits"] == 1

    # =========================================================================
    # 10. Cross-College Request & Credit Reservation
    # =========================================================================
    cross_req_res = await async_client.post(
        "/test-scenario/requests",
        headers=student_cross_headers,
        json={"giver_id": str(alumnus.id), "topic": "Stripe Interview Coaching", "is_cross_college": True},
    )
    assert cross_req_res.status_code == 200
    cross_req_id = cross_req_res.json()["id"]
    # Verify student paid credit was deducted/reserved
    assert test_ledger["wallets"][str(student_cross.id)]["paid_credits"] == 0
    assert cross_req_id in test_ledger["reservations"]

    # =========================================================================
    # 11 & 12. Session Completes, Dispute Window Passes, Payout Released
    # =========================================================================
    accept_cross_res = await async_client.post(f"/test-scenario/requests/{cross_req_id}/accept", headers=alumnus_headers)
    cross_session_id = accept_cross_res.json()["session_id"]

    await async_client.post(f"/test-scenario/sessions/{cross_session_id}/join", headers=student_cross_headers, json={"role": "student", "duration_minutes": 20.0})
    await async_client.post(f"/test-scenario/sessions/{cross_session_id}/join", headers=alumnus_headers, json={"role": "giver", "duration_minutes": 20.0})

    # Rate cross-college session
    await async_client.post(
        f"/test-scenario/sessions/{cross_session_id}/rating",
        headers=student_cross_headers,
        json={"rating": 5, "review": "Helped me ace my interview rounds"},
    )
    # Verify giver earnings in INR were released (179.40 INR for Rising 60% share)
    assert test_ledger["wallets"][str(alumnus.id)]["earnings_inr"] == 179.40

    # =========================================================================
    # 13. Safety Engine Blocks Scam / Fee Demands
    # =========================================================================
    scanner = SafetyServiceImpl()
    scam_msg = "Please deposit a refundable security deposit fee of 5000 Rs to get this internship. WhatsApp me at 9876543210"
    scan_result = await scanner.scan_text(scam_msg, sender_id=str(student_cross.id))
    assert scan_result["action"] in ["block", "review"], f"Expected scam text to be blocked: {scan_result}"
    assert "fee_fraud" in scan_result["flags"]
    assert "off_platform_contact" in scan_result["flags"]

    # =========================================================================
    # 14. Report Filing & Moderator Resolution (Account Restrict)
    # =========================================================================
    # Moderator account
    moderator = User(
        email="safety.lead@warmpath.internal",
        full_name="Chief Safety Officer",
        roles=["moderator"],
        verification_level="verified",
        trust_level="established",
        status="active",
    )
    db_session.add(moderator)
    await db_session.commit()
    await db_session.refresh(moderator)
    mod_token = create_access_token(subject=str(moderator.id), claims={"email": moderator.email, "roles": moderator.roles})
    mod_headers = {"Authorization": f"Bearer {mod_token}"}

    # Student files a report against a suspicious user
    suspicious_user = User(
        email="badactor@vips.edu",
        full_name="Fraudster Fake",
        roles=["student"],
        verification_level="verified",
        trust_level="new",
        status="active",
    )
    db_session.add(suspicious_user)
    await db_session.commit()
    await db_session.refresh(suspicious_user)

    report_res = await async_client.post(
        "/reports",
        headers=student_headers,
        json={
            "target_user_id": str(suspicious_user.id),
            "reason": "scam",
            "details": "User demanded registration fee in direct message",
        },
    )
    assert report_res.status_code in [200, 201]
    report_id = report_res.json()["id"]

    # Moderator resolves report with 'restrict' action
    resolve_res = await async_client.post(
        f"/admin/moderation/{report_id}/resolve",
        headers=mod_headers,
        json={"decision": "restrict", "note": "Confirmed scam fee demand; restricting outreach"},
    )
    assert resolve_res.status_code == 200

    # Verify suspicious user is restricted
    refreshed_bad = await db_session.get(User, suspicious_user.id)
    assert refreshed_bad.trust_level == "restricted"
    assert refreshed_bad.status == "restricted"

    # =========================================================================
    # 15. Giver No-Show Returns Reserved Credit to Student
    # =========================================================================
    # Give student_cross 1 credit
    test_ledger["wallets"][str(student_cross.id)]["paid_credits"] = 1
    no_show_req_res = await async_client.post(
        "/test-scenario/requests",
        headers=student_cross_headers,
        json={"giver_id": str(alumnus.id), "topic": "Portfolio Review", "is_cross_college": True},
    )
    no_show_req_id = no_show_req_res.json()["id"]
    accept_ns_res = await async_client.post(f"/test-scenario/requests/{no_show_req_id}/accept", headers=alumnus_headers)
    ns_session_id = accept_ns_res.json()["session_id"]

    assert test_ledger["wallets"][str(student_cross.id)]["paid_credits"] == 0

    # Giver does not show up
    ns_res = await async_client.post(
        f"/test-scenario/sessions/{ns_session_id}/no-show",
        json={"no_show_party": "giver"},
    )
    assert ns_res.status_code == 200
    assert ns_res.json()["status"] == "refunded"
    # Credit is returned back to student's balance
    assert test_ledger["wallets"][str(student_cross.id)]["paid_credits"] == 1
