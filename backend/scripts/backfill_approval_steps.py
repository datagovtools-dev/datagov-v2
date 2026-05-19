"""
Backfill approval steps for existing DSRs using role assignments from UserProjectRole.
Run: python -m scripts.backfill_approval_steps
"""
import asyncio
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from sqlalchemy import select
from app.database import AsyncSessionLocal
from app.models.dsr import DataSharingRequest, DSRApproval
from app.models.user import Role, User, UserProjectRole

APPROVAL_ROLES = ["data_governance_officer", "dm_pm", "sme", "client"]


async def find_approver(db, role_name: str, project_id, fallback_id):
    result = await db.execute(
        select(UserProjectRole.user_id)
        .join(Role, UserProjectRole.role_id == Role.id)
        .where(
            Role.name == role_name,
            UserProjectRole.project_id == project_id,
            UserProjectRole.revoked_at.is_(None),
        )
        .limit(1)
    )
    uid = result.scalar_one_or_none()
    return uid if uid else fallback_id


async def main():
    async with AsyncSessionLocal() as db:
        # Get a fallback user (first active user)
        fallback = (await db.execute(
            select(User).where(User.is_active == True).limit(1)
        )).scalar_one_or_none()
        if not fallback:
            print("No users found — aborting.")
            return

        dsrs = (await db.execute(select(DataSharingRequest))).scalars().all()
        for dsr in dsrs:
            existing = (await db.execute(
                select(DSRApproval).where(DSRApproval.dsr_id == dsr.id)
            )).scalars().all()

            existing_steps = {a.step_order for a in existing}

            for step, role in enumerate(APPROVAL_ROLES, 1):
                if step in existing_steps:
                    # Update approver_role to new naming in case it's stale
                    for a in existing:
                        if a.step_order == step:
                            a.approver_role = role
                    print(f"  Updated role for step {step} of {dsr.tracking_id}")
                else:
                    approver_id = await find_approver(db, role, dsr.project_id, fallback.id)
                    db.add(DSRApproval(
                        dsr_id=dsr.id,
                        approver_id=approver_id,
                        approver_role=role,
                        step_order=step,
                    ))
                    print(f"  Added step {step} ({role}) for {dsr.tracking_id}")

        await db.commit()
        print("Done.")


asyncio.run(main())
