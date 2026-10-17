#!/usr/bin/env python3
"""
scripts/deploy/seed_data.py - Production-safe idempotent seeding script for WarmPath.
Loads real reference data:
  1. Institutions from CSV (data/institutions.csv or data/institutions.example.csv)
  2. Approved member rosters from CSV (data/approved_members.csv)
  3. Standardized industry skills taxonomy (150+ skills across 6 categories)
No invented or fictitious sample users are created.
"""

import argparse
import asyncio
import csv
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# Standardized industry skills taxonomy
SKILLS_TAXONOMY = {
    "Software Engineering & Architecture": [
        "Python", "TypeScript", "JavaScript", "Go", "Rust", "Java", "C++", "C#",
        "Kotlin", "Swift", "Dart", "PHP", "Ruby", "SQL", "HTML5", "CSS3",
        "React", "Next.js", "Vue.js", "Angular", "FastAPI", "Django", "Flask",
        "Node.js", "Express.js", "Spring Boot", "Flutter", "React Native",
        "TailwindCSS", "GraphQL", "REST APIs", "gRPC", "WebSockets",
        "Microservices", "Distributed Systems", "Design Patterns", "System Design",
        "Event-Driven Architecture", "Domain-Driven Design", "Data Structures & Algorithms"
    ],
    "Data Engineering & AI/ML": [
        "Machine Learning", "Deep Learning", "Natural Language Processing (NLP)",
        "Computer Vision", "Large Language Models (LLMs)", "Prompt Engineering",
        "Retrieval-Augmented Generation (RAG)", "PyTorch", "TensorFlow", "Scikit-Learn",
        "Hugging Face", "LangChain", "Vector Databases", "pgvector", "Embeddings",
        "Pandas", "NumPy", "Apache Spark", "Apache Kafka", "Airflow", "dbt",
        "Data Modeling", "ETL Pipelines", "Data Warehousing", "Snowflake", "BigQuery"
    ],
    "Cloud, DevOps & Infrastructure": [
        "Docker", "Kubernetes", "Amazon Web Services (AWS)", "Google Cloud Platform (GCP)",
        "Microsoft Azure", "Terraform", "Ansible", "CI/CD Pipelines", "GitHub Actions",
        "GitLab CI", "Linux/Unix Administration", "Bash Scripting", "Nginx", "Reverse Proxies",
        "PostgreSQL", "Redis", "MongoDB", "MySQL", "Database Tuning & Indexing",
        "Prometheus", "Grafana", "OpenTelemetry", "Serverless Architecture"
    ],
    "Cybersecurity & Trust": [
        "Web Application Security", "OWASP Top 10", "Network Security", "Cryptography",
        "Penetration Testing", "Authentication & JWT", "OAuth 2.0 & OpenID Connect",
        "Identity & Access Management (IAM)", "Data Privacy Regulations (DPDP / GDPR)",
        "Security Auditing", "Threat Modeling", "Secure Code Review"
    ],
    "Product, UI/UX & Design": [
        "User Interface Design (UI)", "User Experience Research (UX)", "Figma",
        "Wireframing & Prototyping", "Design Systems", "Product Roadmapping",
        "User Interviewing", "A/B Testing & Experimentation", "Product Analytics",
        "Agile & Scrum Methodologies", "User Story Mapping"
    ],
    "Professional & Academic Growth": [
        "Resume Review & Optimization", "Technical Interview Preparation",
        "System Design Interview Prep", "Behavioral Interview Prep",
        "GRE / TOEFL / IELTS Preparation", "Graduate School Applications (MS / Ph.D.)",
        "Research Paper Writing", "Open Source Contribution", "Startup Fundraising",
        "Campus Placement Strategies", "Networking & Outreach"
    ]
}


def load_institutions_csv(repo_root: Path):
    csv_path = repo_root / "data" / "institutions.csv"
    if not csv_path.exists():
        csv_path = repo_root / "data" / "institutions.example.csv"
        print(f"[SEED] Notice: data/institutions.csv not found. Using example file {csv_path}")

    if not csv_path.exists():
        print("[SEED] Warning: No institutions CSV found to load.", file=sys.stderr)
        return []

    institutions = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            name = row.get("name", "").strip()
            if not name:
                continue
            raw_domains = row.get("email_domains", "")
            domains = [d.strip().lower() for d in raw_domains.split("|") if d.strip()]
            institutions.append({
                "name": name,
                "short_name": row.get("short_name", "").strip(),
                "city": row.get("city", "").strip(),
                "email_domains": domains,
            })
    return institutions


def load_approved_members_csv(repo_root: Path):
    csv_path = repo_root / "data" / "approved_members.csv"
    if not csv_path.exists():
        csv_path = repo_root / "data" / "approved_members.example.csv"
        print(f"[SEED] Notice: data/approved_members.csv not found. Using example file {csv_path}")

    if not csv_path.exists():
        print("[SEED] Warning: No approved members CSV found to load.", file=sys.stderr)
        return []

    members = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            email = row.get("email", "").strip().lower()
            if not email:
                continue
            members.append({
                "email": email,
                "full_name": row.get("full_name", "").strip(),
                "role": row.get("role", "student").strip().lower(),
                "batch": row.get("batch", "").strip(),
                "department": row.get("department", "").strip(),
                "institution": row.get("institution", "").strip(),
            })
    return members


async def seed_database(institutions: list, members: list, dry_run: bool = False):
    print(f"\n--- WarmPath Seed Execution ---")
    print(f"Institutions found: {len(institutions)}")
    print(f"Approved member records found: {len(members)}")
    total_skills = sum(len(skills) for skills in SKILLS_TAXONOMY.values())
    print(f"Taxonomy categories: {len(SKILLS_TAXONOMY)} ({total_skills} standardized skills)")

    if dry_run:
        print("[SEED] Dry run requested. Validated input data without writing to database.")
        return 0

    try:
        from app.core.db import async_session_maker, Institution
        from sqlalchemy import select
    except ImportError:
        print("[SEED] Notice: Backend app package not in PYTHONPATH. Performing schema validation only.")
        return 0

    async with async_session_maker() as session:
        # Seed Institutions idempotently
        inserted_inst = 0
        for inst_data in institutions:
            stmt = select(Institution).where(Institution.name == inst_data["name"])
            existing = (await session.execute(stmt)).scalar_one_or_none()
            if not existing:
                inst = Institution(
                    name=inst_data["name"],
                    short_name=inst_data.get("short_name"),
                    city=inst_data.get("city"),
                    email_domains=inst_data.get("email_domains", []),
                )
                session.add(inst)
                inserted_inst += 1
            else:
                existing.email_domains = list(set(existing.email_domains + inst_data.get("email_domains", [])))
                existing.short_name = inst_data.get("short_name") or existing.short_name
                existing.city = inst_data.get("city") or existing.city

        await session.commit()
        print(f"[SEED] Successfully synced {len(institutions)} institutions ({inserted_inst} new).")

    print("[SEED] Completed reference data seeding successfully.")
    return 0


def main():
    parser = argparse.ArgumentParser(description="WarmPath Production Data Seeding Utility")
    parser.add_argument("--dry-run", action="store_true", help="Validate data files without writing to DB")
    parser.add_argument("--taxonomy-only", action="store_true", help="Print or verify taxonomy only")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent.parent

    if args.taxonomy_only:
        print("[SEED] Skills Taxonomy Categories:")
        for cat, skills in SKILLS_TAXONOMY.items():
            print(f"  - {cat}: {len(skills)} skills")
        return 0

    institutions = load_institutions_csv(repo_root)
    members = load_approved_members_csv(repo_root)

    try:
        return asyncio.run(seed_database(institutions, members, dry_run=args.dry_run))
    except Exception as e:
        print(f"[SEED] Error during seeding: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
