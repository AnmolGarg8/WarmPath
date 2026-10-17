"""
backend/app/core/idempotency.py - Idempotency key handling.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import IdempotencyKey


async def get_cached_idempotency_response(session: AsyncSession, key: str) -> IdempotencyKey | None:
    result = await session.execute(select(IdempotencyKey).where(IdempotencyKey.key == key))
    return result.scalar_one_or_none()


async def save_idempotency_response(
    session: AsyncSession,
    key: str,
    response_code: int,
    response_body: dict,
    user_id: UUID | None = None,
):
    entry = IdempotencyKey(
        key=key,
        user_id=user_id,
        response_code=response_code,
        response_body=response_body,
    )
    session.add(entry)
    await session.commit()
