"""Add source_row_count to metadata_records

Revision ID: a4b5c6d7e8f9
Revises: f3a4b5c6d7e8
Create Date: 2026-05-18
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "a4b5c6d7e8f9"
down_revision: Union[str, None] = "f3a4b5c6d7e8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "metadata_records",
        sa.Column("source_row_count", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("metadata_records", "source_row_count")
