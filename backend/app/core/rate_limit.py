import time
from redis.asyncio import Redis
from app.core.errors import AppError
from fastapi import status


class TokenBucketRateLimiter:
    def __init__(self, redis: Redis):
        self.redis = redis

    async def check_rate_limit(
        self,
        key: str,
        max_tokens: int,
        refill_rate_per_sec: float = 1.0,
        tokens_requested: int = 1,
    ) -> bool:
        now = time.time()
        bucket_key = f"ratelimit:{key}"

        # Using Redis hash for bucket state
        pipe = self.redis.pipeline()
        pipe.hget(bucket_key, "tokens")
        pipe.hget(bucket_key, "last_updated")
        results = await pipe.execute()

        raw_tokens, raw_last_updated = results[0], results[1]

        if raw_tokens is None or raw_last_updated is None:
            tokens = float(max_tokens)
            last_updated = now
        else:
            last_updated = float(raw_last_updated)
            elapsed = max(0.0, now - last_updated)
            tokens = min(float(max_tokens), float(raw_tokens) + elapsed * refill_rate_per_sec)

        if tokens >= tokens_requested:
            tokens -= tokens_requested
            pipe = self.redis.pipeline()
            pipe.hset(bucket_key, mapping={"tokens": str(tokens), "last_updated": str(now)})
            pipe.expire(bucket_key, int(max_tokens / refill_rate_per_sec) + 3600)
            await pipe.execute()
            return True
        else:
            return False

    async def acquire_or_raise(
        self,
        key: str,
        limit_daily: int,
        action: str = "request",
    ) -> None:
        # Refill rate spread across 24h
        refill_rate = limit_daily / 86400.0
        allowed = await self.check_rate_limit(
            key=f"{action}:{key}",
            max_tokens=limit_daily,
            refill_rate_per_sec=refill_rate,
            tokens_requested=1,
        )
        if not allowed:
            raise AppError(
                code="rate_limit_exceeded",
                message=f"Daily limit of {limit_daily} {action}(s) reached for your trust level.",
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                details={"limit": limit_daily, "action": action},
            )
