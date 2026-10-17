"""
backend/tests/e2e/test_data_safety.py - DPDP Compliance & Data Safety Verification.
Verifies that DELETE /me removes personal data across modules via transactional events,
and GET /me/data-export covers every module in a structured JSON payload.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import ApprovedMember, Institution, OutboxEvent, User
from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_data_export_covers_all_modules(async_client: AsyncClient, db_session: AsyncSession):
    """
    Verifies that GET /me/data-export produces a complete export
    covering user details, verification requests, and modular domains.
    """
    # 1. Seed user and institution
    inst = Institution(
        name="VIPS Delhi",
        short_name="VIPS",
        city="Delhi",
        email_domains=["vips.edu"],
    )
    db_session.add(inst)
    await db_session.flush()

    user = User(
        email="dpdp.export@vips.edu",
        full_name="Pooja Sharma",
        headline="AI & Data Science Student",
        institution_id=inst.id,
        roles=["student"],
        verification_level="verified",
        badges=["Verified Student"],
        trust_level="verified",
        status="active",
    )
    db_session.add(user)

    approved = ApprovedMember(
        institution_id=inst.id,
        email="dpdp.export@vips.edu",
        full_name="Pooja Sharma",
        role="student",
        batch="2025",
        department="Computer Science",
    )
    db_session.add(approved)
    await db_session.commit()
    await db_session.refresh(user)

    token = create_access_token(subject=str(user.id), claims={"email": user.email, "roles": user.roles})
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Call GET /me/data-export
    res = await async_client.get("/me/data-export", headers=headers)
    assert res.status_code == 200, f"Data export failed: {res.text}"

    data = res.json()
    assert "user" in data
    assert data["user"]["email"] == "dpdp.export@vips.edu"
    assert data["user"]["full_name"] == "Pooja Sharma"

    assert "approved_member_record" in data
    assert data["approved_member_record"]["department"] == "Computer Science"

    assert "modules_data" in data
    modules = data["modules_data"]

    # Verify coverage across all modules
    assert "auth" in modules, "Data export must include auth module data"
    assert "trust" in modules, "Data export must include trust module data"
    assert "resume" in modules, "Data export must include resume module data"
    assert "sessions" in modules, "Data export must include sessions module data"
    assert "ratings" in modules, "Data export must include ratings module data"
    assert "credits" in modules, "Data export must include credits module data"
    assert "payments" in modules, "Data export must include payments module data"

    assert "exported_at" in data


@pytest.mark.asyncio
async def test_delete_me_anonymizes_and_publishes_event(async_client: AsyncClient, db_session: AsyncSession):
    """
    Verifies that DELETE /me anonymizes personal data and publishes
    a 'user.deleted' event to the transactional outbox to notify other modules.
    """
    user = User(
        email="dpdp.delete@vips.edu",
        full_name="Aman Gupta",
        display_name="Aman G",
        headline="Full Stack Developer",
        roles=["student"],
        verification_level="verified",
        badges=["Verified Student"],
        trust_level="new",
        status="active",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    token = create_access_token(subject=str(user.id), claims={"email": user.email, "roles": user.roles})
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Call DELETE /me
    res = await async_client.delete("/me", headers=headers)
    assert res.status_code == 200, f"DELETE /me failed: {res.text}"
    assert "deleted successfully" in res.json().get("message", "")

    # 2. Verify user record is anonymized in DB
    refreshed_user = await db_session.get(User, user.id)
    assert refreshed_user.status == "deleted"
    assert refreshed_user.full_name == "Deactivated Member"
    assert refreshed_user.display_name is None
    assert refreshed_user.headline is None
    assert refreshed_user.badges == []

    # 3. Verify 'user.deleted' outbox event was recorded in DB
    events_res = await db_session.execute(
        select(OutboxEvent).where(
            OutboxEvent.topic == "user.deleted",
        ).order_by(OutboxEvent.created_at.desc())
    )
    events = list(events_res.scalars().all())
    assert len(events) > 0, "No 'user.deleted' event found in transactional outbox!"

    matching_event = next((e for e in events if e.payload.get("user_id") == str(user.id)), None)
    assert matching_event is not None, "Outbox event does not carry deleted user's id"
    assert matching_event.payload.get("email") == "dpdp.delete@vips.edu"
    assert matching_event.payload.get("reason") == "user_requested_deletion"
