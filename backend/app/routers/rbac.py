import uuid
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, get_db
from app.core.rbac import (
    require_permission,
    _ROLE_PERMISSIONS,
    MENU_DEFINITIONS,
    ACTIVITY_DEFINITIONS,
    get_menu_access_for_role,
    get_activities_for_role,
    get_user_capabilities_from_roles,
    resolve_permissions_from_capabilities,
)
from app.models.user import AuditLog, Role, User, UserProjectRole
from app.schemas.rbac import (
    AccessMatrixOut, AssignRoleRequest, BulkUpdateMatrixRequest, MenuAccessItem, ActivityItem,
    PermissionsResponse, RevokeRoleRequest, RoleCreate, RoleMatrixEntry,
    RoleOut, RolePermissionsOut, RoleUpdate, UpdateRolePermissionsRequest, UserProjectRoleOut, UserSummary,
)

router = APIRouter(prefix="/rbac", tags=["rbac"])

DB = Annotated[AsyncSession, Depends(get_db)]


# ── Roles ─────────────────────────────────────────────────────────────────────

@router.get("/roles", response_model=list[RoleOut])
async def list_roles(
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
) -> list[RoleOut]:
    result = await db.execute(select(Role).order_by(Role.id))
    roles = result.scalars().all()
    
    out: list[RoleOut] = []
    for r in roles:
        # Count active users with this role
        user_cnt = (await db.execute(
            select(func.count(UserProjectRole.id)).where(
                and_(UserProjectRole.role_id == r.id, UserProjectRole.revoked_at.is_(None))
            )
        )).scalar_one() or 0
        
        menus_data = get_menu_access_for_role(r.name, r.permissions)
        activities_data = get_activities_for_role(r.name, r.permissions)
        
        out.append(RoleOut(
            id=r.id,
            name=r.name,
            description=r.description,
            created_at=r.created_at,
            user_count=user_cnt,
            accessible_menu_count=len([m for m in menus_data if m["is_accessible"]]),
            permitted_activity_count=len([a for a in activities_data if a["is_permitted"]]),
            menus=[MenuAccessItem(**m) for m in menus_data],
            activities=[ActivityItem(**a) for a in activities_data],
        ))
    return out


@router.get("/access-matrix", response_model=AccessMatrixOut)
async def get_access_matrix(
    db: DB,
    _: Annotated[User, Depends(require_permission("user:read"))],
) -> AccessMatrixOut:
    """Return the global RBAC Access Control & Activity Matrix."""
    result = await db.execute(select(Role).order_by(Role.id))
    roles = result.scalars().all()
    
    role_entries: list[RoleMatrixEntry] = []
    for r in roles:
        user_cnt = (await db.execute(
            select(func.count(UserProjectRole.id)).where(
                and_(UserProjectRole.role_id == r.id, UserProjectRole.revoked_at.is_(None))
            )
        )).scalar_one() or 0
        
        menus_data = get_menu_access_for_role(r.name, r.permissions)
        activities_data = get_activities_for_role(r.name, r.permissions)
        
        role_entries.append(RoleMatrixEntry(
            role_id=r.id,
            role_name=r.name,
            role_description=r.description,
            user_count=user_cnt,
            accessible_menus=[m["id"] for m in menus_data if m["is_accessible"]],
            permitted_activities=[a["id"] for a in activities_data if a["is_permitted"]],
        ))
        
    return AccessMatrixOut(
        menus=MENU_DEFINITIONS,
        activities=ACTIVITY_DEFINITIONS,
        roles=role_entries,
    )


@router.put("/access-matrix", response_model=AccessMatrixOut)
async def update_access_matrix(
    body: BulkUpdateMatrixRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> AccessMatrixOut:
    """Batch update access matrix for multiple roles simultaneously."""
    for item in body.roles:
        res = await db.execute(select(Role).where(Role.id == item.role_id))
        role = res.scalar_one_or_none()
        if not role:
            continue
        if role.name == "super_admin":
            # Protect super_admin from losing wildcard access
            role.permissions = ["*"]
            continue
        
        computed_perms = resolve_permissions_from_capabilities(
            accessible_menu_ids=item.accessible_menus,
            permitted_activity_ids=item.permitted_activities,
        )
        role.permissions = computed_perms
        db.add(AuditLog(
            user_id=current_user.id, module="rbac", action="update_matrix_permissions",
            entity_type="role", entity_id=str(role.id),
            details={"accessible_menus": item.accessible_menus, "permitted_activities": item.permitted_activities},
        ))
        
    await db.commit()
    
    # Return updated matrix
    return await get_access_matrix(db=db, _=current_user)


@router.put("/roles/{role_id}/permissions", response_model=RoleOut)
async def update_role_permissions(
    role_id: int,
    body: UpdateRolePermissionsRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> RoleOut:
    """Update permissions, accessible menus, and activities for a single role."""
    result = await db.execute(select(Role).where(Role.id == role_id))
    role = result.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    if role.name == "super_admin":
        role.permissions = ["*"]
        await db.commit()
        await db.refresh(role)
    else:
        if body.permissions is not None:
            role.permissions = body.permissions
        else:
            role.permissions = resolve_permissions_from_capabilities(
                accessible_menu_ids=body.accessible_menus,
                permitted_activity_ids=body.permitted_activities,
            )
            
        db.add(AuditLog(
            user_id=current_user.id, module="rbac", action="update_role_permissions",
            entity_type="role", entity_id=str(role_id),
            details={"permissions": role.permissions},
        ))
        await db.commit()
        await db.refresh(role)

    user_cnt = (await db.execute(
        select(func.count(UserProjectRole.id)).where(
            and_(UserProjectRole.role_id == role.id, UserProjectRole.revoked_at.is_(None))
        )
    )).scalar_one() or 0
    
    menus_data = get_menu_access_for_role(role.name, role.permissions)
    activities_data = get_activities_for_role(role.name, role.permissions)
    
    return RoleOut(
        id=role.id,
        name=role.name,
        description=role.description,
        created_at=role.created_at,
        user_count=user_cnt,
        accessible_menu_count=len([m for m in menus_data if m["is_accessible"]]),
        permitted_activity_count=len([a for a in activities_data if a["is_permitted"]]),
        menus=[MenuAccessItem(**m) for m in menus_data],
        activities=[ActivityItem(**a) for a in activities_data],
    )


@router.post("/roles/{role_id}/reset-defaults", response_model=RoleOut)
async def reset_role_permissions_to_defaults(
    role_id: int,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> RoleOut:
    """Reset a role's permissions back to system governance factory defaults."""
    result = await db.execute(select(Role).where(Role.id == role_id))
    role = result.scalar_one_or_none()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found")
    
    role.permissions = None
    db.add(AuditLog(
        user_id=current_user.id, module="rbac", action="reset_role_permissions",
        entity_type="role", entity_id=str(role_id),
    ))
    await db.commit()
    await db.refresh(role)

    user_cnt = (await db.execute(
        select(func.count(UserProjectRole.id)).where(
            and_(UserProjectRole.role_id == role.id, UserProjectRole.revoked_at.is_(None))
        )
    )).scalar_one() or 0
    
    menus_data = get_menu_access_for_role(role.name, role.permissions)
    activities_data = get_activities_for_role(role.name, role.permissions)
    
    return RoleOut(
        id=role.id,
        name=role.name,
        description=role.description,
        created_at=role.created_at,
        user_count=user_cnt,
        accessible_menu_count=len([m for m in menus_data if m["is_accessible"]]),
        permitted_activity_count=len([a for a in activities_data if a["is_permitted"]]),
        menus=[MenuAccessItem(**m) for m in menus_data],
        activities=[ActivityItem(**a) for a in activities_data],
    )


@router.post("/roles", response_model=RoleOut, status_code=status.HTTP_201_CREATED)
async def create_role(
    body: RoleCreate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> RoleOut:
    existing = await db.execute(select(Role).where(Role.name == body.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Role name already exists")
    role = Role(name=body.name, description=body.description)
    db.add(role)
    db.add(AuditLog(user_id=current_user.id, module="rbac", action="create_role",
                    entity_type="role", entity_id=body.name))
    await db.commit()
    await db.refresh(role)

    menus_data = get_menu_access_for_role(role.name, role.permissions)
    activities_data = get_activities_for_role(role.name, role.permissions)
    return RoleOut(
        id=role.id,
        name=role.name,
        description=role.description,
        created_at=role.created_at,
        user_count=0,
        accessible_menu_count=len([m for m in menus_data if m["is_accessible"]]),
        permitted_activity_count=len([a for a in activities_data if a["is_permitted"]]),
        menus=[MenuAccessItem(**m) for m in menus_data],
        activities=[ActivityItem(**a) for a in activities_data],
    )


@router.put("/roles/{role_id}", response_model=RoleOut)
async def update_role(
    role_id: int,
    body: RoleUpdate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("user:read"))],
) -> RoleOut:
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

    user_cnt = (await db.execute(
        select(func.count(UserProjectRole.id)).where(
            and_(UserProjectRole.role_id == role.id, UserProjectRole.revoked_at.is_(None))
        )
    )).scalar_one() or 0
    
    menus_data = get_menu_access_for_role(role.name, role.permissions)
    activities_data = get_activities_for_role(role.name, role.permissions)
    return RoleOut(
        id=role.id,
        name=role.name,
        description=role.description,
        created_at=role.created_at,
        user_count=user_cnt,
        accessible_menu_count=len([m for m in menus_data if m["is_accessible"]]),
        permitted_activity_count=len([a for a in activities_data if a["is_permitted"]]),
        menus=[MenuAccessItem(**m) for m in menus_data],
        activities=[ActivityItem(**a) for a in activities_data],
    )


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
    current_user: CurrentUser,
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
) -> list[UserSummary]:
    q = select(User).order_by(User.full_name)
    if search:
        q = q.where(
            User.full_name.ilike(f"%{search}%") | User.email.ilike(f"%{search}%")
        )
    result = await db.execute(q)
    users = result.scalars().all()
    
    out: list[UserSummary] = []
    for user in users:
        asgn = await db.execute(
            select(UserProjectRole).where(
                and_(UserProjectRole.user_id == user.id, UserProjectRole.revoked_at.is_(None))
            )
        )
        roles_raw = asgn.scalars().all()
        role_info_list = []
        role_outs: list[UserProjectRoleOut] = []
        for r in roles_raw:
            role_res = await db.execute(select(Role).where(Role.id == r.role_id))
            role_obj = role_res.scalar_one_or_none()
            r_name = role_obj.name if role_obj else str(r.role_id)
            c_perms = role_obj.permissions if role_obj else None
            role_info_list.append((r_name, c_perms))
            role_outs.append(UserProjectRoleOut(
                id=r.id, user_id=r.user_id, role_id=r.role_id,
                role_name=r_name,
                project_id=r.project_id, assigned_at=r.assigned_at, revoked_at=r.revoked_at,
            ))
            
        caps = get_user_capabilities_from_roles(role_info_list)
        out.append(UserSummary(
            id=user.id,
            full_name=user.full_name,
            email=user.email,
            position=user.position,
            is_active=user.is_active,
            roles=role_outs,
            accessible_menu_count=caps["accessible_menu_count"],
            permitted_activity_count=caps["permitted_activity_count"],
            accessible_menus=[MenuAccessItem(**m) for m in caps["menus"]],
            permitted_activities=[ActivityItem(**a) for a in caps["activities"]],
        ))
    return out


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
    role_info_list = []
    for a in assignments:
        role_res = await db.execute(select(Role).where(Role.id == a.role_id))
        role_obj = role_res.scalar_one_or_none()
        if role_obj:
            r_name = role_obj.name
            c_perms = role_obj.permissions
            role_info_list.append((r_name, c_perms))
            if r_name == "super_admin":
                permissions = {"*"}
            elif c_perms is not None:
                if "*" in c_perms:
                    permissions = {"*"}
                else:
                    permissions.update(c_perms)
            else:
                perms = _ROLE_PERMISSIONS.get(r_name, set())
                if "*" in perms:
                    permissions = {"*"}
                else:
                    permissions.update(perms)
                
    caps = get_user_capabilities_from_roles(role_info_list)
    return PermissionsResponse(
        user_id=user_id,
        permissions=sorted(permissions),
        accessible_menus=[MenuAccessItem(**m) for m in caps["menus"]],
        permitted_activities=[ActivityItem(**a) for a in caps["activities"]],
    )
