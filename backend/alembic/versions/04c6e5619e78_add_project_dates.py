"""add_project_dates

Revision ID: 04c6e5619e78
Revises: 312dcd0ffeaf
Create Date: 2026-05-04 14:53:44.331547

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '04c6e5619e78'
down_revision: Union[str, None] = '312dcd0ffeaf'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('projects', sa.Column('start_date', sa.Date(), nullable=True))
    op.add_column('projects', sa.Column('end_date', sa.Date(), nullable=True))


def downgrade() -> None:
    op.drop_column('projects', 'end_date')
    op.drop_column('projects', 'start_date')
