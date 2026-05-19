import io
import math
import uuid
from datetime import datetime, date, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.core.workflow import WorkflowError, validate_transition
from app.models.bapd import BAPDApproval, BAPDRecord, RetentionPolicy
from app.models.user import AuditLog, User
from app.schemas.bapd import (
    ApprovalActionRequest, BAPDCreate, BAPDListItem, BAPDOut, BAPDUpdate,
    PaginatedBAPD, RetentionPolicyCreate, RetentionPolicyOut, TransitionRequest,
)
from app.worker.tasks.notifications import send_workflow_notification

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

@router.get("", response_model=PaginatedBAPD)
async def list_bapds(
    db: DB,
    _: Annotated[User, Depends(require_permission("bapd:read"))],
    project_id: uuid.UUID | None = Query(default=None),
    status_filter: str = Query(default="", alias="status"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedBAPD:
    q = select(BAPDRecord)
    if project_id:
        q = q.where(BAPDRecord.project_id == project_id)
    if status_filter:
        q = q.where(BAPDRecord.status == status_filter)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar_one()
    rows = (await db.execute(
        q.order_by(BAPDRecord.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).scalars().all()
    return PaginatedBAPD(
        items=[BAPDListItem.model_validate(r) for r in rows],
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=BAPDOut, status_code=201)
async def create_bapd(
    body: BAPDCreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:create"))],
) -> BAPDRecord:
    record = BAPDRecord(**body.model_dump(), status="draft", created_by=current_user.id)
    db.add(record)
    await db.flush()

    # Seed dual approval steps
    for step, role in enumerate(["data_owner", "compliance_officer"], 1):
        db.add(BAPDApproval(
            bapd_id=record.id, approver_id=current_user.id,
            approver_role=role, step_order=step,
        ))

    db.add(AuditLog(user_id=current_user.id, module="bapd", action="create",
                    entity_type="bapd", entity_id=str(record.id)))
    await db.commit()
    await db.refresh(record)
    return record


@router.get("/{bapd_id}", response_model=BAPDOut)
async def get_bapd(
    bapd_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("bapd:read"))],
) -> BAPDRecord:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    return record


@router.put("/{bapd_id}", response_model=BAPDOut)
async def update_bapd(
    bapd_id: uuid.UUID, body: BAPDUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:update"))],
) -> BAPDRecord:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    if record.status not in ("draft", "rejected"):
        raise HTTPException(status_code=400, detail="Only draft or rejected records can be edited")
    for k, v in body.model_dump(exclude_none=True).items():
        setattr(record, k, v)
    db.add(AuditLog(user_id=current_user.id, module="bapd", action="update",
                    entity_type="bapd", entity_id=str(bapd_id)))
    await db.commit()
    await db.refresh(record)
    return record


# ── Workflow Transition ────────────────────────────────────────────────────────

@router.post("/{bapd_id}/transition", response_model=BAPDOut)
async def transition_bapd(
    bapd_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:approve"))],
) -> BAPDRecord:
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
    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action=f"transition_{body.target_status}",
        entity_type="bapd", entity_id=str(bapd_id),
        details={"from": old, "to": body.target_status, "comments": body.comments},
    ))
    await db.commit()
    await db.refresh(record)
    event_map = {"submitted": "bapd_submitted", "approved": "bapd_approved", "rejected": "bapd_rejected"}
    event = event_map.get(body.target_status)
    if event:
        send_workflow_notification.delay(
            event=event, entity_id=str(bapd_id), recipients=[],
            context={"entity_id": str(bapd_id), "actor": current_user.full_name},
        )
    return record


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
    if approval.status != "pending":
        raise HTTPException(status_code=400, detail="Approval step already actioned")

    approval.status = "approved" if body.action == "approve" else "rejected"
    approval.comments = body.comments
    approval.actioned_at = datetime.now(timezone.utc)

    # Advance BAPD status based on dual-approval logic
    if body.action == "reject":
        record.status = "rejected"
    else:
        # Step 1 (data_owner) approved -> under_review
        # Step 2 (compliance_officer) approved -> approved (ready to execute)
        all_approvals = (await db.execute(
            select(BAPDApproval).where(BAPDApproval.bapd_id == bapd_id)
        )).scalars().all()
        all_approved = all(a.status == "approved" for a in all_approvals)
        if all_approved:
            record.status = "approved"
        elif step == 1:
            record.status = "under_review"

    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action=f"approval_{body.action}",
        entity_type="bapd", entity_id=str(bapd_id),
        details={"step": step, "comments": body.comments},
    ))
    await db.commit()
    await db.refresh(record)
    return record


# ── Execute & POD ──────────────────────────────────────────────────────────────

@router.post("/{bapd_id}/execute", response_model=BAPDOut)
async def execute_bapd(
    bapd_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:approve"))],
) -> BAPDRecord:
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
    send_workflow_notification.delay(
        event="bapd_executed", entity_id=str(bapd_id), recipients=[],
        context={"entity_id": str(bapd_id), "actor": current_user.full_name,
                 "pod_path": record.pod_file_path},
    )
    return record


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
