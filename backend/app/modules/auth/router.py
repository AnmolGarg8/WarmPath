from fastapi import APIRouter
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["auth"])


@router.post("/auth/request-otp")
async def request_otp():
    raise ModuleNotImplemented("POST /auth/request-otp")


@router.post("/auth/verify-otp")
async def verify_otp():
    raise ModuleNotImplemented("POST /auth/verify-otp")


@router.post("/auth/refresh")
async def refresh_token():
    raise ModuleNotImplemented("POST /auth/refresh")


@router.post("/auth/logout")
async def logout():
    raise ModuleNotImplemented("POST /auth/logout")


@router.get("/me")
async def get_me():
    raise ModuleNotImplemented("GET /me")


@router.patch("/me")
async def update_me():
    raise ModuleNotImplemented("PATCH /me")


@router.delete("/me")
async def delete_me():
    raise ModuleNotImplemented("DELETE /me")


@router.get("/me/data-export")
async def get_data_export():
    raise ModuleNotImplemented("GET /me/data-export")


@router.get("/institutions")
async def get_institutions():
    raise ModuleNotImplemented("GET /institutions")


@router.post("/verification/submit")
async def submit_verification():
    raise ModuleNotImplemented("POST /verification/submit")


@router.get("/verification/status")
async def get_verification_status():
    raise ModuleNotImplemented("GET /verification/status")
