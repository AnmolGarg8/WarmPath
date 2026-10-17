"""credits tables and default plans seed

Revision ID: 0001_credits_init
Revises: 
Create Date: 2026-10-17 20:00:00.000000

"""
import json
from datetime import datetime, timezone
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001_credits_init"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = ("credits",)
depends_on: Union[str, Sequence[str], None] = "0001_core_base"


def upgrade() -> None:
    # 1. Plans table
    plans_table = op.create_table(
        "plans",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("code", sa.String(length=50), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("price_inr", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("credits_per_month", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reach_bands", postgresql.ARRAY(sa.String()), nullable=False),
        sa.Column("booking_horizon_days", sa.Integer(), nullable=False, server_default="3"),
        sa.Column("priority", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("features", postgresql.JSONB(as_json=True), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_plans_code"), "plans", ["code"], unique=True)

    # Seed default plans from config
    now = datetime.now(timezone.utc)
    op.bulk_insert(
        plans_table,
        [
            {
                "code": "campus",
                "name": "Campus Free",
                "price_inr": 0,
                "credits_per_month": 0,
                "reach_bands": [],
                "booking_horizon_days": 3,
                "priority": 0,
                "features": [
                    "Own-college alumni access",
                    "0 paid credits/month",
                    "3-day booking horizon",
                    "Free 1-on-1 sessions",
                ],
                "active": True,
                "created_at": now,
            },
            {
                "code": "standard",
                "name": "Standard Plan",
                "price_inr": 299,
                "credits_per_month": 1,
                "reach_bands": ["Rising"],
                "booking_horizon_days": 3,
                "priority": 1,
                "features": [
                    "1 cross-college credit/month",
                    "Reach Rising alumni",
                    "3-day booking horizon",
                    "Priority 1 in giver inbox",
                ],
                "active": True,
                "created_at": now,
            },
            {
                "code": "high",
                "name": "High Plan",
                "price_inr": 499,
                "credits_per_month": 2,
                "reach_bands": ["Rising", "Trusted"],
                "booking_horizon_days": 14,
                "priority": 2,
                "features": [
                    "2 cross-college credits/month",
                    "Reach Rising and Trusted alumni",
                    "14-day booking horizon",
                    "Priority 2 in giver inbox",
                ],
                "active": True,
                "created_at": now,
            },
            {
                "code": "premium",
                "name": "Premium Plan",
                "price_inr": 899,
                "credits_per_month": 4,
                "reach_bands": ["Rising", "Trusted", "Top Rated"],
                "booking_horizon_days": 30,
                "priority": 3,
                "features": [
                    "4 cross-college credits/month",
                    "Reach all bands, experts, recruiters, founders and faculty",
                    "30-day booking horizon",
                    "Highest priority (3) in giver inbox",
                ],
                "active": True,
                "created_at": now,
            },
        ],
    )

    # 2. Ledger Accounts table
    op.create_table(
        "ledger_accounts",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("owner_user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("kind", sa.String(length=50), nullable=False),
        sa.Column("balance_credits", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("balance_inr", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_ledger_accounts_owner_user_id"), "ledger_accounts", ["owner_user_id"], unique=False)
    op.create_index(op.f("ix_ledger_accounts_kind"), "ledger_accounts", ["kind"], unique=False)

    # 3. Ledger Entries table
    op.create_table(
        "ledger_entries",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("txn_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("account_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("amount_credits", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("amount_inr", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("direction", sa.String(length=10), nullable=False),
        sa.Column("reason", sa.String(length=100), nullable=False),
        sa.Column("ref_type", sa.String(length=50), nullable=False),
        sa.Column("ref_id", sa.String(length=100), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["account_id"], ["ledger_accounts.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_ledger_entries_txn_id"), "ledger_entries", ["txn_id"], unique=False)
    op.create_index(op.f("ix_ledger_entries_account_id"), "ledger_entries", ["account_id"], unique=False)
    op.create_index(op.f("ix_ledger_entries_ref_type"), "ledger_entries", ["ref_type"], unique=False)
    op.create_index(op.f("ix_ledger_entries_ref_id"), "ledger_entries", ["ref_id"], unique=False)

    # 4. Credit Lots table
    op.create_table(
        "credit_lots",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("account_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("credits_remaining", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("unit_price_inr", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["account_id"], ["ledger_accounts.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_credit_lots_account_id"), "credit_lots", ["account_id"], unique=False)

    # 5. Session Settlements table
    op.create_table(
        "session_settlements",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("session_id", sa.String(length=100), nullable=False),
        sa.Column("request_id", sa.String(length=100), nullable=True),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("giver_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("is_cross_college", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("unit_price_inr", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="pending_window"),
        sa.Column("settles_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("settled_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_session_settlements_session_id"), "session_settlements", ["session_id"], unique=True)
    op.create_index(op.f("ix_session_settlements_request_id"), "session_settlements", ["request_id"], unique=False)
    op.create_index(op.f("ix_session_settlements_status"), "session_settlements", ["status"], unique=False)

    # 6. User Subscriptions table
    op.create_table(
        "user_subscriptions",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("plan_code", sa.String(length=50), nullable=False, server_default="campus"),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="active"),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("renews_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_user_subscriptions_user_id"), "user_subscriptions", ["user_id"], unique=False)

    # 7. Sponsored Seats table
    op.create_table(
        "sponsored_seats",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("institution_id", sa.Integer(), nullable=True),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("plan_tier", sa.String(length=50), nullable=False),
        sa.Column("sponsor_name", sa.String(length=255), nullable=True),
        sa.Column("funded_by", sa.String(length=50), nullable=False, server_default="scholarship_pool"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_sponsored_seats_student_id"), "sponsored_seats", ["student_id"], unique=False)
    op.create_index(op.f("ix_sponsored_seats_institution_id"), "sponsored_seats", ["institution_id"], unique=False)

    # 8. Payout Requests table
    op.create_table(
        "payout_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("amount_inr", sa.Float(), nullable=False),
        sa.Column("upi_id", sa.String(length=255), nullable=False),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_payout_requests_user_id"), "payout_requests", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_payout_requests_user_id"), table_name="payout_requests")
    op.drop_table("payout_requests")
    op.drop_index(op.f("ix_sponsored_seats_institution_id"), table_name="sponsored_seats")
    op.drop_index(op.f("ix_sponsored_seats_student_id"), table_name="sponsored_seats")
    op.drop_table("sponsored_seats")
    op.drop_index(op.f("ix_user_subscriptions_user_id"), table_name="user_subscriptions")
    op.drop_table("user_subscriptions")
    op.drop_index(op.f("ix_session_settlements_status"), table_name="session_settlements")
    op.drop_index(op.f("ix_session_settlements_request_id"), table_name="session_settlements")
    op.drop_index(op.f("ix_session_settlements_session_id"), table_name="session_settlements")
    op.drop_table("session_settlements")
    op.drop_index(op.f("ix_credit_lots_account_id"), table_name="credit_lots")
    op.drop_table("credit_lots")
    op.drop_index(op.f("ix_ledger_entries_ref_id"), table_name="ledger_entries")
    op.drop_index(op.f("ix_ledger_entries_ref_type"), table_name="ledger_entries")
    op.drop_index(op.f("ix_ledger_entries_account_id"), table_name="ledger_entries")
    op.drop_index(op.f("ix_ledger_entries_txn_id"), table_name="ledger_entries")
    op.drop_table("ledger_entries")
    op.drop_index(op.f("ix_ledger_accounts_kind"), table_name="ledger_accounts")
    op.drop_index(op.f("ix_ledger_accounts_owner_user_id"), table_name="ledger_accounts")
    op.drop_table("ledger_accounts")
    op.drop_index(op.f("ix_plans_code"), table_name="plans")
    op.drop_table("plans")
