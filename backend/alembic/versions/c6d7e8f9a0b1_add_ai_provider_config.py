"""add ai provider config

Revision ID: c6d7e8f9a0b1
Revises: b5c6d7e8f9a0
Create Date: 2026-05-20 00:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql


revision: str = "c6d7e8f9a0b1"
down_revision: Union[str, None] = "b5c6d7e8f9a0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "ai_provider_configs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("provider", sa.String(length=40), nullable=False),
        sa.Column("mode", sa.String(length=40), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("base_url", sa.String(length=500), nullable=False, server_default="https://ollama.com"),
        sa.Column("model_name", sa.String(length=160), nullable=False, server_default="gpt-oss:120b"),
        sa.Column("timeout_seconds", sa.Integer(), nullable=False, server_default="60"),
        sa.Column("batch_size", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("encrypted_api_key", sa.Text(), nullable=True),
        sa.Column("api_key_last4", sa.String(length=12), nullable=True),
        sa.Column("updated_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["updated_by"], ["users.id"], name="fk_ai_provider_configs_updated_by_users"),
        sa.PrimaryKeyConstraint("id", name="pk_ai_provider_configs"),
    )
    op.create_index("ix_ai_provider_configs_provider", "ai_provider_configs", ["provider"], unique=False)

    op.execute("ALTER TABLE public.ai_provider_configs ENABLE ROW LEVEL SECURITY")
    op.execute("REVOKE ALL ON TABLE public.ai_provider_configs FROM PUBLIC")
    op.execute("""
    DO $$
    BEGIN
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON TABLE public.ai_provider_configs FROM anon;
      END IF;
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON TABLE public.ai_provider_configs FROM authenticated;
      END IF;
    END $$;
    """)


def downgrade() -> None:
    op.drop_index("ix_ai_provider_configs_provider", table_name="ai_provider_configs")
    op.drop_table("ai_provider_configs")
