from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["institution"])


@router.get("/admin/dashboard/overview")
async def get_dashboard_overview():
    raise ModuleNotImplemented("GET /admin/dashboard/overview")


@router.get("/admin/dashboard/skill-gap")
async def get_dashboard_skill_gap():
    raise ModuleNotImplemented("GET /admin/dashboard/skill-gap")


@router.get("/admin/dashboard/safety-summary")
async def get_dashboard_safety_summary():
    raise ModuleNotImplemented("GET /admin/dashboard/safety-summary")


@router.get("/admin/dashboard/seats")
async def get_dashboard_seats():
    raise ModuleNotImplemented("GET /admin/dashboard/seats")
