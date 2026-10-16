import pytest
from pydantic import SecretStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from app.database import Base
from app.models.user import Role, User, UserProjectRole
from app.routers.rbac import reset_user_password
from app.schemas.rbac import AdminPasswordResetRequest
from app.core.security import verify_password


@pytest.mark.asyncio
async def test_password_reset_uses_atomic_session_version_update():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    import app.models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    sessions = async_sessionmaker(engine, expire_on_commit=False)
    admin_id = uuid4()
    target_id = uuid4()
    async with sessions() as session:
        role = Role(name="super_admin", description="Super Admin", permissions=["*"])
        admin = User(
            id=admin_id,
            full_name="Admin",
            email="admin@example.test",
            password_hash="admin-hash",
            is_active=True,
        )
        target = User(
            id=target_id,
            full_name="Target",
            email="target@example.test",
            password_hash="old-hash",
            is_active=True,
        )
        session.add_all([role, admin, target])
        await session.flush()
        session.add(UserProjectRole(user_id=admin_id, role_id=role.id, assigned_by=admin_id))
        await session.commit()

        with patch("app.routers.rbac.get_active_session_jtis", new=AsyncMock(return_value=[])):
            await reset_user_password(
                target_id,
                AdminPasswordResetRequest(password=SecretStr("Testing-password-2026!")),
                session,
                admin,
            )

        refreshed = (await session.execute(select(User).where(User.id == target_id))).scalar_one()
        assert refreshed.session_version == 1
        assert verify_password("Testing-password-2026!", refreshed.password_hash)

    await engine.dispose()