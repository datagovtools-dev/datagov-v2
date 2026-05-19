import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, get_db
from app.core.rbac import require_permission
from app.models.user import AuditLog, Role, User, UserProjectRole
from app.schemas.rbac import (
    AssignRoleRequest, PermissionsResponse, RevokeRoleRequest,
    RoleCreate, RoleOut, RoleUpdate, UserProjectRoleOut, UserSummary,
)
from app.core.rbac import _ROLE_PERMISSIONS

router = APIRouter(prefix="/rbac", tags=["rbac"])

DB = Annotated[AsyncSession, Depends(get_db)]


# ── Roles ─────────────────────────────────────────────────────────────────────

@router.get("/roles", response_model=list[RoleOut])
async def list_roles(
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
) -> list[Role]:
    result = await db.execute(select(Role).order_by(Role.id))
    return result.scalars().all()


@router.post("/roles", response_model=RoleOut, status_code=status.HTTP_201_CREATED)
async def create_role(
    body: RoleCreate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> Role:
    existing = await db.execute(select(Role).where(Role.name == body.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Role name already exists")
    role = Role(name=body.name, description=body.description)
    db.add(role)
    db.add(AuditLog(user_id=current_user.id, module="rbac", action="create_role",
                    entity_type="role", entity_id=body.name))
    await db.commit()
    await db.refresh(role)
    return role


@router.put("/roles/{role_id}", response_model=RoleOut)
async def update_role(
    role_id: int,
    body: RoleUpdate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> Role:
    result = await db.execute(select(Role).where(Role.id == role_id))
    role = result.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    if body.name is not None:
        role.name = body.name
    if body.description is not None:
        role.description = body.description
    db.add(AuditLog(user_id=current_user.id, module="rbac", action="update_role",
                    entity_type="role", entity_id=str(role_id)))
    await db.commit()
    await db.refresh(role)
    return role


@router.delete("/roles/{role_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_role(
    role_id: int,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> None:
    result = await db.execute(select(Role).where(Role.id == role_id))
    role = result.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    # Check if any active assignments use this role
    assignments = await db.execute(
        select(UserProjectRole).where(
            and_(UserProjectRole.role_id == role_id, UserProjectRole.revoked_at.is_(None))
        )
    )
    if assignments.scalars().first():
        raise HTTPException(status_code=409, detail="Cannot delete role with active assignments")
    await db.delete(role)
    db.add(AuditLog(user_id=current_user.id, module="rbac", action="delete_role",
                    entity_type="role", entity_id=str(role_id)))
    await db.commit()


# ── User ↔ Role assignments ───────────────────────────────────────────────────

@router.get("/users/options", response_model=list[UserSummary])
async def list_user_options(
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
    search: str = Query(default="", max_length=100),
) -> list[User]:
    """Lightweight endpoint for dropdowns — returns only id/full_name/email, no role joins."""
    q = select(User.id, User.full_name, User.email, User.position, User.is_active).where(User.is_active == True).order_by(User.full_name)
    if search:
        q = q.where(User.full_name.ilike(f"%{search}%") | User.email.ilike(f"%{search}%"))
    result = await db.execute(q)
    rows = result.all()
    return [UserSummary(id=r.id, full_name=r.full_name, email=r.email, position=r.position, is_active=r.is_active, roles=[]) for r in rows]


@router.get("/users", response_model=list[UserSummary])
async def list_users(
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
    search: str = Query(default="", max_length=100),
) -> list[User]:
    q = select(User).order_by(User.full_name)
    if search:
        q = q.where(
            User.full_name.ilike(f"%{search}%") | User.email.ilike(f"%{search}%")
        )
    result = await db.execute(q)
    users = result.scalars().all()
    # Attach active role assignments for each user
    for user in users:
        asgn = await db.execute(
            select(UserProjectRole).where(
                and_(UserProjectRole.user_id == user.id, UserProjectRole.revoked_at.is_(None))
            )
        )
        roles_raw = asgn.scalars().all()
        role_outs = []
        for r in roles_raw:
            role_res = await db.execute(select(Role).where(Role.id == r.role_id))
            role_obj = role_res.scalar_one_or_none()
            role_outs.append(UserProjectRoleOut(
                id=r.id, user_id=r.user_id, role_id=r.role_id,
                role_name=role_obj.name if role_obj else str(r.role_id),
                project_id=r.project_id, assigned_at=r.assigned_at, revoked_at=r.revoked_at,
            ))
        user.__dict__["project_roles_out"] = role_outs
    return users


@router.get("/users/{user_id}/roles", response_model=list[UserProjectRoleOut])
async def get_user_roles(
    user_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
) -> list[UserProjectRoleOut]:
    result = await db.execute(
        select(UserProjectRole).where(
            and_(UserProjectRole.user_id == user_id, UserProjectRole.revoked_at.is_(None))
        )
    )
    assignments = result.scalars().all()
    out = []
    for a in assignments:
        role_res = await db.execute(select(Role).where(Role.id == a.role_id))
        role_obj = role_res.scalar_one_or_none()
        out.append(UserProjectRoleOut(
            id=a.id, user_id=a.user_id, role_id=a.role_id,
            role_name=role_obj.name if role_obj else str(a.role_id),
            project_id=a.project_id, assigned_at=a.assigned_at, revoked_at=a.revoked_at,
        ))
    return out


@router.post("/users/{user_id}/roles", response_model=UserProjectRoleOut, status_code=status.HTTP_201_CREATED)
async def assign_role(
    user_id: uuid.UUID,
    body: AssignRoleRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> UserProjectRoleOut:
    # Verify user exists
    u = await db.execute(select(User).where(User.id == user_id))
    if not u.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="User not found")

    # Check no duplicate active assignment
    dup = await db.execute(
        select(UserProjectRole).where(
            and_(
                UserProjectRole.user_id == user_id,
                UserProjectRole.role_id == body.role_id,
                UserProjectRole.project_id == body.project_id,
                UserProjectRole.revoked_at.is_(None),
            )
        )
    )
    if dup.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Role already assigned")

    assignment = UserProjectRole(
        user_id=user_id,
        role_id=body.role_id,
        project_id=body.project_id,
        assigned_by=current_user.id,
    )
    db.add(assignment)
    db.add(AuditLog(
        user_id=current_user.id, module="rbac", action="assign_role",
        entity_type="user_project_role", entity_id=str(user_id),
        details={"role_id": body.role_id, "project_id": str(body.project_id)},
    ))
    await db.flush()
    role_res = await db.execute(select(Role).where(Role.id == body.role_id))
    role_obj = role_res.scalar_one_or_none()
    await db.commit()
    return UserProjectRoleOut(
        id=assignment.id, user_id=assignment.user_id, role_id=assignment.role_id,
        role_name=role_obj.name if role_obj else str(body.role_id),
        project_id=assignment.project_id, assigned_at=assignment.assigned_at,
        revoked_at=None,
    )


@router.delete("/users/{user_id}/roles/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_role(
    user_id: uuid.UUID,
    assignment_id: uuid.UUID,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> None:
    result = await db.execute(
        select(UserProjectRole).where(
            and_(UserProjectRole.id == assignment_id, UserProjectRole.user_id == user_id)
        )
    )
    assignment = result.scalar_one_or_none()
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    assignment.revoked_at = datetime.now(timezone.utc)
    db.add(AuditLog(
        user_id=current_user.id, module="rbac", action="revoke_role",
        entity_type="user_project_role", entity_id=str(assignment_id),
    ))
    await db.commit()


@router.get("/users/{user_id}/permissions", response_model=PermissionsResponse)
async def get_user_permissions(
    user_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
) -> PermissionsResponse:
    result = await db.execute(
        select(UserProjectRole).where(
            and_(UserProjectRole.user_id == user_id, UserProjectRole.revoked_at.is_(None))
        )
    )
    assignments = result.scalars().all()
    permissions: set[str] = set()
    for a in assignments:
        role_res = await db.execute(select(Role).where(Role.id == a.role_id))
        role_obj = role_res.scalar_one_or_none()
        if role_obj:
            perms = _ROLE_PERMISSIONS.get(role_obj.name, set())
            if "*" in perms:
                permissions = {"*"}
                break
            permissions.update(perms)
    return PermissionsResponse(user_id=user_id, permissions=sorted(permissions))
