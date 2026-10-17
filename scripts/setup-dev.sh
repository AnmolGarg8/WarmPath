#!/usr/bin/env bash
set -euo pipefail

echo "================================================================="
echo "              WarmPath Developer Environment Setup                "
echo "================================================================="

# 1. Environment check
echo "[1/5] Checking environment..."
if [ ! -f ".env" ]; then
  if [ -f ".env.example" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
  else
    echo "Warning: .env.example not found."
  fi
fi

# 2. Git pre-commit hooks
echo "[2/5] Installing Git pre-commit hooks..."
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit install --install-hooks
  pre-commit install --hook-type commit-msg
  echo "Pre-commit installed."
else
  echo "pre-commit not found. Please install pre-commit (pip install pre-commit)."
fi

# 3. Generate OpenAPI schema & clients
echo "[3/5] Building unified OpenAPI contract..."
if command -v python3 >/dev/null 2>&1; then
  python3 scripts/build_openapi.py
elif command -v python >/dev/null 2>&1; then
  python scripts/build_openapi.py
fi

echo "[4/5] Generating typed clients for App & Admin..."
bash scripts/gen_clients.sh || true

# 5. Start containers
echo "[5/5] Bootstrapping Docker services..."
if command -v docker >/dev/null 2>&1; then
  docker compose up -d
  echo "Containers started. Database and Redis are online."
else
  echo "Docker not detected. Please ensure Docker is running when testing containers."
fi

echo ""
echo "Setup complete! WarmPath monorepo is ready."
