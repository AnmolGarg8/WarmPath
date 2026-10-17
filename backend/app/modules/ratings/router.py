import uuid
from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["ratings"])


@router.post("/sessions/{id}/rating")
async def submit_session_rating(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /sessions/{id}/rating")


@router.post("/sessions/{id}/request-quality")
async def submit_request_quality(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /sessions/{id}/request-quality")


@router.post("/sessions/{id}/dispute")
async def open_dispute(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /sessions/{id}/dispute")


@router.get("/givers/{id}/rating-summary")
async def get_giver_rating_summary(id: uuid.UUID):
    raise ModuleNotImplemented(f"GET /givers/{id}/rating-summary")


@router.get("/me/band")
async def get_my_band():
    raise ModuleNotImplemented("GET /me/band")


@router.get("/admin/disputes")
async def get_admin_disputes():
    raise ModuleNotImplemented("GET /admin/disputes")


@router.post("/admin/disputes/{id}/resolve")
async def resolve_dispute(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /admin/disputes/{id}/resolve")
