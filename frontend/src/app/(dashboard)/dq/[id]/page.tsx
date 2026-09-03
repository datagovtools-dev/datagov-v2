"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronLeft, ChevronDown, ChevronUp } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { formatDate, formatDateTime } from "@/lib/utils";

type DQDetailTab = "score" | "rules" | "findings" | "archive";

interface DQResultItem {
  id: string;
  check_name: string;
  check_type: string;
  column_name: string | null;
  status: string;
  actual_value: string | null;
  row_count: number | null;
  failed_count: number | null;
  details: Record<string, unknown> | null;
  business_rules: string | null;
  regex_pattern: string | null;
  ai_model: string | null;
  regex_version: string | null;
  column_category: string | null;
  findings: Array<{
    id: string;
    severity: string;
    description: string;
    recommendation: string | null;
    status: string;
  }>;
}

const DQ_DIMENSIONS = ["completeness", "consistency", "uniqueness", "latency"] as const;
type DQDimension = (typeof DQ_DIMENSIONS)[number];

function ScoreBar({ value }: { value: number }) {
  const color =
    value >= 90 ? "bg-emerald-600" : value >= 70 ? "bg-amber-600" : "bg-rose-600";
  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 bg-slate-100 rounded-md h-2 overflow-hidden">
        <div className={`h-full rounded-md transition-all ${color}`} style={{ width: `${value}%` }} />
      </div>
      <span
        className={`text-xs font-mono font-bold w-12 text-right tabular-nums ${
          value >= 90 ? "text-emerald-700" : value >= 70 ? "text-amber-700" : "text-rose-700"
        }`}
      >
        {value.toFixed(1)}%
      </span>
    </div>
  );
}

function DimLabel({ dim }: { dim: string }) {
  const labels: Record<string, string> = {
    completeness: "Completeness",
    consistency: "Consistency",
    uniqueness: "Uniqueness",
    latency: "Latency",
  };
  return <span className="text-[10px] font-mono text-slate-500 uppercase tracking-wider block mb-1">{labels[dim] ?? dim}</span>;
}

function ExpandableText({ text, maxLen = 80 }: { text: string; maxLen?: number }) {
  const [open, setOpen] = useState(false);
  if (text.length <= maxLen) return <span>{text}</span>;
  return (
    <span>
      {open ? text : `${text.slice(0, maxLen)}…`}
      <button
        className="ml-1 text-slate-700 hover:underline text-xs inline-flex items-center gap-0.5 font-mono"
        onClick={() => setOpen((o) => !o)}
      >
        {open ? <><ChevronUp className="h-3 w-3" />less</> : <><ChevronDown className="h-3 w-3" />more</>}
      </button>
    </span>
  );
}

export default function DQDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const [tab, setTab] = useState<DQDetailTab>("score");
  const [reviewComment, setReviewComment] = useState("");
  const [dimFilter, setDimFilter] = useState<string>("");

  const { data: run, isLoading } = useQuery({
    queryKey: ["dq-run", id],
    queryFn: () =>
      api.get<{
        id: string;
        run_name: string;
        dataset_name: string;
        dataset_location: string;
        status: string;
        total_checks: number;
        passed_checks: number;
        failed_checks: number;
        overall_score: string | null;
        started_at: string | null;
        completed_at: string | null;
        triggered_by: string;
        created_at: string;
        results: DQResultItem[];
        gcp_archive: {
          gcs_report_path: string | null;
          bq_dataset: string | null;
          bq_table: string | null;
          archive_status: string;
          archived_at: string;
          error_message: string | null;
        } | null;
      }>(`/dq/${id}`),
    refetchInterval: (q) => {
      const s = q.state.data?.status;
      return s === "pending" || s === "running" ? 4000 : false;
    },
  });

  const reviewMutation = useMutation({
    mutationFn: (payload: { action: string; comments: string }) => {
      const label = payload.action === "approve" ? "Approving" : payload.action === "reject" ? "Rejecting" : "Requesting revision on";
      toast.loading(`${label} DQ inspection run...`, { id: "dq-review" });
      return api.post(`/dq/${id}/review`, payload);
    },
    onSuccess: (_, variables) => {
      const msg = variables.action === "approve" ? "DQ run approved!" : variables.action === "reject" ? "DQ run rejected." : "Revision requested.";
      toast.success(msg, { id: "dq-review" });
      qc.invalidateQueries({ queryKey: ["dq-run", id] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setReviewComment("");
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to action review", { id: "dq-review" });
    },
  });

  const archiveMutation = useMutation({
    mutationFn: () => api.post(`/dq/${id}/archive`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dq-run", id] }),
  });

  const rerunMutation = useMutation({
    mutationFn: () => api.post<{ id: string }>(`/dq/${id}/rerun`, {}),
    onSuccess: (data) => router.push(`/dq/${data.id}`),
  });

  if (isLoading) return <DetailSkeleton />;
  if (!run) return <div className="text-red-500 py-10 text-center">DQ run not found</div>;

  const score = run.overall_score ? parseFloat(run.overall_score) : null;
  const allFindings = run.results.flatMap((r) => r.findings ?? []);
  const criticalFindings = allFindings.filter((f) => f.severity === "critical");
  const canReview = run.status === "completed" || run.status === "under_review";

  // Group results by column for the Score tab
  const byColumn = run.results.reduce<
    Record<string, Partial<Record<DQDimension, number>>>
  >((acc, r) => {
    if (!r.column_name) return acc;
    acc[r.column_name] = acc[r.column_name] ?? {};
    if (r.actual_value) {
      acc[r.column_name][r.check_type as DQDimension] = parseFloat(r.actual_value);
    }
    return acc;
  }, {});

  // Determine which dimensions are present in this run
  const presentDims = DQ_DIMENSIONS.filter((d) =>
    run.results.some((r) => r.check_type === d)
  );

  // Filtered results for Rules tab
  const filteredResults = dimFilter
    ? run.results.filter((r) => r.check_type === dimFilter)
    : run.results;

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-200">
        <div className="min-w-0">
          <div className="flex items-center gap-2.5 flex-wrap">
            <button
              onClick={() => router.back()}
              className="text-slate-400 hover:text-slate-700 flex items-center gap-1 text-xs font-mono shrink-0"
            >
              <ChevronLeft className="h-3.5 w-3.5" /> Back
            </button>
            <Badge variant={statusVariant(run.status)} className="text-[10px]">
              {run.status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
            </Badge>
          </div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1 truncate">{run.run_name}</h1>
          <p className="text-xs text-slate-500 font-mono">
            {run.dataset_name} · Created {formatDateTime(run.created_at)}
            {run.completed_at && ` · Completed ${formatDateTime(run.completed_at)}`}
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {run.status === "approved" && !run.gcp_archive && (
            <Button size="sm" className="h-7.5 text-xs font-medium" disabled={archiveMutation.isPending} onClick={() => archiveMutation.mutate()}>
              Archive to GCP
            </Button>
          )}
          <Button
            variant="outline"
            size="sm"
            className="h-7.5 text-xs font-medium"
            disabled={rerunMutation.isPending}
            onClick={() => rerunMutation.mutate()}
          >
            Re-run Check
          </Button>
        </div>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          {
            label: "Overall Score",
            value: score !== null ? `${score.toFixed(1)}%` : "—",
            color:
              score !== null
                ? score >= 90
                  ? "text-emerald-700"
                  : score >= 70
                  ? "text-amber-700"
                  : "text-rose-700"
                : "text-slate-400",
          },
          { label: "Total Checks", value: run.total_checks, color: "text-slate-900" },
          { label: "Passed", value: run.passed_checks, color: "text-emerald-700" },
          { label: "Failed", value: run.failed_checks, color: "text-rose-700" },
        ].map((kpi) => (
          <div key={kpi.label} className="bg-white rounded-md border border-slate-200 p-3.5 shadow-2xs">
            <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">{kpi.label}</p>
            <p className={`text-xl font-bold font-mono tabular-nums ${kpi.color}`}>{kpi.value}</p>
          </div>
        ))}
      </div>

      {/* Running indicator */}
      {(run.status === "pending" || run.status === "running") && (
        <div className="bg-slate-50 border border-slate-200 rounded-md p-3 flex items-center gap-3">
          <div className="w-4 h-4 rounded-md border-2 border-slate-300 border-t-slate-900 animate-spin flex-shrink-0" />
          <p className="text-xs text-slate-800 font-mono font-medium">
            {run.status === "pending"
              ? "Run is queued — waiting for worker…"
              : "Running DQ checks — page auto-refreshes…"}
          </p>
        </div>
      )}

      {/* Tabs */}
      <div className="bg-white rounded-md border border-slate-200 shadow-2xs overflow-hidden">
        <div className="flex border-b border-slate-200 bg-slate-50/50 overflow-x-auto">
          {(["score", "rules", "findings", "archive"] as DQDetailTab[]).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-4 py-2.5 text-xs font-mono font-medium capitalize transition-colors border-b-2 -mb-px whitespace-nowrap ${
                tab === t
                  ? "border-slate-900 text-slate-900 bg-white"
                  : "border-transparent text-slate-500 hover:text-slate-800"
              }`}
            >
              {t}
              {t === "findings" && allFindings.length > 0 && (
                <span
                  className={`ml-1.5 text-[10px] px-1.5 py-0.2 rounded-md font-mono ${
                    criticalFindings.length
                      ? "bg-rose-50 text-rose-700 border border-rose-200"
                      : "bg-amber-50 text-amber-700 border border-amber-200"
                  }`}
                >
                  {allFindings.length}
                </span>
              )}
            </button>
          ))}
        </div>

        <div className="p-4">
          {/* Score tab — per-column dimension bars */}
          {tab === "score" && (
            <div className="space-y-4">
              {Object.entries(byColumn).map(([col, checks]) => (
                <div key={col} className="space-y-1.5 p-3 rounded-md border border-slate-100 bg-slate-50/30">
                  <p className="text-xs font-mono font-semibold text-slate-900">{col}</p>
                  <div
                    className={`grid gap-3.5 ${
                      presentDims.length === 4
                        ? "grid-cols-2 lg:grid-cols-4"
                        : presentDims.length === 3
                        ? "grid-cols-3"
                        : "grid-cols-2"
                    }`}
                  >
                    {presentDims.map((dim) => (
                      <div key={dim}>
                        <DimLabel dim={dim} />
                        <ScoreBar value={checks[dim] ?? 0} />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
              {Object.keys(byColumn).length === 0 && (
                <p className="text-slate-400 text-xs text-center py-6 font-mono">No results recorded yet.</p>
              )}
            </div>
          )}

          {/* Rules tab — full results table with business rules & regex */}
          {tab === "rules" && (
            <div>
              {/* Dimension filter */}
              <div className="flex gap-1.5 mb-3.5 flex-wrap">
                <button
                  onClick={() => setDimFilter("")}
                  className={`text-[10px] font-mono px-2.5 py-1 rounded-md border transition-colors ${
                    !dimFilter
                      ? "bg-slate-900 text-white border-slate-900 font-semibold"
                      : "text-slate-600 border-slate-200 hover:bg-slate-50"
                  }`}
                >
                  All
                </button>
                {presentDims.map((d) => (
                  <button
                    key={d}
                    onClick={() => setDimFilter(d)}
                    className={`text-[10px] font-mono px-2.5 py-1 rounded-md border capitalize transition-colors ${
                      dimFilter === d
                        ? "bg-slate-900 text-white border-slate-900 font-semibold"
                        : "text-slate-600 border-slate-200 hover:bg-slate-50"
                    }`}
                  >
                    {d}
                  </button>
                ))}
              </div>

              <div className="overflow-x-auto rounded-md border border-slate-200">
                <table className="min-w-full text-xs divide-y divide-slate-100">
                  <thead className="bg-slate-50 text-[10px] uppercase font-mono text-slate-500 border-b border-slate-200">
                    <tr>
                      <th className="px-3 py-2 text-left">Column</th>
                      <th className="px-3 py-2 text-left">Dimension</th>
                      <th className="px-3 py-2 text-left">Score</th>
                      <th className="px-3 py-2 text-left">Business Rules</th>
                      <th className="px-3 py-2 text-left">Regex Pattern</th>
                      <th className="px-3 py-2 text-left">Model</th>
                      <th className="px-3 py-2 text-left">Regex Version</th>
                      <th className="px-3 py-2 text-left">Complexity</th>
                      <th className="px-3 py-2 text-left">Reasoning</th>
                      <th className="px-3 py-2 text-left">Rows</th>
                      <th className="px-3 py-2 text-left">Failed</th>
                      <th className="px-3 py-2 text-left">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredResults.map((r) => (
                      <tr key={r.id} className="hover:bg-slate-50">
                        <td className="px-3 py-2 font-mono text-xs text-slate-900">{r.column_name ?? "—"}</td>
                        <td className="px-3 py-2 capitalize font-mono text-xs text-slate-700">{r.check_type}</td>
                        <td className="px-3 py-2 font-mono font-semibold tabular-nums text-slate-900">
                          {r.actual_value ? `${parseFloat(r.actual_value).toFixed(1)}%` : "—"}
                        </td>
                        <td className="px-3 py-2 text-slate-600 max-w-xs text-xs">
                          {r.business_rules ? (
                            <ExpandableText text={r.business_rules} />
                          ) : (
                            <span className="text-slate-300 font-mono">—</span>
                          )}
                        </td>
                        <td className="px-3 py-2 font-mono text-xs max-w-xs text-slate-700">
                          {r.regex_pattern ? (
                            <ExpandableText text={r.regex_pattern} maxLen={40} />
                          ) : (
                            <span className="text-slate-300 font-mono">—</span>
                          )}
                        </td>
                        <td className="px-3 py-2 text-xs font-mono text-slate-500">
                          {r.ai_model ?? "—"}
                        </td>
                        <td className="px-3 py-2 text-xs font-mono text-slate-500">
                          {r.regex_version ?? "—"}
                        </td>
                        <td className="px-3 py-2 text-xs font-mono text-slate-500">
                          {r.details?.complexity ? String(r.details.complexity) : "—"}
                        </td>
                        <td className="px-3 py-2 text-slate-600 max-w-xs text-xs">
                          {r.details?.reasoning ? (
                            <ExpandableText text={String(r.details.reasoning)} />
                          ) : (
                            <span className="text-slate-300 font-mono">—</span>
                          )}
                        </td>
                        <td className="px-3 py-2 text-slate-500 font-mono tabular-nums">
                          {r.row_count?.toLocaleString()}
                        </td>
                        <td className="px-3 py-2 text-rose-700 font-mono tabular-nums font-semibold">{r.failed_count ?? 0}</td>
                        <td className="px-3 py-2">
                          <span
                            className={`text-[10px] font-mono font-medium px-2 py-0.5 rounded-md border ${
                              r.status === "pass"
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                : r.status === "fail"
                                ? "bg-rose-50 text-rose-700 border-rose-200"
                                : "bg-amber-50 text-amber-700 border-amber-200"
                            }`}
                          >
                            {r.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Findings tab */}
          {tab === "findings" && (
            <div className="space-y-2.5">
              {allFindings.length === 0 ? (
                <p className="text-slate-400 text-xs text-center py-6 font-mono">No findings — all checks passed ✓</p>
              ) : (
                allFindings.map((f) => (
                  <div
                    key={f.id}
                    className={`p-3 rounded-md border ${
                      f.severity === "critical"
                        ? "bg-rose-50/50 border-rose-200"
                        : "bg-amber-50/50 border-amber-200"
                    }`}
                  >
                    <span
                      className={`text-[10px] font-mono font-bold uppercase tracking-wider ${
                        f.severity === "critical" ? "text-rose-700" : "text-amber-800"
                      }`}
                    >
                      {f.severity}
                    </span>
                    <p className="text-xs text-slate-900 mt-1">{f.description}</p>
                    {f.recommendation && (
                      <p className="text-[11px] text-slate-600 mt-1 font-mono">→ {f.recommendation}</p>
                    )}
                  </div>
                ))
              )}
            </div>
          )}

          {/* Archive tab */}
          {tab === "archive" && (
            <div className="space-y-3">
              {run.gcp_archive ? (
                <div className="space-y-3">
                  <div
                    className={`px-3 py-2 rounded-md border text-xs font-mono font-medium ${
                      run.gcp_archive.archive_status === "completed"
                        ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                        : "bg-amber-50 text-amber-700 border-amber-200"
                    }`}
                  >
                    Archive status: {run.gcp_archive.archive_status}
                  </div>
                  <dl className="grid grid-cols-2 gap-3 text-xs">
                    <div>
                      <dt className="text-slate-500 font-mono">GCS Path</dt>
                      <dd className="font-mono text-slate-900 mt-0.5">{run.gcp_archive.gcs_report_path}</dd>
                    </div>
                    <div>
                      <dt className="text-slate-500 font-mono">BigQuery</dt>
                      <dd className="font-mono text-slate-900 mt-0.5">
                        {run.gcp_archive.bq_dataset}.{run.gcp_archive.bq_table}
                      </dd>
                    </div>
                    <div>
                      <dt className="text-slate-500 font-mono">Archived At</dt>
                      <dd className="font-mono text-slate-900 mt-0.5">{formatDateTime(run.gcp_archive.archived_at)}</dd>
                    </div>
                  </dl>
                  {run.gcp_archive.error_message && (
                    <p className="text-xs text-rose-700 bg-rose-50 border border-rose-200 p-2 rounded-md font-mono">
                      {run.gcp_archive.error_message}
                    </p>
                  )}
                </div>
              ) : run.status === "approved" ? (
                <div className="text-center py-4 space-y-2">
                  <p className="text-slate-600 text-xs font-mono">
                    This run is approved but not yet archived to GCP.
                  </p>
                  <Button
                    size="sm"
                    className="h-7.5 text-xs font-medium"
                    onClick={() => archiveMutation.mutate()}
                    disabled={archiveMutation.isPending}
                  >
                    {archiveMutation.isPending ? "Archiving…" : "Archive to GCP Now"}
                  </Button>
                </div>
              ) : (
                <p className="text-slate-400 text-xs font-mono text-center py-4">
                  Archive is available after the run is approved.
                </p>
              )}
            </div>
          )}
        </div>

        {/* Governance review panel */}
        {canReview && (
          <div className="px-4 pb-4 pt-3 border-t border-slate-200 bg-slate-50/40 space-y-2.5">
            <p className="text-xs font-semibold text-slate-900 font-mono uppercase tracking-wider">Governance Review</p>
            <Input
              placeholder="Review comment (optional)…"
              value={reviewComment}
              onChange={(e) => setReviewComment(e.target.value)}
              className="h-8 text-xs font-mono"
            />
            <div className="flex gap-2 justify-end">
              <Button
                variant="outline"
                size="sm"
                className="h-7 text-xs font-medium"
                disabled={reviewMutation.isPending}
                onClick={() =>
                  reviewMutation.mutate({ action: "request_revision", comments: reviewComment })
                }
              >
                Request Revision
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={reviewMutation.isPending}
                className="h-7 text-xs font-medium text-rose-700 border-rose-200 hover:bg-rose-50"
                onClick={() =>
                  reviewMutation.mutate({ action: "reject", comments: reviewComment })
                }
              >
                Reject
              </Button>
              <Button
                size="sm"
                className="h-7 text-xs font-medium"
                disabled={reviewMutation.isPending}
                onClick={() =>
                  reviewMutation.mutate({ action: "approve", comments: reviewComment })
                }
              >
                Approve
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

type BadgeVariant =
  | "default"
  | "success"
  | "warning"
  | "danger"
  | "neutral"
  | "info";

function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    pending: "default",
    running: "warning",
    completed: "info",
    under_review: "info",
    approved: "success",
    rejected: "danger",
    failed: "danger",
  };
  return map[status] ?? "default";
}
