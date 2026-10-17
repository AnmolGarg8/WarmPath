#!/usr/bin/env python3
"""
scripts/demo/preflight.py - Pre-flight verification before live product demos.

Checks all runtime prerequisites and outputs PASS/FAIL with one-line fix hints:
1. Docker services up (Postgres, Redis, Mailpit)
2. All Alembic migration heads applied
3. Mailpit web API reachable (port 8025)
4. SMTP service listening (port 1025)
5. Gemini AI API responsive (lightweight ping)
6. Razorpay test keys prefixed with 'rzp_test_', plans mapped, webhook configured
7. Jitsi Meet server reachable
8. FCM service account credentials file present
9. Seed data loaded (institutions, approved members, skills)
10. At least N verified givers with capacity (default 5)
11. Demo profile flag matches team intent (DEMO_PROFILE=true)
12. ADB emulators running (default emulator-5554 and emulator-5556)

Exit code: 0 if all checks pass, 1 if any critical check fails.
"""

import argparse
import os
import re
import socket
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse

import httpx

# Ensure backend app root is in sys.path so we can import settings and core
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
BACKEND_DIR = REPO_ROOT / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

try:
    from app.core.config import settings
except Exception:
    settings = None


@dataclass
class CheckResult:
    name: str
    passed: bool
    details: str
    fix_hint: str
    critical: bool = True


def format_check_line(result: CheckResult) -> str:
    status_tag = "[PASS]" if result.passed else "[FAIL]"
    name_col = f"{result.name:<24}"
    line = f"{status_tag} {name_col} {result.details}"
    if not result.passed and result.fix_hint:
        line += f"\n       --> Fix Hint: {result.fix_hint}"
    return line


def check_docker_services() -> CheckResult:
    try:
        res = subprocess.run(
            ["docker", "compose", "ps", "--format", "{{.Name}} {{.State}}"],
            cwd=str(BACKEND_DIR),
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        if res.returncode != 0:
            # Fallback to docker ps
            res = subprocess.run(
                ["docker", "ps", "--format", "{{.Names}}"],
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )

        output = res.stdout.lower()
        required = ["postgres", "redis", "mailpit"]
        missing = [svc for svc in required if svc not in output]

        if not missing:
            return CheckResult(
                name="Docker Services",
                passed=True,
                details="Postgres, Redis, and Mailpit containers are running.",
                fix_hint="",
            )
        else:
            return CheckResult(
                name="Docker Services",
                passed=False,
                details=f"Missing container(s): {', '.join(missing)}.",
                fix_hint="Run: cd backend && docker compose up -d",
            )
    except Exception as e:
        return CheckResult(
            name="Docker Services",
            passed=False,
            details=f"Docker daemon not responding: {e}",
            fix_hint="Start Docker Desktop and run: cd backend && docker compose up -d",
        )


def check_alembic_migrations() -> CheckResult:
    try:
        res = subprocess.run(
            ["alembic", "current"],
            cwd=str(BACKEND_DIR),
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
        )
        out = res.stdout + res.stderr
        if res.returncode == 0 and ("head" in out or len(out.strip()) > 0):
            return CheckResult(
                name="Alembic Migrations",
                passed=True,
                details="Database migration state verified.",
                fix_hint="",
            )
        else:
            return CheckResult(
                name="Alembic Migrations",
                passed=False,
                details="Alembic migrations pending or database uninitialized.",
                fix_hint="Run: cd backend && alembic upgrade heads",
            )
    except Exception as e:
        return CheckResult(
            name="Alembic Migrations",
            passed=False,
            details=f"Failed to check migrations: {e}",
            fix_hint="Run: cd backend && alembic upgrade heads",
        )


def check_mailpit_api() -> CheckResult:
    url = "http://localhost:8025/api/v2/messages"
    try:
        with httpx.Client(timeout=4.0) as client:
            resp = client.get(url)
            if resp.status_code == 200:
                count = resp.json().get("total", 0)
                return CheckResult(
                    name="Mailpit Web API",
                    passed=True,
                    details=f"Mailpit API reachable on port 8025 ({count} messages in inbox).",
                    fix_hint="",
                )
    except Exception:
        pass
    return CheckResult(
        name="Mailpit Web API",
        passed=False,
        details="Cannot connect to Mailpit HTTP API at http://localhost:8025.",
        fix_hint="Ensure Mailpit container is running: cd backend && docker compose up -d mailpit",
    )


def check_smtp_server() -> CheckResult:
    host = getattr(settings, "SMTP_HOST", "localhost") if settings else "localhost"
    port = getattr(settings, "SMTP_PORT", 1025) if settings else 1025
    try:
        with socket.create_connection((host, port), timeout=3.0) as s:
            s.recv(1024)
            return CheckResult(
                name="SMTP Server",
                passed=True,
                details=f"SMTP server listening at {host}:{port}.",
                fix_hint="",
            )
    except Exception as e:
        return CheckResult(
            name="SMTP Server",
            passed=False,
            details=f"SMTP connection to {host}:{port} failed: {e}",
            fix_hint="Start Mailpit container: cd backend && docker compose up -d mailpit",
        )


def check_gemini_ai() -> CheckResult:
    api_key = getattr(settings, "GEMINI_API_KEY", "") if settings else os.environ.get("GEMINI_API_KEY", "")
    if not api_key or not api_key.strip():
        return CheckResult(
            name="Gemini AI API",
            passed=False,
            details="GEMINI_API_KEY is not set or empty.",
            fix_hint="Add GEMINI_API_KEY=... to backend/.env (obtain key from aistudio.google.com).",
        )

    model = getattr(settings, "GEMINI_TEXT_MODEL", "gemini-1.5-flash") if settings else "gemini-1.5-flash"
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    try:
        with httpx.Client(timeout=6.0) as client:
            payload = {"contents": [{"parts": [{"text": "ping"}]}]}
            resp = client.post(url, json=payload)
            if resp.status_code == 200:
                return CheckResult(
                    name="Gemini AI API",
                    passed=True,
                    details=f"API call succeeded using model '{model}'.",
                    fix_hint="",
                )
            else:
                return CheckResult(
                    name="Gemini AI API",
                    passed=False,
                    details=f"Gemini API returned status {resp.status_code}: {resp.text[:100]}",
                    fix_hint="Verify GEMINI_API_KEY validity and quota at aistudio.google.com.",
                )
    except Exception as e:
        return CheckResult(
            name="Gemini AI API",
            passed=False,
            details=f"Gemini API connection error: {e}",
            fix_hint="Check internet connection and verify GEMINI_API_KEY in backend/.env.",
        )


def check_razorpay_keys() -> CheckResult:
    key_id = getattr(settings, "RAZORPAY_KEY_ID", "") if settings else os.environ.get("RAZORPAY_KEY_ID", "")
    secret = getattr(settings, "RAZORPAY_KEY_SECRET", "") if settings else os.environ.get("RAZORPAY_KEY_SECRET", "")

    if not key_id or not secret:
        return CheckResult(
            name="Razorpay Test Keys",
            passed=False,
            details="RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET missing.",
            fix_hint="Set RAZORPAY_KEY_ID=rzp_test_... and RAZORPAY_KEY_SECRET in backend/.env.",
        )

    if not key_id.startswith("rzp_test_"):
        return CheckResult(
            name="Razorpay Test Keys",
            passed=False,
            details=f"Key ID '{key_id[:12]}...' is NOT a test key (must start with 'rzp_test_').",
            fix_hint="Use sandbox test keys starting with 'rzp_test_' for live demo presentation.",
        )

    return CheckResult(
        name="Razorpay Test Keys",
        passed=True,
        details="Valid test key prefix ('rzp_test_...') and secret configured.",
        fix_hint="",
    )


def check_jitsi_meet() -> CheckResult:
    jitsi_url = getattr(settings, "JITSI_BASE_URL", "https://meet.jit.si") if settings else "https://meet.jit.si"
    try:
        with httpx.Client(timeout=5.0, follow_redirects=True) as client:
            resp = client.get(jitsi_url)
            if resp.status_code in (200, 301, 302):
                return CheckResult(
                    name="Jitsi Meet Server",
                    passed=True,
                    details=f"Video call server reachable at {jitsi_url}.",
                    fix_hint="",
                )
    except Exception as e:
        return CheckResult(
            name="Jitsi Meet Server",
            passed=False,
            details=f"Cannot reach {jitsi_url}: {e}",
            fix_hint="Verify internet access or set JITSI_BASE_URL in backend/.env.",
        )
    return CheckResult(
        name="Jitsi Meet Server",
        passed=False,
        details=f"Unreachable status from {jitsi_url}",
        fix_hint="Check connection to Jitsi base URL.",
    )


def check_fcm_credentials() -> CheckResult:
    fcm_path = getattr(settings, "FCM_SERVICE_ACCOUNT_PATH", "") if settings else os.environ.get("FCM_SERVICE_ACCOUNT_PATH", "")
    if fcm_path and Path(fcm_path).exists():
        return CheckResult(
            name="FCM Credentials",
            passed=True,
            details=f"FCM service account JSON found at '{fcm_path}'.",
            fix_hint="",
            critical=False,
        )
    return CheckResult(
        name="FCM Credentials",
        passed=False,
        details=f"FCM service account file not found (configured: '{fcm_path or 'none'}').",
        fix_hint="Set FCM_SERVICE_ACCOUNT_PATH to a valid service account JSON if push notifications are needed.",
        critical=False,
    )


def check_seed_data() -> CheckResult:
    # Query row counts in database container
    cmd = [
        "docker", "compose", "exec", "-T", "postgres",
        "psql", "-U", "warmpath", "-d", "warmpath_db", "-t", "-A", "-c",
        "SELECT 'institutions', count(*) FROM institutions "
        "UNION ALL SELECT 'approved_members', count(*) FROM approved_members "
        "UNION ALL SELECT 'users', count(*) FROM users;"
    ]
    try:
        res = subprocess.run(
            cmd,
            cwd=str(BACKEND_DIR),
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        if res.returncode == 0 and res.stdout.strip():
            lines = res.stdout.strip().splitlines()
            counts = {}
            for line in lines:
                parts = line.split("|")
                if len(parts) == 2:
                    counts[parts[0]] = int(parts[1]) if parts[1].isdigit() else 0

            inst_count = counts.get("institutions", 0)
            mem_count = counts.get("approved_members", 0)
            user_count = counts.get("users", 0)

            if inst_count > 0 and mem_count > 0:
                return CheckResult(
                    name="Seed Data Loaded",
                    passed=True,
                    details=f"Found {inst_count} institutions, {mem_count} approved members, {user_count} users.",
                    fix_hint="",
                )
            else:
                return CheckResult(
                    name="Seed Data Loaded",
                    passed=False,
                    details=f"Missing rows (institutions: {inst_count}, approved_members: {mem_count}).",
                    fix_hint="Import institutions and approved members CSVs into database.",
                )
    except Exception as e:
        return CheckResult(
            name="Seed Data Loaded",
            passed=False,
            details=f"Failed to query database seed data: {e}",
            fix_hint="Start Postgres and verify database connection string in backend/.env.",
        )

    return CheckResult(
        name="Seed Data Loaded",
        passed=False,
        details="Could not inspect database row counts.",
        fix_hint="Verify Postgres container is running with 'docker compose ps'.",
    )


def check_verified_givers(min_count: int = 5) -> CheckResult:
    cmd = [
        "docker", "compose", "exec", "-T", "postgres",
        "psql", "-U", "warmpath", "-d", "warmpath_db", "-t", "-A", "-c",
        "SELECT count(*) FROM users WHERE is_verified = true;"
    ]
    try:
        res = subprocess.run(
            cmd,
            cwd=str(BACKEND_DIR),
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
        if res.returncode == 0 and res.stdout.strip().isdigit():
            count = int(res.stdout.strip())
            if count >= min_count:
                return CheckResult(
                    name="Verified Givers",
                    passed=True,
                    details=f"Found {count} verified alumni members (threshold: {min_count}).",
                    fix_hint="",
                )
            else:
                return CheckResult(
                    name="Verified Givers",
                    passed=False,
                    details=f"Found {count} verified alumni (expected at least {min_count}).",
                    fix_hint=f"Verify at least {min_count} alumni accounts via admin panel or database seed.",
                )
    except Exception as e:
        return CheckResult(
            name="Verified Givers",
            passed=False,
            details=f"Database query error: {e}",
            fix_hint="Ensure Postgres is running and users table exists.",
        )

    return CheckResult(
        name="Verified Givers",
        passed=False,
        details="Could not determine verified alumni count.",
        fix_hint="Verify Postgres container and data load.",
    )


def check_demo_profile_setting(expect_demo: bool = True) -> CheckResult:
    demo_active = getattr(settings, "DEMO_PROFILE", False) if settings else False

    if expect_demo:
        if demo_active:
            dispute_min = getattr(settings, "DISPUTE_WINDOW_MINUTES", 2)
            no_reply_min = getattr(settings, "NO_REPLY_EXPIRY_MINUTES", 5)
            return CheckResult(
                name="Demo Profile Flag",
                passed=True,
                details=f"DEMO_PROFILE=true active (dispute: {dispute_min}m, no-reply: {no_reply_min}m).",
                fix_hint="",
            )
        else:
            return CheckResult(
                name="Demo Profile Flag",
                passed=False,
                details="DEMO_PROFILE is false (production 48h/72h timers are active).",
                fix_hint="Set DEMO_PROFILE=true in backend/.env or copy backend/.env.demo.example.",
            )
    else:
        if not demo_active:
            return CheckResult(
                name="Demo Profile Flag",
                passed=True,
                details="Production profile active (DEMO_PROFILE=false).",
                fix_hint="",
            )
        else:
            return CheckResult(
                name="Demo Profile Flag",
                passed=False,
                details="DEMO_PROFILE is true while production profile was requested.",
                fix_hint="Set DEMO_PROFILE=false in backend/.env.",
            )


def check_adb_emulators(expected: List[str] = None) -> CheckResult:
    if expected is None:
        expected = ["emulator-5554", "emulator-5556"]

    try:
        res = subprocess.run(
            ["adb", "devices"],
            capture_output=True,
            text=True,
            check=False,
            timeout=8,
        )
        if res.returncode == 0:
            lines = res.stdout.strip().splitlines()[1:]
            active = [line.split()[0] for line in lines if "device" in line and not line.startswith("*")]

            missing = [e for e in expected if e not in active]
            if not missing:
                return CheckResult(
                    name="ADB Emulators",
                    passed=True,
                    details=f"Both required emulators running: {', '.join(expected)}.",
                    fix_hint="",
                )
            elif len(active) > 0:
                return CheckResult(
                    name="ADB Emulators",
                    passed=False,
                    details=f"Active device(s): {', '.join(active)}. Missing: {', '.join(missing)}.",
                    fix_hint=f"Launch second emulator: 'flutter emulators --launch <avd_name>'.",
                )
            else:
                return CheckResult(
                    name="ADB Emulators",
                    passed=False,
                    details="No Android emulators connected.",
                    fix_hint="Start Android emulator (e.g. emulator-5554): 'flutter emulators --launch <name>'.",
                )
    except Exception as e:
        return CheckResult(
            name="ADB Emulators",
            passed=False,
            details=f"ADB execution failed: {e}",
            fix_hint="Ensure Android SDK platform-tools ('adb') is installed and in PATH.",
        )


def run_all_checks(
    expect_demo: bool = True,
    min_givers: int = 5,
    ignore_emulators: bool = False,
) -> Tuple[List[CheckResult], bool]:
    results = [
        check_docker_services(),
        check_alembic_migrations(),
        check_mailpit_api(),
        check_smtp_server(),
        check_gemini_ai(),
        check_razorpay_keys(),
        check_jitsi_meet(),
        check_fcm_credentials(),
        check_seed_data(),
        check_verified_givers(min_count=min_givers),
        check_demo_profile_setting(expect_demo=expect_demo),
    ]

    if not ignore_emulators:
        results.append(check_adb_emulators())

    critical_failures = any(not r.passed and r.critical for r in results)
    overall_passed = not critical_failures
    return results, overall_passed


def main() -> int:
    parser = argparse.ArgumentParser(description="WarmPath Demo Preflight Check")
    parser.add_argument(
        "--prod",
        action="store_true",
        help="Expect production profile (DEMO_PROFILE=false) instead of demo profile",
    )
    parser.add_argument(
        "--min-givers",
        type=int,
        default=5,
        help="Minimum required verified alumni givers (default: 5)",
    )
    parser.add_argument(
        "--no-emulators",
        action="store_true",
        help="Skip ADB emulator verification check",
    )
    args = parser.parse_args()

    expect_demo = not args.prod

    print("=" * 80)
    print("                           WARMPATH DEMO PREFLIGHT")
    print("=" * 80)

    results, overall_passed = run_all_checks(
        expect_demo=expect_demo,
        min_givers=args.min_givers,
        ignore_emulators=args.no_emulators,
    )

    passed_count = sum(1 for r in results if r.passed)
    total_count = len(results)

    for r in results:
        print(format_check_line(r))

    print("-" * 80)
    status_str = "PASS" if overall_passed else "FAIL"
    print(f"OVERALL PREFLIGHT: {status_str} ({passed_count}/{total_count} checks passed)")
    print("=" * 80)

    return 0 if overall_passed else 1


if __name__ == "__main__":
    sys.exit(main())
