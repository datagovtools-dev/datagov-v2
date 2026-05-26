"""Data Quality module router — FR-DQ-001 to FR-DQ-008."""
import math
import os
import re
import tempfile
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.models.dq import DQGCPArchive, DQRun, DQResult, DQFinding
from app.models.metadata import ProjectSourceFile
from app.models.user import AuditLog, User
from app.schemas.dq import (
    DQDeltaItem, DQGCPArchiveOut, DQReviewAction, DQRunCreate,
    DQRunListItem, DQRunOut, DQStatusResponse, ExcelPreviewResult,
    GCPConnectionRequest, GCPConnectionResult, PaginatedDQRun,
    PostgresConnectionRequest, PostgresConnectionResult,
    ProjectSourceFileOut, ProjectFilePreviewResult,
)
from app.worker.tasks.notifications import send_workflow_notification

router = APIRouter(prefix="/dq", tags=["dq"])
DB = Annotated[AsyncSession, Depends(get_db)]

# Temp file registry (in-memory; keyed by temp_file_key)
_TEMP_FILES: dict[str, str] = {}


# ── Source Validation ──────────────────────────────────────────────────────────

@router.post("/validate-gcp", response_model=GCPConnectionResult)
async def validate_gcp_connection(
    body: GCPConnectionRequest,
    _: Annotated[User, Depends(require_permission("dq:create"))],
) -> GCPConnectionResult:
    """Probe BigQuery table and confirm it is reachable."""
    try:
        from google.cloud import bigquery
        client = bigquery.Client(project=body.gcp_project)
        table_ref = f"{body.gcp_project}.{body.bq_dataset}.{body.bq_table}"
        table = client.get_table(table_ref)
        columns = [f.name for f in table.schema]
        return GCPConnectionResult(
            valid=True,
            message=f"Table {table_ref} reachable ({table.num_rows:,} rows)",
            row_count=table.num_rows,
            columns=columns,
        )
    except ImportError:
        return GCPConnectionResult(valid=False, message="google-cloud-bigquery not installed")
    except Exception as exc:
        return GCPConnectionResult(valid=False, message=str(exc))


@router.post("/validate-postgres", response_model=PostgresConnectionResult)
async def validate_postgres_connection(
    body: PostgresConnectionRequest,
    _: Annotated[User, Depends(require_permission("dq:create"))],
) -> PostgresConnectionResult:
    """Probe a PostgreSQL/Supabase table and confirm it is reachable."""
    import asyncio
    import functools

    def _probe(dsn: str, table: str) -> PostgresConnectionResult:
        try:
            import psycopg2
            conn = psycopg2.connect(dsn, connect_timeout=10)
            cur = conn.cursor()
            cur.execute(f'SELECT COUNT(*) FROM "{table}"')
            row_count = cur.fetchone()[0]
            cur.execute(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_name = %s AND table_schema = 'public' "
                "ORDER BY ordinal_position",
                (table,),
            )
            columns = [r[0] for r in cur.fetchall()]
            cur.close()
            conn.close()
            if not columns:
                return PostgresConnectionResult(
                    valid=False,
                    message=f"Table '{table}' not found or has no columns in schema 'public'",
                )
            return PostgresConnectionResult(
                valid=True,
                message=f"Table '{table}' reachable ({row_count:,} rows)",
                row_count=row_count,
                columns=columns,
            )
        except Exception as exc:
            return PostgresConnectionResult(valid=False, message=str(exc))

    loop = asyncio.get_event_loop()
    return await loop.run_in_executor(
        None, functools.partial(_probe, body.connection_string, body.table_name)
    )


@router.post("/upload-excel", response_model=ExcelPreviewResult)
async def upload_excel(
    file: UploadFile = File(...),
    sheet_name: str = Form(default=""),
    _: Annotated[User, Depends(require_permission("dq:create"))] = None,
) -> ExcelPreviewResult:
    """Accept an .xlsx upload, return sheet list and 10-row preview."""
    if not file.filename or not file.filename.endswith((".xlsx", ".xls")):
        raise HTTPException(status_code=400, detail="Only .xlsx / .xls files are accepted")

    content = await file.read()
    suffix = ".xlsx" if file.filename.endswith(".xlsx") else ".xls"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix, prefix="dq_upload_")
    tmp.write(content)
    tmp.close()

    try:
        import openpyxl
        wb = openpyxl.load_workbook(tmp.name, read_only=True, data_only=True)
        ws_name = sheet_name if sheet_name and sheet_name in wb.sheetnames else wb.sheetnames[0]
        ws = wb[ws_name]
        rows = list(ws.iter_rows(values_only=True))
        if not rows:
            raise HTTPException(status_code=422, detail="Sheet is empty")
        headers = [str(h) if h is not None else f"col_{i}" for i, h in enumerate(rows[0])]
        preview = [dict(zip(headers, (str(v) if v is not None else None for v in row))) for row in rows[1:11]]
        row_count = ws.max_row - 1

        key = os.path.basename(tmp.name)
        _TEMP_FILES[key] = tmp.name

        return ExcelPreviewResult(
            filename=file.filename,
            sheet_name=ws_name,
            row_count=row_count,
            columns=headers,
            preview_rows=preview,
            temp_file_key=key,
        )
    except HTTPException:
        raise
    except Exception as exc:
        os.unlink(tmp.name)
        raise HTTPException(status_code=422, detail=f"Could not parse file: {exc}") from exc


# ── Project source file listing + preview ──────────────────────────────────────

@router.get("/project/{project_id}/sources", response_model=list[ProjectSourceFileOut])
async def list_project_sources(
    project_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:create"))],
) -> list[ProjectSourceFile]:
    """Return all Excel/CSV files imported via the Metadata module for a project."""
    rows = (await db.execute(
        select(ProjectSourceFile)
        .where(ProjectSourceFile.project_id == project_id)
        .order_by(ProjectSourceFile.uploaded_at.desc())
    )).scalars().all()
    return list(rows)


@router.get("/project-sources/{file_id}/preview", response_model=ProjectFilePreviewResult)
async def preview_project_source(
    file_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:create"))],
) -> ProjectFilePreviewResult:
    """Read a project source file from the uploads volume and return a 10-row preview."""
    import asyncio
    import functools

    file = (await db.execute(
        select(ProjectSourceFile).where(ProjectSourceFile.id == file_id)
    )).scalar_one_or_none()
    if not file:
        raise HTTPException(status_code=404, detail="Source file not found")

    def _read_preview(path: str) -> tuple[str, int, list[str], list[dict]]:
        try:
            import openpyxl
            wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
            ws = wb.active
            ws_name = ws.title or "Sheet1"
            rows = list(ws.iter_rows(values_only=True))
            if not rows:
                return ws_name, 0, [], []
            headers = [str(h) if h is not None else f"col_{i}" for i, h in enumerate(rows[0])]
            preview = [
                dict(zip(headers, (str(v) if v is not None else None for v in row)))
                for row in rows[1:11]
            ]
            return ws_name, max(0, ws.max_row - 1), headers, preview
        except Exception as exc:
            raise HTTPException(status_code=422, detail=f"Could not read file: {exc}") from exc

    loop = asyncio.get_event_loop()
    ws_name, row_count, columns, preview_rows = await loop.run_in_executor(
        None, functools.partial(_read_preview, file.stored_path)
    )
    return ProjectFilePreviewResult(
        file_id=file.id,
        filename=file.original_filename,
        source_type=file.source_type,
        sheet_name=ws_name,
        row_count=row_count,
        columns=columns,
        preview_rows=preview_rows,
        file_size=file.file_size,
        uploaded_at=file.uploaded_at,
    )


# ── DQ Runs ────────────────────────────────────────────────────────────────────

@router.get("", response_model=PaginatedDQRun)
async def list_dq_runs(
    db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
    project_id: uuid.UUID | None = Query(default=None),
    status_filter: str = Query(default="", alias="status"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
) -> PaginatedDQRun:
    q = select(DQRun)
    if project_id:
        q = q.where(DQRun.project_id == project_id)
    if status_filter:
        q = q.where(DQRun.status == status_filter)
    total = (await db.execute(select(func.count()).select_from(q.subquery()))).scalar_one()
    rows = (await db.execute(
        q.order_by(DQRun.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    )).scalars().all()
    return PaginatedDQRun(
        items=[DQRunListItem.model_validate(r) for r in rows],
        total=total, page=page, page_size=page_size,
        pages=max(1, math.ceil(total / page_size)),
    )


@router.post("", response_model=DQRunOut, status_code=201)
async def create_dq_run(
    body: DQRunCreate, db: DB,
    current_user: Annotated[User, Depends(require_permission("dq:create"))],
) -> DQRun:
    # Resolve stored_path + override dataset fields for project_file source type
    stored_path: str | None = None
    dataset_name = body.dataset_name
    dataset_location = body.dataset_location

    if body.source_type == "project_file":
        if not body.source_file_id:
            raise HTTPException(status_code=400, detail="source_file_id is required for project_file source type")
        source_file = (await db.execute(
            select(ProjectSourceFile).where(ProjectSourceFile.id == body.source_file_id)
        )).scalar_one_or_none()
        if not source_file:
            raise HTTPException(status_code=404, detail="Source file not found")
        stored_path = source_file.stored_path
        dataset_name = source_file.original_filename
        dataset_location = f"project_file://{source_file.id}"

    run = DQRun(
        project_id=body.project_id,
        source_file_id=body.source_file_id,
        run_name=body.run_name,
        dataset_name=dataset_name,
        dataset_location=dataset_location,
        status="pending",
        triggered_by=current_user.id,
    )
    db.add(run)
    db.add(AuditLog(user_id=current_user.id, module="dq", action="create",
                    entity_type="dq_run", entity_id="pending"))
    await db.flush()

    db.add(AuditLog(user_id=current_user.id, module="dq", action="create",
                    entity_type="dq_run", entity_id=str(run.id)))
    await db.commit()
    await db.refresh(run)

    # Dispatch Celery task
    try:
        from app.worker.tasks.dq import run_dq_generation
        task = run_dq_generation.delay(
            run_id=str(run.id),
            source_type=body.source_type,
            dataset_location=dataset_location,
            gcp_project=body.gcp_project,
            bq_dataset_name=body.bq_dataset,
            bq_table=body.bq_table,
            temp_file_key=body.temp_file_key,
            sheet_name=body.sheet_name,
            postgres_connection_string=body.postgres_connection_string,
            postgres_table=body.postgres_table,
            stored_path=stored_path,
        )
        run.celery_task_id = task.id
        await db.commit()
        await db.refresh(run)
    except Exception as exc:
        import logging
        logging.getLogger(__name__).warning("Could not dispatch DQ task: %s", exc)

    return run


@router.get("/{run_id}", response_model=DQRunOut)
async def get_dq_run(
    run_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> DQRun:
    result = await db.execute(select(DQRun).where(DQRun.id == run_id))
    run = result.scalar_one_or_none()
    if not run:
        raise HTTPException(status_code=404, detail="DQ run not found")
    return run


@router.get("/{run_id}/status", response_model=DQStatusResponse)
async def poll_run_status(
    run_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> DQStatusResponse:
    result = await db.execute(select(DQRun).where(DQRun.id == run_id))
    run = result.scalar_one_or_none()
    if not run:
        raise HTTPException(status_code=404, detail="DQ run not found")

    progress_map = {"pending": 0, "running": 50, "completed": 100, "failed": 0,
                    "under_review": 100, "approved": 100, "rejected": 100}
    msg_map = {
        "pending": "Queued — waiting for worker",
        "running": "Running DQ checks…",
        "completed": "Completed — awaiting review",
        "failed": "Run failed",
        "under_review": "Under governance review",
        "approved": "Approved and archived",
        "rejected": "Rejected — revision required",
    }
    return DQStatusResponse(
        run_id=run.id,
        status=run.status,
        progress_pct=progress_map.get(run.status, 0),
        overall_score=run.overall_score,
        message=msg_map.get(run.status, run.status),
    )


# ── Governance Review ──────────────────────────────────────────────────────────

@router.post("/{run_id}/review", response_model=DQRunOut)
async def review_dq_run(
    run_id: uuid.UUID, body: DQReviewAction, db: DB,
    current_user: Annotated[User, Depends(require_permission("dq:approve"))],
) -> DQRun:
    result = await db.execute(select(DQRun).where(DQRun.id == run_id))
    run = result.scalar_one_or_none()
    if not run:
        raise HTTPException(status_code=404, detail="DQ run not found")
    if run.status not in ("completed", "under_review"):
        raise HTTPException(status_code=400, detail="Run is not in a reviewable state")

    status_map = {"approve": "approved", "reject": "rejected", "request_revision": "under_review"}
    new_status = status_map.get(body.action)
    if not new_status:
        raise HTTPException(status_code=400, detail="action must be approve | reject | request_revision")

    run.status = new_status
    db.add(AuditLog(
        user_id=current_user.id, module="dq", action=f"review_{body.action}",
        entity_type="dq_run", entity_id=str(run_id),
        details={"action": body.action, "comments": body.comments},
    ))
    await db.commit()
    await db.refresh(run)

    event_map = {"approve": "dq_approved", "reject": "dq_rejected", "request_revision": "dq_review_requested"}
    event = event_map.get(body.action)
    if event:
        send_workflow_notification.delay(
            event=event, entity_id=str(run_id), recipients=[],
            context={"run_id": str(run_id), "actor": current_user.full_name},
        )

    # Trigger GCP archive on approval
    if body.action == "approve":
        try:
            from app.worker.tasks.dq import archive_to_gcp
            archive_to_gcp.delay(run_id=str(run_id))
        except Exception:
            pass

    return run


# ── GCP Archive ────────────────────────────────────────────────────────────────

@router.post("/{run_id}/archive", response_model=DQGCPArchiveOut)
async def trigger_archive(
    run_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("dq:approve"))],
) -> DQGCPArchive:
    result = await db.execute(select(DQRun).where(DQRun.id == run_id))
    run = result.scalar_one_or_none()
    if not run:
        raise HTTPException(status_code=404, detail="DQ run not found")
    if run.status != "approved":
        raise HTTPException(status_code=400, detail="Only approved runs can be archived")

    # Idempotent — skip if already archived
    existing = (await db.execute(
        select(DQGCPArchive).where(DQGCPArchive.run_id == run_id)
    )).scalar_one_or_none()
    if existing and existing.archive_status == "completed":
        return existing

    archive = DQGCPArchive(
        run_id=run_id,
        gcs_report_path=f"gs://dq-governance-outputs/{run_id}/dq_results.xlsx",
        bq_dataset="dq_governance",
        bq_table="run_summaries",
        archive_status="pending",
    )
    db.add(archive)
    await db.commit()
    await db.refresh(archive)

    try:
        from app.worker.tasks.dq import archive_to_gcp
        archive_to_gcp.delay(run_id=str(run_id))
    except Exception:
        pass

    return archive


@router.get("/{run_id}/archive", response_model=DQGCPArchiveOut)
async def get_archive(
    run_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> DQGCPArchive:
    archive = (await db.execute(
        select(DQGCPArchive).where(DQGCPArchive.run_id == run_id)
    )).scalar_one_or_none()
    if not archive:
        raise HTTPException(status_code=404, detail="No archive found for this run")
    return archive


# ── Re-run / versioning ────────────────────────────────────────────────────────

@router.post("/{run_id}/rerun", response_model=DQRunOut, status_code=201)
async def rerun_dq(
    run_id: uuid.UUID, db: DB,
    current_user: Annotated[User, Depends(require_permission("dq:create"))],
) -> DQRun:
    """Create a new run version based on the same dataset."""
    result = await db.execute(select(DQRun).where(DQRun.id == run_id))
    original = result.scalar_one_or_none()
    if not original:
        raise HTTPException(status_code=404, detail="DQ run not found")

    # Increment run_name version number
    base_name = re.sub(r"\s+v\d+$", "", original.run_name)
    count = (await db.execute(
        select(func.count()).where(DQRun.dataset_name == original.dataset_name)
    )).scalar_one()

    new_run = DQRun(
        project_id=original.project_id,
        run_name=f"{base_name} v{count + 1}",
        dataset_name=original.dataset_name,
        dataset_location=original.dataset_location,
        status="pending",
        triggered_by=current_user.id,
    )
    db.add(new_run)
    db.add(AuditLog(user_id=current_user.id, module="dq", action="rerun",
                    entity_type="dq_run", entity_id=str(run_id)))
    await db.flush()
    await db.commit()
    await db.refresh(new_run)
    return new_run


# ── Delta comparison ───────────────────────────────────────────────────────────

@router.get("/{run_id}/delta/{prev_run_id}", response_model=list[DQDeltaItem])
async def get_delta(
    run_id: uuid.UUID, prev_run_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> list[DQDeltaItem]:
    curr_results = (await db.execute(
        select(DQResult).where(DQResult.run_id == run_id)
    )).scalars().all()
    prev_results = (await db.execute(
        select(DQResult).where(DQResult.run_id == prev_run_id)
    )).scalars().all()

    prev_map = {r.check_name: r for r in prev_results}
    deltas = []
    for r in curr_results:
        prev = prev_map.get(r.check_name)
        curr_score = float(r.actual_value) if r.actual_value and r.actual_value.replace(".", "").isdigit() else None
        prev_score = float(prev.actual_value) if prev and prev.actual_value and prev.actual_value.replace(".", "").isdigit() else None
        delta = round(curr_score - prev_score, 2) if curr_score is not None and prev_score is not None else None
        deltas.append(DQDeltaItem(
            check_name=r.check_name,
            column_name=r.column_name,
            prev_score=prev_score,
            curr_score=curr_score,
            delta=delta,
            status_changed=prev.status != r.status if prev else True,
        ))
    return deltas
