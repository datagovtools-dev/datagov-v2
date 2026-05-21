import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel


class ProjectCreate(BaseModel):
    project_code: Optional[str] = None
    project_name: str
    customer_name: str
    line_of_business: Optional[str] = None
    use_case: Optional[str] = None
    project_year: int
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
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    line_of_business: Optional[str] = None
    use_case: Optional[str] = None
    project_year: Optional[int] = None
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
