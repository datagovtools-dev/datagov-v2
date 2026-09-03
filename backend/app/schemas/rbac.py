import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr


class MenuAccessItem(BaseModel):
    id: str
    label: str
    href: str
    group: str
    icon: str
    description: str
    is_accessible: bool = False


class ActivityItem(BaseModel):
    id: str
    name: str
    group: str
    category: str
    description: str
    required_permission: Optional[str] = None
    is_permitted: bool = False


class RoleOut(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    created_at: datetime
    accessible_menu_count: int = 0
    permitted_activity_count: int = 0
    user_count: int = 0
    menus: list[MenuAccessItem] = []
    activities: list[ActivityItem] = []

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
    accessible_menus: list[MenuAccessItem] = []
    permitted_activities: list[ActivityItem] = []


class UserSummary(BaseModel):
    id: uuid.UUID
    full_name: str
    email: str
    position: Optional[str] = None
    is_active: bool
    roles: list[UserProjectRoleOut] = []
    accessible_menu_count: int = 0
    permitted_activity_count: int = 0
    accessible_menus: list[MenuAccessItem] = []
    permitted_activities: list[ActivityItem] = []

    model_config = {"from_attributes": True}


class RoleMatrixEntry(BaseModel):
    role_id: int
    role_name: str
    role_description: Optional[str] = None
    user_count: int = 0
    accessible_menus: list[str] = []
    permitted_activities: list[str] = []


class AccessMatrixOut(BaseModel):
    menus: list[dict]
    activities: list[dict]
    roles: list[RoleMatrixEntry]


class UpdateRolePermissionsRequest(BaseModel):
    permissions: Optional[list[str]] = None
    accessible_menus: Optional[list[str]] = None
    permitted_activities: Optional[list[str]] = None


class BulkUpdateMatrixRoleItem(BaseModel):
    role_id: int
    accessible_menus: list[str] = []
    permitted_activities: list[str] = []


class BulkUpdateMatrixRequest(BaseModel):
    roles: list[BulkUpdateMatrixRoleItem]


class RolePermissionsOut(BaseModel):
    role_id: int
    role_name: str
    permissions: list[str]
    accessible_menus: list[str]
    permitted_activities: list[str]

