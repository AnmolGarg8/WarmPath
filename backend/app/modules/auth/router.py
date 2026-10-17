from fastapi import APIRouter, WebSocket, Request, Response
from app.core.config import settings
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

@router.get("/config/public", summary="Retrieve public deployment configuration and demo/test mode flags")
async def get_config_public():
    return {
        "demo_profile": settings.DEMO_PROFILE,
        "test_mode": settings.TEST_MODE,
        "windows": {
            "dispute_minutes": settings.DISPUTE_WINDOW_MINUTES,
            "no_reply_minutes": settings.NO_REPLY_EXPIRY_MINUTES,
            "min_call_seconds": settings.MIN_CALL_SECONDS,
        },
        "band_thresholds": {
            "trusted_min_sessions": settings.TRUSTED_MIN_SESSIONS,
            "top_rated_min_sessions": settings.TOP_RATED_MIN_SESSIONS,
            "lowered": (settings.TRUSTED_MIN_SESSIONS < 5 or settings.TOP_RATED_MIN_SESSIONS < 10),
        },
    }

