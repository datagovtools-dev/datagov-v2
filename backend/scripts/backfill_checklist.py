import asyncio
import sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from app.database import AsyncSessionLocal
from app.models.dsr import DataSharingRequest, AIComplianceChecklist
from sqlalchemy import select

async def main():
    async with AsyncSessionLocal() as db:
        dsrs = (await db.execute(select(DataSharingRequest))).scalars().all()
        for dsr in dsrs:
            exists = (await db.execute(
                select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr.id)
            )).scalar_one_or_none()
            if not exists:
                db.add(AIComplianceChecklist(dsr_id=dsr.id, checklist_json={}))
                print(f"Created checklist for {dsr.tracking_id}")
            else:
                print(f"Checklist already exists for {dsr.tracking_id}")
        await db.commit()

asyncio.run(main())
