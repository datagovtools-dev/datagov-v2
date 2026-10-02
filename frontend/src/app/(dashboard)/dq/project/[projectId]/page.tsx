"use client";

// Project DQ report: the latest DQ run with results of every table in a project. The header cards
// combine all tables; the Score tab keeps each table's own attribute scores; Rules/Findings list all.

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, ChevronLeft } from "lucide-react";
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
  scoreColor,
  type DQResultItem,
  type ReportRow,
} from "@/components/dq/DQReportParts";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { formatDateTime } from "@/lib/utils";
import {
  exportDQRulesExcel,
  exportDQRulesPDF,
  type DQRulesExport,
  type ExportOwner,
  type ExportProject,
} from "@/lib/dqExport";

type ReportTab = "score" | "rules" | "findings";

interface ReportRun {
  id: string;
  run_name: string;
  dataset_name: string;
  version: number | null;
  status: string;
  overall_score: string | null;
  completed_at: string | null;
  created_at: string;
  empty_attributes?: string[] | null;
  results: DQResultItem[];
}

interface ProjectReport {
  project_id: string;
  generated_at: string;
  tables: Array<{ dataset_name: string; run: ReportRun; newer_run_status: string | null }>;
  tables_without_results: string[];
}

export default function ProjectDQReportPage() {
  const { projectId } = useParams<{ projectId: string }>();
  const router = useRouter();
  const [tab, setTab] = useState<ReportTab>("score");
  const [dimFilter, setDimFilter] = useState("");
  const [tableFilter, setTableFilter] = useState("");

  const { data: report, isLoading } = useQuery<ProjectReport>({
    queryKey: ["dq-project-report", projectId],
    queryFn: () => api.get(`/dq/project/${projectId}/report`),
  });
  // Project details for the export header (same queries/cache as ProjectInfoStrip)
  const { data: project } = useQuery<ExportProject>({
    queryKey: ["project", projectId],
    queryFn: () => api.get(`/projects/${projectId}`),
  });
  const { data: owners = [] } = useQuery<ExportOwner[]>({
    queryKey: ["metadata-owners", projectId],
    queryFn: () => api.get(`/metadata/owners/${projectId}`),
  });

  if (isLoading) return <DetailSkeleton />;
  if (!report) return <div className="text-red-500 py-10 text-center">Project report not available</div>;

  const tables = report.tables;
  const rowsByTable = tables.map((t) => ({ table: t, rows: reportRows(t.run) }));
  const allRows: ReportRow[] = rowsByTable.flatMap((t) => t.rows);
  const { summaryCards, metricCards } = buildSummaryCards(allRows, { kind: "project", tables: tables.length });
  const presentDims = DQ_DIMENSIONS.filter((d) => allRows.some((row) => row.r.check_type === d));
  const filteredRows = allRows.filter((row) =>
    (!tableFilter || row.table === tableFilter) && (!dimFilter || row.r.check_type === dimFilter));
  const findings = rowsByTable.flatMap(({ table, rows }) =>
    rows.flatMap((row) => (row.r.findings ?? []).map((f) => ({ ...f, table: table.dataset_name, column: row.r.column_name }))));
  const olderRunTables = tables.filter((t) => t.newer_run_status);

  const rulesExport = (): DQRulesExport => {
    const shownTables = tableFilter || `All ${tables.length} tables`;
    const shownDims = dimFilter ? `${dimFilter.charAt(0).toUpperCase()}${dimFilter.slice(1)} only` : "All dimensions";
    const generated = formatDateTime(report.generated_at);
    return {
      title: `Project Data Quality Report — ${project?.project_code ?? ""} ${project?.project_name ?? ""}`.trim(),
      subtitle: `${tables.length} tables (latest run with results per table) · Generated ${generated} · Tables: ${shownTables} · Rules shown: ${shownDims}`,
      infoRows: [
        ["Report", "Project DQ report (latest run with results per table)"],
        ["Tables", tables.map((t) => `${t.dataset_name} (v${t.run.version ?? "—"})`).join(", ")],
        ["Generated", generated],
        ["Tables shown", shownTables],
        ["Rules shown", shownDims],
      ],
      fileBase: `dq_project_report_${project?.project_code ?? "project"}_${new Date().toISOString().slice(0, 10)}`,
      project,
      owners,
      summaryCards,
      metricCards,
      rows: filteredRows.map((row) => exportRuleRow(row, true)),
    };
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-200">
        <div className="min-w-0">
          <button
            onClick={() => router.push(`/dq?project=${projectId}`)}
            className="text-slate-400 hover:text-slate-700 flex items-center gap-1 text-xs font-mono"
          >
            <ChevronLeft className="h-3.5 w-3.5" /> Back to Data Quality
          </button>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1">Project DQ Report</h1>
          <p className="text-xs text-slate-500 font-mono">
            {tables.length} table{tables.length === 1 ? "" : "s"} · latest run with results per table · generated{" "}
            {formatDateTime(report.generated_at)}
          </p>
        </div>
      </div>

      <ProjectInfoStrip projectId={projectId} />

      {/* Notes about what the report includes */}
      {(olderRunTables.length > 0 || report.tables_without_results.length > 0) && (
        <div className="rounded-md border border-amber-200 bg-amber-50 px-3.5 py-2.5 text-xs text-amber-800 space-y-1">
          {olderRunTables.map((t) => (
            <p key={t.dataset_name}>
              <span className="font-mono font-semibold">{t.dataset_name}</span>: the newest run is {t.newer_run_status}, so the
              previous run with results (version {t.run.version ?? "—"}) is used.
            </p>
          ))}
          {report.tables_without_results.length > 0 && (
            <p>
              Not included (no run with results yet):{" "}
              <span className="font-mono">{report.tables_without_results.join(", ")}</span>
            </p>
          )}
        </div>
      )}

      {tables.length === 0 ? (
        <div className="rounded-md border border-slate-200 bg-white p-8 text-center text-sm text-slate-500">
          No table in this project has DQ results yet. Run DQ from the Data Quality page first.
        </div>
      ) : (
        <>
          {/* KPI cards combined over all tables */}
          <KpiRows summaryCards={summaryCards} metricCards={metricCards} />

          {/* Tabs */}
          <div className="bg-white rounded-md border border-slate-200 shadow-2xs overflow-hidden">
            <div className="flex border-b border-slate-200 bg-slate-50/50 overflow-x-auto">
              {(["score", "rules", "findings"] as ReportTab[]).map((t) => (
                <button
                  key={t}
                  onClick={() => setTab(t)}
                  className={`px-4 py-2.5 text-xs font-mono font-medium capitalize transition-colors border-b-2 -mb-px whitespace-nowrap ${
                    tab === t ? "border-slate-900 text-slate-900 bg-white" : "border-transparent text-slate-500 hover:text-slate-800"
                  }`}
                >
                  {t}
                  {t === "findings" && findings.length > 0 && (
                    <span className="ml-1.5 text-[10px] px-1.5 py-0.2 rounded-md font-mono bg-amber-50 text-amber-700 border border-amber-200">
                      {findings.length}
                    </span>
                  )}
                </button>
              ))}
            </div>

            <div className="p-4">
              {/* Score tab: each table's own attribute scores */}
              {tab === "score" && (
                <div className="space-y-6">
                  <ScoreLegend />
                  {rowsByTable.map(({ table, rows }) => {
                    const score = table.run.overall_score ? parseFloat(table.run.overall_score) : null;
                    return (
                      <section key={table.run.id} className="space-y-3">
                        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-200 pb-2">
                          <div>
                            <h3 className="text-sm font-semibold font-mono text-slate-900">{table.dataset_name}</h3>
                            <p className="text-[11px] text-slate-500 font-mono">
                              Version {table.run.version ?? "—"} · {rows.length} checks · completed{" "}
                              {table.run.completed_at ? formatDateTime(table.run.completed_at) : "—"}
                            </p>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className={`text-sm font-bold font-mono ${scoreColor(score)}`}>
                              {score !== null ? `${score.toFixed(1)}%` : "—"}
                            </span>
                            <button
                              onClick={() => router.push(`/dq/${table.run.id}`)}
                              className="text-xs text-slate-700 hover:text-slate-900 inline-flex items-center gap-1"
                            >
                              Open run <ArrowRight className="h-3 w-3" />
                            </button>
                          </div>
                        </div>
                        <AttributeScores rows={rows} />
                      </section>
                    );
                  })}
                </div>
              )}

              {/* Rules tab: all tables in one list, with table and dimension filters */}
              {tab === "rules" && (
                <div>
                  <div className="flex flex-wrap items-start justify-between gap-3 mb-3.5">
                    <div className="flex flex-wrap items-center gap-3">
                      <select
                        value={tableFilter}
                        onChange={(e) => setTableFilter(e.target.value)}
                        className="border border-slate-200 rounded-md px-2 py-1 text-[11px] font-mono bg-white text-slate-800"
                      >
                        <option value="">All tables ({tables.length})</option>
                        {tables.map((t) => <option key={t.run.id} value={t.dataset_name}>{t.dataset_name}</option>)}
                      </select>
                      <DimensionChips dims={presentDims} value={dimFilter} onChange={setDimFilter} />
                    </div>
                    <ExportMenu
                      disabled={filteredRows.length === 0}
                      title="Exports the rules shown (selected tables and dimension) with the project info and combined score cards"
                      onExcel={() => exportDQRulesExcel(rulesExport())}
                      onPdf={() => exportDQRulesPDF(rulesExport())}
                    />
                  </div>
                  <RulesTable rows={filteredRows} showTable />
                </div>
              )}

              {/* Findings tab: all tables */}
              {tab === "findings" && (
                <div className="space-y-2.5">
                  {findings.length === 0 ? (
                    <p className="text-slate-400 text-xs text-center py-6 font-mono">No findings — all checks passed ✓</p>
                  ) : (
                    findings.map((f) => (
                      <div
                        key={f.id}
                        className={`p-3 rounded-md border ${f.severity === "critical" ? "bg-rose-50/50 border-rose-200" : "bg-amber-50/50 border-amber-200"}`}
                      >
                        <div className="flex flex-wrap items-center gap-2">
                          <span className={`text-[10px] font-mono font-bold uppercase tracking-wider ${f.severity === "critical" ? "text-rose-700" : "text-amber-800"}`}>
                            {f.severity}
                          </span>
                          <span className="text-[10px] font-mono text-slate-500">{f.table}{f.column ? ` · ${f.column}` : ""}</span>
                        </div>
                        <p className="text-xs text-slate-900 mt-1">{f.description}</p>
                        {f.recommendation && <p className="text-[11px] text-slate-600 mt-1 font-mono">→ {f.recommendation}</p>}
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
