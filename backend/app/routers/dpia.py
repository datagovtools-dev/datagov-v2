import copy
import math
import uuid
from datetime import date, datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select, extract
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, get_db
from app.core.rbac import require_permission
from app.core.workflow import WorkflowError, validate_transition
from app.models.dpia import DPIAApproval, DPIARecord
from app.models.dsr import DataSharingRequest
from app.models.project import Project
from app.models.user import AuditLog, User
from app.schemas.dpia import (
    ApprovalActionRequest, DPIACreate, DPIAListItem, DPIAOut, DPIAUpdate,
    PaginatedDPIA, TransitionRequest,
)
from app.worker.tasks.notifications import send_workflow_notification
from app.services.notification_service import notify_approval_requested, notify_approval_completed

router = APIRouter(prefix="/dpia", tags=["dpia"])
DB = Annotated[AsyncSession, Depends(get_db)]

_DPIA_STEP_LABELS = {1: "PIC Data Compliance", 2: "DM/PM Approval"}

_DPIA_OPTS = [
    selectinload(DPIARecord.approvals).selectinload(DPIAApproval.approver),
    selectinload(DPIARecord.project),
]

# ── Default governance template ────────────────────────────────────────────────

_DEFAULT_GOVERNANCE: dict = {
    "access": [
        {"id": "access_1", "item": "Data Sharing Request Document",
         "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_2", "item": "Revoke / Extermination Documentation",
         "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_3", "item": "Data Activity Records Documentation (during project)",
         "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_4", "item": "Role-Based Access Control Document",
         "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_5", "item": "Assess and Approve Documentation Above",
         "responsible": "Client", "status": "", "remarks": ""},
        {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)",
         "responsible": "Client", "status": "", "remarks": ""},
    ],
    "secure_data": [
        {"id": "secure_data_1",
         "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)",
         "responsible": "Client", "status": "", "remarks": ""},
    ],
    "secure_sharing_environment": [
        {"id": "secure_env_1",
         "item": "Provide Secure Environment or Schema to Enable Data Sharing",
         "responsible": "Client", "status": "", "remarks": ""},
    ],
    "data_definition": [
        {"id": "data_def_1", "item": "Create Metadata Documentation",
         "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "data_def_2", "item": "Measure Data Quality Index",
         "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "data_def_3", "item": "Assess and Approve Metadata Definition",
         "responsible": "Client", "status": "", "remarks": ""},
        {"id": "data_def_4",
         "item": "Assess and Approve Data Quality Measurement Approach and Index",
         "responsible": "Client", "status": "", "remarks": ""},
    ],
}


async def _next_tracking_id(db: AsyncSession) -> str:
    year = date.today().year
    count = (await db.execute(
        select(func.count()).where(
            extract("year", DPIARecord.created_at) == year
        )
    )).scalar_one()
    return f"DPIA-{year}-{count + 1:04d}"


async def _get_dpia_or_404(dpia_id: uuid.UUID, db: AsyncSession) -> DPIARecord:
    result = await db.execute(
        select(DPIARecord).options(*_DPIA_OPTS).where(DPIARecord.id == dpia_id)
    )
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="DPIA not found")
    return record


@router.get("", response_model=PaginatedDPIA)
async def list_dpias(
    db: DB,
    _: Annotated[User, Depends(require_permission("dpia:read"))],
    project_id: uuid.UUID | None = Query(default=None),
    status_filter: str = Query(default="", alias="status"),
    year: int | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedDPIA:
    # Latest DSR per project (for DSR ID and DSR status only)
    dsr_latest = (
        select(
            DataSharingRequest.project_id,
            DataSharingRequest.tracking_id.label("dsr_tracking_id"),
            DataSharingRequest.status.label("dsr_status"),
        )
        .distinct(DataSharingRequest.project_id)
        .order_by(DataSharingRequest.project_id, DataSharingRequest.created_at.desc())
        .subquery("dsr_latest")
    )

    base = select(DPIARecord)
    if project_id:
        base = base.where(DPIARecord.project_id == project_id)
    if status_filter:
        base = base.where(DPIARecord.status == status_filter)
    if year is not None:
        base = base.where(extract("year", DPIARecord.created_at) == year)
    total = (await db.execute(select(func.count()).select_from(base.subquery()))).scalar_one()

    q = (
        select(
            DPIARecord,
            dsr_latest.c.dsr_tracking_id,
            dsr_latest.c.dsr_status,
            Project.end_date.label("project_end_date"),
        )
        .outerjoin(dsr_latest, DPIARecord.project_id == dsr_latest.c.project_id)
        .outerjoin(Project, DPIARecord.project_id == Project.id)
    )
    if project_id:
        q = q.where(DPIARecord.project_id == project_id)
    if status_filter:
        q = q.where(DPIARecord.status == status_filter)
    if year is not None:
        q = q.where(extract("year", DPIARecord.created_at) == year)

    rows = (await db.execute(
        q.order_by(DPIARecord.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).all()

    items = [
        DPIAListItem(
            id=r.DPIARecord.id,
            tracking_id=r.DPIARecord.tracking_id,
            project_code=r.DPIARecord.project_code,
            project_name=r.DPIARecord.project_name,
            customer_name=r.DPIARecord.customer_name,
            process_name=r.DPIARecord.process_name,
            data_category=r.DPIARecord.data_category,
            risk_score=r.DPIARecord.risk_score,
            residual_risk=r.DPIARecord.residual_risk,
            status=r.DPIARecord.status,
            assessment_date=r.DPIARecord.assessment_date,
            version=r.DPIARecord.version,
            created_at=r.DPIARecord.created_at,
            dsr_tracking_id=r.dsr_tracking_id,
            dsr_status=r.dsr_status,
            dsr_sharing_end=r.project_end_date,
        )
        for r in rows
    ]
    return PaginatedDPIA(
        items=items,
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=DPIAOut, status_code=201)
async def create_dpia(
    body: DPIACreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dpia:create"))],
) -> DPIARecord:
    risk_score = None
    if body.likelihood_score and body.impact_score:
        risk_score = body.likelihood_score * body.impact_score
    tracking_id = await _next_tracking_id(db)
    governance = body.governance_json if body.governance_json else copy.deepcopy(_DEFAULT_GOVERNANCE)
    record = DPIARecord(
        project_id=body.project_id,
        process_name=body.process_name,
        purpose=body.purpose or "",
        data_category=body.data_category,
        risk_description=body.risk_description,
        mitigation_measures=body.mitigation_measures,
        residual_risk=body.residual_risk,
        likelihood_score=body.likelihood_score,
        impact_score=body.impact_score,
        risk_score=risk_score,
        assessment_date=body.assessment_date or date.today(),
        responsible_party_id=body.responsible_party_id or current_user.id,
        status="draft",
        tracking_id=tracking_id,
        governance_json=governance,
        created_by=current_user.id,
    )
    db.add(record)
    await db.flush()

    # Create approval stubs (step 1: PIC Data Compliance, step 2: DM/PM)
    proj = await db.get(Project, body.project_id)
    step_approvers = [
        ("pic_compliance", proj.pic_data_compliance_id if proj else None),
        ("dm_pm",          proj.delivery_manager_id    if proj else None),
    ]
    for step, (role, approver_id) in enumerate(step_approvers, 1):
        db.add(DPIAApproval(
            dpia_id=record.id,
            approver_id=approver_id or current_user.id,
            approver_role=role,
            step_order=step,
            status="pending",
        ))

    db.add(AuditLog(user_id=current_user.id, module="dpia", action="create",
                    entity_type="dpia", entity_id=str(record.id)))
    await db.commit()
    await db.refresh(record)
    return await _get_dpia_or_404(record.id, db)


@router.get("/{dpia_id}", response_model=DPIAOut)
async def get_dpia(
    dpia_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dpia:read"))],
) -> DPIARecord:
    return await _get_dpia_or_404(dpia_id, db)


@router.put("/{dpia_id}", response_model=DPIAOut)
async def update_dpia(
    dpia_id: uuid.UUID, body: DPIAUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dpia:update"))],
) -> DPIARecord:
    record = await _get_dpia_or_404(dpia_id, db)
    if record.status == "approved":
        raise HTTPException(status_code=400, detail="Approved DPIAs cannot be edited")
    for k, v in body.model_dump(exclude_none=True).items():
        setattr(record, k, v)
    if record.likelihood_score and record.impact_score:
        record.risk_score = record.likelihood_score * record.impact_score
    db.add(AuditLog(user_id=current_user.id, module="dpia", action="update",
                    entity_type="dpia", entity_id=str(dpia_id)))
    await db.commit()
    await db.refresh(record)
    return await _get_dpia_or_404(record.id, db)


@router.post("/{dpia_id}/submit", response_model=DPIAOut)
async def submit_dpia(
    dpia_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("dpia:update"))],
) -> DPIARecord:
    record = await _get_dpia_or_404(dpia_id, db)
    if record.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft DPIAs can be submitted")
    record.status = "submitted"
    step1_res = await db.execute(
        select(DPIAApproval).where(
            DPIAApproval.dpia_id == dpia_id,
            DPIAApproval.step_order == 1,
        )
    )
    step1 = step1_res.scalar_one_or_none()
    if step1:
        step1.status = "requested"
    db.add(AuditLog(user_id=current_user.id, module="dpia", action="submit",
                    entity_type="dpia", entity_id=str(dpia_id)))
    await db.commit()

    if step1 and step1.approver_id:
        step1_user = await db.get(User, step1.approver_id)
        if step1_user:
            await notify_approval_requested(
                db=db,
                approver=step1_user,
                module="dpia",
                tracking_id=record.tracking_id or str(dpia_id)[:8],
                entity_id=str(dpia_id),
                step=1,
                step_label=_DPIA_STEP_LABELS[1],
                actor_name=current_user.full_name,
            )
            await db.commit()

    return await _get_dpia_or_404(dpia_id, db)


@router.post("/{dpia_id}/approvals/{step}", response_model=DPIAOut)
async def action_dpia_approval(
    dpia_id: uuid.UUID, step: int, body: ApprovalActionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("dpia:approve"))],
) -> DPIARecord:
    record = await _get_dpia_or_404(dpia_id, db)
    approval_res = await db.execute(
        select(DPIAApproval).where(
            DPIAApproval.dpia_id == dpia_id,
            DPIAApproval.step_order == step,
        )
    )
    approval = approval_res.scalar_one_or_none()
    if not approval:
        raise HTTPException(status_code=404, detail="Approval step not found")
    if approval.status not in ("pending", "requested"):
        raise HTTPException(status_code=400, detail="Approval step already actioned")

    if approval.approver_id and current_user.id != approval.approver_id and not current_user.is_super_admin:
        raise HTTPException(
            status_code=403,
            detail="Only the designated approver or a Super Admin can approve/reject this step.",
        )

    approval.approver_id = current_user.id
    approval.status = "approved" if body.action == "approve" else "rejected"
    approval.comments = body.comments
    approval.actioned_at = datetime.now(timezone.utc)

    next_approval = None
    if body.action == "approve":
        next_res = await db.execute(
            select(DPIAApproval).where(
                DPIAApproval.dpia_id == dpia_id,
                DPIAApproval.step_order == step + 1,
            )
        )
        next_approval = next_res.scalar_one_or_none()
        if next_approval:
            next_approval.status = "requested"
            record.status = "under_review"
        else:
            record.status = "approved"
    else:
        record.status = "rejected"

    db.add(AuditLog(
        user_id=current_user.id, module="dpia", action=f"approval_{body.action}",
        entity_type="dpia", entity_id=str(dpia_id),
        details={"step": step, "comments": body.comments},
    ))
    await db.commit()

    if body.action == "approve" and next_approval:
        next_user = await db.get(User, next_approval.approver_id)
        if next_user:
            await notify_approval_requested(
                db=db,
                approver=next_user,
                module="dpia",
                tracking_id=record.tracking_id or str(dpia_id)[:8],
                entity_id=str(dpia_id),
                step=step + 1,
                step_label=_DPIA_STEP_LABELS.get(step + 1, f"Step {step + 1}"),
                actor_name=current_user.full_name,
            )
            await db.commit()
    elif body.action == "approve" and not next_approval:
        creator = await db.get(User, record.created_by)
        if creator:
            await notify_approval_completed(
                db=db,
                requester_id=creator.id,
                requester_email=creator.email,
                module="dpia",
                tracking_id=record.tracking_id or str(dpia_id)[:8],
                entity_id=str(dpia_id),
                status="approved",
                actor_name=current_user.full_name,
            )
            await db.commit()
    elif body.action == "reject":
        creator = await db.get(User, record.created_by)
        if creator:
            await notify_approval_completed(
                db=db,
                requester_id=creator.id,
                requester_email=creator.email,
                module="dpia",
                tracking_id=record.tracking_id or str(dpia_id)[:8],
                entity_id=str(dpia_id),
                status="rejected",
                actor_name=current_user.full_name,
                comments=body.comments,
            )
            await db.commit()

    return await _get_dpia_or_404(dpia_id, db)


@router.post("/{dpia_id}/transition", response_model=DPIAOut)
async def transition_dpia(
    dpia_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("dpia:approve"))],
) -> DPIARecord:
    record = await _get_dpia_or_404(dpia_id, db)
    try:
        validate_transition("dpia", record.status, body.target_status)
    except WorkflowError as e:
        raise HTTPException(status_code=400, detail=str(e))
    old = record.status
    record.status = body.target_status
    if body.target_status not in ("draft", "rejected"):
        record.version += 1
    db.add(AuditLog(
        user_id=current_user.id, module="dpia", action=f"transition_{body.target_status}",
        entity_type="dpia", entity_id=str(dpia_id),
        details={"from": old, "to": body.target_status},
    ))
    await db.commit()
    event_map = {"submitted": "dpia_submitted", "approved": "dpia_approved"}
    event = event_map.get(body.target_status)
    if event:
        send_workflow_notification.delay(
            event=event, entity_id=str(dpia_id), recipients=[],
            context={"entity_id": str(dpia_id), "actor": current_user.full_name},
        )
    return await _get_dpia_or_404(dpia_id, db)
