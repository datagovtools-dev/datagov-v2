"""add_project_code

Revision ID: 634dcc21dc86
Revises: 04c6e5619e78
Create Date: 2026-05-04 15:06:37.750878

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '634dcc21dc86'
down_revision: Union[str, None] = '04c6e5619e78'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('projects', sa.Column('project_code', sa.String(length=50), nullable=True))
    op.create_index(op.f('ix_projects_project_code'), 'projects', ['project_code'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_projects_project_code'), table_name='projects')
    op.drop_column('projects', 'project_code')
