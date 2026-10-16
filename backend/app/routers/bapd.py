import copy
import io
import math
import uuid
from datetime import datetime, date, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, select, and_, exists, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, get_db
from app.core.rbac import _user_has_permission, require_permission
from app.core.workflow import WorkflowError, validate_transition
from app.models.bapd import BAPDApproval, BAPDRecord, BAPDTargetDataset, RetentionPolicy
from app.models.metadata import DataOwnerSteward
from app.models.project import Project
from app.models.user import AuditLog, User, UserProjectRole, Role
from app.schemas.bapd import (
    ApprovalActionRequest, BAPDApprovalOut, BAPDCreate, BAPDExecuteRequest, BAPDListItem, BAPDOut, BAPDSignOffUpdate, BAPDTargetDatasetOut, BAPDUpdate,
    PaginatedBAPD, RetentionPolicyCreate, RetentionPolicyOut, TransitionRequest,
)
from app.worker.tasks.notifications import send_workflow_notification
from app.services.notification_service import notify_approval_requested, notify_approval_completed

from typing import Annotated

router = APIRouter(prefix="/bapd", tags=["bapd"])
DB = Annotated[AsyncSession, Depends(get_db)]

_SIGN_OFF_REQUIRED_FIELDS = (
    "approved", "prepared_by", "prepared_position", "prepared_signature", "prepared_date",
    "acknowledged_by", "acknowledged_position", "acknowledged_signature", "acknowledged_date",
)


def _final_sign_off_complete(sign_off: dict | None) -> bool:
    so = sign_off or {}
    return (
        so.get("approved") == "Yes"
        and all(str(so.get(field) or "").strip() for field in _SIGN_OFF_REQUIRED_FIELDS)
        and bool(so.get("prepared_signed_by"))
        and bool(so.get("acknowledged_signed_by"))
    )


_LEGACY_APPROVAL_ROLES = {1: "data_owner", 2: "compliance_officer"}


def _legacy_approvals_complete(approvals: list[BAPDApproval]) -> bool:
    """Require the complete two-step legacy chain before approval or execution."""
    if len(approvals) != len(_LEGACY_APPROVAL_ROLES):
        return False
    if sorted(approval.step_order for approval in approvals) != sorted(_LEGACY_APPROVAL_ROLES):
        return False
    return all(
        approval.approver_role == _LEGACY_APPROVAL_ROLES[approval.step_order]
        and approval.status == "approved"
        for approval in approvals
    )


def _is_legacy_dual_approval(record: BAPDRecord) -> bool:
    """Existing rows with approval steps remain readable/actionable as legacy data."""
    return record.approval_method == "legacy_dual_approval" or bool(record.approvals)


def _approval_method(record: BAPDRecord, approvals: list[BAPDApproval] | None = None) -> str:
    if approvals:
        return "legacy_dual_approval"
    return record.approval_method or "form_sign_off"


def _has_bapd_permission(user: User, permission: str) -> bool:
    return _user_has_permission(user, permission)


def _bapd_actor_scope(user: User):
    """Scope project-approval actors without granting them global RBAC access."""
    return or_(
        Project.sme_id == user.id,
        BAPDRecord.responsible_party_id == user.id,
        exists().where(
            and_(
                DataOwnerSteward.project_id == BAPDRecord.project_id,
                DataOwnerSteward.role_type == "data_owner",
                func.lower(DataOwnerSteward.email) == user.email.casefold(),
            )
        ),
        exists().where(
            and_(
                BAPDApproval.bapd_id == BAPDRecord.id,
                BAPDApproval.approver_id == user.id,
            )
        ),
    )


async def _require_bapd_access(
    record: BAPDRecord,
    db: AsyncSession,
    current_user: User,
    permission: str = "bapd:read",
) -> Project | None:
    project = (await db.execute(select(Project).where(Project.id == record.project_id))).scalar_one_or_none()
    if _has_bapd_permission(current_user, permission):
        return project
    if project and project.sme_id == current_user.id:
        return project
    data_owner = (await db.execute(
        select(DataOwnerSteward).where(
            DataOwnerSteward.project_id == record.project_id,
            DataOwnerSteward.role_type == "data_owner",
            func.lower(DataOwnerSteward.email) == current_user.email.casefold(),
        )
    )).scalars().first()
    if data_owner:
        return project
    approval_actor = (await db.execute(
        select(BAPDApproval.id).where(
            BAPDApproval.bapd_id == record.id,
            BAPDApproval.approver_id == current_user.id,
        )
    )).scalar_one_or_none()
    if approval_actor:
        return project
    raise HTTPException(status_code=403, detail="You are not assigned to this BAPD approval")


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
    db: DB, current_user: CurrentUser,
) -> list[dict]:
    """Return datasets that have passed their retention expiry date."""
    today = date.today()
    query = select(BAPDRecord).where(
        BAPDRecord.expiry_date < today,
        BAPDRecord.status.not_in(["executed", "archived"]),
    )
    if not _has_bapd_permission(current_user, "bapd:read"):
        query = query.join(Project, BAPDRecord.project_id == Project.id).where(_bapd_actor_scope(current_user))
    result = await db.execute(query.order_by(BAPDRecord.expiry_date))
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
    data_owner = (await db.execute(
        select(DataOwnerSteward).where(
            DataOwnerSteward.project_id == record.project_id,
            DataOwnerSteward.role_type == "data_owner",
        ).order_by(DataOwnerSteward.created_at.asc())
    )).scalars().first()
    data_owner_registered = False
    if data_owner and data_owner.email:
        data_owner_registered = bool(await db.scalar(
            select(exists().where(
                User.is_active.is_(True),
                func.lower(User.email) == data_owner.email.casefold(),
            ))
        ))
    creator = (await db.execute(select(User).where(User.id == record.created_by))).scalar_one_or_none()
    resp_party = (await db.execute(select(User).where(User.id == record.responsible_party_id))).scalar_one_or_none()
    policy = None
    if record.retention_policy_id:
        policy = (await db.execute(select(RetentionPolicy).where(RetentionPolicy.id == record.retention_policy_id))).scalar_one_or_none()

    targets_res = await db.execute(
        select(BAPDTargetDataset).where(BAPDTargetDataset.bapd_id == record.id).order_by(BAPDTargetDataset.display_order)
    )
    target_rows = targets_res.scalars().all()
    datasets_out = [BAPDTargetDatasetOut.model_validate(row) for row in target_rows]
    if not datasets_out:
        datasets_out = [BAPDTargetDatasetOut(
            id=record.id,
            dataset_name=record.dataset_name,
            dataset_location=record.dataset_location,
            source_type=None,
            display_order=0,
        )]

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
        project_sme_id=proj.sme_id if proj else None,
        data_owner_registered=data_owner_registered,
        project_code=proj.project_code if proj else None,
        project_name=proj.project_name if proj else "",
        customer_name=proj.customer_name if proj else "",
        dataset_name=record.dataset_name,
        dataset_location=record.dataset_location,
        datasets=datasets_out,
        retention_policy_id=record.retention_policy_id,
        retention_policy_name=policy.dataset_type if policy else None,
        expiry_date=record.expiry_date,
        reason=record.reason,
        responsible_party_id=record.responsible_party_id,
        responsible_party_name=resp_party.full_name if resp_party else None,
        status=record.status,
        approval_method=_approval_method(record, approvals_raw),
        sign_off=record.sign_off_json or {},
        is_final_signed=_final_sign_off_complete(record.sign_off_json),
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
    current_user: CurrentUser,
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

    scope = None if _has_bapd_permission(current_user, "bapd:read") else _bapd_actor_scope(current_user)
    if scope is not None:
        q = q.where(scope)

    count_q = select(func.count(BAPDRecord.id))
    if scope is not None:
        count_q = count_q.select_from(BAPDRecord).join(Project, BAPDRecord.project_id == Project.id).where(scope)
    if project_id:
        count_q = count_q.where(BAPDRecord.project_id == project_id)
    if status_filter:
        count_q = count_q.where(BAPDRecord.status == status_filter)
    total = (await db.execute(count_q)).scalar_one()

    rows = (await db.execute(
        q.order_by(BAPDRecord.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).all()

    page_ids = [r.id for r, *_ in rows]
    legacy_ids = set()
    if page_ids:
        legacy_ids = set((await db.execute(
            select(BAPDApproval.bapd_id).where(BAPDApproval.bapd_id.in_(page_ids))
        )).scalars().all())

    dataset_counts: dict[uuid.UUID, int] = {}
    if page_ids:
        dataset_counts = {
            bapd_id: count
            for bapd_id, count in (await db.execute(
                select(BAPDTargetDataset.bapd_id, func.count(BAPDTargetDataset.id))
                .where(BAPDTargetDataset.bapd_id.in_(page_ids))
                .group_by(BAPDTargetDataset.bapd_id)
            )).all()
        }

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
            dataset_count=dataset_counts.get(r.id, 1),
            expiry_date=r.expiry_date,
            status=r.status,
            approval_method="legacy_dual_approval" if (r.approval_method == "legacy_dual_approval" or r.id in legacy_ids) else (r.approval_method or "form_sign_off"),
            is_final_signed=_final_sign_off_complete(r.sign_off_json),
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
    targets = body.datasets
    record = BAPDRecord(
        project_id=body.project_id,
        dataset_name=targets[0].dataset_name,
        dataset_location=targets[0].dataset_location,
        retention_policy_id=body.retention_policy_id,
        expiry_date=body.expiry_date,
        reason=body.reason,
        responsible_party_id=body.responsible_party_id,
        status="draft",
        approval_method="form_sign_off",
        sign_off_json={},
        created_by=current_user.id,
    )
    record.target_datasets = [
        BAPDTargetDataset(
            dataset_name=target.dataset_name,
            dataset_location=target.dataset_location,
            source_type=target.source_type,
            display_order=index,
        )
        for index, target in enumerate(targets)
    ]
    db.add(record)
    await db.flush()

    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action="create",
        entity_type="bapd", entity_id=str(record.id),
        details={"approval_workflow": False, "approval_method": "form_sign_off"},
    ))
    await db.commit()
    await db.refresh(record)
    return await _build_bapd_out(record, db)


@router.get("/{bapd_id}", response_model=BAPDOut)
async def get_bapd(
    bapd_id: uuid.UUID, db: DB,
    current_user: CurrentUser,
) -> BAPDOut:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    await _require_bapd_access(record, db, current_user, "bapd:read")
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
    changes = body.model_dump(exclude_unset=True)
    dataset_updates = changes.pop("datasets", None)
    for field, val in changes.items():
        setattr(record, field, val)
    if dataset_updates is not None:
        record.target_datasets = [
            BAPDTargetDataset(
                dataset_name=target["dataset_name"],
                dataset_location=target["dataset_location"],
                source_type=target.get("source_type"),
                display_order=index,
            )
            for index, target in enumerate(dataset_updates)
        ]
        record.dataset_name = dataset_updates[0]["dataset_name"]
        record.dataset_location = dataset_updates[0]["dataset_location"]
        changes["datasets"] = dataset_updates
    elif "dataset_name" in changes or "dataset_location" in changes:
        current_name = changes.get("dataset_name", record.dataset_name)
        current_location = changes.get("dataset_location", record.dataset_location)
        record.target_datasets = [BAPDTargetDataset(
            dataset_name=current_name,
            dataset_location=current_location,
            display_order=0,
        )]
    if changes and record.sign_off_json:
        record.sign_off_json = {}
    record.version += 1
    db.add(AuditLog(user_id=current_user.id, module="bapd", action="update",
                    entity_type="bapd", entity_id=str(bapd_id)))
    await db.commit()
    await db.refresh(record)
    return await _build_bapd_out(record, db)


@router.put("/{bapd_id}/sign-off", response_model=BAPDOut)
async def update_bapd_sign_off(
    bapd_id: uuid.UUID, body: BAPDSignOffUpdate, db: DB,
    current_user: CurrentUser,
) -> BAPDOut:
    record = (await db.execute(
        select(BAPDRecord).where(BAPDRecord.id == bapd_id).with_for_update()
    )).scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    await _require_bapd_access(record, db, current_user, "bapd:update")
    if body.version != record.version:
        raise HTTPException(status_code=409, detail="BAPD changed since this sign-off was loaded; refresh and retry")
    if record.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft BAPDs can be signed")
    if _is_legacy_dual_approval(record):
        raise HTTPException(
            status_code=400,
            detail="Legacy BAPD approvals cannot be edited through the form sign-off workflow.",
        )

    project = (await db.execute(
        select(Project).where(Project.id == record.project_id)
    )).scalar_one_or_none()
    sme_id = project.sme_id if project else None
    sme_user = await db.get(User, sme_id) if sme_id else None
    data_owner = (await db.execute(
        select(DataOwnerSteward).where(
            DataOwnerSteward.project_id == record.project_id,
            DataOwnerSteward.role_type == "data_owner",
        ).order_by(DataOwnerSteward.created_at.asc())
    )).scalars().first()
    data_owner_user = None
    if data_owner and data_owner.email:
        data_owner_user = (await db.execute(
            select(User).where(
                User.is_active.is_(True),
                func.lower(User.email) == data_owner.email.casefold(),
            )
        )).scalar_one_or_none()
    submitted = body.sign_off.model_dump(exclude_unset=True)
    previous = copy.deepcopy(record.sign_off_json or {})
    incoming = {**previous, **submitted}

    if not data_owner and any(
        field in submitted and submitted.get(field) != previous.get(field)
        for field in ("prepared_by", "prepared_position")
    ):
        raise HTTPException(
            status_code=403,
            detail="Configure a Project Data Owner before changing prepared signer metadata.",
        )
    if not sme_user and any(
        field in submitted for field in ("acknowledged_by", "acknowledged_position")
    ):
        raise HTTPException(
            status_code=409,
            detail="The assigned Project SME account is unavailable; acknowledged signer metadata cannot be changed.",
        )

    approved_changed = "approved" in submitted and submitted.get("approved") != previous.get("approved")
    if approved_changed and current_user.id != sme_id:
        raise HTTPException(
            status_code=403,
            detail="Only the assigned Project SME can change the final approval decision.",
        )

    prepared_fields = {"prepared_signature", "prepared_date"}
    prepared_changed = any(
        field in submitted and submitted.get(field) != previous.get(field)
        for field in prepared_fields
    )
    prepared_actor_allowed = bool(
        data_owner and current_user.email.casefold() == data_owner.email.casefold()
    )
    can_sme_prepare_on_behalf = bool(
        sme_id == current_user.id and data_owner and data_owner_user is None
    )
    if prepared_changed and not prepared_actor_allowed and not can_sme_prepare_on_behalf:
        raise HTTPException(
            status_code=403,
            detail="Only the configured Project Data Owner can create or change the prepared sign-off, unless the assigned SME is signing for an unregistered owner.",
        )

    acknowledged_fields = {"acknowledged_signature", "acknowledged_date"}
    acknowledged_changed = any(
        field in submitted and submitted.get(field) != previous.get(field)
        for field in acknowledged_fields
    )
    if acknowledged_changed and current_user.id != sme_id:
        raise HTTPException(
            status_code=403,
            detail="Only the assigned Project SME can create or change the acknowledged sign-off.",
        )

    # Both signer identities are server-owned. Free-form client values are
    # accepted only as display input and normalized to the configured actors.
    if data_owner:
        incoming["prepared_by"] = data_owner.full_name
        incoming["prepared_position"] = data_owner.position or "Project Data Owner"
    if sme_user:
        incoming["acknowledged_by"] = sme_user.full_name
        incoming["acknowledged_position"] = sme_user.position or "Project SME"

    if "acknowledged_signature" in submitted:
        if incoming.get("acknowledged_signature"):
            if previous.get("acknowledged_signature") == incoming.get("acknowledged_signature"):
                if not previous.get("acknowledged_signed_by"):
                    raise HTTPException(
                        status_code=409,
                        detail="Existing acknowledged signature has no signer provenance; sign again with a new signature.",
                    )
                if previous["acknowledged_signed_by"] != str(current_user.id):
                    raise HTTPException(
                        status_code=403,
                        detail="Only the original Project SME signer can replay the acknowledged signature.",
                    )
                incoming["acknowledged_signed_by"] = previous["acknowledged_signed_by"]
            else:
                incoming["acknowledged_signed_by"] = str(current_user.id)
        else:
            incoming.pop("acknowledged_signed_by", None)
    if "prepared_signature" in submitted:
        if incoming.get("prepared_signature"):
            if previous.get("prepared_signature") == incoming.get("prepared_signature"):
                if not previous.get("prepared_signed_by"):
                    raise HTTPException(
                        status_code=409,
                        detail="Existing prepared signature has no signer provenance; sign again with a new signature.",
                    )
                if not prepared_actor_allowed and not can_sme_prepare_on_behalf:
                    raise HTTPException(
                        status_code=403,
                        detail="Only the configured Project Data Owner or assigned SME delegate can replay the prepared signature.",
                    )
                incoming["prepared_signed_by"] = previous["prepared_signed_by"]
            else:
                incoming["prepared_signed_by"] = str(current_user.id)
                if can_sme_prepare_on_behalf:
                    incoming["prepared_signed_on_behalf_of"] = {
                        "name": data_owner.full_name,
                        "email": data_owner.email,
                    }
        else:
            incoming.pop("prepared_signed_by", None)
            incoming.pop("prepared_signed_on_behalf_of", None)

    record.sign_off_json = incoming
    record.version += 1
    db.add(AuditLog(
        user_id=current_user.id,
        module="bapd",
        action="sign_off_saved",
        entity_type="bapd",
        entity_id=str(bapd_id),
        details={"approval_method": "form_sign_off"},
    ))
    await db.commit()
    await db.refresh(record)
    return await _build_bapd_out(record, db)


@router.post("/{bapd_id}/submit", response_model=BAPDOut)
async def submit_bapd(
    bapd_id: uuid.UUID, db: DB,
    current_user: CurrentUser,
) -> BAPDOut:
    record = (await db.execute(
        select(BAPDRecord).where(BAPDRecord.id == bapd_id).with_for_update()
    )).scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    await _require_bapd_access(record, db, current_user, "bapd:update")
    if record.status != "draft":
        raise HTTPException(status_code=400, detail="Only draft BAPDs can be submitted")
    if _is_legacy_dual_approval(record):
        raise HTTPException(
            status_code=400,
            detail="Legacy BAPDs must use their existing approval workflow.",
        )

    project = (await db.execute(
        select(Project).where(Project.id == record.project_id)
    )).scalar_one_or_none()
    data_owner = (await db.execute(
        select(DataOwnerSteward).where(
            DataOwnerSteward.project_id == record.project_id,
            DataOwnerSteward.role_type == "data_owner",
        ).order_by(DataOwnerSteward.created_at.asc())
    )).scalars().first()
    if not data_owner:
        raise HTTPException(
            status_code=400,
            detail="Configure a Project Data Owner before submitting the BAPD sign-off.",
        )
    if not project or not project.sme_id or project.sme_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Only the assigned Project SME can submit the final BAPD sign-off.",
        )

    sign_off = record.sign_off_json or {}
    if not _final_sign_off_complete(sign_off):
        raise HTTPException(
            status_code=400,
            detail="Complete both Final Approval & Sign Off signatures before submitting the BAPD.",
        )
    if sign_off.get("acknowledged_signed_by") != str(current_user.id):
        raise HTTPException(
            status_code=403,
            detail="The final acknowledged signature must be submitted by the assigned Project SME.",
        )

    record.status = "approved"
    record.approval_method = "form_sign_off"
    db.add(AuditLog(
        user_id=current_user.id,
        module="bapd",
        action="submit",
        entity_type="bapd",
        entity_id=str(bapd_id),
        details={
            "approval_workflow": False,
            "approval_method": "form_sign_off",
        },
    ))
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
    if body.target_status == "executed":
        raise HTTPException(
            status_code=400,
            detail="Use the BAPD execute endpoint to perform deletion and generate the POD.",
        )
    if _is_legacy_dual_approval(record) and body.target_status == "approved":
        approvals = (await db.execute(
            select(BAPDApproval).where(BAPDApproval.bapd_id == bapd_id)
        )).scalars().all()
        if not _legacy_approvals_complete(approvals):
            raise HTTPException(status_code=400, detail="Complete every legacy BAPD approval step before approval")
    if not _is_legacy_dual_approval(record) and body.target_status in {
        "submitted", "under_review", "approved", "rejected",
    }:
        raise HTTPException(
            status_code=400,
            detail="BAPD approval is completed in the Final Approval & Sign Off section; no separate approval workflow is available.",
        )
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


# ── Legacy Dual Approval Steps ────────────────────────────────────────────────

@router.post("/{bapd_id}/approvals/{step}", response_model=BAPDOut)
async def action_approval(
    bapd_id: uuid.UUID, step: int, body: ApprovalActionRequest, db: DB,
    current_user: CurrentUser,
) -> BAPDOut:
    result = await db.execute(select(BAPDRecord).where(BAPDRecord.id == bapd_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    if not _is_legacy_dual_approval(record):
        raise HTTPException(
            status_code=400,
            detail="BAPD approval is completed in the Final Approval & Sign Off section; no separate approval workflow is available.",
        )

    approval_result = await db.execute(
        select(BAPDApproval).where(
            BAPDApproval.bapd_id == bapd_id,
            BAPDApproval.step_order == step,
        )
    )
    approval = approval_result.scalar_one_or_none()
    if not approval:
        raise HTTPException(status_code=404, detail="Approval step not found")
    if step not in _LEGACY_APPROVAL_ROLES:
        raise HTTPException(status_code=400, detail="Invalid legacy approval step")
    if approval.approver_role != _LEGACY_APPROVAL_ROLES[step]:
        raise HTTPException(status_code=400, detail="Legacy approval step has an invalid role")
    if record.status not in ("submitted", "under_review"):
        raise HTTPException(status_code=400, detail="Legacy approval actions are only available during review")
    if approval.status != "requested":
        raise HTTPException(status_code=400, detail="Approval step is not active")
    if step > 1:
        previous = (await db.execute(
            select(BAPDApproval).where(
                BAPDApproval.bapd_id == bapd_id,
                BAPDApproval.step_order == step - 1,
            )
        )).scalar_one_or_none()
        if previous is None or previous.status != "approved":
            raise HTTPException(status_code=400, detail="Complete the preceding BAPD approval step first")

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
    bapd_id: uuid.UUID, body: BAPDExecuteRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("bapd:approve"))],
) -> BAPDOut:
    """Execute approved BAPD — triggers deletion and generates Proof of Deletion."""
    result = await db.execute(
        select(BAPDRecord).where(BAPDRecord.id == bapd_id).with_for_update()
    )
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="BAPD record not found")
    if record.status != "approved":
        raise HTTPException(status_code=400, detail="Only approved records can be executed")
    if body.confirmation_phrase != "DELETE PERMANENTLY":
        raise HTTPException(status_code=400, detail="Type DELETE PERMANENTLY to confirm permanent deletion")
    if not _is_legacy_dual_approval(record) and not _final_sign_off_complete(record.sign_off_json):
        raise HTTPException(status_code=400, detail="BAPD cannot be executed before Final Approval & Sign Off is complete")
    if _is_legacy_dual_approval(record):
        approvals = (await db.execute(
            select(BAPDApproval).where(BAPDApproval.bapd_id == bapd_id)
        )).scalars().all()
        if not _legacy_approvals_complete(approvals):
            raise HTTPException(status_code=400, detail="Complete every legacy BAPD approval step before execution")

    record.status = "executed"
    record.executed_at = datetime.now(timezone.utc)
    record.executed_by = current_user.id
    # POD path — real GCS upload wired at deployment time
    record.pod_file_path = f"gs://bapd-evidence/{bapd_id}/pod_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"
    record.version += 1

    target_rows = record.target_datasets or [BAPDTargetDataset(
        id=record.id,
        bapd_id=record.id,
        dataset_name=record.dataset_name,
        dataset_location=record.dataset_location,
        display_order=0,
    )]
    target_details = [
        {"dataset_name": target.dataset_name, "dataset_location": target.dataset_location, "source_type": target.source_type}
        for target in target_rows
    ]

    db.add(AuditLog(
        user_id=current_user.id, module="bapd", action="execute",
        entity_type="bapd", entity_id=str(bapd_id),
        details={"pod_path": record.pod_file_path, "datasets": target_details},
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
    target_rows = record.target_datasets
    if target_rows:
        dataset_lines = "\n".join(
            f"{index}. {target.dataset_name} | {target.dataset_location}"
            for index, target in enumerate(target_rows, start=1)
        )
    else:
        dataset_lines = f"1. {record.dataset_name} | {record.dataset_location}"
    content = (
        f"PROOF OF DELETION\n"
        f"=================\n"
        f"BAPD ID    : {bapd_id}\n"
        f"Datasets   :\n{dataset_lines}\n"
        f"Executed At: {record.executed_at}\n"
        f"GCS Path   : {record.pod_file_path}\n"
    ).encode()
    return StreamingResponse(
        io.BytesIO(content),
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="pod_{bapd_id}.txt"'},
    )
