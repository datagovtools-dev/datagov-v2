"""
Celery task: send_workflow_notification
Handles email + in-app alerts for all governance workflow transitions.
Retry: 3 attempts — 30 s / 5 min / 30 min backoff.
"""
from __future__ import annotations

import logging
from typing import Any

from celery import shared_task

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

# Email HTML template (minimal inline-CSS)
_EMAIL_TEMPLATE = """\
<!DOCTYPE html>
<html>
<body style="font-family:Arial,sans-serif;color:#2C3E50;max-width:600px;margin:0 auto">
  <div style="background:#1B2A4A;padding:20px 32px;border-radius:8px 8px 0 0">
    <h2 style="color:white;margin:0">AI Governance Tools</h2>
  </div>
  <div style="padding:24px 32px;border:1px solid #E2E8F0;border-top:none;border-radius:0 0 8px 8px">
    <h3 style="color:#1F5BAE">{subject}</h3>
    <p>{body}</p>
    <p style="margin-top:24px">
      <a href="{action_url}" style="background:#1F5BAE;color:white;padding:10px 20px;border-radius:6px;text-decoration:none">
        {action_label}
      </a>
    </p>
    <hr style="margin-top:32px;border-color:#E2E8F0">
    <p style="font-size:12px;color:#718096">This is an automated notification from the AI Governance Platform.</p>
  </div>
</body>
</html>
"""

EVENT_TEMPLATES: dict[str, dict[str, str]] = {
    "dsr_submitted": {
        "subject": "New Data Sharing Request Submitted — {tracking_id}",
        "body": "A new data sharing request <strong>{tracking_id}</strong> has been submitted by {actor} and is awaiting your review.",
        "action_label": "Review Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_approved": {
        "subject": "Data Sharing Request Approved — {tracking_id}",
        "body": "Your data sharing request <strong>{tracking_id}</strong> has been approved by {actor}.",
        "action_label": "View Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_rejected": {
        "subject": "Data Sharing Request Rejected — {tracking_id}",
        "body": "Your data sharing request <strong>{tracking_id}</strong> has been rejected. Please review the comments.",
        "action_label": "View Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_review_requested": {
        "subject": "Action Required: DSR Approval Request — {tracking_id}",
        "body": (
            "You have been assigned as an approver for data sharing request "
            "<strong>{tracking_id}</strong> (Step {step}: {step_label}).<br><br>"
            "Please review the request and take action at your earliest convenience."
        ),
        "action_label": "Review & Approve",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_sign_off_requested": {
        "subject": "Action Required: Document Sign-Off — {tracking_id}",
        "body": (
            "Your signature is required for data sharing request "
            "<strong>{tracking_id}</strong> (Step {step}: {step_label}).<br><br>"
            "Please open the document, complete your sign-off in the Checklist section."
        ),
        "action_label": "Sign Document",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_step_approved": {
        "subject": "DSR Step Approved — {tracking_id}",
        "body": (
            "Step {step} ({step_label}) for data sharing request "
            "<strong>{tracking_id}</strong> has been approved by {actor}.<br><br>"
            "The request is now awaiting your action for the next step."
        ),
        "action_label": "View Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_step_rejected": {
        "subject": "DSR Rejected — {tracking_id}",
        "body": (
            "Data sharing request <strong>{tracking_id}</strong> has been rejected "
            "at Step {step} ({step_label}) by {actor}.<br><br>"
            "Please review the comments and revise the request if necessary."
        ),
        "action_label": "View Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dsr_expiring": {
        "subject": "Data Sharing Request Expiring Soon — {tracking_id}",
        "body": "The data sharing request <strong>{tracking_id}</strong> will expire in 7 days. Please take action if renewal is needed.",
        "action_label": "View Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dpia_submitted": {
        "subject": "DPIA Submitted for Review — {entity_id}",
        "body": "A DPIA record has been submitted for DPO review by {actor}.",
        "action_label": "Review DPIA",
        "action_path": "/dpia/{entity_id}",
    },
    "dpia_approved": {
        "subject": "DPIA Approved",
        "body": "The DPIA record has been approved and locked by {actor}.",
        "action_label": "View DPIA",
        "action_path": "/dpia/{entity_id}",
    },
    "ropa_submitted": {
        "subject": "ROPA Record Submitted for Review",
        "body": "A ROPA record has been submitted for review by {actor}.",
        "action_label": "Review ROPA",
        "action_path": "/ropa/{entity_id}",
    },
    "bapd_submitted": {
        "subject": "Data Extermination Request Submitted",
        "body": "A BAPD record has been submitted for dual approval by {actor}.",
        "action_label": "Review Request",
        "action_path": "/bapd/{entity_id}",
    },
    "bapd_approved": {
        "subject": "Data Extermination Approved — Action Required",
        "body": "A BAPD record has received all required approvals. Deletion can now be executed by {actor}.",
        "action_label": "Execute Deletion",
        "action_path": "/bapd/{entity_id}",
    },
    "bapd_rejected": {
        "subject": "Data Extermination Request Rejected",
        "body": "The data extermination request has been rejected. Please review the comments.",
        "action_label": "View Request",
        "action_path": "/bapd/{entity_id}",
    },
    "bapd_executed": {
        "subject": "Data Extermination Completed — Proof of Deletion Generated",
        "body": "The data extermination has been executed by {actor}. A Proof of Deletion PDF has been stored.",
        "action_label": "Download POD",
        "action_path": "/bapd/{entity_id}",
    },
    "dsr_expiring_soon": {
        "subject": "Data Sharing Request Expiring in 7 Days — {tracking_id}",
        "body": "The data sharing request <strong>{tracking_id}</strong> is expiring in 7 days. Please renew or close the request.",
        "action_label": "View Request",
        "action_path": "/dsr/{entity_id}",
    },
    "dq_run_completed": {
        "subject": "DQ Run Completed — Score: {overall_score}%",
        "body": "Your data quality run has completed with an overall score of <strong>{overall_score}%</strong>. Please review the results.",
        "action_label": "View Results",
        "action_path": "/dq/{entity_id}",
    },
    "dq_review_requested": {
        "subject": "DQ Run Ready for Governance Review",
        "body": "A data quality run is awaiting governance review by {actor}.",
        "action_label": "Review Now",
        "action_path": "/dq/{entity_id}",
    },
    "dq_approved": {
        "subject": "DQ Run Approved and Archived",
        "body": "The data quality run has been approved by {actor} and archived to GCP.",
        "action_label": "View Archive",
        "action_path": "/dq/{entity_id}",
    },
    "dq_rejected": {
        "subject": "DQ Run Requires Revision",
        "body": "The data quality run has been rejected or requires revision by {actor}. Please re-run after addressing the issues.",
        "action_label": "View Run",
        "action_path": "/dq/{entity_id}",
    },
    "source_files_expiry_warning": {
        "subject": "Uploaded Source Files Expiring in 7 Days — {project_name}",
        "body": (
            "The uploaded source files for project <strong>{project_name}</strong> "
            "will be permanently deleted on <strong>{expiry_date}</strong> "
            "(30 days after the project end date).<br><br>"
            "If you need to retain these files, please download or re-upload them before the deletion date."
        ),
        "action_label": "View Project",
        "action_path": "/projects/{entity_id}",
    },
    "source_files_deleted": {
        "subject": "Uploaded Source Files Deleted — {project_name}",
        "body": (
            "The uploaded source files for project <strong>{project_name}</strong> "
            "have been automatically deleted as the 30-day retention period after the project end date has elapsed.<br><br>"
            "The metadata attributes and definitions remain intact in the system."
        ),
        "action_label": "View Project",
        "action_path": "/projects/{entity_id}",
    },
}


@shared_task(
    bind=True,
    name="app.worker.tasks.notifications.send_workflow_notification",
    max_retries=3,
    default_retry_delay=30,
)
def send_workflow_notification(
    self,
    event: str,
    entity_id: str,
    recipients: list[str],
    context: dict[str, Any],
) -> dict[str, Any]:
    """
    Send email notifications for a workflow event.
    recipients: list of email addresses.
    context: dict with keys like tracking_id, actor, etc.
    """
    template = EVENT_TEMPLATES.get(event)
    if not template:
        logger.warning("Unknown notification event: %s", event)
        return {"sent": 0, "event": event}

    base_url = settings.frontend_url if hasattr(settings, "frontend_url") else "https://app.example.com"
    action_url = base_url + template["action_path"].format(entity_id=entity_id)
    subject = template["subject"].format(**context)
    body = template["body"].format(**context)
    html = _EMAIL_TEMPLATE.format(
        subject=subject,
        body=body,
        action_url=action_url,
        action_label=template["action_label"],
    )

    sent = 0
    for email in recipients:
        try:
            _send_email(to=email, subject=subject, html=html)
            sent += 1
        except Exception as exc:
            logger.error("Failed to send email to %s: %s", email, exc)
            try:
                raise self.retry(exc=exc, countdown=30 * (2 ** self.request.retries))
            except self.MaxRetriesExceededError:
                logger.error("Max retries exceeded for %s event %s", email, event)

    return {"sent": sent, "event": event, "entity_id": entity_id}


def _send_email(to: str, subject: str, html: str) -> None:
    """Dispatch via SendGrid or SMTP depending on config."""
    provider = getattr(settings, "email_provider", "smtp")
    if provider == "sendgrid":
        _send_via_sendgrid(to, subject, html)
    else:
        _send_via_smtp(to, subject, html)


def _send_via_sendgrid(to: str, subject: str, html: str) -> None:
    import sendgrid
    from sendgrid.helpers.mail import Mail
    sg = sendgrid.SendGridAPIClient(api_key=settings.sendgrid_api_key)
    message = Mail(
        from_email=settings.email_from,
        to_emails=to,
        subject=subject,
        html_content=html,
    )
    response = sg.send(message)
    if response.status_code >= 400:
        raise RuntimeError(f"SendGrid error {response.status_code}")


def _send_via_smtp(to: str, subject: str, html: str) -> None:
    import smtplib
    from email.mime.multipart import MIMEMultipart
    from email.mime.text import MIMEText
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = getattr(settings, "email_from", "noreply@example.com")
    msg["To"] = to
    msg.attach(MIMEText(html, "html"))
    with smtplib.SMTP(
        host=getattr(settings, "smtp_host", "localhost"),
        port=int(getattr(settings, "smtp_port", 587)),
    ) as server:
        if getattr(settings, "smtp_tls", True):
            server.starttls()
        user = getattr(settings, "smtp_user", None)
        if user:
            server.login(user, getattr(settings, "smtp_password", ""))
        server.sendmail(msg["From"], [to], msg.as_string())
