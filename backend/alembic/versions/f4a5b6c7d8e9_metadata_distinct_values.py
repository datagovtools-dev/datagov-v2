"""Add distinct_values to metadata_records (backfill migration)

Revision ID: f4a5b6c7d8e9
Revises: e3f4a5b6c7d8
Create Date: 2026-05-25

Uses ADD COLUMN IF NOT EXISTS so this is safe to run against a live database
that already has the column (added outside migrations in a prior session).
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f4a5b6c7d8e9"
down_revision: Union[str, None] = "e3f4a5b6c7d8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE metadata_records ADD COLUMN IF NOT EXISTS distinct_values TEXT"
    )


def downgrade() -> None:
    op.drop_column("metadata_records", "distinct_values")
