import uuid
from typing import Annotated

from fastapi import Cookie, Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.redis_client import is_token_denied
from app.core.security import decode_token
from app.config import get_settings
from app.database import get_db
from app.models.user import User, UserProjectRole, Role
from sqlalchemy import select

bearer_scheme = HTTPBearer(auto_error=False)
settings = get_settings()


def is_local_auth_bypass_request(request: Request) -> bool:
    """Return true only for an explicitly enabled, non-production local request."""
    if not settings.local_auth_bypass_enabled:
        return False
    if settings.environment.strip().lower() in {"production", "prod"}:
        return False
    hostname = (request.url.hostname or "").strip().lower()
    allowed_hosts = {
        host.strip().lower().strip("[]")
        for host in settings.local_auth_bypass_hosts.split(",")
        if host.strip()
    }
    return hostname in allowed_hosts


async def _get_local_bypass_user(db: AsyncSession) -> User:
    """Resolve the configured local testing user without accepting credentials."""
    stmt = (
        select(User)
        .options(selectinload(User.project_roles).selectinload(UserProjectRole.role))
        .where(User.is_active == True)  # noqa: E712
    )
    if settings.local_auth_bypass_email.strip():
        stmt = stmt.where(User.email == settings.local_auth_bypass_email.strip())
    else:
        stmt = stmt.order_by(User.email)
    users = (await db.execute(stmt)).scalars().all()
    user = next(
        (
            candidate
            for candidate in users
            if settings.local_auth_bypass_email.strip() or candidate.is_super_admin
        ),
        None,
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Local auth bypass is enabled but no active test user was found",
        )
    return user


async def get_current_user(
    request: Request,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    if is_local_auth_bypass_request(request):
        return await _get_local_bypass_user(db)

    exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not credentials:
        raise exc
    token = credentials.credentials
    try:
        payload = decode_token(token)
    except JWTError:
        raise exc

    if payload.get("type") != "access":
        raise exc

    jti = payload.get("jti")
    if jti and await is_token_denied(jti):
        raise exc

    user_id_str: str | None = payload.get("sub")
    if not user_id_str:
        raise exc

    try:
        user_id = uuid.UUID(user_id_str)
    except ValueError:
        raise exc

    result = await db.execute(
        select(User)
        .options(selectinload(User.project_roles).selectinload(UserProjectRole.role))
        .where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise exc
    return user


async def get_refresh_token_payload(
    refresh_token: Annotated[str | None, Cookie(alias="refresh_token")] = None,
) -> dict:
    exc = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or missing refresh token")
    if not refresh_token:
        raise exc
    try:
        payload = decode_token(refresh_token)
    except JWTError:
        raise exc
    if payload.get("type") != "refresh":
        raise exc
    jti = payload.get("jti")
    if jti and await is_token_denied(jti):
        raise exc
    return payload


CurrentUser = Annotated[User, Depends(get_current_user)]
