import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.database import Base
from app.models.user import User
from app.services.init_db import seed_initial_data_if_needed


@pytest.mark.asyncio
async def test_seed_preserves_disabled_existing_user():
    engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    import app.models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    sessions = async_sessionmaker(engine, expire_on_commit=False)
    async with sessions() as session:
        await seed_initial_data_if_needed(session)
        user = (await session.execute(
            select(User).where(User.email == "admin@governance.local")
        )).scalar_one()
        user.is_active = False
        await session.commit()

    async with sessions() as session:
        await seed_initial_data_if_needed(session)
        user = (await session.execute(
            select(User).where(User.email == "admin@governance.local")
        )).scalar_one()
        assert user.is_active is False

    await engine.dispose()