"""Seed AI Assessment checklist items for DSR-2026-0001."""
import asyncio, json, os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set"); sys.exit(1)

DSR_ID = "4a6f596c-dcef-437c-bfa1-c777e0db5e6c"

AI_ASSESSMENT = {
    "items": {
        "before_use_1": {
            "status": "Yes",
            "remarks": "The platform has been reviewed against OJK regulations, UU PDP No. 27/2022, and internal AI Ethics & Governance Policy. Legal and compliance sign-off obtained prior to project initiation.",
        },
        "before_use_2": {
            "status": "Yes",
            "remarks": "The generative AI platform used for financial insight generation is officially licensed and has received formal written approval from the Chief Technology Officer and Head of Digital Innovation.",
        },
        "before_use_3": {
            "status": "Yes",
            "remarks": "Platform settings have been configured to disable interaction history logging. The team has opted out of all model training data-sharing options provided by the Gen AI service provider.",
        },
        "input_1": {
            "status": "Yes",
            "remarks": "Customer transaction data is fully anonymised and tokenised before being used as AI model input. No raw PII — names, account numbers, phone numbers — is included in any prompt or model input.",
        },
        "input_2": {
            "status": "Yes",
            "remarks": "All data inputs to the Gen AI pipeline are pseudonymised. Customer identifiers are replaced with internal tokens, and synthetic dummy data is used during model exploration and testing phases.",
        },
        "input_3": {
            "status": "Yes",
            "remarks": "All prompts are reviewed by the AI Engineer and Data Scientist before use. Prompt templates are documented in the project repository under /docs/prompt-log.txt and versioned accordingly.",
        },
        "output_1": {
            "status": "Yes",
            "remarks": "All AI-generated financial insights are reviewed and validated by the Subject Matter Expert (Dewi Rahayu) before being surfaced to end users. A validation checklist is applied to each output batch to check for hallucinations, bias, or inaccuracies.",
        },
        "output_2": {
            "status": "Yes",
            "remarks": "Any source code generated or assisted by Gen AI undergoes mandatory peer review by a senior developer, security static analysis scanning, and functional testing before integration into the customer analytics platform.",
        },
        "utilization_1": {
            "status": "Yes",
            "remarks": "AI-generated insights and recommendations are only released after independent assessment and sign-off by the authorised SME. A review checklist is used to confirm outputs are ready for customer-facing use.",
        },
        "utilization_2": {
            "status": "Yes",
            "remarks": "A feedback and correction loop is in place. Inaccurate or inappropriate AI outputs are flagged, corrected, and logged in the incident register before any distribution to customers or stakeholders.",
        },
    },
    "sign_off": {
        "approved": "Yes",
        "prepared_by": "Ahmad Fauzi",
        "prepared_position": "Senior Delivery Manager",
        "acknowledged_by": "Dewi Rahayu",
        "acknowledged_position": "Senior Data Scientist",
    },
}


async def main() -> None:
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
    from sqlalchemy import text

    engine = create_async_engine(DATABASE_URL, echo=False)
    async with async_sessionmaker(engine, class_=AsyncSession)() as db:
        row = await db.execute(
            text("SELECT checklist_json FROM ai_compliance_checklists WHERE dsr_id = :dsr_id"),
            {"dsr_id": DSR_ID},
        )
        existing = row.scalar_one()
        existing["ai_assessment"] = AI_ASSESSMENT
        await db.execute(
            text("UPDATE ai_compliance_checklists SET checklist_json = :j WHERE dsr_id = :dsr_id"),
            {"j": json.dumps(existing), "dsr_id": DSR_ID},
        )
        await db.commit()
        print("AI assessment seeded successfully.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
