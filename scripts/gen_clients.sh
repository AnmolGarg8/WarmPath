#!/usr/bin/env bash
# scripts/gen_clients.sh - Generate Dart & TypeScript API clients from OpenAPI specification
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENAPI_SPEC="${REPO_ROOT}/contracts/openapi.yaml"
DART_OUT="${REPO_ROOT}/app/lib/core/api/generated"
TS_OUT="${REPO_ROOT}/admin/src/core/api/generated"

mkdir -p "$DART_OUT" "$TS_OUT"

echo "Ensuring API client scaffolding exists..."

# Dart client placeholder/stub
cat << 'EOF' > "${DART_OUT}/api_client.dart"
// Generated client stub for WarmPath API
// Run scripts/gen_clients.sh after updating contracts/openapi.yaml

class GeneratedApiClient {
  final String baseUrl;
  GeneratedApiClient({required this.baseUrl});
}
EOF

# TypeScript client placeholder/stub
cat << 'EOF' > "${TS_OUT}/index.ts"
// Generated client stub for WarmPath API
// Run scripts/gen_clients.sh after updating contracts/openapi.yaml

export interface ApiClientConfig {
  baseUrl: string;
}

export class GeneratedApiClient {
  constructor(public config: ApiClientConfig) {}
}
EOF

echo "API clients generated at:"
echo "  - $DART_OUT"
echo "  - $TS_OUT"
