import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_resume_upload_returns_501(client: AsyncClient):
    response = await client.post("/resume")
    assert response.status_code == 501
    assert response.json()["error"]["code"] == "module_not_implemented"
