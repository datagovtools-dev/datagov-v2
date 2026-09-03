from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, select, case
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, get_db
from app.models.bapd import BAPDRecord
from app.models.dpia import DPIARecord
from app.models.dq import DQRun
from app.models.dsr import DataSharingRequest
from app.models.project import Project
from app.models.ropa import ROPARecord
from app.models.user import AuditLog, User
from app.schemas.dashboard import (
    ActionItem, DashboardResponse, KPIStats,
    ModuleStatusBreakdown, RecentActivity,
)

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("", response_model=DashboardResponse)
async def get_dashboard(db: DB, current_user: CurrentUser) -> DashboardResponse:
    today = date.today()
    month_start = today.replace(day=1)

    active_projects = (await db.execute(select(func.count()).select_from(Project))).scalar_one()

    open_dsrs = (await db.execute(
        select(func.count()).where(DataSharingRequest.status.in_(["draft", "submitted", "under_review"]))
    )).scalar_one()

    pending_dpias = (await db.execute(
        select(func.count()).where(DPIARecord.status.in_(["draft", "under_review"]))
    )).scalar_one()

    bapd_due_soon = (await db.execute(
        select(func.count()).where(
            BAPDRecord.expiry_date <= today + timedelta(days=30),
            BAPDRecord.status.notin_(["executed", "archived"]),
        )
    )).scalar_one()

    dq_runs_month = (await db.execute(
        select(func.count()).where(DQRun.created_at >= month_start)
    )).scalar_one()

    kpi = KPIStats(
        active_projects=active_projects,
        open_dsrs=open_dsrs,
        pending_dpias=pending_dpias,
        bapd_due_soon=bapd_due_soon,
        dq_runs_this_month=dq_runs_month,
    )

    # Recent activity — last 20 audit log entries
    logs = (await db.execute(
        select(AuditLog, User.full_name)
        .join(User, AuditLog.user_id == User.id, isouter=True)
        .order_by(AuditLog.created_at.desc())
        .limit(20)
    )).all()

    activity = [
        RecentActivity(
            module=log.AuditLog.module,
            action=log.AuditLog.action,
            entity_type=log.AuditLog.entity_type or "",
            entity_id=log.AuditLog.entity_id or "",
            actor=log.full_name or "System",
            timestamp=log.AuditLog.created_at.isoformat(),
        )
        for log in logs
    ]

    # My Action Items — pending approvals for current user
    action_items: list[ActionItem] = []

    _DSR_STEP_NAMES = {1: "PIC Compliance Review", 2: "DM Approval", 3: "SME Sign-Off", 4: "Client Sign-Off"}
    _DPIA_STEP_NAMES = {1: "PIC Compliance Review", 2: "DM/PM Approval"}
    _BAPD_STEP_NAMES = {1: "Data Owner Sign-Off", 2: "DGO Compliance Review"}

    # DSRs submitted/under_review
    dsrs_res = await db.execute(
        select(DataSharingRequest)
        .options(selectinload(DataSharingRequest.approvals))
        .where(DataSharingRequest.status.in_(["submitted", "under_review"]))
        .order_by(DataSharingRequest.created_at.asc())
        .limit(20)
    )
    for dsr in dsrs_res.scalars().all():
        active_step = next((a for a in sorted(dsr.approvals, key=lambda x: x.step_order) if a.status == "requested"), None)
        step_label = _DSR_STEP_NAMES.get(active_step.step_order, f"Step {active_step.step_order}") if active_step else "Review"
        expires_in = (dsr.duration_end - today).days if getattr(dsr, "duration_end", None) else None
        urgency = "high" if (expires_in is not None and expires_in <= 7) or dsr.status == "submitted" else "medium"
        action_items.append(ActionItem(
            module="dsr",
            entity_id=str(dsr.id),
            title=f"DSR {dsr.tracking_id} — {step_label} Required",
            status=dsr.status,
            urgency=urgency,
            due_label=f"Expires in {expires_in}d" if expires_in is not None else None,
        ))

    # DPIAs under review
    dpias_res = await db.execute(
        select(DPIARecord)
        .options(selectinload(DPIARecord.approvals))
        .where(DPIARecord.status.in_(["submitted", "under_review"]))
        .order_by(DPIARecord.created_at.asc())
        .limit(10)
    )
    for dpia in dpias_res.scalars().all():
        active_step = next((a for a in sorted(dpia.approvals, key=lambda x: x.step_order) if a.status == "requested"), None)
        step_label = _DPIA_STEP_NAMES.get(active_step.step_order, f"Step {active_step.step_order}") if active_step else "Under Review"
        action_items.append(ActionItem(
            module="dpia",
            entity_id=str(dpia.id),
            title=f"DPIA {dpia.tracking_id or str(dpia.id)[:8]} — {step_label}",
            status=dpia.status,
            urgency="medium",
            due_label=None,
        ))

    # BAPDs needing approval
    bapds_res = await db.execute(
        select(BAPDRecord)
        .options(selectinload(BAPDRecord.approvals))
        .where(BAPDRecord.status.in_(["submitted", "under_review", "pending_approval"]))
        .order_by(BAPDRecord.expiry_date.asc())
        .limit(10)
    )
    for bapd in bapds_res.scalars().all():
        active_step = next((a for a in sorted(bapd.approvals, key=lambda x: x.step_order) if a.status == "requested"), None)
        step_label = _BAPD_STEP_NAMES.get(active_step.step_order, f"Step {active_step.step_order}") if active_step else "Dual Approval"
        days_left = (bapd.expiry_date - today).days if bapd.expiry_date else None
        urgency = "high" if days_left is not None and days_left <= 7 else "medium"
        action_items.append(ActionItem(
            module="bapd",
            entity_id=str(bapd.id),
            title=f"BAPD {str(bapd.id)[:8]} — {step_label}",
            status=bapd.status,
            urgency=urgency,
            due_label=f"Expires in {days_left}d" if days_left is not None else None,
        ))

    # DQ Runs under review
    dq_runs_res = await db.execute(
        select(DQRun)
        .where(DQRun.status == "under_review")
        .order_by(DQRun.created_at.desc())
        .limit(5)
    )
    for dq_run in dq_runs_res.scalars().all():
        action_items.append(ActionItem(
            module="dq",
            entity_id=str(dq_run.id),
            title=f"DQ Run #{str(dq_run.id)[:8]} — Inspection Sign-Off Required",
            status="under_review",
            urgency="medium",
            due_label="Inspection Review",
        ))

    # Sort by urgency
    urgency_order = {"high": 0, "medium": 1, "low": 2}
    action_items.sort(key=lambda x: urgency_order.get(x.urgency, 2))

    # Module status breakdown
    async def _status_counts(model, module_name: str) -> ModuleStatusBreakdown:
        rows = (await db.execute(
            select(model.status, func.count().label("cnt")).group_by(model.status)
        )).all()
        counts = {r[0]: r[1] for r in rows}
        return ModuleStatusBreakdown(
            module=module_name,
            draft=counts.get("draft", 0),
            under_review=counts.get("under_review", 0),
            approved=counts.get("approved", 0),
            archived=counts.get("archived", 0),
            other=sum(v for k, v in counts.items() if k not in ("draft", "under_review", "approved", "archived")),
        )

    module_status = [
        await _status_counts(DataSharingRequest, "dsr"),
        await _status_counts(DPIARecord, "dpia"),
        await _status_counts(ROPARecord, "ropa"),
        await _status_counts(BAPDRecord, "bapd"),
    ]

    return DashboardResponse(
        kpi=kpi,
        recent_activity=activity,
        action_items=action_items[:20],
        module_status=module_status,
    )
