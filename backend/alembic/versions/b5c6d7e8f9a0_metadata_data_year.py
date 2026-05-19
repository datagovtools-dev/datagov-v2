"""add data_year to metadata_records

Revision ID: b5c6d7e8f9a0
Revises: a4b5c6d7e8f9
Create Date: 2026-05-19

"""
from alembic import op
import sqlalchemy as sa

revision = 'b5c6d7e8f9a0'
down_revision = 'a4b5c6d7e8f9'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('metadata_records', sa.Column('data_year', sa.SmallInteger(), nullable=True))


def downgrade() -> None:
    op.drop_column('metadata_records', 'data_year')
