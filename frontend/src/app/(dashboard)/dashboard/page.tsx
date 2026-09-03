"use client";

import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import {
  FolderOpen,
  Share2,
  ShieldCheck,
  Trash2,
  BarChart2,
  Plus,
  ArrowRight,
  Activity,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Database,
  ExternalLink,
} from "lucide-react";
import { api } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { formatDateTime } from "@/lib/utils";

interface KPI {
  active_projects: number;
  open_dsrs: number;
  pending_dpias: number;
  bapd_due_soon: number;
  dq_runs_this_month: number;
}

interface ActivityItem {
  module: string;
  action: string;
  entity_type: string;
  entity_id: string;
  actor: string;
  timestamp: string;
}

interface ActionItem {
  module: string;
  entity_id: string;
  title: string;
  status: string;
  urgency: string;
  due_label: string | null;
}

interface ModuleStatus {
  module: string;
  draft: number;
  under_review: number;
  approved: number;
  archived: number;
  other: number;
}

interface DashboardData {
  kpi: KPI;
  recent_activity: ActivityItem[];
  action_items: ActionItem[];
  module_status: ModuleStatus[];
}

const KPI_CARDS = [
  {
    key: "active_projects",
    label: "Governed Assets",
    sub: "Active data projects",
    icon: FolderOpen,
    href: "/projects",
  },
  {
    key: "open_dsrs",
    label: "Sharing Requests",
    sub: "Pending DSR reviews",
    icon: Share2,
    href: "/dsr",
  },
  {
    key: "pending_dpias",
    label: "Privacy Assessments",
    sub: "Active DPIA evaluations",
    icon: ShieldCheck,
    href: "/dpia",
  },
  {
    key: "dq_runs_this_month",
    label: "Quality Checks",
    sub: "Rule evaluations this mo",
    icon: BarChart2,
    href: "/dq",
  },
  {
    key: "bapd_due_soon",
    label: "Disposal Due",
    sub: "Retention expiry ≤30d",
    icon: Trash2,
    href: "/bapd",
  },
] as const;

const QUICK_ACTIONS = [
  { label: "New Data Sharing Request", href: "/dsr/new", icon: Share2 },
  { label: "Proceed Metadata Dictionary", href: "/metadata", icon: Database },
  { label: "Run Data Quality Check", href: "/dq/new", icon: BarChart2 },
  { label: "Register New Data Asset", href: "/projects/new", icon: Plus },
];

const MODULE_BADGE_MAP: Record<string, "default" | "primary" | "warning" | "info" | "danger" | "success"> = {
  auth: "default",
  project: "default",
  dsr: "warning",
  dpia: "info",
  ropa: "info",
  bapd: "danger",
  metadata: "success",
  dq: "success",
  rbac: "default",
};

const URGENCY_ICON = { high: AlertTriangle, medium: Clock, low: CheckCircle2 };
const URGENCY_COLOR = { high: "text-rose-600", medium: "text-amber-600", low: "text-emerald-600" };

export default function DashboardPage() {
  const { data, isLoading } = useQuery<DashboardData>({
    queryKey: ["dashboard"],
    queryFn: () => api.get<DashboardData>("/dashboard"),
    refetchInterval: 60_000,
  });

  return (
    <div className="space-y-5">
      {/* ── Page Header & Quick Controls ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Executive Overview
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Enterprise governance telemetry, active review queues, and system inventory.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Link href="/projects/new">
            <Button size="sm" className="font-medium">
              <Plus className="h-3.5 w-3.5 mr-1" /> New Data Asset
            </Button>
          </Link>
          <Link href="/dsr/new">
            <Button size="sm" variant="outline" className="font-medium">
              <Share2 className="h-3.5 w-3.5 mr-1 text-slate-600" /> New DSR
            </Button>
          </Link>
          <Link href="/dq/new">
            <Button size="sm" variant="outline" className="font-medium">
              <BarChart2 className="h-3.5 w-3.5 mr-1 text-emerald-600" /> Run DQ
            </Button>
          </Link>
        </div>
      </div>

      {/* ── 1. Telemetry Metric Grid (Strict 4px grid / compact rounded-md) ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-3">
        {KPI_CARDS.map(({ key, label, sub, icon: Icon, href }) => (
          <Link key={key} href={href} className="block group">
            <Card className="hover:border-slate-300 p-3.5 flex flex-col justify-between h-full transition-colors">
              <div className="flex items-start justify-between">
                <div>
                  <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono block">
                    {label}
                  </span>
                  <span className="text-2xl font-bold text-slate-900 font-mono tabular-nums mt-0.5 block">
                    {isLoading ? "—" : data?.kpi[key] ?? 0}
                  </span>
                </div>
                <div className="p-1.5 rounded-md bg-slate-100 text-slate-600">
                  <Icon className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-2.5 pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                <span className="truncate">{sub}</span>
                <ArrowRight className="h-3 w-3 text-slate-400 group-hover:text-slate-900 transition-colors shrink-0 ml-1" />
              </div>
            </Card>
          </Link>
        ))}
      </div>

      {/* ── 2. Primary Operations Grid ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Left Column: Action Required Queue & Governance Workflows (7 cols) */}
        <div className="lg:col-span-7 space-y-4">
          {/* Action Required Queue */}
          <Card className="p-4">
            <CardHeader className="mb-2.5 pb-2 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-amber-600" />
                <CardTitle>Action Items & Approvals</CardTitle>
              </div>
              <Badge variant="warning" className="text-[10px]">
                {data?.action_items?.length || 0} Pending
              </Badge>
            </CardHeader>

            <CardContent>
              {isLoading ? (
                <p className="text-xs text-slate-400 text-center py-6">Loading action items...</p>
              ) : !data?.action_items?.length ? (
                <div className="text-center py-8">
                  <CheckCircle2 className="h-6 w-6 text-emerald-500 mx-auto mb-1.5 opacity-80" />
                  <p className="text-xs font-semibold text-slate-800">All Approvals Clear</p>
                  <p className="text-[11px] text-slate-400 mt-0.5">No pending review tasks require your attention.</p>
                </div>
              ) : (
                <div className="divide-y divide-slate-100 max-h-80 overflow-y-auto">
                  {data.action_items.map((item, i) => {
                    const UrgIcon = URGENCY_ICON[item.urgency as keyof typeof URGENCY_ICON] ?? Clock;
                    return (
                      <Link
                        key={i}
                        href={`/${item.module}/${item.entity_id}`}
                        className="flex items-center justify-between py-2.5 px-1.5 hover:bg-slate-50 rounded-md transition-colors group"
                      >
                        <div className="flex items-start gap-2.5 min-w-0 pr-2">
                          <UrgIcon
                            className={`h-4 w-4 mt-0.5 shrink-0 ${
                              URGENCY_COLOR[item.urgency as keyof typeof URGENCY_COLOR] ?? "text-slate-400"
                            }`}
                          />
                          <div className="min-w-0">
                            <p className="text-xs font-medium text-slate-900 truncate group-hover:text-slate-700">
                              {item.title}
                            </p>
                            <div className="flex items-center gap-2 mt-0.5">
                              <span className="text-[10px] font-mono text-slate-400 uppercase">
                                {item.module}
                              </span>
                              {item.due_label && (
                                <span className="text-[10px] font-medium text-rose-600">
                                  • {item.due_label}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                        <span className="text-xs font-medium text-slate-700 group-hover:text-slate-900 inline-flex items-center gap-1 shrink-0">
                          Review <ArrowRight className="h-3 w-3" />
                        </span>
                      </Link>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Workflow Status Distribution */}
          {data?.module_status && data.module_status.length > 0 && (
            <Card className="p-4">
              <CardHeader className="mb-2.5 pb-2 border-b border-slate-100">
                <CardTitle>Governance Workflow Distribution</CardTitle>
                <CardDescription>Active lifecycle breakdown per governance module</CardDescription>
              </CardHeader>

              <CardContent>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                  {data.module_status.map((ms) => {
                    const total = ms.draft + ms.under_review + ms.approved + ms.archived + ms.other;
                    return (
                      <div key={ms.module} className="p-2.5 rounded-md border border-slate-200 bg-slate-50/50">
                        <div className="flex items-center justify-between mb-1.5">
                          <span className="text-xs font-semibold text-slate-900 uppercase font-mono">
                            {ms.module}
                          </span>
                          <span className="text-xs font-bold font-mono text-slate-700 tabular-nums">
                            {total} total
                          </span>
                        </div>
                        <div className="grid grid-cols-4 gap-1 text-[10px] text-center pt-1 border-t border-slate-200/60 font-mono">
                          <div>
                            <span className="text-slate-400 block">Draft</span>
                            <span className="font-semibold text-slate-700">{ms.draft}</span>
                          </div>
                          <div>
                            <span className="text-blue-600 block">Review</span>
                            <span className="font-semibold text-blue-700">{ms.under_review}</span>
                          </div>
                          <div>
                            <span className="text-emerald-600 block">Approved</span>
                            <span className="font-semibold text-emerald-700">{ms.approved}</span>
                          </div>
                          <div>
                            <span className="text-slate-400 block">Archived</span>
                            <span className="font-semibold text-slate-600">{ms.archived}</span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>
          )}
        </div>

        {/* Right Column: Live Audit Telemetry & Quick Navigation (5 cols) */}
        <div className="lg:col-span-5 space-y-4">
          {/* Live Audit Telemetry */}
          <Card className="p-4">
            <CardHeader className="mb-2.5 pb-2 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <Activity className="h-4 w-4 text-slate-700" />
                <CardTitle>Audit Telemetry</CardTitle>
              </div>
              <span className="text-[10px] font-mono text-slate-400">REALTIME</span>
            </CardHeader>

            <CardContent>
              {isLoading ? (
                <p className="text-xs text-slate-400 py-6 text-center">Loading audit events...</p>
              ) : !data?.recent_activity.length ? (
                <p className="text-xs text-slate-400 py-6 text-center">No recorded activity yet</p>
              ) : (
                <div className="divide-y divide-slate-100 max-h-80 overflow-y-auto">
                  {data.recent_activity.map((a, i) => (
                    <div key={i} className="py-2 flex items-start gap-2.5">
                      <Badge variant={MODULE_BADGE_MAP[a.module] ?? "default"} className="mt-0.5 text-[10px] font-mono uppercase shrink-0">
                        {a.module}
                      </Badge>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs text-slate-800 leading-snug truncate">
                          <span className="font-semibold text-slate-900">{a.actor}</span>{" "}
                          <span className="text-slate-500">{a.action.replace(/_/g, " ")}</span>
                        </p>
                        <div className="flex items-center gap-2 text-[10px] text-slate-400 font-mono mt-0.5">
                          {a.entity_id && <span>#{a.entity_id.slice(0, 8)}</span>}
                          <span>•</span>
                          <span>{formatDateTime(a.timestamp)}</span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Direct Workflow Shortcuts */}
          <Card className="p-4">
            <CardHeader className="mb-2 pb-2 border-b border-slate-100">
              <CardTitle>Direct Operations</CardTitle>
              <CardDescription>Shortcuts to primary governance tools</CardDescription>
            </CardHeader>

            <CardContent className="space-y-1.5">
              {QUICK_ACTIONS.map(({ label, href, icon: Icon }) => (
                <Link key={href} href={href} className="block">
                  <div className="flex items-center justify-between p-2 rounded-md border border-slate-200 bg-white hover:bg-slate-50 text-xs font-medium text-slate-800 transition-colors">
                    <div className="flex items-center gap-2">
                      <Icon className="h-3.5 w-3.5 text-slate-500" />
                      <span>{label}</span>
                    </div>
                    <ExternalLink className="h-3 w-3 text-slate-400" />
                  </div>
                </Link>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
