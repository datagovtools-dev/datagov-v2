from pydantic import BaseModel


class KPIStats(BaseModel):
    active_projects: int
    open_dsrs: int
    pending_dpias: int
    bapd_due_soon: int
    dq_runs_this_month: int


class RecentActivity(BaseModel):
    module: str
    action: str
    entity_type: str
    entity_id: str
    actor: str
    timestamp: str


class ActionItem(BaseModel):
    module: str
    entity_id: str
    title: str
    status: str
    urgency: str  # "high" | "medium" | "low"
    due_label: str | None


class ModuleStatusBreakdown(BaseModel):
    module: str
    draft: int
    under_review: int
    approved: int
    archived: int
    other: int


class DashboardResponse(BaseModel):
    kpi: KPIStats
    recent_activity: list[RecentActivity]
    action_items: list[ActionItem] = []
    module_status: list[ModuleStatusBreakdown] = []
