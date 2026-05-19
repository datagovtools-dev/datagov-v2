"""add_project_sme

Revision ID: b1c2d3e4f5a6
Revises: 634dcc21dc86
Create Date: 2026-05-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'b1c2d3e4f5a6'
down_revision: Union[str, None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('projects', sa.Column(
        'sme_id', postgresql.UUID(as_uuid=True),
        sa.ForeignKey('users.id'), nullable=True,
    ))


def downgrade() -> None:
    op.drop_column('projects', 'sme_id')
