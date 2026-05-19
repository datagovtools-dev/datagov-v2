"""Seed AI checklist approval stubs for existing DSR records (DSR-2026-0001, DSR-2026-0002).
Run once after migration d1e2f3a4b5c6 to backfill approval rows for pre-existing checklists.
"""
import asyncio, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set"); sys.exit(1)


async def main():
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
    from sqlalchemy import text

    engine = create_async_engine(DATABASE_URL, echo=False)
    factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async with factory() as db:
        # Find all AI checklists that have no approval stubs yet
        rows = (await db.execute(text("""
            SELECT acc.id AS checklist_id, dsr.project_id, dsr.requester_id
            FROM ai_compliance_checklists acc
            JOIN data_sharing_requests dsr ON dsr.id = acc.dsr_id
            WHERE NOT EXISTS (
                SELECT 1 FROM ai_checklist_approvals aca WHERE aca.checklist_id = acc.id
            )
        """))).fetchall()

        if not rows:
            print("No checklists without approval stubs found — nothing to seed.")
            await engine.dispose()
            return

        for row in rows:
            checklist_id = row.checklist_id
            project_id = row.project_id
            requester_id = row.requester_id

            # Get project team members
            proj = (await db.execute(text("""
                SELECT pic_data_compliance_id, delivery_manager_id, sme_id
                FROM projects WHERE id = :pid
            """), {"pid": project_id})).fetchone()

            steps = [
                (1, "pic_compliance", proj.pic_data_compliance_id if proj else requester_id),
                (2, "dm",             proj.delivery_manager_id    if proj else requester_id),
                (3, "sme",            proj.sme_id                 if proj else requester_id),
            ]

            for step_order, role, approver_id in steps:
                await db.execute(text("""
                    INSERT INTO ai_checklist_approvals
                        (id, checklist_id, approver_id, approver_role, step_order, status)
                    VALUES
                        (gen_random_uuid(), :cid, :aid, :role, :step, 'pending')
                """), {
                    "cid":  checklist_id,
                    "aid":  approver_id or requester_id,
                    "role": role,
                    "step": step_order,
                })

            print(f"  ✅ Seeded approval stubs for checklist {checklist_id}")

        await db.commit()
        print(f"Done — seeded {len(rows)} checklist(s).")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
