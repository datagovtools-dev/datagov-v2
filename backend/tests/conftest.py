"""Shared pytest fixtures for unit and integration tests."""
import asyncio
import itertools
import os
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from sqlalchemy.pool import StaticPool

# In-memory SQLite for tests; override with TEST_DATABASE_URL (e.g. a SQLite file)
TEST_DB_URL = os.getenv("TEST_DATABASE_URL", "sqlite+aiosqlite:///:memory:")

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def engine():
    eng = create_async_engine(
        TEST_DB_URL,
        echo=False,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    import app.models  # noqa: F401 - ensure all tables are registered
    from app.database import Base
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await eng.dispose()


@pytest_asyncio.fixture
async def db(engine) -> AsyncGenerator[AsyncSession, None]:
    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    async with session_factory() as session:
        yield session
        await session.rollback()


from unittest.mock import patch

@pytest.fixture(autouse=True)
def mock_notifications():
    with patch("app.worker.tasks.notifications.send_workflow_notification.delay") as mock_delay:
        yield mock_delay

@pytest_asyncio.fixture
async def client(engine) -> AsyncGenerator[AsyncClient, None]:
    from app.main import app
    from app.core.deps import get_db
    from sqlalchemy.ext.asyncio import async_sessionmaker

    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    async def override_get_db():
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def auth_user(db: AsyncSession):
    import uuid
    from sqlalchemy import select
    from app.models.user import User, Role, UserProjectRole
    from app.core.security import hash_password

    res = await db.execute(select(Role).where(Role.name == "super_admin"))
    role = res.scalar_one_or_none()
    if not role:
        role = Role(id=1, name="super_admin", description="Super Admin", permissions=["*"])
        db.add(role)
        await db.flush()

    user_id = uuid.uuid4()
    user = User(
        id=user_id,
        full_name="Admin Test",
        email=f"admin_{user_id.hex[:6]}@vibecode.id",
        password_hash=hash_password("adminpassword"),
        position="Lead Architect",
        is_active=True,
    )
    db.add(user)
    await db.flush()

    upr = UserProjectRole(
        user_id=user.id,
        role_id=role.id,
        assigned_by=user.id,
    )
    db.add(upr)
    await db.commit()
    return user


@pytest_asyncio.fixture
async def auth_headers(auth_user) -> dict[str, str]:
    from app.core.security import create_access_token
    token = create_access_token(str(auth_user.id), roles=["superadmin"])
    return {"Authorization": f"Bearer {token}"}


_project_seq = itertools.count(1)


@pytest_asyncio.fixture
async def test_project(db: AsyncSession, auth_user):
    from datetime import date, timedelta
    from app.models.project import Project

    proj = Project(
        project_code=f"PRJ-2026-{next(_project_seq):03d}",  # valid PRJ-YYYY-NNN, unique per test
        customer_name="Test Customer PT",
        line_of_business="Enterprise Digital",
        project_name="AI Governance Suite Project",
        use_case="Data Governance & AI Compliance Testing",
        project_year=2026,
        project_category="Internal",
        is_monetized=False,
        start_date=date.today(),
        end_date=date.today() + timedelta(days=365),
        sme_id=auth_user.id,
        delivery_manager_id=auth_user.id,
        project_manager_id=auth_user.id,
        dgo_id=auth_user.id,
        metadata_officer_id=auth_user.id,
        dq_officer_id=auth_user.id,
        pic_data_compliance_id=auth_user.id,
        created_by=auth_user.id,
    )
    db.add(proj)
    await db.commit()
    await db.refresh(proj)
    return proj
