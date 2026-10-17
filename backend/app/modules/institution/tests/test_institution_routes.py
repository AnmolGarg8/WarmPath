import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_dashboard_overview_returns_501(client: AsyncClient):
    response = await client.get("/admin/dashboard/overview")
    assert response.status_code == 501
    assert response.json()["error"]["code"] == "module_not_implemented"
