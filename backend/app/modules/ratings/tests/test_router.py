import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

@pytest.mark.asyncio
async def test_ratings_endpoints_implemented():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/sessions/00000000-0000-0000-0000-000000000000/rating")
        assert response.status_code in (401, 422)
