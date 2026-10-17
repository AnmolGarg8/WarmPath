import uuid
from typing import Any
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from app.core.models_base import IdempotencyKey


async def get_idempotent_response(
    session: AsyncSession,
    key: str,
    user_id: uuid.UUID,
) -> JSONResponse | None:
    stmt = select(IdempotencyKey).where(
        IdempotencyKey.key == key,
        IdempotencyKey.user_id == user_id,
    )
    result = await session.execute(stmt)
    record = result.scalar_one_or_none()
    if record:
        return JSONResponse(
            status_code=record.response_code,
            content=record.response_body,
            headers={"X-Cache-Lookup": "HIT-IDEMPOTENCY"},
        )
    return None


async def save_idempotent_response(
    session: AsyncSession,
    key: str,
    user_id: uuid.UUID,
    status_code: int,
    body: dict[str, Any],
) -> None:
    record = IdempotencyKey(
        key=key,
        user_id=user_id,
        response_code=status_code,
        response_body=body,
    )
    session.add(record)
    await session.commit()
