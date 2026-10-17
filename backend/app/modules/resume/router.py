from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["resume"])


@router.post("/resume")
async def upload_resume():
    raise ModuleNotImplemented("POST /resume")


@router.get("/resume/profile")
async def get_resume_profile():
    raise ModuleNotImplemented("GET /resume/profile")


@router.put("/resume/profile")
async def update_resume_profile():
    raise ModuleNotImplemented("PUT /resume/profile")


@router.delete("/resume")
async def delete_resume():
    raise ModuleNotImplemented("DELETE /resume")


@router.get("/me/intent")
async def get_my_intent():
    raise ModuleNotImplemented("GET /me/intent")


@router.put("/me/intent")
async def update_my_intent():
    raise ModuleNotImplemented("PUT /me/intent")


@router.get("/me/consents")
async def get_my_consents():
    raise ModuleNotImplemented("GET /me/consents")


@router.put("/me/consents")
async def update_my_consents():
    raise ModuleNotImplemented("PUT /me/consents")
