"""Seed DSR-2026-0001 checklist with pre-filled answers and signatures."""
import asyncio, base64, json, os, struct, sys, zlib

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DATABASE_URL = os.getenv("DATABASE_URL", "")
if not DATABASE_URL:
    print("ERROR: DATABASE_URL not set"); sys.exit(1)

DSR_ID = "4a6f596c-dcef-437c-bfa1-c777e0db5e6c"


def make_sig(strokes: list) -> str:
    w, h = 300, 56
    pixels = [[255, 255, 255] for _ in range(w * h)]
    for i in range(len(strokes) - 1):
        x0, y0 = strokes[i]; x1, y1 = strokes[i + 1]
        steps = max(abs(x1 - x0), abs(y1 - y0), 1) * 2
        for t in range(steps + 1):
            x = int(x0 + (x1 - x0) * t / steps)
            y = int(y0 + (y1 - y0) * t / steps)
            for dx in range(-1, 2):
                for dy in range(-1, 2):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        pixels[ny * w + nx] = [30, 41, 59]

    def ck(name: bytes, data: bytes) -> bytes:
        c = name + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    raw = b"".join(
        b"\x00" + bytes([v for px in pixels[r * w:(r + 1) * w] for v in px])
        for r in range(h)
    )
    png = (
        b"\x89PNG\r\n\x1a\n"
        + ck(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
        + ck(b"IDAT", zlib.compress(raw))
        + ck(b"IEND", b"")
    )
    return "data:image/png;base64," + base64.b64encode(png).decode()


sig_prepared = make_sig([
    (15,35),(25,20),(40,38),(60,18),(80,32),(100,22),
    (125,38),(150,25),(175,18),(195,30),(210,22),(230,35),(250,20),(270,30),(285,25),
])
sig_acknowledged = make_sig([
    (15,28),(30,38),(50,18),(70,35),(90,20),(110,32),
    (135,22),(155,38),(175,25),(200,18),(220,30),(240,22),(260,35),(280,28),(295,32),
])

CHECKLIST = {
    "A_i_1":  {"answer": "No",  "remarks": "No revenue cannibalization risk; data is used solely for internal AI model development."},
    "A_i_2":  {"answer": "No",  "remarks": "Data is anonymised prior to use; no direct customer relationship impact."},
    "A_i_3":  {"answer": "No",  "remarks": "No other commercial interests identified."},
    "A_ii_1": {"answer": "No",  "remarks": "No confidential partnership data is included in the transaction dataset."},
    "A_ii_2": {"answer": "No",  "remarks": "No patent information present in scope of data."},
    "A_ii_3": {"answer": "No",  "remarks": "No M&A-related information included."},
    "A_ii_4": {"answer": "No",  "remarks": "No other commercial secrets identified in the dataset."},
    "B_i":    {"answer": "Yes", "remarks": "Contains personal financial transaction data classified as sensitive under UU PDP."},
    "B_ii":   {"answer": "Yes", "remarks": "PII fields are masked and tokenised before sharing; access restricted to authorised team members only."},
    "B_iii":  {"answer": "Yes", "remarks": "Transaction records contain customer identifiers and financial data constituting personal data."},
    "B_iv":   {"answer": "Yes", "remarks": "Customer consent obtained via Terms & Conditions agreement at account opening."},
    "B_v":    {"answer": "Yes", "remarks": "Research consent included in digital banking app consent form signed by customers."},
    "B_vi":   {"answer": "Yes", "remarks": "Data is processed within the BU secured analytics environment with role-based access control enforced."},
    "C_i_1":  {"answer": "No",  "remarks": "Compliant with OJK regulations on data usage for financial analytics purposes."},
    "C_i_2":  {"answer": "No",  "remarks": "Compliant with UU PDP (Personal Data Protection Law No. 27/2022)."},
    "C_i_3":  {"answer": "No",  "remarks": "Compliant with internal Data Governance Policy v2.1 and AI Ethics Guidelines."},
    "D_i":    {"answer": "Yes", "remarks": "Generative AI models are used for customer financial insight generation. AI Checklist Assessment completed separately."},
    "sign_off": {
        "approved":               "Yes",
        "prepared_by":            "Rendra Kusuma Wijaya",
        "prepared_position":      "Head of Digital Innovation",
        "prepared_signature":     sig_prepared,
        "prepared_date":          "2026-01-25",
        "acknowledged_by":        "Dewi Rahayu",
        "acknowledged_position":  "Senior Data Scientist",
        "acknowledged_signature": sig_acknowledged,
        "acknowledged_date":      "2026-01-25",
        "remarks": "All compliance requirements have been reviewed and satisfied. Data sharing approved for AI model development purposes.",
    },
}


async def main() -> None:
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
    from sqlalchemy import text

    engine = create_async_engine(DATABASE_URL, echo=False)
    async with async_sessionmaker(engine, class_=AsyncSession)() as db:
        await db.execute(
            text(
                "UPDATE ai_compliance_checklists "
                "SET checklist_json = :j, validated_at = '2026-01-25 11:45:00+00' "
                "WHERE dsr_id = :dsr_id"
            ),
            {"j": json.dumps(CHECKLIST), "dsr_id": DSR_ID},
        )
        await db.commit()
        print("Checklist seeded successfully.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
