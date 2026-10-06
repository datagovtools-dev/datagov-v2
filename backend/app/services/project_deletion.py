"""Privileged, explicit deletion of a project asset and its owned records.

The database schema predates this service and most project foreign keys are
``NO ACTION``.  Deletion therefore stays explicit here rather than relying on
implicit ORM/database cascades.  Audit logs are intentionally retained.
"""
from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from typing import Any

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.bapd import BAPDApproval, BAPDRecord
from app.models.dpia import DPIAApproval, DPIARecord
from app.models.dq import DQFinding, DQGCPArchive, DQResult, DQRun
from app.models.dsr import (
    AIChecklistApproval,
    AIComplianceChecklist,
    DSRApproval,
    DataSharingAgreement,
    DataSharingRequest,
)
from app.models.metadata import DataOwnerSteward, MetadataRecord, ProjectSourceFile
from app.models.notification import Notification
from app.models.project import Project
from app.models.ropa import ROPARecord
from app.models.user import AuditLog, UserProjectRole
from app.services.shared_uploads import shared_copy_path

logger = logging.getLogger(__name__)

UPLOADS_ROOT = "/app/uploads"
SHARED_ROOT = "/app/shared_uploads"


@dataclass(frozen=True)
class ProjectDeletionScope:
    project_id: Any
    project_code: str | None
    project_name: str
    source_file_paths: tuple[str, ...]
    dq_run_ids: tuple[Any, ...]
    dq_result_ids: tuple[Any, ...]
    dsr_ids: tuple[Any, ...]
    checklist_ids: tuple[Any, ...]
    dpia_ids: tuple[Any, ...]
    bapd_ids: tuple[Any, ...]
    dsa_ids: tuple[Any, ...]
    notification_entity_ids: tuple[str, ...]
    active_dq_runs: int
    orphan_dsa_ids: tuple[Any, ...]

    @property
    def counts(self) -> dict[str, int]:
        return {
            "metadata_records": self._metadata_count,
            "data_owner_stewards": self._owner_count,
            "project_source_files": len(self.source_file_paths),
            "dq_runs": len(self.dq_run_ids),
            "dq_results": len(self.dq_result_ids),
            "dq_findings": self._finding_count,
            "dq_gcp_archives": self._archive_count,
            "dsr_requests": len(self.dsr_ids),
            "dsr_approvals": self._dsr_approval_count,
            "ai_compliance_checklists": len(self.checklist_ids),
            "ai_checklist_approvals": self._ai_approval_count,
            "dpia_records": len(self.dpia_ids),
            "dpia_approvals": self._dpia_approval_count,
            "ropa_records": self._ropa_count,
            "bapd_records": len(self.bapd_ids),
            "bapd_approvals": self._bapd_approval_count,
            "user_project_roles": self._project_role_count,
            "notifications": self._notification_count,
            "orphan_data_sharing_agreements": len(self.orphan_dsa_ids),
        }

    # These values are filled by collect_scope without making the public
    # response schema depend on private SQLAlchemy result objects.
    _metadata_count: int = 0
    _owner_count: int = 0
    _finding_count: int = 0
    _archive_count: int = 0
    _dsr_approval_count: int = 0
    _ai_approval_count: int = 0
    _dpia_approval_count: int = 0
    _ropa_count: int = 0
    _bapd_approval_count: int = 0
    _project_role_count: int = 0
    _notification_count: int = 0


@dataclass(frozen=True)
class ProjectDeletionResult:
    project_id: Any
    project_code: str | None
    deleted_counts: dict[str, int]
    files_deleted: int
    files_missing: int
    file_cleanup_errors: tuple[str, ...]


def _ids_as_text(*groups: tuple[Any, ...], project_id: Any) -> tuple[str, ...]:
    values = {str(project_id)}
    for group in groups:
        values.update(str(value) for value in group)
    return tuple(sorted(values))


async def _count(db: AsyncSession, model: Any, *criteria: Any) -> int:
    stmt = select(func.count()).select_from(model)
    if criteria:
        stmt = stmt.where(*criteria)
    return int((await db.execute(stmt)).scalar_one())


async def collect_scope(db: AsyncSession, project: Project) -> ProjectDeletionScope:
    """Collect all project-owned IDs before issuing any delete statements."""
    project_id = project.id

    source_rows = (
        await db.execute(
            select(ProjectSourceFile.stored_path).where(ProjectSourceFile.project_id == project_id)
        )
    ).scalars().all()
    dq_run_ids = tuple(
        (await db.execute(select(DQRun.id).where(DQRun.project_id == project_id))).scalars().all()
    )
    dq_result_ids = tuple(
        (await db.execute(select(DQResult.id).where(DQResult.run_id.in_(dq_run_ids)))).scalars().all()
        if dq_run_ids else ()
    )
    dsr_ids = tuple(
        (await db.execute(select(DataSharingRequest.id).where(DataSharingRequest.project_id == project_id))).scalars().all()
    )
    checklist_ids = tuple(
        (await db.execute(select(AIComplianceChecklist.id).where(AIComplianceChecklist.dsr_id.in_(dsr_ids)))).scalars().all()
        if dsr_ids else ()
    )
    dsa_ids = tuple(
        value
        for value in (
            await db.execute(
                select(DataSharingRequest.dsa_id).where(
                    DataSharingRequest.project_id == project_id,
                    DataSharingRequest.dsa_id.is_not(None),
                )
            )
        ).scalars().all()
        if value is not None
    )
    dpia_ids = tuple(
        (await db.execute(select(DPIARecord.id).where(DPIARecord.project_id == project_id))).scalars().all()
    )
    bapd_ids = tuple(
        (await db.execute(select(BAPDRecord.id).where(BAPDRecord.project_id == project_id))).scalars().all()
    )

    orphan_dsa_ids: tuple[Any, ...] = ()
    if dsa_ids:
        still_used = set(
            (
                await db.execute(
                    select(DataSharingRequest.dsa_id).where(
                        DataSharingRequest.dsa_id.in_(dsa_ids),
                        DataSharingRequest.project_id != project_id,
                    )
                )
            ).scalars().all()
        )
        orphan_dsa_ids = tuple(value for value in dsa_ids if value not in still_used)

    notification_entity_ids = _ids_as_text(
        dq_run_ids, dsr_ids, checklist_ids, dpia_ids, bapd_ids, project_id=project_id
    )
    active_dq_runs = await _count(
        db,
        DQRun,
        DQRun.project_id == project_id,
        DQRun.status.in_(("pending", "running")),
    )

    scope = ProjectDeletionScope(
        project_id=project_id,
        project_code=project.project_code,
        project_name=project.project_name,
        source_file_paths=tuple(path for path in source_rows if path),
        dq_run_ids=dq_run_ids,
        dq_result_ids=dq_result_ids,
        dsr_ids=dsr_ids,
        checklist_ids=checklist_ids,
        dpia_ids=dpia_ids,
        bapd_ids=bapd_ids,
        dsa_ids=dsa_ids,
        notification_entity_ids=notification_entity_ids,
        active_dq_runs=active_dq_runs,
        orphan_dsa_ids=orphan_dsa_ids,
        _metadata_count=await _count(db, MetadataRecord, MetadataRecord.project_id == project_id),
        _owner_count=await _count(db, DataOwnerSteward, DataOwnerSteward.project_id == project_id),
        _finding_count=await _count(db, DQFinding, DQFinding.result_id.in_(dq_result_ids)) if dq_result_ids else 0,
        _archive_count=await _count(db, DQGCPArchive, DQGCPArchive.run_id.in_(dq_run_ids)) if dq_run_ids else 0,
        _dsr_approval_count=await _count(db, DSRApproval, DSRApproval.dsr_id.in_(dsr_ids)) if dsr_ids else 0,
        _ai_approval_count=await _count(db, AIChecklistApproval, AIChecklistApproval.checklist_id.in_(checklist_ids)) if checklist_ids else 0,
        _dpia_approval_count=await _count(db, DPIAApproval, DPIAApproval.dpia_id.in_(dpia_ids)) if dpia_ids else 0,
        _ropa_count=await _count(db, ROPARecord, ROPARecord.project_id == project_id),
        _bapd_approval_count=await _count(db, BAPDApproval, BAPDApproval.bapd_id.in_(bapd_ids)) if bapd_ids else 0,
        _project_role_count=await _count(db, UserProjectRole, UserProjectRole.project_id == project_id),
        _notification_count=await _count(db, Notification, Notification.entity_id.in_(notification_entity_ids)),
    )
    return scope


def _safe_upload_file(path: str, uploads_root: str = UPLOADS_ROOT) -> bool:
    """Delete only files inside the configured upload root."""
    real_path = os.path.realpath(path)
    real_root = os.path.realpath(uploads_root)
    return real_path != real_root and real_path.startswith(real_root + os.sep)


def remove_project_files(
    stored_paths: tuple[str, ...],
    uploads_root: str = UPLOADS_ROOT,
    shared_root: str = SHARED_ROOT,
) -> tuple[int, int, tuple[str, ...]]:
    """Remove uploaded files and their committed shared copies.

    Files outside the upload root are never removed; their paths are returned as
    cleanup errors so an operator can handle external storage separately.
    """
    deleted = 0
    missing = 0
    errors: list[str] = []
    for stored_path in stored_paths:
        if not _safe_upload_file(stored_path, uploads_root):
            errors.append(f"unsupported upload path: {stored_path}")
            continue
        try:
            if os.path.isfile(stored_path):
                os.remove(stored_path)
                deleted += 1
                parent = os.path.dirname(stored_path)
                if os.path.isdir(parent) and not os.listdir(parent):
                    os.rmdir(parent)
            else:
                missing += 1
        except OSError as exc:
            errors.append(f"{stored_path}: {exc}")

        try:
            shared = shared_copy_path(stored_path, uploads_root, shared_root)
            if shared and os.path.isfile(shared):
                os.remove(shared)
                parent = os.path.dirname(shared)
                if os.path.isdir(parent) and not os.listdir(parent):
                    os.rmdir(parent)
        except OSError as exc:
            errors.append(f"shared copy {stored_path}: {exc}")
    return deleted, missing, tuple(errors)


async def delete_project_asset(
    db: AsyncSession,
    project: Project,
    actor_id: Any,
    confirmation_code: str,
) -> ProjectDeletionResult:
    """Delete the project and all project-owned records in one DB transaction."""
    if confirmation_code != project.project_code:
        raise ValueError("Confirmation code does not match the asset code")

    scope = await collect_scope(db, project)
    if scope.active_dq_runs:
        raise RuntimeError("Cannot delete an asset while a data-quality run is pending or running")

    project_id = project.id
    # Delete deepest dependants first because the legacy schema mostly uses NO ACTION.
    if scope.checklist_ids:
        await db.execute(delete(AIChecklistApproval).where(AIChecklistApproval.checklist_id.in_(scope.checklist_ids)))
        await db.execute(delete(AIComplianceChecklist).where(AIComplianceChecklist.id.in_(scope.checklist_ids)))
    if scope.dsr_ids:
        await db.execute(delete(DSRApproval).where(DSRApproval.dsr_id.in_(scope.dsr_ids)))
        await db.execute(delete(DataSharingRequest).where(DataSharingRequest.id.in_(scope.dsr_ids)))
    if scope.orphan_dsa_ids:
        await db.execute(delete(DataSharingAgreement).where(DataSharingAgreement.id.in_(scope.orphan_dsa_ids)))

    if scope.dpia_ids:
        await db.execute(delete(DPIAApproval).where(DPIAApproval.dpia_id.in_(scope.dpia_ids)))
        await db.execute(delete(DPIARecord).where(DPIARecord.id.in_(scope.dpia_ids)))

    if scope.bapd_ids:
        await db.execute(delete(BAPDApproval).where(BAPDApproval.bapd_id.in_(scope.bapd_ids)))
        await db.execute(delete(BAPDRecord).where(BAPDRecord.id.in_(scope.bapd_ids)))

    if scope.dq_result_ids:
        await db.execute(delete(DQFinding).where(DQFinding.result_id.in_(scope.dq_result_ids)))
        await db.execute(delete(DQResult).where(DQResult.id.in_(scope.dq_result_ids)))
    if scope.dq_run_ids:
        await db.execute(delete(DQGCPArchive).where(DQGCPArchive.run_id.in_(scope.dq_run_ids)))
        await db.execute(delete(DQRun).where(DQRun.id.in_(scope.dq_run_ids)))

    await db.execute(delete(Notification).where(Notification.entity_id.in_(scope.notification_entity_ids)))
    await db.execute(delete(UserProjectRole).where(UserProjectRole.project_id == project_id))
    await db.execute(delete(MetadataRecord).where(MetadataRecord.project_id == project_id))
    await db.execute(delete(DataOwnerSteward).where(DataOwnerSteward.project_id == project_id))
    await db.execute(delete(ROPARecord).where(ROPARecord.project_id == project_id))
    await db.execute(delete(ProjectSourceFile).where(ProjectSourceFile.project_id == project_id))
    await db.execute(delete(Project).where(Project.id == project_id))

    db.add(
        AuditLog(
            user_id=actor_id,
            module="project",
            action="delete",
            entity_type="project",
            entity_id=str(project_id),
            details={
                "project_code": project.project_code,
                "project_name": project.project_name,
                "deleted_counts": scope.counts,
                "audit_retained": True,
            },
        )
    )
    await db.commit()

    files_deleted, files_missing, file_cleanup_errors = remove_project_files(
        scope.source_file_paths, uploads_root=UPLOADS_ROOT, shared_root=SHARED_ROOT
    )
    if file_cleanup_errors:
        logger.warning("Asset %s database deletion succeeded with file cleanup warnings: %s", project_id, file_cleanup_errors)

    return ProjectDeletionResult(
        project_id=project_id,
        project_code=project.project_code,
        deleted_counts=scope.counts,
        files_deleted=files_deleted,
        files_missing=files_missing,
        file_cleanup_errors=file_cleanup_errors,
    )
