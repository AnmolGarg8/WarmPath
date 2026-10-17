import uuid
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AppError
from app.core.redis import get_redis
from app.modules.availability.models import Availability, CapacityUsage
from app.modules.availability.realtime import publish_presence_change

ONLINE_KEY_PREFIX = "presence:online:"  # presence:online:<user_id> -> stores ISO expiry

def get_online_key(user_id: str) -> str:
    return f"{ONLINE_KEY_PREFIX}{user_id}"

def get_week_start(tz_name: str, reference_dt: Optional[datetime] = None) -> date:
    try:
        tz = ZoneInfo(tz_name)
    except Exception:
        tz = timezone.utc
    
    if reference_dt is None:
        local_now = datetime.now(tz)
    else:
        if reference_dt.tzinfo is None:
            local_now = reference_dt.replace(tzinfo=timezone.utc).astimezone(tz)
        else:
            local_now = reference_dt.astimezone(tz)
            
    monday = local_now.date() - timedelta(days=local_now.weekday())
    return monday

class AvailabilityService:
    @staticmethod
    async def get_or_create_availability(session: AsyncSession, user_id: uuid.UUID) -> Availability:
        stmt = select(Availability).where(Availability.user_id == user_id)
        result = await session.execute(stmt)
        avail = result.scalar_one_or_none()
        if not avail:
            avail = Availability(
                user_id=user_id,
                weekly_capacity=5,
                timezone="UTC",
                windows=[]
            )
            session.add(avail)
            await session.commit()
            await session.refresh(avail)
        return avail

    @staticmethod
    async def update_availability(
        session: AsyncSession,
        user_id: uuid.UUID,
        weekly_capacity: int,
        tz_name: str,
        windows: List[Dict[str, Any]]
    ) -> Availability:
        try:
            ZoneInfo(tz_name)
        except Exception:
            raise AppError(code="invalid_timezone", message=f"Invalid IANA timezone '{tz_name}'", status_code=400)

        avail = await AvailabilityService.get_or_create_availability(session, user_id)
        avail.weekly_capacity = weekly_capacity
        avail.timezone = tz_name
        avail.windows = windows
        avail.updated_at = datetime.now(timezone.utc)
        await session.commit()
        await session.refresh(avail)
        return avail

    @staticmethod
    async def get_capacity_usage(session: AsyncSession, user_id: uuid.UUID, tz_name: str) -> Tuple[int, int]:
        week_start = get_week_start(tz_name)
        stmt = select(CapacityUsage).where(
            CapacityUsage.user_id == user_id,
            CapacityUsage.week_start == week_start
        )
        result = await session.execute(stmt)
        usage = result.scalar_one_or_none()
        used = usage.used if usage else 0
        return week_start, used

    @staticmethod
    async def increment_capacity_usage(session: AsyncSession, user_id: uuid.UUID, tz_name: str, count: int = 1):
        week_start = get_week_start(tz_name)
        stmt = select(CapacityUsage).where(
            CapacityUsage.user_id == user_id,
            CapacityUsage.week_start == week_start
        )
        result = await session.execute(stmt)
        usage = result.scalar_one_or_none()
        if not usage:
            usage = CapacityUsage(
                user_id=user_id,
                week_start=week_start,
                used=count
            )
            session.add(usage)
        else:
            usage.used += count
        await session.commit()

    @staticmethod
    async def decrement_capacity_usage(session: AsyncSession, user_id: uuid.UUID, tz_name: str, count: int = 1):
        week_start = get_week_start(tz_name)
        stmt = select(CapacityUsage).where(
            CapacityUsage.user_id == user_id,
            CapacityUsage.week_start == week_start
        )
        result = await session.execute(stmt)
        usage = result.scalar_one_or_none()
        if usage and usage.used > 0:
            usage.used = max(0, usage.used - count)
            await session.commit()

    @staticmethod
    async def set_online(user_id: str, minutes: int, capacity_left: int) -> Tuple[datetime, int]:
        r = await get_redis()
        key = get_online_key(user_id)
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=minutes)
        ttl_seconds = minutes * 60
        await r.set(key, expires_at.isoformat(), ex=ttl_seconds)
        await publish_presence_change(user_id, online_now=True, capacity_left=capacity_left)
        return expires_at, ttl_seconds

    @staticmethod
    async def set_offline(user_id: str, capacity_left: int):
        r = await get_redis()
        key = get_online_key(user_id)
        await r.delete(key)
        await publish_presence_change(user_id, online_now=False, capacity_left=capacity_left)

    @staticmethod
    async def is_online(user_id: str) -> Tuple[bool, Optional[datetime], int]:
        r = await get_redis()
        key = get_online_key(user_id)
        val = await r.get(key)
        if not val:
            return False, None, 0
        ttl = await r.ttl(key)
        if ttl <= 0:
            return False, None, 0
        try:
            expires_at = datetime.fromisoformat(val)
            return True, expires_at, ttl
        except Exception:
            return True, None, ttl

    @staticmethod
    def calculate_next_window(windows: List[Dict[str, Any]], tz_name: str) -> Optional[str]:
        if not windows:
            return None
        try:
            tz = ZoneInfo(tz_name)
        except Exception:
            tz = timezone.utc

        now = datetime.now(tz)
        current_weekday = now.weekday()
        current_time_str = now.strftime("%H:%M")

        # Check upcoming windows over the next 7 days
        for day_offset in range(8):
            target_day = (current_weekday + day_offset) % 7
            for w in windows:
                if w.get("weekday") == target_day:
                    start_str = w.get("start_time")
                    if day_offset == 0 and start_str <= current_time_str:
                        continue  # already started or passed today
                    target_date = (now + timedelta(days=day_offset)).date()
                    h, m = map(int, start_str.split(":"))
                    next_dt = datetime(target_date.year, target_date.month, target_date.day, h, m, tzinfo=tz)
                    return next_dt.isoformat()
        return None

    @staticmethod
    async def get_presence_status(session: AsyncSession, user_ids: List[str]) -> List[Dict[str, Any]]:
        if not user_ids:
            return []

        # Unique & capped at 100
        clean_ids = list(dict.fromkeys(user_ids))[:100]
        results = []

        # Parse UUIDs
        valid_uuids = []
        for uid in clean_ids:
            try:
                valid_uuids.append(uuid.UUID(uid))
            except Exception:
                pass

        if not valid_uuids:
            return []

        # Fetch availabilities
        stmt = select(Availability).where(Availability.user_id.in_(valid_uuids))
        res = await session.execute(stmt)
        avail_map = {str(a.user_id): a for a in res.scalars().all()}

        # Fetch usage for each
        for uid in clean_ids:
            avail = avail_map.get(uid)
            capacity = avail.weekly_capacity if avail else 5
            tz_name = avail.timezone if avail else "UTC"
            windows = avail.windows if avail else []

            week_start = get_week_start(tz_name)
            usage_stmt = select(CapacityUsage.used).where(
                CapacityUsage.user_id == uuid.UUID(uid),
                CapacityUsage.week_start == week_start
            )
            u_res = await session.execute(usage_stmt)
            used = u_res.scalar_one_or_none() or 0
            capacity_left = max(0, capacity - used)

            online_now, _, _ = await AvailabilityService.is_online(uid)
            next_window = AvailabilityService.calculate_next_window(windows, tz_name)

            results.append({
                "user_id": uid,
                "online_now": online_now,
                "capacity_left": capacity_left,
                "next_window_start": next_window
            })

        return results
