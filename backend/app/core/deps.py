"""
backend/app/core/deps.py - Authentication and authorization FastAPI dependencies.
"""

from collections.abc import Callable
from datetime import UTC, datetime
from uuid import UUID

from fastapi import Depends, Header
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.core.db import User, get_db
from app.core.errors import AppError
from app.core.security import decode_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/verify-otp", auto_error=False)


async def get_current_user(
    token: str | None = Depends(oauth2_scheme),
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db),
) -> User:
    auth_token = token
    if not auth_token and authorization:
        parts = authorization.split()
        if len(parts) == 2 and parts[0].lower() == "bearer":
            auth_token = parts[1]

    if not auth_token:
        raise AppError(code="unauthorized", message="Authentication token required.", status_code=401)

    payload = decode_token(auth_token)
    user_id_str = payload.get("sub")
    if not user_id_str:
        raise AppError(code="token_invalid", message="Token missing subject.", status_code=401)

    try:
        user_uuid = UUID(user_id_str)
    except ValueError:
        raise AppError(code="token_invalid", message="Invalid user id in token.", status_code=401)

    result = await db.execute(
        select(User).options(joinedload(User.institution)).where(User.id == user_uuid)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise AppError(code="user_not_found", message="User account not found.", status_code=401)

    if user.status == "deleted":
        raise AppError(code="account_deleted", message="User account has been deleted.", status_code=401)

    # Update last seen timestamp
    user.last_seen_at = datetime.now(UTC)
    await db.commit()

    return user


def require_role(*roles: str) -> Callable:
    async def role_checker(user: User = Depends(get_current_user)) -> User:
        user_roles = set(user.roles or [])
        if "platform_admin" in user_roles:
            return user
        if not any(r in user_roles for r in roles):
            raise AppError(
                code="insufficient_role",
                message=f"Access denied. Requires one of roles: {list(roles)}",
                status_code=403,
                details={"required_roles": list(roles), "user_roles": list(user_roles)},
            )
        return user

    return role_checker
