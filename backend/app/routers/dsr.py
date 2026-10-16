import copy
import math
import uuid
from datetime import date, datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import extract, func, select, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, get_db
from app.core.rbac import _user_has_permission, require_permission
from app.core.workflow import validate_transition, WorkflowError
from app.models.dpia import DPIAApproval, DPIARecord
from app.models.dsr import (
    AIComplianceChecklist, DSRApproval,
    DataSharingAgreement, DataSharingRequest,
)
from app.models.project import Project
from app.models.user import AuditLog, User
from app.schemas.dsr import (
    AIChecklistOut, AIChecklistUpdate,
    DSACreate, DSAOut, DSRCreate, DSRListItem, DSROut, DSRUpdate,
    PaginatedDSR, TransitionRequest,
)
from app.services.tracking_ids import next_yearly_tracking_id

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
    return await next_yearly_tracking_id(
        db, DPIARecord, DPIARecord.tracking_id, "DPIA"
    )


_DSR_OPTS = [
    selectinload(DataSharingRequest.approvals).selectinload(DSRApproval.approver),
    selectinload(DataSharingRequest.ai_checklist),
    selectinload(DataSharingRequest.project),
]


async def _gen_tracking_id(db: AsyncSession) -> str:
    return await next_yearly_tracking_id(
        db, DataSharingRequest, DataSharingRequest.tracking_id, "DSR"
    )


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


async def _require_dsr_access(
    dsr: DataSharingRequest,
    db: AsyncSession,
    current_user: User,
    permission: str = "dsr:read",
) -> None:
    if _user_has_permission(current_user, permission):
        return
    project = await db.get(Project, dsr.project_id)
    if project and current_user.id in {project.sme_id, dsr.requester_id}:
        return
    raise HTTPException(status_code=403, detail="You are not assigned to this DSR workflow")


def _dsr_actor_scope(current_user: User):
    return or_(
        Project.sme_id == current_user.id,
        DataSharingRequest.requester_id == current_user.id,
    )


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
    current_user: CurrentUser,
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
            AIComplianceChecklist.checklist_json.label("checklist_json"),
            (AIComplianceChecklist.validated_at.isnot(None)).label("is_signed"),
            AIComplianceChecklist.validated_at.label("signed_at"),
            AIComplianceChecklist.status.label("checklist_status"),
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
    # AICK status is based on draft/completed/sign-off state. Legacy approval
    # values remain query-compatible for old records but are no longer produced.
    unsigned = AIComplianceChecklist.validated_at.is_(None)
    if checklist_status == "signed":
        q = q.where(AIComplianceChecklist.validated_at.isnot(None))
    elif checklist_status in ("submitted", "under_review", "rejected"):
        q = q.where(unsigned, AIComplianceChecklist.status == checklist_status)
    elif checklist_status == "pending_approval":  # older links: submitted or under review
        q = q.where(unsigned, AIComplianceChecklist.status.in_(["submitted", "under_review"]))
    elif checklist_status == "pending_signoff":
        q = q.where(unsigned, AIComplianceChecklist.status == "approved")
    elif checklist_status == "in_progress":
        q = q.where(
            unsigned,
            AIComplianceChecklist.status.is_(None)
            | AIComplianceChecklist.status.notin_(["submitted", "under_review", "approved", "rejected"]),
        )

    if not _user_has_permission(current_user, "dsr:read"):
        q = q.where(_dsr_actor_scope(current_user))

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
            is_final_signed=_final_sign_off_complete(r.checklist_json),
            checklist_status=r.checklist_status,
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

    # Resolve the project once for the related DPIA auto-creation below.
    # DSR approval itself is completed by the form's Sign Off section.
    proj_res = await db.execute(select(Project).where(Project.id == dsr.project_id))
    proj = proj_res.scalar_one_or_none()

    # No DSR approval rows are created. The legacy table and response field are
    # retained only so historical records remain readable.

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
    current_user: CurrentUser,
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    await _require_dsr_access(dsr, db, current_user)
    return dsr


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


# ── Submit (draft → approved through Final Approval & Sign Off) ───────────────

_CHECKLIST_REQUIRED_ITEMS = [
    "A_i_1", "A_i_2", "A_i_3",
    "A_ii_1", "A_ii_2", "A_ii_3", "A_ii_4",
    "B_i", "B_ii", "B_iii", "B_iv", "B_v", "B_vi",
    "C_i_1", "C_i_2", "C_i_3",
]
_SIGN_OFF_REQUIRED_FIELDS = [
    "approved", "prepared_by", "prepared_position", "prepared_signature",
    "acknowledged_by", "acknowledged_position", "acknowledged_signature",
]


def _final_sign_off_complete(checklist_json: dict | None) -> bool:
    so = (checklist_json or {}).get("sign_off", {})
    return (
        so.get("approved") == "Yes"
        and all((so.get(field) or "").strip() for field in _SIGN_OFF_REQUIRED_FIELDS)
        and bool(so.get("prepared_signed_by"))
        and bool(so.get("acknowledged_signed_by"))
    )


def _is_checklist_complete(checklist_json: dict, is_ai_use: bool) -> bool:
    required = list(_CHECKLIST_REQUIRED_ITEMS)
    if is_ai_use:
        required.append("D_i")
    for item_id in required:
        v = checklist_json.get(item_id, {})
        if not v.get("answer") or not (v.get("remarks") or "").strip():
            return False
    so = checklist_json.get("sign_off", {})
    if so.get("approved") != "Yes":
        return False
    for f in _SIGN_OFF_REQUIRED_FIELDS:
        if not (so.get(f) or "").strip():
            return False
    return True


@router.post("/{dsr_id}/submit", response_model=DSROut)
async def submit_dsr(
    dsr_id: uuid.UUID, db: DB,
    current_user: CurrentUser,
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    await _require_dsr_access(dsr, db, current_user, "dsr:create")
    if dsr.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft DSRs can be submitted")
    if not dsr.project or dsr.project.sme_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only the assigned Project SME can submit the final DSR sign-off.",
        )

    # Verify checklist completeness before allowing submission
    checklist_res = await db.execute(
        select(AIComplianceChecklist).where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = checklist_res.scalar_one_or_none()
    if not checklist or not _is_checklist_complete(checklist.checklist_json or {}, dsr.is_ai_use):
        raise HTTPException(
            status_code=400,
            detail="Checklist incomplete: fill all sections A–D and complete both Sign Off signatures before submitting.",
        )
    sign_off = (checklist.checklist_json or {}).get("sign_off") or {}
    if not sign_off.get("prepared_signed_by") or not sign_off.get("acknowledged_signed_by"):
        raise HTTPException(
            status_code=400,
            detail="Save both Final Approval & Sign Off signatures through the platform before submitting.",
        )
    acknowledged_signed_by = sign_off.get("acknowledged_signed_by")
    if acknowledged_signed_by and acknowledged_signed_by != str(current_user.id):
        raise HTTPException(
            status_code=403,
            detail="The final acknowledged signature must be submitted by the assigned Project SME.",
        )

    # The completed Sign Off section is the approval. There is no separate
    # PIC -> DM/PM -> SME -> Client approval chain for a DSR.
    dsr.status = "approved"
    checklist.status = "approved"
    if not checklist.validated_at:
        checklist.validated_by = current_user.id
        checklist.validated_at = datetime.now(timezone.utc)

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action="submit",
        entity_type="dsr", entity_id=str(dsr_id),
        details={
            "tracking_id": dsr.tracking_id,
            "approval_workflow": False,
            "approval_method": "form_sign_off",
        },
    ))
    await db.commit()

    return await _get_dsr_or_404(dsr_id, db)

# ── Workflow transition ────────────────────────────────────────────────────────

@router.post("/{dsr_id}/transition", response_model=DSROut)
async def transition_dsr(
    dsr_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("dsr:approve"))],
) -> DataSharingRequest:
    dsr = await _get_dsr_or_404(dsr_id, db)
    if body.target_status in {"submitted", "under_review", "approved", "rejected"}:
        raise HTTPException(
            status_code=400,
            detail="DSR approval is completed in the form Sign Off section; no separate approval workflow is available.",
        )
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
    return await _get_dsr_or_404(dsr_id, db)


# ── AI Compliance Checklist ────────────────────────────────────────────────────

async def _get_checklist_or_404(dsr_id: uuid.UUID, db: AsyncSession) -> AIComplianceChecklist:
    result = await db.execute(
        select(AIComplianceChecklist)
        .where(AIComplianceChecklist.dsr_id == dsr_id)
    )
    checklist = result.scalar_one_or_none()
    if not checklist:
        raise HTTPException(status_code=404, detail="No AI checklist for this DSR")
    return checklist


@router.get("/{dsr_id}/checklist", response_model=AIChecklistOut)
async def get_checklist(
    dsr_id: uuid.UUID, db: DB,
    current_user: CurrentUser,
) -> AIComplianceChecklist:
    dsr = await _get_dsr_or_404(dsr_id, db)
    await _require_dsr_access(dsr, db, current_user)
    return await _get_checklist_or_404(dsr_id, db)


def _ai_sign_off_complete(checklist: AIComplianceChecklist) -> bool:
    """Both AI-assessment sign-off signatures (prepared by DM, acknowledged by SME) are present."""
    so = ((checklist.checklist_json or {}).get("ai_assessment") or {}).get("sign_off") or {}
    return bool(so.get("prepared_signature")) and bool(so.get("acknowledged_signature"))


@router.put("/{dsr_id}/checklist", response_model=AIChecklistOut)
async def update_checklist(
    dsr_id: uuid.UUID, body: AIChecklistUpdate, db: DB,
    current_user: CurrentUser,
) -> AIComplianceChecklist:
    dsr = await _get_dsr_or_404(dsr_id, db)
    await _require_dsr_access(dsr, db, current_user, "dsr:update")
    if dsr.status == "approved":
        raise HTTPException(status_code=400, detail="Approved DSR checklist is immutable")

    checklist = dsr.ai_checklist or await _get_checklist_or_404(dsr_id, db)
    if body.checklist_json is not None:
        incoming = copy.deepcopy(body.checklist_json)
        previous = checklist.checklist_json or {}
        incoming_so = incoming.setdefault("sign_off", {})
        previous_so = previous.get("sign_off", {})
        sme_id = dsr.project.sme_id if dsr.project else None
        sme_user = await db.get(User, sme_id) if sme_id else None
        if sme_user:
            # The acknowledged signer is always the project SME from the
            # platform assignment, never a free-form approver identity.
            incoming_so["acknowledged_by"] = sme_user.full_name
            if sme_user.position:
                incoming_so["acknowledged_position"] = sme_user.position
        has_ack_signature = bool(
            previous_so.get("acknowledged_signature") or incoming_so.get("acknowledged_signature")
        )
        if has_ack_signature and current_user.id != sme_id:
            raise HTTPException(
                status_code=403,
                detail="Only the assigned Project SME can add or change the acknowledged signature.",
            )
        if incoming_so.get("acknowledged_signature"):
            incoming_so["acknowledged_signed_by"] = str(current_user.id)
        else:
            incoming_so.pop("acknowledged_signed_by", None)

        has_prepared_signature = bool(
            previous_so.get("prepared_signature") or incoming_so.get("prepared_signature")
        )
        if has_prepared_signature and current_user.id not in {dsr.requester_id, sme_id}:
            raise HTTPException(
                status_code=403,
                detail="Only the DSR requester or assigned Project SME can manage the prepared signature.",
            )
        if incoming_so.get("prepared_signature"):
            if (
                previous_so.get("prepared_signature") == incoming_so.get("prepared_signature")
                and previous_so.get("prepared_signed_by")
            ):
                incoming_so["prepared_signed_by"] = previous_so["prepared_signed_by"]
            else:
                incoming_so["prepared_signed_by"] = str(current_user.id)
        else:
            incoming_so.pop("prepared_signed_by", None)
        checklist.checklist_json = incoming

    # The AICK assessment has its own signed marker for the AI checklist page.
    # Final DSR sign-off is exposed separately through is_final_signed.
    if _ai_sign_off_complete(checklist):
        if not checklist.validated_at:
            checklist.validated_by = current_user.id
            checklist.validated_at = datetime.now(timezone.utc)
    elif checklist.status != "approved":
        checklist.validated_by = None
        checklist.validated_at = None
    db.add(AuditLog(user_id=current_user.id, module="dsr", action="update_checklist",
                    entity_type="ai_checklist", entity_id=str(dsr_id)))
    await db.commit()
    return await _get_checklist_or_404(dsr_id, db)


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

    # AICK completion is driven by the assessment and the sign-off section;
    # there is no separate approver workflow anymore.
    checklist.status = "approved"

    db.add(AuditLog(
        user_id=current_user.id, module="dsr", action="submit_ai_checklist",
        entity_type="ai_checklist", entity_id=str(checklist.id),
        details={"tracking_id": dsr.tracking_id, "approval_workflow": False},
    ))
    await db.commit()

    return await _get_dsr_or_404(dsr_id, db)
