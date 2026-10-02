"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronLeft } from "lucide-react";
import { api } from "@/lib/api";
import { ProjectInfoStrip } from "@/components/details/ProjectInfoStrip";
import {
  AttributeScores,
  buildSummaryCards,
  DimensionChips,
  DQ_DIMENSIONS,
  ExportMenu,
  exportRuleRow,
  KpiRows,
  reportRows,
  RulesTable,
  ScoreLegend,
  type DQResultItem,
} from "@/components/dq/DQReportParts";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { formatDate, formatDateTime } from "@/lib/utils";
import {
  exportDQRulesExcel,
  exportDQRulesPDF,
  fileNamePart,
  type DQRulesExport,
  type ExportOwner,
  type ExportProject,
} from "@/lib/dqExport";

type DQDetailTab = "score" | "rules" | "findings" | "archive";

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
        project_id: string;
        run_name: string;
        dataset_name: string;
        dataset_location: string;
        version: number | null;
        status: string;
        total_checks: number;
        passed_checks: number;
        failed_checks: number;
        overall_score: string | null;
        started_at: string | null;
        completed_at: string | null;
        triggered_by: string;
        created_at: string;
        empty_attributes?: string[] | null;
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
    mutationFn: () => api.post<{ id: string; version: number; project_id: string }>(`/dq/${id}/rerun`, {}),
    // The new version runs in the background; this version stays visible (Data Quality table, Project Report)
    // until it finishes, and the progress page shows its countdown
    onSuccess: (data) => {
      toast.success(`Version ${data.version} queued. Scores stay on this version until it finishes.`, { id: "dq-rerun" });
      router.push(`/dq/progress/${data.project_id}`);
    },
    onError: (e: any) => {
      toast.error(e.message || "Could not start the re-run", { id: "dq-rerun" });
    },
  });

  // Project details for the export header (same queries/cache as ProjectInfoStrip)
  const { data: project } = useQuery<ExportProject>({
    queryKey: ["project", run?.project_id],
    queryFn: () => api.get(`/projects/${run!.project_id}`),
    enabled: !!run?.project_id,
  });
  const { data: owners = [] } = useQuery<ExportOwner[]>({
    queryKey: ["metadata-owners", run?.project_id],
    queryFn: () => api.get(`/metadata/owners/${run!.project_id}`),
    enabled: !!run?.project_id,
  });

  if (isLoading) return <DetailSkeleton />;
  if (!run) return <div className="text-red-500 py-10 text-center">DQ run not found</div>;

  const score = run.overall_score ? parseFloat(run.overall_score) : null;
  const allFindings = run.results.flatMap((r) => r.findings ?? []);
  const criticalFindings = allFindings.filter((f) => f.severity === "critical");
  const canReview = run.status === "completed" || run.status === "under_review";

  // Checks with their table and blank-attribute flag, and the KPI cards (shared with the project report)
  const rows = reportRows(run);
  const { summaryCards, metricCards } = buildSummaryCards(rows, { kind: "file" }, score);

  // Dimensions present in this run (Rules tab filter chips)
  const presentDims = DQ_DIMENSIONS.filter((d) => run.results.some((r) => r.check_type === d));

  // Filtered rows for the Rules tab
  const filteredRows = dimFilter ? rows.filter((row) => row.r.check_type === dimFilter) : rows;

  // Rules tab export: the rows shown (same values as the table) plus the page header
  const rulesExport = (): DQRulesExport => {
    const version = run.version != null ? String(run.version) : "—";
    const shown = dimFilter ? `${dimFilter.charAt(0).toUpperCase()}${dimFilter.slice(1)} only` : "All dimensions";
    const created = formatDateTime(run.created_at);
    const completed = run.completed_at ? formatDateTime(run.completed_at) : "—";
    return {
      title: `Data Quality Rules Report — ${run.run_name}`,
      subtitle: `${run.dataset_name} · Version ${version} · ${run.status.replace(/_/g, " ")} · Created ${created}`
        + `${run.completed_at ? ` · Completed ${completed}` : ""} · Rules shown: ${shown}`,
      infoRows: [
        ["Run", run.run_name], ["Dataset", run.dataset_name], ["Version", version],
        ["Status", run.status.replace(/_/g, " ")], ["Created", created], ["Completed", completed], ["Rules shown", shown],
      ],
      fileBase: `dq_rules_${project?.project_code ?? "project"}_${fileNamePart(run.dataset_name)}_v${version}_${new Date().toISOString().slice(0, 10)}`,
      project,
      owners,
      summaryCards,
      metricCards,
      rows: filteredRows.map((row) => exportRuleRow(row)),
    };
  };
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

      {/* Project info strip — shown above the KPI cards for every tab */}
      <ProjectInfoStrip projectId={run.project_id} />

      {/* KPI cards: run summary, then average score per metric (N/A when the metric was not run) */}
      <KpiRows summaryCards={summaryCards} metricCards={metricCards} />

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
              {rows.length > 0 && <ScoreLegend />}
              <AttributeScores rows={rows} />
            </div>
          )}

          {/* Rules tab — full results table with business rules & regex */}
          {tab === "rules" && (
            <div>
              {/* Dimension filter + export (exports the rows shown, with the page header) */}
              <div className="flex items-start justify-between gap-3 mb-3.5">
              <DimensionChips dims={presentDims} value={dimFilter} onChange={setDimFilter} />
                <ExportMenu
                  disabled={filteredRows.length === 0}
                  title="Exports the rules shown (all or the selected dimension) with the project info and score cards"
                  onExcel={() => exportDQRulesExcel(rulesExport())}
                  onPdf={() => exportDQRulesPDF(rulesExport())}
                />
              </div>

              <RulesTable rows={filteredRows} />
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
