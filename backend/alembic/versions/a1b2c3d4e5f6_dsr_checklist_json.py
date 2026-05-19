"""dsr_checklist_json

Revision ID: a1b2c3d4e5f6
Revises: 634dcc21dc86
Create Date: 2026-05-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = '634dcc21dc86'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column('ai_compliance_checklists', 'purpose_desc')
    op.drop_column('ai_compliance_checklists', 'fairness_ok')
    op.drop_column('ai_compliance_checklists', 'minimization_ok')
    op.drop_column('ai_compliance_checklists', 'explainability_ok')
    op.add_column(
        'ai_compliance_checklists',
        sa.Column('checklist_json', JSONB, nullable=False, server_default='{}'),
    )


def downgrade() -> None:
    op.drop_column('ai_compliance_checklists', 'checklist_json')
    op.add_column('ai_compliance_checklists', sa.Column('purpose_desc', sa.Text, nullable=True))
    op.add_column('ai_compliance_checklists', sa.Column('fairness_ok', sa.Boolean, nullable=False, server_default='false'))
    op.add_column('ai_compliance_checklists', sa.Column('minimization_ok', sa.Boolean, nullable=False, server_default='false'))
    op.add_column('ai_compliance_checklists', sa.Column('explainability_ok', sa.Boolean, nullable=False, server_default='false'))
