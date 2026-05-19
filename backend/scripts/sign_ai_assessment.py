"""Add signatures to AI Assessment sign-off and mark as completed."""
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
    (15,30),(30,18),(50,36),(70,16),(90,30),(115,20),
    (140,36),(160,22),(185,16),(205,28),(225,18),(250,34),(270,20),(290,28),
])
sig_acknowledged = make_sig([
    (15,32),(35,16),(55,34),(75,20),(100,36),(120,18),
    (145,30),(170,16),(190,32),(210,20),(235,36),(255,22),(275,16),(295,30),
])


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
        existing["ai_assessment"]["sign_off"].update({
            "prepared_signature":     sig_prepared,
            "prepared_date":          "2026-01-27",
            "acknowledged_signature": sig_acknowledged,
            "acknowledged_date":      "2026-01-27",
        })
        await db.execute(
            text(
                "UPDATE ai_compliance_checklists "
                "SET checklist_json = :j, validated_at = '2026-01-27 14:00:00+00' "
                "WHERE dsr_id = :dsr_id"
            ),
            {"j": json.dumps(existing), "dsr_id": DSR_ID},
        )
        await db.commit()
        print("AI assessment signed and status updated.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
