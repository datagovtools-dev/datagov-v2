"""Seed Data & Insights Sharing Evaluation Checklist for DSR-2026-0002 (Smart Credit Risk Analytics Platform)."""
import asyncio, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set"); sys.exit(1)

DSR_ID = "5f8cf746-6035-447a-9cfa-3694bd423aaa"

CHECKLIST = {
    # ── Section A: Interest Protection ────────────────────────────────────────
    "A_i_1": {"answer": "No",  "remarks": "Credit risk data is used for internal analytics only; no revenue cannibalization risk identified."},
    "A_i_2": {"answer": "No",  "remarks": "Data is pseudonymized before sharing; customer identity is protected throughout the process."},
    "A_i_3": {"answer": "No",  "remarks": "No other commercial interest risks have been identified for this data sharing request."},
    "A_ii_1": {"answer": "No", "remarks": "No highly confidential partnership information is included in the requested dataset."},
    "A_ii_2": {"answer": "No", "remarks": "Dataset contains transactional and behavioural data only; no patent-related information involved."},
    "A_ii_3": {"answer": "No", "remarks": "No merger or acquisition information is included in the scope of this data sharing."},
    "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets identified within the requested credit data dataset."},

    # ── Section B: Customer Data & Insights Sharing Consent ───────────────────
    "B_i":  {"answer": "Yes", "remarks": "Dataset includes customer financial behaviour and transaction history, classified as sensitive personal financial data under UU PDP."},
    "B_ii": {"answer": "Yes", "remarks": "Data is pseudonymized and aggregated prior to sharing. PII fields are masked and access is restricted to the authorized analytics team only."},
    "B_iii":{"answer": "Yes", "remarks": "Transaction records and credit history contain personal financial data subject to the Personal Data Protection Law (UU PDP No. 27/2022)."},
    "B_iv": {"answer": "Yes", "remarks": "Written consent has been obtained through customer onboarding agreements and terms of service covering data use in credit risk assessment."},
    "B_v":  {"answer": "Yes", "remarks": "Customer consent for AI/ML model development is covered under the digital banking service agreement signed at account opening."},
    "B_vi": {"answer": "Yes", "remarks": "All data processing is conducted within PT Finansial Nusantara's secured analytics environment with role-based access controls and audit logging."},

    # ── Section C: Regulatory Compliance ──────────────────────────────────────
    "C_i_1": {"answer": "No", "remarks": "OJK regulations on credit scoring and data sharing have been reviewed; this request complies with applicable banking sector regulations."},
    "C_i_2": {"answer": "No", "remarks": "Data sharing is compliant with UU PDP No. 27 of 2022; appropriate technical and organisational safeguards are in place."},
    "C_i_3": {"answer": "No", "remarks": "Internal data governance policy and data sharing SOP have been reviewed; this request is fully compliant with internal regulations."},

    # ── Section D: AI Compliance ───────────────────────────────────────────────
    "D_i": {"answer": "Yes", "remarks": "The credit risk scoring model utilises gradient boosting machine learning algorithms to predict default probability based on customer transaction patterns and financial behaviour data."},

    # ── Sign Off ───────────────────────────────────────────────────────────────
    "sign_off": {
        "approved":               "Yes",
        "prepared_by":            "Dian Pratiwi",
        "prepared_position":      "Head of Analytics",
        "prepared_date":          "",
        "prepared_signature":     "",
        "acknowledged_by":        "Dewi Rahayu",
        "acknowledged_position":  "Senior Data Scientist",
        "acknowledged_date":      "",
        "acknowledged_signature": "",
        "remarks":                "All data governance requirements have been reviewed and verified. This data sharing is approved for credit risk model development purposes only.",
    },
}


async def main():
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
    from sqlalchemy import text

    engine  = create_async_engine(DATABASE_URL, echo=False)
    factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

    async with factory() as db:
        await db.execute(
            text("UPDATE ai_compliance_checklists SET checklist_json = :j WHERE dsr_id = :dsr_id"),
            {"j": json.dumps(CHECKLIST), "dsr_id": DSR_ID},
        )
        await db.commit()
        print("✅ Checklist seeded for DSR-2026-0002.")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
