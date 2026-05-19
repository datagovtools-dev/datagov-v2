"""Schemas for Audit Log module (P6-001)."""
from __future__ import annotations
from datetime import datetime
from typing import Any
import uuid
from pydantic import BaseModel


class AuditLogOut(BaseModel):
    id: int
    user_id: uuid.UUID | None
    actor_name: str | None
    module: str
    action: str
    entity_type: str | None
    entity_id: str | None
    details: Any
    ip_address: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class AuditLogPage(BaseModel):
    items: list[AuditLogOut]
    total: int
    page: int
    page_size: int
