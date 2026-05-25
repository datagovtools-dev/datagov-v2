from celery import Celery
from celery.schedules import crontab
from app.config import get_settings

settings = get_settings()

celery = Celery(
    "ai_governance",
    broker=settings.celery_broker_url,
    backend=settings.celery_broker_url.replace("redis://", "redis://").replace("/0", "/1"),
    include=[
        "app.worker.tasks.notifications",
        "app.worker.tasks.exports",
        "app.worker.tasks.scheduled",
        "app.worker.tasks.metadata",
        "app.worker.tasks.dq",
    ],
)

celery.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Jakarta",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

celery.conf.beat_schedule = {
    "retention-eligibility-scan": {
        "task": "app.worker.tasks.scheduled.retention_eligibility_scan",
        "schedule": crontab(hour=2, minute=0),
    },
    "dsr-expiry-check": {
        "task": "app.worker.tasks.scheduled.dsr_expiry_check",
        "schedule": crontab(hour=8, minute=0),
    },
    "cleanup-temp-files": {
        "task": "app.worker.tasks.scheduled.cleanup_temp_files",
        "schedule": crontab(hour=3, minute=0),
    },
    "gcp-sa-key-purge": {
        "task": "app.worker.tasks.scheduled.gcp_sa_key_purge",
        "schedule": crontab(minute="*/30"),
    },
    "source-file-expiry-check": {
        "task": "app.worker.tasks.scheduled.source_file_expiry_check",
        "schedule": crontab(hour=7, minute=0),
    },
}
