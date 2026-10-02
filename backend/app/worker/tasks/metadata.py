"""
Celery tasks for Metadata Management (Phase 5).
  - retrieve_metadata        : auto-populate attributes from GCP / Excel source
  - generate_ai_definition   : call local Ollama API per-row (FR-META-014)
"""
from __future__ import annotations

import asyncio
import logging
import os
import re
import tempfile
from datetime import date, datetime, timezone
from typing import Any
from uuid import UUID

from celery import shared_task

logger = logging.getLogger(__name__)

# ── PII keyword list (FR-META-011) ────────────────────────────────────────────
_PII_KEYWORDS = {
    # Indonesian
    "nama", "telepon", "nik", "ktp", "passport", "gaji", "agama", "kesehatan",
    "alamat", "tanggal_lahir", "tgl_lahir", "jenis_kelamin", "no_rekening",
    "npwp", "sim", "foto", "wajah", "sidik_jari",
    # English
    "name", "phone", "mobile", "email", "mail", "salary", "gender", "religion",
    "health", "address", "birthdate", "birth_date", "dob", "ssn", "passport",
    "account_number", "credit_card", "card_number", "face", "fingerprint",
    "biometric", "race", "ethnicity", "nationality", "income", "tax_id",
}

# Business term abbreviation map and acronym list (FR-META-013): app/services/metadata_population.py


def _classify_sensitivity(attribute: str) -> str:
    """FR-META-011: return Highly Confidential if PII keyword detected, else Confidential."""
    lower = attribute.lower()
    parts = re.split(r"[_\s\-]", lower)
    for part in parts:
        if part in _PII_KEYWORDS:
            return "Highly Confidential"
    # Substring match for compound names
    for kw in _PII_KEYWORDS:
        if kw in lower:
            return "Highly Confidential"
    return "Confidential"


def _expand_business_term(attribute: str) -> str:
    """FR-META-013: same rule as the API upload (acronyms such as NIK in UPPERCASE)."""
    from app.services.metadata_population import expand_business_term

    return expand_business_term(attribute)


def _detect_data_type(values: list[Any]) -> str:
    """Infer data type from sample values."""
    samples = [v for v in values if v is not None][:20]
    if not samples:
        return "STRING"
    type_map = {
        "BOOLEAN": lambda v: str(v).lower() in ("true", "false", "0", "1"),
        "INTEGER": lambda v: str(v).lstrip("-").isdigit(),
        "FLOAT": lambda v: re.match(r"^-?\d+\.\d+$", str(v)) is not None,
        "DATE": lambda v: re.match(r"^\d{4}-\d{2}-\d{2}$", str(v)) is not None,
        "DATETIME": lambda v: re.match(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}", str(v)) is not None,
        "TIME": lambda v: re.match(r"^\d{2}:\d{2}(:\d{2})?$", str(v)) is not None,
    }
    for dtype, check in type_map.items():
        if sum(1 for s in samples if check(s)) / len(samples) >= 0.8:
            return dtype
    return "STRING"


def _get_sample_data(values: list[Any]) -> str:
    """Return up to 5 distinct non-null values pipe-separated, or '(All Blank)'."""
    seen: list[str] = []
    for v in values:
        if v is not None:
            s = str(v).strip()
            if s and s not in seen:
                seen.append(s)
                if len(seen) == 5:
                    break
    return " | ".join(s[:100] for s in seen) if seen else "(All Blank)"


def _get_distinct_values(values: list[Any], standard_format: str | None) -> str | None:
    """Return comma-separated distinct values.

    Always stored for Category/Boolean. Also stored for any other format with
    ≤ 25 unique non-null values so the UI can offer them if the user later
    reclassifies the column to Category.
    """
    non_null = sorted({str(v).strip() for v in values if v is not None and str(v).strip()})
    if not non_null:
        return None
    is_cat_bool = standard_format and (
        standard_format.startswith("Category:") or standard_format.startswith("Boolean")
    )
    if not is_cat_bool and len(non_null) > 25:
        return None
    return ", ".join(non_null[:20]) if non_null else None


def _is_primary_key_candidate(values: list[Any]) -> bool:
    non_null = [v for v in values if v is not None]
    if not non_null:
        return False
    return len(set(str(v) for v in non_null)) == len(non_null)


def _is_nullable(values: list[Any]) -> bool:
    return any(v is None or str(v).strip() == "" for v in values)


_CAT_NAME_HINTS = {
    "type", "status", "level", "category", "cat", "grade", "tier", "segment",
    "class", "flag", "brand", "color", "colour", "region", "zone", "dept",
    "channel", "method", "mode", "rank", "priority", "state", "group", "grp",
}
_TEXT_NAME_HINTS = {
    "name", "description", "desc", "notes", "note", "remark", "comment",
    "address", "addr", "text", "message", "msg", "content", "detail", "info",
}


def _assess_standard_format(values: list[Any], column_name: str | None = None) -> str | None:
    """Infer an expected value format/constraint from column values."""
    non_null = [
        str(v).strip() for v in values
        if v is not None and str(v).strip() and str(v).strip().lower() not in ("nan", "none", "")
    ]
    if not non_null:
        return None

    total = len(non_null)
    unique_vals = list(dict.fromkeys(non_null))  # deduplicated, order-preserved
    n_unique = len(unique_vals)

    # Boolean — return specific label matching the actual values in the data
    bool_set = {"true", "false", "yes", "no", "y", "n", "0", "1", "t", "f"}
    bool_positive = {"true", "yes", "y", "1", "t"}
    bool_unique_lower = {v.lower() for v in unique_vals}
    if n_unique <= 4 and bool_unique_lower <= bool_set:
        seen_lower: set = set()
        deduped: list = []
        for v in unique_vals:
            if v.lower() not in seen_lower:
                seen_lower.add(v.lower())
                deduped.append(v)
        ordered = sorted(deduped, key=lambda v: (0 if v.lower() in bool_positive else 1))
        return f"Boolean ({' / '.join(ordered)})"

    # Categorical — skip pure numeric columns (let them fall through to Integer/Decimal)
    all_numeric = all(re.match(r"^-?\d+(\.\d+)?$", v) for v in unique_vals)
    if not all_numeric:
        col_parts = set(re.split(r"[_\s\-]", (column_name or "").lower()))
        cat_hint  = bool(col_parts & _CAT_NAME_HINTS)
        text_hint = bool(col_parts & _TEXT_NAME_HINTS)

        avg_val_len = sum(len(v) for v in non_null) / total
        long_values = avg_val_len > 35

        n_thresh = 20 if cat_hint else 15
        r_thresh = 0.12 if cat_hint else 0.10

        avg_freq = total / n_unique
        if (not long_values and not text_hint and
            (n_unique <= n_thresh
             or (total >= 20 and n_unique / total < r_thresh)
             or (total >= 50 and avg_freq >= 3.0 and n_unique <= 30 and avg_val_len <= 30))):
            cats = sorted(unique_vals[:10])
            suffix = ", ..." if n_unique > 10 else ""
            return f"Category: {', '.join(cats)}{suffix}"

    # Date patterns
    date_patterns = [
        (r"^\d{4}-\d{2}-\d{2}$",          "Date (YYYY-MM-DD)"),
        (r"^\d{2}/\d{2}/\d{4}$",          "Date (DD/MM/YYYY)"),
        (r"^\d{2}-\d{2}-\d{4}$",          "Date (DD-MM-YYYY)"),
        (r"^\d{4}/\d{2}/\d{2}$",          "Date (YYYY/MM/DD)"),
    ]
    for pattern, label in date_patterns:
        if sum(1 for v in non_null if re.match(pattern, v)) / total >= 0.85:
            return label

    # Datetime
    if sum(1 for v in non_null if re.match(r"^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}", v)) / total >= 0.85:
        return "Datetime (YYYY-MM-DD HH:MM:SS)"

    # Email
    if sum(1 for v in non_null if re.match(r"^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$", v)) / total >= 0.8:
        return "Email (name@domain.com)"

    # Phone number — must have a separator (+, -, ., space, parens, x) so pure integers don't match
    if sum(
        1 for v in non_null
        if re.match(r"^[+\d][\d\s\-().x]{6,20}$", v)
        and re.search(r"[+\s\-().x]", v)
    ) / total >= 0.8:
        return "Phone number"

    # Integer
    if sum(1 for v in non_null if re.match(r"^-?\d+$", v)) / total >= 0.9:
        return "Integer (whole number)"

    # Decimal — check consistent decimal places
    decimal_matches = [v for v in non_null if re.match(r"^-?\d+\.\d+$", v)]
    if len(decimal_matches) / total >= 0.8:
        dp_counts = [len(v.split(".")[1]) for v in decimal_matches]
        if len(set(dp_counts)) == 1:
            return f"Decimal ({dp_counts[0]} decimal places)"
        return "Decimal number"

    # ID / Code pattern  e.g. CUST-001, TXN_00123, DEM00001 (no separator), 12-digit number
    id_matches = sum(
        1 for v in non_null
        if re.match(r"^[A-Z]{2,}[-_]\d+$", v)
        or re.match(r"^[A-Z]{2,}\d{2,}$", v)
        or re.match(r"^\d{6,20}$", v)
    )
    if id_matches / total >= 0.8:
        return f"ID / Code (e.g. {non_null[0]})"

    # Free text — distinguish short vs long
    avg_len = sum(len(v) for v in non_null) / total
    if avg_len > 40:
        return "Free text (long description)"
    return "Free text"


# ── Task: retrieve_metadata ────────────────────────────────────────────────────

@shared_task(
    bind=True,
    name="app.worker.tasks.metadata.retrieve_metadata",
    max_retries=2,
)
def retrieve_metadata(
    self,
    project_id: str,
    source_type: str,
    gcp_project: str | None = None,
    bq_dataset: str | None = None,
    table_names: list[str] | None = None,
    temp_file_key: str | None = None,   # legacy single-key param
    temp_file_keys: list[str] | None = None,
    file_names: list[str] | None = None,
    project_name: str = "",
    project_year: int = 0,
    customer_name: str = "",
    line_of_business: str | None = None,
    owner_info: dict | None = None,
    initiated_by: str = "",
) -> dict:
    """
    Auto-populate MetadataRecord rows for the selected tables.
    Covers FR-META-002 to FR-META-020.
    """
    from sqlalchemy import select

    from app.database import get_sync_session
    from app.models.metadata import MetadataRecord

    proj_uuid = UUID(project_id)

    # ── Load source data ──────────────────────────────────────
    tables_data: dict[str, dict[str, list[Any]]] = {}

    if source_type == "gcp" and gcp_project and bq_dataset:
        try:
            from google.cloud import bigquery
            client = bigquery.Client(project=gcp_project)
            target_tables = table_names or [t.table_id for t in client.list_tables(f"{gcp_project}.{bq_dataset}")]
            for tbl in target_tables:
                ref = f"{gcp_project}.{bq_dataset}.{tbl}"
                rows = list(client.list_rows(ref, max_results=100))
                if not rows:
                    continue
                schema_cols = [f.name for f in client.get_table(ref).schema]
                data: dict[str, list[Any]] = {c: [] for c in schema_cols}
                for row in rows:
                    for col in schema_cols:
                        data[col].append(row[col])
                tables_data[tbl] = data
        except Exception as exc:
            logger.error("GCP read failed: %s", exc)
            raise self.retry(exc=exc)

    elif source_type == "excel":
        # Support both single key (legacy) and multi-key
        keys = temp_file_keys or ([temp_file_key] if temp_file_key else [])
        if keys:
            try:
                import csv as csv_mod
                import openpyxl
                num_files = len(keys)
                for idx, key in enumerate(keys):
                    file_path = os.path.join(tempfile.gettempdir(), key)
                    original_name = (file_names[idx] if file_names and idx < len(file_names) else key)
                    file_ext = os.path.splitext(key)[1].lower()

                    if file_ext == ".csv":
                        with open(file_path, "rb") as fh:
                            raw = fh.read()
                        try:
                            text = raw.decode("utf-8-sig")
                        except UnicodeDecodeError:
                            text = raw.decode("latin-1", errors="replace")
                        csv_rows = list(csv_mod.reader(text.splitlines()))
                        if len(csv_rows) < 2:
                            continue
                        headers = [str(h).strip() if h else f"col_{i}" for i, h in enumerate(csv_rows[0])]
                        data: dict[str, list[Any]] = {h: [] for h in headers}
                        for row in csv_rows[1:101]:
                            for h, v in zip(headers, row):
                                data[h].append(v if v.strip() else None)
                        sheet_name = os.path.splitext(original_name)[0]
                        tbl_key = f"{original_name} - {sheet_name}" if num_files > 1 else sheet_name
                        tables_data[tbl_key] = data
                    else:
                        wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
                        for sheet_name in wb.sheetnames:
                            ws = wb[sheet_name]
                            rows = list(ws.iter_rows(values_only=True))
                            if len(rows) < 2:
                                continue
                            headers = [str(h) if h is not None else f"col_{i}" for i, h in enumerate(rows[0])]
                            data = {h: [] for h in headers}
                            for row in rows[1:101]:
                                for h, v in zip(headers, row):
                                    data[h].append(v)
                            # Table key: "filename.xlsx - SheetName" for multi-file, "SheetName" for single
                            tbl_key = f"{original_name} - {sheet_name}" if num_files > 1 else sheet_name
                            tables_data[tbl_key] = data
                        wb.close()
            except Exception as exc:
                logger.error("Excel read failed: %s", exc)
                raise self.retry(exc=exc)

    # ── Persist MetadataRecord rows ───────────────────────────
    db = get_sync_session()

    created = updated = 0
    global_seq = 0
    for table_name, columns in tables_data.items():
        domain_table = f"{bq_dataset}.{table_name}" if bq_dataset else table_name
        row_count = max((len(v) for v in columns.values()), default=0)
        for col, values in columns.items():
            global_seq += 1
            seq = global_seq
            sensitivity = _classify_sensitivity(col)
            business_term = _expand_business_term(col)
            data_type = _detect_data_type(values)
            pk = _is_primary_key_candidate(values)
            nullable = _is_nullable(values)
            standard_format = _assess_standard_format(values, col)
            # Column-name hint: pure-digit phone columns stored without separators
            _PHONE_KEYWORDS = {"phone", "mobile", "tel", "hp", "handphone", "telepon", "nohp", "no_hp"}
            if standard_format in ("Integer (whole number)", "Free text", None):
                col_lower = col.lower()
                if any(kw in col_lower for kw in _PHONE_KEYWORDS):
                    standard_format = "Phone number"
            distinct_vals = _get_distinct_values(values, standard_format)
            sample = _get_sample_data(values)
            owner_str = owner_info.get("data_owner", "") if owner_info else ""
            steward_str = owner_info.get("data_steward", "") if owner_info else ""
            current_year = datetime.now(timezone.utc).year
            today = datetime.now(timezone.utc).date()

            # Upsert: match by (project_id, data_domain_table, data_attribute)
            existing = db.scalars(
                select(MetadataRecord).where(
                    MetadataRecord.project_id == proj_uuid,
                    MetadataRecord.data_domain_table == domain_table,
                    MetadataRecord.data_attribute == col,
                )
            ).first()

            if existing:
                existing.data_sensitivity = sensitivity
                existing.business_term = business_term
                existing.sample_data = sample
                existing.data_type = data_type
                existing.is_primary_key = pk
                existing.is_nullable = nullable
                existing.source_row_count = row_count
                existing.standard_format = standard_format
                existing.distinct_values = distinct_vals
                updated += 1
            else:
                db.add(MetadataRecord(
                    project_id=proj_uuid, seq_no=seq, business_users=customer_name,
                    data_domain_table=domain_table, line_of_business=line_of_business,
                    table_type="Source", project_name=project_name, project_year=project_year,
                    data_steward=steward_str, data_owner=owner_str, data_attribute=col,
                    data_year=current_year, data_sensitivity=sensitivity, business_term=business_term,
                    definition_status="pending", sample_data=sample, data_type=data_type,
                    is_primary_key=pk, is_nullable=nullable, data_level="Raw",
                    standard_format=standard_format, distinct_values=distinct_vals, remarks="-",
                    source_type=source_type, source_row_count=row_count,
                    updated_date=today, updated_by=initiated_by,
                ))
                created += 1

    try:
        db.commit()
    finally:
        db.close()

    logger.info("retrieve_metadata: project=%s created=%d updated=%d", project_id, created, updated)
    return {"project_id": project_id, "created": created, "updated": updated,
            "tables": list(tables_data.keys())}


# ── Task: generate_ai_definition ──────────────────────────────────────────────

_AI_OPTIONS: dict[str, Any] = {
    "temperature": 0.20,
    "top_p": 0.85,
    "top_k": 30,
    "repeat_penalty": 1.15,
    "num_predict": 160,
}


def _worker_clean_output(text: str) -> str:
    result = re.sub(r'\n+', ' ', text)
    result = re.sub(r';\s+([a-zA-Z])', lambda m: '. ' + m.group(1).upper(), result)
    result = re.sub(r'\s{2,}', ' ', result).strip()
    if result and not result.endswith('.'):
        result += '.'
    return result


def _worker_clean_table_name(table: str) -> str:
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


def _worker_build_prompt(rec: dict) -> str:
    table_context = _worker_clean_table_name(rec.get("data_domain_table") or "")

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


@shared_task(
    bind=True,
    name="app.worker.tasks.metadata.generate_ai_definition",
    max_retries=1,
)
def generate_ai_definition(self, record_id: str) -> dict:
    """
    FR-META-014: Call local Ollama API to generate a business definition.
    No data leaves the internal Docker network.
    Model and base URL are read from ai_provider_configs table (falls back to env vars).
    """
    from sqlalchemy import select

    from app.database import get_sync_session
    from app.models.ai_config import AIProviderConfig
    from app.models.metadata import MetadataRecord
    from app.services.ai_generation import (
        AICandidateConfig,
        build_candidate_from_config,
        generate_metadata_definition,
    )

    db = get_sync_session()

    # Read the same provider abstraction used by the API and DQ pipeline.
    cfg = db.scalars(
        select(AIProviderConfig)
        .where(AIProviderConfig.provider == "ollama", AIProviderConfig.enabled.is_(True))
        .order_by(AIProviderConfig.updated_at.desc())
        .limit(1)
    ).first()
    if cfg:
        candidate = build_candidate_from_config(cfg)
    else:
        ollama_base = (os.getenv("OLLAMA_URL") or os.getenv("OLLAMA_HOST", "http://ollama:11434")).rstrip("/")
        candidate = AICandidateConfig(
            mode="local",
            enabled=True,
            base_url=ollama_base,
            model_name=os.getenv("OLLAMA_MODEL", "llama3.2:3b"),
            timeout_seconds=int(os.getenv("OLLAMA_TIMEOUT_SECONDS", "120")),
            api_key=os.getenv("OLLAMA_API_KEY") or None,
        )

    record = db.get(MetadataRecord, UUID(record_id))
    if not record:
        db.close()
        return {"error": "record not found"}

    prompt = _worker_build_prompt({
        field: getattr(record, field)
        for field in ("data_domain_table", "data_attribute", "business_term", "data_type",
                      "data_grouping", "line_of_business", "distinct_values",
                      "standard_format", "sample_data", "data_sensitivity",
                      "is_primary_key", "is_nullable")
    })

    definition = None
    status = "pending"

    try:
        definition = asyncio.run(generate_metadata_definition(record, candidate))
        status = "ai_generated" if definition else "pending"
    except Exception as exc:
        logger.error("Ollama error for record %s: %s", record_id, exc)
        status = "pending"

    record.business_definition = definition
    record.definition_status = status
    record.updated_date = date.today()
    try:
        db.commit()
    finally:
        db.close()

    return {"record_id": record_id, "status": status, "definition": definition}
