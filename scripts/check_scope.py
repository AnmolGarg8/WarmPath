#!/usr/bin/env python3
"""
Pre-commit hook and CI check: enforces zero-collision folder ownership.
Fails if any staged or checked file is outside the developer's assigned role paths,
unless ALLOW_SHARED=1 is explicitly exported.
"""

import os
import sys
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
OWNERSHIP_FILE = REPO_ROOT / "scripts" / "ownership.yml"


def load_ownership():
    # Robust parser for simple YAML without requiring external PyYAML
    roles = {}
    current_role = None
    if not OWNERSHIP_FILE.exists():
        print(f"[check_scope] Ownership file not found: {OWNERSHIP_FILE}")
        sys.exit(1)

    with open(OWNERSHIP_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line_str = line.strip()
            if not line_str or line_str.startswith("#"):
                continue
            if line_str == "roles:":
                continue
            if line.startswith("  ") and line_str.endswith(":"):
                current_role = line_str[:-1].strip().lower()
                roles[current_role] = []
            elif line_str.startswith("- ") and current_role:
                path_prefix = line_str[2:].strip()
                roles[current_role].append(path_prefix)
    return roles


def get_git_config_role():
    try:
        res = subprocess.run(
            ["git", "config", "warmpath.member"],
            capture_output=True,
            text=True,
            check=False,
        )
        role = res.stdout.strip().lower()
        return role if role else None
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
        print(f"[check_scope] Error retrieving staged files: {e}")
        sys.exit(1)


def is_path_allowed(file_path, allowed_prefixes):
    norm_file = file_path.replace("\\", "/")
    for prefix in allowed_prefixes:
        norm_prefix = prefix.replace("\\", "/")
        if norm_file == norm_prefix:
            return True
        if norm_prefix.endswith("/") and norm_file.startswith(norm_prefix):
            return True
        if norm_file.startswith(norm_prefix.rstrip("/") + "/"):
            return True
    return False


def main():
    if os.getenv("ALLOW_SHARED") == "1":
        print("[check_scope] ALLOW_SHARED=1 override detected. Skipping scope guard.")
        sys.exit(0)

    # Optional role override via argument (useful for CI)
    target_role = None
    files_to_check = []

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--role" and i + 1 < len(args):
            target_role = args[i + 1].lower()
            i += 2
        elif args[i] == "--files":
            files_to_check = args[i + 1 :]
            break
        else:
            files_to_check.append(args[i])
            i += 1

    if not target_role:
        target_role = get_git_config_role()

    if not target_role:
        print("[check_scope] ERROR: Git config 'warmpath.member' is not set.")
        print("Please configure your role: git config warmpath.member <m1|m2|m3|m4>")
        sys.exit(1)

    ownership = load_ownership()
    if target_role not in ownership:
        print(f"[check_scope] ERROR: Unknown role '{target_role}'. Valid roles: {list(ownership.keys())}")
        sys.exit(1)

    allowed_paths = ownership[target_role]

    if not files_to_check:
        files_to_check = get_staged_files()

    if not files_to_check:
        sys.exit(0)

    violations = []
    for f in files_to_check:
        if not is_path_allowed(f, allowed_paths):
            violations.append(f)

    if violations:
        print(f"\n[check_scope] [X] SCOPE VIOLATION for role '{target_role}'!")
        print("You are modifying files outside your designated ownership area:")
        for v in violations:
            print(f"  - {v}")
        print("\nRules reminder:")
        print(f"  Role '{target_role}' owns:")
        for p in allowed_paths:
            print(f"    * {p}")
        print("\nIf this is an intentional, coordinated cross-cutting fix:")
        print("  Run with override: ALLOW_SHARED=1 git commit ...")
        sys.exit(1)

    print(f"[check_scope] [OK] All {len(files_to_check)} files are within scope for role '{target_role}'.")
    sys.exit(0)


if __name__ == "__main__":
    main()
