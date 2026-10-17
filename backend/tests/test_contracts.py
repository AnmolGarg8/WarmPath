import pytest
from pathlib import Path
from app.main import app

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def test_all_contract_paths_registered():
    app_paths = {route.path for route in app.routes if hasattr(route, "path")}

    # System paths
    assert "/health" in app_paths
    assert "/ready" in app_paths

    # Module paths from contracts
    expected_paths = [
        "/auth/request-otp",
        "/auth/verify-otp",
        "/auth/refresh",
        "/auth/logout",
        "/me",
        "/me/data-export",
        "/institutions",
        "/verification/submit",
        "/verification/status",
        "/reports",
        "/blocks",
        "/blocks/{user_id}",
        "/me/trust",
        "/admin/moderation/queue",
        "/admin/moderation/{id}/resolve",
        "/admin/verification/queue",
        "/admin/verification/{id}/decide",
        "/admin/approved-members/upload",
        "/admin/audit-log",
        "/resume",
        "/resume/profile",
        "/me/intent",
        "/me/consents",
        "/recommendations",
        "/givers/{id}",
        "/me/giver-profile",
        "/me/availability",
        "/me/online",
        "/presence",
        "/requests",
        "/requests/{id}",
        "/requests/{id}/accept",
        "/requests/{id}/decline",
        "/givers/{id}/slots",
        "/requests/{id}/messages",
        "/sessions/{id}",
        "/sessions/{id}/join",
        "/sessions/{id}/leave",
        "/me/sessions",
        "/notifications/devices",
        "/sessions/{id}/rating",
        "/sessions/{id}/request-quality",
        "/sessions/{id}/dispute",
        "/givers/{id}/rating-summary",
        "/me/band",
        "/admin/disputes",
        "/admin/disputes/{id}/resolve",
        "/plans",
        "/me/subscription",
        "/me/wallet",
        "/me/earnings",
        "/me/cashout",
        "/me/donate-credits",
        "/sponsored-seats",
        "/admin/sponsored-seats",
        "/subscriptions",
        "/subscriptions/cancel",
        "/webhooks/razorpay",
        "/admin/dashboard/overview",
        "/admin/dashboard/skill-gap",
        "/admin/dashboard/safety-summary",
        "/admin/dashboard/seats",
    ]

    for p in expected_paths:
        assert p in app_paths, f"Expected path '{p}' is missing from FastAPI routes!"
