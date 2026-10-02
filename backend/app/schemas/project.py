import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field

# project_code is not accepted from clients: the API assigns PRJ-<project_year>-<next number>.
class ProjectCreate(BaseModel):
    project_name: str
    customer_name: str
    line_of_business: Optional[str] = None
    use_case: Optional[str] = None
    project_year: int = Field(ge=1000, le=9999)
    project_category: str
    is_monetized: bool = False
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    sme_id: Optional[uuid.UUID] = None
    delivery_manager_id: Optional[uuid.UUID] = None
    project_manager_id: Optional[uuid.UUID] = None
    dgo_id: Optional[uuid.UUID] = None
    metadata_officer_id: Optional[uuid.UUID] = None
    dq_officer_id: Optional[uuid.UUID] = None
    pic_data_compliance_id: Optional[uuid.UUID] = None


class ProjectUpdate(BaseModel):
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    line_of_business: Optional[str] = None
    use_case: Optional[str] = None
    project_year: Optional[int] = Field(default=None, ge=1000, le=9999)
    project_category: Optional[str] = None
    is_monetized: Optional[bool] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    sme_id: Optional[uuid.UUID] = None
    delivery_manager_id: Optional[uuid.UUID] = None
    project_manager_id: Optional[uuid.UUID] = None
    dgo_id: Optional[uuid.UUID] = None
    metadata_officer_id: Optional[uuid.UUID] = None
    dq_officer_id: Optional[uuid.UUID] = None
    pic_data_compliance_id: Optional[uuid.UUID] = None


class ProjectOut(BaseModel):
    id: uuid.UUID
    project_code: Optional[str] = None
    project_name: str
    customer_name: str
    line_of_business: Optional[str] = None
    use_case: Optional[str] = None
    project_year: int
    project_category: str
    is_monetized: bool
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    sme_id: Optional[uuid.UUID] = None
    delivery_manager_id: Optional[uuid.UUID] = None
    project_manager_id: Optional[uuid.UUID] = None
    dgo_id: Optional[uuid.UUID] = None
    metadata_officer_id: Optional[uuid.UUID] = None
    dq_officer_id: Optional[uuid.UUID] = None
    pic_data_compliance_id: Optional[uuid.UUID] = None
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ProjectListItem(BaseModel):
    id: uuid.UUID
    project_code: Optional[str] = None
    project_name: str
    customer_name: str
    project_year: int
    project_category: str
    is_monetized: bool
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class NextProjectCode(BaseModel):
    project_year: int
    project_code: str


class SourceFileRetentionOut(BaseModel):
    """How long the project's uploaded source files are kept (see app/services/retention.py)."""
    end_date: Optional[date] = None
    expiry_date: Optional[date] = None   # files are deleted on this day
    warning_date: Optional[date] = None
    basis: str                           # "default" (end date + 30 days) | "ropa" (approved ROPA)
    default_days: int
    ropa_retention_period: Optional[str] = None
    ropa_process_name: Optional[str] = None
    unreadable_ropa_periods: list[str] = []


class ProjectFiltersResponse(BaseModel):
    years: list[int]
    categories: list[str]
    clients: list[str]


class PaginatedProjects(BaseModel):
    items: list[ProjectListItem]
    total: int
    page: int
    page_size: int
    pages: int
