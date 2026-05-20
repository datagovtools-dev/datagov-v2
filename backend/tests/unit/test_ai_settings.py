import os
import pathlib

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")
os.environ.setdefault("DATABASE_NULL_POOL", "true")

from app.routers.settings import _to_status


def test_ai_status_exposes_batch_and_timeout_defaults():
    status = _to_status(None)

    assert status.timeout_seconds == 60
    assert status.batch_size == 5


def test_ai_config_rls_migration_keeps_browser_roles_revoked():
    migration = pathlib.Path("alembic/versions/c7d8e9f0a1b2_allow_backend_ai_config_rls.py").read_text()

    assert "CREATE POLICY rls_ai_provider_configs_backend_insert" in migration
    assert "CREATE POLICY rls_ai_provider_configs_backend_update" in migration
    assert "REVOKE ALL ON TABLE public.ai_provider_configs FROM anon" in migration
    assert "REVOKE ALL ON TABLE public.ai_provider_configs FROM authenticated" in migration
