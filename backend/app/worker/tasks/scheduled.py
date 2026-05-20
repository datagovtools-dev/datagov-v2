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


@shared_task(name="app.worker.tasks.scheduled.gcp_sa_key_purge")
def gcp_sa_key_purge() -> dict:
    """Every 30 min: purge in-memory GCP SA keys older than 30 min."""
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=30)
    purged = [k for k, v in list(_GCP_SA_KEYS.items()) if v["stored_at"] < cutoff]
    for k in purged:
        del _GCP_SA_KEYS[k]
    logger.info("Purged %d GCP SA keys", len(purged))
    return {"purged": len(purged)}
