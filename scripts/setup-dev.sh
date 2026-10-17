#!/usr/bin/env bash
# scripts/setup-dev.sh - Local developer environment setup
set -euo pipefail

echo "==> Setting up WarmPath development environment..."

# 1. Environment file
if [ ! -f .env ]; then
  echo "Copying .env.example to .env..."
  cp .env.example .env
fi

# 2. Check and install pre-commit
if command -v pre-commit &> /dev/null; then
  echo "Installing git pre-commit hooks..."
  pre-commit install
else
  echo "Warning: pre-commit is not installed globally. Run: pip install pre-commit && pre-commit install"
fi

# 3. Generate OpenAPI merged contract and clients
echo "Building merged OpenAPI contract..."
python3 scripts/build_openapi.py || python scripts/build_openapi.py

echo "Generating API clients..."
bash scripts/gen_clients.sh

# 4. Start Docker dependencies
if command -v docker &> /dev/null; then
  echo "Starting PostgreSQL and Redis via Docker Compose..."
  docker compose up -d postgres redis mailpit
else
  echo "Warning: Docker is not available. Please start PostgreSQL (with pgvector) and Redis manually."
fi

echo "==> WarmPath environment setup complete!"
echo "Next steps:"
echo "  1. Set your member role: git config warmpath.member m1 (or m2, m3, m4)"
echo "  2. Backend: cd backend && pip install -e . && alembic upgrade heads && uvicorn app.main:app --reload"
echo "  3. Flutter: cd app && flutter run -d emulator-5554"
echo "  4. Admin:   cd admin && npm install && npm run dev"
