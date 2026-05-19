import math
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, get_db
from app.core.rbac import require_permission
from app.models.project import Project
from app.models.user import AuditLog, User
from app.schemas.project import (
    PaginatedProjects, ProjectCreate, ProjectFiltersResponse,
    ProjectListItem, ProjectOut, ProjectUpdate,
)

router = APIRouter(prefix="/projects", tags=["projects"])

DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("", response_model=PaginatedProjects)
async def list_projects(
    db: DB,
    _: Annotated[User, Depends(require_permission("project:read"))],
    search: str = Query(default="", max_length=100),
    year: int = Query(default=0),
    category: str = Query(default=""),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedProjects:
    q = select(Project)
    if search:
        q = q.where(
            Project.project_name.ilike(f"%{search}%")
            | Project.customer_name.ilike(f"%{search}%")
            | Project.project_code.ilike(f"%{search}%")
        )
    if year:
        q = q.where(Project.project_year == year)
    if category:
        q = q.where(Project.project_category == category)

    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(count_q)).scalar_one()

    q = q.order_by(Project.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    rows = (await db.execute(q)).scalars().all()

    return PaginatedProjects(
        items=[ProjectListItem.model_validate(r) for r in rows],
        total=total,
        page=page,
        page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.get("/filters", response_model=ProjectFiltersResponse)
async def get_filters(
    db: DB,
    _: Annotated[User, Depends(require_permission("project:read"))],
) -> ProjectFiltersResponse:
    year_rows = await db.execute(
        select(Project.project_year).distinct().order_by(Project.project_year)
    )
    years = [r.project_year for r in year_rows]
    cat_rows = await db.execute(
        select(Project.project_category).distinct().order_by(Project.project_category)
    )
    categories = [r.project_category for r in cat_rows]
    return ProjectFiltersResponse(years=years, categories=categories)


@router.get("/{project_id}", response_model=ProjectOut)
async def get_project(
    project_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_permission("project:read"))],
) -> Project:
    result = await db.execute(select(Project).where(Project.id == project_id))
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return project


@router.post("", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
async def create_project(
    body: ProjectCreate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("project:create"))],
) -> Project:
    project = Project(**body.model_dump(), created_by=current_user.id)
    db.add(project)
    await db.flush()
    db.add(AuditLog(
        user_id=current_user.id, module="project", action="create",
        entity_type="project", entity_id=str(project.id),
        details={"project_name": body.project_name, "customer_name": body.customer_name},
    ))
    await db.commit()
    await db.refresh(project)
    return project


@router.put("/{project_id}", response_model=ProjectOut)
async def update_project(
    project_id: uuid.UUID,
    body: ProjectUpdate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("project:update"))],
) -> Project:
    result = await db.execute(select(Project).where(Project.id == project_id))
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(project, field, value)
    db.add(AuditLog(
        user_id=current_user.id, module="project", action="update",
        entity_type="project", entity_id=str(project_id),
    ))
    await db.commit()
    await db.refresh(project)
    return project
