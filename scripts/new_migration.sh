#!/usr/bin/env bash
# scripts/new_migration.sh - Generate a new Alembic migration for a specific module branch
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <module> <message>"
  echo "Example: $0 auth \"add phone verification field\""
  exit 1
fi

MODULE="$1"
MESSAGE="$2"
MODULES=("auth" "trust" "resume" "matching" "availability" "sessions" "ratings" "credits" "payments" "institution")

VALID=false
for m in "${MODULES[@]}"; do
  if [ "$m" == "$MODULE" ]; then
    VALID=true
    break
  fi
done

if [ "$VALID" != "true" ]; then
  echo "Error: Unknown module '$MODULE'. Must be one of: ${MODULES[*]}"
  exit 1
fi

MIGRATIONS_DIR="backend/app/modules/${MODULE}/migrations"
mkdir -p "$MIGRATIONS_DIR"

echo "Creating migration for module '${MODULE}' with message: '${MESSAGE}'..."
cd backend
alembic revision -m "${MESSAGE}" --branch-label="${MODULE}" --version-path="app/modules/${MODULE}/migrations"
cd ..
echo "Migration created in ${MIGRATIONS_DIR}"
