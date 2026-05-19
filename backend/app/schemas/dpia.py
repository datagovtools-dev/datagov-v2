import uuid
from datetime import datetime, date
from typing import Optional, Any
from pydantic import BaseModel, model_validator


class DPIAApprovalOut(BaseModel):
    id: uuid.UUID
    dpia_id: uuid.UUID
    approver_id: uuid.UUID
    approver_name: str
    approver_role: str
    step_order: int
    status: str
    comments: Optional[str] = None
    actioned_at: Optional[datetime] = None
    model_config = {"from_attributes": True}


class DPIACreate(BaseModel):
    project_id: uuid.UUID
    process_name: str
    data_category: str
    risk_description: str
    mitigation_measures: Optional[str] = None
    residual_risk: Optional[str] = None
    governance_json: Optional[dict] = None
    # auto-filled backend-side — no longer required from the form
    purpose: Optional[str] = None
    assessment_date: Optional[date] = None
    responsible_party_id: Optional[uuid.UUID] = None
    likelihood_score: Optional[int] = None
    impact_score: Optional[int] = None

    @model_validator(mode="after")
    def validate_scores(self):
        for field in ("likelihood_score", "impact_score"):
            v = getattr(self, field)
            if v is not None and not (1 <= v <= 5):
                raise ValueError(f"{field} must be between 1 and 5")
        return self


class DPIAUpdate(BaseModel):
    process_name: Optional[str] = None
    purpose: Optional[str] = None
    data_category: Optional[str] = None
    risk_description: Optional[str] = None
    mitigation_measures: Optional[str] = None
    residual_risk: Optional[str] = None
    likelihood_score: Optional[int] = None
    impact_score: Optional[int] = None
    assessment_date: Optional[date] = None
    responsible_party_id: Optional[uuid.UUID] = None
    governance_json: Optional[dict] = None


class DPIAOut(BaseModel):
    id: uuid.UUID
    tracking_id: Optional[str] = None
    project_id: uuid.UUID
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    process_name: str
    purpose: str
    data_category: str
    risk_description: str
    mitigation_measures: Optional[str] = None
    residual_risk: Optional[str] = None
    likelihood_score: Optional[int] = None
    impact_score: Optional[int] = None
    risk_score: Optional[int] = None
    assessment_date: date
    responsible_party_id: uuid.UUID
    status: str
    version: int
    governance_json: Optional[Any] = None
    approvals: list[DPIAApprovalOut] = []
    created_by: uuid.UUID
    created_at: datetime
    updated_at: datetime
    model_config = {"from_attributes": True}


class DPIAListItem(BaseModel):
    id: uuid.UUID
    tracking_id: Optional[str] = None
    project_code: Optional[str] = None
    project_name: Optional[str] = None
    customer_name: Optional[str] = None
    process_name: str
    data_category: str
    risk_score: Optional[int] = None
    residual_risk: Optional[str] = None
    status: str
    assessment_date: date
    version: int
    created_at: datetime
    dsr_tracking_id: Optional[str] = None
    dsr_status: Optional[str] = None
    dsr_sharing_end: Optional[date] = None
    model_config = {"from_attributes": True}


class PaginatedDPIA(BaseModel):
    items: list[DPIAListItem]
    total: int
    page: int
    page_size: int
    pages: int


class TransitionRequest(BaseModel):
    target_status: str
    comments: Optional[str] = None


class ApprovalActionRequest(BaseModel):
    action: str  # "approve" or "reject"
    comments: Optional[str] = None
