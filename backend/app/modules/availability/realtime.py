import json
import asyncio
from typing import Dict, Set, Optional
from app.core.redis import get_redis

# Shared Redis pub/sub channel namespaces
# Sessions module and availability module publish/subscribe here:
PRESENCE_CHANNEL_PREFIX = "realtime:presence:"       # realtime:presence:<user_id>
INBOX_CHANNEL_PREFIX = "realtime:inbox:"             # realtime:inbox:<user_id>
SESSION_CHANNEL_PREFIX = "realtime:session:"         # realtime:session:<session_id>

MAX_SUBSCRIPTIONS_PER_CONNECTION = 100
MAX_PRESENCE_QUERY_USERS = 100

def get_presence_channel(user_id: str) -> str:
    return f"{PRESENCE_CHANNEL_PREFIX}{user_id}"

def get_inbox_channel(user_id: str) -> str:
    return f"{INBOX_CHANNEL_PREFIX}{user_id}"

def get_session_channel(session_id: str) -> str:
    return f"{SESSION_CHANNEL_PREFIX}{session_id}"

async def publish_presence_change(user_id: str, online_now: bool, capacity_left: int):
    try:
        r = await get_redis()
        channel = get_presence_channel(user_id)
        payload = json.dumps({
            "type": "presence_update",
            "user_id": user_id,
            "online_now": online_now,
            "capacity_left": capacity_left
        })
        await r.publish(channel, payload)
    except Exception:
        pass
