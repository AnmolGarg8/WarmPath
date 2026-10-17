#!/bin/bash
set -e

# WarmPath Container Entrypoint Dispatcher
# Supports API mode, Worker mode, Migration mode, or custom commands

MODE="${1:-api}"

case "$MODE" in
  api)
    echo "[WarmPath Entrypoint] Starting FastAPI production server on port ${PORT:-8000}..."
    exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}" --workers "${WORKERS:-4}"
    ;;
  worker)
    echo "[WarmPath Entrypoint] Starting ARQ background worker..."
    exec python -m app.core.worker
    ;;
  migrate)
    echo "[WarmPath Entrypoint] Running Alembic database migrations..."
    exec alembic upgrade heads
    ;;
  seed)
    echo "[WarmPath Entrypoint] Running database seed utility..."
    shift
    exec python scripts/deploy/seed_data.py "$@"
    ;;
  *)
    echo "[WarmPath Entrypoint] Executing custom command: $@"
    exec "$@"
    ;;
esac
