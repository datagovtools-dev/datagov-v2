import uuid
from datetime import timedelta, timezone, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Response, status, Request
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.deps import CurrentUser, get_refresh_token_payload
from app.core.rbac import ROLE_SESSION_LIMITS
from app.core.redis_client import (
    deny_token, is_token_denied,
    add_user_session, remove_user_session, get_active_session_jtis,
)
from app.core.security import create_access_token, create_refresh_token, decode_token, hash_password, verify_password
from app.database import get_db
from app.models.user import AuditLog, User, UserProjectRole, Role

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()

REFRESH_COOKIE_MAX_AGE = settings.refresh_token_expire_days * 86400


# --- Schemas ---

class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


from app.core.rbac import (
    ROLE_SESSION_LIMITS,
    _ROLE_PERMISSIONS,
    get_user_capabilities_from_roles,
)

class UserOut(BaseModel):
    id: uuid.UUID
    email: str
    full_name: str
    is_active: bool
    is_super_admin: bool = False
    roles: list[str] = []
    permissions: list[str] = []
    accessible_menus: list[str] = []
    permitted_activities: list[str] = []

    model_config = {"from_attributes": True}


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str


# --- Helpers ---

def _set_refresh_cookie(response: Response, token: str) -> None:
    response.set_cookie(
        key="refresh_token",
        value=token,
        httponly=True,
        secure=settings.environment == "production",
        samesite="lax",
        max_age=REFRESH_COOKIE_MAX_AGE,
        path="/api/v1/auth",
    )


def _clear_refresh_cookie(response: Response) -> None:
    response.delete_cookie(key="refresh_token", path="/api/v1/auth")


async def _log(db: AsyncSession, user_id: uuid.UUID | None, action: str, request: Request, entity_id: str | None = None) -> None:
    log = AuditLog(
        user_id=user_id,
        module="auth",
        action=action,
        entity_type="user",
        entity_id=entity_id,
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    )
    db.add(log)
    await db.flush()


async def _get_session_limit(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Return the concurrent session limit for this user (0 = unlimited)."""
    role_names = (await db.execute(
        select(Role.name)
        .join(UserProjectRole, UserProjectRole.role_id == Role.id)
        .where(UserProjectRole.user_id == user_id, UserProjectRole.revoked_at.is_(None))
    )).scalars().all()
    limit = 0
    for name in role_names:
        if name in ROLE_SESSION_LIMITS:
            candidate = ROLE_SESSION_LIMITS[name]
            if limit == 0 or candidate < limit:
                limit = candidate
    return limit


async def _enforce_session_limit(user_id: str, limit: int) -> None:
    """Deny and remove sessions beyond the limit (oldest evicted first)."""
    if limit <= 0:
        return
    active = await get_active_session_jtis(user_id)
    excess = len(active) - limit
    if excess > 0:
        for old_jti in active[:excess]:
            await deny_token(old_jti, settings.refresh_token_expire_days * 86400)
            await remove_user_session(user_id, old_jti)


# --- Endpoints ---

@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    request: Request,
    response: Response,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is disabled")

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    # Track session and enforce concurrent limit
    rt_payload = decode_token(refresh_token)
    rt_jti: str = rt_payload["jti"]
    rt_exp: int = int(rt_payload["exp"])
    await add_user_session(str(user.id), rt_jti, rt_exp)

    session_limit = await _get_session_limit(db, user.id)
    await _enforce_session_limit(str(user.id), session_limit)

    _set_refresh_cookie(response, refresh_token)

    user.last_login_at = datetime.now(timezone.utc)
    await _log(db, user.id, "login", request, str(user.id))
    await db.commit()

    return TokenResponse(access_token=access_token)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    payload: Annotated[dict, Depends(get_refresh_token_payload)],
    response: Response,
    db: Annotated[AsyncSession, Depends(get_db)],
    request: Request,
) -> TokenResponse:
    user_id_str: str = payload["sub"]
    old_jti: str | None = payload.get("jti")

    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id_str)))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    access_token = create_access_token(user_id_str)
    new_refresh = create_refresh_token(user_id_str)

    # Rotate session tracking: remove old JTI, register new one
    if old_jti:
        await remove_user_session(user_id_str, old_jti)
    rt_payload = decode_token(new_refresh)
    await add_user_session(user_id_str, rt_payload["jti"], int(rt_payload["exp"]))

    _set_refresh_cookie(response, new_refresh)

    await _log(db, user.id, "token_refresh", request, user_id_str)
    await db.commit()

    return TokenResponse(access_token=access_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    current_user: CurrentUser,
    response: Response,
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    # Remove the refresh session from tracking and denylist it
    rt_cookie = request.cookies.get("refresh_token")
    if rt_cookie:
        try:
            rt_payload = decode_token(rt_cookie)
            old_jti = rt_payload.get("jti")
            if old_jti:
                await remove_user_session(str(current_user.id), old_jti)
                await deny_token(old_jti, settings.refresh_token_expire_days * 86400)
        except Exception:
            pass

    _clear_refresh_cookie(response)
    await _log(db, current_user.id, "logout", request, str(current_user.id))
    await db.commit()


@router.get("/me", response_model=UserOut)
async def me(current_user: CurrentUser) -> UserOut:
    roles = [
        getattr(upr.role, "name", "")
        for upr in getattr(current_user, "project_roles", [])
        if upr.revoked_at is None and getattr(upr, "role", None)
    ]
    roles = [r for r in roles if r]
    
    perms: set[str] = set()
    for r in roles:
        role_perms = _ROLE_PERMISSIONS.get(r, set())
        if "*" in role_perms:
            perms = {"*"}
            break
        perms.update(role_perms)
        
    caps = get_user_capabilities_from_roles(roles)
    accessible_menu_ids = [m["id"] for m in caps["menus"] if m["is_accessible"]]
    permitted_activity_ids = [a["id"] for a in caps["activities"] if a["is_permitted"]]
    
    return UserOut(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        is_super_admin=current_user.is_super_admin,
        roles=roles,
        permissions=sorted(perms),
        accessible_menus=accessible_menu_ids,
        permitted_activities=permitted_activity_ids,
    )


@router.post("/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def register(
    body: RegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    request: Request,
) -> User:
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    user = User(
        full_name=body.full_name,
        email=body.email,
        password_hash=hash_password(body.password),
    )
    db.add(user)
    await db.flush()
    await _log(db, user.id, "register", request, str(user.id))
    await db.commit()
    await db.refresh(user)
    return user
