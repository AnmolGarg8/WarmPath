#!/usr/bin/env python3
"""
scripts/deploy/create_admin.py - Protected script to create the first platform admin.
No hardcoded sample credentials. Prompts interactively or takes CLI flags.
"""

import argparse
import asyncio
import os
import re
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path


def is_valid_email(email: str) -> bool:
    pattern = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    return bool(re.match(pattern, email))


async def create_platform_admin(email: str, full_name: str, institution_name: str = None):
    try:
        from app.core.db import async_session_maker, User, Institution, OutboxEvent
        from sqlalchemy import select
    except ImportError:
        print("Error: Backend dependencies not found in PYTHONPATH. Run within backend virtual environment.", file=sys.stderr)
        return 1

    async with async_session_maker() as session:
        # Check if user already exists
        stmt = select(User).where(User.email == email)
        user = (await session.execute(stmt)).scalar_one_or_none()

        institution_id = None
        if institution_name:
            inst_stmt = select(Institution).where(Institution.name.ilike(f"%{institution_name}%"))
            inst = (await session.execute(inst_stmt)).scalar_one_or_none()
            if inst:
                institution_id = inst.id

        if user:
            print(f"[ADMIN CREATION] User with email '{email}' already exists (ID: {user.id}).")
            current_roles = list(user.roles or [])
            if "platform_admin" not in current_roles:
                current_roles.extend(["platform_admin", "moderator"])
                user.roles = list(set(current_roles))
                print("[ADMIN CREATION] Elevated existing user to 'platform_admin' and 'moderator'.")
            else:
                print("[ADMIN CREATION] User is already a platform_admin.")
            if institution_id and not user.institution_id:
                user.institution_id = institution_id
        else:
            user = User(
                id=uuid.uuid4(),
                email=email,
                full_name=full_name,
                institution_id=institution_id,
                roles=["student", "platform_admin", "moderator"],
                created_at=datetime.now(timezone.utc),
            )
            session.add(user)
            print(f"[ADMIN CREATION] Created new admin user '{full_name}' <{email}> (ID: {user.id}).")

        # Emit audit event to outbox
        audit_event = OutboxEvent(
            topic="admin.created",
            payload={
                "user_id": str(user.id),
                "email": email,
                "roles": user.roles,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
            status="pending",
            retry_count=0,
            created_at=datetime.now(timezone.utc),
        )
        session.add(audit_event)

        await session.commit()
        print("[ADMIN CREATION] Success: Admin role granted and audit log event recorded.")
        return 0


def main():
    parser = argparse.ArgumentParser(description="Create First Platform Admin for WarmPath")
    parser.add_argument("--email", help="Administrator email address")
    parser.add_argument("--name", help="Administrator full name")
    parser.add_argument("--institution", help="Associated institution name (optional)")
    args = parser.parse_args()

    email = args.email
    name = args.name
    institution = args.institution

    if not email:
        try:
            email = input("Enter Admin Email: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nCancelled.")
            return 1

    if not is_valid_email(email):
        print(f"Error: '{email}' is not a valid email address.", file=sys.stderr)
        return 1

    if not name:
        try:
            name = input("Enter Admin Full Name: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nCancelled.")
            return 1

    if not name:
        print("Error: Name cannot be empty.", file=sys.stderr)
        return 1

    return asyncio.run(create_platform_admin(email, name, institution))


if __name__ == "__main__":
    sys.exit(main())
