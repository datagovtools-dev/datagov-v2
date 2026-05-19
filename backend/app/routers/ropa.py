import math
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.core.workflow import WorkflowError, validate_transition
from app.models.ropa import ROPARecord
from app.models.user import AuditLog, User
from app.schemas.ropa import (
    PaginatedROPA, ROPACreate, ROPAListItem, ROPAOut,
    ROPAUpdate, TransitionRequest, LEGAL_BASIS_OPTIONS,
)
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
    q = select(ROPARecord)
    if project_id:
        q = q.where(ROPARecord.project_id == project_id)
    if status_filter:
        q = q.where(ROPARecord.status == status_filter)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar_one()
    rows = (await db.execute(
        q.order_by(ROPARecord.created_at.desc())
        .offset((page - 1) * page_size).limit(page_size)
    )).scalars().all()
    return PaginatedROPA(
        items=[ROPAListItem.model_validate(r) for r in rows],
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=ROPAOut, status_code=201)
async def create_ropa(
    body: ROPACreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("ropa:create"))],
) -> ROPARecord:
    record = ROPARecord(**body.model_dump(), status="draft", created_by=current_user.id)
    db.add(record)
    await db.flush()
    db.add(AuditLog(user_id=current_user.id, module="ropa", action="create",
                    entity_type="ropa", entity_id=str(record.id)))
    await db.commit()
    await db.refresh(record)
    return record


@router.get("/{ropa_id}", response_model=ROPAOut)
async def get_ropa(
    ropa_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("ropa:read"))],
) -> ROPARecord:
    result = await db.execute(select(ROPARecord).where(ROPARecord.id == ropa_id))
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="ROPA record not found")
    return record


@router.put("/{ropa_id}", response_model=ROPAOut)
async def update_ropa(
    ropa_id: uuid.UUID, body: ROPAUpdate, db: DB,
    current_user: Annotated[User, Depends(require_permission("ropa:update"))],
) -> ROPARecord:
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
    return record


@router.post("/{ropa_id}/transition", response_model=ROPAOut)
async def transition_ropa(
    ropa_id: uuid.UUID, body: TransitionRequest, db: DB,
    current_user: Annotated[User, Depends(require_permission("ropa:update"))],
) -> ROPARecord:
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
        details={"from": old, "to": body.target_status},
    ))
    await db.commit()
    await db.refresh(record)
    if body.target_status == "submitted":
        send_workflow_notification.delay(
            event="ropa_submitted", entity_id=str(ropa_id), recipients=[],
            context={"entity_id": str(ropa_id), "actor": current_user.full_name},
        )
    return record
