"""
One-off script: rebuild approval steps for DSR-2026-0001 so all 4 steps
appear as Approved (matching its Signed & Locked state).

Run from backend/: python -m scripts.fix_trial_dsr_approvals
"""
import asyncio, sys, os
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from sqlalchemy import select, delete
from app.database import AsyncSessionLocal
from app.models.dsr import DataSharingRequest, DSRApproval
from app.models.user import User

TRACKING_ID = "DSR-2026-0001"

STEPS = [
    (1, "data_governance_officer"),
    (2, "dm_pm"),
    (3, "sme"),
    (4, "client"),
]

NOW = datetime.now(timezone.utc)


async def main():
    async with AsyncSessionLocal() as db:
        dsr = (await db.execute(
            select(DataSharingRequest).where(DataSharingRequest.tracking_id == TRACKING_ID)
        )).scalar_one_or_none()

        if not dsr:
            print(f"DSR {TRACKING_ID} not found.")
            return

        # Use the first active user as the approver for all steps
        approver = (await db.execute(
            select(User).where(User.is_active == True).limit(1)
        )).scalar_one_or_none()

        if not approver:
            print("No active users found.")
            return

        # Remove existing steps
        await db.execute(delete(DSRApproval).where(DSRApproval.dsr_id == dsr.id))
        print(f"Cleared existing approval steps for {TRACKING_ID}")

        # Insert 4 approved steps
        for step_order, role in STEPS:
            db.add(DSRApproval(
                dsr_id=dsr.id,
                approver_id=approver.id,
                approver_role=role,
                step_order=step_order,
                status="approved",
                actioned_at=NOW,
                comments=None,
            ))
            print(f"  Step {step_order} ({role}) → Approved by {approver.full_name}")

        await db.commit()
        print(f"\nDone. {TRACKING_ID} now has 4 approved steps.")


asyncio.run(main())
