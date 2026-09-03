"""Notification helper service for dispatching both In-App notifications and Email alerts."""
from __future__ import annotations
import uuid
import logging
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.models.user import User
from app.worker.tasks.notifications import send_workflow_notification

logger = logging.getLogger(__name__)


async def create_in_app_notification(
    db: AsyncSession,
    user_id: uuid.UUID,
    module: str,
    event: str,
    title: str,
    body: str | None = None,
    entity_type: str | None = None,
    entity_id: str | None = None,
) -> Notification:
    """Create an in-app notification record in the database for the user's bell drawer."""
    notif = Notification(
        user_id=user_id,
        module=module,
        event=event,
        title=title,
        body=body,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id else None,
        is_read=False,
    )
    db.add(notif)
    return notif


async def notify_approval_requested(
    db: AsyncSession,
    approver: User,
    module: str,
    tracking_id: str,
    entity_id: str | uuid.UUID,
    step: int,
    step_label: str,
    actor_name: str,
    extra_details: str | None = None,
) -> None:
    """Send both in-app bell notification and email for an approval request to the next approver."""
    title = f"{module.upper()} Approval Required: {tracking_id}"
    body = (
        f"{actor_name} submitted {module.upper()} ({tracking_id}) which requires your review "
        f"and sign-off for Step {step} ({step_label})."
    )
    if extra_details:
        body += f" Note: {extra_details}"

    await create_in_app_notification(
        db=db,
        user_id=approver.id,
        module=module,
        event=f"{module}_approval_requested",
        title=title,
        body=body,
        entity_type=module,
        entity_id=str(entity_id),
    )

    try:
        send_workflow_notification.delay(
            event=f"{module}_review_requested",
            entity_id=str(entity_id),
            recipients=[approver.email] if approver.email else [],
            context={
                "tracking_id": tracking_id,
                "actor": actor_name,
                "step": step,
                "step_label": step_label,
            },
        )
    except Exception as exc:
        logger.warning("Failed to queue email notification: %s", exc)


async def notify_approval_completed(
    db: AsyncSession,
    requester_id: uuid.UUID,
    requester_email: str | None,
    module: str,
    tracking_id: str,
    entity_id: str | uuid.UUID,
    status: str,  # "approved" or "rejected"
    actor_name: str,
    comments: str | None = None,
) -> None:
    """Notify the requester when their submission is approved or rejected."""
    action_label = "Approved" if status == "approved" else "Rejected"
    title = f"{module.upper()} {tracking_id} {action_label}"
    body = f"Your {module.upper()} request ({tracking_id}) has been {status} by {actor_name}."
    if comments:
        body += f" Comments: {comments}"

    await create_in_app_notification(
        db=db,
        user_id=requester_id,
        module=module,
        event=f"{module}_{status}",
        title=title,
        body=body,
        entity_type=module,
        entity_id=str(entity_id),
    )

    if requester_email:
        try:
            send_workflow_notification.delay(
                event=f"{module}_{status}",
                entity_id=str(entity_id),
                recipients=[requester_email],
                context={
                    "tracking_id": tracking_id,
                    "actor": actor_name,
                    "comments": comments or "",
                },
            )
        except Exception as exc:
            logger.warning("Failed to queue email notification: %s", exc)
