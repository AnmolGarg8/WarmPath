#!/usr/bin/env python3
"""
Seed script: loads real institutions from data/institutions.csv into the database.
No synthetic/dummy data. Run after migrations.
"""

import sys
import csv
import asyncio
from pathlib import Path

# Add backend directory to path
REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "backend"))

from sqlalchemy import select
from app.core.db import async_session_factory
from app.core.models_base import Institution


async def load_institutions(csv_path: Path):
    if not csv_path.exists():
        print(f"[load_institutions] CSV file not found: {csv_path}")
        print("Please provide a valid CSV file based on data/institutions.example.csv")
        sys.exit(1)

    print(f"[load_institutions] Loading institutions from {csv_path}...")
    loaded = 0

    async with async_session_factory() as session:
        with open(csv_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                name = row.get("name", "").strip()
                short_name = row.get("short_name", "").strip()
                city = row.get("city", "").strip()
                domains_raw = row.get("email_domains", "").strip()
                domains = [d.strip() for d in domains_raw.split("|") if d.strip()]

                if not name:
                    continue

                # Check if already exists
                stmt = select(Institution).where(Institution.name == name)
                res = await session.execute(stmt)
                existing = res.scalar_one_or_none()

                if not existing:
                    inst = Institution(
                        name=name,
                        short_name=short_name or name[:10],
                        city=city,
                        email_domains=domains,
                    )
                    session.add(inst)
                    loaded += 1

        await session.commit()
    print(f"[load_institutions] Successfully loaded {loaded} new institution(s).")


def main():
    csv_file = REPO_ROOT / "data" / "institutions.csv"
    if len(sys.argv) > 1:
        csv_file = Path(sys.argv[1])
    asyncio.run(load_institutions(csv_file))


if __name__ == "__main__":
    main()
