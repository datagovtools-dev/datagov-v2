"use client";

import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Plus, BarChart2, Table2, ArrowRight, Activity } from "lucide-react";
import { api } from "@/lib/api";
import { ProjectInfoStrip } from "@/components/details/ProjectInfoStrip";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { formatDate } from "@/lib/utils";

interface ProjectOption {
  id: string;
  project_code: string | null;
  project_name: string;
}

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
  // latest_run_* = newest run with results; a newer run without results (queued/running/failed) is below
  latest_run_version: number | null;
  newer_run_id: string | null;
  newer_run_status: string | null;
  newer_run_version: number | null;
}

interface ProjectProgress { active_count: number; eta_seconds: number | null }

function formatDuration(totalSeconds: number): string {
  const s = Math.max(Math.round(totalSeconds), 0);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${String(s % 60).padStart(2, "0")}` : `${m}:${String(s % 60).padStart(2, "0")}`;
}

// Badge for a re-run that has no results yet, shown next to the version whose results are displayed
function NewerRunBadge({ t }: { t: DQTableSummary }) {
  if (!t.newer_run_id || !t.newer_run_status) return null;
  const v = t.newer_run_version ? `v${t.newer_run_version}` : "New run";
  const cfg: Record<string, { text: string; cls: string }> = {
    pending: { text: `${v} queued`, cls: "bg-slate-100 text-slate-700 border-slate-200" },
    running: { text: `${v} running`, cls: "bg-blue-50 text-blue-700 border-blue-200" },
    failed: { text: `${v} failed`, cls: "bg-rose-50 text-rose-700 border-rose-200" },
  };
  const c = cfg[t.newer_run_status] ?? { text: `${v} ${t.newer_run_status}`, cls: "bg-slate-100 text-slate-700 border-slate-200" };
  return (
    <Link href={`/dq/${t.newer_run_id}`} title="Newer run without results yet; the scores shown are from the previous version until it finishes"
      className={`inline-flex items-center text-[10px] font-mono font-medium px-1.5 py-0.2 rounded-md border ${c.cls}`}>
      {c.text}
    </Link>
  );
}

function ScorePill({ score }: { score: string | null }) {
  if (!score) return <span className="text-slate-400 text-xs font-mono">—</span>;
  const n = parseFloat(score);
  const color =
    n >= 90
      ? "bg-emerald-50 text-emerald-700 border-emerald-200"
      : n >= 70
      ? "bg-amber-50 text-amber-700 border-amber-200"
      : "bg-rose-50 text-rose-700 border-rose-200";
  return (
    <span
      className={`inline-flex items-center px-1.5 py-0.2 rounded-md text-xs font-mono font-semibold border tabular-nums ${color}`}
    >
      {n.toFixed(1)}%
    </span>
  );
}

type BadgeVariant =
  | "default"
  | "success"
  | "warning"
  | "danger"
  | "neutral"
  | "info";

function statusVariant(status: string | null): BadgeVariant {
  if (!status) return "default";
  const map: Record<string, BadgeVariant> = {
    pending: "neutral",
    running: "info",
    completed: "success",
    under_review: "warning",
    approved: "success",
    rejected: "danger",
    failed: "danger",
  };
  return map[status] ?? "default";
}

function SourceBadge({ type }: { type: string }) {
  const cfg: Record<string, { label: string }> = {
    excel: { label: "Excel" },
    gcp: { label: "BigQuery" },
    postgresql: { label: "Postgres" },
  };
  const c = cfg[type] ?? { label: type };
  return (
    <span className="inline-flex items-center text-[10px] font-mono font-medium px-1.5 py-0.2 rounded-md border border-slate-200 bg-slate-50 text-slate-700">
      {c.label}
    </span>
  );
}

export default function DQListPage() {
  const [projectId, setProjectId] = useState("");
  const [runFilter, setRunFilter] = useState<"all" | "has_runs" | "no_runs">("all");

  // Keep the selected project in the URL (?project=) so Back from a run or the project report returns to it
  useEffect(() => {
    const fromUrl = new URLSearchParams(window.location.search).get("project");
    if (fromUrl) setProjectId(fromUrl);
  }, []);
  useEffect(() => {
    const url = projectId ? `/dq?project=${projectId}` : "/dq";
    if (window.location.pathname + window.location.search !== url) window.history.replaceState(null, "", url);
  }, [projectId]);

  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  // Queued/running runs of the project: banner with time left, and no second start while they run
  const { data: progress } = useQuery<ProjectProgress>({
    queryKey: ["dq-progress", projectId],
    queryFn: () => api.get<ProjectProgress>(`/dq/project/${projectId}/progress`),
    enabled: !!projectId,
    refetchInterval: (q) => ((q.state.data?.active_count ?? 0) > 0 ? 10000 : false),
  });
  const running = (progress?.active_count ?? 0) > 0;

  const { data: tables, isLoading } = useQuery<DQTableSummary[]>({
    queryKey: ["dq-tables-summary", projectId],
    queryFn: () => api.get<DQTableSummary[]>(`/dq/project/${projectId}/tables-summary`),
    enabled: !!projectId,
    refetchInterval: running ? 10000 : false, // badges follow the runs; scores switch when a run finishes
  });
  const [progressAt, setProgressAt] = useState(() => Date.now());
  const [nowTick, setNowTick] = useState(() => Date.now());
  useEffect(() => { setProgressAt(Date.now()); }, [progress]);
  useEffect(() => {
    if (!running) return;
    const t = setInterval(() => setNowTick(Date.now()), 1000);
    return () => clearInterval(t);
  }, [running]);
  const timeLeft = progress?.eta_seconds != null ? Math.max(progress.eta_seconds - (nowTick - progressAt) / 1000, 0) : null;

  const allTables = tables ?? [];
  const displayed =
    runFilter === "has_runs"
      ? allTables.filter((t) => t.total_runs > 0)
      : runFilter === "no_runs"
      ? allTables.filter((t) => t.total_runs === 0)
      : allTables;

  const totalRuns = allTables.reduce((s, t) => s + t.total_runs, 0);
  const scored = allTables.filter((t) => t.latest_run_score);
  const avgScore =
    scored.length > 0
      ? scored.reduce((s, t) => s + parseFloat(t.latest_run_score!), 0) / scored.length
      : null;
  const withRuns = allTables.filter((t) => t.total_runs > 0).length;
  const noRuns = allTables.filter((t) => t.total_runs === 0).length;

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Data Quality Control
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Evaluate Completeness, Consistency, Uniqueness, and Freshness dimensions per data asset
          </p>
          {projectId && tables && (
            <div className="flex items-center gap-2.5 mt-1 text-xs text-slate-500 font-mono">
              <span>
                <span className="font-semibold text-slate-900">{allTables.length}</span> tables
              </span>
              <span className="text-slate-300">·</span>
              <span>
                <span className="font-semibold text-slate-900">{totalRuns}</span> runs executed
              </span>
              {avgScore !== null && (
                <>
                  <span className="text-slate-300">·</span>
                  <span>
                    Avg Score:{" "}
                    <span className="font-bold text-emerald-700 tabular-nums">
                      {avgScore.toFixed(1)}%
                    </span>
                  </span>
                </>
              )}
            </div>
          )}
        </div>
        {projectId && running ? (
          <Link href={`/dq/progress/${projectId}`} className="shrink-0" title="DQ is running for this project; follow it, or start new runs after it finishes">
            <Button size="sm" className="font-medium">
              <Activity className="h-3.5 w-3.5 mr-1" /> View Progress
            </Button>
          </Link>
        ) : (
          <Link href={`/dq/new${projectId ? `?project=${projectId}` : ""}`} className="shrink-0">
            <Button size="sm" className="font-medium">
              <Plus className="h-3.5 w-3.5 mr-1" /> {projectId ? "Run All Data" : "New DQ Run"}
            </Button>
          </Link>
        )}
      </div>

      {/* Project Selector Card */}
      <div className="rounded-md border border-slate-200 bg-white p-3.5 shadow-2xs">
        <div className="max-w-sm">
          <label className="block text-xs font-semibold text-slate-700 mb-1">
            Select Governance Project
          </label>
          <select
            value={projectId}
            onChange={(e) => {
              setProjectId(e.target.value);
              setRunFilter("all");
            }}
            className="w-full border border-slate-200 rounded-md px-2.5 py-1.5 text-xs bg-white text-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-950"
          >
            <option value="">Select project to evaluate...</option>
            {projects?.map((p) => (
              <option key={p.id} value={p.id}>
                {p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Project info strip for the selected project */}
      {projectId && <ProjectInfoStrip projectId={projectId} />}

      {/* DQ running for this project: way back to the progress page */}
      {projectId && running && (
        <div className="rounded-md border border-blue-200 bg-blue-50 px-3.5 py-2.5 flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="w-4 h-4 flex-shrink-0 rounded-full border-2 border-blue-200 border-t-blue-600 animate-spin" />
            <p className="text-xs text-blue-900">
              <span className="font-semibold">DQ running for this project</span>
              {" · "}{progress!.active_count} file{progress!.active_count > 1 ? "s" : ""} queued or running
              {timeLeft !== null && <>{" · "}<span className="font-mono font-semibold">≈ {formatDuration(timeLeft)} left</span></>}
              <span className="text-blue-700"> · Scores below stay on the previous version until each file finishes.</span>
            </p>
          </div>
          <Link href={`/dq/progress/${projectId}`}>
            <Button size="sm" variant="outline" className="h-7 text-xs bg-white">
              View progress <ArrowRight className="h-3 w-3 ml-1" />
            </Button>
          </Link>
        </div>
      )}

      {/* Table List Card */}
      {projectId ? (
        <div className="rounded-md border border-slate-200 bg-white shadow-2xs overflow-hidden">
          <div className="flex flex-wrap items-center justify-between gap-2.5 px-3.5 py-2.5 border-b border-slate-200 bg-slate-50/50">
            <div className="flex items-center gap-3">
              <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-700 font-mono">
                Source Tables & Status
              </h2>
              <div className="flex gap-1">
                {[
                  { key: "all", label: `All (${allTables.length})` },
                  { key: "has_runs", label: `Evaluated (${withRuns})` },
                  { key: "no_runs", label: `Unchecked (${noRuns})` },
                ].map(({ key, label }) => (
                  <button
                    key={key}
                    onClick={() => setRunFilter(key as any)}
                    className={`text-[10px] font-mono px-2 py-0.5 rounded-md font-medium transition-colors ${
                      runFilter === key
                        ? "bg-slate-900 text-white font-semibold"
                        : "text-slate-600 hover:bg-slate-200/60"
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>

            {allTables.length > 0 && (
              <div className="flex items-center gap-2 shrink-0">
                {withRuns > 0 && (
                  <Link href={`/dq/project/${projectId}`} title="DQ results of all tables in this project: combined summary, per-table scores, all rules">
                    <Button size="sm" variant="outline" className="h-6.5 text-[11px]">
                      <BarChart2 className="h-3 w-3 mr-1" /> Project Report
                    </Button>
                  </Link>
                )}
                {running ? (
                  <Link href={`/dq/progress/${projectId}`} title="DQ is running for this project; start new runs after it finishes">
                    <Button size="sm" variant="outline" className="h-6.5 text-[11px]">
                      <Activity className="h-3 w-3 mr-1" /> View Progress
                    </Button>
                  </Link>
                ) : (
                  <Link href={`/dq/new?project=${projectId}`}>
                    <Button size="sm" variant="outline" className="h-6.5 text-[11px]">
                      <Plus className="h-3 w-3 mr-1" /> Run All
                    </Button>
                  </Link>
                )}
              </div>
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
                <TableHead>Last Checked</TableHead>
                <TableHead className="text-right w-24">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {!displayed.length && !isLoading ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center py-10 text-xs text-slate-400 font-mono">
                    {!allTables.length
                      ? "No tables documented for this project — import data via Metadata module first."
                      : "No tables match the selected filter."}
                  </TableCell>
                </TableRow>
              ) : (
                displayed.map((t) => (
                  <TableRow key={t.table_name}>
                    <TableCell className="font-mono text-xs font-semibold text-slate-900">
                      <div className="flex items-center gap-1.5">
                        <Table2 className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                        <span>{t.table_name}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <SourceBadge type={t.source_type} />
                    </TableCell>
                    <TableCell className="text-xs text-slate-600 tabular-nums font-mono">{t.attribute_count}</TableCell>
                    <TableCell className="text-xs text-slate-900 tabular-nums font-semibold font-mono">{t.total_runs}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1.5">
                        <ScorePill score={t.latest_run_score} />
                        {t.latest_run_score && t.latest_run_version ? (
                          <span className="text-[10px] font-mono text-slate-400">v{t.latest_run_version}</span>
                        ) : null}
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap items-center gap-1">
                        {t.latest_run_status ? (
                          <Badge variant={statusVariant(t.latest_run_status)} className="text-[10px] capitalize">
                            {t.latest_run_status.replace(/_/g, " ")}
                          </Badge>
                        ) : (
                          <span className="text-slate-400 text-xs font-mono">—</span>
                        )}
                        <NewerRunBadge t={t} />
                      </div>
                    </TableCell>
                    <TableCell className="text-xs text-slate-500 font-mono">
                      {t.latest_run_date ? formatDate(t.latest_run_date) : "—"}
                    </TableCell>
                    <TableCell className="text-right">
                      {t.latest_run_id ? (
                        <Link
                          href={`/dq/${t.latest_run_id}`}
                          className="inline-flex items-center gap-1 text-xs font-medium text-slate-700 hover:text-slate-900"
                        >
                          Report <ArrowRight className="h-3 w-3" />
                        </Link>
                      ) : (
                        <Link
                          href={`/dq/new?project=${projectId}${t.source_file_id ? `&file=${t.source_file_id}` : ""}`}
                          className="inline-flex items-center gap-1 text-xs font-medium text-slate-700 hover:text-slate-900"
                        >
                          Run DQ <ArrowRight className="h-3 w-3" />
                        </Link>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      ) : (
        <div className="rounded-md border border-slate-200 bg-white p-12 text-center shadow-2xs">
          <div className="flex h-10 w-10 items-center justify-center rounded-md bg-slate-100 text-slate-700 mx-auto mb-2.5">
            <BarChart2 className="h-5 w-5" />
          </div>
          <h3 className="text-sm font-semibold text-slate-900">Select a Project to Inspect Quality</h3>
          <p className="text-xs text-slate-500 mt-0.5 max-w-sm mx-auto">
            Choose a data governance project above to evaluate completeness, consistency, and freshness metrics.
          </p>
        </div>
      )}
    </div>
  );
}
