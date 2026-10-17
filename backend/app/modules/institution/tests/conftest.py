"""
Pytest fixtures for institution module tests.
Owner: M4
"""

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
from app.core.db import Base, Institution, User, get_db
from app.main import app
from app.modules.institution.models import (
    InstitutionAccessReachRecord,
    InstitutionEventLog,
    InstitutionRequestRecord,
    InstitutionSafetyRecord,
    InstitutionSeatGrant,
    InstitutionSeatsRecord,
    InstitutionSessionRecord,
    InstitutionSkillGapRecord,
    InstitutionUserReadModel,
)
from app.modules.institution.service import clear_cache

# Register SQLite adapters and type compilers for in-memory SQLite test DB
sqlite3.register_adapter(uuid.UUID, lambda u: str(u))
sqlite3.register_adapter(list, lambda l: json.dumps(l))
sqlite3.register_adapter(dict, lambda d: json.dumps(d))
sqlite3.register_converter("UUID", lambda b: uuid.UUID(b.decode("utf-8")))

SQLiteTypeCompiler.visit_ARRAY = lambda self, type_, **kw: "TEXT"
SQLiteTypeCompiler.visit_JSONB = lambda self, type_, **kw: "TEXT"

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(autouse=True)
def reset_service_cache():
    clear_cache()
    yield
    clear_cache()


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async_sm = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_sm() as session:
        # Seed test institutions
        inst1 = Institution(
            id=1,
            name="Vivekananda Institute of Professional Studies",
            short_name="VIPS-TC",
            city="New Delhi",
            email_domains=["vipstc.edu.in"],
        )
        inst2 = Institution(
            id=2,
            name="Indian Institute of Technology Delhi",
            short_name="IITD",
            city="New Delhi",
            email_domains=["iitd.ac.in"],
        )
        session.add_all([inst1, inst2])

        # Seed test users
        student_inst1 = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000001"),
            email="student1@vipstc.edu.in",
            full_name="Student One",
            institution_id=1,
            roles=["student"],
        )
        giver_inst1 = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000002"),
            email="giver1@vipstc.edu.in",
            full_name="Giver Alumni One",
            institution_id=1,
            roles=["alumnus"],
        )
        giver_inst2 = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000003"),
            email="giver2@iitd.ac.in",
            full_name="Giver Alumni Two",
            institution_id=2,
            roles=["alumnus"],
        )
        admin_inst1 = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000004"),
            email="admin@vipstc.edu.in",
            full_name="VIPS Admin",
            institution_id=1,
            roles=["institution_admin"],
        )
        platform_admin = User(
            id=uuid.UUID("00000000-0000-0000-0000-000000000005"),
            email="platform@warmpath.org",
            full_name="Platform Admin",
            institution_id=1,
            roles=["platform_admin"],
        )
        session.add_all([student_inst1, giver_inst1, giver_inst2, admin_inst1, platform_admin])

        # Initialize seats records
        seats1 = InstitutionSeatsRecord(
            institution_id=1,
            sponsored_seats_granted=0,
            total_budget_inr=50000.0,
            remaining_budget_inr=50000.0,
            scholarship_pool_balance=15000.0,
        )
        seats2 = InstitutionSeatsRecord(
            institution_id=2,
            sponsored_seats_granted=0,
            total_budget_inr=75000.0,
            remaining_budget_inr=75000.0,
            scholarship_pool_balance=25000.0,
        )
        session.add_all([seats1, seats2])

        await session.commit()
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def _get_db_override():
        yield db_session

    app.dependency_overrides[get_db] = _get_db_override
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
