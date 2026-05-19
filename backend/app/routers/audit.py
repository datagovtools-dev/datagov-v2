"""Audit Log read-only API — P6-001."""
from __future__ import annotations
from datetime import datetime
from typing import Annotated
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.models.user import AuditLog, User
from app.schemas.audit import AuditLogOut, AuditLogPage

router = APIRouter(prefix="/audit-logs", tags=["audit"])
DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("", response_model=AuditLogPage)
async def list_audit_logs(
    db: DB,
    _: Annotated[User, Depends(require_permission("audit:read"))],
    module: str = Query(default=""),
    action: str = Query(default=""),
    user_id: str = Query(default=""),
    entity_id: str = Query(default=""),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=50, ge=1, le=1000),
) -> AuditLogPage:
    q = select(AuditLog, User.full_name.label("actor_name")).join(
        User, AuditLog.user_id == User.id, isouter=True
    )

    if module:
        q = q.where(AuditLog.module == module)
    if action:
        q = q.where(AuditLog.action.ilike(f"%{action}%"))
    if user_id:
        try:
            q = q.where(AuditLog.user_id == uuid.UUID(user_id))
        except ValueError:
            pass
    if entity_id:
        q = q.where(AuditLog.entity_id.ilike(f"%{entity_id}%"))
    if date_from:
        q = q.where(AuditLog.created_at >= date_from)
    if date_to:
        q = q.where(AuditLog.created_at <= date_to)

    total_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(total_q)).scalar_one()

    q = q.order_by(AuditLog.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    rows = (await db.execute(q)).all()

    items = [
        AuditLogOut(
            id=row.AuditLog.id,
            user_id=row.AuditLog.user_id,
            actor_name=row.actor_name,
            module=row.AuditLog.module,
            action=row.AuditLog.action,
            entity_type=row.AuditLog.entity_type,
            entity_id=row.AuditLog.entity_id,
            details=row.AuditLog.details,
            ip_address=row.AuditLog.ip_address,
            created_at=row.AuditLog.created_at,
        )
        for row in rows
    ]

    return AuditLogPage(items=items, total=total, page=page, page_size=page_size)


@router.get("/modules", response_model=list[str])
async def list_modules(
    db: DB,
    _: Annotated[User, Depends(require_permission("audit:read"))],
) -> list[str]:
    result = await db.execute(
        select(AuditLog.module).distinct().order_by(AuditLog.module)
    )
    return [r[0] for r in result.fetchall()]
