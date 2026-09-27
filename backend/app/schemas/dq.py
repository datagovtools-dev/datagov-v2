import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any, Optional
from pydantic import BaseModel, field_validator


# ── Project source files ───────────────────────────────────────────────────────

class ProjectSourceFileOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    source_type: str
    original_filename: str
    stored_path: str
    file_size: Optional[int] = None
    uploaded_at: datetime
    uploaded_by: Optional[str] = None
    file_available: bool = True  # False when the uploaded file is no longer in the uploads folder
    active_run_id: Optional[uuid.UUID] = None      # a DQ run of this file is queued or running
    active_run_status: Optional[str] = None
    model_config = {"from_attributes": True}


class ProjectFilePreviewResult(BaseModel):
    file_id: uuid.UUID
    filename: str
    source_type: str
    sheet_name: str
    row_count: int
    columns: list[str]
    preview_rows: list[dict[str, Any]]
    file_size: Optional[int] = None
    uploaded_at: datetime


class ProjectFileDQSummary(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    source_type: str
    original_filename: str
    file_size: Optional[int] = None
    uploaded_at: datetime
    total_runs: int = 0
    latest_run_id: Optional[uuid.UUID] = None
    latest_run_name: Optional[str] = None
    latest_run_status: Optional[str] = None
    latest_run_score: Optional[str] = None
    latest_run_date: Optional[datetime] = None


class DQTableSummary(BaseModel):
    table_name: str
    source_type: str
    attribute_count: int = 0
    source_file_id: Optional[uuid.UUID] = None
    total_runs: int = 0
    latest_run_id: Optional[uuid.UUID] = None
    latest_run_name: Optional[str] = None
    latest_run_status: Optional[str] = None
    latest_run_score: Optional[str] = None
    latest_run_date: Optional[datetime] = None
    # The latest_run_* fields show the newest run WITH results, so a re-run keeps the previous
    # version visible; a newer run without results (queued, running or failed) is reported here.
    latest_run_version: Optional[int] = None
    newer_run_id: Optional[uuid.UUID] = None
    newer_run_status: Optional[str] = None
    newer_run_version: Optional[int] = None


class DQProgressRun(BaseModel):
    run_id: uuid.UUID
    dataset_name: str
    version: int
    status: str
    created_at: datetime


class DQProjectProgress(BaseModel):
    """Progress page: queued/running runs of a project plus runs that finished in the last hours."""
    project_id: uuid.UUID
    active_count: int
    eta_seconds: Optional[int] = None  # until the last active run of the project finishes
    runs: list[DQProgressRun] = []


# ── Source validation ──────────────────────────────────────────────────────────

class GCPConnectionRequest(BaseModel):
    gcp_project: str
    bq_dataset: str
    bq_table: str
    # SA key JSON is uploaded as a file; validated in the router


class GCPConnectionResult(BaseModel):
    valid: bool
    message: str
    row_count: Optional[int] = None
    columns: Optional[list[str]] = None


class ExcelPreviewResult(BaseModel):
    filename: str
    sheet_name: str
    row_count: int
    columns: list[str]
    preview_rows: list[dict[str, Any]]
    temp_file_key: str   # opaque key used when creating the run


# ── DQ Run ─────────────────────────────────────────────────────────────────────

class DQRunCreate(BaseModel):
    project_id: uuid.UUID
    run_name: str
    source_type: str          # gcp | excel | project_file
    dataset_name: str
    dataset_location: str
    # GCP params (when source_type == 'gcp')
    gcp_project: Optional[str] = None
    bq_dataset: Optional[str] = None
    bq_table: Optional[str] = None
    # Excel params (when source_type == 'excel')
    temp_file_key: Optional[str] = None
    sheet_name: Optional[str] = None
    # Project file params (when source_type == 'project_file')
    source_file_id: Optional[uuid.UUID] = None


class DQFindingOut(BaseModel):
    id: uuid.UUID
    severity: str
    description: str
    recommendation: Optional[str] = None
    status: str
    model_config = {"from_attributes": True}


class DQResultOut(BaseModel):
    id: uuid.UUID
    check_name: str
    check_type: str
    column_name: Optional[str] = None
    data_type: Optional[str] = None
    status: str
    expected_value: Optional[str] = None
    actual_value: Optional[str] = None
    row_count: Optional[int] = None
    failed_count: Optional[int] = None
    details: Optional[dict[str, Any]] = None
    business_rules: Optional[str] = None
    regex_pattern: Optional[str] = None
    regex_version: Optional[str] = None
    remarks: Optional[str] = None
    findings: list[DQFindingOut] = []
    model_config = {"from_attributes": True}


class DQGCPArchiveOut(BaseModel):
    id: uuid.UUID
    gcs_report_path: Optional[str] = None
    bq_dataset: Optional[str] = None
    bq_table: Optional[str] = None
    archived_at: datetime
    archive_status: str
    error_message: Optional[str] = None
    model_config = {"from_attributes": True}


class DQRunOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    source_file_id: Optional[uuid.UUID] = None
    run_name: str
    dataset_name: str
    dataset_location: str
    version: Optional[int] = None
    status: str
    total_checks: int
    passed_checks: int
    failed_checks: int
    overall_score: Optional[Decimal] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    triggered_by: uuid.UUID
    celery_task_id: Optional[str] = None
    created_at: datetime
    columns_total: Optional[int] = None
    columns_done: Optional[int] = None
    error_category: Optional[str] = None
    error_message: Optional[str] = None
    empty_attributes: Optional[list[str]] = None
    results: list[DQResultOut] = []
    gcp_archive: Optional[DQGCPArchiveOut] = None
    model_config = {"from_attributes": True}


class DQProjectReportTable(BaseModel):
    """One table (source file) of the project report: its latest run that has results."""
    dataset_name: str
    run: DQRunOut
    newer_run_status: Optional[str] = None  # set when a newer run exists but has no results (failed/running)


class DQProjectReport(BaseModel):
    project_id: uuid.UUID
    generated_at: datetime
    tables: list[DQProjectReportTable] = []
    tables_without_results: list[str] = []  # tables whose runs all failed or are still running


class DQRunListItem(BaseModel):
    id: uuid.UUID
    run_name: str
    dataset_name: str
    version: Optional[int] = None
    status: str
    total_checks: int
    passed_checks: int
    failed_checks: int
    overall_score: Optional[Decimal] = None
    created_at: datetime
    completed_at: Optional[datetime] = None
    model_config = {"from_attributes": True}


class PaginatedDQRun(BaseModel):
    items: list[DQRunListItem]
    total: int
    page: int
    page_size: int
    pages: int


class DQStatusResponse(BaseModel):
    run_id: uuid.UUID
    status: str
    progress_pct: int
    overall_score: Optional[Decimal] = None
    message: str
    # Progress and time estimate (Generate step)
    columns_total: Optional[int] = None
    columns_done: Optional[int] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    queue_position: Optional[int] = None      # runs ahead of this one in the worker queue
    eta_seconds: Optional[int] = None         # estimated seconds until this run is finished
    # Failure explanation (see app.services.dq_failures)
    error_category: Optional[str] = None
    error_title: Optional[str] = None
    error_explanation: Optional[str] = None
    error_action: Optional[str] = None
    error_detail: Optional[str] = None
    will_retry: bool = False


# ── Review ─────────────────────────────────────────────────────────────────────

class DQReviewAction(BaseModel):
    action: str   # approve | reject | request_revision
    comments: Optional[str] = None


# ── Re-run delta ───────────────────────────────────────────────────────────────

class DQDeltaItem(BaseModel):
    check_name: str
    column_name: Optional[str]
    prev_score: Optional[float]
    curr_score: Optional[float]
    delta: Optional[float]
    status_changed: bool
