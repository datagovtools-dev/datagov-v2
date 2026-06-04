"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Plus, BarChart2, Table2 } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { formatDate } from "@/lib/utils";

interface ProjectOption { id: string; project_code: string | null; project_name: string; }

interface DQTableSummary {
  table_name: string;
  source_type: string;
  attribute_count: number;
  source_file_id: string | null;
  total_runs: number;
  latest_run_id: string | null;
  latest_run_name: string | null;
  latest_run_status: string | null;
  latest_run_score: string | null;
  latest_run_date: string | null;
}

function ScorePill({ score }: { score: string | null }) {
  if (!score) return <span className="text-surface-400">—</span>;
  const n = parseFloat(score);
  const color = n >= 90 ? "bg-green-100 text-green-700" : n >= 70 ? "bg-yellow-100 text-yellow-700" : "bg-red-100 text-red-700";
  return <span className={`inline-flex items-center px-2 py-0.5 rounded text-sm font-semibold ${color}`}>{n.toFixed(1)}%</span>;
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(status: string | null): BadgeVariant {
  if (!status) return "default";
  const map: Record<string, BadgeVariant> = {
    pending: "default", running: "warning", completed: "in-review",
    under_review: "in-review", approved: "approved", rejected: "rejected", failed: "danger",
  };
  return map[status] ?? "default";
}

function SourceBadge({ type }: { type: string }) {
  const cfg: Record<string, { icon: string; label: string; cls: string }> = {
    excel:      { icon: "📊", label: "Excel",      cls: "bg-green-50 text-green-700" },
    gcp:        { icon: "☁",  label: "GCP",        cls: "bg-blue-50 text-blue-700" },
    postgresql: { icon: "🐘", label: "PostgreSQL", cls: "bg-teal-50 text-teal-700" },
  };
  const c = cfg[type] ?? { icon: "📄", label: type, cls: "bg-surface-100 text-surface-600" };
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${c.cls}`}>
      {c.icon} {c.label}
    </span>
  );
}

export default function DQListPage() {
  const [projectId, setProjectId] = useState("");
  const [runFilter, setRunFilter] = useState<"all" | "has_runs" | "no_runs">("all");

  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: tables, isLoading } = useQuery<DQTableSummary[]>({
    queryKey: ["dq-tables-summary", projectId],
    queryFn: () => api.get<DQTableSummary[]>(`/dq/project/${projectId}/tables-summary`),
    enabled: !!projectId,
  });

  const allTables = tables ?? [];
  const displayed =
    runFilter === "has_runs" ? allTables.filter((t) => t.total_runs > 0) :
    runFilter === "no_runs"  ? allTables.filter((t) => t.total_runs === 0) :
    allTables;

  const totalRuns  = allTables.reduce((s, t) => s + t.total_runs, 0);
  const scored     = allTables.filter((t) => t.latest_run_score);
  const avgScore   = scored.length > 0
    ? scored.reduce((s, t) => s + parseFloat(t.latest_run_score!), 0) / scored.length
    : null;
  const withRuns   = allTables.filter((t) => t.total_runs > 0).length;
  const noRuns     = allTables.filter((t) => t.total_runs === 0).length;

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Data Quality</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Monitor completeness, consistency, uniqueness, and latency per table across your projects
          </p>
          {projectId && tables && (
            <div className="flex items-center gap-4 mt-1.5">
              <span className="text-sm text-surface-600">
                <span className="font-semibold text-surface-800">{allTables.length}</span>{" "}
                table{allTables.length !== 1 ? "s" : ""}
              </span>
              <span className="text-surface-300">·</span>
              <span className="text-sm text-surface-600">
                <span className="font-semibold text-surface-800">{totalRuns}</span>{" "}
                DQ run{totalRuns !== 1 ? "s" : ""}
              </span>
              {avgScore !== null && (
                <>
                  <span className="text-surface-300">·</span>
                  <span className="text-sm text-surface-600">
                    Avg score:{" "}
                    <span className="font-semibold text-surface-800">{avgScore.toFixed(1)}%</span>
                  </span>
                </>
              )}
            </div>
          )}
        </div>
        <Link href={`/dq/new${projectId ? `?project=${projectId}` : ""}`} className="shrink-0">
          <Button className="whitespace-nowrap">
            <Plus className="h-4 w-4 mr-1" /> {projectId ? "Run All Project Data" : "New Project DQ Run"}
          </Button>
        </Link>
      </div>

      {/* Project selector */}
      <div className="bg-white rounded-xl border border-surface-200 p-5 mb-5">
        <div className="max-w-sm">
          <label className="block text-sm font-medium text-surface-700 mb-1">Project</label>
          <select
            value={projectId}
            onChange={(e) => { setProjectId(e.target.value); setRunFilter("all"); }}
            className="w-full border border-surface-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 text-surface-700"
          >
            <option value="">Select project…</option>
            {projects?.map((p) => (
              <option key={p.id} value={p.id}>
                {p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Table list */}
      {projectId ? (
        <div className="bg-white rounded-xl border border-surface-200 overflow-hidden">
          <div className="flex items-center justify-between px-4 py-3 border-b border-surface-100">
            <div className="flex items-center gap-3">
              <h2 className="font-semibold text-surface-800">Source Tables</h2>
              {isLoading && <span className="text-xs text-surface-400">Loading…</span>}
              <div className="flex gap-1">
                {([
                  { key: "all",      label: `All (${allTables.length})` },
                  { key: "has_runs", label: `Has DQ Runs (${withRuns})` },
                  { key: "no_runs",  label: `No Runs Yet (${noRuns})` },
                ] as const).map(({ key, label }) => (
                  <button key={key} onClick={() => setRunFilter(key)}
                    className={`text-xs px-2.5 py-1 rounded-full font-medium transition-colors ${
                      runFilter === key
                        ? key === "no_runs" ? "bg-amber-100 text-amber-700" : "bg-primary-100 text-primary-700"
                        : "text-surface-500 hover:bg-surface-100"
                    }`}>
                    {label}
                  </button>
                ))}
              </div>
            </div>
            {allTables.length > 0 && (
              <Link href={`/dq/new?project=${projectId}`} className="shrink-0">
                <Button size="sm" variant="outline" className="whitespace-nowrap">
                  <Plus className="h-3.5 w-3.5 mr-1" /> Run All Project Data
                </Button>
              </Link>
            )}
          </div>

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Table Name</TableHead>
                <TableHead>Source</TableHead>
                <TableHead>Attributes</TableHead>
                <TableHead>DQ Runs</TableHead>
                <TableHead>Latest Score</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Last Run</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {!displayed.length && !isLoading ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center py-10 text-surface-400">
                    {!allTables.length
                      ? "No tables documented for this project — import data via the Metadata module first"
                      : "No tables match the selected filter"}
                  </TableCell>
                </TableRow>
              ) : displayed.map((t) => (
                <TableRow key={t.table_name}>
                  <TableCell className="font-medium text-surface-800">
                    <div className="flex items-center gap-2">
                      <Table2 className="h-4 w-4 text-surface-400 shrink-0" />
                      <span className="text-sm">{t.table_name}</span>
                    </div>
                  </TableCell>
                  <TableCell><SourceBadge type={t.source_type} /></TableCell>
                  <TableCell className="text-surface-600 text-sm">{t.attribute_count}</TableCell>
                  <TableCell className="text-surface-600 text-sm">{t.total_runs}</TableCell>
                  <TableCell><ScorePill score={t.latest_run_score} /></TableCell>
                  <TableCell>
                    {t.latest_run_status ? (
                      <Badge variant={statusVariant(t.latest_run_status)}>
                        {t.latest_run_status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
                      </Badge>
                    ) : (
                      <span className="text-surface-400 text-sm">—</span>
                    )}
                  </TableCell>
                  <TableCell className="text-surface-500 text-sm">
                    {t.latest_run_date ? formatDate(t.latest_run_date) : "—"}
                  </TableCell>
                  <TableCell className="text-right">
                    {t.latest_run_id ? (
                      <Link href={`/dq/${t.latest_run_id}`} className="text-xs text-primary-600 hover:underline">
                        View DQ →
                      </Link>
                    ) : t.source_file_id ? (
                      <Link
                        href={`/dq/new?project=${projectId}&file=${t.source_file_id}`}
                        className="text-xs text-primary-600 hover:underline"
                      >
                        Run DQ →
                      </Link>
                    ) : (
                      <Link href={`/dq/new?project=${projectId}`} className="text-xs text-primary-600 hover:underline">
                        Run DQ →
                      </Link>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-surface-200 p-14 text-center">
          <BarChart2 className="h-10 w-10 text-surface-300 mx-auto mb-3" />
          <p className="text-surface-500 font-medium">Select a project to view its data quality status</p>
          <p className="text-sm text-surface-400 mt-1">
            Tables are shared with the Metadata module — each row represents one documented table
          </p>
        </div>
      )}
    </div>
  );
}
