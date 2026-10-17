import pytest
from httpx import ASGITransport, AsyncClient

from app.core.config import settings
from app.main import app


@pytest.mark.asyncio
async def test_get_config_public_production_defaults():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/config/public")

    assert response.status_code == 200
    data = response.json()

    assert "demo_profile" in data
    assert "test_mode" in data
    assert "windows" in data
    assert "dispute_minutes" in data["windows"]
    assert "no_reply_minutes" in data["windows"]
    assert "min_call_seconds" in data["windows"]
    assert "band_thresholds" in data

    # Verify no secrets or credentials leaked
    assert "jwt_secret" not in data
    assert "secret_key" not in data
    assert "password" not in data
    assert "api_key" not in data


@pytest.mark.asyncio
async def test_get_config_public_reflects_overrides(monkeypatch):
    monkeypatch.setattr(settings, "DEMO_PROFILE", True)
    monkeypatch.setattr(settings, "DISPUTE_WINDOW_MINUTES", 2)
    monkeypatch.setattr(settings, "NO_REPLY_EXPIRY_MINUTES", 5)
    monkeypatch.setattr(settings, "MIN_CALL_SECONDS", 60)
    monkeypatch.setattr(settings, "TRUSTED_MIN_SESSIONS", 1)
    monkeypatch.setattr(settings, "TOP_RATED_MIN_SESSIONS", 2)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/config/public")

    assert response.status_code == 200
    data = response.json()

    assert data["demo_profile"] is True
    assert data["windows"]["dispute_minutes"] == 2
    assert data["windows"]["no_reply_minutes"] == 5
    assert data["windows"]["min_call_seconds"] == 60
    assert data["band_thresholds"]["trusted_min_sessions"] == 1
    assert data["band_thresholds"]["top_rated_min_sessions"] == 2
    assert data["band_thresholds"]["lowered"] is True
