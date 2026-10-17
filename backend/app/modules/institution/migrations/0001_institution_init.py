"""institution reporting tables and read models

Revision ID: 0001_institution_init
Revises: 
Create Date: 2026-10-17 22:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0001_institution_init"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = ("institution",)
depends_on: Union[str, Sequence[str], None] = "0001_core_base"


def upgrade() -> None:
    # 1. Event Log
    op.create_table(
        "institution_event_logs",
        sa.Column("event_id", sa.String(length=100), primary_key=True, nullable=False),
        sa.Column("topic", sa.String(length=100), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 2. User Read Model
    op.create_table(
        "institution_user_read_model",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("institution_id", sa.Integer(), nullable=False),
        sa.Column("role", sa.String(length=50), nullable=False, server_default="student"),
        sa.Column("skills", postgresql.JSONB(as_json=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f("ix_institution_user_read_model_institution_id"), "institution_user_read_model", ["institution_id"], unique=False)

    # 3. Request Records
    op.create_table(
        "institution_request_records",
        sa.Column("request_id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("giver_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_institution_id", sa.Integer(), nullable=False),
        sa.Column("giver_institution_id", sa.Integer(), nullable=False),
        sa.Column("is_cross_college", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="posted"),
        sa.Column("first_response_seconds", sa.Float(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(op.f("ix_institution_request_records_student_institution_id"), "institution_request_records", ["student_institution_id"], unique=False)
    op.create_index(op.f("ix_institution_request_records_giver_institution_id"), "institution_request_records", ["giver_institution_id"], unique=False)
    op.create_index(op.f("ix_institution_request_records_created_at"), "institution_request_records", ["created_at"], unique=False)

    # 4. Session Records
    op.create_table(
        "institution_session_records",
        sa.Column("session_id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("request_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("giver_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_institution_id", sa.Integer(), nullable=False),
        sa.Column("giver_institution_id", sa.Integer(), nullable=False),
        sa.Column("is_cross_college", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="booked"),
        sa.Column("duration_minutes", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("rating", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(op.f("ix_institution_session_records_student_institution_id"), "institution_session_records", ["student_institution_id"], unique=False)
    op.create_index(op.f("ix_institution_session_records_giver_institution_id"), "institution_session_records", ["giver_institution_id"], unique=False)
    op.create_index(op.f("ix_institution_session_records_created_at"), "institution_session_records", ["created_at"], unique=False)

    # 5. Skill Gap Records
    op.create_table(
        "institution_skill_gap_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("institution_id", sa.Integer(), nullable=False),
        sa.Column("skill_name", sa.String(length=100), nullable=False),
        sa.Column("category", sa.String(length=50), nullable=False, server_default="skill"),
        sa.Column("demand_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("supply_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f("ix_institution_skill_gap_records_institution_id"), "institution_skill_gap_records", ["institution_id"], unique=False)
    op.create_index(op.f("ix_institution_skill_gap_records_skill_name"), "institution_skill_gap_records", ["skill_name"], unique=False)

    # 6. Safety Records
    op.create_table(
        "institution_safety_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("institution_id", sa.Integer(), nullable=False),
        sa.Column("incident_type", sa.String(length=50), nullable=False),
        sa.Column("reference_id", sa.String(length=100), nullable=False),
        sa.Column("status", sa.String(length=50), nullable=False, server_default="opened"),
        sa.Column("opened_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("resolution_time_hours", sa.Float(), nullable=True),
    )
    op.create_index(op.f("ix_institution_safety_records_institution_id"), "institution_safety_records", ["institution_id"], unique=False)
    op.create_index(op.f("ix_institution_safety_records_reference_id"), "institution_safety_records", ["reference_id"], unique=False)

    # 7. Seats Records
    op.create_table(
        "institution_seats_records",
        sa.Column("institution_id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column("sponsored_seats_granted", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_budget_inr", sa.Float(), nullable=False, server_default="50000.0"),
        sa.Column("remaining_budget_inr", sa.Float(), nullable=False, server_default="50000.0"),
        sa.Column("scholarship_pool_balance", sa.Float(), nullable=False, server_default="15000.0"),
        sa.Column("donations_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("donations_amount_inr", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    # 8. Access Reach Records
    op.create_table(
        "institution_access_reach_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("student_institution_id", sa.Integer(), nullable=False),
        sa.Column("giver_institution_id", sa.Integer(), nullable=False),
        sa.Column("session_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("student_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("giver_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_activity_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f("ix_institution_access_reach_records_student_institution_id"), "institution_access_reach_records", ["student_institution_id"], unique=False)
    op.create_index(op.f("ix_institution_access_reach_records_giver_institution_id"), "institution_access_reach_records", ["giver_institution_id"], unique=False)

    # 9. Seat Grants Record
    op.create_table(
        "institution_seat_grants",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("institution_id", sa.Integer(), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("student_email_masked", sa.String(length=255), nullable=False),
        sa.Column("plan_code", sa.String(length=50), nullable=False, server_default="standard"),
        sa.Column("funding_source", sa.String(length=100), nullable=False, server_default="Institution Budget"),
        sa.Column("granted_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(op.f("ix_institution_seat_grants_institution_id"), "institution_seat_grants", ["institution_id"], unique=False)


def downgrade() -> None:
    op.drop_table("institution_seat_grants")
    op.drop_table("institution_access_reach_records")
    op.drop_table("institution_seats_records")
    op.drop_table("institution_safety_records")
    op.drop_table("institution_skill_gap_records")
    op.drop_table("institution_session_records")
    op.drop_table("institution_request_records")
    op.drop_table("institution_user_read_model")
    op.drop_table("institution_event_logs")
