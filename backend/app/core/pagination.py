"""
backend/app/core/pagination.py - Cursor pagination helper.
Contract format: {"items": [...], "next_cursor": "..."}
"""

import base64
import json
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    next_cursor: str | None = None


def encode_cursor(data: dict) -> str:
    raw = json.dumps(data)
    return base64.urlsafe_b64encode(raw.encode("utf-8")).decode("utf-8")


def decode_cursor(cursor_str: str | None) -> dict | None:
    if not cursor_str:
        return None
    try:
        raw = base64.urlsafe_b64decode(cursor_str.encode("utf-8")).decode("utf-8")
        return json.loads(raw)
    except Exception:
        return None
