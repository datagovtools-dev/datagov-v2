import copy
import math
import uuid
from datetime import date, datetime, time, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import extract, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, get_db
from app.core.rbac import require_permission
from app.core.workflow import validate_transition, WorkflowError
from app.models.dpia import DPIAApproval, DPIARecord
from app.models.dsr import (
    AIChecklistApproval, AIComplianceChecklist, DSRApproval,
    DataSharingAgreement, DataSharingRequest,
)
from app.models.project import Project
from app.models.user import AuditLog, Role, User, UserProjectRole
from app.schemas.dsr import (
    AIChecklistOut, AIChecklistUpdate, AIChecklistApprovalOut, ApprovalActionRequest,
    DSACreate, DSAOut, DSRCreate, DSRListItem, DSROut, DSRUpdate,
    PaginatedDSR, TransitionRequest,
)
from app.worker.tasks.notifications import send_workflow_notification

router = APIRouter(prefix="/dsr", tags=["dsr"])
DB = Annotated[AsyncSession, Depends(get_db)]

_DPIA_DEFAULT_GOVERNANCE: dict = {
    "access": [
        {"id": "access_1", "item": "Data Sharing Request Document", "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_2", "item": "Revoke / Extermination Documentation", "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_4", "item": "Role-Based Access Control Document", "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "access_5", "item": "Assess and Approve Documentation Above", "responsible": "Client", "status": "", "remarks": ""},
        {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "responsible": "Client", "status": "", "remarks": ""},
    ],
    "secure_data": [
        {"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "responsible": "Client", "status": "", "remarks": ""},
    ],
    "secure_sharing_environment": [
        {"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "responsible": "Client", "status": "", "remarks": ""},
    ],
    "data_definition": [
        {"id": "data_def_1", "item": "Create Metadata Documentation", "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "data_def_2", "item": "Measure Data Quality Index", "responsible": "Internal", "status": "", "remarks": ""},
        {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "responsible": "Client", "status": "", "remarks": ""},
        {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "responsible": "Client", "status": "", "remarks": ""},
    ],
}


async def _next_dpia_tracking_id(db: AsyncSession) -> str:
    year = date.today().year
    count = (await db.execute(
        select(func.count()).where(extract("year", DPIARecord.created_at) == year)
    )).scalar_one()
    return f"DPIA-{year}-{count + 1:04d}"


_DSR_OPTS = [
    selectinload(DataSharingRequest.approvals).selectinload(DSRApproval.approver),
    selectinload(DataSharingRequest.ai_checklist).selectinload(
        AIComplianceChecklist.approvals
    ).selectinload(AIChecklistApproval.approver),
    selectinload(DataSharingRequest.project),
]


def _end_of_day(d: date) -> date:
    """Sharing end is always treated as 23:59 — stored as the same date,
    flagged here so expiry checks use datetime.combine(d, time(23, 59))."""
    return d


def _next_tracking_id(year: int, seq: int) -> str:
    return f"DSR-{year}-{seq:04d}"


async def _gen_tracking_id(db: AsyncSession) -> str:
    year = datetime.now(timezone.utc).year
    count = (await db.execute(
        select(func.count()).where(
            func.extract("year", DataSharingRequest.created_at) == year
        )
    )).scalar_one()
    return _next_tracking_id(year, count + 1)


async def _find_approver_for_role(
    db: AsyncSession, role_name: str, project_id: uuid.UUID, fallback_id: uuid.UUID
) -> uuid.UUID:
    result = await db.execute(
        select(UserProjectRole.user_id)
        .join(Role, UserProjectRole.role_id == Role.id)
        .where(
            Role.name == role_name,
            UserProjectRole.project_id == project_id,
            UserProjectRole.revoked_at.is_(None),
        )
        .limit(1)
    )
    uid = result.scalar_one_or_none()
    return uid if uid else fallback_id


_STEP_LABELS = {1: "PIC Data Compliance Approval", 2: "DM / PM Approval", 3: "SME Sign Off", 4: "Client Sign Off"}
_SIGN_OFF_STEPS = {3, 4}

_AI_STEP_LABELS = {1: "PIC Data Compliance Approval", 2: "DM Sign-off", 3: "SME Sign-off"}
_AI_SIGN_OFF_STEPS = {3}

_AI_CHECKLIST_REQUIRED_ITEMS = [
    "before_use_1", "before_use_2", "before_use_3",
    "input_1", "input_2", "input_3",
    "output_1", "output_2",
    "utilization_1", "utilization_2",
]
_AI_SIGN_OFF_REQUIRED_FIELDS = ["approved", "prepared_by", "prepared_position", "acknowledged_by", "acknowledged_position"]


def _is_ai_checklist_complete(checklist_json: dict) -> bool:
    ai = checklist_json.get("ai_assessment", {})
    items = ai.get("items", {})
    for item_id in _AI_CHECKLIST_REQUIRED_ITEMS:
        if not items.get(item_id, {}).get("status"):
            return False
    so = ai.get("sign_off", {})
    for f in _AI_SIGN_OFF_REQUIRED_FIELDS:
        if not (so.get(f) or "").strip():
            return False
    return True


async def _get_user(db: AsyncSession, user_id: uuid.UUID) -> User | None:
    return (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()


def _notify_approver(user: User, step: int, dsr_id: str, tracking_id: str, actor_name: str) -> None:
    step_label = _STEP_LABELS.get(step, f"Step {step}")
    event = "dsr_sign_off_requested" if step in _SIGN_OFF_STEPS else "dsr_review_requested"
    send_workflow_notification.delay(
        event=event,
        entity_id=dsr_id,
        recipients=[user.email],
        context={
            "tracking_id": tracking_id,
            "actor": actor_name,
            "step": step,
            "step_label": step_label,
        },
    )


async def _get_dsr_or_404(dsr_id: uuid.UUID, db: AsyncSession) -> DataSharingRequest:
    result = await db.execute(
        select(DataSharingRequest)
        .options(*_DSR_OPTS)
        .where(DataSharingRequest.id == dsr_id)
    )
    dsr = result.scalar_one_or_none()
    if not dsr:
        raise HTTPException(status_code=404, detail="DSR not found")
    return dsr


# ── DSA ───────────────────────────────────────────────────────────────────────

@router.get("/agreements", response_model=list[DSAOut])
async def list_agreements(db: DB, _: Annotated[User, Depends(require_permission("dsr:read"))]) -> list:
    result = await db.execute(select(DataSharingAgreement).order_by(DataSharingAgreement.created_at.desc()))
    return result.scalars().all()


@router.post("/agreements", response_model=DSAOut, status_code=201)
async def create_agreement(
    body: DSACreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:create"))],
) -> DataSharingAgreement:
    dsa = DataSharingAgreement(**body.model_dump())
    db.add(dsa)
    await db.commit()
    await db.refresh(dsa)
    return dsa


# ── DSR CRUD ──────────────────────────────────────────────────────────────────

@router.get("", response_model=PaginatedDSR)
async def list_dsrs(
    db: DB,
    _: Annotated[User, Depends(require_permission("dsr:read"))],
    search: str = Query(default=""),
    status_filter: str = Query(default="", alias="status"),
    project_id: uuid.UUID | None = Query(default=None),
    is_ai_use: bool | None = Query(default=None),
    year: int | None = Query(default=None),
    checklist_status: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedDSR:
    q = (
        select(
            DataSharingRequest,
            Project.project_name,
            Project.project_code,
            Project.end_date.label("project_end_date"),
            (AIComplianceChecklist.validated_at.isnot(None)).label("is_signed"),
            AIComplianceChecklist.validated_at.label("signed_at"),
        )
        .join(Project, DataSharingRequest.project_id == Project.id)
        .outerjoin(AIComplianceChecklist, DataSharingRequest.id == AIComplianceChecklist.dsr_id)
    )
    if search:
        q = q.where(
            DataSharingRequest.tracking_id.ilike(f"%{search}%")
            | Project.project_name.ilike(f"%{search}%")
        )
    if status_filter:
        q = q.where(DataSharingRequest.status == status_filter)
    if project_id:
        q = q.where(DataSharingRequest.project_id == project_id)
    if is_ai_use is not None:
        q = q.where(DataSharingRequest.is_ai_use == is_ai_use)
    if year is not None:
        q = q.where(extract("year", DataSharingRequest.created_at) == year)
    if checklist_status == "signed":
        q = q.where(AIComplianceChecklist.validated_at.isnot(None))
    elif checklist_status == "pending_signoff":
        q = q.where(
            AIComplianceChecklist.validated_at.is_(None),
            DataSharingRequest.status.in_(["approved", "executed"]),
        )
    elif checklist_status == "in_progress":
        q = q.where(
            AIComplianceChecklist.validated_at.is_(None),
            DataSharingRequest.status.notin_(["approved", "executed"]),
        )

    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar_one()
    rows = (await db.execute(
        q.order_by(DataSharingRequest.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).all()

    items = [
        DSRListItem(
            id=r.DataSharingRequest.id,
            tracking_id=r.DataSharingRequest.tracking_id,
            project_id=r.DataSharingRequest.project_id,
            project_code=r.project_code,
            project_name=r.project_name,
            recipient=r.DataSharingRequest.recipient,
            status=r.DataSharingRequest.status,
            is_signed=bool(r.is_signed),
            signed_at=r.signed_at,
            is_ai_use=r.DataSharingRequest.is_ai_use,
            duration_end=r.DataSharingRequest.duration_end,
            project_end_date=r.project_end_date,
            created_at=r.DataSharingRequest.created_at,
        )
        for r in rows
    ]
    return PaginatedDSR(
        items=items,
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=DSROut, status_code=201)
async def create_dsr(
    body: DSRCreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:create"))],
) -> DataSharingRequest:
    tracking_id = await _gen_tracking_id(db)
    dsr = DataSharingRequest(
        **body.model_dump(),
        tracking_id=tracking_id,
        requester_id=current_user.id,
        status="draft",
    )
    db.add(dsr)
    await db.flush()

    # Always create the compliance checklist for every DSR
    checklist_rec = AIComplianceChecklist(dsr_id=dsr.id, checklist_json={}, status="draft")
    db.add(checklist_rec)
    await db.flush()  # populate checklist_rec.id

    # Look up approvers directly from project fields (reliable — no role-name guessing)
    proj_res = await db.execute(select(Project).where(Project.id == dsr.project_id))
    proj = proj_res.scalar_one_or_none()

    step_approvers = [
        ("pic_compliance", proj.pic_data_compliance_id if proj else None),
        ("dm_pm",          proj.delivery_manager_id    if proj else None),
        ("sme",            proj.sme_id                 if proj else None),
        ("client",         proj.dgo_id                 if proj else None),
    ]

    for step, (role, approver_id) in enumerate(step_approvers, 1):
        db.add(DSRApproval(
            dsr_id=dsr.id, approver_id=approver_id or current_user.id,
            approver_role=role, step_order=step,
            status="pending",
        ))

    # AI checklist 3-step approval stubs (always created so names are always visible)
    ai_step_approvers = [
        ("pic_compliance", proj.pic_data_compliance_id if proj else None),
        ("dm",             proj.delivery_manager_id    if proj else None),
        ("sme",            proj.sme_id                 if proj else None),
    ]
    for step, (role, approver_id) in enumerate(ai_step_approvers, 1):
        db.add(AIChecklistApproval(
            checklist_id=checklist_rec.id,
            approver_id=approver_id or current_user.id,
            approver_role=role, step_order=step,
            status="pending",
        ))

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action="create",
        entity_type="dsr", entity_id=str(dsr.id),
        details={"tracking_id": tracking_id},
    ))

    # Auto-create a DPIA for this project if none exists yet
    existing_dpia = (await db.execute(
        select(DPIARecord).where(DPIARecord.project_id == dsr.project_id).limit(1)
    )).scalar_one_or_none()
    if not existing_dpia:
        dpia_tracking_id = await _next_dpia_tracking_id(db)
        dpia_rec = DPIARecord(
            project_id=dsr.project_id,
            process_name=proj.project_name if proj else "—",
            purpose="",
            data_category="",
            risk_description="",
            assessment_date=date.today(),
            responsible_party_id=current_user.id,
            status="draft",
            tracking_id=dpia_tracking_id,
            governance_json=copy.deepcopy(_DPIA_DEFAULT_GOVERNANCE),
            created_by=current_user.id,
        )
        db.add(dpia_rec)
        await db.flush()
        for step, (role, approver_id) in enumerate([
            ("pic_compliance", proj.pic_data_compliance_id if proj else None),
            ("dm_pm",          proj.delivery_manager_id    if proj else None),
        ], 1):
            db.add(DPIAApproval(
                dpia_id=dpia_rec.id,
                approver_id=approver_id or current_user.id,
                approver_role=role, step_order=step, status="pending",
            ))

    dsr_id = dsr.id
    await db.commit()

    return await _get_dsr_or_404(dsr_id, db)


@router.get("/{dsr_id}", response_model=DSROut)
async def get_dsr(
    dsr_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dsr:read"))],
) -> DataSharingRequest:
    return await _get_dsr_or_404(dsr_id, db)


@router.put("/{dsr_id}", response_model=DSROut)
async def update_dsr(
    dsr_id: uuid.UUID, body: DSRUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:update"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    if dsr.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft DSRs can be edited")
    for k, v in body.model_dump(exclude_none=True).items():
        setattr(dsr, k, v)
    db.add(AuditLog(user_id=current_user.id, module="dsr", action="update",
                    entity_type="dsr", entity_id=str(dsr_id)))
    await db.commit()
    return await _get_dsr_or_404(dsr_id, db)


# ── Submit (draft → submitted, activates step 1) ─────────────────────────────

_CHECKLIST_REQUIRED_ITEMS = [
    "A_i_1", "A_i_2", "A_i_3",
    "A_ii_1", "A_ii_2", "A_ii_3", "A_ii_4",
    "B_i", "B_ii", "B_iii", "B_iv", "B_v", "B_vi",
    "C_i_1", "C_i_2", "C_i_3",
]
_SIGN_OFF_REQUIRED_FIELDS = ["approved", "prepared_by", "prepared_position", "acknowledged_by", "acknowledged_position"]


def _is_checklist_complete(checklist_json: dict, is_ai_use: bool) -> bool:
    required = list(_CHECKLIST_REQUIRED_ITEMS)
    if is_ai_use:
        required.append("D_i")
    for item_id in required:
        v = checklist_json.get(item_id, {})
        if not v.get("answer") or not (v.get("remarks") or "").strip():
            return False
    so = checklist_json.get("sign_off", {})
    for f in _SIGN_OFF_REQUIRED_FIELDS:
        if not (so.get(f) or "").strip():
            return False
    return True


@router.post("/{dsr_id}/submit", response_model=DSROut)
async def submit_dsr(
    dsr_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:create"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    if dsr.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft DSRs can be submitted")

    # Verify checklist completeness before allowing submission
    checklist_res = await db.execute(
        select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = checklist_res.scalar_one_or_none()
    if not checklist or not _is_checklist_complete(checklist.checklist_json or {}, dsr.is_ai_use):
        raise HTTPException(
            status_code=400,
            detail="Checklist incomplete: fill all sections A–D and sign-off fields (excluding signatures) before submitting.",
        )

    dsr.status = "submitted"

    # Activate step 1 (DGO)
    step1_res = await db.execute(
        select(DSRApproval).where(DSRApproval.dsr_id == dsr_id, DSRApproval.step_order == 1)
    )
    step1 = step1_res.scalar_one_or_none()
    step1_approver_id = None
    if step1:
        step1.status = "requested"
        step1_approver_id = step1.approver_id

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action="submit",
        entity_type="dsr", entity_id=str(dsr_id),
        details={"tracking_id": dsr.tracking_id},
    ))
    await db.commit()

    if step1_approver_id:
        step1_user = await _get_user(db, step1_approver_id)
        if step1_user:
            _notify_approver(step1_user, 1, str(dsr_id), dsr.tracking_id, current_user.full_name)

    return await _get_dsr_or_404(dsr_id, db)


# ── Workflow transition ────────────────────────────────────────────────────────

@router.post("/{dsr_id}/transition", response_model=DSROut)
async def transition_dsr(
    dsr_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:approve"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    try:
        validate_transition("dsr", dsr.status, body.target_status)
    except WorkflowError as e:
        raise HTTPException(status_code=400, detail=str(e))

    old_status = dsr.status
    dsr.status = body.target_status
    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action=f"transition_{body.target_status}",
        entity_type="dsr", entity_id=str(dsr_id),
        details={"from": old_status, "to": body.target_status, "comments": body.comments},
    ))
    await db.commit()

    # Fire notification async
    event_map = {"submitted": "dsr_submitted", "approved": "dsr_approved", "rejected": "dsr_rejected"}
    event = event_map.get(body.target_status)
    if event:
        send_workflow_notification.delay(
            event=event, entity_id=str(dsr_id),
            recipients=[],
            context={"tracking_id": dsr.tracking_id, "actor": current_user.full_name},
        )
    return await _get_dsr_or_404(dsr_id, db)


# ── Approval action ────────────────────────────────────────────────────────────

@router.post("/{dsr_id}/approvals/{step}", response_model=DSROut)
async def action_approval(
    dsr_id: uuid.UUID, step: int, body: ApprovalActionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:approve"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)

    approval_res = await db.execute(
        select(DSRApproval).where(
            DSRApproval.dsr_id == dsr_id,
            DSRApproval.step_order == step,
        )
    )
    approval = approval_res.scalar_one_or_none()
    if not approval:
        raise HTTPException(status_code=404, detail="Approval step not found")
    if approval.status not in ("pending", "requested"):
        raise HTTPException(status_code=400, detail="Approval step already actioned")

    approval.status = "approved" if body.action == "approve" else "rejected"
    approval.comments = body.comments
    approval.actioned_at = datetime.now(timezone.utc)

    next_approval = None
    if body.action == "approve":
        # Activate the next step
        next_approval_res = await db.execute(
            select(DSRApproval).where(
                DSRApproval.dsr_id == dsr_id,
                DSRApproval.step_order == step + 1,
            )
        )
        next_approval = next_approval_res.scalar_one_or_none()
        if next_approval:
            next_approval.status = "requested"
            dsr.status = "under_review"
        else:
            # No more steps — all approved
            dsr.status = "approved"
    else:
        dsr.status = "rejected"

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action=f"approval_{body.action}",
        entity_type="dsr", entity_id=str(dsr_id),
        details={"step": step, "comments": body.comments},
    ))
    await db.commit()

    # Post-commit notifications
    step_label = _STEP_LABELS.get(step, f"Step {step}")
    if body.action == "approve":
        if next_approval:
            next_user = await _get_user(db, next_approval.approver_id)
            if next_user:
                _notify_approver(next_user, step + 1, str(dsr_id), dsr.tracking_id, current_user.full_name)
    else:
        # Notify the requester of the rejection
        requester = await _get_user(db, dsr.requester_id)
        if requester:
            send_workflow_notification.delay(
                event="dsr_step_rejected",
                entity_id=str(dsr_id),
                recipients=[requester.email],
                context={
                    "tracking_id": dsr.tracking_id,
                    "actor": current_user.full_name,
                    "step": step,
                    "step_label": step_label,
                },
            )

    return await _get_dsr_or_404(dsr_id, db)


# ── AI Compliance Checklist ────────────────────────────────────────────────────

@router.get("/{dsr_id}/checklist", response_model=AIChecklistOut)
async def get_checklist(
    dsr_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dsr:read"))],
) -> AIComplianceChecklist:
    result = await db.execute(
        select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = result.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="No AI checklist for this DSR")
    return checklist


@router.put("/{dsr_id}/checklist", response_model=AIChecklistOut)
async def update_checklist(
    dsr_id: uuid.UUID, body: AIChecklistUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:update"))],
) -> AIComplianceChecklist:
    result = await db.execute(
        select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = result.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="No AI checklist for this DSR")
    if body.checklist_json is not None:
        checklist.checklist_json = body.checklist_json
    # Sign-off is complete only when both physical signatures are present
    cj = checklist.checklist_json or {}
    main_so = cj.get("sign_off", {})
    both_signed = bool(main_so.get("prepared_signature")) and bool(main_so.get("acknowledged_signature"))
    if both_signed:
        if not checklist.validated_at:
            checklist.validated_by = str(current_user.id)
            checklist.validated_at = datetime.now(timezone.utc)
    else:
        checklist.validated_by = None
        checklist.validated_at = None
    db.add(AuditLog(user_id=current_user.id, module="dsr", action="update_checklist",
                    entity_type="ai_checklist", entity_id=str(dsr_id)))
    await db.commit()
    await db.refresh(checklist)
    return checklist


# ── AI Checklist Submit ────────────────────────────────────────────────────────

@router.post("/{dsr_id}/checklist/submit", response_model=DSROut)
async def submit_ai_checklist(
    dsr_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:create"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    if not dsr.is_ai_use:
        raise HTTPException(status_code=400, detail="This DSR is not marked as AI use")

    checklist_res = await db.execute(
        select(AIComplianceChecklist)
        .options(selectinload(AIComplianceChecklist.approvals).selectinload(AIChecklistApproval.approver))
        .where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = checklist_res.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="AI checklist not found")
    if checklist.status != "draft":
        raise HTTPException(status_code=400, detail="AI checklist has already been submitted")
    if not _is_ai_checklist_complete(checklist.checklist_json or {}):
        raise HTTPException(
            status_code=400,
            detail="AI checklist incomplete: fill all assessment items and sign-off fields before submitting.",
        )

    checklist.status = "submitted"

    # Ensure approval stubs exist (safety net for checklists created before this feature)
    if not checklist.approvals:
        proj_res = await db.execute(select(Project).where(Project.id == dsr.project_id))
        proj = proj_res.scalar_one_or_none()
        ai_step_approvers = [
            ("pic_compliance", proj.pic_data_compliance_id if proj else None),
            ("dm",             proj.delivery_manager_id    if proj else None),
            ("sme",            proj.sme_id                 if proj else None),
        ]
        for step, (role, approver_id) in enumerate(ai_step_approvers, 1):
            db.add(AIChecklistApproval(
                checklist_id=checklist.id,
                approver_id=approver_id or current_user.id,
                approver_role=role, step_order=step,
                status="pending",
            ))
        await db.flush()

    # Activate step 1
    step1_res = await db.execute(
        select(AIChecklistApproval).where(
            AIChecklistApproval.checklist_id == checklist.id,
            AIChecklistApproval.step_order == 1,
        )
    )
    step1 = step1_res.scalar_one_or_none()
    step1_approver_id = None
    if step1:
        step1.status = "requested"
        step1_approver_id = step1.approver_id

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action="submit_ai_checklist",
        entity_type="ai_checklist", entity_id=str(checklist.id),
        details={"tracking_id": dsr.tracking_id},
    ))
    await db.commit()

    if step1_approver_id:
        step1_user = await _get_user(db, step1_approver_id)
        if step1_user:
            send_workflow_notification.delay(
                event="dsr_review_requested",
                entity_id=str(dsr_id),
                recipients=[step1_user.email],
                context={"tracking_id": dsr.tracking_id, "actor": current_user.full_name,
                         "step": 1, "step_label": _AI_STEP_LABELS[1]},
            )

    return await _get_dsr_or_404(dsr_id, db)


# ── AI Checklist Approval Action ───────────────────────────────────────────────

@router.post("/{dsr_id}/checklist/approvals/{step}", response_model=DSROut)
async def action_ai_checklist_approval(
    dsr_id: uuid.UUID, step: int, body: ApprovalActionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:approve"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)

    checklist_res = await db.execute(
        select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = checklist_res.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="AI checklist not found")

    approval_res = await db.execute(
        select(AIChecklistApproval).where(
            AIChecklistApproval.checklist_id == checklist.id,
            AIChecklistApproval.step_order == step,
        )
    )
    approval = approval_res.scalar_one_or_none()
    if not approval:
        raise HTTPException(status_code=404, detail="Approval step not found")
    if approval.status not in ("pending", "requested"):
        raise HTTPException(status_code=400, detail="Approval step already actioned")

    approval.status = "approved" if body.action == "approve" else "rejected"
    approval.comments = body.comments
    approval.actioned_at = datetime.now(timezone.utc)

    next_approval = None
    if body.action == "approve":
        next_approval_res = await db.execute(
            select(AIChecklistApproval).where(
                AIChecklistApproval.checklist_id == checklist.id,
                AIChecklistApproval.step_order == step + 1,
            )
        )
        next_approval = next_approval_res.scalar_one_or_none()
        if next_approval:
            next_approval.status = "requested"
            checklist.status = "under_review"
        else:
            checklist.status = "approved"
    else:
        checklist.status = "rejected"

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action=f"ai_checklist_approval_{body.action}",
        entity_type="ai_checklist", entity_id=str(checklist.id),
        details={"step": step, "comments": body.comments},
    ))
    await db.commit()

    if body.action == "approve" and next_approval:
        next_user = await _get_user(db, next_approval.approver_id)
        if next_user:
            send_workflow_notification.delay(
                event="dsr_sign_off_requested" if step + 1 in _AI_SIGN_OFF_STEPS else "dsr_review_requested",
                entity_id=str(dsr_id),
                recipients=[next_user.email],
                context={"tracking_id": dsr.tracking_id, "actor": current_user.full_name,
                         "step": step + 1, "step_label": _AI_STEP_LABELS.get(step + 1, f"Step {step + 1}")},
            )

    return await _get_dsr_or_404(dsr_id, db)
