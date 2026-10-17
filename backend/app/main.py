"""
backend/app/main.py - WarmPath FastAPI Application Entrypoint.
Auto-discovers and registers all modules from app/modules/.
Frozen after P0.
"""

import importlib
import pkgutil
import sys
from contextlib import asynccontextmanager
from pathlib import Path

_backend_dir = Path(__file__).resolve().parent.parent
_repo_root = _backend_dir.parent
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))
if str(_repo_root) in sys.path:
    sys.path.remove(str(_repo_root))
if "" in sys.path:
    sys.path.remove("")

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.errors import AppError, app_error_handler
from app.core.events import event_bus
from app.core.health import router as health_router
from app.core.logging import RequestIdMiddleware, setup_logging
from app.core.ports import ports
from app.core.redis import close_redis


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    yield
    await close_redis()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
    description="WarmPath: Trusted, Intent-First Alumni Network",
    lifespan=lifespan,
)

# Global Middlewares
app.add_middleware(RequestIdMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception Handlers
from fastapi.exceptions import RequestValidationError

from app.core.errors import validation_error_handler

app.add_exception_handler(AppError, app_error_handler)
app.add_exception_handler(RequestValidationError, validation_error_handler)

# Health & Readiness
app.include_router(health_router)

# Module Auto-Discovery
modules_dir = Path(__file__).resolve().parent / "modules"
module_names = []
if modules_dir.exists():
    for p in sorted(modules_dir.iterdir()):
        if p.is_dir() and not p.name.startswith(("_", ".")):
            module_names.append(p.name)

for mod_name in module_names:
    try:
        mod = importlib.import_module(f"app.modules.{mod_name}.module")
        if hasattr(mod, "ROUTER"):
            app.include_router(mod.ROUTER)
        if hasattr(mod, "register_events"):
            mod.register_events(event_bus)
        if hasattr(mod, "register_ports"):
            mod.register_ports(ports)
    except Exception as e:
        print(f"Warning: Failed to load module '{mod_name}': {e}", file=sys.stderr)
