import math
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, get_db
from app.core.rbac import require_permission, require_super_admin
from app.models.project import PROJECT_CODE_PATTERN, Project
from app.models.user import AuditLog, User
from app.schemas.project import (
    NextProjectCode, PaginatedProjects, ProjectCreate, ProjectDeletionPreview, ProjectDeletionResult,
    ProjectFiltersResponse, ProjectListItem, ProjectOut, ProjectUpdate, SourceFileRetentionOut,
)
from app.services.project_deletion import collect_scope, delete_project_asset
from app.services.retention import project_retention

router = APIRouter(prefix="/projects", tags=["projects"])

DB = Annotated[AsyncSession, Depends(get_db)]


async def next_project_code(db: AsyncSession, year: int) -> str:
    """Next Project ID for a year: PRJ-<year>-<highest used sequence + 1>, starting at 001."""
    codes = (await db.execute(
        select(Project.project_code).where(Project.project_code.like(f"PRJ-{year:04d}-%"))
    )).scalars().all()
    used = [int(m.group(2)) for c in codes if c and (m := PROJECT_CODE_PATTERN.match(c))]
    seq = max(used, default=0) + 1
    if seq > 999:
        raise HTTPException(status_code=409, detail=f"No Project IDs left for {year} (PRJ-{year}-999 is used)")
    return f"PRJ-{year:04d}-{seq:03d}"


@router.get("", response_model=PaginatedProjects)
async def list_projects(
    db: DB,
    _: Annotated[User, Depends(require_permission("project:read"))],
    search: str = Query(default="", max_length=100),
    year: int = Query(default=0),
    category: str = Query(default=""),
    client: str = Query(default=""),
    is_monetized: str = Query(default=""),
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
    if client:
        q = q.where(Project.customer_name == client)
    if is_monetized in ("true", "false"):
        q = q.where(Project.is_monetized == (is_monetized == "true"))

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
    client_rows = await db.execute(
        select(Project.customer_name).distinct().order_by(Project.customer_name)
    )
    clients = [r.customer_name for r in client_rows if r.customer_name]
    return ProjectFiltersResponse(years=years, categories=categories, clients=clients)


@router.get("/next-code", response_model=NextProjectCode)
async def get_next_project_code(
    db: DB,
    _: Annotated[User, Depends(require_permission("project:create"))],
    year: int = Query(ge=1000, le=9999),
) -> NextProjectCode:
    """Preview of the Project ID the next new project for this year will receive."""
    return NextProjectCode(project_year=year, project_code=await next_project_code(db, year))


@router.get("/{project_id}/deletion-preview", response_model=ProjectDeletionPreview)
async def get_project_deletion_preview(
    project_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_super_admin())],
) -> ProjectDeletionPreview:
    project = (await db.execute(select(Project).where(Project.id == project_id))).scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    scope = await collect_scope(db, project)
    return ProjectDeletionPreview(
        project_id=project.id,
        project_code=project.project_code,
        project_name=project.project_name,
        related_counts=scope.counts,
        uploaded_file_count=len(scope.source_file_paths),
        active_dq_runs=scope.active_dq_runs,
        can_delete=bool(project.project_code) and scope.active_dq_runs == 0,
    )


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


@router.get("/{project_id}/source-file-retention", response_model=SourceFileRetentionOut)
async def get_source_file_retention(
    project_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_permission("project:read"))],
) -> SourceFileRetentionOut:
    """Until when uploaded source files are kept: end date + 30 days, or + the approved ROPA retention period."""
    project = (await db.execute(select(Project).where(Project.id == project_id))).scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    return SourceFileRetentionOut(**(await project_retention(db, project)).as_dict())


@router.delete("/{project_id}", response_model=ProjectDeletionResult)
async def delete_project(
    project_id: uuid.UUID,
    db: DB,
    current_user: Annotated[User, Depends(require_super_admin())],
    confirmation_code: str = Query(..., min_length=1, max_length=80),
) -> ProjectDeletionResult:
    project = (await db.execute(select(Project).where(Project.id == project_id))).scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")
    if not project.project_code:
        raise HTTPException(status_code=409, detail="Asset has no project code and cannot be safely confirmed")
    try:
        result = await delete_project_asset(db, project, current_user.id, confirmation_code)
        return ProjectDeletionResult(
            project_id=result.project_id,
            project_code=result.project_code,
            deleted_counts=result.deleted_counts,
            files_deleted=result.files_deleted,
            files_missing=result.files_missing,
            file_cleanup_errors=list(result.file_cleanup_errors),
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc


@router.post("", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
async def create_project(
    body: ProjectCreate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("project:create"))],
) -> Project:
    # The Project ID is always assigned here; retry if a concurrent create took the same number
    for attempt in range(3):
        code = await next_project_code(db, body.project_year)
        project = Project(**body.model_dump(), project_code=code, created_by=current_user.id)
        db.add(project)
        try:
            await db.flush()
            break
        except IntegrityError:
            await db.rollback()
            if attempt == 2:
                raise HTTPException(status_code=409, detail="Could not assign a Project ID, please try again")
    db.add(AuditLog(
        user_id=current_user.id, module="project", action="create",
        entity_type="project", entity_id=str(project.id),
        details={"project_code": code, "project_name": body.project_name, "customer_name": body.customer_name},
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
    changes = body.model_dump(exclude_none=True)
    details = None
    # The Project ID's year must match the project year: a year change assigns a new ID
    if "project_year" in changes and changes["project_year"] != project.project_year:
        old_code = project.project_code
        project.project_code = await next_project_code(db, changes["project_year"])
        details = {"project_code": {"from": old_code, "to": project.project_code}}
    for field, value in changes.items():
        setattr(project, field, value)
    db.add(AuditLog(
        user_id=current_user.id, module="project", action="update",
        entity_type="project", entity_id=str(project_id), details=details,
    ))
    await db.commit()
    await db.refresh(project)
    return project
