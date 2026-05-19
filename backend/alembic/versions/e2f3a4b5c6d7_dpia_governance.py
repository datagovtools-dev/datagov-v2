"""Add tracking_id and governance_json to dpia_records

Revision ID: e2f3a4b5c6d7
Revises: d1e2f3a4b5c6
Create Date: 2026-05-07
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'e2f3a4b5c6d7'
down_revision: Union[str, None] = 'd1e2f3a4b5c6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('dpia_records',
        sa.Column('tracking_id', sa.String(30), nullable=True))
    op.add_column('dpia_records',
        sa.Column('governance_json', postgresql.JSONB(astext_type=sa.Text()),
                  nullable=True, server_default='{}'))
    op.create_index('ix_dpia_records_tracking_id', 'dpia_records',
                    ['tracking_id'], unique=True)
    # Backfill tracking_id for any pre-existing records
    op.execute("""
        WITH numbered AS (
            SELECT id,
                   EXTRACT(YEAR FROM created_at)::int AS yr,
                   ROW_NUMBER() OVER (
                       PARTITION BY EXTRACT(YEAR FROM created_at)
                       ORDER BY created_at
                   ) AS rn
            FROM dpia_records
            WHERE tracking_id IS NULL
        )
        UPDATE dpia_records d
        SET tracking_id = 'DPIA-' || n.yr || '-' || LPAD(n.rn::text, 4, '0')
        FROM numbered n
        WHERE d.id = n.id
    """)


def downgrade() -> None:
    op.drop_index('ix_dpia_records_tracking_id', 'dpia_records')
    op.drop_column('dpia_records', 'governance_json')
    op.drop_column('dpia_records', 'tracking_id')
