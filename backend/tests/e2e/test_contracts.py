"""
backend/tests/e2e/test_contracts.py - Contract Tests with Schemathesis against merged OpenAPI contract.
Validates that endpoints conform to the schemas, response codes, and error formats.
"""

import sys
from pathlib import Path

import pytest
import schemathesis
from httpx import AsyncClient

from app.main import app

repo_root = Path(__file__).resolve().parent.parent.parent.parent
if str(repo_root) not in sys.path:
    sys.path.append(str(repo_root))

from scripts.build_openapi import build_merged_openapi

openapi_path = repo_root / "contracts" / "openapi.yaml"
if not openapi_path.exists():
    import yaml
    merged = build_merged_openapi()
    openapi_path.parent.mkdir(parents=True, exist_ok=True)
    with open(openapi_path, "w", encoding="utf-8") as f:
        yaml.dump(merged, f, sort_keys=False)

# Load Schemathesis schema from the merged openapi specification
schema = schemathesis.openapi.from_path(str(openapi_path))


def test_openapi_contract_validity():
    """
    Validates that the merged OpenAPI document is structurally valid,
    contains paths, components, and error response schemas.
    """
    merged = build_merged_openapi()
    assert "openapi" in merged
    assert "paths" in merged
    assert len(merged["paths"]) > 0, "OpenAPI contract paths cannot be empty"

    # Verify standard ErrorResponse component exists
    schemas = merged.get("components", {}).get("schemas", {})
    assert "ErrorResponse" in schemas
    assert "error" in schemas["ErrorResponse"]["properties"]
    assert "code" in schemas["ErrorResponse"]["properties"]["error"]["properties"]
    assert "message" in schemas["ErrorResponse"]["properties"]["error"]["properties"]


@pytest.mark.asyncio
async def test_auth_contract_conformance(async_client: AsyncClient):
    """
    Validates that implemented Auth endpoints conform to ErrorResponse on validation failure.
    """
    # 1. Invalid email in request-otp returns 422 with ErrorResponse schema
    res = await async_client.post("/auth/request-otp", json={"email": "invalid-email-format"})
    assert res.status_code == 422
    data = res.json()
    assert "error" in data
    assert "code" in data["error"]
    assert "message" in data["error"]

    # 2. Unsupported institution domain returns 422 institution_not_supported
    res2 = await async_client.post("/auth/request-otp", json={"email": "student@unknown-university.xyz"})
    assert res2.status_code == 422
    data2 = res2.json()
    assert data2["error"]["code"] == "institution_not_supported"


@pytest.mark.asyncio
async def test_trust_contract_conformance(async_client: AsyncClient):
    """
    Validates that Trust & Moderation endpoints conform to ErrorResponse on unauthorized access.
    """
    res = await async_client.get("/admin/moderation/queue")
    assert res.status_code == 401
    data = res.json()
    assert "error" in data
    assert data["error"]["code"] in ["unauthorized", "token_invalid"]


def test_schemathesis_operations_match_backend():
    """
    Validates that every operation path in the Schemathesis parsed schema
    corresponds to a mounted route in the FastAPI application.
    """
    backend_routes = set()
    for route in app.routes:
        if hasattr(route, "path"):
            backend_routes.add(route.path)

    for op in schema:
        # op is the path in schemathesis 4
        assert op in backend_routes, f"OpenAPI contract operation '{op}' not implemented in FastAPI app"
