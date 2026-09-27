"use client";

// Shared building blocks of the DQ run page and the project DQ report: KPI cards, per-attribute
// score bars, the rules table, and the summary numbers behind the cards.

import { useState } from "react";
import { ChevronDown, ChevronUp, Download } from "lucide-react";
import { Button } from "@/components/ui/Button";
import type { ExportRuleRow } from "@/lib/dqExport";

export interface DQResultItem {
  id: string;
  check_name: string;
  check_type: string;
  column_name: string | null;
  data_type: string | null;
  status: string;
  actual_value: string | null;
  row_count: number | null;
  failed_count: number | null;
  details: Record<string, unknown> | null;
  business_rules: string | null;
  regex_pattern: string | null;
  regex_version: string | null;
  remarks: string | null;
  findings: Array<{
    id: string;
    severity: string;
    description: string;
    recommendation: string | null;
    status: string;
  }>;
}

// One check (result row) with the table it belongs to; `blank` = its attribute has no values at all
export interface ReportRow {
  r: DQResultItem;
  table: string;
  version: number | null;
  blank: boolean;
}

export const DQ_DIMENSIONS = ["completeness", "consistency", "uniqueness", "latency"] as const;
export type DQDimension = (typeof DQ_DIMENSIONS)[number];

// Why a metric can be missing for an attribute (the reference method only creates some rules conditionally)
const NOT_APPLICABLE_REASON: Record<DQDimension, string> = {
  completeness: "Completeness was not calculated for this attribute",
  consistency: "Consistency was not calculated for this attribute",
  uniqueness: "Uniqueness is only checked when every value in the column is different",
  latency: "Latency is only checked for date/time columns",
};

// Blank slot for a metric that was not run, so it is not mistaken for a 0% score
export function NotApplicableBar({ dim }: { dim: DQDimension }) {
  return (
    <div className="flex items-center gap-2" title={NOT_APPLICABLE_REASON[dim]}>
      <div className="flex-1 h-2 rounded-md border border-dashed border-slate-200" />
      <span className="text-[10px] font-mono text-slate-400 w-12 text-right whitespace-nowrap">N/A</span>
    </div>
  );
}

export function scoreColor(value: number | null): string {
  if (value === null) return "text-slate-400";
  return value >= 90 ? "text-emerald-700" : value >= 70 ? "text-amber-700" : "text-rose-700";
}

export interface KpiCardData { label: string; value: string; color: string; hint: string }

export function KpiCard({ label, value, color, hint }: KpiCardData) {
  return (
    <div className="bg-white rounded-md border border-slate-200 p-3.5 shadow-2xs">
      <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">{label}</p>
      <p className={`text-xl font-bold font-mono tabular-nums ${color}`}>{value}</p>
      <p className="text-[11px] text-slate-500 leading-snug mt-1">{hint}</p>
    </div>
  );
}

// The two rows of KPI cards
export function KpiRows({ summaryCards, metricCards }: { summaryCards: KpiCardData[]; metricCards: KpiCardData[] }) {
  return (
    <>
      {[summaryCards, metricCards].map((cards, row) => (
        <div key={row} className="grid grid-cols-2 sm:grid-cols-5 gap-3">
          {cards.map((card) => <KpiCard key={card.label} {...card} />)}
        </div>
      ))}
    </>
  );
}

// Short explanation of each metric card; `n` = number of attributes with that metric
const METRIC_HINT: Record<DQDimension, { scored: (n: number) => string; none: string }> = {
  completeness: {
    scored: (n) => `Average share of filled (non-empty) values, over ${n} attribute${n === 1 ? "" : "s"}.`,
    none: "No completeness check here.",
  },
  consistency: {
    scored: (n) => `Average share of values matching the expected format (regex), over ${n} attribute${n === 1 ? "" : "s"}.`,
    none: "No consistency check here.",
  },
  uniqueness: {
    scored: (n) => `Checked for ${n} attribute${n === 1 ? "" : "s"} where every value is different (e.g. IDs).`,
    none: "No attribute has all-different values, so uniqueness was not checked.",
  },
  latency: {
    scored: (n) => `How recent the latest date is (100 = today, 0 = over 30 days old), over ${n} date column${n === 1 ? "" : "s"}.`,
    none: "No date/time column here, so latency was not checked.",
  },
};

export function ScoreBar({ value }: { value: number }) {
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

export function DimLabel({ dim }: { dim: string }) {
  const labels: Record<string, string> = {
    completeness: "Completeness",
    consistency: "Consistency",
    uniqueness: "Uniqueness",
    latency: "Latency",
  };
  return <span className="text-[10px] font-mono text-slate-500 uppercase tracking-wider block mb-1">{labels[dim] ?? dim}</span>;
}

export function ExpandableText({ text, maxLen = 80 }: { text: string; maxLen?: number }) {
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

// ── Summary numbers ──────────────────────────────────────────────────────────────

/** Attributes of a run with no values: stored by newer runs, else Completeness = 0% (every row empty). */
export function runBlankAttributes(run: { empty_attributes?: string[] | null; results: DQResultItem[] }): string[] {
  return run.empty_attributes
    ?? run.results
      .filter((r) => r.check_type === "completeness" && (r.row_count ?? 0) > 0 && r.actual_value != null
        && parseFloat(r.actual_value) === 0)
      .map((r) => r.column_name as string);
}

/** Result rows of a run, with its table name and blank-attribute flag. */
export function reportRows(
  run: { dataset_name: string; version: number | null; empty_attributes?: string[] | null; results: DQResultItem[] },
): ReportRow[] {
  const blank = new Set(runBlankAttributes(run));
  return run.results.map((r) => ({
    r, table: run.dataset_name, version: run.version, blank: !!r.column_name && blank.has(r.column_name),
  }));
}

/** Status shown for a check: 'no_data' for an attribute with no values (older runs stored those as fail). */
export function rowStatus(row: ReportRow): string {
  return row.blank ? "no_data" : row.r.status;
}

function scoreOf(r: DQResultItem): number | null {
  if (r.actual_value == null || r.actual_value === "") return null;
  const v = parseFloat(r.actual_value);
  return Number.isNaN(v) ? null : v;
}

/**
 * The two rows of KPI cards. `scope` words the explanations for one file or a whole project;
 * `overallScore` defaults to the average of all check scores (as stored for a single run).
 */
export function buildSummaryCards(
  rows: ReportRow[],
  scope: { kind: "file" } | { kind: "project"; tables: number },
  overallScore?: number | null,
): { summaryCards: KpiCardData[]; metricCards: KpiCardData[] } {
  const multi = scope.kind === "project";
  const attrKey = (row: ReportRow) => `${row.table}::${row.r.column_name}`;
  const attributes = new Set(rows.filter((row) => row.r.column_name).map(attrKey));
  const blankAttrs = [...new Set(rows.filter((row) => row.blank).map(attrKey))];
  const blankNames = blankAttrs.map((k) => {
    const [table, column] = k.split("::");
    return multi ? `${column} (${table})` : column;
  });
  const count = (s: string) => rows.filter((row) => rowStatus(row) === s).length;
  const passed = count("pass");
  const warning = count("warning");
  const failed = count("fail");
  const blankChecks = count("no_data");
  const where = multi
    ? `the ${attributes.size} attributes (columns) in the ${scope.tables} table${scope.tables === 1 ? "" : "s"} of this project`
    : `the ${attributes.size} attributes (columns) in this file`;
  const inWhere = multi ? "in these tables" : "in this file";

  const scores = rows.map((row) => scoreOf(row.r)).filter((v): v is number => v !== null);
  const overall = overallScore !== undefined
    ? overallScore
    : scores.length ? scores.reduce((a, b) => a + b, 0) / scores.length : null;
  const listed = `${blankNames.slice(0, 3).join(", ")}${blankNames.length > 3 ? ` and ${blankNames.length - 3} more` : ""}`;

  const summaryCards: KpiCardData[] = [
    {
      label: "Total Metric Checks",
      value: String(rows.length),
      color: "text-slate-900",
      hint: `Up to 4 metric checks per attribute, for ${where}: ${passed} passed + ${warning} warning + ${failed} failed + ${blankChecks} on blank attributes.`,
    },
    { label: "Passed Checks", value: String(passed), color: "text-emerald-700", hint: "Metric checks scoring 95% or higher: no action needed." },
    { label: "Warning Checks", value: String(warning), color: "text-amber-700", hint: "Metric checks scoring 70% to below 95%: acceptable, but worth a review." },
    { label: "Failed Checks", value: String(failed), color: "text-rose-700", hint: "Metric checks on real values scoring below 70% (a 0% here means wrong format or stale dates): listed in Findings." },
    {
      label: "Blank Attributes",
      value: `${blankAttrs.length} / ${attributes.size}`,
      color: blankAttrs.length ? "text-rose-700" : "text-slate-900",
      hint: blankAttrs.length === 0
        ? `Columns ${inWhere} with no values at all (blank, null, spaces, 'NULL', 'N/A'). None here: every column has data.`
        : `Columns ${inWhere} with no values at all (blank, null, spaces, 'NULL', 'N/A'): ${listed}. Their ${blankChecks} metric check${blankChecks === 1 ? "" : "s"} show as "no data".`,
    },
  ];

  const metricCards: KpiCardData[] = [
    {
      label: "Overall Score",
      value: overall !== null ? `${overall.toFixed(1)}%` : "—",
      color: scoreColor(overall),
      hint: `Average score of all ${rows.length} checks, across every metric and attribute${multi ? " of all tables" : ""} (blank/null checks count as 0%).`,
    },
    ...DQ_DIMENSIONS.map((dim) => {
      const values = rows.filter((row) => row.r.check_type === dim).map((row) => scoreOf(row.r)).filter((v): v is number => v !== null);
      const average = values.length ? values.reduce((a, b) => a + b, 0) / values.length : null;
      return {
        label: `${dim.charAt(0).toUpperCase()}${dim.slice(1)} Score`,
        value: average !== null ? `${average.toFixed(1)}%` : "N/A",
        color: scoreColor(average),
        hint: average !== null ? METRIC_HINT[dim].scored(values.length) : METRIC_HINT[dim].none,
      };
    }),
  ];
  return { summaryCards, metricCards };
}

// ── Score tab: one card per attribute with the 4 metric slots ────────────────────

export function ScoreLegend() {
  return (
    <p className="text-[11px] text-slate-500">
      <span className="font-mono text-slate-400">N/A</span> = metric not run for this attribute
      (Uniqueness only for columns where every value is different; Latency only for date/time columns).{" "}
      <span className="font-mono text-slate-400">No data</span> = the attribute has no values at all.
      Hover a blank bar for the reason.
    </p>
  );
}

/** Per-attribute score bars for the rows of ONE table. */
export function AttributeScores({ rows }: { rows: ReportRow[] }) {
  const byColumn = new Map<string, { blank: boolean; scores: Partial<Record<DQDimension, number | null>> }>();
  for (const row of rows) {
    if (!row.r.column_name) continue;
    const entry = byColumn.get(row.r.column_name) ?? { blank: row.blank, scores: {} };
    entry.scores[row.r.check_type as DQDimension] = scoreOf(row.r);
    byColumn.set(row.r.column_name, entry);
  }
  if (byColumn.size === 0) {
    return <p className="text-slate-400 text-xs text-center py-6 font-mono">No results recorded yet.</p>;
  }
  return (
    <div className="space-y-4">
      {[...byColumn.entries()].map(([col, { blank, scores }]) => (
        <div key={col} className="space-y-1.5 p-3 rounded-md border border-slate-100 bg-slate-50/30">
          <p className="text-xs font-mono font-semibold text-slate-900">
            {col}
            {blank && (
              <span className="ml-2 text-[10px] font-medium px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 border border-slate-200">
                no data — all values empty
              </span>
            )}
          </p>
          <div className="grid gap-3.5 grid-cols-2 lg:grid-cols-4">
            {DQ_DIMENSIONS.map((dim) => {
              const value = scores[dim];
              return (
                <div key={dim} className={value === undefined || blank ? "opacity-70" : undefined}>
                  <DimLabel dim={dim} />
                  {value === undefined ? (
                    <NotApplicableBar dim={dim} />
                  ) : blank ? (
                    <div className="flex items-center gap-2" title="This attribute has no values (blank, null, spaces, 'NULL', 'N/A'), so the check has nothing to measure">
                      <div className="flex-1 h-2 rounded-md bg-slate-200" />
                      <span className="text-[10px] font-mono text-slate-500 w-12 text-right whitespace-nowrap">No data</span>
                    </div>
                  ) : value === null ? (
                    <div className="flex items-center gap-2" title="The rule was generated but has no score">
                      <div className="flex-1 h-2 rounded-md bg-slate-100" />
                      <span className="text-[10px] font-mono text-slate-400 w-12 text-right">No score</span>
                    </div>
                  ) : (
                    <ScoreBar value={value} />
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Rules tab ───────────────────────────────────────────────────────────────────

export function StatusBadge({ row }: { row: ReportRow }) {
  const s = rowStatus(row);
  return (
    <span
      className={`text-[10px] font-mono font-medium px-2 py-0.5 rounded-md border whitespace-nowrap ${
        s === "pass"
          ? "bg-emerald-50 text-emerald-700 border-emerald-200"
          : s === "fail"
          ? "bg-rose-50 text-rose-700 border-rose-200"
          : s === "no_data"
          ? "bg-slate-100 text-slate-500 border-slate-200"
          : "bg-amber-50 text-amber-700 border-amber-200"
      }`}
      title={s === "no_data" ? "This attribute has no values (blank, null, spaces, 'NULL', 'N/A')" : undefined}
    >
      {s === "no_data" ? "no data" : s}
    </span>
  );
}

// Column widths (% of the table) so all columns, Status included, fit on screen without scrolling;
// long text wraps inside its cell. The Table column (project report) takes its share from the text columns.
const RULE_COLUMNS: { label: string; width: number; widthWithTable: number }[] = [
  { label: "Column", width: 8, widthWithTable: 7 },
  { label: "Data Type", width: 5, widthWithTable: 5 },
  { label: "Dimension", width: 7, widthWithTable: 7 },
  { label: "Score", width: 5, widthWithTable: 5 },
  { label: "Business Rules", width: 16, widthWithTable: 13 },
  { label: "Regex Pattern", width: 11, widthWithTable: 10 },
  { label: "Version", width: 4, widthWithTable: 4 },
  { label: "Regex Version", width: 6, widthWithTable: 6 },
  { label: "Complexity", width: 5.5, widthWithTable: 5 },
  { label: "Reasoning", width: 13, widthWithTable: 11 },
  { label: "Remarks", width: 6.5, widthWithTable: 6 },
  { label: "Rows", width: 4, widthWithTable: 3.5 },
  { label: "Failed", width: 3.5, widthWithTable: 3.5 },
  { label: "Status", width: 5.5, widthWithTable: 6 },
];
const TABLE_COLUMN_WIDTH = 8;

/** The rules table; `showTable` adds a Table column (project report). */
export function RulesTable({ rows, showTable = false }: { rows: ReportRow[]; showTable?: boolean }) {
  const dash = <span className="text-slate-300 font-mono">—</span>;
  const cell = "px-2 py-2 align-top break-words";
  return (
    <div className="overflow-x-auto rounded-md border border-slate-200">
      <table className="w-full min-w-[1100px] table-fixed text-xs divide-y divide-slate-100">
        <colgroup>
          {showTable && <col style={{ width: `${TABLE_COLUMN_WIDTH}%` }} />}
          {RULE_COLUMNS.map((c) => <col key={c.label} style={{ width: `${showTable ? c.widthWithTable : c.width}%` }} />)}
        </colgroup>
        <thead className="bg-slate-50 text-[10px] uppercase font-mono text-slate-500 border-b border-slate-200">
          <tr>
            {showTable && <th className="px-2 py-2 text-left align-bottom">Table</th>}
            {RULE_COLUMNS.map((c) => <th key={c.label} className="px-2 py-2 text-left align-bottom">{c.label}</th>)}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {rows.map((row) => {
            const r = row.r;
            return (
              <tr key={r.id} className="hover:bg-slate-50">
                {showTable && <td className={`${cell} font-mono text-[11px] text-slate-500 break-all`}>{row.table}</td>}
                <td className={`${cell} font-mono text-xs text-slate-900 break-all`}>{r.column_name ?? "—"}</td>
                <td className={`${cell} font-mono text-xs text-slate-500`}>{r.data_type ?? "—"}</td>
                <td className={`${cell} capitalize font-mono text-xs text-slate-700`}>{r.check_type}</td>
                <td className={`${cell} font-mono font-semibold tabular-nums text-slate-900`}>
                  {r.actual_value ? `${parseFloat(r.actual_value).toFixed(1)}%` : "—"}
                </td>
                <td className={`${cell} text-slate-600 text-xs`}>
                  {r.business_rules ? <ExpandableText text={r.business_rules} /> : dash}
                </td>
                <td className={`${cell} font-mono text-xs text-slate-700 break-all`}>
                  {r.regex_pattern ? <ExpandableText text={r.regex_pattern} maxLen={40} /> : dash}
                </td>
                <td className={`${cell} text-xs font-mono text-slate-500 tabular-nums`}>{row.version ?? "—"}</td>
                <td className={`${cell} text-xs font-mono text-slate-500`}>{r.regex_version ?? "—"}</td>
                <td className={`${cell} text-xs font-mono text-slate-500`}>
                  {r.details?.complexity ? String(r.details.complexity) : "—"}
                </td>
                <td className={`${cell} text-slate-600 text-xs`}>
                  {r.details?.reasoning ? <ExpandableText text={String(r.details.reasoning)} /> : dash}
                </td>
                <td className={`${cell} text-slate-600 text-xs`}>
                  {r.remarks && r.remarks !== "-" ? <ExpandableText text={r.remarks} /> : <span className="text-slate-400 font-mono">-</span>}
                </td>
                <td className={`${cell} text-slate-500 font-mono tabular-nums`}>{r.row_count?.toLocaleString()}</td>
                <td className={`${cell} text-rose-700 font-mono tabular-nums font-semibold`}>{r.failed_count ?? 0}</td>
                <td className={cell}><StatusBadge row={row} /></td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

/** A rules-table row in the export format (same values as the table). */
export function exportRuleRow(row: ReportRow, withTable = false): ExportRuleRow {
  const r = row.r;
  const s = rowStatus(row);
  return {
    ...(withTable ? { table: row.table } : {}),
    column: r.column_name ?? "—",
    dataType: r.data_type ?? "—",
    dimension: r.check_type.charAt(0).toUpperCase() + r.check_type.slice(1),
    score: r.actual_value ? `${parseFloat(r.actual_value).toFixed(1)}%` : "—",
    businessRules: r.business_rules ?? "—",
    regex: r.regex_pattern ?? "—",
    version: row.version != null ? String(row.version) : "—",
    regexVersion: r.regex_version ?? "—",
    complexity: r.details?.complexity ? String(r.details.complexity) : "—",
    reasoning: r.details?.reasoning ? String(r.details.reasoning) : "—",
    remarks: r.remarks && r.remarks !== "-" ? r.remarks : "-",
    rows: r.row_count != null ? r.row_count.toLocaleString() : "—",
    failed: String(r.failed_count ?? 0),
    status: s === "no_data" ? "no data" : s,
  };
}

/** Export dropdown (Excel / PDF), same pattern as the Metadata page. */
export function ExportMenu({ disabled, title, onExcel, onPdf }: {
  disabled?: boolean; title: string; onExcel: () => void; onPdf: () => void;
}) {
  return (
    <div className="relative group shrink-0">
      <Button variant="outline" size="sm" disabled={disabled} className="h-7.5 text-xs font-medium" title={title}>
        <Download className="h-3.5 w-3.5 mr-1" /> Export
      </Button>
      <div className="absolute right-0 top-full mt-1 w-36 bg-white border border-slate-200 rounded-md shadow-md z-20 hidden group-hover:block overflow-hidden">
        <button onClick={onExcel} className="w-full text-left px-3 py-1.5 text-xs text-slate-700 hover:bg-slate-50 font-mono">
          Excel (.xlsx)
        </button>
        <button onClick={onPdf} className="w-full text-left px-3 py-1.5 text-xs text-slate-700 hover:bg-slate-50 font-mono border-t border-slate-100">
          PDF
        </button>
      </div>
    </div>
  );
}

/** Dimension filter chips (All + the dimensions present). */
export function DimensionChips({ dims, value, onChange }: { dims: string[]; value: string; onChange: (d: string) => void }) {
  const chip = (active: boolean) =>
    `text-[10px] font-mono px-2.5 py-1 rounded-md border capitalize transition-colors ${
      active ? "bg-slate-900 text-white border-slate-900 font-semibold" : "text-slate-600 border-slate-200 hover:bg-slate-50"
    }`;
  return (
    <div className="flex gap-1.5 flex-wrap">
      <button onClick={() => onChange("")} className={chip(!value)}>All</button>
      {dims.map((d) => (
        <button key={d} onClick={() => onChange(d)} className={chip(value === d)}>{d}</button>
      ))}
    </div>
  );
}
