"""create ratings, disputes, and band profiles

Revision ID: 0001_ratings_init
Revises: 0001_core_base
Create Date: 2026-10-17 19:25:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0001_ratings_init'
down_revision: Union[str, None] = '0001_core_base'
branch_labels: Union[str, Sequence[str], None] = ('ratings',)
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.create_table(
        'session_ratings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), unique=True, nullable=False),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('giver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('stars', sa.Integer(), nullable=False),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('tags', postgresql.JSONB(as_json=True), server_default='[]', nullable=False),
        sa.Column('weight', sa.Float(), server_default='1.0', nullable=False),
        sa.Column('is_suspicious', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('suspicion_flags', postgresql.JSONB(as_json=True), server_default='[]', nullable=False),
        sa.Column('safety_approved', sa.Boolean(), server_default='true', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(op.f('ix_session_ratings_giver_id'), 'session_ratings', ['giver_id'], unique=False)
    op.create_index(op.f('ix_session_ratings_student_id'), 'session_ratings', ['student_id'], unique=False)

    op.create_table(
        'request_quality_ratings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), unique=True, nullable=False),
        sa.Column('giver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('stars', sa.Integer(), nullable=False),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        'giver_band_profiles',
        sa.Column('giver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('current_band', sa.String(length=20), server_default='Rising', nullable=False),
        sa.Column('smoothed_average', sa.Float(), server_default='4.0', nullable=False),
        sa.Column('rated_sessions_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('completed_sessions_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('total_booked_sessions_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('giver_no_show_count', sa.Integer(), server_default='0', nullable=False),
        sa.Column('completion_rate', sa.Float(), server_default='1.0', nullable=False),
        sa.Column('last_band_change', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        'session_disputes',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), unique=True, nullable=False),
        sa.Column('opened_by_user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('reason', sa.String(length=50), nullable=False),
        sa.Column('details', sa.Text(), nullable=False),
        sa.Column('status', sa.String(length=20), server_default='open', nullable=False),
        sa.Column('decision', sa.String(length=50), nullable=True),
        sa.Column('resolution_note', sa.Text(), nullable=True),
        sa.Column('resolved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
    )

def downgrade() -> None:
    op.drop_table('session_disputes')
    op.drop_table('giver_band_profiles')
    op.drop_table('request_quality_ratings')
    op.drop_table('session_ratings')
