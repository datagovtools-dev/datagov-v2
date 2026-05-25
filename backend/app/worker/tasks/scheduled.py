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
    Real SQL execution uses a synchronous psycopg2 session wired at deployment.
    """
    import psycopg2
    import os

    db_url = os.getenv("DATABASE_URL", "")
    if not db_url:
        logger.warning("DATABASE_URL not set; retention scan skipped")
        return {"status": "skipped", "reason": "no DATABASE_URL"}

    # Convert asyncpg URL to psycopg2 URL
    sync_url = db_url.replace("postgresql+asyncpg://", "postgresql://")
    today = date.today().isoformat()
    flagged = 0
    try:
        conn = psycopg2.connect(sync_url)
        cur = conn.cursor()
        cur.execute(
            """
            SELECT COUNT(*) FROM bapd_records
            WHERE expiry_date < %s
              AND status NOT IN ('executed', 'archived')
            """,
            (today,),
        )
        flagged = cur.fetchone()[0]
        cur.close()
        conn.close()
    except Exception as exc:  # noqa: BLE001
        logger.error("Retention scan DB error: %s", exc)
        return {"status": "error", "error": str(exc)}

    logger.info("Retention eligibility scan: %d overdue records found", flagged)
    return {"status": "completed", "overdue_records": flagged, "scanned_at": datetime.utcnow().isoformat()}


@shared_task(name="app.worker.tasks.scheduled.dsr_expiry_check")
def dsr_expiry_check() -> dict:
    """Daily 08:00 WIB: warn on DSRs expiring in 7 days; auto-revoke expired."""
    import psycopg2
    import os

    db_url = os.getenv("DATABASE_URL", "")
    if not db_url:
        logger.warning("DATABASE_URL not set; DSR expiry check skipped")
        return {"status": "skipped", "reason": "no DATABASE_URL"}

    sync_url = db_url.replace("postgresql+asyncpg://", "postgresql://")
    today = date.today()
    warn_threshold = (today + timedelta(days=7)).isoformat()
    today_str = today.isoformat()
    warned = revoked = 0

    try:
        conn = psycopg2.connect(sync_url)
        cur = conn.cursor()

        # DSRs expiring within 7 days (still active)
        cur.execute(
            """
            SELECT id, tracking_id FROM data_sharing_requests
            WHERE duration_end <= %s AND duration_end > %s
              AND status NOT IN ('rejected', 'archived', 'executed')
            """,
            (warn_threshold, today_str),
        )
        expiring_soon = cur.fetchall()
        warned = len(expiring_soon)

        # Auto-revoke past due date
        cur.execute(
            """
            UPDATE data_sharing_requests
            SET status = 'archived'
            WHERE duration_end < %s
              AND status = 'approved'
            RETURNING id
            """,
            (today_str,),
        )
        revoked = cur.rowcount
        conn.commit()
        cur.close()
        conn.close()
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
    """Daily 07:00 WIB: warn project teams 7 days before source file deletion;
    delete files + records when 30 days past project end_date."""
    import os
    import psycopg2
    import psycopg2.extras

    db_url = os.getenv("DATABASE_URL", "")
    if not db_url:
        logger.warning("DATABASE_URL not set; source file expiry check skipped")
        return {"status": "skipped", "reason": "no DATABASE_URL"}

    sync_url = db_url.replace("postgresql+asyncpg://", "postgresql://")
    today = date.today()
    warn_date = today + timedelta(days=7)   # alert when expiry is 7 days away
    warned = deleted_projects = deleted_files = 0

    try:
        conn = psycopg2.connect(sync_url)
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

        # Projects that have uploaded source files and have an end_date set
        cur.execute("""
            SELECT DISTINCT p.id, p.project_name, p.end_date,
                   p.sme_id, p.delivery_manager_id, p.project_manager_id,
                   p.dgo_id, p.metadata_officer_id, p.dq_officer_id,
                   p.pic_data_compliance_id, p.created_by
            FROM projects p
            INNER JOIN project_source_files psf ON psf.project_id = p.id
            WHERE p.end_date IS NOT NULL
        """)
        projects = cur.fetchall()

        # Fetch all super-admin user IDs + emails
        cur.execute("""
            SELECT DISTINCT u.id, u.email
            FROM users u
            JOIN project_roles pr ON pr.user_id = u.id
            JOIN roles r ON r.id = pr.role_id
            WHERE r.name = 'super_admin'
              AND pr.revoked_at IS NULL
              AND u.is_active = TRUE
        """)
        super_admins = cur.fetchall()

        for proj in projects:
            end_date = proj["end_date"]
            if isinstance(end_date, str):
                from datetime import datetime as _dt
                end_date = _dt.strptime(end_date, "%Y-%m-%d").date()

            expiry_date = end_date + timedelta(days=30)
            project_id = str(proj["id"])
            project_name = proj["project_name"]

            # Collect team member IDs (non-null project fields)
            team_ids = {
                str(proj[col])
                for col in ("sme_id", "delivery_manager_id", "project_manager_id",
                            "dgo_id", "metadata_officer_id", "dq_officer_id",
                            "pic_data_compliance_id", "created_by")
                if proj[col]
            }
            team_ids.update(str(sa["id"]) for sa in super_admins)

            if not team_ids:
                continue

            # Fetch emails for all recipients
            id_list = list(team_ids)
            cur.execute(
                "SELECT id, email FROM users WHERE id = ANY(%s::uuid[]) AND is_active = TRUE",
                (id_list,),
            )
            recipients = cur.fetchall()
            recipient_emails = [r["email"] for r in recipients if r["email"]]
            recipient_ids   = [str(r["id"]) for r in recipients]

            # ── 7-day warning ────────────────────────────────────────
            if expiry_date == warn_date:
                warned += 1
                # In-app notifications
                for uid in recipient_ids:
                    cur.execute(
                        """INSERT INTO notifications
                           (id, user_id, module, event, title, body, entity_type, entity_id, is_read)
                           VALUES (gen_random_uuid(), %s::uuid, 'metadata',
                                   'source_files_expiry_warning',
                                   %s, %s, 'project', %s, FALSE)""",
                        (
                            uid,
                            f"Source files expiring in 7 days — {project_name}",
                            (
                                f"Uploaded source files for project \"{project_name}\" will be "
                                f"permanently deleted on {expiry_date.strftime('%d %b %Y')}. "
                                "Download them before the deadline if needed."
                            ),
                            project_id,
                        ),
                    )
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
                            "actor": "system",
                        },
                    )
                except Exception:
                    pass

            # ── Deletion ─────────────────────────────────────────────
            elif expiry_date <= today:
                # Fetch file paths before deleting records
                cur.execute(
                    "SELECT id, stored_path FROM project_source_files WHERE project_id = %s",
                    (project_id,),
                )
                files = cur.fetchall()

                # Delete physical files
                for f in files:
                    try:
                        if f["stored_path"] and os.path.exists(f["stored_path"]):
                            os.remove(f["stored_path"])
                            deleted_files += 1
                    except OSError as exc:
                        logger.warning("Could not delete %s: %s", f["stored_path"], exc)

                # Remove DB records
                cur.execute(
                    "DELETE FROM project_source_files WHERE project_id = %s",
                    (project_id,),
                )
                deleted_projects += 1

                # In-app notifications
                for uid in recipient_ids:
                    cur.execute(
                        """INSERT INTO notifications
                           (id, user_id, module, event, title, body, entity_type, entity_id, is_read)
                           VALUES (gen_random_uuid(), %s::uuid, 'metadata',
                                   'source_files_deleted',
                                   %s, %s, 'project', %s, FALSE)""",
                        (
                            uid,
                            f"Source files deleted — {project_name}",
                            (
                                f"Uploaded source files for project \"{project_name}\" have been "
                                "automatically deleted (30-day post-project retention elapsed). "
                                "Metadata attributes and definitions remain intact."
                            ),
                            project_id,
                        ),
                    )
                # Email notifications (best-effort)
                try:
                    from app.worker.tasks.notifications import send_workflow_notification
                    send_workflow_notification.delay(
                        event="source_files_deleted",
                        entity_id=project_id,
                        recipients=recipient_emails,
                        context={"project_name": project_name, "actor": "system"},
                    )
                except Exception:
                    pass

        conn.commit()
        cur.close()
        conn.close()
    except Exception as exc:
        logger.error("Source file expiry check error: %s", exc)
        return {"status": "error", "error": str(exc)}

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
