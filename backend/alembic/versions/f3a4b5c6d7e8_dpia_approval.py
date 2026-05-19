"""DPIA approval workflow

Revision ID: f3a4b5c6d7e8
Revises: e2f3a4b5c6d7
Create Date: 2026-05-15
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'f3a4b5c6d7e8'
down_revision: Union[str, None] = 'e2f3a4b5c6d7'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'dpia_approvals',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text('gen_random_uuid()')),
        sa.Column('dpia_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('dpia_records.id', ondelete='CASCADE'),
                  nullable=False),
        sa.Column('approver_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id'), nullable=False),
        sa.Column('approver_role', sa.String(80), nullable=False),
        sa.Column('step_order', sa.SmallInteger(), nullable=False),
        sa.Column('status', sa.String(20), nullable=False, server_default='pending'),
        sa.Column('comments', sa.Text(), nullable=True),
        sa.Column('actioned_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index('ix_dpia_approvals_dpia_id', 'dpia_approvals', ['dpia_id'])


def downgrade() -> None:
    op.drop_index('ix_dpia_approvals_dpia_id', table_name='dpia_approvals')
    op.drop_table('dpia_approvals')
