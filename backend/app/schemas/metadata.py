import uuid
from datetime import datetime, date
from typing import Any, Optional
from pydantic import BaseModel


# ── Data Owner / Steward ───────────────────────────────────────────────────────

OWNER_ROLE_TYPES = [
    "data_owner",
    "lead_business_steward",
    "business_steward",
    "lead_it_steward",
    "it_steward",
]


class DataOwnerStewardCreate(BaseModel):
    role_type: str
    full_name: str
    email: str
    position: Optional[str] = None


class DataOwnerStewardOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    role_type: str
    full_name: str
    email: str
    position: Optional[str] = None
    created_at: datetime
    model_config = {"from_attributes": True}


# ── Source table discovery ─────────────────────────────────────────────────────

class SourceTableInfo(BaseModel):
    table_name: str
    column_count: int
    documented: bool            # true if at least one MetadataRecord exists for this table+project
    row_count: Optional[int] = None
    source_type: str            # gcp | excel


class UploadedMetadataTable(BaseModel):
    table_name: str
    columns: list[str]
    sample_rows: list[list[Any]] = []
    row_count: int = 0


class ProceedMetadataRequest(BaseModel):
    project_id: uuid.UUID
    source_type: str            # gcp | excel
    gcp_project: Optional[str] = None
    bq_dataset: Optional[str] = None
    table_names: Optional[list[str]] = None   # selected tables
    temp_file_key: Optional[str] = None        # for excel source (single, legacy)
    temp_file_keys: Optional[list[str]] = None # for excel source (multi-file)
    file_names: Optional[list[str]] = None     # original filenames matching temp_file_keys order
    uploaded_tables: Optional[list[UploadedMetadataTable]] = None


# ── Metadata Record ────────────────────────────────────────────────────────────

class MetadataRecordOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    seq_no: int
    business_users: str
    data_domain_table: str
    line_of_business: Optional[str] = None
    table_type: str
    project_name: str
    project_year: int
    data_steward: Optional[str] = None
    data_owner: Optional[str] = None
    data_attribute: str
    data_year: Optional[int] = None
    data_sensitivity: str
    data_grouping: Optional[str] = None
    business_term: Optional[str] = None
    business_definition: Optional[str] = None
    definition_status: str
    standard_format: Optional[str] = None
    distinct_values: Optional[str] = None
    is_primary_key: Optional[bool] = None
    is_nullable: Optional[bool] = None
    sample_data: Optional[str] = None
    data_type: Optional[str] = None
    data_level: str
    updated_date: Optional[date] = None
    updated_by: Optional[str] = None
    remarks: str
    source_type: str
    source_row_count: Optional[int] = None
    created_at: datetime
    model_config = {"from_attributes": True}


class MetadataRecordUpdate(BaseModel):
    line_of_business: Optional[str] = None
    table_type: Optional[str] = None
    data_steward: Optional[str] = None
    data_owner: Optional[str] = None
    data_year: Optional[int] = None
    data_sensitivity: Optional[str] = None
    data_grouping: Optional[str] = None
    business_term: Optional[str] = None
    business_definition: Optional[str] = None
    standard_format: Optional[str] = None
    definition_status: Optional[str] = None
    data_level: Optional[str] = None
    remarks: Optional[str] = None


class MetadataBatchSaveRequest(BaseModel):
    project_id: uuid.UUID
    records: list[dict[str, Any]]   # list of {id, ...fields}


class MetadataBatchSaveResult(BaseModel):
    saved: int
    errors: list[dict[str, str]]


class BulkGroupingRequest(BaseModel):
    project_id: uuid.UUID
    table_filter: str       # data_domain_table value to match
    data_grouping: str      # value to apply


class AIRegenerateRequest(BaseModel):
    record_id: uuid.UUID


class ProceedResponse(BaseModel):
    task_id: str
    message: str
    queued_records: int
    processed_records: int = 0
