from fastapi import APIRouter, WebSocket, Request, Response
from app.core.errors import ModuleNotImplemented

router = APIRouter(tags=["auth"])

@router.post("/auth/request-otp", summary="Request one-time password for email")
async def post_auth_request_otp():
    raise ModuleNotImplemented("/auth/request-otp")

@router.post("/auth/verify-otp", summary="Verify one-time password and receive tokens")
async def post_auth_verify_otp():
    raise ModuleNotImplemented("/auth/verify-otp")

@router.post("/auth/refresh", summary="Refresh access token")
async def post_auth_refresh():
    raise ModuleNotImplemented("/auth/refresh")

@router.post("/auth/logout", summary="Revoke active session token")
async def post_auth_logout():
    raise ModuleNotImplemented("/auth/logout")

@router.get("/me", summary="Retrieve current authenticated user profile")
async def get_me():
    raise ModuleNotImplemented("/me")

@router.patch("/me", summary="Update authenticated user profile")
async def patch_me():
    raise ModuleNotImplemented("/me")

@router.delete("/me", summary="Request account and data deletion under DPDP Act")
async def delete_me():
    raise ModuleNotImplemented("/me")

@router.get("/me/data-export", summary="Download personal data export")
async def get_me_data_export():
    raise ModuleNotImplemented("/me/data-export")

@router.get("/institutions", summary="List supported institutions")
async def get_institutions():
    raise ModuleNotImplemented("/institutions")

@router.post("/verification/submit", summary="Submit institutional credentials for verification")
async def post_verification_submit():
    raise ModuleNotImplemented("/verification/submit")

@router.get("/verification/status", summary="Check current verification status")
async def get_verification_status():
    raise ModuleNotImplemented("/verification/status")
