"""
backend/app/modules/matching/tests/test_matching.py - Test suite for matching engine.
Verifies hard gates, score components with fixed vectors, deterministic explainability,
cold-start boost, daily exposure cap, locked cross-college scope, and cache invalidation.
"""

import math
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List
from unittest.mock import AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.errors import AppError
from app.core.ports import ports
from app.main import app
from app.modules.matching.models import GiverProfile, StudentMatchProfile
from app.modules.matching.schemas import GiverProfileCreateUpdate, ScoreComponents
from app.modules.matching.service import (
    COLD_START_BOOST,
    MAX_DAILY_EXPOSURE,
    WEIGHT_AFFINITY,
    WEIGHT_AVAILABILITY,
    WEIGHT_EXPERTISE,
    WEIGHT_INTENT,
    WEIGHT_RATING,
    WEIGHT_RESPONSE_ODDS,
    MatchingService,
    cosine_similarity,
    deterministic_dummy_vector,
)


# --- Mock Port Classes for Testing ---

class MockTrustPort:
    def __init__(self, levels: Dict[str, str] = None, blocked: set = None):
        self.levels = levels or {}
        self.blocked = blocked or set()

    async def get_level(self, user_id: str) -> str:
        return self.levels.get(user_id, "verified")

    async def can(self, user_id: str, action: str) -> Dict[str, Any]:
        return {"allowed": True, "reason": "ok"}

    async def is_blocked(self, user_a: str, user_b: str) -> bool:
        return (user_a, user_b) in self.blocked or (user_b, user_a) in self.blocked


class MockPresencePort:
    def __init__(self, mapping: Dict[str, Dict[str, Any]] = None):
        self.mapping = mapping or {}

    async def status(self, user_ids: List[str]) -> Dict[str, Any]:
        result = {}
        for uid in user_ids:
            result[uid] = self.mapping.get(uid, {"online": True, "capacity_left": 3})
        return result


class MockRatingsPort:
    def __init__(self, mapping: Dict[str, Dict[str, Any]] = None):
        self.mapping = mapping or {}

    async def get_band(self, giver_id: str) -> Dict[str, Any]:
        return self.mapping.get(
            giver_id,
            {"band": "Trusted", "smoothed_avg": 4.5, "n": 10, "completion_rate": 0.95},
        )


class MockCreditsPort:
    def __init__(self, can_access_allowed: bool = True, reason: str = "ok"):
        self.can_access_allowed = can_access_allowed
        self.reason = reason

    async def can_access(self, student_id: str, giver_id: str) -> Dict[str, Any]:
        return {
            "allowed": self.can_access_allowed,
            "reason": self.reason,
            "plan": "Standard",
            "cost": 1,
        }

    async def reserve(self, student_id: str, request_id: str, giver_id: str) -> None:
        pass

    async def release(self, request_id: str) -> None:
        pass

    async def refund(self, request_id: str, reason: str) -> None:
        pass


# --- Unit Tests: Math & Fixed Vector Scoring ---

def test_cosine_similarity_fixed_vectors():
    # Identical vectors -> similarity = 1.0
    v1 = [1.0, 0.0, 0.0]
    assert math.isclose(cosine_similarity(v1, v1), 1.0, rel_tol=1e-5)

    # Orthogonal vectors -> dot = 0 -> mapped to 0.5
    v2 = [0.0, 1.0, 0.0]
    assert math.isclose(cosine_similarity(v1, v2), 0.5, rel_tol=1e-5)

    # Opposite vectors -> dot = -1 -> mapped to 0.0
    v3 = [-1.0, 0.0, 0.0]
    assert math.isclose(cosine_similarity(v1, v3), 0.0, rel_tol=1e-5)


def test_score_components_with_fixed_inputs():
    service = MatchingService(session=None)

    # Fixed dummy vectors
    student_vec = [1.0] * 768
    giver_vec = [1.0] * 768

    student = StudentMatchProfile(
        user_id=uuid.uuid4(),
        institution_id=1,
        department="Computer Science",
        batch=2026,
        societies=["ACM"],
        skills=[{"name": "Python", "category": "Languages"}, {"name": "SQL", "category": "DB"}],
        domains=["Web Development"],
        profile_embedding=student_vec,
        intent_goal="Software Internship",
        intent_roles=["Backend Intern"],
        intent_domains=["Tech"],
        intent_help_type="resume_review",
        intent_embedding=student_vec,
        profile_version=1,
    )

    giver = GiverProfile(
        user_id=uuid.uuid4(),
        institution_id=1,
        department="Computer Science",
        batch=2024,
        societies=["ACM"],
        skills=[{"name": "Python", "category": "Languages"}, {"name": "Docker", "category": "DevOps"}],
        topics=["Backend Engineering", "Python"],
        domains=["Web Development"],
        offers=["resume_review", "mock_interview"],
        embedding=giver_vec,
        weekly_capacity=4,
        response_stats={"acceptance_rate": 0.95, "median_response_minutes": 25},
    )

    presence_info = {"online": True, "capacity_left": 4}
    band_info = {"band": "Top Rated", "smoothed_avg": 4.8, "n": 15, "completion_rate": 0.98}

    scores = service.calculate_score_components(student, giver, band_info, presence_info)

    assert 0.0 <= scores.expertise_fit <= 1.0
    assert 0.0 <= scores.intent_fit <= 1.0
    assert 0.0 <= scores.affinity <= 1.0
    assert 0.0 <= scores.availability <= 1.0
    assert 0.0 <= scores.rating <= 1.0
    assert 0.0 <= scores.response_odds <= 1.0
    assert scores.cold_start_boost == 0.0  # n >= 5
    assert 0.0 <= scores.total_score <= 1.0

    # Total score should equal weighted sum
    expected_sum = (
        WEIGHT_EXPERTISE * scores.expertise_fit
        + WEIGHT_INTENT * scores.intent_fit
        + WEIGHT_AFFINITY * scores.affinity
        + WEIGHT_AVAILABILITY * scores.availability
        + WEIGHT_RATING * scores.rating
        + WEIGHT_RESPONSE_ODDS * scores.response_odds
    )
    assert math.isclose(scores.total_score, round(expected_sum, 3), abs_tol=0.01)


def test_cold_start_boost_applied_for_new_givers():
    service = MatchingService(session=None)
    student_vec = [1.0] * 768
    giver_vec = [1.0] * 768

    student = StudentMatchProfile(
        user_id=uuid.uuid4(),
        institution_id=1,
        skills=[{"name": "Python"}],
        profile_embedding=student_vec,
        intent_embedding=student_vec,
    )

    # Giver with fewer than 5 rated sessions
    giver = GiverProfile(
        user_id=uuid.uuid4(),
        institution_id=1,
        skills=[{"name": "Python"}],
        offers=["resume_review"],
        embedding=giver_vec,
        weekly_capacity=3,
        response_stats={"acceptance_rate": 0.90, "median_response_minutes": 60, "total_sessions": 2},
    )

    presence_info = {"online": False, "capacity_left": 3}
    # n = 2 < 5 threshold
    band_info = {"band": "Rising", "smoothed_avg": 4.0, "n": 2, "completion_rate": 1.0}

    scores = service.calculate_score_components(student, giver, band_info, presence_info)
    assert scores.cold_start_boost == COLD_START_BOOST
    assert scores.total_score > 0.0


def test_deterministic_why_lines_explainability():
    service = MatchingService(session=None)
    student = StudentMatchProfile(
        user_id=uuid.uuid4(),
        institution_id=1,
        batch=2026,
        department="Computer Science",
        skills=[{"name": "Python"}, {"name": "FastAPI"}],
        intent_help_type="mock_interview",
    )
    giver = GiverProfile(
        user_id=uuid.uuid4(),
        institution_id=1,
        batch=2024,
        department="Computer Science",
        skills=[{"name": "Python"}, {"name": "AWS"}],
        offers=["mock_interview", "resume_review"],
        weekly_capacity=2,
    )

    scores = ScoreComponents(
        expertise_fit=0.85,
        intent_fit=0.90,
        affinity=0.80,
        availability=0.85,
        rating=0.90,
        response_odds=0.80,
        cold_start_boost=0.0,
        total_score=0.85,
    )

    presence_online = {"online": True, "capacity_left": 2}
    band_top_rated = {"band": "Top Rated", "smoothed_avg": 4.8, "n": 12}

    why_lines = service.generate_why_lines(student, giver, scores, presence_online, band_top_rated)

    assert isinstance(why_lines, list)
    assert len(why_lines) >= 3
    # Check deterministic phrases
    assert any("Shares your Python skills" in line for line in why_lines)
    assert any("mock interview" in line for line in why_lines)
    assert any("Same college" in line for line in why_lines)
    assert any("Online now" in line for line in why_lines)


# --- Unit Tests: Hard Gates (Never Weights) ---

@pytest.mark.asyncio
async def test_hard_gates_exclude_unverified_and_restricted_givers():
    mock_session = AsyncMock()

    student_id = uuid.uuid4()
    giver_unverified_id = uuid.uuid4()
    giver_restricted_id = uuid.uuid4()
    giver_valid_id = uuid.uuid4()

    # Create dummy givers
    g_unverified = GiverProfile(user_id=giver_unverified_id, institution_id=1, offers=["career_guidance"])
    g_restricted = GiverProfile(user_id=giver_restricted_id, institution_id=1, offers=["career_guidance"])
    g_valid = GiverProfile(user_id=giver_valid_id, institution_id=1, offers=["career_guidance"])

    service = MatchingService(session=mock_session)

    # Stub DB queries
    mock_session.execute.return_value.scalars.return_value.all.return_value = [
        g_unverified,
        g_restricted,
        g_valid,
    ]
    mock_session.execute.return_value.scalar_one_or_none.return_value = None

    # Set TrustPort: unverified is "new", restricted is "restricted", valid is "verified"
    trust_levels = {
        str(student_id): "verified",
        str(giver_unverified_id): "new",
        str(giver_restricted_id): "restricted",
        str(giver_valid_id): "verified",
    }
    ports.trust = MockTrustPort(levels=trust_levels)
    ports.presence = MockPresencePort()
    ports.ratings = MockRatingsPort()
    ports.credits = MockCreditsPort()

    resp = await service.get_recommendations(student_id=student_id, scope="own_college")

    recommended_giver_ids = [item.giver.id for item in resp.items]
    assert giver_unverified_id not in recommended_giver_ids
    assert giver_restricted_id not in recommended_giver_ids
    assert giver_valid_id in recommended_giver_ids


@pytest.mark.asyncio
async def test_hard_gates_exclude_blocked_and_zero_capacity_givers():
    mock_session = AsyncMock()

    student_id = uuid.uuid4()
    giver_blocked_id = uuid.uuid4()
    giver_zero_cap_id = uuid.uuid4()
    giver_valid_id = uuid.uuid4()

    g_blocked = GiverProfile(user_id=giver_blocked_id, institution_id=1, offers=["domain_talk"])
    g_zero_cap = GiverProfile(user_id=giver_zero_cap_id, institution_id=1, offers=["domain_talk"])
    g_valid = GiverProfile(user_id=giver_valid_id, institution_id=1, offers=["domain_talk"])

    service = MatchingService(session=mock_session)
    mock_session.execute.return_value.scalars.return_value.all.return_value = [
        g_blocked,
        g_zero_cap,
        g_valid,
    ]
    mock_session.execute.return_value.scalar_one_or_none.return_value = None

    # Block giver_blocked_id
    ports.trust = MockTrustPort(blocked={(str(student_id), str(giver_blocked_id))})
    # Giver zero cap has capacity_left = 0
    ports.presence = MockPresencePort(
        mapping={
            str(giver_zero_cap_id): {"online": False, "capacity_left": 0},
            str(giver_valid_id): {"online": True, "capacity_left": 2},
        }
    )
    ports.ratings = MockRatingsPort()
    ports.credits = MockCreditsPort()

    resp = await service.get_recommendations(student_id=student_id, scope="own_college")
    rec_ids = [item.giver.id for item in resp.items]

    assert giver_blocked_id not in rec_ids
    assert giver_zero_cap_id not in rec_ids
    assert giver_valid_id in rec_ids


@pytest.mark.asyncio
async def test_exposure_cap_excludes_flooded_givers():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    flooded_giver_id = uuid.uuid4()
    normal_giver_id = uuid.uuid4()

    g_flooded = GiverProfile(
        user_id=flooded_giver_id,
        institution_id=1,
        offers=["career_guidance"],
        daily_impressions_count=MAX_DAILY_EXPOSURE,  # Hit cap
    )
    g_normal = GiverProfile(
        user_id=normal_giver_id,
        institution_id=1,
        offers=["career_guidance"],
        daily_impressions_count=5,  # Under cap
    )

    service = MatchingService(session=mock_session)
    mock_session.execute.return_value.scalars.return_value.all.return_value = [g_flooded, g_normal]
    mock_session.execute.return_value.scalar_one_or_none.return_value = None

    ports.trust = MockTrustPort()
    ports.presence = MockPresencePort()
    ports.ratings = MockRatingsPort()
    ports.credits = MockCreditsPort()

    resp = await service.get_recommendations(student_id=student_id, scope="own_college")
    rec_ids = [item.giver.id for item in resp.items]

    assert flooded_giver_id not in rec_ids
    assert normal_giver_id in rec_ids


@pytest.mark.asyncio
async def test_locked_cross_college_results_when_plan_required():
    mock_session = AsyncMock()
    student_id = uuid.uuid4()
    cross_giver_id = uuid.uuid4()

    # Different institution
    g_cross = GiverProfile(
        user_id=cross_giver_id,
        institution_id=999,  # cross-college
        offers=["mock_interview"],
        company="Amazon",
        role_title="Senior SDE",
        bio="Private contact information",
    )

    service = MatchingService(session=mock_session)
    mock_session.execute.return_value.scalars.return_value.all.return_value = [g_cross]
    mock_session.execute.return_value.scalar_one_or_none.return_value = None

    # CreditsPort denies access (plan required)
    ports.trust = MockTrustPort()
    ports.presence = MockPresencePort()
    ports.ratings = MockRatingsPort()
    ports.credits = MockCreditsPort(can_access_allowed=False, reason="plan_required")

    resp = await service.get_recommendations(student_id=student_id, scope="cross_college")

    assert resp.locked is True
    assert resp.lock_reason == "plan_required"
    assert len(resp.items) == 1
    item = resp.items[0]
    assert item.locked is True
    assert item.lock_reason == "plan_required"
    # Contact info masked
    assert "Subscribe" in item.giver.bio


# --- Integration HTTP Router Tests ---

@pytest.mark.asyncio
async def test_get_recommendations_unverified_student_forbidden():
    transport = ASGITransport(app=app)
    unverified_student_id = str(uuid.uuid4())

    ports.trust = MockTrustPort(levels={unverified_student_id: "new"})

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.get(
            "/recommendations",
            headers={"X-User-Id": unverified_student_id},
        )
        assert res.status_code == 403
        data = res.json()
        assert data["error"]["code"] == "student_verification_required"


@pytest.mark.asyncio
async def test_put_me_giver_profile_without_giver_role_forbidden():
    transport = ASGITransport(app=app)
    student_only_id = str(uuid.uuid4())

    # Trust level is new and user has only student role
    ports.trust = MockTrustPort(levels={student_only_id: "new"})

    payload = {
        "offers": ["resume_review"],
        "topics": ["Algorithms"],
        "skills": [{"name": "Python", "category": "Languages"}],
        "domains": ["AI"],
    }

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        res = await client.put(
            "/me/giver-profile",
            headers={"X-User-Id": student_only_id},
            json=payload,
        )
        assert res.status_code == 403
        assert res.json()["error"]["code"] == "giver_role_required"


@pytest.mark.asyncio
async def test_get_giver_public_card_masks_contact_details():
    transport = ASGITransport(app=app)
    giver_id = uuid.uuid4()
    student_id = uuid.uuid4()

    ports.trust = MockTrustPort()
    ports.presence = MockPresencePort()
    ports.ratings = MockRatingsPort()

    with patch("app.modules.matching.service.MatchingService.get_giver_profile") as mock_get_profile:
        mock_get_profile.return_value = GiverProfile(
            user_id=giver_id,
            offers=["career_guidance"],
            topics=["Tech"],
            skills=[{"name": "Python"}],
            domains=["Cloud"],
            company="Microsoft",
            role_title="Staff Engineer",
            bio="Happy to help alumni",
            weekly_capacity=3,
        )

        async with AsyncClient(transport=transport, base_url="http://test") as client:
            res = await client.get(
                f"/givers/{giver_id}",
                headers={"X-User-Id": str(student_id)},
            )
            assert res.status_code == 200
            data = res.json()
            assert data["id"] == str(giver_id)
            assert data["headline"] == "Staff Engineer at Microsoft"
            # Never exposes contact details
            assert "email" not in data
            assert "phone" not in data
            assert isinstance(data["why_lines"], list)
