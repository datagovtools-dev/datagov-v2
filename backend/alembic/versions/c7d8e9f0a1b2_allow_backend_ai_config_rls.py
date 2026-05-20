"""allow backend roles to manage AI provider config

Revision ID: c7d8e9f0a1b2
Revises: c6d7e8f9a0b1
Create Date: 2026-05-20 00:00:00.000000
"""
from typing import Sequence, Union

from alembic import op


revision: str = "c7d8e9f0a1b2"
down_revision: Union[str, None] = "c6d7e8f9a0b1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("""
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'ai_provider_configs'
          AND policyname = 'rls_ai_provider_configs_backend_select'
      ) THEN
        CREATE POLICY rls_ai_provider_configs_backend_select
        ON public.ai_provider_configs
        FOR SELECT
        TO public
        USING (true);
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'ai_provider_configs'
          AND policyname = 'rls_ai_provider_configs_backend_insert'
      ) THEN
        CREATE POLICY rls_ai_provider_configs_backend_insert
        ON public.ai_provider_configs
        FOR INSERT
        TO public
        WITH CHECK (true);
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'ai_provider_configs'
          AND policyname = 'rls_ai_provider_configs_backend_update'
      ) THEN
        CREATE POLICY rls_ai_provider_configs_backend_update
        ON public.ai_provider_configs
        FOR UPDATE
        TO public
        USING (true)
        WITH CHECK (true);
      END IF;
    END $$;
    """)

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
    op.execute("DROP POLICY IF EXISTS rls_ai_provider_configs_backend_update ON public.ai_provider_configs")
    op.execute("DROP POLICY IF EXISTS rls_ai_provider_configs_backend_insert ON public.ai_provider_configs")
    op.execute("DROP POLICY IF EXISTS rls_ai_provider_configs_backend_select ON public.ai_provider_configs")
