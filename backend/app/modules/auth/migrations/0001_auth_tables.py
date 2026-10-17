"""auth branch tables and user extensions

Revision ID: 0001_auth_tables
Revises: 0001_core_base
Create Date: 2026-10-17 18:45:00.000000

"""
from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = '0001_auth_tables'
down_revision: str | None = '0001_core_base'
branch_labels: str | Sequence[str] | None = ('auth',)
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1. Extend users table
    op.add_column('users', sa.Column('verification_level', sa.String(length=50), server_default='email_only', nullable=False))
    op.add_column('users', sa.Column('badges', postgresql.ARRAY(sa.String()), server_default='{}', nullable=False))
    op.add_column('users', sa.Column('display_name', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('headline', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('avatar_url', sa.String(length=1024), nullable=True))
    op.add_column('users', sa.Column('trust_level', sa.String(length=50), server_default='new', nullable=False))
    op.add_column('users', sa.Column('status', sa.String(length=50), server_default='active', nullable=False))
    op.add_column('users', sa.Column('last_seen_at', sa.DateTime(timezone=True), nullable=True))

    # 2. Table approved_members
    op.create_table(
        'approved_members',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('institution_id', sa.Integer(), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=255), nullable=False),
        sa.Column('role', sa.String(length=50), nullable=False),
        sa.Column('batch', sa.String(length=50), nullable=True),
        sa.Column('department', sa.String(length=100), nullable=True),
        sa.Column('claimed_by_user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['claimed_by_user_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['institution_id'], ['institutions.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_approved_members_email'), 'approved_members', ['email'], unique=True)

    # 3. Table verification_requests
    op.create_table(
        'verification_requests',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('kind', sa.String(length=50), nullable=False),
        sa.Column('evidence_text', sa.Text(), nullable=False),
        sa.Column('evidence_urls', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('company_name', sa.String(length=255), nullable=True),
        sa.Column('company_registration', sa.String(length=255), nullable=True),
        sa.Column('status', sa.String(length=50), server_default='pending', nullable=False),
        sa.Column('decided_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('decision_reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_verification_requests_status'), 'verification_requests', ['status'], unique=False)
    op.create_index(op.f('ix_verification_requests_user_id'), 'verification_requests', ['user_id'], unique=False)

    # 4. Table refresh_tokens
    op.create_table(
        'refresh_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('family_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('token_hash', sa.String(length=255), nullable=False),
        sa.Column('is_revoked', sa.Boolean(), server_default='false', nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_refresh_tokens_family_id'), 'refresh_tokens', ['family_id'], unique=False)
    op.create_index(op.f('ix_refresh_tokens_token_hash'), 'refresh_tokens', ['token_hash'], unique=False)
    op.create_index(op.f('ix_refresh_tokens_user_id'), 'refresh_tokens', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_refresh_tokens_user_id'), table_name='refresh_tokens')
    op.drop_index(op.f('ix_refresh_tokens_token_hash'), table_name='refresh_tokens')
    op.drop_index(op.f('ix_refresh_tokens_family_id'), table_name='refresh_tokens')
    op.drop_table('refresh_tokens')
    op.drop_index(op.f('ix_verification_requests_user_id'), table_name='verification_requests')
    op.drop_index(op.f('ix_verification_requests_status'), table_name='verification_requests')
    op.drop_table('verification_requests')
    op.drop_index(op.f('ix_approved_members_email'), table_name='approved_members')
    op.drop_table('approved_members')
    op.drop_column('users', 'last_seen_at')
    op.drop_column('users', 'status')
    op.drop_column('users', 'trust_level')
    op.drop_column('users', 'avatar_url')
    op.drop_column('users', 'headline')
    op.drop_column('users', 'display_name')
    op.drop_column('users', 'badges')
    op.drop_column('users', 'verification_level')
