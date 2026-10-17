from fastapi import APIRouter, WebSocket, Request, Response
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["institution"])

@router.get("/admin/dashboard/overview", summary="Overview of active sessions, response times, and fulfillment")
async def get_admin_dashboard_overview():
    raise ModuleNotImplemented("/admin/dashboard/overview")

@router.get("/admin/dashboard/skill-gap", summary="Analysis of in-demand student skills vs alumni supply")
async def get_admin_dashboard_skill_gap():
    raise ModuleNotImplemented("/admin/dashboard/skill-gap")

@router.get("/admin/dashboard/safety-summary", summary="Safety incident summary and moderation resolution rate")
async def get_admin_dashboard_safety_summary():
    raise ModuleNotImplemented("/admin/dashboard/safety-summary")

@router.get("/admin/dashboard/seats", summary="Usage metrics for sponsored seats and credits")
async def get_admin_dashboard_seats():
    raise ModuleNotImplemented("/admin/dashboard/seats")
