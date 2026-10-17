#!/usr/bin/env python3
"""
scripts/check_no_mock.py - Production No-Mock & Anti-Placeholder Guard.

Scans app/lib, admin/src, and backend/app (excluding test folders, docs, and *.example.* files)
and fails CI on:
1. The words mock, dummy, lorem, fake_data, sample_data, sample_user, sample_event, sample_mentor
   in source identifiers or strings.
2. Future.delayed used in non-test app code unless the line carries the comment `// allow-delay: <reason>`.
3. JSON or CSV data files under app/assets or admin/public.
4. Any string in scripts/banned_strings.txt (e.g. Recommended Mentor, John Doe, Jane Doe, React & Node expertise match).

Exceptions:
- An explicit exception on a line requires the comment `allow-mock: <reason>` on that line.
  The reason is logged to stdout so reviewers and CI can verify it.
- An explicit delay exception requires `allow-delay: <reason>` on that line.
"""

import argparse
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


@dataclass
class Violation:
    file_path: Path
    line_number: int
    message: str
    line_text: str


# Regex patterns for banned words in source identifiers or strings
BANNED_WORD_PATTERNS = [
    # Compound tokens (snake_case and camelCase / PascalCase)
    r"\b(fake_data|sample_data|sample_user|sample_event|sample_mentor)\b",
    r"\b(fakeData|sampleData|sampleUser|sampleEvent|sampleMentor)\b",
    # mock, dummy, lorem bounded by non-alphanumeric or string boundaries or underscores
    r"(?:(?<=[^a-zA-Z0-9])|^)(mock|dummy|lorem)(?=[^a-zA-Z0-9]|$)",
    # camelCase / PascalCase variants: e.g. mockUser, getMockData, DummyClass, loremIpsum
    r"(?:(?<=[a-z])|(?<=[0-9]))(Mock|Dummy|Lorem)(?=[A-Z0-9]|$|[^a-zA-Z0-9])",
    r"(?:(?<=[^a-zA-Z0-9])|^)(Mock|Dummy|Lorem)(?=[A-Z])",
    r"(?:(?<=[^a-zA-Z0-9])|^)(mock|dummy|lorem)(?=[A-Z])",
]

COMPILED_BANNED_WORDS = re.compile("|".join(BANNED_WORD_PATTERNS), re.IGNORECASE)
ALLOW_MOCK_RE = re.compile(r"allow-mock:\s*(.+)", re.IGNORECASE)
ALLOW_DELAY_RE = re.compile(r"allow-delay:\s*(.+)", re.IGNORECASE)

EXCLUDED_DIR_NAMES = {"test", "tests", "__tests__", "docs", "node_modules", ".dart_tool", ".git", "__pycache__", "build", "dist"}
EXCLUDED_FILE_SUFFIXES = ("_test.dart", "_test.py", ".test.ts", ".test.tsx", ".test.js", ".test.jsx", ".spec.ts", ".spec.tsx")


def is_test_or_excluded_path(path: Path) -> bool:
    """Check if the path is in an excluded directory, test directory, docs, or is an example file."""
    parts = [p.lower() for p in path.parts]
    if any(p in EXCLUDED_DIR_NAMES for p in parts):
        return True

    name = path.name.lower()
    if ".example." in name or ".sample." in name:
        return True

    if name.endswith(EXCLUDED_FILE_SUFFIXES) or name.startswith("test_"):
        return True

    return False


def load_banned_strings(banned_strings_file: Path) -> List[str]:
    """Load banned strings from scripts/banned_strings.txt."""
    if not banned_strings_file.exists():
        return []

    strings = []
    for line in banned_strings_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            strings.append(line)
    return strings


def scan_file_lines(
    file_path: Path,
    repo_root: Path,
    banned_strings: List[str],
) -> Tuple[List[Violation], List[str]]:
    """Scan a source code file line by line."""
    violations: List[Violation] = []
    allow_logs: List[str] = []
    rel_path = file_path.relative_to(repo_root) if file_path.is_relative_to(repo_root) else file_path

    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        violations.append(
            Violation(
                file_path=rel_path,
                line_number=0,
                message=f"Failed to read file: {e}",
                line_text="",
            )
        )
        return violations, allow_logs

    lines = content.splitlines()
    for idx, line in enumerate(lines, start=1):
        # 1. Check for explicit allow-mock comment
        allow_mock_match = ALLOW_MOCK_RE.search(line)
        if allow_mock_match:
            reason = allow_mock_match.group(1).strip()
            allow_logs.append(f"[ALLOW-MOCK] {rel_path}:{idx}: {reason}")
            # When allow-mock is present, skip all mock/dummy/banned_strings checks for this line
            continue

        # 2. Check Future.delayed
        if "Future.delayed" in line:
            allow_delay_match = ALLOW_DELAY_RE.search(line)
            if allow_delay_match:
                reason = allow_delay_match.group(1).strip()
                allow_logs.append(f"[ALLOW-DELAY] {rel_path}:{idx}: {reason}")
            else:
                violations.append(
                    Violation(
                        file_path=rel_path,
                        line_number=idx,
                        message="Future.delayed used in non-test code without '// allow-delay: <reason>'",
                        line_text=line.strip(),
                    )
                )

        # 3. Check banned strings
        for banned_str in banned_strings:
            if banned_str.lower() in line.lower():
                violations.append(
                    Violation(
                        file_path=rel_path,
                        line_number=idx,
                        message=f"Banned string found: '{banned_str}'",
                        line_text=line.strip(),
                    )
                )

        # 4. Check banned words in identifiers or strings
        word_match = COMPILED_BANNED_WORDS.search(line)
        if word_match:
            matched_term = word_match.group(0)
            violations.append(
                Violation(
                    file_path=rel_path,
                    line_number=idx,
                    message=f"Banned word found: '{matched_term}'",
                    line_text=line.strip(),
                )
            )

    return violations, allow_logs


def scan_data_directories(repo_root: Path) -> List[Violation]:
    """Check for forbidden JSON/CSV data files under app/assets or admin/public."""
    violations: List[Violation] = []
    data_dirs = [repo_root / "app" / "assets", repo_root / "admin" / "public"]

    for d in data_dirs:
        if not d.exists() or not d.is_dir():
            continue
        for root, _, files in os.walk(d):
            root_path = Path(root)
            for f in files:
                f_path = root_path / f
                rel_path = f_path.relative_to(repo_root)
                f_lower = f.lower()

                if is_test_or_excluded_path(f_path):
                    continue

                if f_lower.endswith((".json", ".csv")):
                    violations.append(
                        Violation(
                            file_path=rel_path,
                            line_number=0,
                            message=f"Prohibited data file '{rel_path}' in assets/public folder (mock/sample data not allowed in repo)",
                            line_text="",
                        )
                    )

    return violations


def get_pr_changed_files(repo_root: Path, base_ref: str) -> List[Path]:
    """Get list of changed files in PR against base_ref."""
    try:
        res = subprocess.run(
            ["git", "diff", "--name-only", f"{base_ref}...HEAD"],
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            check=True,
        )
        return [repo_root / Path(line.strip()) for line in res.stdout.splitlines() if line.strip()]
    except Exception as e:
        print(f"[NO-MOCK GUARD] Warning: could not get PR diff against {base_ref}: {e}", file=sys.stderr)
        return []


def run_scanner(
    repo_root: Path,
    banned_strings_path: Optional[Path] = None,
    pr_base: Optional[str] = None,
) -> Tuple[List[Violation], List[str], int]:
    """Run the entire no-mock scan across repo_root, optionally scoped to PR diff."""
    if banned_strings_path is None:
        banned_strings_path = repo_root / "scripts" / "banned_strings.txt"

    banned_strings = load_banned_strings(banned_strings_path)

    all_violations: List[Violation] = []
    all_allow_logs: List[str] = []
    scanned_files_count = 0

    if pr_base:
        changed_files = get_pr_changed_files(repo_root, pr_base)
        print(f"[NO-MOCK GUARD] Checking {len(changed_files)} changed file(s) against base {pr_base}...")
        for f_path in changed_files:
            if not f_path.exists() or f_path.is_dir():
                continue

            rel_str = f_path.relative_to(repo_root).as_posix()
            # Check if file belongs to scanned source or asset domains
            in_source_scope = any(rel_str.startswith(prefix) for prefix in ("app/lib/", "admin/src/", "backend/app/"))
            in_data_scope = any(rel_str.startswith(prefix) for prefix in ("app/assets/", "admin/public/"))

            if in_data_scope:
                if not is_test_or_excluded_path(f_path) and f_path.suffix.lower() in (".json", ".csv"):
                    all_violations.append(
                        Violation(
                            file_path=f_path.relative_to(repo_root),
                            line_number=0,
                            message=f"Prohibited data file '{rel_str}' in assets/public folder",
                            line_text="",
                        )
                    )
            elif in_source_scope:
                if is_test_or_excluded_path(f_path):
                    continue
                if f_path.name.lower().endswith((".png", ".jpg", ".jpeg", ".ico", ".svg", ".lock", ".pyc")):
                    continue

                scanned_files_count += 1
                v_list, a_list = scan_file_lines(f_path, repo_root, banned_strings)
                all_violations.extend(v_list)
                all_allow_logs.extend(a_list)

        return all_violations, all_allow_logs, scanned_files_count

    # Full repository scan
    scan_targets = [
        repo_root / "app" / "lib",
        repo_root / "admin" / "src",
        repo_root / "backend" / "app",
    ]

    for target in scan_targets:
        if not target.exists() or not target.is_dir():
            continue
        for root, _, files in os.walk(target):
            root_path = Path(root)
            for f in files:
                f_path = root_path / f
                if is_test_or_excluded_path(f_path):
                    continue

                if f.lower().endswith((".png", ".jpg", ".jpeg", ".ico", ".svg", ".lock", ".pyc")):
                    continue

                scanned_files_count += 1
                v_list, a_list = scan_file_lines(f_path, repo_root, banned_strings)
                all_violations.extend(v_list)
                all_allow_logs.extend(a_list)

    data_violations = scan_data_directories(repo_root)
    all_violations.extend(data_violations)

    return all_violations, all_allow_logs, scanned_files_count


def main() -> int:
    parser = argparse.ArgumentParser(description="WarmPath No-Mock Guard")
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Repository root path",
    )
    parser.add_argument(
        "--banned-strings",
        type=Path,
        default=None,
        help="Path to banned_strings.txt",
    )
    parser.add_argument(
        "--ci",
        action="store_true",
        help="Run in CI mode (checks PR diff if --pr-base is specified)",
    )
    parser.add_argument(
        "--pr-base",
        default=None,
        help="Base git reference to compare PR against (e.g. origin/main)",
    )
    args = parser.parse_args()

    repo_root = args.root.resolve()
    banned_strings_file = args.banned_strings.resolve() if args.banned_strings else None
    pr_base = args.pr_base if (args.ci and args.pr_base) else args.pr_base

    print(f"[NO-MOCK GUARD] Starting scan at: {repo_root}")
    violations, allow_logs, scanned_count = run_scanner(repo_root, banned_strings_file, pr_base=pr_base)

    if allow_logs:
        print(f"\n[NO-MOCK GUARD] Audited {len(allow_logs)} explicit allow exception(s):")
        for log in allow_logs:
            print(f"  {log}")

    if violations:
        print(f"\n[NO-MOCK GUARD] ERROR: Found {len(violations)} violation(s):", file=sys.stderr)
        for v in violations:
            loc = f"{v.file_path}:{v.line_number}" if v.line_number > 0 else str(v.file_path)
            print(f"  - {loc}: {v.message}", file=sys.stderr)
            if v.line_text:
                print(f"      > {v.line_text}", file=sys.stderr)
        print("\nAll application screens and logic must use real backend APIs and types.", file=sys.stderr)
        print("To allow a legitimate temporary exception, add `// allow-mock: <reason>` or `// allow-delay: <reason>`.", file=sys.stderr)
        return 1

    print(f"\n[NO-MOCK GUARD] OK: Scanned {scanned_count} files across source directories.")
    print("[NO-MOCK GUARD] No prohibited mock words, placeholder strings, delays, or data files found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
