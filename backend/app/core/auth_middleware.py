"""
backend/app/core/auth_middleware.py - Enforce authentication on all non-allowlisted routes.
Owner: M1
"""

from fastapi import Request, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.errors import AppError
from app.core.security import decode_token

# Public routes allowlisted by specification:
# /auth/request-otp, /auth/verify-otp, /auth/refresh, /institutions, /plans, /config/public, /health, /webhooks/razorpay (signature-verified)
PUBLIC_ALLOWLIST_EXACT = {
    "/auth/request-otp",
    "/auth/verify-otp",
    "/auth/refresh",
    "/institutions",
    "/plans",
    "/config/public",
    "/health",
    "/healthz",
    "/readyz",
    "/webhooks/razorpay",
    "/openapi.json",
    "/docs",
    "/docs/oauth2-redirect",
    "/redoc",
}

PUBLIC_PREFIXES = (
    "/docs",
    "/redoc",
    "/openapi.json",
)


class AuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # Allow CORS preflight requests
        if request.method == "OPTIONS":
            return await call_next(request)

        path = request.url.path.rstrip("/")
        if not path:
            path = "/"

        # Check exact allowlist or prefix
        if path in PUBLIC_ALLOWLIST_EXACT or any(path.startswith(prefix) for prefix in PUBLIC_PREFIXES):
            return await call_next(request)

        # Non-allowlisted route requires authentication
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "error": {
                        "code": "unauthorized",
                        "message": "Authentication required.",
                        "details": None,
                    }
                },
            )

        token = auth_header[7:].strip()
        try:
            payload = decode_token(token)
            if payload.get("type") != "access":
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={
                        "error": {
                            "code": "token_invalid",
                            "message": "Access token required.",
                            "details": None,
                        }
                    },
                )
        except AppError as e:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "error": {
                        "code": e.code,
                        "message": e.message,
                        "details": e.details,
                    }
                },
            )
        except Exception:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "error": {
                        "code": "token_invalid",
                        "message": "Invalid authentication token.",
                        "details": None,
                    }
                },
            )

        return await call_next(request)
