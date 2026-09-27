import os

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")

from app.routers.settings import _to_status


def test_ai_status_exposes_batch_and_timeout_defaults():
    status = _to_status(None)

    assert status.timeout_seconds == 60
    assert status.batch_size == 5
