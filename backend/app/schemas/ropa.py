import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class ROPACreate(BaseModel):
    project_id: uuid.UUID
    process_name: str
    purpose: str
    data_category: str
    data_subject: str
    legal_basis: str
    retention_period: str
    recipient: Optional[str] = None
    linked_asset_ids: Optional[list[str]] = None


class ROPAUpdate(BaseModel):
    process_name: Optional[str] = None
    purpose: Optional[str] = None
    data_category: Optional[str] = None
    data_subject: Optional[str] = None
    legal_basis: Optional[str] = None
    retention_period: Optional[str] = None
    recipient: Optional[str] = None
    linked_asset_ids: Optional[list[str]] = None


class ROPAOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    process_name: str
    purpose: str
    data_category: str
    data_subject: str
    legal_basis: str
    retention_period: str
    recipient: Optional[str] = None
    linked_asset_ids: Optional[list[str]] = None
    status: str
    version: int
    created_by: uuid.UUID
    created_by_name: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}


class ROPAListItem(BaseModel):
    id: uuid.UUID
    project_id: Optional[uuid.UUID] = None
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    process_name: str
    data_category: str
    legal_basis: str
    status: str
    version: int
    created_at: datetime
    model_config = {"from_attributes": True}


class PaginatedROPA(BaseModel):
    items: list[ROPAListItem]
    total: int
    page: int
    page_size: int
    pages: int


class TransitionRequest(BaseModel):
    target_status: str
    comments: Optional[str] = None


LEGAL_BASIS_OPTIONS = [
    "Consent",
    "Contract",
    "Legal Obligation",
    "Vital Interests",
    "Public Task",
    "Legitimate Interests",
]
