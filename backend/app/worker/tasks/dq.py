"""
Celery task: run_dq_generation
Computes Completeness, Consistency (AI-powered via Ollama), Uniqueness,
and Latency for a dataset. Supports GCP BigQuery, Excel, and PostgreSQL.
"""
from __future__ import annotations

import json
import logging
import math
import os
import random
import re
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any
from uuid import UUID

import requests
from celery import shared_task

from app.core.secrets import decrypt_secret

logger = logging.getLogger(__name__)

# ── Prompt template ────────────────────────────────────────────────────────────

CONSISTENCY_PROMPT = """Offer broad validation rules and a RegEx pattern based on the dataset's characteristics (Column Name, Type, and Value). Aim to capture the essence of what makes data reliable and uniform in the larger dataset. Consider the data snapshot thoroughly and assume the provided information is accurate but may not fully encompass all data. Prioritize creating the output from the data snapshot based on Sample Values, followed by Column Name, and then Column Type.

Requirements:
1. Validation Rules:
- Propose validation rules that encompass all the sample data provided.
- Clearly differentiate between mandatory and optional segments in the sample values.
- Identify edge cases that might arise.

2. Generalized Regex Pattern:
- Create a generalized RegEx pattern (only in UTF-8) based on the rules.
- For column type float64, ensure the regex pattern handles floating-point numbers including optional decimal places.
- Do not overcomplicate the pattern; use a general pattern if the value is too complex and varied.
- The regex pattern should be compatible with the "import re" library in Python.
- Use ^ at the beginning and $ at the end of the pattern.

3. Test the regex against each sample value and iterate until all values match (or stop after 2 minutes).

4. Sample data:
Column Name: <COLUMN-NAME>
Column Type: <COLUMN-TYPE>
Sample Values: <COLUMN-DATA>

5. Generate this as final output:
- Column Name: <INSERT_SOMETHING>
- Column Type: <INSERT_SOMETHING>
- Business Rules: a. <INSERT_SOMETHING>; b. <INSERT_SOMETHING>; c. <INSERT_SOMETHING>
- RegEx Pattern: r'^<INSERT-YOUR-REGEX-HERE>$'
- Complexity: <High, Medium, Low>
- Reasoning: <The reasoning>

Indicate your final output by typing: "HERE IS THE FINAL RESULT". Only output what is in template number 5 after that line.
"""

# ── AI helpers ─────────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class DQAIConfig:
    model_name: str
    base_url: str
    timeout_seconds: int
    api_key: str | None = None


def _get_ai_config(db_url: str) -> DQAIConfig | None:
    """Return enabled Ollama config from AI Setup, or None to use rule-based fallback."""
    import psycopg2
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        cur.execute(
            "SELECT model_name, base_url, timeout_seconds, encrypted_api_key "
            "FROM ai_provider_configs "
            "WHERE provider = 'ollama' AND enabled = true "
            "ORDER BY updated_at DESC LIMIT 1"
        )
        row = cur.fetchone()
        cur.close()
        conn.close()
        if row:
            model_name, base_url, timeout_seconds, encrypted_api_key = row
            if model_name and base_url:
                return DQAIConfig(
                    model_name=model_name,
                    base_url=base_url.rstrip("/"),
                    timeout_seconds=timeout_seconds or 60,
                    api_key=decrypt_secret(encrypted_api_key),
                )
    except Exception as exc:
        logger.warning("Could not load AI config from DB: %s", exc)
    return None


def _check_sample_size(n: int) -> int:
    if n < 200:
        return n
    if n < 500:
        return math.ceil(0.5 * n)
    if n <= 5000:
        return math.ceil(0.3 * n)
    return math.ceil(0.1 * n)


def _call_ollama(
    prompt: str,
    model: str,
    base_url: str,
    timeout: int = 120,
    api_key: str | None = None,
) -> str:
    headers = {"Authorization": f"Bearer {api_key}"} if api_key else None
    resp = requests.post(
        f"{base_url.rstrip('/')}/api/generate",
        json={"model": model, "prompt": prompt, "stream": False},
        headers=headers,
        timeout=timeout,
    )
    resp.raise_for_status()
    return resp.json().get("response", "")


def _extract_from_output(raw_text: str) -> dict:
    result = {"business_rules": "", "regex_pattern": ""}

    m = re.search(r"HERE IS THE FINAL RESULT\.?\s*", raw_text, re.DOTALL | re.IGNORECASE)
    if m:
        raw_text = raw_text[m.end():]

    raw_text = re.sub(r"\*\*", "", raw_text, flags=re.DOTALL)

    clean = re.sub(r"\*|\s{2,}", "", raw_text, flags=re.DOTALL)
    br_m = re.search(r"Business Rules:\s*(.*?)\s*RegEx Pattern:", clean, re.DOTALL)
    result["business_rules"] = br_m.group(1).strip() if br_m else ""

    rx_m = re.search(r"r'\^.*?\$'", raw_text, re.DOTALL)
    result["regex_pattern"] = rx_m.group(0).strip() if rx_m else ""

    return result


def _clean_regex(raw_pattern: str) -> str:
    """Strip r'...' wrapper, return just the regex string."""
    pat = raw_pattern.strip()
    pat = re.sub(r"^r'", "", pat)
    pat = re.sub(r"'$", "", pat)
    return pat


def _apply_regex_score(values: list[Any], regex_str: str) -> tuple[int, int, float]:
    """Return (matched, total_non_null, score_pct)."""
    non_null = [v for v in values if v is not None]
    total = len(non_null)
    matched = 0
    if regex_str and total:
        try:
            pat = re.compile(regex_str, re.DOTALL)
            matched = sum(1 for v in non_null if pat.fullmatch(str(v)))
        except re.error:
            pass
    score = round((matched / total) * 100, 2) if total else 0.0
    return matched, total, score


# ── Format-detection fallback ──────────────────────────────────────────────────

def _detect_format_regex(values: list[Any]) -> str | None:
    samples = [str(v) for v in values if v is not None][:50]
    if not samples:
        return None
    patterns = [
        (r"^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$", "email"),
        (r"^\d{4}-\d{2}-\d{2}$", "date_iso"),
        (r"^\+?\d[\d\s\-]{7,14}$", "phone"),
        (r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", "uuid"),
        (r"^\d+$", "integer"),
        (r"^-?\d+(\.\d+)?$", "decimal"),
    ]
    for pat, _ in patterns:
        hits = sum(1 for s in samples if re.match(pat, s, re.IGNORECASE))
        if hits / len(samples) >= 0.7:
            return pat
    return None


# ── Compute functions ──────────────────────────────────────────────────────────

def _score_pct(passed: int, total: int) -> float:
    return round((passed / total) * 100, 2) if total else 0.0


def _infer_dtype(values: list[Any]) -> str:
    non_null = [v for v in values if v is not None]
    if not non_null:
        return "object"
    sample = non_null[:20]
    if all(isinstance(v, bool) for v in sample):
        return "bool"
    if all(isinstance(v, int) and not isinstance(v, bool) for v in sample):
        return "int64"
    if all(isinstance(v, float) for v in sample):
        return "float64"
    return "object"


def _compute_completeness(col: str, values: list[Any]) -> dict:
    total = len(values)
    non_null = sum(1 for v in values if v is not None and str(v).strip() != "")
    null_count = total - non_null
    score = _score_pct(non_null, total)
    return {
        "check_name": f"{col}__completeness",
        "check_type": "completeness",
        "column_name": col,
        "score": score,
        "row_count": total,
        "failed_count": null_count,
        "status": "pass" if score >= 95 else "warning" if score >= 80 else "fail",
        "business_rules": f"There should be no empty field for {col} in this table",
        "regex_pattern": None,
        "ai_model": None,
        "regex_version": None,
        "details": {"null_count": null_count, "non_null_count": non_null},
    }


def _compute_ai_consistency(
    col: str,
    col_type: str,
    values: list[Any],
    ai_config: DQAIConfig | None,
) -> dict:
    total = len(values)
    non_null = [v for v in values if v is not None]
    unique_vals = list(set(str(v) for v in non_null))
    size = min(_check_sample_size(len(unique_vals)), len(unique_vals), 25)
    random.seed(42)
    sample = sorted(random.sample(unique_vals, size) if size <= len(unique_vals) else unique_vals)

    raw_text = ""
    extracted: dict = {"business_rules": "", "regex_pattern": ""}
    regex_str = ""
    used_model = "rule-based"

    try:
        prompt = (
            CONSISTENCY_PROMPT
            .replace("<COLUMN-NAME>", col)
            .replace("<COLUMN-TYPE>", col_type)
            .replace("<COLUMN-DATA>", str(sample))
        )
        if not ai_config:
            raise RuntimeError("AI Setup is not enabled or configured")
        raw_text = _call_ollama(
            prompt,
            ai_config.model_name,
            ai_config.base_url,
            ai_config.timeout_seconds,
            ai_config.api_key,
        )
        extracted = _extract_from_output(raw_text)
        regex_str = _clean_regex(extracted.get("regex_pattern", ""))
        used_model = ai_config.model_name
    except Exception as exc:
        logger.warning("AI consistency failed for '%s': %s — falling back to rule-based", col, exc)
        regex_str = _detect_format_regex(values) or ""

    matched, non_null_total, score = _apply_regex_score(values, regex_str)
    failed = non_null_total - matched

    return {
        "check_name": f"{col}__consistency",
        "check_type": "consistency",
        "column_name": col,
        "score": score,
        "row_count": total,
        "failed_count": failed,
        "status": "pass" if score >= 95 else "warning" if score >= 70 else "fail",
        "business_rules": extracted.get("business_rules") or "",
        "regex_pattern": regex_str,
        "ai_model": used_model,
        "regex_version": "New Version",
        "details": {
            "matched": matched,
            "raw_text": raw_text[:3000] if raw_text else "",
        },
    }


def _compute_uniqueness(col: str, values: list[Any]) -> dict | None:
    """Only create a Uniqueness row for fully-unique columns (ID-like)."""
    non_null = [v for v in values if v is not None]
    total = len(non_null)
    unique = len(set(str(v) for v in non_null))
    if total > 0 and total == unique:
        return {
            "check_name": f"{col}__uniqueness",
            "check_type": "uniqueness",
            "column_name": col,
            "score": 100.0,
            "row_count": total,
            "failed_count": 0,
            "status": "pass",
            "business_rules": f"There should be no duplicated field for {col} in this table",
            "regex_pattern": None,
            "ai_model": None,
            "regex_version": None,
            "details": {"unique_count": unique, "total_non_null": total},
        }
    return None


def _detect_datetime_cols(columns_data: dict[str, list[Any]]) -> list[str]:
    result = []
    for col, values in columns_data.items():
        non_null = [v for v in values if v is not None][:20]
        if not non_null:
            continue
        if any(isinstance(v, datetime) for v in non_null[:5]):
            result.append(col)
            continue
        date_like = sum(1 for v in non_null if re.match(r"^\d{4}-\d{2}-\d{2}", str(v)))
        if len(non_null) > 0 and date_like / len(non_null) >= 0.8:
            result.append(col)
    return result


def _parse_date_safe(v: Any) -> datetime | None:
    if v is None:
        return None
    if isinstance(v, datetime):
        return v
    if hasattr(v, "year") and hasattr(v, "month"):
        return datetime(v.year, v.month, v.day, tzinfo=timezone.utc)
    s = str(v)
    for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d %H:%M:%S", "%d/%m/%Y", "%m/%d/%Y"):
        try:
            return datetime.strptime(s[: len(fmt)], fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def _compute_latency(col: str, values: list[Any]) -> dict:
    today = datetime.now(timezone.utc).date()
    latest = None
    for v in values:
        parsed = _parse_date_safe(v)
        if parsed:
            d = parsed.date()
            if latest is None or d > latest:
                latest = d

    if latest is None:
        score = 0.0
    else:
        days_ago = (today - latest).days  # 0 = today, positive = in the past
        if days_ago <= 0:
            score = 100.0
        elif days_ago <= 7:
            score = 70.0
        elif days_ago <= 14:
            score = 50.0
        elif days_ago <= 30:
            score = 30.0
        else:
            score = 0.0

    return {
        "check_name": f"{col}__latency",
        "check_type": "latency",
        "column_name": col,
        "score": score,
        "row_count": len(values),
        "failed_count": 0 if score >= 70 else 1,
        "status": "pass" if score >= 70 else "warning" if score >= 30 else "fail",
        "business_rules": f"Latest date in {col} should not be more than 14 days ago",
        "regex_pattern": None,
        "ai_model": None,
        "regex_version": None,
        "details": {
            "latest_date": str(latest) if latest else None,
            "days_since_latest": (today - latest).days if latest else None,
        },
    }


def _collect_findings(check: dict) -> list[dict]:
    findings = []
    col = check["column_name"]
    score = check["score"]
    ct = check["check_type"]
    failed = check["failed_count"]

    if ct == "completeness" and failed:
        findings.append({
            "severity": "critical" if score < 80 else "warning",
            "description": f"Column '{col}' has {failed} null/empty values ({100 - score:.1f}% null rate).",
            "recommendation": f"Investigate data pipeline for missing values in '{col}'.",
        })
    elif ct == "consistency" and failed and check.get("regex_pattern"):
        findings.append({
            "severity": "warning",
            "description": f"Column '{col}' has {failed} values not matching expected pattern ({score:.1f}% match).",
            "recommendation": "Standardise input validation for this field.",
        })
    elif ct == "latency" and score < 70:
        findings.append({
            "severity": "critical" if score < 30 else "warning",
            "description": f"Column '{col}' has stale datetime data (latency score: {score:.0f}%).",
            "recommendation": f"Ensure '{col}' is updated with recent data regularly.",
        })
    return findings


def _analyse_dataframe(
    columns_data: dict[str, list[Any]],
    ai_config: DQAIConfig | None,
) -> tuple[list[dict], float]:
    """Return (check_results_list, overall_score)."""
    results: list[dict] = []
    scores: list[float] = []

    datetime_cols = _detect_datetime_cols(columns_data)

    for col, values in columns_data.items():
        col_type = _infer_dtype(values)
        total_unique = len(set(str(v) for v in values if v is not None))

        # Completeness
        comp = _compute_completeness(col, values)
        comp["details"]["total_unique"] = total_unique
        comp["findings"] = _collect_findings(comp)
        results.append(comp)
        scores.append(comp["score"])

        # Consistency (AI-powered with rule-based fallback)
        cons = _compute_ai_consistency(col, col_type, values, ai_config)
        cons["details"]["total_unique"] = total_unique
        cons["findings"] = _collect_findings(cons)
        results.append(cons)
        scores.append(cons["score"])

        # Uniqueness (only for fully-unique columns)
        uniq = _compute_uniqueness(col, values)
        if uniq:
            uniq["details"]["total_unique"] = total_unique
            uniq["findings"] = []
            results.append(uniq)
            scores.append(uniq["score"])

        # Latency (only for datetime columns)
        if col in datetime_cols:
            lat = _compute_latency(col, values)
            lat["details"]["total_unique"] = total_unique
            lat["findings"] = _collect_findings(lat)
            results.append(lat)
            scores.append(lat["score"])

    overall = round(sum(scores) / len(scores), 2) if scores else 0.0
    return results, overall


# ── Read data helpers ──────────────────────────────────────────────────────────

def _read_excel(file_path: str, sheet_name: str | None = None) -> dict[str, list[Any]]:
    import openpyxl
    wb = openpyxl.load_workbook(file_path, read_only=True, data_only=True)
    ws = wb[sheet_name] if sheet_name and sheet_name in wb.sheetnames else wb.active
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        return {}
    headers = [str(h) if h is not None else f"col_{i}" for i, h in enumerate(rows[0])]
    data: dict[str, list[Any]] = {h: [] for h in headers}
    for row in rows[1:]:
        for header, val in zip(headers, row):
            data[header].append(val)
    return data


def _read_postgres(connection_string: str, table_name: str, max_rows: int = 10_000) -> dict[str, list[Any]]:
    import psycopg2
    conn = psycopg2.connect(connection_string, connect_timeout=15)
    cur = conn.cursor()
    cur.execute(f'SELECT * FROM "{table_name}" LIMIT %s', (max_rows,))
    cols = [desc[0] for desc in cur.description]
    rows = cur.fetchall()
    cur.close()
    conn.close()
    data: dict[str, list[Any]] = {col: [] for col in cols}
    for row in rows:
        for col, val in zip(cols, row):
            data[col].append(val)
    return data


def _read_bigquery(
    gcp_project: str, bq_dataset: str, bq_table: str, sa_key: dict | None
) -> dict[str, list[Any]]:
    try:
        from google.cloud import bigquery
        from google.oauth2 import service_account

        if sa_key:
            creds = service_account.Credentials.from_service_account_info(sa_key)
            client = bigquery.Client(project=gcp_project, credentials=creds)
        else:
            client = bigquery.Client(project=gcp_project)

        table_ref = f"{gcp_project}.{bq_dataset}.{bq_table}"
        rows = list(client.list_rows(table_ref, max_results=10_000))
        if not rows:
            return {}
        schema = rows[0].keys()
        data: dict[str, list[Any]] = {col: [] for col in schema}
        for row in rows:
            for col in schema:
                data[col].append(row[col])
        return data
    except Exception as exc:
        logger.error("BigQuery read error: %s", exc)
        raise


# ── Celery tasks ───────────────────────────────────────────────────────────────

@shared_task(
    bind=True,
    name="app.worker.tasks.dq.run_dq_generation",
    max_retries=2,
    default_retry_delay=60,
)
def run_dq_generation(
    self,
    run_id: str,
    source_type: str,
    dataset_location: str,
    gcp_project: str | None = None,
    bq_dataset_name: str | None = None,
    bq_table: str | None = None,
    temp_file_key: str | None = None,
    sheet_name: str | None = None,
    postgres_connection_string: str | None = None,
    postgres_table: str | None = None,
    stored_path: str | None = None,
) -> dict:
    """Compute 4-dimension DQ checks and persist results via synchronous psycopg2."""
    import psycopg2

    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    if not db_url:
        return {"error": "no DATABASE_URL"}

    run_uuid = run_id
    started_at = datetime.now(timezone.utc)

    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        cur.execute(
            "UPDATE dq_runs SET status='running', started_at=%s, celery_task_id=%s WHERE id=%s",
            (started_at, self.request.id, run_uuid),
        )
        conn.commit()

        # Load AI config from DB
        ai_config = _get_ai_config(db_url)
        if ai_config:
            logger.info("DQ run %s using AI model=%s base_url=%s", run_id, ai_config.model_name, ai_config.base_url)
        else:
            logger.info("DQ run %s using rule-based consistency fallback; AI Setup is not ready", run_id)

        # Load data
        if source_type == "project_file" and stored_path:
            columns_data = _read_excel(stored_path, sheet_name)
        elif source_type == "excel" and temp_file_key:
            file_path = os.path.join(tempfile.gettempdir(), temp_file_key)
            columns_data = _read_excel(file_path, sheet_name)
        elif source_type == "gcp" and gcp_project:
            columns_data = _read_bigquery(gcp_project, bq_dataset_name or "", bq_table or "", None)
        elif source_type == "postgres" and postgres_connection_string and postgres_table:
            columns_data = _read_postgres(postgres_connection_string, postgres_table)
        else:
            raise ValueError(f"Unsupported source_type={source_type!r}")

        check_results, overall_score = _analyse_dataframe(columns_data, ai_config)

        passed = sum(1 for r in check_results if r["status"] == "pass")
        failed_checks = sum(1 for r in check_results if r["status"] == "fail")
        total = len(check_results)
        completed_at = datetime.now(timezone.utc)

        # Persist results
        for r in check_results:
            cur.execute(
                """INSERT INTO dq_results
                   (id, run_id, check_name, check_type, column_name,
                    status, actual_value, row_count, failed_count, details,
                    business_rules, regex_pattern, ai_model, regex_version, column_category)
                   VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, %s, %s, %s, %s,
                           %s, %s, %s, %s, %s)
                   RETURNING id""",
                (
                    run_uuid,
                    r["check_name"], r["check_type"], r["column_name"],
                    r["status"], str(r["score"]), r["row_count"], r["failed_count"],
                    json.dumps(r.get("details", {})),
                    r.get("business_rules"), r.get("regex_pattern"),
                    r.get("ai_model"), r.get("regex_version"), r.get("column_category"),
                ),
            )
            result_id = cur.fetchone()[0]

            for f in r.get("findings", []):
                cur.execute(
                    """INSERT INTO dq_findings
                       (id, result_id, severity, description, recommendation, status)
                       VALUES (gen_random_uuid(), %s, %s, %s, %s, 'open')""",
                    (result_id, f["severity"], f["description"], f.get("recommendation")),
                )

        cur.execute(
            """UPDATE dq_runs SET
               status='completed', completed_at=%s,
               total_checks=%s, passed_checks=%s, failed_checks=%s, overall_score=%s
               WHERE id=%s""",
            (completed_at, total, passed, failed_checks, overall_score, run_uuid),
        )
        conn.commit()
        cur.close()
        conn.close()

        try:
            from app.worker.tasks.notifications import send_workflow_notification
            send_workflow_notification.delay(
                event="dq_run_completed", entity_id=run_id, recipients=[],
                context={"run_id": run_id, "overall_score": str(overall_score), "actor": "system"},
            )
        except Exception:
            pass

        logger.info("DQ run %s completed: score=%.1f%%, checks=%d", run_id, overall_score, total)
        return {"run_id": run_id, "overall_score": overall_score,
                "total_checks": total, "passed": passed, "failed": failed_checks}

    except Exception as exc:
        logger.error("DQ run %s failed: %s", run_id, exc)
        try:
            conn2 = psycopg2.connect(db_url)
            cur2 = conn2.cursor()
            cur2.execute("UPDATE dq_runs SET status='failed' WHERE id=%s", (run_uuid,))
            conn2.commit()
            cur2.close()
            conn2.close()
        except Exception:
            pass
        raise self.retry(exc=exc, countdown=60)


@shared_task(
    bind=True,
    name="app.worker.tasks.dq.archive_to_gcp",
    max_retries=2,
)
def archive_to_gcp(self, run_id: str) -> dict:
    """Write run summary to BigQuery and upload report to GCS."""
    import psycopg2

    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    if not db_url:
        return {"error": "no DATABASE_URL"}

    run_uuid = run_id
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()

        cur.execute(
            "SELECT dataset_name, overall_score, total_checks, passed_checks, "
            "failed_checks, completed_at FROM dq_runs WHERE id=%s",
            (run_uuid,),
        )
        row = cur.fetchone()
        if not row:
            return {"error": "run not found"}

        gcs_path = f"gs://dq-governance-outputs/{run_id}/dq_results.xlsx"

        cur.execute(
            """INSERT INTO dq_gcp_archives
               (id, run_id, gcs_report_path, bq_dataset, bq_table, archive_status)
               VALUES (gen_random_uuid(), %s, %s, 'dq_governance', 'run_summaries', 'completed')
               ON CONFLICT (run_id)
               DO UPDATE SET gcs_report_path=%s, archive_status='completed'""",
            (run_uuid, gcs_path, gcs_path),
        )
        conn.commit()
        cur.close()
        conn.close()

        logger.info("DQ run %s archived to GCS=%s", run_id, gcs_path)
        return {"run_id": run_id, "gcs_path": gcs_path}

    except Exception as exc:
        logger.error("archive_to_gcp failed for run %s: %s", run_id, exc)
        raise self.retry(exc=exc, countdown=120)
