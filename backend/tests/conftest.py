"""
backend/tests/conftest.py - Pytest fixtures and environment configuration.
"""

import json
import os
import sqlite3

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.types import ARRAY


# Register SQLite DDL fallbacks for PostgreSQL types
@compiles(ARRAY, "sqlite")
def compile_array_sqlite(type_, compiler, **kw):
    return "JSON"

@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"

# SQLite bind/result processors for ARRAY and JSONB
orig_array_bp = ARRAY.bind_processor
def custom_array_bp(self, dialect):
    if dialect.name == "sqlite":
        return lambda val: json.dumps(val) if isinstance(val, (list, tuple)) else val
    return orig_array_bp(self, dialect)
ARRAY.bind_processor = custom_array_bp

orig_array_rp = ARRAY.result_processor
def custom_array_rp(self, dialect, coltype):
    if dialect.name == "sqlite":
        return lambda val: json.loads(val) if isinstance(val, str) else (val or [])
    return orig_array_rp(self, dialect, coltype)
ARRAY.result_processor = custom_array_rp

orig_jsonb_bp = JSONB.bind_processor
def custom_jsonb_bp(self, dialect):
    if dialect.name == "sqlite":
        return lambda val: json.dumps(val) if isinstance(val, (dict, list)) else val
    return orig_jsonb_bp(self, dialect)
JSONB.bind_processor = custom_jsonb_bp

orig_jsonb_rp = JSONB.result_processor
def custom_jsonb_rp(self, dialect, coltype):
    if dialect.name == "sqlite":
        return lambda val: json.loads(val) if isinstance(val, str) else val
    return orig_jsonb_rp(self, dialect, coltype)
JSONB.result_processor = custom_jsonb_rp

sqlite3.register_adapter(list, json.dumps)

import app.core.redis as core_redis
from app.core.db import Base, Institution, get_db
from app.main import app

# Determine test database URL
TEST_DB_URL = os.environ.get("DATABASE_URL", "sqlite+aiosqlite:///:memory:")

test_engine = create_async_engine(TEST_DB_URL, echo=False)
test_session_maker = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest_asyncio.fixture(scope="session", autouse=True)
async def init_test_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session():
    async with test_session_maker() as session:
        yield session


@pytest_asyncio.fixture(autouse=True)
async def seed_default_institution(db_session: AsyncSession):
    inst_res = await db_session.execute(
        select(Institution).where(Institution.name == "Vivekananda Institute")
    )
    inst = inst_res.scalar_one_or_none()
    if not inst:
        inst = Institution(
            name="Vivekananda Institute",
            short_name="VIPS",
            city="Delhi",
            email_domains=["vips.edu"],
        )
        db_session.add(inst)
        await db_session.commit()


@pytest_asyncio.fixture(autouse=True)
async def override_deps(db_session):
    # Override database dependency with test session
    app.dependency_overrides[get_db] = lambda: db_session

    orig_get_redis = core_redis.get_redis
    orig_redis_client = core_redis._redis_client
    fake_r = None
    try:
        import fakeredis.aioredis as fake_aioredis
        fake_r = fake_aioredis.FakeRedis(decode_responses=True)
        async def fake_get_redis():
            return fake_r
        core_redis.get_redis = fake_get_redis
        core_redis._redis_client = fake_r
    except ImportError:
        pass

    yield

    app.dependency_overrides.clear()
    core_redis.get_redis = orig_get_redis
    core_redis._redis_client = orig_redis_client
    if fake_r is not None:
        await fake_r.flushall()


@pytest_asyncio.fixture
async def async_client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
