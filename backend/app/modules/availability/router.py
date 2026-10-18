import uuid
import json
import asyncio
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status, Header
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_db, async_session_maker
from app.core.errors import AppError
from app.core.rate_limit import check_rate_limit
from app.core.security import decode_token
from app.core.redis import get_redis
from app.modules.availability.schemas import (
    AvailabilityUpdate,
    AvailabilityResponse,
    OnlineRequest,
    OnlineResponse,
    PresenceStatus,
    TimeWindow
)
from app.modules.availability.service import AvailabilityService, get_week_start
from app.modules.availability.realtime import (
    MAX_SUBSCRIPTIONS_PER_CONNECTION,
    MAX_PRESENCE_QUERY_USERS,
    PRESENCE_CHANNEL_PREFIX,
    INBOX_CHANNEL_PREFIX,
    SESSION_CHANNEL_PREFIX
)

router = APIRouter(tags=["availability"])

async def get_current_user_id(authorization: Optional[str] = Header(None)) -> str:
    if not authorization or not authorization.startswith("Bearer "):
        raise AppError(code="unauthorized", message="Authentication required", status_code=status.HTTP_401_UNAUTHORIZED)
    token = authorization.split(" ")[1]
    payload = decode_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise AppError(code="unauthorized", message="Invalid authentication token", status_code=status.HTTP_401_UNAUTHORIZED)
    return user_id

@router.put("/me/availability", response_model=AvailabilityResponse, summary="Set weekly schedule and session capacity limit")
async def put_me_availability(
    data: AvailabilityUpdate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    avail = await AvailabilityService.update_availability(
        db,
        uid,
        data.weekly_capacity,
        data.timezone,
        [w.model_dump() for w in data.windows]
    )
    _, used = await AvailabilityService.get_capacity_usage(db, uid, avail.timezone)
    capacity_left = max(0, avail.weekly_capacity - used)

    return AvailabilityResponse(
        user_id=str(avail.user_id),
        weekly_capacity=avail.weekly_capacity,
        timezone=avail.timezone,
        windows=[TimeWindow(**w) for w in avail.windows],
        used_this_week=used,
        capacity_left=capacity_left,
        updated_at=avail.updated_at
    )

@router.get("/me/availability", response_model=AvailabilityResponse, summary="Retrieve current availability schedule")
async def get_me_availability(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    avail = await AvailabilityService.get_or_create_availability(db, uid)
    _, used = await AvailabilityService.get_capacity_usage(db, uid, avail.timezone)
    capacity_left = max(0, avail.weekly_capacity - used)

    return AvailabilityResponse(
        user_id=str(avail.user_id),
        weekly_capacity=avail.weekly_capacity,
        timezone=avail.timezone,
        windows=[TimeWindow(**w) for w in avail.windows],
        used_this_week=used,
        capacity_left=capacity_left,
        updated_at=avail.updated_at
    )

@router.post("/me/online", response_model=OnlineResponse, summary="Open instant connect window")
async def post_me_online(
    req: OnlineRequest,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    avail = await AvailabilityService.get_or_create_availability(db, uid)
    _, used = await AvailabilityService.get_capacity_usage(db, uid, avail.timezone)
    capacity_left = max(0, avail.weekly_capacity - used)

    expires_at, ttl = await AvailabilityService.set_online(user_id, req.minutes, capacity_left)
    return OnlineResponse(
        user_id=user_id,
        online_now=True,
        expires_at=expires_at,
        remaining_seconds=ttl
    )

@router.delete("/me/online", response_model=OnlineResponse, summary="Close instant connect window")
async def delete_me_online(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    uid = uuid.UUID(user_id)
    avail = await AvailabilityService.get_or_create_availability(db, uid)
    _, used = await AvailabilityService.get_capacity_usage(db, uid, avail.timezone)
    capacity_left = max(0, avail.weekly_capacity - used)

    await AvailabilityService.set_offline(user_id, capacity_left)
    return OnlineResponse(
        user_id=user_id,
        online_now=False,
        expires_at=None,
        remaining_seconds=0
    )

@router.get("/presence", response_model=List[PresenceStatus], summary="Check online and capacity status for givers")
async def get_presence(
    user_ids: str = Query(..., description="Comma-separated list of giver UUIDs (max 100)"),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(get_current_user_id)
):
    await check_rate_limit(user_id, trust_level="verified", action="presence_query")
    raw_ids = [uid.strip() for uid in user_ids.split(",") if uid.strip()]
    if len(raw_ids) > MAX_PRESENCE_QUERY_USERS:
        raise AppError(code="too_many_ids", message=f"Maximum {MAX_PRESENCE_QUERY_USERS} user IDs permitted.", status_code=400)

    statuses = await AvailabilityService.get_presence_status(db, raw_ids)
    return [PresenceStatus(**s) for s in statuses]

@router.get("/ws", status_code=status.HTTP_101_SWITCHING_PROTOCOLS, include_in_schema=True)
async def websocket_handshake():
    """WebSocket presence connection endpoint descriptor."""
    return {"message": "Switching protocols to WebSocket"}

@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None)
):
    await websocket.accept()
    auth_user_id = None

    # Authenticate via query param or initial auth message
    if token:
        try:
            payload = decode_token(token)
            auth_user_id = payload.get("sub")
        except Exception:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    if not auth_user_id:
        try:
            init_msg = await asyncio.wait_for(websocket.receive_text(), timeout=10.0)
            data = json.loads(init_msg)
            if data.get("type") == "auth" and "token" in data:
                payload = decode_token(data["token"])
                auth_user_id = payload.get("sub")
            else:
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                return
        except Exception:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

    # User authenticated!
    redis_conn = await get_redis()
    pubsub = redis_conn.pubsub()
    subscribed_channels = set()

    # Automatically subscribe to own private inbox
    own_inbox = f"{INBOX_CHANNEL_PREFIX}{auth_user_id}"
    await pubsub.subscribe(own_inbox)
    subscribed_channels.add(own_inbox)

    async def redis_listener():
        try:
            while True:
                msg = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)
                if msg and msg.get("data"):
                    data = msg["data"]
                    if isinstance(data, bytes):
                        data = data.decode("utf-8")
                    await websocket.send_text(data)
                await asyncio.sleep(0.01)
        except asyncio.CancelledError:
            pass
        except Exception:
            pass

    listener_task = asyncio.create_task(redis_listener())

    try:
        while True:
            text = await websocket.receive_text()
            msg = json.loads(text)
            action = msg.get("action")

            if action == "ping":
                await websocket.send_json({"type": "pong"})
            elif action == "subscribe_presence":
                # Limit subscriptions
                giver_ids = msg.get("giver_ids", [])
                if len(subscribed_channels) + len(giver_ids) > MAX_SUBSCRIPTIONS_PER_CONNECTION:
                    await websocket.send_json({"error": "subscription_limit_exceeded", "max": MAX_SUBSCRIPTIONS_PER_CONNECTION})
                    continue

                for gid in giver_ids:
                    chan = f"{PRESENCE_CHANNEL_PREFIX}{gid}"
                    if chan not in subscribed_channels:
                        await pubsub.subscribe(chan)
                        subscribed_channels.add(chan)
                await websocket.send_json({"type": "subscribed", "count": len(subscribed_channels)})

            elif action == "unsubscribe_presence":
                giver_ids = msg.get("giver_ids", [])
                for gid in giver_ids:
                    chan = f"{PRESENCE_CHANNEL_PREFIX}{gid}"
                    if chan in subscribed_channels:
                        await pubsub.unsubscribe(chan)
                        subscribed_channels.remove(chan)
                await websocket.send_json({"type": "unsubscribed", "count": len(subscribed_channels)})

            elif action == "subscribe_session":
                # Only allowed to subscribe to sessions the user is party to (enforced by session_id convention or checked)
                session_id = msg.get("session_id")
                if session_id:
                    chan = f"{SESSION_CHANNEL_PREFIX}{session_id}"
                    if chan not in subscribed_channels and len(subscribed_channels) < MAX_SUBSCRIPTIONS_PER_CONNECTION:
                        await pubsub.subscribe(chan)
                        subscribed_channels.add(chan)
                        await websocket.send_json({"type": "session_subscribed", "session_id": session_id})
    except (WebSocketDisconnect, asyncio.CancelledError):
        pass
    finally:
        listener_task.cancel()
        await pubsub.unsubscribe()
        await pubsub.close()
