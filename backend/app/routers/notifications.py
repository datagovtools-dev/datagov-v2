"""In-App Notification Center API — P6-002."""
from __future__ import annotations
from typing import Annotated
import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, get_db
from app.models.notification import Notification, NotificationPreference
from app.models.user import User
from app.schemas.notification import (
    NotificationListResponse, NotificationOut,
    NotificationPreferenceOut, NotificationPreferenceUpdate,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])
DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("", response_model=NotificationListResponse)
async def list_notifications(
    db: DB,
    current_user: CurrentUser,
    is_read: bool | None = Query(default=None),
    module: str = Query(default=""),
    limit: int = Query(default=50, ge=1, le=200),
) -> NotificationListResponse:
    q = select(Notification).where(Notification.user_id == current_user.id)
    if is_read is not None:
        q = q.where(Notification.is_read == is_read)
    if module:
        q = q.where(Notification.module == module)
    q = q.order_by(Notification.created_at.desc()).limit(limit)

    items = (await db.execute(q)).scalars().all()

    unread = (await db.execute(
        select(func.count()).where(
            Notification.user_id == current_user.id,
            Notification.is_read == False,  # noqa: E712
        )
    )).scalar_one()

    return NotificationListResponse(
        items=[NotificationOut.model_validate(n) for n in items],
        unread_count=unread,
    )


@router.put("/{notification_id}/read", response_model=NotificationOut)
async def mark_read(
    notification_id: uuid.UUID,
    db: DB,
    current_user: CurrentUser,
) -> NotificationOut:
    notif = (await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
    )).scalar_one_or_none()
    if notif:
        notif.is_read = True
        await db.commit()
        await db.refresh(notif)
    return NotificationOut.model_validate(notif)


@router.put("/read-all", response_model=dict)
async def mark_all_read(db: DB, current_user: CurrentUser) -> dict:
    await db.execute(
        update(Notification)
        .where(Notification.user_id == current_user.id, Notification.is_read == False)  # noqa: E712
        .values(is_read=True)
    )
    await db.commit()
    return {"message": "All notifications marked as read"}


@router.get("/preferences", response_model=list[NotificationPreferenceOut])
async def get_preferences(db: DB, current_user: CurrentUser) -> list[NotificationPreferenceOut]:
    prefs = (await db.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == current_user.id)
    )).scalars().all()
    return [NotificationPreferenceOut.model_validate(p) for p in prefs]


@router.put("/preferences", response_model=list[NotificationPreferenceOut])
async def update_preferences(
    body: list[NotificationPreferenceUpdate],
    db: DB,
    current_user: CurrentUser,
) -> list[NotificationPreferenceOut]:
    for pref_in in body:
        existing = (await db.execute(
            select(NotificationPreference).where(
                NotificationPreference.user_id == current_user.id,
                NotificationPreference.module == pref_in.module,
            )
        )).scalar_one_or_none()

        if existing:
            existing.in_app = pref_in.in_app
            existing.email = pref_in.email
        else:
            db.add(NotificationPreference(
                user_id=current_user.id,
                module=pref_in.module,
                in_app=pref_in.in_app,
                email=pref_in.email,
            ))

    await db.commit()
    prefs = (await db.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == current_user.id)
    )).scalars().all()
    return [NotificationPreferenceOut.model_validate(p) for p in prefs]
