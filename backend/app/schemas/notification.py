"""Schemas for In-App Notification Center — P6-002."""
from __future__ import annotations
from datetime import datetime
import uuid
from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: uuid.UUID
    module: str
    event: str
    title: str
    body: str | None
    entity_type: str | None
    entity_id: str | None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationPreferenceOut(BaseModel):
    module: str
    in_app: bool
    email: bool

    model_config = {"from_attributes": True}


class NotificationPreferenceUpdate(BaseModel):
    module: str
    in_app: bool = True
    email: bool = True


class NotificationListResponse(BaseModel):
    items: list[NotificationOut]
    unread_count: int
