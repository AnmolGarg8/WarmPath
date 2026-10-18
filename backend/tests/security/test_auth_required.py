"""
backend/tests/security/test_auth_required.py - Verify authentication gating across all endpoints.
Walks the OpenAPI schema and asserts 401 without a token for every route not in allowlist.
Owner: M1
"""

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app

# Specification allowlist:
# /auth/request-otp, /auth/verify-otp, /auth/refresh, /institutions, /plans, /config/public, /health, /webhooks/razorpay (signature-verified)
PUBLIC_ALLOWLIST = {
    "/auth/request-otp",
    "/auth/verify-otp",
    "/auth/refresh",
    "/institutions",
    "/plans",
    "/config/public",
    "/health",
    "/healthz",
    "/readyz",
    "/webhooks/razorpay",
    "/openapi.json",
    "/docs",
    "/docs/oauth2-redirect",
    "/redoc",
}


@pytest.mark.asyncio
async def test_all_routes_require_auth_except_allowlist():
    """
    Walks the complete OpenAPI schema and verifies every non-allowlisted endpoint
    returns HTTP 401 Unauthorized when requested without an authentication token.
    Fails with the complete list of offenders if any endpoint fails.
    """
    transport = ASGITransport(app=app)
    offenders = []

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        schema = app.openapi()
        paths = schema.get("paths", {})

        for path, path_item in sorted(paths.items()):
            # Normalize trailing slash
            norm_path = path.rstrip("/") or "/"
            if norm_path in PUBLIC_ALLOWLIST or any(norm_path.startswith(prefix) for prefix in ("/docs", "/redoc", "/openapi")):
                continue

            for method in path_item.keys():
                method_upper = method.upper()
                if method_upper not in ("GET", "POST", "PUT", "PATCH", "DELETE"):
                    continue

                # Substitute route params with deterministic UUID
                sample_uuid = "00000000-0000-0000-0000-000000000001"
                test_path = path.replace("{id}", sample_uuid).replace("{user_id}", sample_uuid)

                # Request without any Authorization header
                res = await client.request(method_upper, test_path)

                if res.status_code != 401:
                    offenders.append(
                        f"Offender: {method_upper} {path} (called: {test_path}) returned {res.status_code} instead of 401"
                    )

    assert not offenders, f"The following endpoints failed to require authentication:\n" + "\n".join(offenders)


@pytest.mark.asyncio
async def test_allowlisted_endpoints_accessible_without_token():
    """
    Verifies that specification-allowlisted endpoints are accessible without requiring a bearer token.
    """
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # Public config
        res_config = await client.get("/config/public")
        assert res_config.status_code == 200, f"/config/public returned {res_config.status_code}"

        # Public plans
        res_plans = await client.get("/plans")
        assert res_plans.status_code == 200, f"/plans returned {res_plans.status_code}"

        # Institutions list
        res_inst = await client.get("/institutions")
        assert res_inst.status_code == 200, f"/institutions returned {res_inst.status_code}"

        # Health checks
        res_health = await client.get("/healthz")
        assert res_health.status_code == 200, f"/healthz returned {res_health.status_code}"
