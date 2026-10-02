"""One-off script: regenerate business definitions for ALL metadata records.

Uses the validated llama3.2:3b Variant A prompt + _clean_output post-processing.
Reads records from DB, calls Ollama directly, writes back to DB.

Usage (inside container):
    python scripts/regenerate_all_definitions.py
    python scripts/regenerate_all_definitions.py --dry-run   # print prompts only
"""
import argparse
import os
import re
import sys
from datetime import date

import httpx
from sqlalchemy import select, update

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.database import get_sync_session  # noqa: E402
from app.models.metadata import MetadataRecord  # noqa: E402
from app.models.project import Project  # noqa: E402

OLLAMA_URL = "http://ollama:11434/api/generate"
MODEL = "llama3.2:3b"
OPTIONS = {
    "temperature": 0.20,
    "top_p": 0.85,
    "top_k": 30,
    "repeat_penalty": 1.15,
    "num_predict": 160,
}


# ── post-processing ────────────────────────────────────────────────────────────

def _clean_output(text: str) -> str:
    result = re.sub(r'\n+', ' ', text)
    result = re.sub(r';\s+([a-zA-Z])', lambda m: '. ' + m.group(1).upper(), result)
    result = re.sub(r'\s{2,}', ' ', result).strip()
    if result and not result.endswith('.'):
        result += '.'
    return result


# ── prompt builder ─────────────────────────────────────────────────────────────

def _clean_table_name(table: str) -> str:
    if not table:
        return ""
    for ext in (".xlsx", ".xls", ".csv"):
        idx = table.lower().find(ext)
        if idx > 0:
            table = table[:idx]
            break
    for sep in (" - ", " – ", "_"):
        parts = table.rsplit(sep, 1)
        if len(parts) == 2 and parts[1].lower().startswith("sheet"):
            table = parts[0]
    return table.strip(" -_")


def build_prompt(rec: dict) -> str:
    table_context = _clean_table_name(rec.get("data_domain_table") or "")
    ctx_lines = [
        f"Source table: {table_context}",
        f"Business term: {rec.get('business_term') or rec.get('data_attribute') or ''}",
        f"Data type: {rec.get('data_type') or 'text'}",
    ]
    if rec.get("data_grouping"):
        ctx_lines.append(f"Domain: {rec['data_grouping']}")
    if rec.get("line_of_business"):
        ctx_lines.append(f"Line of business: {rec['line_of_business']}")
    if rec.get("distinct_values"):
        ctx_lines.append(f"Possible values: {rec['distinct_values']}")
    else:
        if rec.get("standard_format"):
            ctx_lines.append(f"Value format / range: {rec['standard_format']}")
        if rec.get("sample_data"):
            ctx_lines.append(f"Example value: {rec['sample_data']}")
    if rec.get("data_sensitivity"):
        ctx_lines.append(f"Sensitivity: {rec['data_sensitivity']}")
    if rec.get("is_primary_key") is not None:
        ctx_lines.append(f"Primary key: {'Yes' if rec['is_primary_key'] else 'No'}")
    if rec.get("is_nullable") is not None:
        ctx_lines.append(f"Nullable: {'Yes' if rec['is_nullable'] else 'No'}")

    context = "\n".join(ctx_lines)

    sf = rec.get("standard_format") or ""
    is_categorical = bool(rec.get("distinct_values")) or sf.startswith("Category:") or sf.startswith("Boolean")
    n = "3" if is_categorical else "2"
    s3 = "\n   3. What each possible value means in practice — one clause per value" if is_categorical else ""

    conditional: list[str] = []
    if rec.get("data_sensitivity") in ("Highly Confidential", "Restricted"):
        conditional.append("8. This data is personally identifiable — briefly note it is handled under data privacy policy.")
    if rec.get("is_primary_key"):
        conditional.append("9. Mention that this value uniquely identifies each record.")
    if rec.get("is_nullable"):
        conditional.append("10. Briefly note when or why this value may be absent.")
    conditional_block = ("\n" + "\n".join(conditional)) if conditional else ""

    return (
        "You are a senior data governance specialist writing a business data dictionary entry.\n\n"
        f"{context}\n\n"
        "CRITICAL: Every sentence must end with a period (.). "
        "Using a semicolon (;) anywhere in your response is forbidden — if you use one, your answer is wrong.\n\n"
        f"Write exactly {n} sentences as one continuous paragraph. Rules:\n"
        "1. Start with a verb — Captures / Records / Identifies / Measures / Tracks / Indicates / Reflects\n"
        "2. Never name the column or business term\n"
        f"3. Sentence 1: what real-world fact this records, anchored to the business area and domain\n"
        f"4. Sentence 2: how it is used in business decisions or reporting{s3}\n"
        "5. Do not mention the table name — draw context from the business area or domain only.\n"
        "6. Write in plain, everyday language — no jargon, no acronyms, no technical terms. "
        "Any reader regardless of background should understand what this data means.\n"
        "7. No line breaks between sentences. Output the definition only."
        f"{conditional_block}\n"
    )


# ── Ollama call ────────────────────────────────────────────────────────────────

def generate(prompt: str) -> str:
    resp = httpx.post(
        OLLAMA_URL,
        json={"model": MODEL, "prompt": prompt, "stream": False, "options": OPTIONS},
        timeout=180.0,
    )
    resp.raise_for_status()
    return _clean_output(resp.json().get("response", "").strip())


# ── main ───────────────────────────────────────────────────────────────────────

def main(dry_run: bool = False) -> None:
    db = get_sync_session()

    m = MetadataRecord
    records = db.execute(
        select(
            m.id, m.data_attribute, m.business_term, m.data_type,
            m.data_domain_table, m.data_grouping, m.line_of_business,
            m.distinct_values, m.standard_format, m.sample_data,
            m.data_sensitivity, m.is_primary_key, m.is_nullable,
            Project.project_code,
        )
        .join(Project, Project.id == m.project_id)
        .order_by(Project.project_code, m.data_domain_table, m.seq_no)
    ).mappings().all()
    total = len(records)
    print(f"\nRecords to process: {total}")
    print(f"Model: {MODEL}  |  dry_run={dry_run}\n{'─' * 70}")

    processed = failed = 0
    current_project = None

    for rec in records:
        if rec["project_code"] != current_project:
            current_project = rec["project_code"]
            print(f"\n{'═' * 70}\n  {current_project}\n{'═' * 70}")

        label = f"{rec['data_domain_table']} · {rec['data_attribute']}"
        print(f"\n  [{label}]")

        prompt = build_prompt(rec)
        if dry_run:
            print(f"  [DRY RUN — prompt length: {len(prompt)} chars]")
            continue

        try:
            definition = generate(prompt)
            db.execute(update(m).where(m.id == rec["id"]).values(
                business_definition=definition,
                definition_status="ai_generated",
                updated_date=date.today(),
            ))
            db.commit()
            processed += 1
            print(f"  {definition}")
        except Exception as exc:
            failed += 1
            print(f"  ERROR: {exc}", file=sys.stderr)

    db.close()
    print(f"\n{'═' * 70}")
    print(f"Done. Processed: {processed}  Failed: {failed}  Total: {total}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    main(dry_run=args.dry_run)
