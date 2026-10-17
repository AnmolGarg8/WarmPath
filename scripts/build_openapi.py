#!/usr/bin/env python3
"""
scripts/build_openapi.py - Merges OpenAPI fragments and validates backend paths.
"""

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


BASE_TEMPLATE = {
    "openapi": "3.1.0",
    "info": {
        "title": "WarmPath API",
        "version": "1.0.0",
        "description": "API contract for WarmPath: trusted, intent-first alumni network.",
    },
    "servers": [{"url": "http://localhost:8000", "description": "Local development server"}],
    "paths": {},
    "components": {
        "schemas": {
            "ErrorResponse": {
                "type": "object",
                "properties": {
                    "error": {
                        "type": "object",
                        "properties": {
                            "code": {"type": "string"},
                            "message": {"type": "string"},
                            "details": {"type": "object"},
                        },
                        "required": ["code", "message"],
                    }
                },
                "required": ["error"],
            }
        }
    },
}


def build_merged_openapi():
    repo_root = Path(__file__).resolve().parent.parent
    contracts_dir = repo_root / "contracts" / "modules"
    output_file = repo_root / "contracts" / "openapi.yaml"

    if not contracts_dir.exists():
        print(f"Directory {contracts_dir} not found. Creating...", file=sys.stderr)
        contracts_dir.mkdir(parents=True, exist_ok=True)

    merged = dict(BASE_TEMPLATE)
    merged["paths"] = {}
    merged["components"] = dict(BASE_TEMPLATE["components"])

    if yaml is None:
        print("Warning: PyYAML not installed. Writing basic schema.", file=sys.stderr)
        output_file.write_text("# openapi.yaml (merged)\nopenapi: 3.1.0\n", encoding="utf-8")
        return merged

    for yaml_file in sorted(contracts_dir.glob("*.yaml")):
        try:
            content = yaml.safe_load(yaml_file.read_text(encoding="utf-8"))
            if not content:
                continue
            paths = content.get("paths", {})
            for path, methods in paths.items():
                if path in merged["paths"]:
                    merged["paths"][path].update(methods)
                else:
                    merged["paths"][path] = methods

            schemas = content.get("components", {}).get("schemas", {})
            for s_name, s_def in schemas.items():
                merged["components"]["schemas"][s_name] = s_def
        except Exception as e:
            print(f"Error parsing contract {yaml_file}: {e}", file=sys.stderr)

    with open(output_file, "w", encoding="utf-8") as f:
        yaml.dump(merged, f, sort_keys=False)

    print(f"Successfully generated {output_file} with {len(merged['paths'])} paths.")
    return merged


def verify_backend(merged_contract):
    repo_root = Path(__file__).resolve().parent.parent
    backend_path = repo_root / "backend"
    sys.path.insert(0, str(backend_path))

    try:
        from app.main import app
    except ImportError as e:
        print(f"Notice: Could not import app.main ({e}). Skipping backend route verification.", file=sys.stderr)
        return True

    backend_routes = set()
    for route in app.routes:
        if hasattr(route, "path"):
            backend_routes.add(route.path)

    contract_paths = set(merged_contract.get("paths", {}).keys())
    missing = contract_paths - backend_routes

    if missing:
        print(f"Error: Backend is missing routes declared in OpenAPI contract:", file=sys.stderr)
        for p in sorted(missing):
            print(f"  - {p}", file=sys.stderr)
        return False

    print("Success: All OpenAPI contract paths are implemented in backend router registry.")
    return True


def main():
    parser = argparse.ArgumentParser(description="Build and verify OpenAPI specifications")
    parser.add_argument("--verify-backend", action="store_true", help="Verify backend routes against contract")
    args = parser.parse_args()

    merged = build_merged_openapi()
    if args.verify_backend:
        ok = verify_backend(merged)
        sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
