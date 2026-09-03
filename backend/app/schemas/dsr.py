import uuid
from datetime import datetime, date
from typing import Any, Optional
from pydantic import BaseModel


class DSRCreate(BaseModel):
    dataset_name: str
    recipient: str
    purpose: str
    is_ai_use: bool = False
    duration_start: date
    duration_end: date
    project_id: uuid.UUID


class DSRUpdate(BaseModel):
    dataset_name: Optional[str] = None
    recipient: Optional[str] = None
    purpose: Optional[str] = None
    is_ai_use: Optional[bool] = None
    duration_start: Optional[date] = None
    duration_end: Optional[date] = None


class DSRApprovalOut(BaseModel):
    id: uuid.UUID
    approver_id: uuid.UUID
    approver_role: str
    approver_name: str = ""
    step_order: int
    status: str
    comments: Optional[str] = None
    actioned_at: Optional[datetime] = None
    model_config = {"from_attributes": True}


class AIChecklistApprovalOut(BaseModel):
    id: uuid.UUID
    approver_id: uuid.UUID
    approver_role: str
    approver_name: str = ""
    step_order: int
    status: str
    comments: Optional[str] = None
    actioned_at: Optional[datetime] = None
    model_config = {"from_attributes": True}


class AIChecklistOut(BaseModel):
    id: uuid.UUID
    checklist_json: dict[str, Any] = {}
    status: str = "draft"
    validated_by: Optional[uuid.UUID] = None
    validated_at: Optional[datetime] = None
    approvals: list[AIChecklistApprovalOut] = []
    model_config = {"from_attributes": True}


class AIChecklistUpdate(BaseModel):
    checklist_json: Optional[dict[str, Any]] = None


class DSROut(BaseModel):
    id: uuid.UUID
    tracking_id: str
    project_id: uuid.UUID
    project_code: Optional[str] = None
    project_name: str = ""
    requester_id: uuid.UUID
    dataset_name: str
    recipient: str
    purpose: str
    is_ai_use: bool
    duration_start: date
    duration_end: date
    project_end_date: Optional[date] = None
    status: str
    created_at: datetime
    updated_at: datetime
    approvals: list[DSRApprovalOut] = []
    ai_checklist: Optional[AIChecklistOut] = None
    model_config = {"from_attributes": True}


class DSRListItem(BaseModel):
    id: uuid.UUID
    tracking_id: str
    project_id: uuid.UUID
    project_code: Optional[str] = None
    project_name: str
    recipient: str
    status: str
    is_signed: bool = False
    signed_at: Optional[datetime] = None
    checklist_status: Optional[str] = None
    is_ai_use: bool
    duration_end: date
    project_end_date: Optional[date] = None
    created_at: datetime
    model_config = {"from_attributes": True}


class PaginatedDSR(BaseModel):
    items: list[DSRListItem]
    total: int
    page: int
    page_size: int
    pages: int


class TransitionRequest(BaseModel):
    target_status: str
    comments: Optional[str] = None


class ApprovalActionRequest(BaseModel):
    action: str  # "approve" | "reject"
    comments: Optional[str] = None


class DSAOut(BaseModel):
    id: uuid.UUID
    title: str
    file_path: Optional[str] = None
    validity_start: date
    validity_end: Optional[date] = None
    created_at: datetime
    model_config = {"from_attributes": True}


class DSACreate(BaseModel):
    title: str
    validity_start: date
    validity_end: Optional[date] = None
