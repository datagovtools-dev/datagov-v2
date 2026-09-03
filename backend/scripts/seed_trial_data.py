"""
Seed trial project data: users, project PRJ-2026-001, DSR DSR-2026-0001,
DSR approvals, AI compliance checklist, and SME assignment.

Run inside the api container after seed_admin.py:
  docker compose exec api python scripts/seed_trial_data.py
"""
import asyncio
import os
import sys
import uuid
from datetime import date, datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import select

from app.config import get_settings

DATABASE_URL = os.getenv("DATABASE_URL", "") or get_settings().database_url
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set")
    sys.exit(1)

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

TRIAL_USERS = [
    {"full_name": "Ahmad Fauzi",        "email": "ahmad.fauzi@company.com"},
    {"full_name": "Bagas Adi Nugraha",  "email": "bagas.nugraha@company.com"},
    {"full_name": "Anisa Putri",        "email": "anisa.putri@company.com"},
    {"full_name": "Budi Santoso",       "email": "budi.santoso@company.com"},
    {"full_name": "Dewi Rahayu",        "email": "dewi.rahayu@company.com"},
    {"full_name": "Eko Prasetyo",       "email": "eko.prasetyo@company.com"},
    {"full_name": "Fitri Handayani",    "email": "fitri.handayani@company.com"},
]


async def main():
    engine = create_async_engine(DATABASE_URL, echo=False)
    session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async with session_factory() as db:
        from app.models.user import Role, User, UserProjectRole
        from app.models.project import Project
        from app.models.dsr import DataSharingRequest, DSRApproval, AIComplianceChecklist

        # ── 1. Create trial users ─────────────────────────────────────────────
        print("Creating trial users...")
        user_map: dict[str, User] = {}
        regular_role = (await db.execute(
            select(Role).where(Role.name == "regular_user")
        )).scalar_one_or_none()

        for u in TRIAL_USERS:
            existing = (await db.execute(
                select(User).where(User.email == u["email"])
            )).scalar_one_or_none()
            if existing:
                print(f"  [OK] exists: {u['full_name']}")
                user_map[u["full_name"]] = existing
            else:
                new_user = User(
                    id=uuid.uuid4(),
                    full_name=u["full_name"],
                    email=u["email"],
                    password_hash=pwd_ctx.hash("User1234!"),
                    is_active=True,
                )
                db.add(new_user)
                await db.flush()
                user_map[u["full_name"]] = new_user
                print(f"  + created: {u['full_name']}")

                if regular_role:
                    db.add(UserProjectRole(
                        user_id=new_user.id,
                        role_id=regular_role.id,
                        project_id=None,
                        assigned_by=new_user.id,
                    ))

        await db.commit()

        # ── 2. Get admin user (created_by) ────────────────────────────────────
        admin = (await db.execute(
            select(User).where(User.email == "admin@governance.local")
        )).scalar_one_or_none()
        if not admin:
            print("ERROR: admin user not found. Run seed_admin.py first.")
            return

        # Refresh user objects after commit
        for name in list(user_map.keys()):
            await db.refresh(user_map[name])

        dm  = user_map["Ahmad Fauzi"]
        pm  = user_map["Bagas Adi Nugraha"]
        dgo = user_map["Anisa Putri"]
        pic = user_map["Budi Santoso"]
        sme = user_map["Dewi Rahayu"]

        # ── 3. Create trial project ───────────────────────────────────────────
        print("\nCreating trial project PRJ-2026-001...")
        proj = (await db.execute(
            select(Project).where(Project.project_code == "PRJ-2026-001")
        )).scalar_one_or_none()

        if proj:
            print("  [OK] project exists")
            # Update sme_id if missing
            if proj.sme_id is None:
                proj.sme_id = sme.id
                await db.commit()
                print("  + sme_id assigned")
        else:
            proj = Project(
                id=uuid.uuid4(),
                project_code="PRJ-2026-001",
                project_name="AI-Powered Customer Analytics Platform",
                customer_name="PT Maju Bersama Digital",
                line_of_business="Digital Banking",
                use_case="Leverage generative AI to analyze customer transaction patterns and generate personalized financial insights.",
                project_year=2026,
                project_category="AI / Machine Learning",
                is_monetized=True,
                start_date=date(2026, 1, 15),
                end_date=date(2026, 12, 31),
                sme_id=sme.id,
                delivery_manager_id=dm.id,
                project_manager_id=pm.id,
                dgo_id=dgo.id,
                metadata_officer_id=dgo.id,
                dq_officer_id=dgo.id,
                pic_data_compliance_id=pic.id,
                created_by=admin.id,
            )
            db.add(proj)
            await db.commit()
            await db.refresh(proj)
            print("  + created")

        # ── 4. Create DSR ─────────────────────────────────────────────────────
        print("\nCreating trial DSR DSR-2026-0001...")
        dsr = (await db.execute(
            select(DataSharingRequest).where(DataSharingRequest.tracking_id == "DSR-2026-0001")
        )).scalar_one_or_none()

        if dsr:
            print("  [OK] DSR exists")
        else:
            dsr = DataSharingRequest(
                id=uuid.uuid4(),
                tracking_id="DSR-2026-0001",
                project_id=proj.id,
                requester_id=pm.id,
                dataset_name="Customer Transaction Dataset Q1-2026",
                recipient="PT Maju Bersama Digital",
                purpose="Train and validate generative AI models for personalized financial insight generation.",
                is_ai_use=True,
                duration_start=date(2026, 2, 1),
                duration_end=date(2026, 12, 31),
                status="approved",
            )
            db.add(dsr)
            await db.commit()
            await db.refresh(dsr)
            print("  + created")

        # ── 5. Create DSR approvals ───────────────────────────────────────────
        print("\nCreating DSR approvals...")
        existing_approvals = (await db.execute(
            select(DSRApproval).where(DSRApproval.dsr_id == dsr.id)
        )).scalars().all()

        if existing_approvals:
            print("  [OK] approvals exist")
        else:
            approval_steps = [
                (dm.id,  "Delivery Manager",            1, "approved", "Reviewed and approved. Data usage aligns with project scope."),
                (dgo.id, "Data Governance Officer",     2, "approved", "Approved. Governance policies compliant."),
                (pic.id, "PIC Data Compliance",         3, "approved", "Approved. Compliance requirements satisfied."),
            ]
            for approver_id, role_label, step, status, comment in approval_steps:
                db.add(DSRApproval(
                    id=uuid.uuid4(),
                    dsr_id=dsr.id,
                    approver_id=approver_id,
                    approver_role=role_label,
                    step_order=step,
                    status=status,
                    comments=comment,
                    actioned_at=datetime.now(timezone.utc),
                ))
            await db.commit()
            print("  + 3 approval steps created")

        # ── 6. Create AI compliance checklist ─────────────────────────────────
        print("\nCreating AI compliance checklist...")
        checklist = (await db.execute(
            select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr.id)
        )).scalar_one_or_none()

        if checklist:
            print("  [OK] checklist exists")
        else:
            checklist = AIComplianceChecklist(
                id=uuid.uuid4(),
                dsr_id=dsr.id,
                checklist_json={},
            )
            db.add(checklist)
            await db.commit()
            print("  + created (empty — fill via UI)")

    await engine.dispose()
    print("\n[OK] Trial data seed complete!")
    print(f"\n   Project  : PRJ-2026-001")
    print(f"   DSR      : DSR-2026-0001 (is_ai_use=True)")
    print(f"   SME      : {sme.full_name} ({sme.email})")
    print(f"   DM       : {dm.full_name} ({dm.email})")
    print(f"   PM       : {pm.full_name} ({pm.email})")
    print(f"\n   All user passwords: User1234!")


if __name__ == "__main__":
    asyncio.run(main())
