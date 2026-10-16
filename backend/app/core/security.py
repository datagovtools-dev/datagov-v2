import base64
import hashlib
import uuid as _uuid
from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import get_settings

settings = get_settings()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"
LONG_PASSWORD_HASH_PREFIX = "bcrypt-sha256$"


def _bcrypt_input(password: str) -> str:
    """Keep bcrypt safe for the API's 128-character password limit."""
    if len(password.encode("utf-8")) <= 72:
        return password
    digest = hashlib.sha256(password.encode("utf-8")).digest()
    return base64.b64encode(digest).decode("ascii")


def hash_password(plain: str) -> str:
    # Prefix every new hash so unmarked legacy bcrypt hashes can be rejected.
    # Legacy bcrypt cannot distinguish a real long password from a valid 72-byte
    # prefix, so accepting those hashes would preserve password aliases.
    return LONG_PASSWORD_HASH_PREFIX + pwd_context.hash(_bcrypt_input(plain))


def verify_password(plain: str, hashed: str) -> bool:
    if not hashed.startswith(LONG_PASSWORD_HASH_PREFIX):
        # Existing unmarked bcrypt hashes require an explicit password reset.
        # Silent fallback would accept every password sharing the first 72 bytes.
        return False
    return pwd_context.verify(_bcrypt_input(plain), hashed[len(LONG_PASSWORD_HASH_PREFIX):])


def _make_token(subject: str, expires_delta: timedelta, token_type: str, extra: dict[str, Any] | None = None) -> str:
    now = datetime.now(timezone.utc)
    payload: dict[str, Any] = {
        "sub": subject,
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
        "jti": str(_uuid.uuid4()),
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def create_access_token(
    user_id: str,
    roles: list[str] | None = None,
    session_version: int | None = None,
) -> str:
    extra: dict[str, Any] = {"roles": roles or []}
    if session_version is not None:
        extra["sv"] = session_version
    return _make_token(
        subject=user_id,
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
        token_type="access",
        extra=extra,
    )


def create_refresh_token(user_id: str, session_version: int | None = None) -> str:
    extra = {"sv": session_version} if session_version is not None else None
    return _make_token(
        subject=user_id,
        expires_delta=timedelta(days=settings.refresh_token_expire_days),
        token_type="refresh",
        extra=extra,
    )


def decode_token(token: str) -> dict[str, Any]:
    """Decode and validate a JWT. Raises JWTError on failure."""
    return jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
