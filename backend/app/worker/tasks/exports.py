"""
Celery tasks: async export engine — PDF (WeasyPrint), XLSX (openpyxl), CSV.
"""
from __future__ import annotations

import csv
import io
import logging
import os
import tempfile
from typing import Any

from celery import shared_task

logger = logging.getLogger(__name__)

# Registered export renderers per module + format
_COLUMN_MAP: dict[str, list[str]] = {
    "dsr": ["tracking_id", "dataset_name", "recipient", "purpose", "status",
            "duration_start", "duration_end", "is_ai_use", "created_at"],
    "dpia": ["process_name", "purpose", "data_category", "risk_description",
             "likelihood_score", "impact_score", "risk_score", "residual_risk",
             "assessment_date", "status", "version"],
    "ropa": ["process_name", "purpose", "data_category", "data_subject",
             "legal_basis", "retention_period", "recipient", "status", "version"],
    "bapd": ["dataset_name", "dataset_location", "expiry_date", "reason",
             "status", "executed_at", "version"],
    "metadata": ["seq_no", "data_domain_table", "data_attribute", "data_sensitivity",
                 "data_grouping", "business_term", "business_definition", "definition_status",
                 "data_type", "data_level", "is_primary_key", "is_nullable"],
    "dq": ["run_name", "dataset_name", "status", "total_checks",
           "passed_checks", "failed_checks", "overall_score", "created_at"],
}


@shared_task(
    bind=True,
    name="app.worker.tasks.exports.generate_export",
    max_retries=2,
)
def generate_export(
    self,
    module: str,
    fmt: str,
    records: list[dict[str, Any]],
    filename_prefix: str = "export",
) -> dict[str, str]:
    """
    Generate an export file and return its temp path.
    fmt: 'csv' | 'xlsx' | 'pdf'
    Returns: {"path": "/tmp/...", "filename": "...", "content_type": "..."}
    """
    columns = _COLUMN_MAP.get(module, list(records[0].keys()) if records else [])

    if fmt == "csv":
        return _export_csv(records, columns, filename_prefix)
    elif fmt == "xlsx":
        return _export_xlsx(records, columns, filename_prefix)
    elif fmt == "pdf":
        return _export_pdf(records, columns, filename_prefix, module)
    else:
        raise ValueError(f"Unsupported export format: {fmt}")


def _export_csv(records: list[dict], columns: list[str], prefix: str) -> dict[str, str]:
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".csv", prefix=f"{prefix}_")
    with open(tmp.name, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(records)
    return {"path": tmp.name, "filename": f"{prefix}.csv", "content_type": "text/csv"}


def _export_xlsx(records: list[dict], columns: list[str], prefix: str) -> dict[str, str]:
    try:
        import openpyxl
        from openpyxl.styles import Font, PatternFill, Alignment
    except ImportError:
        raise RuntimeError("openpyxl not installed")

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = prefix.capitalize()

    # Header row
    header_fill = PatternFill("solid", fgColor="1B2A4A")
    header_font = Font(bold=True, color="FFFFFF")
    for col_i, col_name in enumerate(columns, 1):
        cell = ws.cell(row=1, column=col_i, value=col_name.replace("_", " ").title())
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center")

    # Data rows
    for row_i, record in enumerate(records, 2):
        for col_i, col_name in enumerate(columns, 1):
            ws.cell(row=row_i, column=col_i, value=str(record.get(col_name, "") or ""))

    # Auto-width
    for col in ws.columns:
        max_len = max((len(str(c.value or "")) for c in col), default=10)
        ws.column_dimensions[col[0].column_letter].width = min(max_len + 4, 50)

    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".xlsx", prefix=f"{prefix}_")
    wb.save(tmp.name)
    return {
        "path": tmp.name,
        "filename": f"{prefix}.xlsx",
        "content_type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    }


def _export_pdf(records: list[dict], columns: list[str], prefix: str, module: str) -> dict[str, str]:
    try:
        from weasyprint import HTML as WP_HTML
    except ImportError:
        raise RuntimeError("weasyprint not installed")

    rows_html = "".join(
        "<tr>" + "".join(f"<td>{record.get(c, '')}</td>" for c in columns) + "</tr>"
        for record in records
    )
    headers_html = "".join(f"<th>{c.replace('_',' ').title()}</th>" for c in columns)
    html_content = f"""
    <html><head><style>
      body{{font-family:Arial,sans-serif;font-size:11px;color:#2C3E50}}
      h1{{color:#1B2A4A;font-size:16px}}
      table{{width:100%;border-collapse:collapse;margin-top:12px}}
      th{{background:#1B2A4A;color:white;padding:6px 8px;text-align:left;font-size:10px}}
      td{{padding:5px 8px;border-bottom:1px solid #E2E8F0;font-size:10px}}
      tr:nth-child(even){{background:#F8FAFC}}
    </style></head><body>
      <h1>{module.upper()} Export Report</h1>
      <p style="color:#718096;font-size:10px">Generated: {__import__('datetime').datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}</p>
      <table><thead><tr>{headers_html}</tr></thead><tbody>{rows_html}</tbody></table>
    </body></html>
    """
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".pdf", prefix=f"{prefix}_")
    WP_HTML(string=html_content).write_pdf(tmp.name)
    return {"path": tmp.name, "filename": f"{prefix}.pdf", "content_type": "application/pdf"}
