import os

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")

from app.routers.settings import _to_status
from app.schemas.settings import AISettingsUpdate


def test_ai_status_exposes_batch_and_timeout_defaults():
    status = _to_status(None)

    assert status.timeout_seconds == 60
    assert status.batch_size == 5


def test_ai_settings_accepts_openrouter_provider():
    settings = AISettingsUpdate(
        provider="openrouter",
        mode="cloud",
        base_url="https://openrouter.ai/api/v1",
        model_name="openai/gpt-4o-mini",
    )

    assert settings.provider == "openrouter"
