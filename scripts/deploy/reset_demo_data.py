#!/usr/bin/env python3
"""
scripts/deploy/reset_demo_data.py - Safely reset transient demo records.
Clears test requests, active call sessions, in-app messages, and temporary Redis presence keys
WITHOUT dropping database tables, deleting reference institutions, or purging approved rosters.
"""

import argparse
import asyncio
import os
import sys
from pathlib import Path


async def reset_demo_records(force: bool = False):
    if not force:
        confirm = input("Are you sure you want to reset transient demo sessions & requests? (yes/no): ")
        if confirm.strip().lower() not in ("yes", "y"):
            print("Reset aborted.")
            return 0

    print("[DEMO RESET] Connecting to database and Redis...")
    try:
        from app.core.db import async_session_maker
        from app.core.redis import get_redis
        from sqlalchemy import text
    except ImportError:
        print("Error: Backend dependencies not found in PYTHONPATH. Run within backend environment.", file=sys.stderr)
        return 1

    # 1. Clear database transient tables safely
    async with async_session_maker() as session:
        transient_tables = [
            "session_messages",
            "messages",
            "ratings",
            "disputes",
            "call_sessions",
            "sessions",
            "mentorship_requests",
            "requests",
            "capacity_usage",
            "idempotency_keys"
        ]
        cleared_tables = []
        for tbl in transient_tables:
            try:
                await session.execute(text(f"DELETE FROM {tbl}"))
                cleared_tables.append(tbl)
            except Exception:
                # Table might not exist in current migration state; roll back savepoint
                await session.rollback()

        await session.commit()
        print(f"[DEMO RESET] Cleared transient database tables: {', '.join(cleared_tables) if cleared_tables else 'None found'}")

    # 2. Reset transient Redis keys (online presence, temporary active windows)
    try:
        r = await get_redis()
        # Find presence keys
        keys = []
        async for key in r.scan_iter("presence:*"):
            keys.append(key)
        async for key in r.scan_iter("online:*"):
            keys.append(key)
        async for key in r.scan_iter("slot_lock:*"):
            keys.append(key)

        if keys:
            await r.delete(*keys)
            print(f"[DEMO RESET] Flushed {len(keys)} transient Redis presence/session keys.")
        else:
            print("[DEMO RESET] Redis has no transient presence keys to clear.")
    except Exception as e:
        print(f"[DEMO RESET] Notice: Redis cleanup skipped or unreachable ({e}).")

    print("[DEMO RESET] Demo environment has been safely reset to a fresh presentation baseline.")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Safely reset WarmPath demo session records")
    parser.add_argument("--force", "-f", action="store_true", help="Skip confirmation prompt")
    args = parser.parse_args()

    return asyncio.run(reset_demo_records(force=args.force))


if __name__ == "__main__":
    sys.exit(main())
