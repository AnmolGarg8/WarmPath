"""trust branch tables: reports, blocks, flagged_items, audit_logs

Revision ID: 0001_trust_tables
Revises: 0001_core_base
Create Date: 2026-10-17 19:25:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = '0001_trust_tables'
down_revision: str | None = '0001_core_base'
branch_labels: str | Sequence[str] | None = ('trust',)
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. reports table
    op.create_table(
        'reports',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('reporter_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('target_user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('message_id', sa.String(length=255), nullable=True),
        sa.Column('request_id', sa.String(length=255), nullable=True),
        sa.Column('reason', sa.String(length=100), nullable=False),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('status', sa.String(length=50), server_default='pending', nullable=False),
        sa.Column('resolution_decision', sa.String(length=50), nullable=True),
        sa.Column('resolution_note', sa.Text(), nullable=True),
        sa.Column('resolved_by_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['reporter_id'], ['users.id']),
        sa.ForeignKeyConstraint(['target_user_id'], ['users.id']),
        sa.ForeignKeyConstraint(['resolved_by_id'], ['users.id']),
    )
    op.create_index('ix_reports_reporter_id', 'reports', ['reporter_id'])
    op.create_index('ix_reports_target_user_id', 'reports', ['target_user_id'])
    op.create_index('ix_reports_status', 'reports', ['status'])

    # 2. blocks table
    op.create_table(
        'blocks',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('blocker_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('blocked_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('reason', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['blocker_id'], ['users.id']),
        sa.ForeignKeyConstraint(['blocked_id'], ['users.id']),
        sa.UniqueConstraint('blocker_id', 'blocked_id', name='uq_blocker_blocked'),
    )
    op.create_index('ix_blocks_blocker_id', 'blocks', ['blocker_id'])
    op.create_index('ix_blocks_blocked_id', 'blocks', ['blocked_id'])

    # 3. flagged_items table
    op.create_table(
        'flagged_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('sender_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('text', sa.Text(), nullable=False),
        sa.Column('flags', postgresql.JSONB(), server_default='[]', nullable=False),
        sa.Column('action', sa.String(length=50), nullable=False),
        sa.Column('context', sa.String(length=100), nullable=True),
        sa.Column('status', sa.String(length=50), server_default='pending', nullable=False),
        sa.Column('resolved_by_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['sender_id'], ['users.id']),
        sa.ForeignKeyConstraint(['resolved_by_id'], ['users.id']),
    )
    op.create_index('ix_flagged_items_sender_id', 'flagged_items', ['sender_id'])
    op.create_index('ix_flagged_items_status', 'flagged_items', ['status'])

    # 4. audit_logs table
    op.create_table(
        'audit_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('actor_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('actor_email', sa.String(length=255), nullable=False),
        sa.Column('action', sa.String(length=100), nullable=False),
        sa.Column('target_type', sa.String(length=50), nullable=False),
        sa.Column('target_id', sa.String(length=255), nullable=False),
        sa.Column('institution_id', sa.Integer(), nullable=True),
        sa.Column('details', postgresql.JSONB(), server_default='{}', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['actor_id'], ['users.id']),
        sa.ForeignKeyConstraint(['institution_id'], ['institutions.id']),
    )
    op.create_index('ix_audit_logs_actor_id', 'audit_logs', ['actor_id'])
    op.create_index('ix_audit_logs_action', 'audit_logs', ['action'])
    op.create_index('ix_audit_logs_target_id', 'audit_logs', ['target_id'])
    op.create_index('ix_audit_logs_institution_id', 'audit_logs', ['institution_id'])


def downgrade() -> None:
    op.drop_table('audit_logs')
    op.drop_table('flagged_items')
    op.drop_table('blocks')
    op.drop_table('reports')
