#!/usr/bin/env python3
"""
Merges individual module OpenAPI fragments from contracts/modules/*.yaml
into a single unified contracts/openapi.yaml specification.
"""

import sys
from pathlib import Path
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULES_DIR = REPO_ROOT / "contracts" / "modules"
OUTPUT_FILE = REPO_ROOT / "contracts" / "openapi.yaml"

BASE_OPENAPI = {
    "openapi": "3.0.3",
    "info": {
        "title": "WarmPath API",
        "version": "1.0.0",
        "description": "API contract for WarmPath alumni network platform.",
    },
    "servers": [
        {"url": "http://localhost:8000", "description": "Local backend"},
        {"url": "http://10.0.2.2:8000", "description": "Android emulator"},
    ],
    "paths": {},
    "components": {
        "schemas": {
            "AppError": {
                "type": "object",
                "required": ["error"],
                "properties": {
                    "error": {
                        "type": "object",
                        "required": ["code", "message"],
                        "properties": {
                            "code": {"type": "string"},
                            "message": {"type": "string"},
                            "details": {"type": "object", "nullable": True},
                        },
                    }
                },
            }
        }
    },
}


def main():
    merged = dict(BASE_OPENAPI)
    merged["paths"] = dict(BASE_OPENAPI["paths"])
    merged["components"]["schemas"] = dict(BASE_OPENAPI["components"]["schemas"])

    if not MODULES_DIR.exists():
        print(f"[build_openapi] Modules directory not found: {MODULES_DIR}")
        sys.exit(1)

    yaml_files = sorted(MODULES_DIR.glob("*.yaml"))
    print(f"[build_openapi] Found {len(yaml_files)} contract fragments.")

    for yf in yaml_files:
        with open(yf, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}

        # Merge paths
        paths = data.get("paths", {})
        for path, operations in paths.items():
            if path in merged["paths"]:
                merged["paths"][path].update(operations)
            else:
                merged["paths"][path] = operations

        # Merge schemas
        schemas = data.get("components", {}).get("schemas", {})
        for schema_name, schema_def in schemas.items():
            merged["components"]["schemas"][schema_name] = schema_def

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        yaml.dump(merged, f, sort_keys=False, allow_unicode=True)

    print(f"[build_openapi] Unified contract written to: {OUTPUT_FILE} ({len(merged['paths'])} paths)")


if __name__ == "__main__":
    main()
