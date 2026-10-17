"""
backend/app/core/health.py - Health and readiness probes.
"""

from fastapi import APIRouter, status
from fastapi.responses import JSONResponse
from sqlalchemy import text

from app.core.db import async_session_maker
from app.core.redis import get_redis

router = APIRouter(tags=["health"])


@router.get("/healthz")
async def health_check():
    return {"status": "ok"}


@router.get("/readyz")
async def readiness_check():
    # Verify Database connectivity
    db_ok = False
    try:
        async with async_session_maker() as session:
            await session.execute(text("SELECT 1"))
            db_ok = True
    except Exception:
        db_ok = False

    # Verify Redis connectivity
    redis_ok = False
    try:
        r = await get_redis()
        await r.ping()
        redis_ok = True
    except Exception:
        redis_ok = False

    overall_ok = db_ok and redis_ok
    status_code = status.HTTP_200_OK if overall_ok else status.HTTP_503_SERVICE_UNAVAILABLE

    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if overall_ok else "not_ready",
            "database": "ok" if db_ok else "unreachable",
            "redis": "ok" if redis_ok else "unreachable",
        },
    )
