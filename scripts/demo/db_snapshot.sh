#!/usr/bin/env bash
# scripts/demo/db_snapshot.sh
# Creates and restores pg_dump snapshots of the local demo database.
# Refuses to run against remote, staging, or production databases.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BACKEND_DIR="${REPO_ROOT}/backend"
SNAPSHOT_DIR="${REPO_ROOT}/data/snapshots"

CONTAINER_NAME="postgres"
DB_USER="warmpath"
DB_NAME="warmpath_db"

ACTION="${1:-save}"
SNAPSHOT_FILE="${2:-}"

# --- SAFETY REFUSAL CHECK ---
DATABASE_URL="postgresql://warmpath:secretpassword@localhost:5432/warmpath_db"
if [ -f "${BACKEND_DIR}/.env" ]; then
    ENV_URL=$(grep -E '^\s*DATABASE_URL\s*=' "${BACKEND_DIR}/.env" | cut -d '=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -n "${ENV_URL}" ]; then
        DATABASE_URL="${ENV_URL}"
    fi
fi

# Run safety validator via Python db_safety module
python3 -c "
import sys
from scripts.demo.db_safety import is_safe_local_database
safe, reason = is_safe_local_database('${DATABASE_URL}')
if not safe:
    print(f'[SAFETY REFUSAL] {reason}', file=sys.stderr)
    sys.exit(1)
print(f'[SAFETY CHECK] {reason}')
" || {
    echo "[SAFETY REFUSAL] Refusing to snapshot/restore: Database URL '${DATABASE_URL}' does not match local demo criteria." >&2
    exit 1
}

mkdir -p "${SNAPSHOT_DIR}"

case "${ACTION}" in
    save|backup)
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        if [ -z "${SNAPSHOT_FILE}" ]; then
            TARGET="${SNAPSHOT_DIR}/warmpath_demo_${TIMESTAMP}.sql"
        else
            TARGET="${SNAPSHOT_FILE}"
        fi

        echo "[SNAPSHOT] Exporting pg_dump from container '${CONTAINER_NAME}' to '${TARGET}'..."
        docker compose -f "${BACKEND_DIR}/docker-compose.yml" exec -T "${CONTAINER_NAME}" \
            pg_dump -U "${DB_USER}" --clean --if-exists "${DB_NAME}" > "${TARGET}"

        if [ -s "${TARGET}" ]; then
            echo "[SNAPSHOT] SUCCESS: Database snapshot saved: ${TARGET}"
        else
            echo "[SNAPSHOT] ERROR: Snapshot file is empty or was not created." >&2
            exit 1
        fi
        ;;

    restore|load)
        if [ -z "${SNAPSHOT_FILE}" ]; then
            TARGET=$(ls -t "${SNAPSHOT_DIR}"/*.sql 2>/dev/null | head -n 1 || true)
            if [ -z "${TARGET}" ]; then
                echo "[SNAPSHOT] ERROR: No snapshot found in ${SNAPSHOT_DIR} to restore." >&2
                exit 1
            fi
        else
            TARGET="${SNAPSHOT_FILE}"
        fi

        if [ ! -f "${TARGET}" ]; then
            echo "[SNAPSHOT] ERROR: Snapshot file not found: ${TARGET}" >&2
            exit 1
        fi

        echo "[SNAPSHOT] Restoring database '${DB_NAME}' from '${TARGET}'..."
        docker compose -f "${BACKEND_DIR}/docker-compose.yml" exec -T "${CONTAINER_NAME}" \
            psql -U "${DB_USER}" -d "${DB_NAME}" < "${TARGET}"

        echo "[SNAPSHOT] SUCCESS: Database restored to known-good demo state from ${TARGET}."
        ;;

    list)
        echo "Available WarmPath Demo Snapshots in ${SNAPSHOT_DIR} :"
        ls -lh "${SNAPSHOT_DIR}"/*.sql 2>/dev/null || echo "No snapshots found."
        ;;

    *)
        echo "Usage: $0 {save|restore|list} [snapshot_file]"
        exit 1
        ;;
esac
