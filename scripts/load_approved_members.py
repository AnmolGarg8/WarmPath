#!/usr/bin/env python3
"""
Seed script: loads pre-approved institution members from data/approved_members.csv.
No synthetic/dummy data. Run after migrations and after loading institutions.
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
from app.core.models_base import Institution, ApprovedMember


async def load_approved_members(csv_path: Path):
    if not csv_path.exists():
        print(f"[load_approved_members] CSV file not found: {csv_path}")
        print("Please provide a valid CSV file based on data/approved_members.example.csv")
        sys.exit(1)

    print(f"[load_approved_members] Loading members from {csv_path}...")
    loaded = 0

    async with async_session_factory() as session:
        # Load institution lookup map
        inst_res = await session.execute(select(Institution))
        inst_map = {inst.name.lower(): inst.id for inst in inst_res.scalars().all()}
        inst_map.update({inst.short_name.lower(): inst.id for inst in inst_res.scalars().all()})

        with open(csv_path, mode="r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                email = row.get("email", "").strip().lower()
                full_name = row.get("full_name", "").strip()
                role = row.get("role", "student").strip().lower()
                batch = row.get("batch", "").strip()
                dept = row.get("department", "").strip()
                inst_name = row.get("institution", "").strip().lower()

                if not email or not full_name:
                    continue

                inst_id = inst_map.get(inst_name)

                # Check if exists
                stmt = select(ApprovedMember).where(ApprovedMember.email == email)
                res = await session.execute(stmt)
                existing = res.scalar_one_or_none()

                if not existing:
                    member = ApprovedMember(
                        email=email,
                        full_name=full_name,
                        role=role,
                        batch=batch,
                        department=dept,
                        institution_id=inst_id,
                    )
                    session.add(member)
                    loaded += 1

        await session.commit()
    print(f"[load_approved_members] Successfully loaded {loaded} new approved member(s).")


def main():
    csv_file = REPO_ROOT / "data" / "approved_members.csv"
    if len(sys.argv) > 1:
        csv_file = Path(sys.argv[1])
    asyncio.run(load_approved_members(csv_file))


if __name__ == "__main__":
    main()
