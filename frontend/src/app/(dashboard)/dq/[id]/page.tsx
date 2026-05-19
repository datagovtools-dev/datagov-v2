"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronLeft } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { formatDate, formatDateTime } from "@/lib/utils";

type DQDetailTab = "score" | "rules" | "findings" | "archive";

function ScoreBar({ value }: { value: number }) {
  const color = value >= 90 ? "bg-green-500" : value >= 70 ? "bg-yellow-500" : "bg-red-500";
  return (
    <div className="flex items-center gap-3">
      <div className="flex-1 bg-gray-100 rounded-full h-3 overflow-hidden">
        <div className={`h-full rounded-full transition-all ${color}`} style={{ width: `${value}%` }} />
      </div>
      <span className={`text-sm font-bold w-14 text-right ${value >= 90 ? "text-green-600" : value >= 70 ? "text-yellow-600" : "text-red-600"}`}>
        {value.toFixed(1)}%
      </span>
    </div>
  );
}

export default function DQDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const [tab, setTab] = useState<DQDetailTab>("score");
  const [reviewComment, setReviewComment] = useState("");

  const { data: run, isLoading } = useQuery({
    queryKey: ["dq-run", id],
    queryFn: () => api.get<{
      id: string; run_name: string; dataset_name: string; dataset_location: string;
      status: string; total_checks: number; passed_checks: number; failed_checks: number;
      overall_score: string | null; started_at: string | null; completed_at: string | null;
      triggered_by: string; created_at: string;
      results: Array<{
        id: string; check_name: string; check_type: string; column_name: string | null;
        status: string; actual_value: string | null; row_count: number | null;
        failed_count: number | null; details: Record<string, unknown> | null;
        findings: Array<{ id: string; severity: string; description: string; recommendation: string | null; status: string }>;
      }>;
      gcp_archive: {
        gcs_report_path: string | null; bq_dataset: string | null; bq_table: string | null;
        archive_status: string; archived_at: string; error_message: string | null;
      } | null;
    }>(`/dq/${id}`),
    refetchInterval: (q) => {
      const s = q.state.data?.status;
      return s === "pending" || s === "running" ? 4000 : false;
    },
  });

  const reviewMutation = useMutation({
    mutationFn: (payload: { action: string; comments: string }) => api.post(`/dq/${id}/review`, payload),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["dq-run", id] }); setReviewComment(""); },
  });

  const archiveMutation = useMutation({
    mutationFn: () => api.post(`/dq/${id}/archive`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dq-run", id] }),
  });

  const rerunMutation = useMutation({
    mutationFn: () => api.post<{ id: string }>(`/dq/${id}/rerun`, {}),
    onSuccess: (data) => router.push(`/dq/${data.id}`),
  });

  if (isLoading) return <div className="text-surface-400 py-10 text-center">Loading…</div>;
  if (!run) return <div className="text-red-500 py-10 text-center">DQ run not found</div>;

  const score = run.overall_score ? parseFloat(run.overall_score) : null;
  const allFindings = run.results.flatMap((r) => r.findings ?? []);
  const criticalFindings = allFindings.filter((f) => f.severity === "critical");
  const canReview = run.status === "completed" || run.status === "under_review";

  // Group results by check_type for Score tab
  const byColumn = run.results.reduce<Record<string, { completeness?: number; uniqueness?: number; consistency?: number }>>((acc, r) => {
    if (!r.column_name) return acc;
    acc[r.column_name] = acc[r.column_name] ?? {};
    if (r.actual_value) {
      acc[r.column_name][r.check_type as "completeness" | "uniqueness" | "consistency"] = parseFloat(r.actual_value);
    }
    return acc;
  }, {});

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="flex items-center gap-3 flex-wrap">
            <button onClick={() => router.back()} className="text-surface-400 hover:text-surface-600 flex items-center gap-1 text-sm shrink-0">
              <ChevronLeft className="h-4 w-4" /> Back
            </button>
            <Badge variant={statusVariant(run.status)}>{run.status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}</Badge>
          </div>
          <h1 className="text-xl font-bold text-surface-800 mt-0.5 truncate">{run.run_name}</h1>
          <p className="text-sm text-surface-500">
            {run.dataset_name} · Created {formatDateTime(run.created_at)}
            {run.completed_at && ` · Completed ${formatDateTime(run.completed_at)}`}
          </p>
        </div>
        <div className="flex gap-2 shrink-0">
          {run.status === "approved" && !run.gcp_archive && (
            <Button size="sm" disabled={archiveMutation.isPending} onClick={() => archiveMutation.mutate()}>
              Archive to GCP
            </Button>
          )}
          <Button variant="outline" size="sm" disabled={rerunMutation.isPending} onClick={() => rerunMutation.mutate()}>
            Re-run
          </Button>
        </div>
      </div>

      {/* KPI cards */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: "Overall Score", value: score !== null ? `${score.toFixed(1)}%` : "—", color: score !== null ? (score >= 90 ? "text-green-600" : score >= 70 ? "text-yellow-600" : "text-red-600") : "text-surface-400" },
          { label: "Total Checks", value: run.total_checks, color: "text-surface-800" },
          { label: "Passed", value: run.passed_checks, color: "text-green-600" },
          { label: "Failed", value: run.failed_checks, color: "text-red-500" },
        ].map((kpi) => (
          <div key={kpi.label} className="bg-white rounded-xl border border-surface-200 p-4">
            <p className="text-xs text-surface-400 mb-1">{kpi.label}</p>
            <p className={`text-2xl font-bold ${kpi.color}`}>{kpi.value}</p>
          </div>
        ))}
      </div>

      {/* Status alert for running */}
      {(run.status === "pending" || run.status === "running") && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-center gap-3">
          <div className="w-5 h-5 rounded-full border-2 border-blue-300 border-t-blue-600 animate-spin flex-shrink-0" />
          <p className="text-sm text-blue-800 font-medium">
            {run.status === "pending" ? "Run is queued — waiting for worker…" : "Running DQ checks — page auto-refreshes…"}
          </p>
        </div>
      )}

      {/* Tabs */}
      <div className="bg-white rounded-xl border border-surface-200 overflow-hidden">
        <div className="flex border-b border-surface-100">
          {(["score", "rules", "findings", "archive"] as DQDetailTab[]).map((t) => (
            <button key={t} onClick={() => setTab(t)}
              className={`px-5 py-3 text-sm font-medium capitalize transition-colors border-b-2 -mb-px ${
                tab === t ? "border-primary-500 text-primary-600" : "border-transparent text-surface-500 hover:text-surface-700"
              }`}>
              {t}
              {t === "findings" && allFindings.length > 0 && (
                <span className={`ml-1 text-xs px-1.5 py-0.5 rounded-full ${criticalFindings.length ? "bg-red-100 text-red-600" : "bg-yellow-100 text-yellow-700"}`}>
                  {allFindings.length}
                </span>
              )}
            </button>
          ))}
        </div>

        <div className="p-5">
          {/* Score tab — per-column bar chart */}
          {tab === "score" && (
            <div className="space-y-4">
              {Object.entries(byColumn).map(([col, checks]) => (
                <div key={col} className="space-y-1">
                  <p className="text-sm font-mono font-medium text-gray-700">{col}</p>
                  <div className="grid grid-cols-3 gap-4">
                    {(["completeness", "uniqueness", "consistency"] as const).map((ct) => (
                      <div key={ct}>
                        <p className="text-xs text-gray-400 capitalize mb-1">{ct}</p>
                        <ScoreBar value={checks[ct] ?? 0} />
                      </div>
                    ))}
                  </div>
                </div>
              ))}
              {Object.keys(byColumn).length === 0 && <p className="text-gray-400 text-center py-4">No results yet</p>}
            </div>
          )}

          {/* Rules tab — full results table */}
          {tab === "rules" && (
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm divide-y divide-surface-100">
                <thead className="bg-surface-50 text-xs uppercase text-surface-500">
                  <tr>
                    <th className="px-3 py-2 text-left">Column</th>
                    <th className="px-3 py-2 text-left">Check Type</th>
                    <th className="px-3 py-2 text-left">Score</th>
                    <th className="px-3 py-2 text-left">Rows</th>
                    <th className="px-3 py-2 text-left">Failed</th>
                    <th className="px-3 py-2 text-left">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-50">
                  {run.results.map((r) => (
                    <tr key={r.id} className="hover:bg-surface-50">
                      <td className="px-3 py-2 font-mono text-xs">{r.column_name ?? "—"}</td>
                      <td className="px-3 py-2 capitalize text-surface-700">{r.check_type}</td>
                      <td className="px-3 py-2 font-semibold">{r.actual_value ? `${parseFloat(r.actual_value).toFixed(1)}%` : "—"}</td>
                      <td className="px-3 py-2 text-surface-500">{r.row_count?.toLocaleString()}</td>
                      <td className="px-3 py-2 text-red-500">{r.failed_count ?? 0}</td>
                      <td className="px-3 py-2">
                        <span className={`text-xs font-medium px-2 py-0.5 rounded ${
                          r.status === "pass" ? "bg-green-100 text-green-700" :
                          r.status === "fail" ? "bg-red-100 text-red-700" : "bg-yellow-100 text-yellow-700"
                        }`}>{r.status}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Findings tab */}
          {tab === "findings" && (
            <div className="space-y-3">
              {allFindings.length === 0 ? (
                <p className="text-gray-400 text-center py-6">No findings — all checks passed ✓</p>
              ) : allFindings.map((f) => (
                <div key={f.id} className={`p-3 rounded-lg border-l-4 ${
                  f.severity === "critical" ? "bg-red-50 border-red-500" : "bg-yellow-50 border-yellow-400"
                }`}>
                  <span className={`text-xs font-bold uppercase ${f.severity === "critical" ? "text-red-600" : "text-yellow-700"}`}>
                    {f.severity}
                  </span>
                  <p className="text-sm text-gray-800 mt-0.5">{f.description}</p>
                  {f.recommendation && <p className="text-xs text-gray-600 mt-1">→ {f.recommendation}</p>}
                </div>
              ))}
            </div>
          )}

          {/* Archive tab */}
          {tab === "archive" && (
            <div className="space-y-4">
              {run.gcp_archive ? (
                <div className="space-y-3">
                  <div className={`px-3 py-2 rounded text-sm font-medium ${
                    run.gcp_archive.archive_status === "completed" ? "bg-green-50 text-green-700" : "bg-yellow-50 text-yellow-700"
                  }`}>
                    Archive status: {run.gcp_archive.archive_status}
                  </div>
                  <dl className="grid grid-cols-2 gap-3 text-sm">
                    <div><dt className="text-gray-500">GCS Path</dt><dd className="font-mono text-xs mt-0.5">{run.gcp_archive.gcs_report_path}</dd></div>
                    <div><dt className="text-gray-500">BigQuery</dt><dd className="font-mono text-xs mt-0.5">{run.gcp_archive.bq_dataset}.{run.gcp_archive.bq_table}</dd></div>
                    <div><dt className="text-gray-500">Archived At</dt><dd className="mt-0.5">{formatDateTime(run.gcp_archive.archived_at)}</dd></div>
                  </dl>
                  {run.gcp_archive.error_message && (
                    <p className="text-sm text-red-600 bg-red-50 p-2 rounded">{run.gcp_archive.error_message}</p>
                  )}
                </div>
              ) : run.status === "approved" ? (
                <div className="text-center py-4 space-y-3">
                  <p className="text-gray-600 text-sm">This run is approved but not yet archived to GCP.</p>
                  <Button onClick={() => archiveMutation.mutate()} disabled={archiveMutation.isPending}>
                    {archiveMutation.isPending ? "Archiving…" : "Archive to GCP Now"}
                  </Button>
                </div>
              ) : (
                <p className="text-gray-400 text-center py-4">Archive is available after the run is approved.</p>
              )}
            </div>
          )}
        </div>

        {/* Review panel at bottom of card — only when reviewable */}
        {canReview && (
          <div className="px-5 pb-5 pt-3 border-t border-surface-100 space-y-3">
            <p className="text-sm font-medium text-surface-700">Governance Review</p>
            <Input placeholder="Review comment (optional)…" value={reviewComment}
              onChange={(e) => setReviewComment(e.target.value)} />
            <div className="flex gap-2 justify-end">
              <Button variant="outline" size="sm" disabled={reviewMutation.isPending}
                onClick={() => reviewMutation.mutate({ action: "request_revision", comments: reviewComment })}>
                Request Revision
              </Button>
              <Button variant="outline" size="sm" disabled={reviewMutation.isPending}
                className="text-red-700 border-red-300 hover:bg-red-50"
                onClick={() => reviewMutation.mutate({ action: "reject", comments: reviewComment })}>
                Reject
              </Button>
              <Button size="sm" disabled={reviewMutation.isPending}
                onClick={() => reviewMutation.mutate({ action: "approve", comments: reviewComment })}>
                Approve
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    pending: "default", running: "warning", completed: "in-review",
    under_review: "in-review", approved: "approved", rejected: "rejected", failed: "danger",
  };
  return map[status] ?? "default";
}
