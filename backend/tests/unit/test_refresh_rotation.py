import pytest
from fastapi import HTTPException, Request, Response
from unittest.mock import AsyncMock, Mock
from uuid import uuid4

from app.core import redis_client
from app.models.user import User
from app.routers import auth


class FakeRedis:
    def __init__(self):
        self.values: dict[str, str] = {}

    async def set(self, key, value, ex=None, nx=False):
        if nx and key in self.values:
            return None
        self.values[key] = value
        return True


@pytest.mark.asyncio
async def test_consume_token_is_atomic_and_single_use(monkeypatch):
    client = FakeRedis()
    monkeypatch.setattr(redis_client, "is_redis_enabled", lambda: True)
    monkeypatch.setattr(redis_client, "get_redis", lambda: _resolved(client))

    assert await redis_client.consume_token("jti-1", 60) is True
    assert await redis_client.consume_token("jti-1", 60) is False


async def _resolved(value):
    return value


@pytest.mark.asyncio
async def test_consume_token_fails_closed_without_redis(monkeypatch):
    monkeypatch.setattr(redis_client, "is_redis_enabled", lambda: False)

    with pytest.raises(RuntimeError):
        await redis_client.consume_token("jti-1", 60)


def _request() -> Request:
    return Request({"type": "http", "method": "POST", "path": "/auth/refresh", "headers": []})


@pytest.mark.asyncio
async def test_refresh_rejects_reuse_of_consumed_refresh_token(monkeypatch):
    user = User(
        id=uuid4(),
        full_name="Refresh User",
        email="refresh@example.test",
        password_hash="hash",
        is_active=True,
        session_version=0,
    )
    db_result = type("Result", (), {"scalar_one_or_none": lambda self: user})()
    db = type("FakeDB", (), {
        "execute": AsyncMock(return_value=db_result),
        "add": Mock(),
        "flush": AsyncMock(),
        "commit": AsyncMock(),
    })()
    consume = AsyncMock(side_effect=[True, False])
    monkeypatch.setattr(auth, "consume_token", consume)
    monkeypatch.setattr(auth, "remove_user_session", AsyncMock())
    monkeypatch.setattr(auth, "add_user_session", AsyncMock())
    monkeypatch.setattr(auth, "_log", AsyncMock())
    payload = {"sub": str(user.id), "jti": "refresh-jti", "type": "refresh", "sv": 0}

    first = await auth.refresh(payload, Response(), db, _request())
    assert first.access_token
    with pytest.raises(HTTPException) as error:
        await auth.refresh(payload, Response(), db, _request())
    assert error.value.status_code == 401
    assert consume.await_count == 2


@pytest.mark.asyncio
async def test_refresh_returns_service_unavailable_when_consumption_fails(monkeypatch):
    user = User(
        id=uuid4(),
        full_name="Refresh User",
        email="refresh@example.test",
        password_hash="hash",
        is_active=True,
        session_version=0,
    )
    db_result = type("Result", (), {"scalar_one_or_none": lambda self: user})()
    db = type("FakeDB", (), {"execute": AsyncMock(return_value=db_result)})()
    monkeypatch.setattr(auth, "consume_token", AsyncMock(side_effect=RuntimeError("redis unavailable")))
    payload = {"sub": str(user.id), "jti": "refresh-jti", "type": "refresh", "sv": 0}

    with pytest.raises(HTTPException) as error:
        await auth.refresh(payload, Response(), db, _request())
    assert error.value.status_code == 503