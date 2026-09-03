import math
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.core.workflow import WorkflowError, validate_transition
from app.models.project import Project
from app.models.ropa import ROPARecord
from app.models.user import AuditLog, User, UserProjectRole, Role
from app.schemas.ropa import (
    PaginatedROPA, ROPACreate, ROPAListItem, ROPAOut,
    ROPAUpdate, TransitionRequest, LEGAL_BASIS_OPTIONS,
)
from app.services.notification_service import notify_approval_requested, notify_approval_completed
from app.worker.tasks.notifications import send_workflow_notification

router = APIRouter(prefix="/ropa", tags=["ropa"])
DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("/legal-basis-options", response_model=list[str])
async def legal_basis_options() -> list[str]:
    return LEGAL_BASIS_OPTIONS


@router.get("", response_model=PaginatedROPA)
async def list_ropas(
    db: DB,
    _: Annotated[User, Depends(require_permission("ropa:read"))],
    project_id: uuid.UUID | None = Query(default=None),
    status_filter: str = Query(default="", alias="status"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedROPA:
    q = (
        select(
            ROPARecord,
            Project.project_code,
            Project.project_name,
            Project.customer_name,
        )
        .join(Project, ROPARecord.project_id == Project.id)
    )
    if project_id:
        q = q.where(ROPARecord.project_id == project_id)
    if status_filter:
        q = q.where(ROPARecord.status == status_filter)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar_one()
    rows = (await db.execute(
        q.order_by(ROPARecord.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).all()

    items = [
        ROPAListItem(
            id=r.ROPARecord.id,
            project_id=r.ROPARecord.project_id,
            project_code=r.project_code,
            project_name=r.project_name,
            customer_name=r.customer_name,
            process_name=r.ROPARecord.process_name,
            data_category=r.ROPARecord.data_category,
            legal_basis=r.ROPARecord.legal_basis,
            status=r.ROPARecord.status,
            version=r.ROPARecord.version,
            created_at=r.ROPARecord.created_at,
        )
        for r in rows
    ]

    return PaginatedROPA(
        items=items,
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=ROPAOut, status_code=201)
async def create_ropa(
    body: ROPACreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("ropa:create"))],
) -> ROPAOut:
    record = ROPARecord(**body.model_dump(), status="draft", created_by=current_user.id)
    db.add(record)
    await db.flush()

    proj = (await db.execute(select(Project).where(Project.id == record.project_id))).scalar_one_or_none()

    db.add(AuditLog(user_id=current_user.id, module="ropa", action="create",
                    entity_type="ropa", entity_id=str(record.id)))
    await db.commit()
    await db.refresh(record)

    return ROPAOut(
        id=record.id,
        project_id=record.project_id,
        project_code=proj.project_code if proj else None,
        project_name=proj.project_name if proj else None,
        customer_name=proj.customer_name if proj else None,
        process_name=record.process_name,
        purpose=record.purpose,
        data_category=record.data_category,
        data_subject=record.data_subject,
        legal_basis=record.legal_basis,
        retention_period=record.retention_period,
        recipient=record.recipient,
        linked_asset_ids=record.linked_asset_ids,
        status=record.status,
        version=record.version,
        created_by=record.created_by,
        created_by_name=current_user.full_name,
        created_at=record.created_at,
        updated_at=record.updated_at,
    )


@router.get("/{ropa_id}", response_model=ROPAOut)
async def get_ropa(
    ropa_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("ropa:read"))],
) -> ROPAOut:
    result = await db.execute(
        select(
            ROPARecord,
            Project.project_code,
            Project.project_name,
            Project.customer_name,
            User.full_name.label("created_by_name"),
        )
        .join(Project, ROPARecord.project_id == Project.id)
        .outerjoin(User, ROPARecord.created_by == User.id)
        .where(ROPARecord.id == ropa_id)
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="ROPA record not found")

    return ROPAOut(
        id=row.ROPARecord.id,
        project_id=row.ROPARecord.project_id,
        project_code=row.project_code,
        project_name=row.project_name,
        customer_name=row.customer_name,
        process_name=row.ROPARecord.process_name,
        purpose=row.ROPARecord.purpose,
        data_category=row.ROPARecord.data_category,
        data_subject=row.ROPARecord.data_subject,
        legal_basis=row.ROPARecord.legal_basis,
        retention_period=row.ROPARecord.retention_period,
        recipient=row.ROPARecord.recipient,
        linked_asset_ids=row.ROPARecord.linked_asset_ids,
        status=row.ROPARecord.status,
        version=row.ROPARecord.version,
        created_by=row.ROPARecord.created_by,
        created_by_name=row.created_by_name,
        created_at=row.ROPARecord.created_at,
        updated_at=row.ROPARecord.updated_at,
    )


@router.put("/{ropa_id}", response_model=ROPAOut)
async def update_ropa(
    ropa_id: uuid.UUID, body: ROPAUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("ropa:update"))],
) -> ROPAOut:
    result = await db.execute(select(ROPARecord).where(ROPARecord.id == ropa_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="ROPA record not found")
    if record.status == "approved":
        raise HTTPException(status_code=400, detail="Approved ROPA records cannot be edited")
    for k, v in body.model_dump(exclude_none=True).items():
        setattr(record, k, v)
    db.add(AuditLog(user_id=current_user.id, module="ropa", action="update",
                    entity_type="ropa", entity_id=str(ropa_id)))
    await db.commit()
    await db.refresh(record)

    return await get_ropa(ropa_id, db, current_user)


@router.post("/{ropa_id}/transition", response_model=ROPAOut)
async def transition_ropa(
    ropa_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("ropa:update"))],
) -> ROPAOut:
    result = await db.execute(select(ROPARecord).where(ROPARecord.id == ropa_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="ROPA record not found")
    try:
        validate_transition("ropa", record.status, body.target_status)
    except WorkflowError as e:
        raise HTTPException(status_code=400, detail=str(e))
    old = record.status
    record.status = body.target_status
    if body.target_status == "approved":
        record.version += 1
    db.add(AuditLog(
        user_id=current_user.id, module="ropa", action=f"transition_{body.target_status}",
        entity_type="ropa", entity_id=str(ropa_id),
        details={"from": old, "to": body.target_status, "comments": body.comments},
    ))
    await db.commit()
    await db.refresh(record)

    # In-App and background notifications
    if body.target_status == "submitted":
        proj = (await db.execute(select(Project).where(Project.id == record.project_id))).scalar_one_or_none()
        target_user_ids = []
        if proj:
            if proj.dgo_id:
                target_user_ids.append(proj.dgo_id)
            if proj.pic_data_compliance_id:
                target_user_ids.append(proj.pic_data_compliance_id)
        if not target_user_ids:
            officers = (await db.execute(
                select(User).join(UserProjectRole, User.id == UserProjectRole.user_id)
                .join(Role, UserProjectRole.role_id == Role.id)
                .where(Role.name.in_(["data_governance_officer", "compliance_officer", "dpo"]))
            )).scalars().all()
            target_user_ids = [u.id for u in officers]

        for u_id in set(target_user_ids):
            target_user = (await db.execute(select(User).where(User.id == u_id))).scalar_one_or_none()
            if target_user:
                await notify_approval_requested(
                    db=db,
                    approver=target_user,
                    module="ropa",
                    tracking_id=record.process_name,
                    entity_id=str(record.id),
                    step=1,
                    step_label="Compliance Review & Sign-Off",
                    actor_name=current_user.full_name,
                )
        await db.commit()

    elif body.target_status in ("approved", "rejected"):
        creator = (await db.execute(select(User).where(User.id == record.created_by))).scalar_one_or_none()
        if creator:
            await notify_approval_completed(
                db=db,
                requester_id=creator.id,
                requester_email=creator.email,
                module="ropa",
                tracking_id=record.process_name,
                entity_id=str(record.id),
                status=body.target_status,
                actor_name=current_user.full_name,
                comments=body.comments,
            )
            await db.commit()

    return await get_ropa(ropa_id, db, current_user)
