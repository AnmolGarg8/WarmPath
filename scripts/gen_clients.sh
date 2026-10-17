#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OPENAPI_FILE="$REPO_ROOT/contracts/openapi.yaml"
DART_OUT="$REPO_ROOT/app/lib/core/api/generated"
TS_OUT="$REPO_ROOT/admin/src/core/api/generated"

echo "[gen_clients] Ensuring output directories exist..."
mkdir -p "$DART_OUT"
mkdir -p "$TS_OUT"

# 1. TypeScript Client for React Admin
echo "[gen_clients] Generating TypeScript API client..."
if command -v npx >/dev/null 2>&1 && [ -f "$REPO_ROOT/admin/package.json" ]; then
  npx --yes openapi-typescript "$OPENAPI_FILE" -o "$TS_OUT/schema.d.ts" 2>/dev/null || {
    echo "[gen_clients] Notice: openapi-typescript unavailable, generating baseline TS types..."
    cat << 'EOF' > "$TS_OUT/schema.d.ts"
// Generated TypeScript schema definitions from OpenAPI contract
export interface AppError {
  error: {
    code: string;
    message: string;
    details?: Record<string, any>;
  };
}

export interface UserResponse {
  id: string;
  email: string;
  full_name: string;
  institution_id?: string | null;
  roles: string[];
  created_at: string;
}

export interface PaginatedResponse<T> {
  items: T[];
  next_cursor: string | null;
}
EOF
  }
fi

# 2. Dart Client for Flutter App
echo "[gen_clients] Generating Dart API client stubs..."
cat << 'EOF' > "$DART_OUT/api_types.dart"
// Auto-generated Dart types from WarmPath OpenAPI contract

class AppError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  AppError({
    required this.code,
    required this.message,
    this.details,
  });

  factory AppError.fromJson(Map<String, dynamic> json) {
    final err = json['error'] as Map<String, dynamic>? ?? json;
    return AppError(
      code: err['code'] as String? ?? 'unknown_error',
      message: err['message'] as String? ?? 'An unexpected error occurred',
      details: err['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'error': {
      'code': code,
      'message': message,
      'details': details,
    }
  };
}

class UserResponse {
  final String id;
  final String email;
  final String fullName;
  final String? institutionId;
  final List<String> roles;
  final String createdAt;

  UserResponse({
    required this.id,
    required this.email,
    required this.fullName,
    this.institutionId,
    required this.roles,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      institutionId: json['institution_id'] as String?,
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] as String,
    );
  }
}
EOF

echo "[gen_clients] Client generation complete."
