"""Metadata Management router — FR-META-001 to FR-META-022 (Phase 5)."""
import uuid
from datetime import date
from typing import Annotated

import os
import tempfile

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from sqlalchemy import select, update, func, distinct
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.models.metadata import DataOwnerSteward, MetadataRecord
from app.models.project import Project
from app.models.user import AuditLog, User
from app.services.ai_generation import (
    AIGenerationError,
    apply_generated_definition,
    build_candidate_from_config,
    config_is_ready,
    generate_metadata_definition,
    get_ai_config,
)
from app.services.metadata_population import (
    parse_csv_upload_content,
    parse_excel_upload_file,
    populate_metadata_records,
)
from app.schemas.metadata import (
    AIRegenerateRequest, BulkGroupingRequest, DataOwnerStewardCreate,
    DataOwnerStewardOut, MetadataBatchSaveRequest, MetadataBatchSaveResult,
    MetadataRecordOut, MetadataRecordUpdate, OWNER_ROLE_TYPES,
    ProceedMetadataRequest, ProceedResponse, SourceTableInfo,
)

router = APIRouter(prefix="/metadata", tags=["metadata"])
DB = Annotated[AsyncSession, Depends(get_db)]


# ── Global stats ──────────────────────────────────────────────────────────────

@router.get("/stats", response_model=dict)
async def get_metadata_stats(
    db: DB,
    _: Annotated[User, Depends(require_permission("metadata:read"))],
) -> dict:
    """Return total projects, tables, and attributes with metadata records."""
    result = await db.execute(
        select(
            func.count(distinct(MetadataRecord.project_id)).label("projects"),
            func.count(distinct(
                func.concat(MetadataRecord.project_id, "||", MetadataRecord.data_domain_table)
            )).label("tables"),
            func.count(MetadataRecord.id).label("attributes"),
        )
    )
    row = result.one()
    return {"projects": row.projects, "tables": row.tables, "attributes": row.attributes}


# ── FR-META-022: Data Owner & Steward Management ──────────────────────────────

@router.get("/owners/{project_id}", response_model=list[DataOwnerStewardOut])
async def list_owners(
    project_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("metadata:read"))],
) -> list[DataOwnerSteward]:
    result = await db.execute(
        select(DataOwnerSteward)
        .where(DataOwnerSteward.project_id == project_id)
        .order_by(DataOwnerSteward.role_type)
    )
    return result.scalars().all()


@router.post("/owners/{project_id}", response_model=DataOwnerStewardOut, status_code=201)
async def upsert_owner(
    project_id: uuid.UUID,
    body: DataOwnerStewardCreate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
) -> DataOwnerSteward:
    if body.role_type not in OWNER_ROLE_TYPES:
        raise HTTPException(status_code=400, detail=f"role_type must be one of {OWNER_ROLE_TYPES}")

    existing = (await db.execute(
        select(DataOwnerSteward).where(
            DataOwnerSteward.project_id == project_id,
            DataOwnerSteward.role_type == body.role_type,
            DataOwnerSteward.email == body.email,
        )
    )).scalar_one_or_none()

    if existing:
        existing.full_name = body.full_name
        existing.email = body.email
        await db.commit()
        await db.refresh(existing)
        return existing

    record = DataOwnerSteward(project_id=project_id, **body.model_dump())
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return record


@router.delete("/owners/{project_id}/{owner_id}", status_code=204)
async def delete_owner(
    project_id: uuid.UUID, owner_id: uuid.UUID, db: DB,
    _: Annotated[User, Depends(require_permission("metadata:update"))],
) -> None:
    record = (await db.execute(
        select(DataOwnerSteward).where(
            DataOwnerSteward.id == owner_id,
            DataOwnerSteward.project_id == project_id,
        )
    )).scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Owner/steward not found")
    await db.delete(record)
    await db.commit()


# ── Excel Upload — discover sheets as tables ─────────────────────────────────

@router.post("/upload-excel")
async def upload_excel_metadata(
    file: UploadFile = File(...),
    _: Annotated[User, Depends(require_permission("metadata:create"))] = None,
) -> dict:
    """Upload an Excel or CSV file and return sheet names + column/row counts as discoverable tables."""
    ext = os.path.splitext(file.filename or "upload.xlsx")[1].lower()
    if ext not in (".xlsx", ".xls", ".csv"):
        raise HTTPException(status_code=400, detail="Only .xlsx / .xls / .csv files are supported")

    temp_key = f"meta_excel_{uuid.uuid4().hex}{ext}"
    temp_path = os.path.join(tempfile.gettempdir(), temp_key)

    content = await file.read()
    with open(temp_path, "wb") as f:
        f.write(content)

    try:
        if ext == ".csv":
            sheets, tables = parse_csv_upload_content(content, file.filename or "data.csv")
        else:
            sheets, tables = parse_excel_upload_file(temp_path)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not parse file: {exc}") from exc

    return {"temp_key": temp_key, "sheets": sheets, "tables": tables}


# ── FR-META-001: Source Table Discovery ───────────────────────────────────────

@router.get("/tables/{project_id}", response_model=list[SourceTableInfo])
async def list_source_tables(
    project_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_permission("metadata:read"))],
    source_type: str = Query(default="gcp"),
    gcp_project: str = Query(default=""),
    bq_dataset: str = Query(default=""),
    connection_string: str = Query(default=""),
    pg_schema: str = Query(default="public"),
) -> list[SourceTableInfo]:
    """List available tables and flag which are already documented."""
    # Fetch tables that already have records for this project
    documented_result = await db.execute(
        select(MetadataRecord.data_domain_table)
        .where(MetadataRecord.project_id == project_id)
        .distinct()
    )
    documented_tables = {r[0] for r in documented_result.fetchall()}

    tables: list[SourceTableInfo] = []

    if source_type == "postgresql" and connection_string:
        try:
            import psycopg2
            src_conn = psycopg2.connect(connection_string)
            src_cur = src_conn.cursor()
            src_cur.execute(
                "SELECT table_name FROM information_schema.tables "
                "WHERE table_schema = %s AND table_type = 'BASE TABLE' ORDER BY table_name",
                (pg_schema,),
            )
            for (table_name,) in src_cur.fetchall():
                src_cur.execute(
                    "SELECT COUNT(*) FROM information_schema.columns "
                    "WHERE table_schema = %s AND table_name = %s",
                    (pg_schema, table_name),
                )
                col_count = src_cur.fetchone()[0]
                try:
                    src_cur.execute(f'SELECT COUNT(*) FROM "{pg_schema}"."{table_name}"')
                    row_count = src_cur.fetchone()[0]
                except Exception:
                    row_count = None
                full_name = f"{pg_schema}.{table_name}"
                tables.append(SourceTableInfo(
                    table_name=table_name,
                    column_count=col_count,
                    documented=full_name in documented_tables or table_name in documented_tables,
                    row_count=row_count,
                    source_type="postgresql",
                ))
            src_conn.close()
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"PostgreSQL error: {exc}") from exc

    elif source_type == "gcp" and gcp_project and bq_dataset:
        try:
            from google.cloud import bigquery
            client = bigquery.Client(project=gcp_project)
            for tbl in client.list_tables(f"{gcp_project}.{bq_dataset}"):
                full_name = f"{bq_dataset}.{tbl.table_id}"
                table_obj = client.get_table(f"{gcp_project}.{bq_dataset}.{tbl.table_id}")
                tables.append(SourceTableInfo(
                    table_name=tbl.table_id,
                    column_count=len(table_obj.schema),
                    documented=full_name in documented_tables,
                    row_count=table_obj.num_rows,
                    source_type="gcp",
                ))
        except Exception as exc:
            raise HTTPException(status_code=400, detail=f"GCP error: {exc}") from exc
    else:
        # Fallback: return tables already in DB for this project
        for dt in documented_tables:
            recs_result = await db.execute(
                select(MetadataRecord)
                .where(MetadataRecord.project_id == project_id,
                       MetadataRecord.data_domain_table == dt)
            )
            recs = recs_result.scalars().all()
            cols = len(recs)
            row_count = next((r.source_row_count for r in recs if r.source_row_count is not None), None)
            actual_source_type = next((r.source_type for r in recs if r.source_type), "db")
            tables.append(SourceTableInfo(
                table_name=dt, column_count=cols, documented=True, source_type=actual_source_type,
                row_count=row_count,
            ))

    return tables


# ── FR-META-001: Proceed (auto-populate selected metadata) ───────────────────

@router.post("/proceed", response_model=ProceedResponse)
async def proceed_metadata(
    body: ProceedMetadataRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:create"))],
) -> ProceedResponse:
    """Auto-populate metadata attributes for the selected tables."""
    project = (await db.execute(
        select(Project).where(Project.id == body.project_id)
    )).scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Get owner info for pre-filling
    owners = (await db.execute(
        select(DataOwnerSteward).where(DataOwnerSteward.project_id == body.project_id)
    )).scalars().all()
    owner_map = {o.role_type: f"{o.full_name} <{o.email}>" for o in owners}

    db.add(AuditLog(user_id=current_user.id, module="metadata", action="proceed",
                    entity_type="metadata", entity_id=str(body.project_id)))

    try:
        result = await populate_metadata_records(
            db,
            project_id=body.project_id,
            source_type=body.source_type,
            gcp_project=body.gcp_project,
            bq_dataset=body.bq_dataset,
            table_names=body.table_names,
            uploaded_tables=body.uploaded_tables,
            temp_file_key=body.temp_file_key,
            temp_file_keys=body.temp_file_keys,
            file_names=body.file_names,
            connection_string=body.connection_string,
            pg_schema=body.pg_schema or "public",
            project_name=project.project_name,
            project_year=getattr(project, "project_year", 2024),
            customer_name=getattr(project, "customer_name", ""),
            line_of_business=getattr(project, "line_of_business", None),
            owner_info=owner_map,
            initiated_by=f"{current_user.full_name} <{current_user.email}>",
        )
        await db.commit()
    except (ValueError, FileNotFoundError) as exc:
        await db.rollback()
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        await db.rollback()
        raise HTTPException(status_code=500, detail=f"Metadata auto-population failed: {exc}") from exc

    processed = int(result.get("processed", 0))
    table_count = len(result.get("tables", []))
    return ProceedResponse(
        task_id="sync",
        message=f"Metadata auto-population completed for {table_count} table{'s' if table_count != 1 else ''}.",
        queued_records=processed,
        processed_records=processed,
    )


# ── FR-META-001: Get attribute grid ──────────────────────────────────────────

@router.get("/{project_id}", response_model=list[MetadataRecordOut])
async def get_metadata(
    project_id: uuid.UUID,
    db: DB,
    _: Annotated[User, Depends(require_permission("metadata:read"))],
    table_filter: str = Query(default=""),
) -> list[MetadataRecord]:
    q = select(MetadataRecord).where(MetadataRecord.project_id == project_id)
    if table_filter:
        q = q.where(MetadataRecord.data_domain_table == table_filter)
    q = q.order_by(MetadataRecord.data_domain_table, MetadataRecord.seq_no)
    result = await db.execute(q)
    return result.scalars().all()


# ── FR-META-019: Single record update ────────────────────────────────────────

@router.put("/{record_id}", response_model=MetadataRecordOut)
async def update_metadata_record(
    record_id: uuid.UUID,
    body: MetadataRecordUpdate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
) -> MetadataRecord:
    record = (await db.execute(
        select(MetadataRecord).where(MetadataRecord.id == record_id)
    )).scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Metadata record not found")

    for k, v in body.model_dump(exclude_none=True).items():
        setattr(record, k, v)

    # FR-META-019: stamp updated_date and updated_by per row
    record.updated_date = date.today()
    record.updated_by = f"{current_user.full_name} <{current_user.email}>"

    await db.commit()
    await db.refresh(record)
    return record


# ── FR-META-021: Batch save ───────────────────────────────────────────────────

@router.post("/save", response_model=MetadataBatchSaveResult)
async def batch_save_metadata(
    body: MetadataBatchSaveRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
) -> MetadataBatchSaveResult:
    saved = 0
    errors: list[dict] = []
    today = date.today()
    updated_by = f"{current_user.full_name} <{current_user.email}>"

    for rec_data in body.records:
        rec_id = rec_data.get("id")
        if not rec_id:
            errors.append({"error": "missing id", "data": str(rec_data)[:100]})
            continue
        try:
            rec_uuid = uuid.UUID(str(rec_id))
            record = (await db.execute(
                select(MetadataRecord).where(MetadataRecord.id == rec_uuid)
            )).scalar_one_or_none()
            if not record:
                errors.append({"id": str(rec_id), "error": "not found"})
                continue

            allowed = {
                "line_of_business", "table_type", "data_steward", "data_owner",
                "data_year", "data_sensitivity", "data_grouping", "business_term",
                "business_definition", "standard_format", "definition_status",
                "data_level", "remarks",
            }
            for k, v in rec_data.items():
                if k != "id" and k in allowed and v is not None:
                    setattr(record, k, v)
            record.updated_date = today
            record.updated_by = updated_by
            saved += 1
        except Exception as exc:
            errors.append({"id": str(rec_id), "error": str(exc)})

    await db.commit()

    db.add(AuditLog(
        user_id=current_user.id, module="metadata", action="batch_save",
        entity_type="metadata", entity_id=str(body.project_id),
        details={"saved": saved, "errors": len(errors)},
    ))
    await db.commit()

    return MetadataBatchSaveResult(saved=saved, errors=errors)


# ── FR-META-012: Bulk Grouping ────────────────────────────────────────────────

@router.post("/bulk-grouping", response_model=dict)
async def bulk_grouping(
    body: BulkGroupingRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
) -> dict:
    result = await db.execute(
        select(MetadataRecord).where(
            MetadataRecord.project_id == body.project_id,
            MetadataRecord.data_domain_table == body.table_filter,
        )
    )
    records = result.scalars().all()
    today = date.today()
    updated_by = f"{current_user.full_name} <{current_user.email}>"

    for r in records:
        r.data_grouping = body.data_grouping
        r.updated_date = today
        r.updated_by = updated_by

    db.add(AuditLog(
        user_id=current_user.id, module="metadata", action="bulk_grouping",
        entity_type="metadata", entity_id=str(body.project_id),
        details={"table": body.table_filter, "grouping": body.data_grouping, "rows": len(records)},
    ))
    await db.commit()
    return {"updated": len(records), "data_grouping": body.data_grouping}


# ── Bulk stamp: mark all records in a project as updated by current user ──────

@router.post("/bulk-stamp/{project_id}", response_model=dict)
async def bulk_stamp(
    project_id: uuid.UUID,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
) -> dict:
    """Stamp updated_date + updated_by on every record in the project."""
    result = await db.execute(
        select(MetadataRecord).where(MetadataRecord.project_id == project_id)
    )
    records = result.scalars().all()
    today = date.today()
    updated_by = f"{current_user.full_name} <{current_user.email}>"

    for r in records:
        r.updated_date = today
        r.updated_by = updated_by

    db.add(AuditLog(
        user_id=current_user.id, module="metadata", action="bulk_stamp",
        entity_type="metadata", entity_id=str(project_id),
        details={"stamped": len(records)},
    ))
    await db.commit()
    return {"stamped": len(records)}


# ── FR-META-014: AI regenerate for single row ─────────────────────────────────

@router.post("/regenerate-definition", response_model=dict)
async def regenerate_definition(
    body: AIRegenerateRequest,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
) -> dict:
    record = (await db.execute(
        select(MetadataRecord).where(MetadataRecord.id == body.record_id)
    )).scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Record not found")

    try:
        config = await get_ai_config(db)
        if not config_is_ready(config):
            raise AIGenerationError("AI generation is not configured. Ask an administrator to set up Ollama Cloud.", 400)
        candidate = build_candidate_from_config(config)
        definition = await generate_metadata_definition(record, candidate)
        apply_generated_definition(record, definition, current_user)
        db.add(AuditLog(
            user_id=current_user.id,
            module="metadata",
            action="regenerate_ai_definition",
            entity_type="metadata_record",
            entity_id=str(record.id),
            details={"provider": candidate.provider, "model_name": candidate.model_name},
        ))
        await db.commit()
        await db.refresh(record)
        return {
            "record_id": str(record.id),
            "status": record.definition_status,
            "definition": record.business_definition,
            "provider": candidate.provider,
            "model_name": candidate.model_name,
            "message": "AI definition generated",
        }
    except AIGenerationError as exc:
        raise HTTPException(status_code=exc.http_status, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Could not generate AI definition") from exc


# ── FR-META-014: Regenerate ALL pending definitions for a project ─────────────

@router.post("/regenerate-all/{project_id}", response_model=dict)
async def regenerate_all_definitions(
    project_id: uuid.UUID,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("metadata:update"))],
    limit: int | None = Query(default=None, ge=1, le=25),
) -> dict:
    """Generate pending definitions in bounded chunks for serverless runtimes."""
    config = await get_ai_config(db)
    if not config_is_ready(config):
        raise HTTPException(
            status_code=400,
            detail="AI generation is not configured. Ask an administrator to set up Ollama Cloud.",
        )
    candidate = build_candidate_from_config(config)
    chunk_size = min(limit or candidate.batch_size, 25)

    result = await db.execute(
        select(MetadataRecord).where(
            MetadataRecord.project_id == project_id,
            (MetadataRecord.business_definition.is_(None)) | (MetadataRecord.definition_status != "ai_generated"),
        ).order_by(MetadataRecord.data_domain_table, MetadataRecord.seq_no).limit(chunk_size)
    )
    records = result.scalars().all()
    if not records:
        return {"processed": 0, "failed": 0, "remaining": 0, "message": "Nothing to generate", "failures": []}

    processed = 0
    failures: list[dict[str, str]] = []
    for record in records:
        try:
            definition = await generate_metadata_definition(record, candidate)
            apply_generated_definition(record, definition, current_user)
            processed += 1
        except AIGenerationError as exc:
            failures.append({"record_id": str(record.id), "error": str(exc)})

    if processed:
        db.add(AuditLog(
            user_id=current_user.id,
            module="metadata",
            action="regenerate_all_ai_definitions",
            entity_type="project",
            entity_id=str(project_id),
            details={
                "processed": processed,
                "failed": len(failures),
                "provider": candidate.provider,
                "model_name": candidate.model_name,
            },
        ))
    await db.commit()

    remaining_result = await db.execute(
        select(func.count(MetadataRecord.id)).where(
            MetadataRecord.project_id == project_id,
            (MetadataRecord.business_definition.is_(None)) | (MetadataRecord.definition_status != "ai_generated"),
        )
    )
    remaining = int(remaining_result.scalar_one())
    return {
        "processed": processed,
        "failed": len(failures),
        "remaining": remaining,
        "message": f"Generated {processed} definitions",
        "failures": failures[:5],
    }
