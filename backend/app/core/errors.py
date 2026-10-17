"""
backend/app/core/errors.py - Unified error representation and exception handlers.
Contract format: {"error": {"code": "...", "message": "...", "details": {...}}}
"""

from typing import Any

from fastapi import Request, status
from fastapi.responses import JSONResponse


class AppError(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        details: dict[str, Any] | None = None,
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(message)


class PortNotReady(AppError):
    def __init__(self, port_name: str):
        super().__init__(
            code="port_not_ready",
            message=f"Service port '{port_name}' is not ready.",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            details={"port": port_name},
        )


class ModuleNotImplemented(AppError):
    def __init__(self, endpoint: str):
        super().__init__(
            code="module_not_implemented",
            message=f"Endpoint '{endpoint}' is scaffolded and pending module implementation.",
            status_code=status.HTTP_501_NOT_IMPLEMENTED,
            details={"endpoint": endpoint},
        )


def error_response(code: str, message: str, status_code: int, details: dict[str, Any] | None = None) -> JSONResponse:
    return JSONResponse(
        status_code=status_code,
        content={
            "error": {
                "code": code,
                "message": message,
                "details": details or {},
            }
        },
    )


from fastapi.exceptions import RequestValidationError


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return error_response(
        code=exc.code,
        message=exc.message,
        status_code=exc.status_code,
        details=exc.details,
    )


async def validation_error_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    errors = exc.errors()
    msg = errors[0].get("msg", "Invalid request parameters") if errors else "Validation error"
    return error_response(
        code="validation_error",
        message=msg,
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        details={"validation_errors": errors},
    )
