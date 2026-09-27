"""Data Quality module router — FR-DQ-001 to FR-DQ-008."""
import math
import os
import re
import tempfile
import uuid
from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.models.dq import DQGCPArchive, DQRun, DQResult, DQFinding
from app.models.metadata import MetadataRecord, ProjectSourceFile
from app.models.user import AuditLog, User
from app.schemas.dq import (
    DQDeltaItem, DQGCPArchiveOut, DQProgressRun, DQProjectProgress, DQProjectReport, DQProjectReportTable,
    DQReviewAction, DQRunCreate,
    DQRunListItem, DQRunOut, DQStatusResponse, DQTableSummary, ExcelPreviewResult,
    GCPConnectionRequest, GCPConnectionResult, PaginatedDQRun,
    ProjectFileDQSummary, ProjectSourceFileOut, ProjectFilePreviewResult,
)
from app.worker.tasks.notifications import send_workflow_notification

router = APIRouter(prefix="/dq", tags=["dq"])
DB = Annotated[AsyncSession, Depends(get_db)]


async def _load_run(db: AsyncSession, run_id: uuid.UUID) -> DQRun | None:
    """Fetch a DQRun with all nested relationships eager-loaded (required for async SA)."""
    return (await db.execute(
        select(DQRun)
        .where(DQRun.id == run_id)
        .options(
            selectinload(DQRun.results).selectinload(DQResult.findings),
            selectinload(DQRun.gcp_archive),
        )
    )).scalar_one_or_none()


async def _next_run_version(db: AsyncSession, project_id: uuid.UUID, dataset_name: str) -> int:
    """DQ update number for a dataset within a project: highest existing version + 1 (first run = 1)."""
    current = (await db.execute(
        select(func.max(DQRun.version)).where(DQRun.project_id == project_id, DQRun.dataset_name == dataset_name)
    )).scalar_one()
    return (current or 0) + 1


# Time estimate for the Generate step. The worker runs one DQ file at a time (--concurrency=1) and
# llama3.2:3b on CPU needs about a minute per column (35-150 s measured, 2026-09-27).
SECONDS_PER_COLUMN = 65
MODEL_WARMUP_SECONDS = 60     # first AI call while the model loads
UNKNOWN_COLUMN_COUNT = 10     # used when the column count is not known yet
ETA_PRIOR_COLUMNS = 2         # weight of the usual speed against the speed measured so far
QUEUE_LOOKBACK = timedelta(hours=24)  # older pending runs are stale, not queued work


def _count_columns(path: str) -> int | None:
    """Number of named columns in the first sheet's header row (None when unreadable)."""
    try:
        import openpyxl

        wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
        try:
            header = next(wb.active.iter_rows(min_row=1, max_row=1, values_only=True), ())
        finally:
            wb.close()
        return sum(1 for h in header if h not in (None, "")) or None
    except Exception:
        return None


def _utc(value: datetime | None) -> datetime | None:
    return value.replace(tzinfo=UTC) if value is not None and value.tzinfo is None else value


def _remaining_seconds(run: DQRun, now: datetime) -> int:
    """Estimated seconds until `run` finishes, from its progress so far."""
    if run.status not in ("pending", "running"):
        return 0
    total = run.columns_total or UNKNOWN_COLUMN_COUNT
    done = run.columns_done or 0
    started = _utc(run.started_at)
    if run.status == "running" and started:
        elapsed = max((now - started).total_seconds(), 0)
        if done:
            # speed so far, blended with the usual speed so the first (model-loading) column
            # does not swing the estimate; the estimate keeps falling while a column runs
            per_column = (elapsed + ETA_PRIOR_COLUMNS * SECONDS_PER_COLUMN) / (done + ETA_PRIOR_COLUMNS)
            return int(max(total * per_column - elapsed, 15))
        return int(max(total * SECONDS_PER_COLUMN + MODEL_WARMUP_SECONDS - elapsed, 15))
    return total * SECONDS_PER_COLUMN


ACTIVE_STATUSES = ("pending", "running")
PROGRESS_WINDOW = timedelta(hours=12)  # finished runs still listed on the progress page


async def _queue_and_eta(db: AsyncSession, run: DQRun, now: datetime) -> tuple[int | None, int | None]:
    """Files queued before `run` and the seconds until it finishes (the worker runs one file at a time)."""
    if run.status not in ACTIVE_STATUSES:
        return None, None
    ahead = (await db.execute(
        select(DQRun).where(
            DQRun.status.in_(ACTIVE_STATUSES),
            DQRun.created_at < run.created_at,
            DQRun.created_at >= (run.created_at - QUEUE_LOOKBACK),
            DQRun.id != run.id,
        )
    )).scalars().all() if run.status == "pending" else []
    return len(ahead), sum(_remaining_seconds(r, now) for r in ahead) + _remaining_seconds(run, now)


async def _active_run_for_file(db: AsyncSession, source_file_id: uuid.UUID | None) -> DQRun | None:
    """A queued or running DQ run of this source file (stale pending runs older than a day do not count)."""
    if source_file_id is None:
        return None
    return (await db.execute(
        select(DQRun).where(
            DQRun.source_file_id == source_file_id,
            DQRun.status.in_(ACTIVE_STATUSES),
            DQRun.created_at >= datetime.now(UTC).replace(tzinfo=None) - QUEUE_LOOKBACK,
        ).order_by(DQRun.created_at.desc())
    )).scalars().first()


def _already_running(run: DQRun) -> HTTPException:
    state = "running" if run.status == "running" else "queued"
    return HTTPException(
        status_code=409,
        detail=f"A DQ run for '{run.dataset_name}' is already {state} (version {run.version}). "
               "Follow it on Data Quality > this project > View progress; start a new run after it finishes.",
    )


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
) -> list[ProjectSourceFileOut]:
    """Return all Excel/CSV files imported via the Metadata module for a project."""
    rows = (await db.execute(
        select(ProjectSourceFile)
        .where(ProjectSourceFile.project_id == project_id)
        .order_by(ProjectSourceFile.uploaded_at.desc())
    )).scalars().all()
    out = []
    for f in rows:
        active = await _active_run_for_file(db, f.id)
        out.append(ProjectSourceFileOut.model_validate(f).model_copy(update={
            "file_available": os.path.exists(f.stored_path),
            "active_run_id": active.id if active else None,
            "active_run_status": active.status if active else None,
        }))
    return out


@router.get("/project/{project_id}/summary", response_model=list[ProjectFileDQSummary])
async def get_project_dq_summary(
    project_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> list:
    """Return source files for a project with their latest DQ run stats."""
    files = (await db.execute(
        select(ProjectSourceFile)
        .where(ProjectSourceFile.project_id == project_id)
        .order_by(ProjectSourceFile.uploaded_at.desc())
    )).scalars().all()

    if not files:
        return []

    file_ids = [f.id for f in files]
    runs = (await db.execute(
        select(DQRun)
        .where(DQRun.source_file_id.in_(file_ids))
        .order_by(DQRun.created_at.desc())
    )).scalars().all()

    runs_by_file: dict = {f.id: [] for f in files}
    for r in runs:
        if r.source_file_id in runs_by_file:
            runs_by_file[r.source_file_id].append(r)

    result = []
    for f in files:
        file_runs = runs_by_file.get(f.id, [])
        latest = file_runs[0] if file_runs else None
        result.append(ProjectFileDQSummary(
            id=f.id,
            project_id=f.project_id,
            source_type=f.source_type,
            original_filename=f.original_filename,
            file_size=f.file_size,
            uploaded_at=f.uploaded_at,
            total_runs=len(file_runs),
            latest_run_id=latest.id if latest else None,
            latest_run_name=latest.run_name if latest else None,
            latest_run_status=latest.status if latest else None,
            latest_run_score=str(latest.overall_score) if latest and latest.overall_score is not None else None,
            latest_run_date=latest.completed_at or latest.created_at if latest else None,
        ))
    return result


@router.get("/project/{project_id}/tables-summary", response_model=list[DQTableSummary])
async def get_project_dq_tables_summary(
    project_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> list:
    """Return metadata tables for a project with their latest DQ run status.

    Each row represents one table (= one sheet for Excel), aligned with the
    Metadata module's table-level view.  The link is:
      metadata_records.data_domain_table ("file.xlsx - SheetName")
      → extract filename → project_source_files → dq_runs
    """
    # 1. Distinct tables from metadata
    table_rows = (await db.execute(
        select(
            MetadataRecord.data_domain_table,
            MetadataRecord.source_type,
            func.count(MetadataRecord.id).label("cnt"),
        )
        .where(MetadataRecord.project_id == project_id)
        .group_by(MetadataRecord.data_domain_table, MetadataRecord.source_type)
        .order_by(MetadataRecord.data_domain_table)
    )).all()

    # 2. All source files for the project, keyed by filename
    files = (await db.execute(
        select(ProjectSourceFile).where(ProjectSourceFile.project_id == project_id)
    )).scalars().all()
    files_by_name: dict[str, ProjectSourceFile] = {f.original_filename: f for f in files}

    # 3. All DQ runs linked to those files, grouped by source_file_id
    runs_by_file: dict = {f.id: [] for f in files}
    if files:
        runs = (await db.execute(
            select(DQRun)
            .where(DQRun.source_file_id.in_([f.id for f in files]))
            .order_by(DQRun.created_at.desc())
        )).scalars().all()
        for r in runs:
            if r.source_file_id in runs_by_file:
                runs_by_file[r.source_file_id].append(r)

    # 4. Build result — one row per metadata table
    result = []
    for table_name, source_type, attr_count in table_rows:
        # Extract filename from "filename - SheetName" pattern
        filename: str | None = table_name.split(" - ")[0] if " - " in table_name else None
        # Single-file uploads store only the sheet name; fall back to the one file if unambiguous
        if filename is None and len(files) == 1:
            filename = files[0].original_filename

        source_file = files_by_name.get(filename) if filename else None
        file_runs = runs_by_file.get(source_file.id, []) if source_file else []
        newest = file_runs[0] if file_runs else None
        # Show the newest run with results, so a re-run keeps the previous version visible until it finishes
        latest = next((r for r in file_runs if r.status in REPORT_STATUSES), newest)
        newer = newest if newest is not None and latest is not None and newest.id != latest.id else None

        result.append(DQTableSummary(
            table_name=table_name,
            source_type=source_type,
            attribute_count=attr_count,
            source_file_id=source_file.id if source_file else None,
            total_runs=len(file_runs),
            latest_run_id=latest.id if latest else None,
            latest_run_name=latest.run_name if latest else None,
            latest_run_status=latest.status if latest else None,
            latest_run_score=(
                str(latest.overall_score)
                if latest and latest.overall_score is not None else None
            ),
            latest_run_date=latest.completed_at or latest.created_at if latest else None,
            latest_run_version=latest.version if latest else None,
            newer_run_id=newer.id if newer else None,
            newer_run_status=newer.status if newer else None,
            newer_run_version=newer.version if newer else None,
        ))
    return result


@router.get("/project/{project_id}/progress", response_model=DQProjectProgress)
async def get_project_dq_progress(
    project_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> DQProjectProgress:
    """Runs to show on the project's progress page: queued/running ones and those finished recently."""
    now = datetime.now(UTC)
    since = now.replace(tzinfo=None) - PROGRESS_WINDOW
    runs = (await db.execute(
        select(DQRun).where(
            DQRun.project_id == project_id,
            (DQRun.status.in_(ACTIVE_STATUSES)) | (DQRun.created_at >= since),
        ).order_by(DQRun.created_at)
    )).scalars().all()
    active = [r for r in runs if r.status in ACTIVE_STATUSES and _utc(r.created_at) >= now - QUEUE_LOOKBACK]
    eta = None
    if active:
        etas = [(await _queue_and_eta(db, r, now))[1] or 0 for r in active]
        eta = max(etas)
    return DQProjectProgress(
        project_id=project_id,
        active_count=len(active),
        eta_seconds=eta,
        runs=[DQProgressRun(run_id=r.id, dataset_name=r.dataset_name, version=r.version, status=r.status,
                            created_at=r.created_at) for r in runs],
    )


REPORT_STATUSES = ("completed", "under_review", "approved", "rejected")  # runs that have results


@router.get("/project/{project_id}/report", response_model=DQProjectReport)
async def get_project_dq_report(
    project_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> DQProjectReport:
    """Project DQ report: for every table (source file) the latest run that has results.

    Tables are keyed by source file (or dataset name for runs without one). When the newest run of
    a table failed or is still running, the previous run with results is used and noted.
    """
    runs = (await db.execute(
        select(DQRun)
        .where(DQRun.project_id == project_id)
        .options(selectinload(DQRun.results).selectinload(DQResult.findings), selectinload(DQRun.gcp_archive))
        .order_by(DQRun.created_at.desc())
    )).scalars().all()

    newest: dict[str, DQRun] = {}
    used: dict[str, DQRun] = {}
    for r in runs:  # newest first
        key = str(r.source_file_id or r.dataset_name)
        newest.setdefault(key, r)
        if key not in used and r.status in REPORT_STATUSES and r.results:
            used[key] = r

    tables = [
        DQProjectReportTable(
            dataset_name=run.dataset_name,
            run=DQRunOut.model_validate(run),
            newer_run_status=newest[key].status if newest[key].id != run.id else None,
        )
        for key, run in sorted(used.items(), key=lambda item: item[1].dataset_name.lower())
    ]
    return DQProjectReport(
        project_id=project_id,
        generated_at=datetime.now(UTC),
        tables=tables,
        tables_without_results=sorted(r.dataset_name for key, r in newest.items() if key not in used),
    )


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
        if not os.path.exists(source_file.stored_path):
            raise HTTPException(
                status_code=400,
                detail=f"Source file '{source_file.original_filename}' is no longer in the uploads folder; "
                       "re-upload it in Metadata, then start a new DQ run",
            )
        active = await _active_run_for_file(db, source_file.id)
        if active is not None:
            raise _already_running(active)
        stored_path = source_file.stored_path
        dataset_name = source_file.original_filename
        dataset_location = f"project_file://{source_file.id}"

    run = DQRun(
        project_id=body.project_id,
        source_file_id=body.source_file_id,
        run_name=body.run_name,
        dataset_name=dataset_name,
        dataset_location=dataset_location,
        version=await _next_run_version(db, body.project_id, dataset_name),
        status="pending",
        triggered_by=current_user.id,
        columns_total=_count_columns(stored_path) if stored_path else None,  # for the time estimate
        columns_done=0,
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
            stored_path=stored_path,
        )
        run.celery_task_id = task.id
        await db.commit()
        await db.refresh(run)
    except Exception as exc:
        import logging
        logging.getLogger(__name__).warning("Could not dispatch DQ task: %s", exc)

    loaded = await _load_run(db, run.id)
    return loaded or run


@router.get("/{run_id}", response_model=DQRunOut)
async def get_dq_run(
    run_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("dq:read"))],
) -> DQRun:
    run = await _load_run(db, run_id)
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

    from app.services.dq_failures import CATEGORIES

    # One worker runs DQ files one at a time: everything queued before this run goes first
    queue_position, eta = await _queue_and_eta(db, run, datetime.now(UTC))

    total, done = run.columns_total, run.columns_done or 0
    if run.status == "running":
        progress = int(100 * done / total) if total else 0
    else:
        progress = {"completed": 100, "under_review": 100, "approved": 100, "rejected": 100}.get(run.status, 0)

    msg_map = {
        "pending": "Queued — waiting for worker",
        "running": "Running DQ checks…",
        "completed": "Completed — awaiting review",
        "failed": "Run failed",
        "under_review": "Under governance review",
        "approved": "Approved and archived",
        "rejected": "Rejected — revision required",
    }
    message = msg_map.get(run.status, run.status)
    if run.status == "pending" and queue_position:
        message = f"Queued — {queue_position} file{'s' if queue_position > 1 else ''} ahead"
    elif run.status == "running" and total:
        message = f"Running — {done} of {total} columns done"

    error_category, error_detail = run.error_category, run.error_message
    if run.status == "failed" and not error_category:
        # Runs that failed before failure reasons were recorded: the missing file is the one cause we can still check
        source = await db.get(ProjectSourceFile, run.source_file_id) if run.source_file_id else None
        if source is not None and not os.path.exists(source.stored_path):
            error_category, error_detail = "source_file_missing", f"Missing file: {source.original_filename}"
        else:
            error_category, error_detail = "unexpected", "The reason was not recorded for this older run; see the worker log."

    category = CATEGORIES.get(error_category or "")
    return DQStatusResponse(
        run_id=run.id,
        status=run.status,
        progress_pct=progress,
        overall_score=run.overall_score,
        message=message,
        columns_total=total,
        columns_done=done,
        started_at=run.started_at,
        completed_at=run.completed_at,
        queue_position=queue_position,
        eta_seconds=eta,
        error_category=error_category,
        error_title=category.title if category else None,
        error_explanation=category.explanation if category else None,
        error_action=category.action if category else None,
        error_detail=error_detail,
        will_retry=run.status == "pending" and bool(run.error_category),
    )


# ── Governance Review ──────────────────────────────────────────────────────────

@router.post("/{run_id}/review", response_model=DQRunOut)
async def review_dq_run(
    run_id: uuid.UUID, body: DQReviewAction, db: DB,
    current_user: Annotated[User, Depends(require_permission("dq:approve"))],
) -> DQRun:
    run = await _load_run(db, run_id)
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

    event_map = {"approve": "dq_approved", "reject": "dq_rejected", "request_revision": "dq_review_requested"}
    event = event_map.get(body.action)
    if event:
        try:
            send_workflow_notification.delay(
                event=event, entity_id=str(run_id), recipients=[],
                context={"run_id": str(run_id), "actor": current_user.full_name},
            )
        except Exception:
            pass

    # Trigger GCP archive on approval
    if body.action == "approve":
        try:
            from app.worker.tasks.dq import archive_to_gcp
            archive_to_gcp.delay(run_id=str(run_id))
        except Exception:
            pass

    loaded = await _load_run(db, run_id)
    return loaded or run


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
    """Create and dispatch a new version of a run on the same project source file."""
    result = await db.execute(select(DQRun).where(DQRun.id == run_id))
    original = result.scalar_one_or_none()
    if not original:
        raise HTTPException(status_code=404, detail="DQ run not found")
    source_file = (await db.execute(
        select(ProjectSourceFile).where(ProjectSourceFile.id == original.source_file_id)
    )).scalar_one_or_none() if original.source_file_id else None
    if source_file is None:
        raise HTTPException(
            status_code=400,
            detail="Re-run needs the run's project source file; it is missing, so start a new DQ run instead",
        )
    if not os.path.exists(source_file.stored_path):
        raise HTTPException(
            status_code=400,
            detail=f"Source file '{source_file.original_filename}' is no longer in the uploads folder; "
                   "re-upload it in Metadata, then start a new DQ run",
        )
    active = await _active_run_for_file(db, source_file.id)
    if active is not None:
        raise _already_running(active)

    version = await _next_run_version(db, original.project_id, original.dataset_name)
    base_name = re.sub(r"\s+v\d+$", "", original.run_name)
    new_run = DQRun(
        project_id=original.project_id,
        source_file_id=original.source_file_id,
        run_name=f"{base_name} v{version}",
        dataset_name=original.dataset_name,
        dataset_location=original.dataset_location,
        version=version,
        status="pending",
        triggered_by=current_user.id,
        columns_total=_count_columns(source_file.stored_path),
        columns_done=0,
    )
    db.add(new_run)
    db.add(AuditLog(user_id=current_user.id, module="dq", action="rerun",
                    entity_type="dq_run", entity_id=str(run_id)))
    await db.flush()
    await db.commit()
    await db.refresh(new_run)

    try:
        from app.worker.tasks.dq import run_dq_generation
        task = run_dq_generation.delay(
            run_id=str(new_run.id), source_type="project_file",
            dataset_location=new_run.dataset_location, stored_path=source_file.stored_path,
        )
        new_run.celery_task_id = task.id
        await db.commit()
        await db.refresh(new_run)
    except Exception as exc:
        import logging
        logging.getLogger(__name__).warning("Could not dispatch DQ re-run task: %s", exc)
    return await _load_run(db, new_run.id) or new_run


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
