import pytest
from fastapi import HTTPException

from app.core import deps
from app.core.security import create_refresh_token


@pytest.mark.asyncio
async def test_refresh_payload_returns_503_when_redis_is_unavailable(monkeypatch):
    monkeypatch.setattr(
        deps,
        "is_token_denied",
        lambda _jti: _raise_redis_error(),
    )

    with pytest.raises(HTTPException) as error:
        await deps.get_refresh_token_payload(
            create_refresh_token("00000000-0000-0000-0000-000000000001", session_version=0)
        )

    assert error.value.status_code == 503


async def _raise_redis_error():
    raise RuntimeError("redis unavailable")