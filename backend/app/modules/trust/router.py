import uuid
from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["trust"])


@router.post("/reports")
async def create_report():
    raise ModuleNotImplemented("POST /reports")


@router.post("/blocks")
async def create_block():
    raise ModuleNotImplemented("POST /blocks")


@router.delete("/blocks/{user_id}")
async def delete_block(user_id: uuid.UUID):
    raise ModuleNotImplemented(f"DELETE /blocks/{user_id}")


@router.get("/me/trust")
async def get_my_trust():
    raise ModuleNotImplemented("GET /me/trust")


@router.get("/admin/moderation/queue")
async def get_moderation_queue():
    raise ModuleNotImplemented("GET /admin/moderation/queue")


@router.post("/admin/moderation/{id}/resolve")
async def resolve_moderation(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /admin/moderation/{id}/resolve")


@router.get("/admin/verification/queue")
async def get_verification_queue():
    raise ModuleNotImplemented("GET /admin/verification/queue")


@router.post("/admin/verification/{id}/decide")
async def decide_verification(id: uuid.UUID):
    raise ModuleNotImplemented(f"POST /admin/verification/{id}/decide")


@router.post("/admin/approved-members/upload")
async def upload_approved_members():
    raise ModuleNotImplemented("POST /admin/approved-members/upload")


@router.get("/admin/audit-log")
async def get_audit_log():
    raise ModuleNotImplemented("GET /admin/audit-log")
