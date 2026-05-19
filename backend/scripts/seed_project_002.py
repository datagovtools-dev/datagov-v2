"""Seed PRJ-2026-002 project record."""
import asyncio, os, sys, uuid
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set"); sys.exit(1)

# Team member IDs from existing users
AHMAD_FAUZI      = "13c686f6-db44-4585-b9f1-6c6200aac025"  # Senior Delivery Manager
BAGAS            = "9af488f8-db30-4b90-a672-c1ec50f45c85"  # Project Manager
DEWI_RAHAYU      = "4aa61e37-f659-44ae-810b-41d4ac793b26"  # Senior Data Scientist (SME)
ANISA_PUTRI      = "c8cf883c-330c-46c0-b023-3629c2f99a69"  # Data Governance Officer
EKO_PRASETYO     = "facd7d45-6237-46a9-8015-507fe266c7ff"  # Data Analyst (Metadata Officer)
FITRI_HANDAYANI  = "19d275fc-8c44-4411-a412-92a85834759b"  # AI Engineer (DQ Officer)
BUDI_SANTOSO     = "1b6e6cdf-4700-4914-81cf-29f7e768c523"  # Data Compliance Officer

async def main():
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
    from sqlalchemy import text

    engine  = create_async_engine(DATABASE_URL, echo=False)
    factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async with factory() as db:
        existing = (await db.execute(
            text("SELECT id FROM projects WHERE project_code = 'PRJ-2026-002'")
        )).scalar_one_or_none()

        if existing:
            print("PRJ-2026-002 already exists — skipping.")
        else:
            await db.execute(text("""
                INSERT INTO projects (
                    id, project_code, project_name, customer_name,
                    line_of_business, use_case, project_category,
                    project_year, start_date, end_date, is_monetized,
                    delivery_manager_id, project_manager_id, sme_id,
                    dgo_id, metadata_officer_id, dq_officer_id, pic_data_compliance_id,
                    created_by, created_at, updated_at
                ) VALUES (
                    :id, 'PRJ-2026-002', 'Smart Credit Risk Analytics Platform', 'PT Finansial Nusantara',
                    'Financial Services',
                    'Develop an AI-powered credit risk scoring model leveraging customer financial behaviour, transaction history, and external credit bureau data to improve loan approval accuracy and reduce default rates across retail banking portfolios.',
                    'AI / Machine Learning',
                    2026, '2026-03-01', '2026-12-31', true,
                    :dm, :pm, :sme,
                    :dgo, :mo, :dqo, :pic,
                    :created_by, '2026-03-01 08:00:00+07', '2026-03-01 08:00:00+07'
                )
            """), {
                "id":         str(uuid.uuid4()),
                "dm":         AHMAD_FAUZI,
                "pm":         BAGAS,
                "sme":        DEWI_RAHAYU,
                "dgo":        ANISA_PUTRI,
                "mo":         EKO_PRASETYO,
                "dqo":        FITRI_HANDAYANI,
                "pic":        BUDI_SANTOSO,
                "created_by": AHMAD_FAUZI,
            })
            await db.commit()
            print("✅ PRJ-2026-002 created successfully.")
            print("   Project Name : Smart Credit Risk Analytics Platform")
            print("   Customer     : PT Finansial Nusantara")
            print("   Category     : AI / Machine Learning")
            print("   Timeline     : 01 Mar 2026 – 31 Dec 2026")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(main())
