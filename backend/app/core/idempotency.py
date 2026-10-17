"""
backend/app/core/idempotency.py - Idempotency key handling.
"""

from typing import Optional
from uuid import UUID
from fastapi import Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import IdempotencyKey


async def get_cached_idempotency_response(session: AsyncSession, key: str) -> Optional[IdempotencyKey]:
    result = await session.execute(select(IdempotencyKey).where(IdempotencyKey.key == key))
    return result.scalar_one_or_none()


async def save_idempotency_response(
    session: AsyncSession,
    key: str,
    response_code: int,
    response_body: dict,
    user_id: Optional[UUID] = None,
):
    entry = IdempotencyKey(
        key=key,
        user_id=user_id,
        response_code=response_code,
        response_body=response_body,
    )
    session.add(entry)
    await session.commit()
