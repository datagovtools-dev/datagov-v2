import logging

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, MappedColumn, Session, sessionmaker
from sqlalchemy import MetaData, create_engine, event, inspect
from sqlalchemy.pool import StaticPool
from app.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()


def _set_sqlite_pragmas(dbapi_conn, _record) -> None:
    # WAL + busy timeout let the API and the Celery worker share one SQLite file
    cursor = dbapi_conn.cursor()
    cursor.execute("PRAGMA journal_mode=WAL")
    cursor.execute("PRAGMA busy_timeout=30000")
    cursor.close()


db_url = settings.database_url
engine_options = {
    "echo": settings.debug,
    "connect_args": {"check_same_thread": False, "timeout": 30},
}
if ":memory:" in db_url:
    engine_options["poolclass"] = StaticPool

engine = create_async_engine(db_url, **engine_options)
if ":memory:" not in db_url:
    event.listen(engine.sync_engine, "connect", _set_sqlite_pragmas)

AsyncSessionLocal = async_sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

_sync_sessionmaker: sessionmaker[Session] | None = None


def get_sync_session() -> Session:
    """Synchronous ORM session for Celery tasks and maintenance scripts."""
    global _sync_sessionmaker
    if _sync_sessionmaker is None:
        import app.models  # noqa: F401  (register all mappers)

        sync_engine = create_engine(
            settings.database_url_sync, connect_args={"check_same_thread": False, "timeout": 30}
        )
        event.listen(sync_engine, "connect", _set_sqlite_pragmas)
        _sync_sessionmaker = sessionmaker(sync_engine, expire_on_commit=False)
    return _sync_sessionmaker()

NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=NAMING_CONVENTION)


_AUDIT_LOG_TRIGGERS = (
    (
        "CREATE TRIGGER IF NOT EXISTS tg_audit_logs_no_update BEFORE UPDATE ON audit_logs "
        "BEGIN SELECT RAISE(ABORT, 'audit_logs rows are immutable'); END"
    ),
    (
        "CREATE TRIGGER IF NOT EXISTS tg_audit_logs_no_delete BEFORE DELETE ON audit_logs "
        "BEGIN SELECT RAISE(ABORT, 'audit_logs rows are immutable'); END"
    ),
)


def sync_schema(conn) -> None:
    """Bring an existing SQLite database up to the current models (run after create_all).

    create_all only creates missing tables, so model columns added later are
    added here with ALTER TABLE ADD COLUMN. SQLite cannot add a NOT NULL column
    without a default, so new columns are added as nullable; type changes,
    renames and drops still need a manual script.
    """
    inspector = inspect(conn)
    for table in Base.metadata.sorted_tables:
        if not inspector.has_table(table.name):
            continue
        existing = {column["name"] for column in inspector.get_columns(table.name)}
        for column in table.columns:
            if column.name in existing:
                continue
            column_type = column.type.compile(dialect=conn.dialect)
            conn.exec_driver_sql(f'ALTER TABLE "{table.name}" ADD COLUMN "{column.name}" {column_type}')
            logger.warning("Schema sync: added column %s.%s (%s)", table.name, column.name, column_type)
    for ddl in _AUDIT_LOG_TRIGGERS:
        conn.exec_driver_sql(ddl)


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
