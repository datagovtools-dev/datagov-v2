"""
Celery task: run_dq_generation
Computes Completeness, Consistency (AI-powered via Ollama), Uniqueness,
and Latency for a dataset. Supports GCP BigQuery, Excel and project source files.
"""
from __future__ import annotations

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
    parser_contract_version: str = "legacy_v1"
    dq_policy: str = "guarded_legacy"
    model_override_enabled: bool = True
    repair_enabled: bool = True
    minimum_score_delta: float = 0.0
    fallback_enabled: bool = True
    provider: str = "ollama"


def _get_ai_config(db) -> DQAIConfig | None:
    """Return the enabled configured AI provider, or None for rule-based fallback."""
    from sqlalchemy import select

    from app.models.ai_config import AIProviderConfig
    try:
        cfg = db.scalars(
            select(AIProviderConfig)
            .where(AIProviderConfig.enabled.is_(True))
            .order_by(AIProviderConfig.updated_at.desc())
            .limit(1)
        ).first()
        if cfg and cfg.model_name and cfg.base_url:
            return DQAIConfig(
                provider=getattr(cfg, "provider", None) or "ollama",
                model_name=cfg.model_name,
                base_url=cfg.base_url.rstrip("/"),
                timeout_seconds=cfg.timeout_seconds or 60,
                api_key=decrypt_secret(cfg.encrypted_api_key),
                parser_contract_version=getattr(cfg, "parser_contract_version", None) or "legacy_v1",
                dq_policy=getattr(cfg, "dq_policy", None) or "guarded_legacy",
                model_override_enabled=(
                    getattr(cfg, "model_override_enabled", None)
                    if getattr(cfg, "model_override_enabled", None) is not None else True
                ),
                repair_enabled=(
                    getattr(cfg, "repair_enabled", None)
                    if getattr(cfg, "repair_enabled", None) is not None else True
                ),
                minimum_score_delta=float(getattr(cfg, "minimum_score_delta", None) or 0.0),
                fallback_enabled=(
                    getattr(cfg, "fallback_enabled", None)
                    if getattr(cfg, "fallback_enabled", None) is not None else True
                ),
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
    provider: str = "ollama",
) -> str:
    if provider == "openrouter":
        from app.services.ai_generation import openrouter_endpoint

        endpoint = openrouter_endpoint(base_url, "chat/completions")
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
        }
    else:
        endpoint = f"{base_url.rstrip('/')}/api/generate"
        headers = {"Authorization": f"Bearer {api_key}"} if api_key else None
        payload = {"model": model, "prompt": prompt, "stream": False}
    resp = requests.post(
        endpoint,
        json=payload,
        headers=headers,
        timeout=timeout,
    )
    resp.raise_for_status()
    data = resp.json()
    if provider == "openrouter":
        choices = data.get("choices") or []
        message = choices[0].get("message") if choices else {}
        content = message.get("content", "") if isinstance(message, dict) else ""
        return content if isinstance(content, str) else ""
    return data.get("response", "")


def _extract_from_output(raw_text: str, contract_version: str = "legacy_v1") -> dict:
    from app.services.ai_output_parser import parse_dq_output

    parsed = parse_dq_output(raw_text, contract_version=contract_version)
    return {
        "business_rules": parsed["business_rules"],
        "regex_pattern": parsed["regex_pattern"],
        "complexity": parsed["complexity"],
        "reasoning": parsed["reasoning"],
        "parser_warnings": parsed["parser_warnings"],
    }


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
        "regex_version": None,
        "remarks": "-",
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

    extracted: dict = {"business_rules": "", "regex_pattern": ""}
    regex_str = ""
    remarks = "-"

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
            ai_config.provider,
        )
        extracted = _extract_from_output(raw_text, contract_version=ai_config.parser_contract_version if ai_config else "legacy_v1")
        regex_str = _clean_regex(extracted.get("regex_pattern", ""))
    except Exception as exc:
        logger.warning("AI consistency failed for '%s': %s — falling back to rule-based", col, exc)
        regex_str = _detect_format_regex(values) or ""
        remarks = f"AI rule generation unavailable ({exc}); rule-based format regex used"

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
        "regex_version": "New Version",
        "remarks": remarks,
        "details": {"matched": matched},
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
            "regex_version": None,
            "remarks": "-",
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
        "regex_version": None,
        "remarks": "-",
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


def _dq_model(ai_config: DQAIConfig | None) -> str:
    """Model used for DQ rule generation: DQ_PRIMARY_MODEL, else Settings > AI Setup, else llama3.2:3b."""
    return os.getenv("DQ_PRIMARY_MODEL") or (ai_config.model_name if ai_config else None) or "llama3.2:3b"


def _analyse_dataframe(
    columns_data: dict[str, list[Any]],
    ai_config: DQAIConfig | None,
    table_name: str = "",
    project_name: str = "",
    on_column_done: Any = None,
) -> tuple[list[dict], float]:
    """Return (check_results_list, overall_score) using the provided reference DQ method."""
    import pandas as pd
    from app.services.reference_dq import (
        ReferenceDQConfig,
        result_rows_from_reference,
        run_reference_dq_for_dataframe,
    )

    base_url = (
        os.getenv("DQ_OLLAMA_BASE_URL")
        or (ai_config.base_url if ai_config else None)
        or "http://ollama:11434"
    )
    # Same model as Metadata (Settings > AI Setup, llama3.2:3b) unless DQ_* env vars override it;
    # the second pass reuses it with the repair prompt.
    primary_model = _dq_model(ai_config)
    config = ReferenceDQConfig(
        base_url=base_url,
        timeout_seconds=max(int(os.getenv("DQ_OLLAMA_TIMEOUT_SECONDS") or (ai_config.timeout_seconds if ai_config else 120)), 300),
        api_key=ai_config.api_key if ai_config else os.getenv("DQ_OLLAMA_API_KEY"),
        primary_model=primary_model,
        secondary_model=os.getenv("DQ_SECONDARY_MODEL") or primary_model,
        parser_contract_version=ai_config.parser_contract_version if ai_config else "legacy_v1",
        dq_policy=ai_config.dq_policy if ai_config else "guarded_legacy",
        model_override_enabled=ai_config.model_override_enabled if ai_config else True,
        repair_enabled=ai_config.repair_enabled if ai_config else True,
        minimum_score_delta=ai_config.minimum_score_delta if ai_config else 0.0,
        fallback_enabled=ai_config.fallback_enabled if ai_config else True,
    )
    df_raw = pd.DataFrame(columns_data)
    reference_df = run_reference_dq_for_dataframe(
        df_raw=df_raw,
        table_name=table_name,
        project_name=project_name,
        config=config,
        on_column_done=on_column_done,
    )
    return result_rows_from_reference(reference_df)


# ── Read data helpers ──────────────────────────────────────────────────────────

def _read_excel(file_path: str, sheet_name: str | None = None) -> dict[str, list[Any]]:
    """Backward-compatible reader name; dispatches CSV and Excel by extension."""
    from app.services.tabular_reader import read_tabular_columns

    return read_tabular_columns(file_path, sheet_name)


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
    stored_path: str | None = None,
) -> dict:
    """Compute 4-dimension DQ checks and persist results via a synchronous ORM session."""
    from sqlalchemy import update

    from app.database import get_sync_session
    from app.models.dq import DQFinding, DQResult, DQRun
    from app.models.project import Project

    from app.services.dq_failures import (
        CATEGORIES,
        EmptyDataError,
        UnsupportedSourceError,
        classify_failure,
        failure_detail,
    )

    run_uuid = UUID(run_id)
    started_at = datetime.now(timezone.utc)
    ai_config = None

    db = get_sync_session()
    try:
        run = db.get(DQRun, run_uuid)
        if run is None:
            raise ValueError(f"DQ run {run_id} not found")
        run.status = "running"
        run.started_at = started_at
        run.celery_task_id = self.request.id
        run.columns_done = 0
        run.error_category = None
        run.error_message = None
        db.commit()
        project = db.get(Project, run.project_id) if run.project_id else None
        current_dataset_name = run.dataset_name or ""
        current_project_name = project.project_name if project else ""

        # Load AI config from DB
        ai_config = _get_ai_config(db)
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
        else:
            raise UnsupportedSourceError(f"Unsupported source_type={source_type!r}")
        if not columns_data or not any(len(values) for values in columns_data.values()):
            raise EmptyDataError("The sheet has no header or no data rows")

        from app.services.reference_dq import empty_attributes

        run.columns_total = len(columns_data)
        empty_cols = empty_attributes(columns_data)
        db.commit()

        def _progress(done: int, total: int) -> None:
            db.execute(update(DQRun).where(DQRun.id == run_uuid).values(columns_done=done, columns_total=total))
            db.commit()

        check_results, overall_score = _analyse_dataframe(
            columns_data,
            ai_config,
            table_name=current_dataset_name or dataset_location,
            project_name=current_project_name or "",
            on_column_done=_progress,
        )

        # Attributes that hold no real value at all: their checks are 'no_data', not failed
        from app.services.reference_dq import mark_blank_attributes

        mark_blank_attributes(check_results, empty_cols)

        passed = sum(1 for r in check_results if r["status"] == "pass")
        failed_checks = sum(1 for r in check_results if r["status"] == "fail")
        total = len(check_results)
        completed_at = datetime.now(timezone.utc)

        # Persist results
        for r in check_results:
            result = DQResult(
                run_id=run_uuid,
                check_name=r["check_name"], check_type=r["check_type"], column_name=r["column_name"],
                data_type=r.get("data_type"), remarks=r.get("remarks") or "-",
                status=r["status"], actual_value=str(r["score"]),
                row_count=r["row_count"], failed_count=r["failed_count"],
                details=r.get("details", {}),
                business_rules=r.get("business_rules"), regex_pattern=r.get("regex_pattern"),
                regex_version=r.get("regex_version"),
            )
            db.add(result)
            db.flush()  # assigns result.id for the findings below

            for f in r.get("findings", []):
                db.add(DQFinding(
                    result_id=result.id, severity=f["severity"], description=f["description"],
                    recommendation=f.get("recommendation"), status="open",
                ))

        run.status = "completed"
        run.completed_at = completed_at
        run.total_checks = total
        run.passed_checks = passed
        run.failed_checks = failed_checks
        run.overall_score = overall_score
        run.empty_attributes = empty_cols
        db.commit()
        db.close()

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
        category = classify_failure(exc)
        detail = failure_detail(exc, category, model=_dq_model(ai_config))
        # Retry only when the cause can go away by itself (AI service busy/down, database busy)
        will_retry = CATEGORIES[category].transient and self.request.retries < self.max_retries
        logger.error("DQ run %s failed (%s, retry=%s): %s", run_id, category, will_retry, exc)
        if will_retry:
            detail = (f"Attempt {self.request.retries + 1} of {self.max_retries + 1} failed; "
                      f"retrying automatically in 60 s. {detail}")
        try:
            db.rollback()
            db.execute(update(DQRun).where(DQRun.id == run_uuid).values(
                status="pending" if will_retry else "failed", error_category=category, error_message=detail,
            ))
            db.commit()
        except Exception:
            pass
        finally:
            db.close()
        if will_retry:
            raise self.retry(exc=exc, countdown=60)
        return {"run_id": run_id, "status": "failed", "error_category": category}


@shared_task(
    bind=True,
    name="app.worker.tasks.dq.archive_to_gcp",
    max_retries=2,
)
def archive_to_gcp(self, run_id: str) -> dict:
    """Write run summary to BigQuery and upload report to GCS."""
    from sqlalchemy import select

    from app.database import get_sync_session
    from app.models.dq import DQGCPArchive, DQRun

    run_uuid = UUID(run_id)
    try:
        with get_sync_session() as db:
            if db.get(DQRun, run_uuid) is None:
                return {"error": "run not found"}

            gcs_path = f"gs://dq-governance-outputs/{run_id}/dq_results.xlsx"

            # Upsert on run_id (one archive row per run)
            archive = db.scalars(select(DQGCPArchive).where(DQGCPArchive.run_id == run_uuid)).first()
            if archive is None:
                archive = DQGCPArchive(run_id=run_uuid, bq_dataset="dq_governance", bq_table="run_summaries")
                db.add(archive)
            archive.gcs_report_path = gcs_path
            archive.archive_status = "completed"
            db.commit()

        logger.info("DQ run %s archived to GCS=%s", run_id, gcs_path)
        return {"run_id": run_id, "gcs_path": gcs_path}

    except Exception as exc:
        logger.error("archive_to_gcp failed for run %s: %s", run_id, exc)
        raise self.retry(exc=exc, countdown=120)
