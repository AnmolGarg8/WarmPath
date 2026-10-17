"""create sessions and requests tables

Revision ID: 0001_sessions_init
Revises: 0001_core_base
Create Date: 2026-10-17 19:20:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0001_sessions_init'
down_revision: Union[str, None] = '0001_core_base'
branch_labels: Union[str, Sequence[str], None] = ('sessions',)
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.create_table(
        'mentorship_requests',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('giver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('kind', sa.String(length=20), nullable=False),
        sa.Column('intent_text', sa.Text(), nullable=False),
        sa.Column('slot_start', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', sa.String(length=20), server_default='pending', nullable=False),
        sa.Column('priority', sa.Integer(), server_default='1', nullable=False),
        sa.Column('plan_name', sa.String(length=50), nullable=True),
        sa.Column('is_cross_college', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('decline_reason', sa.Text(), nullable=True),
        sa.Column('idempotency_key', sa.String(length=255), unique=True, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(op.f('ix_mentorship_requests_student_id'), 'mentorship_requests', ['student_id'], unique=False)
    op.create_index(op.f('ix_mentorship_requests_giver_id'), 'mentorship_requests', ['giver_id'], unique=False)
    op.create_index(op.f('ix_mentorship_requests_status'), 'mentorship_requests', ['status'], unique=False)

    op.create_table(
        'call_sessions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('request_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('mentorship_requests.id', ondelete='CASCADE'), unique=True, nullable=False),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('giver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('scheduled_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('duration_minutes', sa.Integer(), server_default='20', nullable=False),
        sa.Column('room_url', sa.String(length=255), nullable=False),
        sa.Column('status', sa.String(length=20), server_default='scheduled', nullable=False),
        sa.Column('student_joined_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('student_left_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('giver_joined_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('giver_left_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('no_show_party', sa.String(length=20), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint('giver_id', 'scheduled_at', name='uq_giver_scheduled_slot')
    )
    op.create_index(op.f('ix_call_sessions_student_id'), 'call_sessions', ['student_id'], unique=False)
    op.create_index(op.f('ix_call_sessions_giver_id'), 'call_sessions', ['giver_id'], unique=False)
    op.create_index(op.f('ix_call_sessions_status'), 'call_sessions', ['status'], unique=False)

    op.create_table(
        'thread_messages',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('request_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('mentorship_requests.id', ondelete='CASCADE'), nullable=False),
        sa.Column('sender_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('safety_action', sa.String(length=20), server_default='allow', nullable=False),
        sa.Column('flags', postgresql.JSONB(as_json=True), server_default='[]', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(op.f('ix_thread_messages_request_id'), 'thread_messages', ['request_id'], unique=False)

    op.create_table(
        'device_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('fcm_token', sa.String(length=512), unique=True, nullable=False),
        sa.Column('platform', sa.String(length=20), server_default='android', nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(op.f('ix_device_tokens_user_id'), 'device_tokens', ['user_id'], unique=False)

def downgrade() -> None:
    op.drop_table('device_tokens')
    op.drop_table('thread_messages')
    op.drop_table('call_sessions')
    op.drop_table('mentorship_requests')
