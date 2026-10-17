"""payments tables for subscriptions, webhooks, and test-mode payouts

Revision ID: 0001_payments_init
Revises: 
Create Date: 2026-10-17 22:00:00.000000

"""
from datetime import datetime, timezone
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001_payments_init"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = ("payments",)
depends_on: Union[str, Sequence[str], None] = "0001_core_base"


def upgrade() -> None:
    # 1. Subscriptions table
    op.create_table(
        "subscriptions",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("plan_code", sa.String(length=50), nullable=False),
        sa.Column("razorpay_subscription_id", sa.String(length=100), nullable=False),
        sa.Column("razorpay_plan_id", sa.String(length=100), nullable=True),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="created"),
        sa.Column("current_period_start", sa.DateTime(timezone=True), nullable=True),
        sa.Column("current_period_end", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_subscriptions_user_id"), "subscriptions", ["user_id"], unique=False)
    op.create_index(op.f("ix_subscriptions_razorpay_subscription_id"), "subscriptions", ["razorpay_subscription_id"], unique=True)

    # 2. Payment Events table (Webhook Idempotency)
    op.create_table(
        "payment_events",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("event_id", sa.String(length=100), nullable=False),
        sa.Column("event_type", sa.String(length=100), nullable=False),
        sa.Column("payload", postgresql.JSONB(as_json=True), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_payment_events_event_id"), "payment_events", ["event_id"], unique=True)
    op.create_index(op.f("ix_payment_events_event_type"), "payment_events", ["event_type"], unique=False)

    # 3. Payout Requests table
    op.create_table(
        "payments_payout_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("amount_inr", sa.Float(), nullable=False),
        sa.Column("upi_id", sa.String(length=255), nullable=True),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="requested"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_payments_payout_requests_user_id"), "payments_payout_requests", ["user_id"], unique=False)

    # 4. Giver Earnings Read Model
    op.create_table(
        "giver_earnings_read_model",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("available_earnings_inr", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("user_id"),
    )

    # 5. Razorpay Plan Mappings table
    op.create_table(
        "razorpay_plan_mappings",
        sa.Column("plan_code", sa.String(length=50), nullable=False),
        sa.Column("razorpay_plan_id", sa.String(length=100), nullable=False),
        sa.Column("price_inr", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("plan_code"),
    )


def downgrade() -> None:
    op.drop_table("razorpay_plan_mappings")
    op.drop_table("giver_earnings_read_model")
    op.drop_index(op.f("ix_payments_payout_requests_user_id"), table_name="payments_payout_requests")
    op.drop_table("payments_payout_requests")
    op.drop_index(op.f("ix_payment_events_event_type"), table_name="payment_events")
    op.drop_index(op.f("ix_payment_events_event_id"), table_name="payment_events")
    op.drop_table("payment_events")
    op.drop_index(op.f("ix_subscriptions_razorpay_subscription_id"), table_name="subscriptions")
    op.drop_index(op.f("ix_subscriptions_user_id"), table_name="subscriptions")
    op.drop_table("subscriptions")
