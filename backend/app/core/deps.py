import uuid
from typing import Annotated

from fastapi import Cookie, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.redis_client import is_token_denied
from app.core.security import decode_token
from app.database import get_db
from app.models.user import User, UserProjectRole, Role
from sqlalchemy import select

bearer_scheme = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
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
