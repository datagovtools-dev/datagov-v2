from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, MappedColumn
from sqlalchemy import MetaData
from sqlalchemy.pool import NullPool
from app.config import get_settings

settings = get_settings()

engine_options = {
    "pool_pre_ping": True,
    "echo": settings.debug,
}

if settings.database_null_pool:
    engine_options["poolclass"] = NullPool
else:
    engine_options["pool_size"] = 10
    engine_options["max_overflow"] = 20

engine = create_async_engine(settings.database_url, **engine_options)

AsyncSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


async def get_db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
