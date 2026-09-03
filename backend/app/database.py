from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, MappedColumn
from sqlalchemy import MetaData
from sqlalchemy.pool import NullPool, StaticPool
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import JSONB, UUID, ARRAY, INET
from app.config import get_settings

@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"

@compiles(UUID, "sqlite")
def compile_uuid_sqlite(type_, compiler, **kw):
    return "VARCHAR(36)"

@compiles(ARRAY, "sqlite")
def compile_array_sqlite(type_, compiler, **kw):
    return "JSON"

@compiles(INET, "sqlite")
def compile_inet_sqlite(type_, compiler, **kw):
    return "VARCHAR(45)"

settings = get_settings()

engine_options = {
    "echo": settings.debug,
}

db_url = settings.database_url.replace("@localhost:", "@127.0.0.1:")

if "sqlite" in db_url:
    engine_options["connect_args"] = {"check_same_thread": False}
    if ":memory:" in db_url:
        engine_options["poolclass"] = StaticPool
else:
    engine_options["pool_pre_ping"] = True
    if settings.database_null_pool:
        engine_options["poolclass"] = NullPool
    else:
        engine_options["pool_size"] = 10
        engine_options["max_overflow"] = 20

engine = create_async_engine(db_url, **engine_options)

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
