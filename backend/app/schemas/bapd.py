import uuid
from datetime import datetime, date
from typing import Any, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field, model_validator


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
    approver_name: str = ""
    approver_role: str
    step_order: int
    status: str
    comments: Optional[str] = None
    actioned_at: Optional[datetime] = None
    model_config = {"from_attributes": True}


class BAPDTargetDatasetCreate(BaseModel):
    dataset_name: str = Field(min_length=1, max_length=300)
    dataset_location: str = Field(min_length=1, max_length=2000)
    source_type: str | None = Field(default=None, max_length=60)


class BAPDTargetDatasetOut(BAPDTargetDatasetCreate):
    id: uuid.UUID
    display_order: int
    model_config = ConfigDict(from_attributes=True)


class BAPDCreate(BaseModel):
    project_id: uuid.UUID
    dataset_name: str | None = Field(default=None, max_length=300)
    dataset_location: str | None = Field(default=None, max_length=2000)
    datasets: list[BAPDTargetDatasetCreate] = Field(default_factory=list)
    retention_policy_id: Optional[uuid.UUID] = None
    expiry_date: date
    reason: str
    responsible_party_id: uuid.UUID

    @model_validator(mode="after")
    def normalize_legacy_single_dataset(self):
        if not self.datasets and self.dataset_name and self.dataset_location:
            self.datasets = [BAPDTargetDatasetCreate(
                dataset_name=self.dataset_name,
                dataset_location=self.dataset_location,
            )]
        if not self.datasets:
            raise ValueError("At least one BAPD dataset must be selected")
        return self


class BAPDUpdate(BaseModel):
    dataset_name: Optional[str] = None
    dataset_location: Optional[str] = None
    datasets: list[BAPDTargetDatasetCreate] | None = None
    retention_policy_id: Optional[uuid.UUID] = None
    expiry_date: Optional[date] = None
    reason: Optional[str] = None
    responsible_party_id: Optional[uuid.UUID] = None

    @model_validator(mode="after")
    def validate_dataset_update(self):
        if self.datasets is not None and not self.datasets:
            raise ValueError("At least one BAPD dataset must be selected")
        return self


class BAPDOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    project_sme_id: Optional[uuid.UUID] = None
    data_owner_registered: bool = False
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    dataset_name: str
    dataset_location: str
    datasets: list[BAPDTargetDatasetOut] = Field(default_factory=list)
    retention_policy_id: Optional[uuid.UUID] = None
    retention_policy_name: Optional[str] = None
    expiry_date: date
    reason: str
    responsible_party_id: uuid.UUID
    responsible_party_name: Optional[str] = None
    status: str
    approval_method: str = "form_sign_off"
    sign_off: dict[str, Any] = Field(default_factory=dict)
    is_final_signed: bool = False
    pod_file_path: Optional[str] = None
    executed_at: Optional[datetime] = None
    executed_by: Optional[uuid.UUID] = None
    version: int
    created_by: uuid.UUID
    created_by_name: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    approvals: list[BAPDApprovalOut] = Field(default_factory=list)
    model_config = {"from_attributes": True}


class BAPDListItem(BaseModel):
    id: uuid.UUID
    project_id: Optional[uuid.UUID] = None
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    dataset_name: str
    dataset_location: str
    dataset_count: int = 1
    expiry_date: date
    status: str
    approval_method: str = "form_sign_off"
    is_final_signed: bool = False
    version: int
    responsible_party_name: Optional[str] = None
    created_by_name: Optional[str] = None
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


class BAPDSignOffPayload(BaseModel):
    approved: Literal["Yes", "No"] | None = None
    prepared_by: str | None = None
    prepared_position: str | None = None
    prepared_signature: str | None = Field(default=None, max_length=2_000_000)
    prepared_date: str | None = None
    acknowledged_by: str | None = None
    acknowledged_position: str | None = None
    acknowledged_signature: str | None = Field(default=None, max_length=2_000_000)
    acknowledged_date: str | None = None
    model_config = ConfigDict(extra="ignore")


class BAPDSignOffUpdate(BaseModel):
    version: int = Field(ge=1)
    sign_off: BAPDSignOffPayload = Field(default_factory=BAPDSignOffPayload)


class BAPDExecuteRequest(BaseModel):
    confirmation_phrase: str = Field(min_length=1, max_length=64)


class TransitionRequest(BaseModel):
    target_status: str
    comments: Optional[str] = None


class ApprovalActionRequest(BaseModel):
    action: Literal["approve", "reject"]
    comments: Optional[str] = None


class EligibleDataset(BaseModel):
    dataset_name: str
    dataset_location: str
    expiry_date: date
    retention_policy_id: Optional[uuid.UUID] = None
    days_overdue: int
