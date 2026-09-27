"""Create a read-only viewer user and ensure the viewer role exists in the DB."""
import asyncio, os, sys, uuid
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set"); sys.exit(1)

VIEWER_EMAIL    = os.getenv("VIEWER_EMAIL",    "viewer@governance.local")
VIEWER_PASSWORD = os.getenv("VIEWER_PASSWORD", "Viewer1234!")
VIEWER_NAME     = os.getenv("VIEWER_NAME",     "Read-Only Viewer")
VIEWER_POSITION = os.getenv("VIEWER_POSITION", "Internal Auditor")  # job title in the company

async def main():
    from passlib.context import CryptContext
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
    from sqlalchemy import select
    from app.models.user import Role, User, UserProjectRole

    pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")
    engine  = create_async_engine(DATABASE_URL, echo=False)
    factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async with factory() as db:
        # 1. Ensure viewer role exists
        viewer_role = (await db.execute(select(Role).where(Role.name == "viewer"))).scalar_one_or_none()
        if not viewer_role:
            viewer_role = Role(name="viewer", description="Read-only access to all modules")
            db.add(viewer_role)
            await db.commit()
            await db.refresh(viewer_role)
            print("  + Created role: viewer")
        else:
            print("  ✓ Role exists: viewer")

        # 2. Create viewer user
        user = (await db.execute(select(User).where(User.email == VIEWER_EMAIL))).scalar_one_or_none()
        if not user:
            user = User(
                id=uuid.uuid4(),
                full_name=VIEWER_NAME,
                email=VIEWER_EMAIL,
                position=VIEWER_POSITION,
                password_hash=pwd_ctx.hash(VIEWER_PASSWORD),
                is_active=True,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            print(f"  + Created user: {VIEWER_EMAIL}")
        else:
            print(f"  ✓ User exists: {VIEWER_EMAIL}")

        # 3. Assign viewer role (global, no project scope)
        existing = (await db.execute(
            select(UserProjectRole).where(
                UserProjectRole.user_id == user.id,
                UserProjectRole.role_id == viewer_role.id,
                UserProjectRole.project_id == None,
            )
        )).scalar_one_or_none()

        if not existing:
            db.add(UserProjectRole(user_id=user.id, role_id=viewer_role.id, project_id=None, assigned_by=user.id))
            await db.commit()
            print(f"  + Assigned viewer role to {VIEWER_EMAIL}")
        else:
            print(f"  ✓ viewer role already assigned")

    await engine.dispose()
    print("\n✅ Viewer account ready.")
    print(f"   Email    : {VIEWER_EMAIL}")
    print(f"   Password : {VIEWER_PASSWORD}")

if __name__ == "__main__":
    asyncio.run(main())
