// Export of the DQ Rules tab (Excel / PDF) of a run or of the project DQ report, including the page
// header: project info strip and the two rows of KPI cards. Same approach as the Metadata export:
// xlsx in the browser, PDF via a print window.

export interface ExportProject {
  project_code: string | null;
  project_name: string;
  project_year: number | null;
  customer_name: string | null;
  line_of_business: string | null;
}

export interface ExportOwner {
  role_type: string;
  full_name: string;
  email: string;
}

export interface ExportCard {
  label: string;
  value: string;
  color: string; // tailwind text colour class used on the page
  hint: string;
}

export interface ExportRuleRow {
  table?: string; // project report only
  column: string;
  dataType: string;
  dimension: string;
  score: string;
  businessRules: string;
  regex: string;
  version: string;
  regexVersion: string;
  complexity: string;
  reasoning: string;
  remarks: string;
  rows: string;
  failed: string;
  status: string;
}

export interface DQRulesExport {
  title: string;                   // report title, e.g. "Data Quality Rules Report — DQ Run — car_demand_data"
  subtitle: string;                // one line under the title in the PDF
  infoRows: Array<[string, string]>; // label/value lines at the top of the Excel sheet
  fileBase: string;                // file name without extension
  project?: ExportProject;
  owners: ExportOwner[];
  summaryCards: ExportCard[];
  metricCards: ExportCard[];
  rows: ExportRuleRow[];
}

type RuleColumn = { key: keyof ExportRuleRow; label: string; width: string; wch: number };

const TABLE_COLUMN: RuleColumn = { key: "table", label: "Table", width: "8%", wch: 26 };
const RULE_COLUMNS: RuleColumn[] = [
  { key: "column", label: "Column", width: "8%", wch: 22 },
  { key: "dataType", label: "Data Type", width: "5%", wch: 12 },
  { key: "dimension", label: "Dimension", width: "6%", wch: 13 },
  { key: "score", label: "Score", width: "4%", wch: 8 },
  { key: "businessRules", label: "Business Rules", width: "16%", wch: 60 },
  { key: "regex", label: "Regex Pattern", width: "11%", wch: 35 },
  { key: "version", label: "Version", width: "3.5%", wch: 8 },
  { key: "regexVersion", label: "Regex Version", width: "5%", wch: 13 },
  { key: "complexity", label: "Complexity", width: "5%", wch: 11 },
  { key: "reasoning", label: "Reasoning", width: "13%", wch: 50 },
  { key: "remarks", label: "Remarks", width: "11%", wch: 40 },
  { key: "rows", label: "Rows", width: "4%", wch: 8 },
  { key: "failed", label: "Failed", width: "3.5%", wch: 8 },
  { key: "status", label: "Status", width: "4%", wch: 9 },
];

function columnsFor(data: DQRulesExport): RuleColumn[] {
  return data.rows.some((r) => r.table) ? [TABLE_COLUMN, ...RULE_COLUMNS] : RULE_COLUMNS;
}

const COLOR_HEX: Record<string, string> = {
  "text-emerald-700": "#047857",
  "text-amber-700": "#b45309",
  "text-rose-700": "#be123c",
  "text-slate-900": "#0f172a",
  "text-slate-400": "#94a3b8",
};

function projectFields(data: DQRulesExport) {
  const steward = data.owners.find((o) => o.role_type === "lead_business_steward")
    ?? data.owners.find((o) => o.role_type === "business_steward");
  const owner = data.owners.find((o) => o.role_type === "data_owner");
  const p = data.project;
  return {
    steward,
    owner,
    fields: [
      { label: "Project ID", value: p?.project_code ?? "—" },
      { label: "Project Name", value: p?.project_name ?? "—" },
      { label: "Project Year", value: p?.project_year != null ? String(p.project_year) : "—" },
      { label: "Business Users", value: p?.customer_name || "—" },
      { label: "Line of Business", value: p?.line_of_business || "—" },
      { label: "Data Steward", value: steward ? `${steward.full_name} <${steward.email}>` : "—" },
      { label: "Data Owner", value: owner ? `${owner.full_name} <${owner.email}>` : "—" },
    ],
  };
}

/** Safe file-name part (e.g. a dataset name without extension). */
export function fileNamePart(text: string): string {
  return text.replace(/\.[^.]+$/, "").replace(/[^\w-]+/g, "_");
}

export function exportDQRulesExcel(data: DQRulesExport): void {
  import("xlsx").then((XLSX) => {
    const { fields } = projectFields(data);
    const columns = columnsFor(data);
    const aoa: (string | number)[][] = [
      [data.title],
      ...data.infoRows,
      ["Exported", new Date().toLocaleString()],
      [],
      ["Project"],
      fields.map((f) => f.label),
      fields.map((f) => f.value),
      [],
      ["Summary"],
      data.summaryCards.map((c) => c.label),
      data.summaryCards.map((c) => c.value),
      data.summaryCards.map((c) => c.hint),
      [],
      ["Score per metric"],
      data.metricCards.map((c) => c.label),
      data.metricCards.map((c) => c.value),
      data.metricCards.map((c) => c.hint),
      [],
      ["Rules"],
      columns.map((c) => c.label),
      ...data.rows.map((r) => columns.map((c) => r[c.key] ?? "")),
    ];
    const ws = XLSX.utils.aoa_to_sheet(aoa);
    ws["!cols"] = columns.map((c, i) => ({ wch: i < 7 ? Math.max(c.wch, 24) : c.wch }));
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "DQ Rules");
    XLSX.writeFile(wb, `${data.fileBase}.xlsx`);
  });
}

function esc(text: string): string {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

export function exportDQRulesPDF(data: DQRulesExport): void {
  const { steward, owner, fields } = projectFields(data);
  const columns = columnsFor(data);
  const label = (t: string) =>
    `<div style="font-size:8px;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:0.07em;margin-bottom:3px">${esc(t)}</div>`;
  const person = (p?: ExportOwner) => p
    ? `<div style="font-size:11px">${esc(p.full_name)}</div><div style="font-size:9px;color:#94a3b8">${esc(p.email)}</div>`
    : `<div style="font-size:11px;color:#94a3b8">—</div>`;

  const infoHtml = `
    <div class="box" style="display:grid;grid-template-columns:repeat(7,1fr);gap:12px 16px">
      ${fields.slice(0, 5).map((f, i) => `<div>${label(f.label)}<div style="font-size:11px;${i < 2 ? "font-weight:700;" : ""}${i === 0 ? "font-family:'Courier New',monospace;" : ""}">${esc(f.value)}</div></div>`).join("")}
      <div>${label("Data Steward")}${person(steward)}</div>
      <div>${label("Data Owner")}${person(owner)}</div>
    </div>`;

  const cardRow = (cards: ExportCard[]) => `
    <div style="display:grid;grid-template-columns:repeat(${cards.length},1fr);gap:10px;margin-bottom:10px">
      ${cards.map((c) => `
        <div class="box" style="margin:0">
          ${label(c.label)}
          <div style="font-size:18px;font-weight:700;font-family:'Courier New',monospace;color:${COLOR_HEX[c.color] ?? "#0f172a"}">${esc(c.value)}</div>
          <div style="font-size:9px;color:#64748b;margin-top:3px;line-height:1.4">${esc(c.hint)}</div>
        </div>`).join("")}
    </div>`;

  const statusPill = (s: string) => {
    const style = s === "pass" ? "background:#ecfdf5;color:#047857;border-color:#a7f3d0"
      : s === "fail" ? "background:#fff1f2;color:#be123c;border-color:#fecdd3"
      : s === "no data" ? "background:#f1f5f9;color:#64748b;border-color:#e2e8f0"
      : "background:#fffbeb;color:#b45309;border-color:#fde68a";
    return `<span style="display:inline-block;padding:1px 5px;border-radius:4px;border:1px solid;font-size:7px;font-weight:700;${style}">${esc(s)}</span>`;
  };
  const mono = new Set<keyof ExportRuleRow>(["table", "column", "dataType", "regex", "version", "rows", "failed"]);
  const tableHtml = `
    <table>
      <colgroup>${columns.map((c) => `<col style="width:${c.width}">`).join("")}</colgroup>
      <thead><tr>${columns.map((c) => `<th>${c.label}</th>`).join("")}</tr></thead>
      <tbody>${data.rows.map((r) => `<tr>${columns.map((c) => {
        if (c.key === "status") return `<td>${statusPill(r.status)}</td>`;
        const style = mono.has(c.key) ? "font-family:'Courier New',monospace;" : "";
        const failedStyle = c.key === "failed" ? "color:#be123c;font-weight:700;" : "";
        return `<td style="${style}${failedStyle}">${esc(r[c.key] ?? "")}</td>`;
      }).join("")}</tr>`).join("")}</tbody>
    </table>`;

  const html = `<!DOCTYPE html><html><head><meta charset="utf-8"/>
    <title>${esc(data.fileBase)}</title>
    <style>
      @page { size: A3 landscape; margin: 12mm; }
      * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; font-size: 9px; color: #1e293b; margin: 0; }
      h2 { font-size: 14px; font-weight: 700; margin: 0 0 2px; color: #0f172a; }
      .sub { font-size: 9px; color: #64748b; font-family: 'Courier New', monospace; margin-bottom: 12px; }
      .box { padding: 12px 14px; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 10px; background: #fff; }
      table { width: 100%; border-collapse: collapse; table-layout: fixed; margin-top: 6px; }
      th { background: #f1f5f9; font-size: 7.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em;
           padding: 6px 5px; border: 0.5px solid #e2e8f0; color: #475569; text-align: left; }
      td { padding: 5px; border: 0.5px solid #e2e8f0; vertical-align: top; word-wrap: break-word; white-space: normal;
           font-size: 8px; color: #334155; line-height: 1.4; }
      tbody tr:nth-child(even) td { background: #f8fafc; }
      tr { page-break-inside: avoid; }
    </style></head><body>
    <h2>${esc(data.title)}</h2>
    <div class="sub">${esc(data.subtitle)}</div>
    ${infoHtml}
    ${cardRow(data.summaryCards)}
    ${cardRow(data.metricCards)}
    ${tableHtml}
    </body></html>`;

  const win = window.open("", "_blank");
  if (!win) return;
  win.document.write(html);
  win.document.close();
  win.focus();
  setTimeout(() => { win.print(); }, 600);
}
