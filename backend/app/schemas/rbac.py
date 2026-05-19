import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class RoleOut(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class RoleCreate(BaseModel):
    name: str
    description: Optional[str] = None


class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None


class UserProjectRoleOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    role_id: int
    role_name: str
    project_id: Optional[uuid.UUID] = None
    assigned_at: datetime
    revoked_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class AssignRoleRequest(BaseModel):
    user_id: uuid.UUID
    role_id: int
    project_id: Optional[uuid.UUID] = None


class RevokeRoleRequest(BaseModel):
    user_project_role_id: uuid.UUID


class PermissionsResponse(BaseModel):
    user_id: uuid.UUID
    permissions: list[str]


class UserSummary(BaseModel):
    id: uuid.UUID
    full_name: str
    email: str
    position: Optional[str] = None
    is_active: bool
    roles: list[UserProjectRoleOut] = []

    model_config = {"from_attributes": True}
