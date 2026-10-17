import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_recommendations_returns_501(client: AsyncClient):
    response = await client.get("/recommendations")
    assert response.status_code == 501
    assert response.json()["error"]["code"] == "module_not_implemented"
