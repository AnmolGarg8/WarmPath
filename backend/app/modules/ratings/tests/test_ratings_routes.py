import uuid
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_ratings_band_returns_501(client: AsyncClient):
    response = await client.get("/me/band")
    assert response.status_code == 501
    assert response.json()["error"]["code"] == "module_not_implemented"
