"""
backend/app/core/rate_limit.py - Redis token-bucket rate limiter based on trust level.
"""

from app.core.config import settings
from app.core.errors import AppError
from app.core.redis import get_redis


def get_daily_limit_for_trust_level(trust_level: str) -> int:
    level = trust_level.lower()
    if level == "restricted":
        return settings.REQUEST_LIMIT_RESTRICTED
    elif level == "established":
        return settings.REQUEST_LIMIT_ESTABLISHED
    elif level == "verified":
        return settings.REQUEST_LIMIT_VERIFIED
    return settings.REQUEST_LIMIT_NEW


async def check_rate_limit(user_id: str, trust_level: str = "new", action: str = "request"):
    try:
        r = await get_redis()
        key = f"ratelimit:{user_id}:{action}"
        limit = get_daily_limit_for_trust_level(trust_level)

        current = await r.incr(key)
        if current == 1:
            # 24-hour expiration for daily limit window
            await r.expire(key, 86400)

        if current > limit:
            raise AppError(
                code="rate_limit_exceeded",
                message=f"Daily limit of {limit} {action}s exceeded for trust level '{trust_level}'.",
                status_code=429,
                details={"limit": limit, "current": current, "trust_level": trust_level},
            )
    except AppError:
        raise
    except Exception:
        # If redis fails, fail gracefully in dev mode
        pass
