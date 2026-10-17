import os
import importlib
import pkgutil
from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.core.db import engine, async_session_factory
from app.core.redis import get_redis, close_redis
from app.core.logging import RequestIdMiddleware, logger
from app.core.errors import AppError, app_error_handler, unhandled_exception_handler
from app.core.events import event_bus
from app.core.ports import port_registry
import app.modules as modules_pkg


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("warmpath_api_starting", environment=settings.ENVIRONMENT)
    # Ensure Redis client is warmed
    try:
        redis = await get_redis()
        await redis.ping()
    except Exception as e:
        logger.warning("redis_connection_warning", error=str(e))
    yield
    await close_redis()
    await engine.dispose()
    logger.info("warmpath_api_stopped")


app = FastAPI(
    title="WarmPath API",
    version="1.0.0",
    description="WarmPath: Intent-First Alumni Network Monolith API",
    lifespan=lifespan,
)

# Middleware
app.add_middleware(RequestIdMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)


# Health and Readiness Endpoints
@app.get("/health", tags=["system"])
async def health():
    return {"status": "ok"}


@app.get("/ready", tags=["system"])
async def readiness():
    checks = {"database": False, "redis": False}
    # Check Database
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
            checks["database"] = True
    except Exception as e:
        checks["database_error"] = str(e)

    # Check Redis
    try:
        redis = await get_redis()
        await redis.ping()
        checks["redis"] = True
    except Exception as e:
        checks["redis_error"] = str(e)

    all_ready = checks["database"] and checks["redis"]
    status_code = status.HTTP_200_OK if all_ready else status.HTTP_503_SERVICE_UNAVAILABLE
    return JSONResponse(status_code=status_code, content={"ready": all_ready, "checks": checks})


# Auto-Discovery of Modules
def register_modules(app_instance: FastAPI) -> None:
    modules_dir = Path(__file__).resolve().parent / "modules"
    for item in sorted(modules_dir.iterdir()):
        if item.is_dir() and (item / "module.py").exists():
            mod_name = item.name
            try:
                mod = importlib.import_module(f"app.modules.{mod_name}.module")
                router = getattr(mod, "ROUTER", None)
                if router:
                    app_instance.include_router(router)

                register_events_fn = getattr(mod, "register_events", None)
                if callable(register_events_fn):
                    register_events_fn(event_bus)

                register_ports_fn = getattr(mod, "register_ports", None)
                if callable(register_ports_fn):
                    register_ports_fn(port_registry)

                logger.info("module_loaded", module=mod_name)
            except Exception as e:
                logger.error("module_load_failed", module=mod_name, error=str(e))
                raise e


register_modules(app)
