"""
backend/app/modules/trust/tests/conftest.py - Trust module test fixtures.
"""

import pytest_asyncio
import app.core.db as core_db
from app.core.ports import ports
from tests.conftest import *


@pytest_asyncio.fixture(autouse=True)
async def patch_trust_session_maker():
    orig_sm = core_db.async_session_maker
    core_db.async_session_maker = test_session_maker
    if hasattr(ports, "trust") and hasattr(ports.trust, "_session_maker"):
        ports.trust._session_maker = test_session_maker
    if hasattr(ports, "safety") and hasattr(ports.safety, "_session_maker"):
        ports.safety._session_maker = test_session_maker
    yield
    core_db.async_session_maker = orig_sm
