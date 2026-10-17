"""
scripts/demo/db_safety.py - Safety guard to prevent destructive snapshot operations
against remote, staging, or production databases.
"""

from typing import Tuple
from urllib.parse import urlparse

SAFE_HOSTS = {"localhost", "127.0.0.1", "postgres", "0.0.0.0", "", "none"}
DANGEROUS_DOMAINS = [
    "amazonaws.com",
    "rds.",
    "azure.com",
    "supabase.co",
    "render.com",
    "railway.app",
    "neon.tech",
    "elephantsql.com",
    "cloudsql",
]


def is_safe_local_database(db_url: str) -> Tuple[bool, str]:
    """
    Validate that the database connection string targets a safe, local demo database.
    Refuses execution against remote or production environments.
    """
    if not db_url or not db_url.strip():
        return False, "Refused: Database URL is empty or undefined."

    clean_url = db_url.strip()
    # Normalize postgresql+asyncpg:// to postgresql:// for standard urllib parsing
    if clean_url.startswith("postgresql+asyncpg://"):
        clean_url = "postgresql://" + clean_url[len("postgresql+asyncpg://"):]

    try:
        parsed = urlparse(clean_url)
    except Exception as e:
        return False, f"Invalid database URL format: {e}"

    host = (parsed.hostname or "").lower()
    path = (parsed.path or "").lstrip("/")

    # 1. Host check
    if any(domain in host for domain in DANGEROUS_DOMAINS):
        return False, f"Refused: Host '{host}' matches a known cloud/production database provider."

    if host not in SAFE_HOSTS:
        return False, f"Refused: Host '{host}' is not an authorized local host ({', '.join(sorted(SAFE_HOSTS))})."

    # 2. Database name check
    db_name = path.lower()
    if not db_name:
        return False, "Refused: No database name specified in database URL."

    allowed_keywords = ("warmpath", "test", "demo", "dev")
    if not any(k in db_name for k in allowed_keywords):
        return (
            False,
            f"Refused: Database name '{db_name}' does not contain required local demo keywords: {allowed_keywords}.",
        )

    return True, f"Verified safe local database: host='{host}', db='{db_name}'."
