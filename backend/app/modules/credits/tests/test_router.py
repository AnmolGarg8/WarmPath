"""
Router tests for credits module endpoints.
Owner: M4
"""

import uuid
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_plans(client: AsyncClient):
    response = await client.get("/plans")
    assert response.status_code == 200
    data = response.json()
    assert "plans" in data
    assert len(data["plans"]) == 4

    codes = [p["code"] for p in data["plans"]]
    assert "campus" in codes
    assert "standard" in codes
    assert "high" in codes
    assert "premium" in codes

    standard = next(p for p in data["plans"] if p["code"] == "standard")
    assert standard["price_inr"] == 299
    assert standard["credits_per_month"] == 1
    assert len(standard["features"]) > 0


@pytest.mark.asyncio
async def test_get_subscription(client: AsyncClient):
    user_id = str(uuid.uuid4())
    response = await client.get("/me/subscription", headers={"X-User-Id": user_id})
    assert response.status_code == 200
    data = response.json()
    assert data["plan_tier"] == "campus"
    assert data["status"] == "active"
    assert data["credits_remaining"] == 0


@pytest.mark.asyncio
async def test_get_wallet_empty(client: AsyncClient):
    user_id = str(uuid.uuid4())
    response = await client.get("/me/wallet", headers={"X-User-Id": user_id})
    assert response.status_code == 200
    data = response.json()
    assert data["available_credits"] == 0
    assert data["affinity_credits"] == 0
    assert data["items"] == []


@pytest.mark.asyncio
async def test_get_earnings(client: AsyncClient):
    user_id = str(uuid.uuid4())
    response = await client.get("/me/earnings", headers={"X-User-Id": user_id})
    assert response.status_code == 200
    data = response.json()
    assert data["cashable_balance_inr"] == 0.0
    assert "by_band_payout_share" in data
    assert data["by_band_payout_share"]["Rising"] == 0.60
    assert data["by_band_payout_share"]["Trusted"] == 0.70
    assert data["by_band_payout_share"]["Top Rated"] == 0.80


@pytest.mark.asyncio
async def test_sponsored_seats(client: AsyncClient):
    user_id = str(uuid.uuid4())
    response = await client.get("/sponsored-seats", headers={"X-User-Id": user_id})
    assert response.status_code == 200
    data = response.json()
    assert data["eligible"] is False
    assert data["seats"] == []
