"""One-off script: backfill standard_format for metadata records that have none.

Inference order:
  1. data_type → numeric / date / boolean types resolved directly
  2. sample_data pattern match → date, datetime, email, phone, integer,
     decimal, ID/code detected from the single stored sample
  3. Fallback → "Free text" for STRING columns with unrecognisable samples

Usage (inside container):
    python scripts/backfill_standard_format.py
    python scripts/backfill_standard_format.py --dry-run
    python scripts/backfill_standard_format.py --overwrite   # re-assess ALL, not just nulls
"""
import argparse
import os
import re

import psycopg2
import psycopg2.extras

DB_URL = os.environ["DATABASE_URL_SYNC"]


# ── Type → format map ─────────────────────────────────────────────────────────

_TYPE_MAP: dict[str, str] = {
    "INTEGER":    "Integer (whole number)",
    "INT":        "Integer (whole number)",
    "INT2":       "Integer (whole number)",
    "INT4":       "Integer (whole number)",
    "INT8":       "Integer (whole number)",
    "BIGINT":     "Integer (whole number)",
    "SMALLINT":   "Integer (whole number)",
    "TINYINT":    "Integer (whole number)",
    "FLOAT":      "Decimal number",
    "FLOAT4":     "Decimal number",
    "FLOAT8":     "Decimal number",
    "DOUBLE":     "Decimal number",
    "DOUBLE PRECISION": "Decimal number",
    "REAL":       "Decimal number",
    "DECIMAL":    "Decimal number",
    "NUMERIC":    "Decimal number",
    "BOOLEAN":    "Boolean (Yes/No or True/False)",
    "BOOL":       "Boolean (Yes/No or True/False)",
    "DATE":       "Date (YYYY-MM-DD)",
    "DATETIME":   "Datetime (YYYY-MM-DD HH:MM:SS)",
    "TIMESTAMP":  "Datetime (YYYY-MM-DD HH:MM:SS)",
    "TIMESTAMPTZ": "Datetime (YYYY-MM-DD HH:MM:SS)",
    "TIMESTAMP WITH TIME ZONE":    "Datetime (YYYY-MM-DD HH:MM:SS)",
    "TIMESTAMP WITHOUT TIME ZONE": "Datetime (YYYY-MM-DD HH:MM:SS)",
}

_BOOL_SET = {"true", "false", "yes", "no", "y", "n", "0", "1", "t", "f"}


def _infer(data_type: str, sample: str | None) -> str | None:
    dt = (data_type or "").strip().upper()

    # Direct type match
    if dt in _TYPE_MAP:
        return _TYPE_MAP[dt]

    # VARCHAR/TEXT/STRING — pattern-match the single sample
    s = (sample or "").strip()
    if not s:
        return "Free text"

    # Boolean value — single sample can't determine the pair, use generic label
    if s.lower() in _BOOL_SET:
        return f"Boolean ({s})"

    # Datetime (must check before date)
    if re.match(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}", s):
        return "Datetime (YYYY-MM-DD HH:MM:SS)"

    # Date formats
    if re.match(r"^\d{4}-\d{2}-\d{2}$", s):
        return "Date (YYYY-MM-DD)"
    if re.match(r"^\d{2}/\d{2}/\d{4}$", s):
        return "Date (DD/MM/YYYY)"
    if re.match(r"^\d{2}-\d{2}-\d{4}$", s):
        return "Date (DD-MM-YYYY)"
    if re.match(r"^\d{4}/\d{2}/\d{2}$", s):
        return "Date (YYYY/MM/DD)"

    # Email
    if re.match(r"^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$", s):
        return "Email (name@domain.com)"

    # Phone — must contain a separator so pure integers don't match
    if re.match(r"^[+\d][\d\s\-().x]{6,20}$", s) and re.search(r"[+\s\-().x]", s):
        return "Phone number"

    # Pure integer (could be from STRING column storing numbers)
    if re.match(r"^-?\d+$", s):
        return "Integer (whole number)"

    # Decimal
    if re.match(r"^-?\d+\.\d+$", s):
        dp = len(s.split(".")[1])
        return f"Decimal ({dp} decimal places)"

    # ID / Code  e.g. TXN-001, CUST_0123, 12-digit number
    if re.match(r"^[A-Z]{2,}[-_]\d+$", s) or re.match(r"^\d{6,20}$", s):
        return f"ID / Code (e.g. {s})"

    # Can't determine categorical vs free text from one sample → conservative fallback
    return "Free text"


# ── Main ──────────────────────────────────────────────────────────────────────

def _infer_from_distinct(distinct_values: str) -> str | None:
    """Re-run categorical/boolean detection from stored distinct_values string."""
    vals = [v.strip() for v in distinct_values.split(",") if v.strip()]
    if not vals:
        return None
    bool_set = {"true", "false", "yes", "no", "y", "n", "0", "1", "t", "f"}
    bool_positive = {"true", "yes", "y", "1", "t"}
    if len(vals) <= 4 and all(v.lower() in bool_set for v in vals):
        ordered = sorted(vals, key=lambda v: (0 if v.lower() in bool_positive else 1))
        return f"Boolean ({' / '.join(ordered)})"
    cats = sorted(vals[:10])
    suffix = ", ..." if len(vals) > 10 else ""
    return f"Category: {', '.join(cats)}{suffix}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run",   action="store_true", help="Print inferences, do not write")
    parser.add_argument("--overwrite", action="store_true", help="Re-assess ALL records, not just nulls")
    args = parser.parse_args()

    conn = psycopg2.connect(DB_URL)
    cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    where = "TRUE" if args.overwrite else "(standard_format IS NULL OR standard_format = '')"
    cur.execute(f"""
        SELECT id, data_type, sample_data, distinct_values, data_attribute, data_domain_table, standard_format
        FROM metadata_records
        WHERE {where}
        ORDER BY data_domain_table, data_attribute
    """)
    rows = cur.fetchall()

    print(f"{'DRY RUN — ' if args.dry_run else ''}Processing {len(rows)} records …\n")

    updated = skipped = 0
    update_cur = conn.cursor()

    for r in rows:
        # Prefer distinct_values for categorical re-inference when available
        if r["distinct_values"]:
            inferred = _infer_from_distinct(r["distinct_values"]) or _infer(r["data_type"], r["sample_data"])
        else:
            inferred = _infer(r["data_type"], r["sample_data"])
        if not inferred:
            skipped += 1
            continue

        tag = "(no change)" if inferred == r["standard_format"] else ""
        print(f"  [{r['data_domain_table']}] {r['data_attribute']:40s}  {r['data_type']:12s}  →  {inferred}  {tag}")

        if not args.dry_run and inferred != r["standard_format"]:
            update_cur.execute(
                "UPDATE metadata_records SET standard_format = %s WHERE id = %s",
                (inferred, r["id"]),
            )
            updated += 1

    if not args.dry_run:
        conn.commit()
        print(f"\nDone. Updated {updated} records, skipped {skipped}.")
    else:
        print(f"\nDry run complete. Would update {len([r for r in rows if _infer(r['data_type'], r['sample_data'])])} records.")

    cur.close()
    update_cur.close()
    conn.close()


if __name__ == "__main__":
    main()
