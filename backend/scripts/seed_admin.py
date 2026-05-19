"""
Seed the first Super Admin user and all 8 default roles.
Run inside the api container after migrations:

  docker compose -f docker-compose.dev.yml exec api python scripts/seed_admin.py

Or with custom credentials:
  ADMIN_EMAIL=admin@company.com ADMIN_PASSWORD=MyPass123! python scripts/seed_admin.py
"""
import asyncio
import os
import sys

# Allow running from the /app directory inside Docker
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select
import uuid

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set")
    sys.exit(1)

ADMIN_EMAIL    = os.getenv("ADMIN_EMAIL",    "admin@governance.local")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "Admin1234!")
ADMIN_NAME     = os.getenv("ADMIN_NAME",     "Super Administrator")

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

DEFAULT_ROLES = [
    ("super_admin",        "Full access to all modules and settings"),
    ("data_governance_officer", "Manages governance policies and approvals"),
    ("compliance_officer", "Reviews and approves compliance-related items"),
    ("data_owner",         "Owns datasets and approves DSRs and BAPDs"),
    ("data_steward",       "Manages metadata and data quality for assigned domains"),
    ("dpo",                "Data Protection Officer — reviews DPIAs"),
    ("auditor",            "Read-only access to audit logs and reports"),
    ("regular_user",       "Basic access for project members"),
]

ROLE_PERMISSIONS = {
    "super_admin": [
        "projects:read","projects:create","projects:update","projects:delete",
        "dsr:read","dsr:create","dsr:update","dsr:delete",
        "dpia:read","dpia:create","dpia:update","dpia:delete",
        "ropa:read","ropa:create","ropa:update","ropa:delete",
        "bapd:read","bapd:create","bapd:update","bapd:delete",
        "dq:read","dq:create","dq:update",
        "metadata:read","metadata:create","metadata:update",
        "audit:read","rbac:read","rbac:update",
    ],
}


async def main():
    engine = create_async_engine(DATABASE_URL, echo=False)
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async with session_factory() as db:
        # 1. Seed roles
        from app.models.user import Role, User, UserProjectRole
        print("Seeding roles...")
        for role_name, desc in DEFAULT_ROLES:
            existing = (await db.execute(
                select(Role).where(Role.name == role_name)
            )).scalar_one_or_none()
            if not existing:
                db.add(Role(name=role_name, description=desc))
                print(f"  + role: {role_name}")
            else:
                print(f"  ✓ role exists: {role_name}")
        await db.commit()

        # 2. Create super admin user
        print(f"\nCreating admin user: {ADMIN_EMAIL}")
        existing_user = (await db.execute(
            select(User).where(User.email == ADMIN_EMAIL)
        )).scalar_one_or_none()

        if existing_user:
            print(f"  ✓ User already exists: {ADMIN_EMAIL}")
            user = existing_user
        else:
            user = User(
                id=uuid.uuid4(),
                full_name=ADMIN_NAME,
                email=ADMIN_EMAIL,
                password_hash=pwd_ctx.hash(ADMIN_PASSWORD),
                is_active=True,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            print(f"  + Created user: {ADMIN_EMAIL}")

        # 3. Assign super_admin role globally
        super_admin_role = (await db.execute(
            select(Role).where(Role.name == "super_admin")
        )).scalar_one_or_none()

        if super_admin_role:
            existing_assignment = (await db.execute(
                select(UserProjectRole).where(
                    UserProjectRole.user_id == user.id,
                    UserProjectRole.role_id == super_admin_role.id,
                    UserProjectRole.project_id == None,
                )
            )).scalar_one_or_none()

            if not existing_assignment:
                db.add(UserProjectRole(
                    user_id=user.id,
                    role_id=super_admin_role.id,
                    project_id=None,
                    assigned_by=user.id,
                ))
                await db.commit()
                print(f"  + Assigned super_admin role to {ADMIN_EMAIL}")
            else:
                print(f"  ✓ super_admin role already assigned")

    await engine.dispose()
    print("\n✅ Seed complete!")
    print(f"\n   Login URL : http://localhost:3000/login")
    print(f"   Email     : {ADMIN_EMAIL}")
    print(f"   Password  : {ADMIN_PASSWORD}")
    print("\n   ⚠  Change the password after first login!")


if __name__ == "__main__":
    asyncio.run(main())
