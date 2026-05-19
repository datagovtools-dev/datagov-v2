"use client";

import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { FolderOpen, Share2, ShieldCheck, Trash2, BarChart2, Plus, ArrowRight, Activity, AlertTriangle, CheckCircle2, Clock } from "lucide-react";
import { api } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { formatDateTime } from "@/lib/utils";

interface KPI { active_projects: number; open_dsrs: number; pending_dpias: number; bapd_due_soon: number; dq_runs_this_month: number }
interface ActivityItem { module: string; action: string; entity_type: string; entity_id: string; actor: string; timestamp: string }
interface ActionItem { module: string; entity_id: string; title: string; status: string; urgency: string; due_label: string | null }
interface ModuleStatus { module: string; draft: number; under_review: number; approved: number; archived: number; other: number }
interface DashboardData { kpi: KPI; recent_activity: ActivityItem[]; action_items: ActionItem[]; module_status: ModuleStatus[] }

const KPI_CARDS = [
  { key: "active_projects",    label: "Active Projects",    icon: FolderOpen,  color: "text-primary-600", bg: "bg-primary-50", href: "/projects" },
  { key: "open_dsrs",          label: "Open DSRs",          icon: Share2,      color: "text-amber-600",   bg: "bg-amber-50",   href: "/dsr" },
  { key: "pending_dpias",      label: "Pending DPIAs",      icon: ShieldCheck, color: "text-blue-600",    bg: "bg-blue-50",    href: "/dpia" },
  { key: "bapd_due_soon",      label: "BAPD Due ≤30 days",  icon: Trash2,      color: "text-red-600",     bg: "bg-red-50",     href: "/bapd" },
  { key: "dq_runs_this_month", label: "DQ Runs This Month", icon: BarChart2,   color: "text-teal-600",    bg: "bg-teal-50",    href: "/dq" },
] as const;

const QUICK_ACTIONS = [
  { label: "New Data Sharing Request", href: "/dsr/new",      icon: Share2 },
  { label: "Proceed Metadata",         href: "/metadata",     icon: FolderOpen },
  { label: "Run Data Quality Check",   href: "/dq/new",       icon: BarChart2 },
  { label: "New Project",              href: "/projects/new", icon: Plus },
];

const MODULE_COLORS: Record<string, "primary" | "warning" | "info" | "danger" | "success" | "default"> = {
  auth: "default", project: "primary", dsr: "warning", dpia: "info",
  ropa: "info", bapd: "danger", metadata: "success", dq: "success", rbac: "default",
};

const URGENCY_ICON = { high: AlertTriangle, medium: Clock, low: CheckCircle2 };
const URGENCY_COLOR = { high: "text-red-600", medium: "text-amber-600", low: "text-green-600" };

// Minimal SVG donut chart
function DonutChart({ data }: { data: { label: string; value: number; color: string }[] }) {
  const total = data.reduce((s, d) => s + d.value, 0);
  if (total === 0) return <div className="text-xs text-gray-400 text-center py-2">No data</div>;
  const r = 36, cx = 44, cy = 44, stroke = 14;
  const circumference = 2 * Math.PI * r;
  let offset = 0;
  const slices = data.map((d) => {
    const dash = (d.value / total) * circumference;
    const slice = { ...d, dash, offset };
    offset += dash;
    return slice;
  });
  return (
    <div className="flex items-center gap-3">
      <svg width="88" height="88" viewBox="0 0 88 88">
        {slices.map((s, i) => (
          <circle key={i} cx={cx} cy={cy} r={r} fill="none" stroke={s.color}
            strokeWidth={stroke} strokeDasharray={`${s.dash} ${circumference - s.dash}`}
            strokeDashoffset={-s.offset} style={{ transform: "rotate(-90deg)", transformOrigin: "50% 50%" }} />
        ))}
        <text x={cx} y={cy + 5} textAnchor="middle" fontSize="13" fontWeight="bold" fill="#374151">{total}</text>
      </svg>
      <div className="flex flex-col gap-1">
        {data.map((d) => (
          <div key={d.label} className="flex items-center gap-1.5 text-xs text-gray-600">
            <span className="w-2.5 h-2.5 rounded-sm shrink-0" style={{ background: d.color }} />
            {d.label}: <span className="font-semibold">{d.value}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

const STATUS_PALETTE = ["#3B82F6", "#F59E0B", "#10B981", "#6B7280", "#EF4444"];

export default function DashboardPage() {
  const { data, isLoading } = useQuery<DashboardData>({
    queryKey: ["dashboard"],
    queryFn: () => api.get<DashboardData>("/dashboard"),
    refetchInterval: 60_000,
  });

  return (
    <div className="space-y-6">
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p className="text-sm text-surface-500 mt-0.5">Overview of your governance platform</p>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4">
        {KPI_CARDS.map(({ key, label, icon: Icon, color, bg, href }) => (
          <Link key={key} href={href} className="block hover:no-underline">
            <Card className="hover:shadow-card-hover transition-shadow cursor-pointer">
              <CardContent className="pt-4">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="text-xs font-medium text-surface-500 uppercase tracking-wide">{label}</p>
                    <p className={`mt-2 text-3xl font-bold ${color}`}>
                      {isLoading ? "—" : (data?.kpi[key] ?? "—")}
                    </p>
                  </div>
                  <div className={`${bg} p-2 rounded-lg`}>
                    <Icon className={`h-5 w-5 ${color}`} />
                  </div>
                </div>
                <div className="flex items-center gap-1 mt-3 text-xs text-surface-400">
                  <ArrowRight className="h-3 w-3" /> View all
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Quick Actions */}
        <Card>
          <CardHeader><CardTitle>Quick Actions</CardTitle></CardHeader>
          <CardContent className="flex flex-col gap-2">
            {QUICK_ACTIONS.map(({ label, href, icon: Icon }) => (
              <Link key={href} href={href} className="w-full">
                <Button variant="outline" className="justify-start gap-3 h-10 w-full">
                  <Icon className="h-4 w-4 text-primary-500" />{label}
                </Button>
              </Link>
            ))}
          </CardContent>
        </Card>

        {/* My Action Items */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-500" /> My Action Items
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <p className="text-sm text-surface-400 text-center py-4">Loading…</p>
            ) : !data?.action_items?.length ? (
              <p className="text-sm text-surface-400 text-center py-4">No pending actions</p>
            ) : (
              <div className="space-y-2 max-h-64 overflow-y-auto">
                {data.action_items.map((item, i) => {
                  const UrgIcon = URGENCY_ICON[item.urgency as keyof typeof URGENCY_ICON] ?? Clock;
                  return (
                    <Link key={i} href={`/${item.module}/${item.entity_id}`}
                      className="flex items-start gap-2 p-2 rounded-lg border border-gray-100 hover:bg-gray-50 transition-colors">
                      <UrgIcon className={`h-4 w-4 mt-0.5 shrink-0 ${URGENCY_COLOR[item.urgency as keyof typeof URGENCY_COLOR] ?? "text-gray-500"}`} />
                      <div className="flex-1 min-w-0">
                        <p className="text-sm text-gray-800 truncate">{item.title}</p>
                        {item.due_label && <p className="text-xs text-red-500">{item.due_label}</p>}
                      </div>
                      <Badge variant={item.urgency === "high" ? "danger" : "warning"} className="text-xs shrink-0">
                        {item.module.toUpperCase()}
                      </Badge>
                    </Link>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-4 w-4 text-surface-400" /> Recent Activity
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <p className="text-sm text-surface-400 py-4 text-center">Loading…</p>
            ) : !data?.recent_activity.length ? (
              <p className="text-sm text-surface-400 py-4 text-center">No recent activity</p>
            ) : (
              <div className="space-y-3 max-h-64 overflow-y-auto">
                {data.recent_activity.map((a, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <Badge variant={MODULE_COLORS[a.module] ?? "default"} className="mt-0.5 shrink-0 capitalize">
                      {a.module}
                    </Badge>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-surface-800">
                        <span className="font-medium">{a.actor}</span>
                        {" "}<span className="text-surface-500">{a.action.replace(/_/g, " ")}</span>
                        {a.entity_id && <span className="ml-1 font-mono text-xs text-surface-400">{a.entity_id.slice(0, 8)}…</span>}
                      </p>
                      <p className="text-xs text-surface-400 mt-0.5">{formatDateTime(a.timestamp)}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Module Status Breakdown */}
      {data?.module_status && data.module_status.length > 0 && (
        <div>
          <h2 className="text-base font-semibold text-gray-800 mb-3">Module Status</h2>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            {data.module_status.map((ms) => (
              <Card key={ms.module}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-sm capitalize">{ms.module.toUpperCase()}</CardTitle>
                </CardHeader>
                <CardContent>
                  <DonutChart data={[
                    { label: "Draft",       value: ms.draft,        color: STATUS_PALETTE[1] },
                    { label: "In Review",   value: ms.under_review, color: STATUS_PALETTE[0] },
                    { label: "Approved",    value: ms.approved,     color: STATUS_PALETTE[2] },
                    { label: "Archived",    value: ms.archived,     color: STATUS_PALETTE[3] },
                    { label: "Other",       value: ms.other,        color: STATUS_PALETTE[4] },
                  ].filter(d => d.value > 0)} />
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
