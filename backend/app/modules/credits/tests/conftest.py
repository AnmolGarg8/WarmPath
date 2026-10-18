"""
Pytest fixtures for credits module tests.
Owner: M4
"""

import json
import sqlite3
import uuid
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.dialects.sqlite.base import SQLiteTypeCompiler
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.db import Base, get_db
from app.main import app
from app.modules.credits.models import (
    CreditLot,
    LedgerAccount,
    LedgerEntry,
    PayoutRequest,
    Plan,
    SessionSettlement,
    SponsoredSeat,
    UserSubscription,
)
from app.modules.credits.service import CreditsService

# Register SQLite adapters and type compilers for in-memory SQLite test DB
sqlite3.register_adapter(uuid.UUID, lambda u: str(u))
sqlite3.register_adapter(list, lambda l: json.dumps(l))
sqlite3.register_converter("UUID", lambda b: uuid.UUID(b.decode("utf-8")))
SQLiteTypeCompiler.visit_ARRAY = lambda self, type_, **kw: "TEXT"
SQLiteTypeCompiler.visit_UUID = lambda self, type_, **kw: "TEXT"

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def db_session():
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async_sm = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_sm() as session:
        await CreditsService.seed_plans_if_empty(session)
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession):
    async def _get_db_override():
        yield db_session

    app.dependency_overrides[get_db] = _get_db_override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
