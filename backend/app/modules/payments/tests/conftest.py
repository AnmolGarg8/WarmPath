"""
Pytest fixtures for payments module tests.
Owner: M4
"""

import hashlib
import hmac
import json
import sqlite3
import uuid
from typing import AsyncGenerator
import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.dialects.sqlite.base import SQLiteTypeCompiler
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings
from app.core.db import Base, IdempotencyKey, OutboxEvent, User, get_db
from app.main import app
from app.modules.payments.client import RazorpayClientWrapper, set_razorpay_client
from app.modules.payments.models import (
    GiverEarningsReadModel,
    PaymentEvent,
    PayoutRequest,
    RazorpayPlanMapping,
    Subscription,
)

# Register SQLite adapters and type compilers for in-memory SQLite test DB
sqlite3.register_adapter(uuid.UUID, lambda u: str(u))
sqlite3.register_adapter(list, lambda l: json.dumps(l))
sqlite3.register_adapter(dict, lambda d: json.dumps(d))
sqlite3.register_converter("UUID", lambda b: uuid.UUID(b.decode("utf-8")))

SQLiteTypeCompiler.visit_ARRAY = lambda self, type_, **kw: "TEXT"
SQLiteTypeCompiler.visit_JSONB = lambda self, type_, **kw: "TEXT"
SQLiteTypeCompiler.visit_UUID = lambda self, type_, **kw: "TEXT"

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
MOCK_WEBHOOK_SECRET = "test_webhook_secret_key_12345"


class MockRazorpayClient(RazorpayClientWrapper):
    """Mock client that intercepts Razorpay API calls in tests without network access."""

    def __init__(self):
        self.key_id = "rzp_test_mock_key_id"
        self.key_secret = "mock_secret"
        self.webhook_secret = MOCK_WEBHOOK_SECRET
        self._subscriptions_store = {}
        self._plans_store = {
            "standard": "plan_rzp_test_standard",
            "high": "plan_rzp_test_high",
            "premium": "plan_rzp_test_premium",
        }

    def verify_webhook_signature(self, raw_body: bytes, signature: str) -> bool:
        if not signature or not self.webhook_secret:
            return False
        expected = hmac.new(
            self.webhook_secret.encode("utf-8"),
            raw_body,
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected, signature)

    def create_subscription(self, plan_id: str, total_count: int = 12):
        sub_id = f"sub_rzp_test_{uuid.uuid4().hex[:12]}"
        data = {
            "id": sub_id,
            "plan_id": plan_id,
            "status": "created",
            "total_count": total_count,
        }
        self._subscriptions_store[sub_id] = data
        return data

    def cancel_subscription(self, subscription_id: str, at_period_end: bool = True):
        if subscription_id in self._subscriptions_store:
            self._subscriptions_store[subscription_id]["status"] = "cancelled"
        return {"id": subscription_id, "status": "cancelled"}

    def fetch_subscription(self, subscription_id: str):
        return self._subscriptions_store.get(
            subscription_id,
            {"id": subscription_id, "status": "active"},
        )

    def create_plan(self, name: str, amount_paise: int, period: str = "monthly", interval: int = 1):
        plan_id = f"plan_rzp_test_{uuid.uuid4().hex[:8]}"
        return {"id": plan_id, "item": {"name": name, "amount": amount_paise}}

    def fetch_all_plans(self):
        return {
            "items": [
                {"id": "plan_rzp_test_standard", "item": {"name": "standard"}},
                {"id": "plan_rzp_test_high", "item": {"name": "high"}},
                {"id": "plan_rzp_test_premium", "item": {"name": "premium"}},
            ]
        }


@pytest.fixture(scope="session", autouse=True)
def setup_test_settings():
    settings.ENVIRONMENT = "test"
    settings.RAZORPAY_KEY_ID = "rzp_test_mock_key_id"
    settings.RAZORPAY_KEY_SECRET = "mock_secret"
    settings.RAZORPAY_WEBHOOK_SECRET = MOCK_WEBHOOK_SECRET


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async_sm = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_sm() as session:
        # Seed default test users (student and giver)
        student = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000001"),
            email="student@example.edu",
            full_name="Test Student",
            roles=["student"],
        )
        giver = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000002"),
            email="giver@alumni.edu",
            full_name="Test Giver Alumni",
            roles=["alumni"],
        )
        session.add_all([student, giver])

        # Preseed plan mappings
        for code, pid, price in [
            ("standard", "plan_rzp_test_standard", 299),
            ("high", "plan_rzp_test_high", 599),
            ("premium", "plan_rzp_test_premium", 999),
        ]:
            session.add(
                RazorpayPlanMapping(
                    plan_code=code,
                    razorpay_plan_id=pid,
                    price_inr=price,
                )
            )

        await session.commit()
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest_asyncio.fixture
async def mock_rzp_client():
    client = MockRazorpayClient()
    set_razorpay_client(client)
    yield client
    set_razorpay_client(None)


@pytest_asyncio.fixture
async def client(db_session: AsyncSession, mock_rzp_client: MockRazorpayClient):
    async def _get_db_override():
        yield db_session

    app.dependency_overrides[get_db] = _get_db_override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


def generate_webhook_signature(raw_body: bytes, secret: str = MOCK_WEBHOOK_SECRET) -> str:
    """Generate valid HMAC-SHA256 signature for testing webhooks."""
    return hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha256).hexdigest()
