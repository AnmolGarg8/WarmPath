#!/bin/bash
set -e

# WarmPath Production Release Script
# Executed automatically during CI/CD deploy phase or container startup

echo "=== [WarmPath Release] Starting Release Pipeline ==="

# Step 1: Verify Database Connectivity
echo "[WarmPath Release] 1/3 Verifying database connectivity..."
python -c "
import asyncio, sys
from app.core.db import async_session_maker
from sqlalchemy import text
async def check():
    try:
        async with async_session_maker() as s:
            await s.execute(text('SELECT 1'))
            print('Database connected successfully.')
    except Exception as e:
        print(f'Database connection failed: {e}', file=sys.stderr)
        sys.exit(1)
asyncio.run(check())
"

# Step 2: Run Alembic Migrations
echo "[WarmPath Release] 2/3 Applying database migrations (alembic upgrade heads)..."
alembic upgrade heads

# Step 3: Sync Reference Data & Taxonomy
echo "[WarmPath Release] 3/3 Synchronizing reference data and skills taxonomy..."
python scripts/deploy/seed_data.py

echo "=== [WarmPath Release] Release Pipeline Completed Successfully! ==="
