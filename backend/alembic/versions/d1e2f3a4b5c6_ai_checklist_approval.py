"""AI checklist approval workflow

Revision ID: d1e2f3a4b5c6
Revises: c1d2e3f4a5b6
Create Date: 2026-05-07
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'd1e2f3a4b5c6'
down_revision: Union[str, None] = 'c1d2e3f4a5b6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'ai_compliance_checklists',
        sa.Column('status', sa.String(30), nullable=False, server_default='draft')
    )
    op.create_table(
        'ai_checklist_approvals',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text('gen_random_uuid()')),
        sa.Column('checklist_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('ai_compliance_checklists.id', ondelete='CASCADE'),
                  nullable=False),
        sa.Column('approver_id', postgresql.UUID(as_uuid=True),
                  sa.ForeignKey('users.id'), nullable=False),
        sa.Column('approver_role', sa.String(80), nullable=False),
        sa.Column('step_order', sa.SmallInteger(), nullable=False),
        sa.Column('status', sa.String(20), nullable=False, server_default='pending'),
        sa.Column('comments', sa.Text(), nullable=True),
        sa.Column('actioned_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        'ix_ai_checklist_approvals_checklist_id',
        'ai_checklist_approvals', ['checklist_id']
    )


def downgrade() -> None:
    op.drop_index('ix_ai_checklist_approvals_checklist_id',
                  table_name='ai_checklist_approvals')
    op.drop_table('ai_checklist_approvals')
    op.drop_column('ai_compliance_checklists', 'status')
