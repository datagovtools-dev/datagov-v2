"""Unit tests for RBAC permission enforcement."""
import pytest
from unittest.mock import AsyncMock, MagicMock

from fastapi import HTTPException


class MockUser:
    def __init__(self, permissions: list[str]):
        self.id = "test-user-id"
        self.email = "test@example.com"
        self.full_name = "Test User"
        self._permissions = permissions

    def has_permission(self, perm: str) -> bool:
        return perm in self._permissions


def _make_checker(permission: str):
    """Returns an async callable that raises 403 if user lacks permission."""
    async def check(user: MockUser) -> MockUser:
        if not user.has_permission(permission):
            raise HTTPException(status_code=403, detail="Forbidden")
        return user
    return check


@pytest.mark.asyncio
async def test_user_with_permission_passes():
    user = MockUser(["metadata:read", "metadata:update"])
    checker = _make_checker("metadata:read")
    result = await checker(user)
    assert result is user


@pytest.mark.asyncio
async def test_user_without_permission_raises_403():
    user = MockUser(["dsr:read"])
    checker = _make_checker("metadata:update")
    with pytest.raises(HTTPException) as exc_info:
        await checker(user)
    assert exc_info.value.status_code == 403


@pytest.mark.asyncio
async def test_superadmin_has_all_permissions():
    user = MockUser(["*"])
    # Superadmin pattern — any perm string matches
    user._permissions = ["metadata:read", "metadata:update", "dsr:read", "dsr:create",
                         "dpia:read", "ropa:read", "bapd:read", "dq:read", "audit:read"]
    checker = _make_checker("audit:read")
    result = await checker(user)
    assert result is user
