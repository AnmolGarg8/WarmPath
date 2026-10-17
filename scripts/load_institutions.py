#!/usr/bin/env python3
"""
scripts/load_institutions.py - Loads institutions from CSV into the database.
"""

import csv
import os
import sys
from pathlib import Path


def main():
    repo_root = Path(__file__).resolve().parent.parent
    csv_path = repo_root / "data" / "institutions.csv"
    if not csv_path.exists():
        csv_path = repo_root / "data" / "institutions.example.csv"
        print(f"Notice: data/institutions.csv not found. Using example file {csv_path}")

    if not csv_path.exists():
        print("Error: No institutions CSV found to load.", file=sys.stderr)
        return 1

    rows = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row.get("name"):
                continue
            domains = [d.strip() for d in row.get("email_domains", "").split("|") if d.strip()]
            rows.append({
                "name": row["name"].strip(),
                "short_name": row.get("short_name", "").strip(),
                "city": row.get("city", "").strip(),
                "email_domains": domains,
            })

    print(f"Loaded {len(rows)} institution records from CSV.")
    # Database connection logic can be invoked when DB is running
    return 0


if __name__ == "__main__":
    sys.exit(main())
