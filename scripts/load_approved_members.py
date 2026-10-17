#!/usr/bin/env python3
"""
scripts/load_approved_members.py - Loads pre-approved member records from CSV.
"""

import csv
import os
import sys
from pathlib import Path


def main():
    repo_root = Path(__file__).resolve().parent.parent
    csv_path = repo_root / "data" / "approved_members.csv"
    if not csv_path.exists():
        csv_path = repo_root / "data" / "approved_members.example.csv"
        print(f"Notice: data/approved_members.csv not found. Using example file {csv_path}")

    if not csv_path.exists():
        print("Error: No approved members CSV found to load.", file=sys.stderr)
        return 1

    rows = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if not row.get("email"):
                continue
            rows.append({
                "email": row["email"].strip().lower(),
                "full_name": row.get("full_name", "").strip(),
                "role": row.get("role", "student").strip(),
                "batch": row.get("batch", "").strip(),
                "department": row.get("department", "").strip(),
                "institution": row.get("institution", "").strip(),
            })

    print(f"Loaded {len(rows)} approved member records from CSV.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
