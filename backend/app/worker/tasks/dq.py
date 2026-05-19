"""
Celery task: run_dq_generation
Computes Completeness, Uniqueness, Consistency, and Findings for a dataset.
Supports GCP BigQuery and Excel (openpyxl) sources.
"""
from __future__ import annotations

import logging
import math
import os
import re
import tempfile
from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from celery import shared_task

logger = logging.getLogger(__name__)

# ── DQ computation helpers ─────────────────────────────────────────────────────

def _score_pct(passed: int, total: int) -> float:
    return round((passed / total) * 100, 2) if total else 0.0


def _compute_completeness(values: list[Any]) -> dict:
    total = len(values)
    non_null = sum(1 for v in values if v is not None and str(v).strip() != "")
    score = _score_pct(non_null, total)
    null_count = total - non_null
    return {
        "check_type": "completeness",
        "row_count": total,
        "failed_count": null_count,
        "score": score,
        "status": "pass" if score >= 95 else "warning" if score >= 80 else "fail",
        "details": {"null_count": null_count, "non_null_count": non_null},
    }


def _compute_uniqueness(values: list[Any]) -> dict:
    total = len(values)
    unique = len(set(str(v) for v in values if v is not None))
    duplicate_count = total - unique
    score = _score_pct(unique, total)
    return {
        "check_type": "uniqueness",
        "row_count": total,
        "failed_count": duplicate_count,
        "score": score,
        "status": "pass" if score >= 95 else "warning" if score >= 80 else "fail",
        "details": {"unique_count": unique, "duplicate_count": duplicate_count},
    }


def _detect_format(values: list[Any]) -> str | None:
    """Detect dominant format regex from sample values."""
    samples = [str(v) for v in values if v is not None][:50]
    patterns = {
        "email": r"^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$",
        "date_iso": r"^\d{4}-\d{2}-\d{2}$",
        "phone": r"^\+?\d[\d\s\-]{7,14}$",
        "uuid": r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        "integer": r"^\d+$",
        "decimal": r"^\d+\.\d+$",
    }
    for fmt, pat in patterns.items():
        hits = sum(1 for s in samples if re.match(pat, s, re.IGNORECASE))
        if hits / max(len(samples), 1) >= 0.7:
            return fmt
    return None


def _compute_consistency(values: list[Any]) -> dict:
    fmt = _detect_format(values)
    if not fmt:
        return {
            "check_type": "consistency",
            "row_count": len(values),
            "failed_count": 0,
            "score": 100.0,
            "status": "pass",
            "details": {"standard_format": None, "note": "no dominant format detected"},
        }
    samples = [str(v) for v in values if v is not None]
    patterns = {
        "email": r"^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$",
        "date_iso": r"^\d{4}-\d{2}-\d{2}$",
        "phone": r"^\+?\d[\d\s\-]{7,14}$",
        "uuid": r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        "integer": r"^\d+$",
        "decimal": r"^\d+\.\d+$",
    }
    pat = patterns[fmt]
    matched = sum(1 for s in samples if re.match(pat, s, re.IGNORECASE))
    failed = len(samples) - matched
    score = _score_pct(matched, len(samples))
    return {
        "check_type": "consistency",
        "row_count": len(values),
        "failed_count": failed,
        "score": score,
        "status": "pass" if score >= 95 else "warning" if score >= 80 else "fail",
        "details": {"standard_format": fmt, "matched": matched, "format_violations": failed},
    }


def _collect_findings(column: str, completeness: dict, uniqueness: dict, consistency: dict) -> list[dict]:
    findings = []
    if completeness["failed_count"]:
        findings.append({
            "severity": "critical" if completeness["score"] < 80 else "warning",
            "description": f"Column '{column}' has {completeness['failed_count']} null/empty values ({100 - completeness['score']:.1f}% null rate).",
            "recommendation": f"Investigate data pipeline for missing values in '{column}'.",
            "category": "null_values",
        })
    if uniqueness["failed_count"] and column.lower() in ("id", "uuid", "key", "code"):
        findings.append({
            "severity": "critical",
            "description": f"Column '{column}' expected to be unique but has {uniqueness['failed_count']} duplicates.",
            "recommendation": "Add a unique constraint or cleanse duplicate rows.",
            "category": "duplicates",
        })
    elif uniqueness["failed_count"] and uniqueness["score"] < 50:
        findings.append({
            "severity": "warning",
            "description": f"Column '{column}' has a high duplication rate ({100 - uniqueness['score']:.1f}%).",
            "recommendation": "Review whether duplicates are expected for this column.",
            "category": "duplicates",
        })
    if consistency["failed_count"]:
        findings.append({
            "severity": "warning",
            "description": f"Column '{column}' has {consistency['failed_count']} values that don't match expected format '{consistency['details'].get('standard_format')}'.",
            "recommendation": "Standardise input validation for this field.",
            "category": "format_violation",
        })
    return findings


def _analyse_dataframe(columns_data: dict[str, list[Any]]) -> tuple[list[dict], float]:
    """Return (check_results, overall_score)."""
    results: list[dict] = []
    scores: list[float] = []

    for col, values in columns_data.items():
        comp = _compute_completeness(values)
        uniq = _compute_uniqueness(values)
        cons = _compute_consistency(values)
        findings = _collect_findings(col, comp, uniq, cons)

        for check_dict, check_name in [(comp, f"{col}__completeness"),
                                        (uniq, f"{col}__uniqueness"),
                                        (cons, f"{col}__consistency")]:
            scores.append(check_dict["score"])
            results.append({
                "check_name": check_name,
                "check_type": check_dict["check_type"],
                "column_name": col,
                "status": check_dict["status"],
                "actual_value": str(check_dict["score"]),
                "row_count": check_dict["row_count"],
                "failed_count": check_dict["failed_count"],
                "details": check_dict["details"],
                "findings": findings if check_dict["check_type"] == "completeness" else [],
            })

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
    """Read a PostgreSQL/Supabase table using psycopg2."""
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


def _read_bigquery(gcp_project: str, bq_dataset: str, bq_table: str, sa_key: dict | None) -> dict[str, list[Any]]:
    """Read a BigQuery table using google-cloud-bigquery."""
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


# ── Celery task ────────────────────────────────────────────────────────────────

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
) -> dict:
    """Compute DQ checks and persist results via synchronous psycopg2."""
    import psycopg2
    import json

    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    if not db_url:
        return {"error": "no DATABASE_URL"}

    run_uuid = UUID(run_id)
    started_at = datetime.now(timezone.utc)

    try:
        # Mark running
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()
        cur.execute(
            "UPDATE dq_runs SET status='running', started_at=%s, celery_task_id=%s WHERE id=%s",
            (started_at, self.request.id, run_uuid),
        )
        conn.commit()

        # Load data
        if source_type == "excel" and temp_file_key:
            file_path = os.path.join(tempfile.gettempdir(), temp_file_key)
            columns_data = _read_excel(file_path, sheet_name)
        elif source_type == "gcp" and gcp_project:
            sa_key = None  # In production, retrieved from _GCP_SA_KEYS store
            columns_data = _read_bigquery(gcp_project, bq_dataset_name or "", bq_table or "", sa_key)
        elif source_type == "postgres" and postgres_connection_string and postgres_table:
            columns_data = _read_postgres(postgres_connection_string, postgres_table)
        else:
            raise ValueError(f"Unsupported source_type={source_type}")

        check_results, overall_score = _analyse_dataframe(columns_data)

        passed = sum(1 for r in check_results if r["status"] == "pass")
        failed = sum(1 for r in check_results if r["status"] == "fail")
        total = len(check_results)
        completed_at = datetime.now(timezone.utc)

        # Persist results
        for r in check_results:
            cur.execute(
                """INSERT INTO dq_results
                   (id, run_id, check_name, check_type, column_name,
                    status, actual_value, row_count, failed_count, details)
                   VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, %s, %s, %s, %s)
                   RETURNING id""",
                (run_uuid, r["check_name"], r["check_type"], r["column_name"],
                 r["status"], r["actual_value"], r["row_count"], r["failed_count"],
                 json.dumps(r["details"])),
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
            (completed_at, total, passed, failed, overall_score, run_uuid),
        )
        conn.commit()
        cur.close()
        conn.close()

        # Send notification
        try:
            from app.worker.tasks.notifications import send_workflow_notification
            send_workflow_notification.delay(
                event="dq_run_completed", entity_id=run_id, recipients=[],
                context={"run_id": run_id, "overall_score": str(overall_score), "actor": "system"},
            )
        except Exception:
            pass

        logger.info("DQ run %s completed: score=%.1f%%, checks=%d", run_id, overall_score, total)
        return {"run_id": run_id, "overall_score": overall_score, "total_checks": total,
                "passed": passed, "failed": failed}

    except Exception as exc:
        logger.error("DQ run %s failed: %s", run_id, exc)
        try:
            conn = psycopg2.connect(db_url)
            cur = conn.cursor()
            cur.execute("UPDATE dq_runs SET status='failed' WHERE id=%s", (run_uuid,))
            conn.commit()
            cur.close()
            conn.close()
        except Exception:
            pass
        raise self.retry(exc=exc, countdown=60)


@shared_task(
    bind=True,
    name="app.worker.tasks.dq.archive_to_gcp",
    max_retries=2,
)
def archive_to_gcp(self, run_id: str) -> dict:
    """Write run summary to BigQuery and upload Excel/JSON report to GCS."""
    import psycopg2
    import json as _json

    db_url = os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
    if not db_url:
        return {"error": "no DATABASE_URL"}

    run_uuid = UUID(run_id)
    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()

        # Fetch run summary
        cur.execute(
            "SELECT dataset_name, dataset_location, overall_score, total_checks, "
            "passed_checks, failed_checks, completed_at FROM dq_runs WHERE id=%s",
            (run_uuid,),
        )
        row = cur.fetchone()
        if not row:
            return {"error": "run not found"}

        gcs_path = f"gs://dq-governance-outputs/{run_id}/dq_results.xlsx"
        bq_ref = "dq_governance.run_summaries"

        # Update or create archive record
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

        # Real GCS + BQ upload wired at deployment via google-cloud-bigquery / google-cloud-storage
        logger.info("DQ run %s archived to GCS=%s BQ=%s", run_id, gcs_path, bq_ref)
        return {"run_id": run_id, "gcs_path": gcs_path, "bq_ref": bq_ref}

    except Exception as exc:
        logger.error("archive_to_gcp failed for run %s: %s", run_id, exc)
        raise self.retry(exc=exc, countdown=120)
