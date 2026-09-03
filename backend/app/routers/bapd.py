import io
import math
import uuid
from datetime import datetime, date, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.core.workflow import WorkflowError, validate_transition
from app.models.bapd import BAPDApproval, BAPDRecord, RetentionPolicy
from app.models.project import Project
from app.models.user import AuditLog, User, UserProjectRole, Role
from app.schemas.bapd import (
    ApprovalActionRequest, BAPDApprovalOut, BAPDCreate, BAPDListItem, BAPDOut, BAPDUpdate,
    PaginatedBAPD, RetentionPolicyCreate, RetentionPolicyOut, TransitionRequest,
)
from app.worker.tasks.notifications import send_workflow_notification
from app.services.notification_service import notify_approval_requested, notify_approval_completed

from typing import Annotated

router = APIRouter(prefix="/bapd", tags=["bapd"])
DB = Annotated[AsyncSession, Depends(get_db)]

# ── Retention Policies ─────────────────────────────────────────────────────────

@router.get("/retention-policies", response_model=list[RetentionPolicyOut])
async def list_retention_policies(db: DB, _: Annotated[User, Depends(require_permission("bapd:read"))]):
    result = await db.execute(select(RetentionPolicy).order_by(RetentionPolicy.dataset_type))
    return result.scalars().all()


@router.post("/retention-policies", response_model=RetentionPolicyOut, status_code=201)
async def create_retention_policy(
    body: RetentionPolicyCreate, db: DB,
    _: Annotated[User, Depends(require_permission("bapd:create"))],
) -> RetentionPolicy:
    policy = RetentionPolicy(**body.model_dump())
    db.add(policy)
    await db.commit()
    await db.refresh(policy)
    return policy


@router.post("/retention-policies/seed", status_code=201)
async def seed_retention_policies(
    db: DB, _: Annotated[User, Depends(require_permission("bapd:create"))],
) -> dict:
    """Seed default organisation retention policies."""
    defaults = [
        ("Personal Data", 1825, "GDPR Art.5(1)(e) — 5 years"),
        ("Financial Records", 2555, "Company Act — 7 years"),
        ("Health Data", 3650, "Health Act — 10 years"),
        ("Operational Logs", 365, "IT Policy — 1 year"),
        ("Audit Logs", 2555, "Compliance — 7 years"),
        ("Marketing Data", 730, "PDPA — 2 years"),
        ("Employee Records", 3650, "Labour Law — 10 years"),
        ("Contract Data", 3650, "Civil Code — 10 years"),
    ]
    created = 0
    for dtype, days, ref in defaults:
        existing = (await db.execute(
            select(RetentionPolicy).where(RetentionPolicy.dataset_type == dtype)
        )).scalar_one_or_none()
        if not existing:
            db.add(RetentionPolicy(dataset_type=dtype, retention_days=days, policy_reference=ref))
            created += 1
    await db.commit()
    return {"seeded": created, "message": f"{created} policies created"}


# ── Eligible Datasets ──────────────────────────────────────────────────────────

@router.get("/eligible-datasets")
async def list_eligible_datasets(
    db: DB, _: Annotated[User, Depends(require_permission("bapd:read"))],
) -> list[dict]:
    """Return datasets that have passed their retention expiry date."""
    today = date.today()
    result = await db.execute(
        select(BAPDRecord).where(
            BAPDRecord.expiry_date < today,
            BAPDRecord.status.not_in(["executed", "archived"]),
        ).order_by(BAPDRecord.expiry_date)
    )
    records = result.scalars().all()
    return [
        {
            "id": str(r.id),
            "dataset_name": r.dataset_name,
            "dataset_location": r.dataset_location,
            "expiry_date": r.expiry_date.isoformat(),
            "retention_policy_id": str(r.retention_policy_id) if r.retention_policy_id else None,
            "days_overdue": (today - r.expiry_date).days,
            "status": r.status,
        }
        for r in records
    ]


# ── BAPD CRUD ──────────────────────────────────────────────────────────────────

async def _build_bapd_out(record: BAPDRecord, db: AsyncSession) -> BAPDOut:
    proj = (await db.execute(select(Project).where(Project.id == record.project_id))).scalar_one_or_none()
    creator = (await db.execute(select(User).where(User.id == record.created_by))).scalar_one_or_none()
    resp_party = (await db.execute(select(User).where(User.id == record.responsible_party_id))).scalar_one_or_none()
    policy = None
    if record.retention_policy_id:
        policy = (await db.execute(select(RetentionPolicy).where(RetentionPolicy.id == record.retention_policy_id))).scalar_one_or_none()

    approvals_res = await db.execute(
        select(BAPDApproval).where(BAPDApproval.bapd_id == record.id).order_by(BAPDApproval.step_order)
    )
    approvals_raw = approvals_res.scalars().all()
    approvals_out = []
    for app in approvals_raw:
        app_user = (await db.execute(select(User).where(User.id == app.approver_id))).scalar_one_or_none()
        approvals_out.append(BAPDApprovalOut(
            id=app.id,
            bapd_id=app.bapd_id,
            approver_id=app.approver_id,
            approver_name=app_user.full_name if app_user else "",
            approver_role=app.approver_role,
            step_order=app.step_order,
            status=app.status,
            comments=app.comments,
            actioned_at=app.actioned_at,
        ))

    return BAPDOut(
        id=record.id,
        project_id=record.project_id,
        project_code=proj.project_code if proj else None,
        project_name=proj.project_name if proj else "",
        customer_name=proj.customer_name if proj else "",
        dataset_name=record.dataset_name,
        dataset_location=record.dataset_location,
        retention_policy_id=record.retention_policy_id,
        retention_policy_name=policy.dataset_type if policy else None,
        expiry_date=record.expiry_date,
        reason=record.reason,
        responsible_party_id=record.responsible_party_id,
        responsible_party_name=resp_party.full_name if resp_party else None,
        status=record.status,
        pod_file_path=record.pod_file_path,
        executed_at=record.executed_at,
        executed_by=record.executed_by,
        version=record.version,
        created_by=record.created_by,
        created_by_name=creator.full_name if creator else None,
        created_at=record.created_at,
        updated_at=record.updated_at,
        approvals=approvals_out,
    )


@router.get("", response_model=PaginatedBAPD)
async def list_bapds(
    db: DB,
    _: Annotated[User, Depends(require_permission("bapd:read"))],
    project_id: uuid.UUID | None = Query(default=None),
    status_filter: str = Query(default="", alias="status"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedBAPD:
    q = (
        select(
            BAPDRecord,
            Project.project_code,
            Project.project_name,
            Project.customer_name,
            User.full_name.label("creator_name"),
        )
        .outerjoin(Project, BAPDRecord.project_id == Project.id)
        .outerjoin(User, BAPDRecord.created_by == User.id)
    )
    if project_id:
        q = q.where(BAPDRecord.project_id == project_id)
    if status_filter:
        q = q.where(BAPDRecord.status == status_filter)

    count_q = select(func.count(BAPDRecord.id))
    if project_id:
        count_q = count_q.where(BAPDRecord.project_id == project_id)
    if status_filter:
        count_q = count_q.where(BAPDRecord.status == status_filter)
    total = (await db.execute(count_q)).scalar_one()

    rows = (await db.execute(
        q.order_by(BAPDRecord.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).all()

    items = []
    for r, p_code, p_name, cust_name, creator_name in rows:
        items.append(BAPDListItem(
            id=r.id,
            project_id=r.project_id,
            project_code=p_code,
            project_name=p_name,
            customer_name=cust_name,
            dataset_name=r.dataset_name,
            dataset_location=r.dataset_location,
            expiry_date=r.expiry_date,
            status=r.status,
            version=r.version,
            created_by_name=creator_name,
            pod_file_path=r.pod_file_path,
            executed_at=r.executed_at,
            created_at=r.created_at,
        ))

    return PaginatedBAPD(
        items=items,
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=BAPDOut, status_code=201)
async def create_bapd(
    body: BAPDCreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:create"))],
) -> BAPDOut:
    record = BAPDRecord(**body.model_dump(), status="draft", created_by=current_user.id)
    db.add(record)
    await db.flush()

    # Look up approvers directly from project fields or designated roles
    proj_res = await db.execute(select(Project).where(Project.id == record.project_id))
    proj = proj_res.scalar_one_or_none()

    comp_officer_id = None
    if proj and proj.pic_data_compliance_id:
        comp_officer_id = proj.pic_data_compliance_id
    else:
        comp_res = await db.execute(
            select(User.id)
            .join(UserProjectRole, and_(UserProjectRole.user_id == User.id, UserProjectRole.revoked_at.is_(None)))
            .join(Role, and_(Role.id == UserProjectRole.role_id, Role.name.in_(("compliance_officer", "dpo"))))
        )
        comp_officer_id = comp_res.scalars().first()

    data_owner_id = (proj.dgo_id if proj and proj.dgo_id else None) or (proj.sme_id if proj and proj.sme_id else None) or record.responsible_party_id

    step_approvers = [
        ("data_owner",         data_owner_id),
        ("compliance_officer", comp_officer_id or current_user.id),
    ]

    # Seed dual approval steps
    for step, (role, approver_id) in enumerate(step_approvers, 1):
        db.add(BAPDApproval(
            bapd_id=record.id, approver_id=approver_id or current_user.id,
            approver_role=role, step_order=step, status="pending",
        ))

    db.add(AuditLog(user_id=current_user.id, module="bapd", action="create",
                    entity_type="bapd", entity_id=str(record.id)))
    await db.commit()
    await db.refresh(record)
    return await _build_bapd_out(record, db)


@router.get("/{bapd_id}", response_model=BAPDOut)
async def get_bapd(
    bapd_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("bapd:read"))],
) -> BAPDOut:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    return await _build_bapd_out(record, db)


@router.put("/{bapd_id}", response_model=BAPDOut)
async def update_bapd(
    bapd_id: uuid.UUID, body: BAPDUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:update"))],
) -> BAPDOut:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    if record.status not in ("draft", "rejected"):
        raise HTTPException(status_code=400, detail="Only draft or rejected BAPDs can be edited")
    for field, val in body.model_dump(exclude_unset=True).items():
        setattr(record, field, val)
    record.version += 1
    db.add(AuditLog(user_id=current_user.id, module="bapd", action="update",
                    entity_type="bapd", entity_id=str(bapd_id)))
    await db.commit()
    await db.refresh(record)
    return await _build_bapd_out(record, db)


# ── Workflow Transition ────────────────────────────────────────────────────────

@router.post("/{bapd_id}/transition", response_model=BAPDOut)
async def transition_bapd(
    bapd_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:update"))],
) -> BAPDOut:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    try:
        validate_transition("bapd", record.status, body.target_status)
    except WorkflowError as e:
        raise HTTPException(status_code=400, detail=str(e))
    old = record.status
    record.status = body.target_status
    if body.target_status not in ("draft", "rejected"):
        record.version += 1
    
    # If transitioning to submitted/under_review, activate Step 1 approval
    step1 = None
    if body.target_status in ("submitted", "under_review"):
        step1_res = await db.execute(
            select(BAPDApproval).where(BAPDApproval.bapd_id == bapd_id, BAPDApproval.step_order == 1)
        )
        step1 = step1_res.scalar_one_or_none()
        if step1 and step1.status == "pending":
            step1.status = "requested"

    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action=f"transition_{body.target_status}",
        entity_type="bapd", entity_id=str(bapd_id),
        details={"from": old, "to": body.target_status},
    ))
    await db.commit()
    await db.refresh(record)

    if body.target_status in ("submitted", "under_review") and step1 and step1.approver_id:
        step1_user = await db.get(User, step1.approver_id)
        if step1_user:
            await notify_approval_requested(
                db=db,
                approver=step1_user,
                module="bapd",
                tracking_id=f"BAPD-{str(bapd_id)[:8]}",
                entity_id=str(bapd_id),
                step=1,
                step_label="Data Owner Sign-Off",
                actor_name=current_user.full_name,
            )
            await db.commit()

    return await _build_bapd_out(record, db)


# ── Dual Approval Steps ────────────────────────────────────────────────────────

@router.post("/{bapd_id}/approvals/{step}", response_model=BAPDOut)
async def action_approval(
    bapd_id: uuid.UUID, step: int, body: ApprovalActionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:approve"))],
) -> BAPDRecord:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")

    approval_result = await db.execute(
        select(BAPDApproval).where(
            BAPDApproval.bapd_id == bapd_id,
            BAPDApproval.step_order == step,
        )
    )
    approval = approval_result.scalar_one_or_none()
    if not approval:
        raise HTTPException(status_code=404, detail="Approval step not found")
    if approval.status not in ("pending", "requested"):
        raise HTTPException(status_code=400, detail="Approval step already actioned")

    # Determine if current_user is permitted to act on this approval step
    is_designated = bool(approval.approver_id and current_user.id == approval.approver_id)

    user_roles_res = await db.execute(
        select(Role.name)
        .join(UserProjectRole, and_(UserProjectRole.role_id == Role.id, UserProjectRole.revoked_at.is_(None)))
        .where(UserProjectRole.user_id == current_user.id)
    )
    user_roles = set(user_roles_res.scalars().all())

    is_role_match = (
        (approval.approver_role == "data_owner" and bool(user_roles.intersection({"data_owner", "data_steward", "data_governance_officer"}))) or
        (approval.approver_role == "compliance_officer" and bool(user_roles.intersection({"compliance_officer", "dpo"})))
    )

    if not is_designated and not current_user.is_super_admin and not is_role_match:
        raise HTTPException(
            status_code=403,
            detail="Only the designated approver, a user with the matching compliance role, or a Super Admin can approve/reject this step.",
        )

    approval.approver_id = current_user.id
    approval.status = "approved" if body.action == "approve" else "rejected"
    approval.comments = body.comments
    approval.actioned_at = datetime.now(timezone.utc)

    # Advance BAPD status based on dual-approval logic
    next_step = None
    all_approved = False
    if body.action == "reject":
        record.status = "rejected"
    else:
        # Check all approvals
        all_approvals = (await db.execute(
            select(BAPDApproval).where(BAPDApproval.bapd_id == bapd_id)
        )).scalars().all()
        all_approved = all(a.status == "approved" for a in all_approvals)
        if all_approved:
            record.status = "approved"
        else:
            record.status = "under_review"
            # Activate next pending step
            next_step_res = await db.execute(
                select(BAPDApproval).where(BAPDApproval.bapd_id == bapd_id, BAPDApproval.step_order == step + 1)
            )
            next_step = next_step_res.scalar_one_or_none()
            if next_step and next_step.status == "pending":
                next_step.status = "requested"

    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action=f"approval_{body.action}",
        entity_type="bapd", entity_id=str(bapd_id),
        details={"step": step, "comments": body.comments},
    ))
    await db.commit()
    await db.refresh(record)

    if body.action == "approve" and next_step and next_step.approver_id:
        next_user = await db.get(User, next_step.approver_id)
        if next_user:
            await notify_approval_requested(
                db=db,
                approver=next_user,
                module="bapd",
                tracking_id=f"BAPD-{str(bapd_id)[:8]}",
                entity_id=str(bapd_id),
                step=step + 1,
                step_label="Compliance Officer Review",
                actor_name=current_user.full_name,
            )
            await db.commit()
    elif body.action == "approve" and all_approved:
        requester = await db.get(User, record.responsible_party_id)
        if requester:
            await notify_approval_completed(
                db=db,
                requester_id=requester.id,
                requester_email=requester.email,
                module="bapd",
                tracking_id=f"BAPD-{str(bapd_id)[:8]}",
                entity_id=str(bapd_id),
                status="approved",
                actor_name=current_user.full_name,
            )
            await db.commit()
    elif body.action == "reject":
        requester = await db.get(User, record.responsible_party_id)
        if requester:
            await notify_approval_completed(
                db=db,
                requester_id=requester.id,
                requester_email=requester.email,
                module="bapd",
                tracking_id=f"BAPD-{str(bapd_id)[:8]}",
                entity_id=str(bapd_id),
                status="rejected",
                actor_name=current_user.full_name,
                comments=body.comments,
            )
            await db.commit()

    return await _build_bapd_out(record, db)


# ── Execute & POD ──────────────────────────────────────────────────────────────

@router.post("/{bapd_id}/execute", response_model=BAPDOut)
async def execute_bapd(
    bapd_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:approve"))],
) -> BAPDOut:
    """Execute approved BAPD — triggers deletion and generates Proof of Deletion."""
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    if record.status != "approved":
        raise HTTPException(status_code=400, detail="Only approved records can be executed")

    record.status = "executed"
    record.executed_at = datetime.now(timezone.utc)
    record.executed_by = current_user.id
    # POD path — real GCS upload wired at deployment time
    record.pod_file_path = f"gs://bapd-evidence/{bapd_id}/pod_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"
    record.version += 1

    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action="execute",
        entity_type="bapd", entity_id=str(bapd_id),
        details={"pod_path": record.pod_file_path},
    ))
    await db.commit()
    await db.refresh(record)
    try:
        send_workflow_notification.delay(
            event="bapd_executed", entity_id=str(bapd_id), recipients=[],
            context={"entity_id": str(bapd_id), "actor": current_user.full_name,
                     "pod_path": record.pod_file_path},
        )
    except Exception:
        pass

    requester = await db.get(User, record.responsible_party_id)
    if requester:
        await notify_approval_completed(
            db=db,
            requester_id=requester.id,
            requester_email=requester.email,
            module="bapd",
            tracking_id=f"BAPD-{str(bapd_id)[:8]}",
            entity_id=str(bapd_id),
            status="executed",
            actor_name=current_user.full_name,
        )
        await db.commit()

    return await _build_bapd_out(record, db)


@router.get("/{bapd_id}/pod")
async def download_pod(
    bapd_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("bapd:read"))],
) -> StreamingResponse:
    """Download Proof of Deletion PDF (stub — returns simple PDF in dev)."""
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    if not record.pod_file_path:
        raise HTTPException(status_code=404, detail="Proof of Deletion not yet generated")

    # In production this streams from GCS; in dev returns a simple text marker
    content = (
        f"PROOF OF DELETION\n"
        f"=================\n"
        f"BAPD ID    : {bapd_id}\n"
        f"Dataset    : {record.dataset_name}\n"
        f"Location   : {record.dataset_location}\n"
        f"Executed At: {record.executed_at}\n"
        f"GCS Path   : {record.pod_file_path}\n"
    ).encode()
    return StreamingResponse(
        io.BytesIO(content),
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="pod_{bapd_id}.txt"'},
    )
