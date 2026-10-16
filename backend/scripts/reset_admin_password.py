"""Interactively reset the seeded admin password without exposing it to shell args.

Run inside the API container:
  docker exec -it ag_api python scripts/reset_admin_password.py
"""
import asyncio
import getpass
import os
import sys
from datetime import datetime, timezone

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Allow running from the /app directory inside Docker.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.config import get_settings
from app.core.security import hash_password
from app.models.user import Role, User, UserProjectRole


async def main() -> None:
    email = os.getenv("ADMIN_EMAIL", "admin@governance.local").strip()
    password = getpass.getpass("New admin password (hidden): ")
    confirmation = getpass.getpass("Confirm new admin password (hidden): ")

    if len(password) < 12 or len(password) > 128:
        raise SystemExit("ERROR: password must be 12-128 characters")
    if password != confirmation:
        raise SystemExit("ERROR: passwords do not match")

    settings = get_settings()
    engine = create_async_engine(settings.database_url, echo=False)
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    try:
        async with session_factory() as db:
            user = (await db.execute(select(User).where(User.email == email))).scalar_one_or_none()
            if not user:
                raise SystemExit("ERROR: admin user not found")

            result = await db.execute(
                update(User)
                .where(User.id == user.id)
                .values(
                    password_hash=hash_password(password),
                    session_version=func.coalesce(User.session_version, 0) + 1,
                )
                .returning(User.session_version)
            )
            new_version = result.scalar_one()

            super_admin = (await db.execute(
                select(Role).where(Role.name == "super_admin")
            )).scalar_one_or_none()
            if not super_admin:
                raise SystemExit("ERROR: super_admin role not found")

            active_assignments = (await db.execute(
                select(UserProjectRole)
                .where(
                    UserProjectRole.user_id == user.id,
                    UserProjectRole.role_id == super_admin.id,
                    UserProjectRole.project_id.is_(None),
                    UserProjectRole.revoked_at.is_(None),
                )
                .order_by(UserProjectRole.assigned_at, UserProjectRole.id)
            )).scalars().all()

            for duplicate in active_assignments[1:]:
                duplicate.revoked_at = datetime.now(timezone.utc)
            if not active_assignments:
                db.add(UserProjectRole(
                    user_id=user.id,
                    role_id=super_admin.id,
                    project_id=None,
                    assigned_by=user.id,
                ))

            await db.commit()
            print(f"[OK] Admin password reset for {email}; session_version={new_version}")
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
