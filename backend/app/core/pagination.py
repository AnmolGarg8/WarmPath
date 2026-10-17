"""
backend/app/core/pagination.py - Cursor pagination helper.
Contract format: {"items": [...], "next_cursor": "..."}
"""

import base64
import json
from typing import Any, Generic, List, Optional, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    next_cursor: Optional[str] = None


def encode_cursor(data: dict) -> str:
    raw = json.dumps(data)
    return base64.urlsafe_b64encode(raw.encode("utf-8")).decode("utf-8")


def decode_cursor(cursor_str: Optional[str]) -> Optional[dict]:
    if not cursor_str:
        return None
    try:
        raw = base64.urlsafe_b64decode(cursor_str.encode("utf-8")).decode("utf-8")
        return json.loads(raw)
    except Exception:
        return None
