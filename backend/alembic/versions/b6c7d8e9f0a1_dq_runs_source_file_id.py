"""Add source_file_id FK to dq_runs for Metadata-DQ integration

Revision ID: b6c7d8e9f0a1
Revises: f4a5b6c7d8e9
Create Date: 2026-05-26
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "b6c7d8e9f0a1"
down_revision: Union[str, None] = "f4a5b6c7d8e9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "dq_runs",
        sa.Column("source_file_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_dq_runs_source_file_id",
        "dq_runs", "project_source_files",
        ["source_file_id"], ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint("fk_dq_runs_source_file_id", "dq_runs", type_="foreignkey")
    op.drop_column("dq_runs", "source_file_id")
