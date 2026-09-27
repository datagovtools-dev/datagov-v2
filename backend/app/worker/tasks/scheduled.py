"""Celery Beat scheduled maintenance tasks."""
from __future__ import annotations

import logging
import os
import glob
from datetime import date, timedelta, timezone, datetime

from celery import shared_task

logger = logging.getLogger(__name__)

# In-memory GCP SA key store (keyed by session_id)
_GCP_SA_KEYS: dict[str, dict] = {}


def store_gcp_sa_key(session_id: str, key_data: dict) -> None:
    _GCP_SA_KEYS[session_id] = {"data": key_data, "stored_at": datetime.now(timezone.utc)}


def get_gcp_sa_key(session_id: str) -> dict | None:
    return _GCP_SA_KEYS.get(session_id, {}).get("data")


@shared_task(name="app.worker.tasks.scheduled.retention_eligibility_scan")
def retention_eligibility_scan() -> dict:
    """Daily 02:00 WIB: scan BAPDRecords against retention policies.

    Marks records with expiry_date < today that are still in draft/submitted
    status so BAPD Officers see them on the eligible-datasets panel.
    """
    from sqlalchemy import func, select

    from app.database import get_sync_session
    from app.models.bapd import BAPDRecord

    flagged = 0
    try:
        with get_sync_session() as db:
            flagged = db.scalar(
                select(func.count()).select_from(BAPDRecord).where(
                    BAPDRecord.expiry_date < date.today(),
                    BAPDRecord.status.not_in(("executed", "archived")),
                )
            )
    except Exception as exc:  # noqa: BLE001
        logger.error("Retention scan DB error: %s", exc)
        return {"status": "error", "error": str(exc)}

    logger.info("Retention eligibility scan: %d overdue records found", flagged)
    return {"status": "completed", "overdue_records": flagged, "scanned_at": datetime.utcnow().isoformat()}


@shared_task(name="app.worker.tasks.scheduled.dsr_expiry_check")
def dsr_expiry_check() -> dict:
    """Daily 08:00 WIB: warn on DSRs expiring in 7 days; auto-revoke expired."""
    from sqlalchemy import select, update

    from app.database import get_sync_session
    from app.models.dsr import DataSharingRequest

    today = date.today()
    warn_threshold = today + timedelta(days=7)
    warned = revoked = 0

    try:
        with get_sync_session() as db:
            # DSRs expiring within 7 days (still active)
            expiring_soon = db.execute(
                select(DataSharingRequest.id, DataSharingRequest.tracking_id).where(
                    DataSharingRequest.duration_end <= warn_threshold,
                    DataSharingRequest.duration_end > today,
                    DataSharingRequest.status.not_in(("rejected", "archived", "executed")),
                )
            ).all()
            warned = len(expiring_soon)

            # Auto-revoke past due date
            result = db.execute(
                update(DataSharingRequest)
                .where(DataSharingRequest.duration_end < today, DataSharingRequest.status == "approved")
                .values(status="archived")
            )
            revoked = result.rowcount
            db.commit()
    except Exception as exc:  # noqa: BLE001
        logger.error("DSR expiry check DB error: %s", exc)
        return {"status": "error", "error": str(exc)}

    # Fire warning notifications (non-blocking — best effort)
    try:
        from app.worker.tasks.notifications import send_workflow_notification
        for dsr_id, tracking_id in expiring_soon:
            send_workflow_notification.delay(
                event="dsr_expiring_soon",
                entity_id=str(dsr_id),
                recipients=[],
                context={"tracking_id": tracking_id, "actor": "system"},
            )
    except Exception:  # noqa: BLE001
        pass

    logger.info("DSR expiry check: %d warned, %d auto-archived", warned, revoked)
    return {"status": "completed", "warned": warned, "auto_archived": revoked,
            "checked_at": datetime.utcnow().isoformat()}


@shared_task(name="app.worker.tasks.scheduled.cleanup_temp_files")
def cleanup_temp_files() -> dict:
    """Daily 03:00 WIB: delete temp export files older than 24 h."""
    import tempfile
    tmp_dir = tempfile.gettempdir()
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    deleted = 0
    for pattern in ("export_*.csv", "export_*.xlsx", "export_*.pdf"):
        for path in glob.glob(os.path.join(tmp_dir, pattern)):
            try:
                mtime = datetime.fromtimestamp(os.path.getmtime(path), tz=timezone.utc)
                if mtime < cutoff:
                    os.remove(path)
                    deleted += 1
            except OSError:
                pass
    logger.info("Deleted %d temp files", deleted)
    return {"deleted": deleted}


@shared_task(name="app.worker.tasks.scheduled.source_file_expiry_check")
def source_file_expiry_check() -> dict:
    """Daily 07:00 WIB: warn project teams 7 days before source file deletion; delete files +
    records at project end_date + 30 days, or end_date + the approved ROPA retention period
    (see app/services/retention.py)."""
    import os

    from sqlalchemy import delete, select

    from app.database import get_sync_session
    from app.models.metadata import ProjectSourceFile
    from app.models.notification import Notification
    from app.models.project import Project
    from app.models.user import Role, User, UserProjectRole
    from app.services.retention import project_retention_sync
    from app.services.shared_uploads import remove_shared_copy

    today = date.today()
    warn_date = today + timedelta(days=7)   # alert when expiry is 7 days away
    warned = deleted_projects = deleted_files = 0
    team_cols = ("sme_id", "delivery_manager_id", "project_manager_id",
                 "dgo_id", "metadata_officer_id", "dq_officer_id",
                 "pic_data_compliance_id", "created_by")

    db = get_sync_session()
    try:
        # Projects that have uploaded source files and have an end_date set
        projects = db.scalars(
            select(Project).distinct()
            .join(ProjectSourceFile, ProjectSourceFile.project_id == Project.id)
            .where(Project.end_date.is_not(None))
        ).all()

        # All active super-admin user IDs
        super_admin_ids = set(db.scalars(
            select(User.id).distinct()
            .join(UserProjectRole, UserProjectRole.user_id == User.id)
            .join(Role, Role.id == UserProjectRole.role_id)
            .where(Role.name == "super_admin", UserProjectRole.revoked_at.is_(None), User.is_active.is_(True))
        ).all())

        for proj in projects:
            # end_date + 30 days, or end_date + the retention period of an approved ROPA
            retention = project_retention_sync(db, proj)
            expiry_date = retention.expiry_date
            if expiry_date is None:
                continue
            basis_text = (f"project end date + approved ROPA retention period \"{retention.ropa_retention_period}\""
                          if retention.basis == "ropa" else "project end date + 30 days, no approved ROPA")
            project_id = str(proj.id)
            project_name = proj.project_name

            # Collect team member IDs (non-null project fields)
            team_ids = {getattr(proj, col) for col in team_cols if getattr(proj, col)}
            team_ids.update(super_admin_ids)

            if not team_ids:
                continue

            # Fetch emails for all recipients
            recipients = db.execute(
                select(User.id, User.email).where(User.id.in_(team_ids), User.is_active.is_(True))
            ).all()
            recipient_emails = [r.email for r in recipients if r.email]
            recipient_ids = [r.id for r in recipients]

            # ── 7-day warning ────────────────────────────────────────
            if expiry_date == warn_date:
                warned += 1
                # In-app notifications
                for uid in recipient_ids:
                    db.add(Notification(
                        user_id=uid, module="metadata", event="source_files_expiry_warning",
                        title=f"Source files expiring in 7 days — {project_name}",
                        body=(
                            f"Uploaded source files for project \"{project_name}\" will be "
                            f"permanently deleted on {expiry_date.strftime('%d %b %Y')} ({basis_text}). "
                            "Download them before the deadline if needed."
                        ),
                        entity_type="project", entity_id=project_id, is_read=False,
                    ))
                # Email notifications (best-effort)
                try:
                    from app.worker.tasks.notifications import send_workflow_notification
                    send_workflow_notification.delay(
                        event="source_files_expiry_warning",
                        entity_id=project_id,
                        recipients=recipient_emails,
                        context={
                            "project_name": project_name,
                            "expiry_date": expiry_date.strftime("%d %b %Y"),
                            "retention_basis": basis_text,
                            "actor": "system",
                        },
                    )
                except Exception:
                    pass

            # ── Deletion ─────────────────────────────────────────────
            elif expiry_date <= today:
                # Fetch file paths before deleting records
                stored_paths = db.scalars(
                    select(ProjectSourceFile.stored_path).where(ProjectSourceFile.project_id == proj.id)
                ).all()

                # Delete physical files (and their repository copy in shared_uploads, if any)
                for stored_path in stored_paths:
                    try:
                        if stored_path and os.path.exists(stored_path):
                            os.remove(stored_path)
                            deleted_files += 1
                    except OSError as exc:
                        logger.warning("Could not delete %s: %s", stored_path, exc)
                    remove_shared_copy(stored_path)

                # Remove DB records
                db.execute(delete(ProjectSourceFile).where(ProjectSourceFile.project_id == proj.id))
                deleted_projects += 1

                # In-app notifications
                for uid in recipient_ids:
                    db.add(Notification(
                        user_id=uid, module="metadata", event="source_files_deleted",
                        title=f"Source files deleted — {project_name}",
                        body=(
                            f"Uploaded source files for project \"{project_name}\" have been "
                            f"automatically deleted (retention elapsed: {basis_text}). "
                            "Metadata attributes and definitions remain intact."
                        ),
                        entity_type="project", entity_id=project_id, is_read=False,
                    ))
                # Email notifications (best-effort)
                try:
                    from app.worker.tasks.notifications import send_workflow_notification
                    send_workflow_notification.delay(
                        event="source_files_deleted",
                        entity_id=project_id,
                        recipients=recipient_emails,
                        context={"project_name": project_name, "retention_basis": basis_text, "actor": "system"},
                    )
                except Exception:
                    pass

        db.commit()
    except Exception as exc:
        db.rollback()
        logger.error("Source file expiry check error: %s", exc)
        return {"status": "error", "error": str(exc)}
    finally:
        db.close()

    logger.info(
        "Source file expiry check: %d projects warned, %d projects deleted (%d files)",
        warned, deleted_projects, deleted_files,
    )
    return {
        "status": "completed",
        "warned": warned,
        "deleted_projects": deleted_projects,
        "deleted_files": deleted_files,
        "checked_at": datetime.utcnow().isoformat(),
    }


@shared_task(name="app.worker.tasks.scheduled.gcp_sa_key_purge")
def gcp_sa_key_purge() -> dict:
    """Every 30 min: purge in-memory GCP SA keys older than 30 min."""
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=30)
    purged = [k for k, v in list(_GCP_SA_KEYS.items()) if v["stored_at"] < cutoff]
    for k in purged:
        del _GCP_SA_KEYS[k]
    logger.info("Purged %d GCP SA keys", len(purged))
    return {"purged": len(purged)}
