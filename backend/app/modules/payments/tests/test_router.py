"""
Router integration sanity tests for payments module.
Owner: M4
"""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_payments_endpoints_registered(client: AsyncClient):
    """Confirm payment endpoints are registered and respond to validation."""
    # POST /subscriptions without body or headers returns 400 (idempotency key required)
    res = await client.post("/subscriptions", json={"plan_code": "standard"})
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "idempotency_key_required"

    # POST /webhooks/razorpay without signature returns 400
    res_webhook = await client.post("/webhooks/razorpay", json={})
    assert res_webhook.status_code == 400
    assert res_webhook.json()["error"]["code"] == "invalid_signature"
