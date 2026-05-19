import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel


class RetentionPolicyOut(BaseModel):
    id: uuid.UUID
    dataset_type: str
    retention_days: int
    policy_reference: Optional[str] = None
    model_config = {"from_attributes": True}


class RetentionPolicyCreate(BaseModel):
    dataset_type: str
    retention_days: int
    policy_reference: Optional[str] = None


class BAPDApprovalOut(BaseModel):
    id: uuid.UUID
    bapd_id: uuid.UUID
    approver_id: uuid.UUID
    approver_role: str
    step_order: int
    status: str
    comments: Optional[str] = None
    actioned_at: Optional[datetime] = None
    model_config = {"from_attributes": True}


class BAPDCreate(BaseModel):
    project_id: uuid.UUID
    dataset_name: str
    dataset_location: str
    retention_policy_id: Optional[uuid.UUID] = None
    expiry_date: date
    reason: str
    responsible_party_id: uuid.UUID


class BAPDUpdate(BaseModel):
    dataset_name: Optional[str] = None
    dataset_location: Optional[str] = None
    retention_policy_id: Optional[uuid.UUID] = None
    expiry_date: Optional[date] = None
    reason: Optional[str] = None
    responsible_party_id: Optional[uuid.UUID] = None


class BAPDOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    dataset_name: str
    dataset_location: str
    retention_policy_id: Optional[uuid.UUID] = None
    expiry_date: date
    reason: str
    responsible_party_id: uuid.UUID
    status: str
    pod_file_path: Optional[str] = None
    executed_at: Optional[datetime] = None
    executed_by: Optional[uuid.UUID] = None
    version: int
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime
    approvals: list[BAPDApprovalOut] = []
    model_config = {"from_attributes": True}


class BAPDListItem(BaseModel):
    id: uuid.UUID
    dataset_name: str
    dataset_location: str
    expiry_date: date
    status: str
    version: int
    pod_file_path: Optional[str] = None
    executed_at: Optional[datetime] = None
    created_at: datetime
    model_config = {"from_attributes": True}


class PaginatedBAPD(BaseModel):
    items: list[BAPDListItem]
    total: int
    page: int
    page_size: int
    pages: int


class TransitionRequest(BaseModel):
    target_status: str
    comments: Optional[str] = None


class ApprovalActionRequest(BaseModel):
    action: str  # approve | reject
    comments: Optional[str] = None


class EligibleDataset(BaseModel):
    dataset_name: str
    dataset_location: str
    expiry_date: date
    retention_policy_id: Optional[uuid.UUID] = None
    days_overdue: int
