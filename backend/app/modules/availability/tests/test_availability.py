import uuid
import asyncio
from datetime import datetime, date, timedelta, timezone
import pytest
from unittest.mock import AsyncMock, patch, MagicMock

from app.modules.availability.service import AvailabilityService, get_week_start
from app.modules.availability.schemas import TimeWindow, AvailabilityUpdate
from app.modules.availability.realtime import (
    MAX_SUBSCRIPTIONS_PER_CONNECTION,
    MAX_PRESENCE_QUERY_USERS,
    publish_presence_change,
    get_presence_channel,
    get_inbox_channel,
    get_session_channel
)
from app.modules.availability.module import ConcretePresencePort
from app.core.security import create_access_token
from app.core.ports import ports

def test_week_start_timezone_boundaries():
    dt_sunday_utc = datetime(2026, 10, 18, 23, 30, tzinfo=timezone.utc)
    utc_week = get_week_start("UTC", dt_sunday_utc)
    assert utc_week == date(2026, 10, 12)

    ist_week = get_week_start("Asia/Kolkata", dt_sunday_utc)
    assert ist_week == date(2026, 10, 19)

def test_calculate_next_window():
    windows = [
        {"weekday": 0, "start_time": "10:00", "end_time": "12:00"},
        {"weekday": 2, "start_time": "14:00", "end_time": "16:00"},
    ]
    next_win = AvailabilityService.calculate_next_window(windows, "UTC")
    assert next_win is not None
    assert "T" in next_win

def test_time_window_validation():
    w = TimeWindow(weekday=1, start_time="09:30", end_time="11:45")
    assert w.weekday == 1

    with pytest.raises(ValueError):
        TimeWindow(weekday=1, start_time="9:30", end_time="25:00")

def test_realtime_channel_naming():
    user_id = str(uuid.uuid4())
    session_id = str(uuid.uuid4())
    assert get_presence_channel(user_id) == f"realtime:presence:{user_id}"
    assert get_inbox_channel(user_id) == f"realtime:inbox:{user_id}"
    assert get_session_channel(session_id) == f"realtime:session:{session_id}"

@pytest.mark.asyncio
async def test_online_ttl_and_presence_mock():
    user_id = str(uuid.uuid4())
    mock_redis = AsyncMock()
    mock_redis.get.return_value = (datetime.now(timezone.utc) + timedelta(minutes=30)).isoformat()
    mock_redis.ttl.return_value = 1800
    mock_redis.set.return_value = True

    with patch("app.modules.availability.service.get_redis", return_value=mock_redis):
        # Set online for 30 minutes
        expires_at, ttl = await AvailabilityService.set_online(user_id, minutes=30, capacity_left=5)
        assert ttl == 1800
        assert expires_at > datetime.now(timezone.utc)
        mock_redis.set.assert_called_once()

        # Check is_online
        online_now, exp, rem_ttl = await AvailabilityService.is_online(user_id)
        assert online_now is True
        assert rem_ttl == 1800

@pytest.mark.asyncio
async def test_presence_port_contract():
    port = ConcretePresencePort()
    test_user_id = str(uuid.uuid4())
    
    with patch("app.modules.availability.service.AvailabilityService.get_presence_status") as mock_status:
        mock_status.return_value = [
            {"user_id": test_user_id, "online_now": True, "capacity_left": 3, "next_window_start": None}
        ]
        status_map = await port.status([test_user_id])
        assert test_user_id in status_map
        assert status_map[test_user_id]["online"] is True
        assert status_map[test_user_id]["capacity_left"] == 3
