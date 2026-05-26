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

class PostgresConnectionRequest(BaseModel):
    connection_string: str   # full DSN, e.g. postgresql://user:pass@host:5432/db
    table_name: str          # unqualified table name, e.g. "customer"


class PostgresConnectionResult(BaseModel):
    valid: bool
    message: str
    row_count: Optional[int] = None
    columns: Optional[list[str]] = None


class DQRunCreate(BaseModel):
    project_id: uuid.UUID
    run_name: str
    source_type: str          # gcp | excel | postgres | project_file
    dataset_name: str
    dataset_location: str
    # GCP params (when source_type == 'gcp')
    gcp_project: Optional[str] = None
    bq_dataset: Optional[str] = None
    bq_table: Optional[str] = None
    # Excel params (when source_type == 'excel')
    temp_file_key: Optional[str] = None
    sheet_name: Optional[str] = None
    # PostgreSQL/Supabase params (when source_type == 'postgres')
    postgres_connection_string: Optional[str] = None
    postgres_table: Optional[str] = None
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
    status: str
    expected_value: Optional[str] = None
    actual_value: Optional[str] = None
    row_count: Optional[int] = None
    failed_count: Optional[int] = None
    details: Optional[dict[str, Any]] = None
    business_rules: Optional[str] = None
    regex_pattern: Optional[str] = None
    ai_model: Optional[str] = None
    regex_version: Optional[str] = None
    column_category: Optional[str] = None
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
    results: list[DQResultOut] = []
    gcp_archive: Optional[DQGCPArchiveOut] = None
    model_config = {"from_attributes": True}


class DQRunListItem(BaseModel):
    id: uuid.UUID
    run_name: str
    dataset_name: str
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
