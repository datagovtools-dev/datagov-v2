from datetime import datetime, timezone

from redis.asyncio import Redis, from_url
from app.config import get_settings

_redis: Redis | None = None


def is_redis_enabled() -> bool:
    settings = get_settings()
    return bool(settings.redis_url and settings.redis_url.startswith("redis"))


async def get_redis() -> Redis:
    global _redis
    if not is_redis_enabled():
        raise RuntimeError("Redis is not configured")
    if _redis is None:
        settings = get_settings()
        _redis = from_url(settings.redis_url, decode_responses=True)
    return _redis


async def close_redis() -> None:
    global _redis
    if _redis is not None:
        await _redis.aclose()
        _redis = None


DENYLIST_PREFIX = "jwt:deny:"
SESSION_PREFIX = "session:"


async def deny_token(jti: str, ttl_seconds: int) -> None:
    if not is_redis_enabled():
        return
    r = await get_redis()
    await r.setex(f"{DENYLIST_PREFIX}{jti}", ttl_seconds, "1")


async def is_token_denied(jti: str) -> bool:
    if not is_redis_enabled():
        return False
    r = await get_redis()
    return await r.exists(f"{DENYLIST_PREFIX}{jti}") == 1


async def set_session(user_id: str, data: str, ttl_seconds: int) -> None:
    if not is_redis_enabled():
        return
    r = await get_redis()
    await r.setex(f"{SESSION_PREFIX}{user_id}", ttl_seconds, data)


async def get_session(user_id: str) -> str | None:
    if not is_redis_enabled():
        return None
    r = await get_redis()
    return await r.get(f"{SESSION_PREFIX}{user_id}")


async def delete_session(user_id: str) -> None:
    if not is_redis_enabled():
        return
    r = await get_redis()
    await r.delete(f"{SESSION_PREFIX}{user_id}")


# ── Concurrent session tracking (per-user refresh token registry) ─────────────

USER_SESSIONS_PREFIX = "user_sessions:"


async def add_user_session(user_id: str, jti: str, exp_ts: int) -> None:
    """Register a refresh token JTI in the user's active-session sorted set.
    Score = expiry Unix timestamp so expired entries can be pruned by range."""
    if not is_redis_enabled():
        return
    r = await get_redis()
    key = f"{USER_SESSIONS_PREFIX}{user_id}"
    now = int(datetime.now(timezone.utc).timestamp())
    await r.zremrangebyscore(key, "-inf", now)   # prune already-expired tokens
    await r.zadd(key, {jti: exp_ts})
    await r.expire(key, 8 * 86400)               # key TTL slightly > token expiry


async def remove_user_session(user_id: str, jti: str) -> None:
    if not is_redis_enabled():
        return
    r = await get_redis()
    await r.zrem(f"{USER_SESSIONS_PREFIX}{user_id}", jti)


async def get_active_session_jtis(user_id: str) -> list[str]:
    """Return active refresh token JTIs, oldest first (lowest expiry score)."""
    if not is_redis_enabled():
        return []
    r = await get_redis()
    key = f"{USER_SESSIONS_PREFIX}{user_id}"
    now = int(datetime.now(timezone.utc).timestamp())
    await r.zremrangebyscore(key, "-inf", now)
    return await r.zrange(key, 0, -1)
