"""
Router sanity tests for institution module.
Owner: M4
"""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_institution_endpoints_registered(client: AsyncClient):
    """Confirm institution admin endpoints are properly registered and return 200."""
    res_ov = await client.get("/admin/dashboard/overview")
    assert res_ov.status_code == 200

    res_sg = await client.get("/admin/dashboard/skill-gap")
    assert res_sg.status_code == 200

    res_safe = await client.get("/admin/dashboard/safety-summary")
    assert res_safe.status_code == 200

    res_seats = await client.get("/admin/dashboard/seats")
    assert res_seats.status_code == 200
