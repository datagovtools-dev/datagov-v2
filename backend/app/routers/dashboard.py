from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, select, case, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, get_db
from app.models.bapd import BAPDApproval, BAPDRecord
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

    _DPIA_STEP_NAMES = {1: "PIC Compliance Review", 2: "DM/PM Approval"}

    # DPIAs under review
    dpias_res = await db.execute(
        select(DPIARecord)
        .options(selectinload(DPIARecord.approvals), selectinload(DPIARecord.project))
        .where(DPIARecord.status.in_(["submitted", "under_review"]))
        .order_by(DPIARecord.created_at.asc())
        .limit(10)
    )
    for dpia in dpias_res.scalars().all():
        def _assigned_to_current_user(approval) -> bool:
            if current_user.is_super_admin or approval.approver_id == current_user.id:
                return True
            project = dpia.project
            if not project:
                return False
            if approval.approver_role == "pic_compliance":
                return project.pic_data_compliance_id == current_user.id
            if approval.approver_role == "dm_pm":
                return current_user.id in {project.delivery_manager_id, project.project_manager_id}
            return False

        active_step = next((
            a for a in sorted(dpia.approvals, key=lambda x: x.step_order)
            if a.status == "requested" and _assigned_to_current_user(a)
        ), None)
        if active_step is None:
            continue
        step_label = _DPIA_STEP_NAMES.get(active_step.step_order, f"Step {active_step.step_order}") if active_step else "Under Review"
        action_items.append(ActionItem(
            module="dpia",
            entity_id=str(dpia.id),
            title=f"DPIA {dpia.tracking_id or str(dpia.id)[:8]} — {step_label}",
            status=dpia.status,
            urgency="medium",
            due_label=None,
        ))

    # BAPDs awaiting Final Approval & Sign Off from the assigned Project SME,
    # plus legacy approval steps assigned to the current user.
    bapds_res = await db.execute(
        select(BAPDRecord)
        .join(Project, BAPDRecord.project_id == Project.id)
        .outerjoin(BAPDApproval, BAPDApproval.bapd_id == BAPDRecord.id)
        .where(
            or_(
                and_(
                    BAPDRecord.status == "draft",
                    or_(
                        BAPDRecord.approval_method == "form_sign_off",
                        and_(BAPDRecord.approval_method.is_(None), BAPDApproval.id.is_(None)),
                    ),
                    Project.sme_id == current_user.id,
                ),
                and_(
                    BAPDRecord.status.in_(["submitted", "under_review"]),
                    BAPDApproval.status.in_(["pending", "requested"]),
                    or_(BAPDApproval.approver_id == current_user.id, current_user.is_super_admin),
                ),
            )
        )
        .order_by(BAPDRecord.expiry_date.asc())
        .limit(20)
    )
    for bapd in bapds_res.scalars().unique().all():
        days_left = (bapd.expiry_date - today).days if bapd.expiry_date else None
        urgency = "high" if days_left is not None and days_left <= 7 else "medium"
        is_legacy = bool(bapd.approvals) or bapd.approval_method == "legacy_dual_approval"
        action_label = "Legacy Approval Step" if is_legacy else "Final Approval & Sign Off"
        action_items.append(ActionItem(
            module="bapd",
            entity_id=str(bapd.id),
            title=f"BAPD {str(bapd.id)[:8]} — {action_label}",
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
