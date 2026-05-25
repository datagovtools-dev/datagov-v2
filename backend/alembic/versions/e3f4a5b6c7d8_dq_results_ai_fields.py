"""Add AI-generated fields to dq_results for 4-dimension DQ output

Revision ID: e3f4a5b6c7d8
Revises: d8e9f0a1b2c3
Create Date: 2026-05-25
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e3f4a5b6c7d8"
down_revision: Union[str, None] = "d8e9f0a1b2c3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("dq_results", sa.Column("business_rules", sa.Text(), nullable=True))
    op.add_column("dq_results", sa.Column("regex_pattern", sa.Text(), nullable=True))
    op.add_column("dq_results", sa.Column("ai_model", sa.String(100), nullable=True))
    op.add_column("dq_results", sa.Column("regex_version", sa.String(50), nullable=True))
    op.add_column("dq_results", sa.Column("column_category", sa.String(50), nullable=True))


def downgrade() -> None:
    op.drop_column("dq_results", "column_category")
    op.drop_column("dq_results", "regex_version")
    op.drop_column("dq_results", "ai_model")
    op.drop_column("dq_results", "regex_pattern")
    op.drop_column("dq_results", "business_rules")
