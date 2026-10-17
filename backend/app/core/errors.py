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
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details or {}

    def to_dict(self) -> dict[str, Any]:
        return {
            "error": {
                "code": self.code,
                "message": self.message,
                "details": self.details if self.details else None,
            }
        }


class PortNotReady(AppError):
    def __init__(self, port_name: str, reason: str = "Service port implementation not registered or offline"):
        super().__init__(
            code="port_not_ready",
            message=f"Port '{port_name}' is not ready: {reason}",
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


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.to_dict(),
    )


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "code": "internal_server_error",
                "message": "An unexpected server error occurred.",
                "details": None,
            }
        },
    )
