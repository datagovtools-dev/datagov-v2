from typing import Annotated
from functools import lru_cache

from fastapi import Depends, HTTPException, status

from app.core.deps import CurrentUser
from app.models.user import User

# Maximum concurrent sessions per role (0 / absent = unlimited)
ROLE_SESSION_LIMITS: dict[str, int] = {
    "viewer": 2,
}

# Permission registry: role -> set of allowed actions
# Format: "<module>:<action>"
_ROLE_PERMISSIONS: dict[str, set[str]] = {
    "super_admin": {"*"},  # wildcard — all permissions
    "compliance_officer": {
        # Full operational access across every module — no system/user-management access
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read", "dq:create", "dq:approve",
        "user:read",
        "audit:read",
    },
    "dpo": {
        # Data Protection Officer — same as compliance_officer
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read", "dq:create", "dq:approve",
        "user:read",
        "audit:read",
    },
    "data_governance_officer": {
        "dsr:read", "dsr:approve", "dsr:reject",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update", "ropa:approve",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:update",
        "dq:read", "dq:run",
        "project:read",
        "user:read",
        "audit:read",
    },
    "project_manager": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create",
        "dpia:read",
        "ropa:read",
        "bapd:read",
        "metadata:read",
        "dq:read",
        "user:read",
    },
    "data_steward": {
        "metadata:read", "metadata:create", "metadata:update",
        "ropa:read", "ropa:create", "ropa:update",
        "dq:read", "dq:run", "dq:create",
        "project:read",
    },
    "data_owner": {
        "dsr:read", "dsr:approve", "dsr:reject",
        "metadata:read",
        "project:read",
    },
    "requester": {
        "dsr:read", "dsr:create", "dsr:update",
        "project:read",
    },
    "auditor": {
        "audit:read",
        "dsr:read",
        "dpia:read",
        "ropa:read",
        "bapd:read",
        "metadata:read",
        "dq:read",
        "project:read",
        "user:read",
    },
    "viewer": {
        "dsr:read",
        "dsr:create",
        "dpia:read",
        "ropa:read",
        "bapd:read",
        "metadata:read",
        "dq:read",
        "project:read",
        "user:read",
    },
}


@lru_cache(maxsize=256)
def _role_has_permission(role: str, permission: str) -> bool:
    allowed = _ROLE_PERMISSIONS.get(role, set())
    return "*" in allowed or permission in allowed


def _user_has_permission(user: User, permission: str) -> bool:
    """Check roles stored on the user object (loaded via joined eager load)."""
    for upr in getattr(user, "project_roles", []):
        if upr.revoked_at is None:
            role_name = getattr(upr.role, "name", None)
            if role_name and _role_has_permission(role_name, permission):
                return True
    return False


def require_permission(permission: str):
    """FastAPI dependency factory. Usage: Depends(require_permission('dsr:approve'))"""
    async def _check(current_user: CurrentUser) -> User:
        if not _user_has_permission(current_user, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: '{permission}' required",
            )
        return current_user
    return _check


def require_any_permission(*permissions: str):
    """Pass if user has at least one of the given permissions."""
    async def _check(current_user: CurrentUser) -> User:
        for perm in permissions:
            if _user_has_permission(current_user, perm):
                return current_user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Permission denied: one of {permissions} required",
        )
    return _check
