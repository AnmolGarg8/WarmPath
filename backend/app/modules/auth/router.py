"""
backend/app/modules/auth/router.py - Endpoints for authentication, profiles, and verification.
"""

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.db import User, get_db
from app.core.deps import get_current_user
from app.modules.auth.schemas import (
    AuthResponse,
    DataExportResponse,
    InstitutionSchema,
    LogoutRequest,
    RefreshTokenRequest,
    RefreshTokenResponse,
    RequestOtpRequest,
    RequestOtpResponse,
    UpdateMeRequest,
    UserSchema,
    VerificationRequestSchema,
    VerificationStatusResponse,
    VerificationSubmitRequest,
    VerifyOtpRequest,
)
from app.modules.auth.service import AuthService

router = APIRouter(tags=["auth"])


@router.post("/auth/request-otp", response_model=RequestOtpResponse, summary="Request one-time password for email")
async def request_otp(
    payload: RequestOtpRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    client_ip = request.client.host if request.client else "127.0.0.1"
    res = await AuthService.request_otp(payload.email, client_ip, db)
    return res


@router.post("/auth/verify-otp", response_model=AuthResponse, summary="Verify one-time password and receive tokens")
async def verify_otp(
    payload: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
):
    res = await AuthService.verify_otp(payload.email, payload.code, db)
    return res


@router.post("/auth/refresh", response_model=RefreshTokenResponse, summary="Refresh access token")
async def refresh_token(
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    res = await AuthService.refresh_tokens(payload.refresh_token, db)
    return res


@router.post("/auth/logout", summary="Revoke active session token")
async def logout(
    payload: LogoutRequest,
    db: AsyncSession = Depends(get_db),
):
    await AuthService.logout(payload.refresh_token, db)
    return {"message": "Logged out successfully"}


@router.get("/me", response_model=UserSchema, summary="Retrieve current authenticated user profile")
async def get_me(user: User = Depends(get_current_user)):
    return user


@router.patch("/me", response_model=UserSchema, summary="Update authenticated user profile")
async def update_me(
    payload: UpdateMeRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.update_me(user, payload, db)


@router.delete("/me", summary="Request account and data deletion under DPDP Act")
async def delete_me(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await AuthService.delete_me(user, db)
    return {"message": "Account and personal data deleted successfully"}


@router.get("/me/data-export", response_model=DataExportResponse, summary="Download personal data export")
async def get_data_export(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.get_data_export(user, db)


@router.get("/institutions", response_model=list[InstitutionSchema], summary="List supported institutions")
async def get_institutions(db: AsyncSession = Depends(get_db)):
    return await AuthService.get_institutions(db)


@router.post("/verification/submit", response_model=VerificationRequestSchema, status_code=status.HTTP_201_CREATED, summary="Submit institutional credentials for verification")
async def submit_verification(
    payload: VerificationSubmitRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.submit_verification(user, payload, db)


@router.get("/verification/status", response_model=VerificationStatusResponse, summary="Check current verification status")
async def get_verification_status(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await AuthService.get_verification_status(user, db)


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
