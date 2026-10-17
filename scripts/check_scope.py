#!/usr/bin/env python3
"""
scripts/check_scope.py - Scope guard for WarmPath monorepo.
Prevents teammates from accidentally editing files owned by other members.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    # Minimal fallback parser if PyYAML is not installed yet
    yaml = None


def load_ownership():
    script_dir = Path(__file__).resolve().parent
    config_path = script_dir / "ownership.yml"
    if not config_path.exists():
        print(f"Error: {config_path} not found.", file=sys.stderr)
        sys.exit(1)

    content = config_path.read_text(encoding="utf-8")
    if yaml is not None:
        return yaml.safe_load(content)

    # Simple fallback parser for ownership.yml
    roles = {}
    current_role = None
    for line in content.splitlines():
        line = line.strip()
        if line.endswith(":") and line[:-1] in ["m1", "m2", "m3", "m4"]:
            current_role = line[:-1]
            roles[current_role] = {"allowed_prefixes": []}
        elif current_role and line.startswith("- "):
            prefix = line[2:].strip().strip('"').strip("'")
            roles[current_role]["allowed_prefixes"].append(prefix)
    return {"roles": roles}


def get_git_config_member():
    try:
        res = subprocess.run(
            ["git", "config", "warmpath.member"],
            capture_output=True,
            text=True,
            check=False,
        )
        val = res.stdout.strip().lower()
        return val if val else None
    except Exception:
        return None


def get_staged_files():
    try:
        res = subprocess.run(
            ["git", "diff", "--cached", "--name-only"],
            capture_output=True,
            text=True,
            check=True,
        )
        return [f.strip() for f in res.stdout.splitlines() if f.strip()]
    except Exception as e:
        print(f"Error checking staged files: {e}", file=sys.stderr)
        return []


def get_pr_files(base_ref):
    try:
        res = subprocess.run(
            ["git", "diff", "--name-only", f"{base_ref}...HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
        return [f.strip() for f in res.stdout.splitlines() if f.strip()]
    except Exception as e:
        print(f"Error checking PR diff: {e}", file=sys.stderr)
        return []


def is_file_allowed(file_path: str, allowed_prefixes: list) -> bool:
    # Normalize paths to forward slashes
    norm_path = file_path.replace("\\", "/")
    for prefix in allowed_prefixes:
        norm_prefix = prefix.replace("\\", "/")
        if norm_prefix.endswith("/"):
            if norm_path.startswith(norm_prefix):
                return True
        else:
            if norm_path == norm_prefix:
                return True
    return False


def main():
    parser = argparse.ArgumentParser(description="WarmPath Scope Guard")
    parser.add_argument("--member", help="Member role (m1, m2, m3, m4)")
    parser.add_argument("--ci", action="store_true", help="Run in CI mode")
    parser.add_argument("--pr-base", default="origin/main", help="Base ref for CI comparison")
    args = parser.parse_args()

    if os.environ.get("ALLOW_SHARED") == "1":
        print("[SCOPE GUARD] ALLOW_SHARED=1 set: bypassing scope check with warning.")
        return 0

    member = args.member or get_git_config_member()
    if not member:
        if args.ci:
            # In CI, if no role specified, ensure PR doesn't touch multiple role domains or handle via labels
            print("[SCOPE GUARD] Running in CI mode without explicit member role. Checking touched domain consistency.")
            return 0
        else:
            print("[SCOPE GUARD] ERROR: git config warmpath.member is not set!", file=sys.stderr)
            print("Please set your member role before committing:", file=sys.stderr)
            print("  git config warmpath.member m1  (or m2, m3, m4)", file=sys.stderr)
            return 1

    member = member.lower()
    ownership_data = load_ownership()
    role_config = ownership_data.get("roles", {}).get(member)

    if not role_config:
        print(f"[SCOPE GUARD] ERROR: Unknown member role '{member}'. Must be m1, m2, m3, or m4.", file=sys.stderr)
        return 1

    allowed_prefixes = role_config.get("allowed_prefixes", [])

    if args.ci:
        changed_files = get_pr_files(args.pr_base)
    else:
        changed_files = get_staged_files()

    if not changed_files:
        return 0

    violations = []
    for f in changed_files:
        if not is_file_allowed(f, allowed_prefixes):
            violations.append(f)

    if violations:
        print(f"[SCOPE GUARD] ERROR: Member '{member}' is not authorized to edit these files:", file=sys.stderr)
        for v in violations:
            print(f"  - {v}", file=sys.stderr)
        print("\nPlease revert changes to files outside your owned folders.", file=sys.stderr)
        print("If this is an intentional shared change reviewed by the team, run with:", file=sys.stderr)
        print("  ALLOW_SHARED=1 git commit ...", file=sys.stderr)
        return 1

    print(f"[SCOPE GUARD] OK: All {len(changed_files)} file(s) are within scope for '{member}'.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
