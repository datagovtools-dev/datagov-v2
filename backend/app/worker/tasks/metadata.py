"""
Celery tasks for Metadata Management (Phase 5).
  - retrieve_metadata        : auto-populate attributes from GCP / Excel source
  - generate_ai_definition   : call local Ollama API per-row (FR-META-014)
"""
from __future__ import annotations

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

# ── Business term abbreviation map (FR-META-013) ──────────────────────────────
_ABBREV_MAP = {
    "id": "Identifier", "nm": "Name", "cd": "Code", "dt": "Date",
    "dttm": "Date Time", "no": "Number", "num": "Number", "qty": "Quantity",
    "amt": "Amount", "val": "Value", "desc": "Description", "flg": "Flag",
    "ind": "Indicator", "sts": "Status", "typ": "Type", "cat": "Category",
    "grp": "Group", "seq": "Sequence", "ref": "Reference", "src": "Source",
    "tgt": "Target", "tot": "Total", "avg": "Average", "max": "Maximum",
    "min": "Minimum", "cnt": "Count", "pct": "Percentage", "ts": "Timestamp",
    "upd": "Updated", "cre": "Created", "del": "Deleted", "usr": "User",
    "org": "Organisation", "dept": "Department", "div": "Division",
    "loc": "Location", "addr": "Address", "tel": "Telephone", "fax": "Fax",
    "url": "URL", "img": "Image", "doc": "Document", "file": "File",
    "txt": "Text", "msg": "Message", "err": "Error", "log": "Log",
}


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
    """FR-META-013: expand abbreviated column name to full business term."""
    # Strip table prefix patterns (tbl_, fk_, idx_, etc.)
    clean = re.sub(r"^(tbl_|fk_|idx_|pk_|f_|t_)", "", attribute, flags=re.IGNORECASE)
    parts = re.split(r"[_\s\-]", clean)
    expanded = []
    for part in parts:
        lower = part.lower()
        if lower in _ABBREV_MAP:
            expanded.append(_ABBREV_MAP[lower])
        else:
            expanded.append(part.capitalize())
    return " ".join(expanded)


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
    """Return first non-null value or '(All Blank)'."""
    for v in values:
        if v is not None and str(v).strip():
            return str(v)[:200]
    return "(All Blank)"


def _is_primary_key_candidate(values: list[Any]) -> bool:
    non_null = [v for v in values if v is not None]
    if not non_null:
        return False
    return len(set(str(v) for v in non_null)) == len(non_null)


def _is_nullable(values: list[Any]) -> bool:
    return any(v is None or str(v).strip() == "" for v in values)


def _assess_standard_format(values: list[Any]) -> str | None:
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

    # Boolean
    bool_set = {"true", "false", "yes", "no", "y", "n", "0", "1", "t", "f"}
    if n_unique <= 4 and all(v.lower() in bool_set for v in unique_vals):
        return "Boolean (Yes/No or True/False)"

    # Categorical / Enum — low cardinality
    if n_unique <= 15 or (total >= 20 and n_unique / total < 0.1):
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

    # Phone number
    if sum(1 for v in non_null if re.match(r"^[+\d][\d\s\-().]{6,18}$", v)) / total >= 0.8:
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

    # ID / Code pattern  e.g. CUST-001, TXN_00123, 12-digit number
    id_matches = sum(
        1 for v in non_null
        if re.match(r"^[A-Z]{2,}[-_]\d+$", v) or re.match(r"^\d{6,20}$", v)
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
    connection_string: str | None = None,
    pg_schema: str = "public",
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
    import psycopg2
    import json

    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    if not db_url:
        return {"error": "no DATABASE_URL"}

    proj_uuid = str(UUID(project_id))  # psycopg2 needs str, not UUID object

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

    elif source_type == "postgresql" and connection_string:
        try:
            src_conn = psycopg2.connect(connection_string)
            src_cur = src_conn.cursor()
            target_tables = table_names
            if not target_tables:
                src_cur.execute(
                    "SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = %s AND table_type = 'BASE TABLE' ORDER BY table_name",
                    (pg_schema,),
                )
                target_tables = [r[0] for r in src_cur.fetchall()]
            for tbl in target_tables:
                src_cur.execute(
                    "SELECT column_name FROM information_schema.columns "
                    "WHERE table_schema = %s AND table_name = %s ORDER BY ordinal_position",
                    (pg_schema, tbl),
                )
                cols = [r[0] for r in src_cur.fetchall()]
                if not cols:
                    continue
                try:
                    src_cur.execute(f'SELECT * FROM "{pg_schema}"."{tbl}" LIMIT 100')
                    rows = src_cur.fetchall()
                except Exception:
                    rows = []
                data: dict[str, list[Any]] = {c: [] for c in cols}
                for row in rows:
                    for i, col in enumerate(cols):
                        data[col].append(row[i] if i < len(row) else None)
                tables_data[tbl] = data
            src_conn.close()
        except Exception as exc:
            logger.error("PostgreSQL read failed: %s", exc)
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
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    created = updated = 0
    global_seq = 0
    for table_name, columns in tables_data.items():
        domain_table = (f"{bq_dataset}.{table_name}" if bq_dataset
                        else f"{pg_schema}.{table_name}" if source_type == "postgresql"
                        else table_name)
        row_count = max((len(v) for v in columns.values()), default=0)
        for col, values in columns.items():
            global_seq += 1
            seq = global_seq
            sensitivity = _classify_sensitivity(col)
            business_term = _expand_business_term(col)
            sample = _get_sample_data(values)
            data_type = _detect_data_type(values)
            pk = _is_primary_key_candidate(values)
            nullable = _is_nullable(values)
            standard_format = _assess_standard_format(values)
            owner_str = owner_info.get("data_owner", "") if owner_info else ""
            steward_str = owner_info.get("data_steward", "") if owner_info else ""
            current_year = datetime.now(timezone.utc).year
            today = datetime.now(timezone.utc).date()

            # Upsert: match by (project_id, data_domain_table, data_attribute)
            cur.execute(
                "SELECT id FROM metadata_records WHERE project_id=%s AND data_domain_table=%s AND data_attribute=%s",
                (proj_uuid, domain_table, col),
            )
            existing = cur.fetchone()

            if existing:
                cur.execute(
                    """UPDATE metadata_records SET
                       data_sensitivity=%s, business_term=%s, sample_data=%s,
                       data_type=%s, is_primary_key=%s, is_nullable=%s, source_row_count=%s,
                       standard_format=%s
                       WHERE id=%s""",
                    (sensitivity, business_term, sample, data_type, pk, nullable, row_count, standard_format, existing[0]),
                )
                updated += 1
            else:
                cur.execute(
                    """INSERT INTO metadata_records
                       (id, project_id, seq_no, business_users, data_domain_table,
                        line_of_business, table_type, project_name, project_year, data_steward, data_owner,
                        data_attribute, data_year, data_sensitivity, business_term, definition_status,
                        sample_data, data_type, is_primary_key, is_nullable,
                        data_level, standard_format, remarks, source_type, source_row_count,
                        updated_date, updated_by)
                       VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, 'Source', %s, %s,
                               %s, %s, %s, %s, %s, %s, 'pending', %s, %s, %s, %s,
                               'Raw', %s, '-', %s, %s, %s, %s)""",
                    (proj_uuid, seq, customer_name, domain_table, line_of_business,
                     project_name, project_year, steward_str, owner_str, col,
                     current_year, sensitivity, business_term,
                     sample, data_type, pk, nullable, standard_format, source_type, row_count,
                     today, initiated_by),
                )
                created += 1

    conn.commit()
    cur.close()
    conn.close()

    logger.info("retrieve_metadata: project=%s created=%d updated=%d", project_id, created, updated)
    return {"project_id": project_id, "created": created, "updated": updated,
            "tables": list(tables_data.keys())}


# ── Task: generate_ai_definition ──────────────────────────────────────────────

@shared_task(
    bind=True,
    name="app.worker.tasks.metadata.generate_ai_definition",
    max_retries=1,
)
def generate_ai_definition(self, record_id: str) -> dict:
    """
    FR-META-014: Call local Ollama API to generate a business definition.
    No data leaves the internal Docker network.
    Timeout 30 s → set definition_status='pending', business_definition=null.
    """
    import psycopg2
    import httpx

    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    ollama_url = os.getenv("OLLAMA_URL", "http://ollama:11434")
    model = os.getenv("OLLAMA_MODEL", "phi3:mini")

    if not db_url:
        return {"error": "no DATABASE_URL"}

    rec_uuid = str(UUID(record_id))  # psycopg2 needs str, not UUID object
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    cur.execute(
        """SELECT data_domain_table, data_attribute, business_term, sample_data, data_type
           FROM metadata_records WHERE id=%s""",
        (rec_uuid,),
    )
    row = cur.fetchone()
    if not row:
        cur.close()
        conn.close()
        return {"error": "record not found"}

    table, attribute, business_term, sample, data_type = row
    prompt = (
        f"You are a data governance expert. Write a clear, concise business definition "
        f"for a database column.\n"
        f"Table: {table}\n"
        f"Column: {attribute}\n"
        f"Business Term: {business_term or attribute}\n"
        f"Data Type: {data_type or 'unknown'}\n"
        f"Sample Value: {sample or 'not available'}\n\n"
        f"Write only the definition in 1-2 sentences. Do not include headers or column names in your answer."
    )

    definition = None
    status = "pending"

    try:
        response = httpx.post(
            f"{ollama_url}/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
            timeout=120.0,
        )
        if response.status_code == 200:
            data = response.json()
            definition = data.get("response", "").strip()
            status = "ai_generated" if definition else "pending"
        else:
            logger.warning("Ollama returned %d for record %s", response.status_code, record_id)
    except httpx.TimeoutException:
        logger.warning("Ollama timeout for record %s — marking pending", record_id)
        status = "pending"
    except Exception as exc:
        logger.error("Ollama error for record %s: %s", record_id, exc)
        status = "pending"

    cur.execute(
        "UPDATE metadata_records SET business_definition=%s, definition_status=%s WHERE id=%s",
        (definition, status, rec_uuid),
    )
    conn.commit()
    cur.close()
    conn.close()

    return {"record_id": record_id, "status": status, "definition": definition}
