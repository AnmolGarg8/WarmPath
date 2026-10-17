import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_auth_request_otp_returns_501(client: AsyncClient):
    response = await client.post("/auth/request-otp", json={"email": "test@vips.edu"})
    assert response.status_code == 501
    data = response.json()
    assert data["error"]["code"] == "module_not_implemented"
