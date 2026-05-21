/**
 * Opens a styled A4 print window so the user can Save as PDF.
 * No external dependencies — uses the browser's native print-to-PDF.
 */
export function printA4(title: string, bodyHtml: string): void {
  const win = window.open("", "_blank", "width=900,height=700");
  if (!win) return;

  win.document.write(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>${title}</title>
  <style>
    @page { size: A4 portrait; margin: 18mm 20mm; }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: Arial, sans-serif; font-size: 10pt; color: #1a202c; line-height: 1.5; }
    .pdf-header { display: flex; align-items: center; justify-content: space-between;
      border-bottom: 2px solid #1B2A4A; padding-bottom: 8px; margin-bottom: 16px; }
    .pdf-header .brand { font-size: 11pt; font-weight: bold; color: #1B2A4A; }
    .pdf-header .meta { font-size: 8pt; color: #718096; text-align: right; }
    h1.doc-title { font-size: 14pt; font-weight: bold; color: #1B2A4A; margin-bottom: 4px; }
    .doc-subtitle { font-size: 9pt; color: #718096; margin-bottom: 18px; }
    .section { margin-bottom: 16px; page-break-inside: avoid; }
    .section-title { font-size: 9pt; font-weight: bold; text-transform: uppercase;
      letter-spacing: 0.05em; color: #4a5568; background: #EDF2F7;
      padding: 5px 8px; border-left: 3px solid #1B2A4A; margin-bottom: 8px; }
    .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 16px; }
    .field { margin-bottom: 4px; }
    .field-label { font-size: 7.5pt; color: #718096; text-transform: uppercase;
      letter-spacing: 0.04em; }
    .field-value { font-size: 10pt; font-weight: 500; color: #1a202c; }
    .field-value.empty { color: #a0aec0; font-weight: normal; }
    .full-width { grid-column: 1 / -1; }
    table { width: 100%; border-collapse: collapse; font-size: 9pt; }
    th { background: #EDF2F7; text-align: left; padding: 5px 8px;
      font-size: 8pt; font-weight: bold; color: #4a5568;
      border: 1px solid #CBD5E0; }
    td { padding: 5px 8px; border: 1px solid #E2E8F0; vertical-align: top; }
    tr:nth-child(even) td { background: #F7FAFC; }
    .badge { display: inline-block; padding: 1px 8px; border-radius: 9999px;
      font-size: 8pt; font-weight: 600; }
    .badge-approved { background: #C6F6D5; color: #22543D; }
    .badge-rejected { background: #FED7D7; color: #742A2A; }
    .badge-pending  { background: #E2E8F0; color: #4A5568; }
    .badge-ai       { background: #FEFCBF; color: #744210; }
    .badge-draft    { background: #E2E8F0; color: #4A5568; }
    .badge-warning  { background: #FEEBC8; color: #7B341E; }
    .badge-review   { background: #BEE3F8; color: #2A4365; }
    .badge-danger   { background: #FED7D7; color: #742A2A; }
    .timeline { list-style: none; padding: 0; }
    .timeline li { display: flex; gap: 12px; padding: 6px 0;
      border-bottom: 1px solid #EDF2F7; }
    .timeline li:last-child { border-bottom: none; }
    .tl-step { font-weight: bold; color: #1B2A4A; font-size: 9pt; min-width: 26px; }
    .tl-label { font-weight: 600; font-size: 9pt; }
    .tl-meta  { font-size: 8pt; color: #718096; }
    .sig-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 4px; }
    .sig-box { border: 1px solid #CBD5E0; border-radius: 4px; padding: 8px 10px; }
    .sig-box .sig-title { font-size: 8pt; font-weight: bold; color: #4a5568;
      text-transform: uppercase; letter-spacing: 0.04em; margin-bottom: 6px; }
    .sig-image { max-width: 100%; height: 56px; object-fit: contain; display: block; }
    .sig-line { border-bottom: 1px solid #CBD5E0; height: 40px; margin: 6px 0 2px; }
    .sig-name { font-size: 9pt; font-weight: 600; }
    .sig-date { font-size: 8pt; color: #718096; }
    .pdf-footer { margin-top: 24px; border-top: 1px solid #E2E8F0;
      padding-top: 6px; font-size: 7.5pt; color: #a0aec0;
      display: flex; justify-content: space-between; }
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
  <div class="pdf-header">
    <span class="brand">AI Governance Tools</span>
    <span class="meta">Generated: ${new Date().toLocaleString("en-GB")}</span>
  </div>
  ${bodyHtml}
  <div class="pdf-footer">
    <span>AI Governance Tools — Confidential</span>
    <span>${title}</span>
  </div>
  <script>window.onload = () => { window.print(); }<\/script>
</body>
</html>`);
  win.document.close();
}

/** Render a label/value field row */
export function pdfField(label: string, value: string | null | undefined, fullWidth = false): string {
  const cls = fullWidth ? "field full-width" : "field";
  const val = value?.trim() ? value : "—";
  const valCls = value?.trim() ? "field-value" : "field-value empty";
  return `<div class="${cls}">
    <div class="field-label">${label}</div>
    <div class="${valCls}">${val}</div>
  </div>`;
}

export type PdfBadgeType = "approved" | "rejected" | "pending" | "ai" | "draft" | "warning" | "review" | "danger";

export function pdfBadge(text: string, type: PdfBadgeType): string {
  return `<span class="badge badge-${type}">${text}</span>`;
}

export function pdfStatusBadge(status: string, isSigned = false): string {
  if (isSigned) return pdfBadge("Signed & Locked", "approved");
  const map: Record<string, PdfBadgeType> = {
    draft: "draft", submitted: "warning", under_review: "review",
    approved: "approved", rejected: "rejected", executed: "approved",
    archived: "draft", requested: "warning", pending: "draft",
  };
  const type = map[status] ?? "draft";
  const label = status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
  return pdfBadge(label, type);
}
