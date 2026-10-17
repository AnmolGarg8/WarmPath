#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <module> \"migration message\""
  echo "Example: $0 auth \"add_refresh_tokens_table\""
  echo ""
  echo "Available modules:"
  echo "  core, auth, trust, resume, matching, availability, sessions, ratings, credits, payments, institution"
  exit 1
fi

MODULE="$1"
MESSAGE="$2"

cd "$(dirname "$0")/../backend"

echo "Creating new migration for branch '$MODULE': '$MESSAGE'..."
alembic revision --head="${MODULE}@head" -m "$MESSAGE" --version-path="app/modules/${MODULE}/migrations/versions"

echo ""
echo "Migration created successfully."
echo "To apply all migrations across all module branches, run:"
echo "  alembic upgrade heads"
