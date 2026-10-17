import asyncio
from datetime import datetime, timezone
from sqlalchemy import select, update
from app.core.config import settings
from app.core.db import async_session_factory
from app.core.models_base import OutboxEvent
from app.core.events import event_bus
from app.core.logging import logger


async def process_outbox_events(ctx: dict):
    """Worker task that polls pending outbox events and dispatches them to subscribers."""
    now = datetime.now(timezone.utc)
    async with async_session_factory() as session:
        stmt = (
            select(OutboxEvent)
            .where(
                OutboxEvent.status == "pending",
                OutboxEvent.scheduled_at <= now,
            )
            .order_by(OutboxEvent.created_at.asc())
            .limit(50)
            .with_for_update(skip_locked=True)
        )
        res = await session.execute(stmt)
        events = res.scalars().all()

        for event in events:
            try:
                await event_bus.dispatch_in_memory(event.topic, event.payload)
                event.status = "processed"
                event.processed_at = datetime.now(timezone.utc)
            except Exception as e:
                event.attempts += 1
                logger.error("outbox_dispatch_failed", event_id=str(event.id), topic=event.topic, error=str(e))
                if event.attempts >= 5:
                    event.status = "failed"

        await session.commit()


async def startup(ctx: dict):
    logger.info("arq_worker_started", redis_url=settings.REDIS_URL)


async def shutdown(ctx: dict):
    logger.info("arq_worker_stopped")


class WorkerSettings:
    redis_settings = settings.REDIS_URL
    on_startup = startup
    on_shutdown = shutdown
    functions = [process_outbox_events]
    cron_jobs = []
