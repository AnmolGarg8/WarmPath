"""create availability and capacity_usage tables

Revision ID: 0001_avail_init
Revises: 0001_core_base
Create Date: 2026-10-17 19:15:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0001_avail_init'
down_revision: Union[str, None] = '0001_core_base'
branch_labels: Union[str, Sequence[str], None] = ('availability',)
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    op.create_table(
        'availability',
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('weekly_capacity', sa.Integer(), nullable=False, server_default='5'),
        sa.Column('timezone', sa.String(length=50), nullable=False, server_default='UTC'),
        sa.Column('windows', postgresql.JSONB(), nullable=False, server_default='[]'),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    op.create_table(
        'capacity_usage',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('week_start', sa.Date(), nullable=False),
        sa.Column('used', sa.Integer(), nullable=False, server_default='0'),
    )
    op.create_index(op.f('ix_capacity_usage_user_id'), 'capacity_usage', ['user_id'], unique=False)
    op.create_index(op.f('ix_capacity_usage_week_start'), 'capacity_usage', ['week_start'], unique=False)

def downgrade() -> None:
    op.drop_index(op.f('ix_capacity_usage_week_start'), table_name='capacity_usage')
    op.drop_index(op.f('ix_capacity_usage_user_id'), table_name='capacity_usage')
    op.drop_table('capacity_usage')
    op.drop_table('availability')
