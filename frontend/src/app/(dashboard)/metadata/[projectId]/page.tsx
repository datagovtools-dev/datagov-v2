"use client";

import { useState, useEffect, useRef, Suspense } from "react";
import { useParams, useSearchParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronLeft, Search, Download, Info } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";

interface MetadataRecord {
  id: string;
  seq_no: number;
  business_users: string;
  data_domain_table: string;
  line_of_business: string | null;
  table_type: string;
  project_name: string;
  project_year: number;
  data_steward: string | null;
  data_owner: string | null;
  data_attribute: string;
  data_year: number | null;
  data_sensitivity: string;
  data_grouping: string | null;
  business_term: string | null;
  business_definition: string | null;
  definition_status: string;
  standard_format: string | null;
  is_primary_key: boolean | null;
  is_nullable: boolean | null;
  sample_data: string | null;
  data_type: string | null;
  data_level: string;
  updated_date: string | null;
  updated_by: string | null;
  remarks: string;
  created_at: string;
}

interface AISettingsStatus {
  enabled: boolean;
  configured: boolean;
  provider: string;
  mode: string;
  base_url: string;
  model_name: string;
  timeout_seconds: number;
  batch_size: number;
  api_key_configured: boolean;
}

const SENSITIVITY_OPTIONS = ["Public", "Internal", "Confidential", "Highly Confidential"];
const DATA_LEVEL_OPTIONS = ["Raw", "Staging", "Aggregate"];

const SENSITIVITY_COLORS: Record<string, string> = {
  "Public": "bg-green-100 text-green-700 border-green-200",
  "Internal": "bg-blue-100 text-blue-700 border-blue-200",
  "Confidential": "bg-yellow-100 text-yellow-700 border-yellow-200",
  "Highly Confidential": "bg-red-100 text-red-700 border-red-200",
};

function SensitivityPill({ value }: { value: string }) {
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold border ${SENSITIVITY_COLORS[value] ?? "bg-gray-100 text-gray-600 border-gray-200"}`}>
      {value}
    </span>
  );
}

function AiBadge({ status }: { status: string }) {
  if (status !== "ai_generated") return null;
  return (
    <span className="ml-1 inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-violet-100 text-violet-700 border border-violet-300">
      AI
    </span>
  );
}

export default function MetadataGridPage() {
  return <Suspense><MetadataGridContent /></Suspense>;
}

function MetadataGridContent() {
  const { projectId } = useParams<{ projectId: string }>();
  const searchParams = useSearchParams();
  const router = useRouter();
  const qc = useQueryClient();

  const [tableFilter, setTableFilter] = useState(searchParams.get("table") ?? "");
  const [sensitivityFilter, setSensitivityFilter] = useState("");
  const [search, setSearch] = useState("");
  const [editingId, setEditingId] = useState<string | null>(null);
  const [drafts, setDrafts] = useState<Record<string, Partial<MetadataRecord>>>({});
  const [bulkGrouping, setBulkGrouping] = useState("");
  const [showBulkGrouping, setShowBulkGrouping] = useState(false);
  const [regenQueued, setRegenQueued] = useState<Set<string>>(new Set());
  const [regenAllRunning, setRegenAllRunning] = useState(false);
  const [regenError, setRegenError] = useState("");
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const { data: project } = useQuery<{ id: string; project_code: string | null; project_name: string; project_year: number; customer_name: string; line_of_business: string | null }>({
    queryKey: ["project", projectId],
    queryFn: () => api.get(`/projects/${projectId}`),
    enabled: !!projectId,
  });

  const { data: owners = [] } = useQuery<{ role_type: string; full_name: string; email: string }[]>({
    queryKey: ["metadata-owners", projectId],
    queryFn: () => api.get(`/metadata/owners/${projectId}`),
    enabled: !!projectId,
  });

  const { data: aiStatus } = useQuery<AISettingsStatus>({
    queryKey: ["ai-settings-status"],
    queryFn: () => api.get<AISettingsStatus>("/settings/ai/status"),
  });

  const { data: records = [], isLoading } = useQuery<MetadataRecord[]>({
    queryKey: ["metadata", projectId, tableFilter],
    queryFn: () => {
      const p = new URLSearchParams();
      if (tableFilter) p.set("table_filter", tableFilter);
      return api.get<MetadataRecord[]>(`/metadata/${projectId}?${p}`);
    },
    refetchInterval: regenAllRunning ? 5000 : false,
  });

  const aiReady = aiStatus?.configured ?? false;

  // Distinct tables for the filter dropdown
  const allTables = [...new Set(records.map((r) => r.data_domain_table))].sort();

  const filteredRecords = records.filter((r) => {
    if (sensitivityFilter && r.data_sensitivity !== sensitivityFilter) return false;
    if (!search) return true;
    return (
      r.data_attribute.toLowerCase().includes(search.toLowerCase()) ||
      (r.business_term ?? "").toLowerCase().includes(search.toLowerCase()) ||
      (r.business_definition ?? "").toLowerCase().includes(search.toLowerCase())
    );
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<MetadataRecord> }) =>
      api.put(`/metadata/${id}`, data),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ["metadata", projectId] });
      setEditingId(null);
      setDrafts((d) => { const n = { ...d }; delete n[id]; return n; });
    },
  });

  const batchSaveMutation = useMutation({
    mutationFn: () => api.post("/metadata/save", {
      project_id: projectId,
      records: Object.entries(drafts).map(([id, data]) => ({ id, ...data })),
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["metadata", projectId] });
      setDrafts({});
    },
  });

  const bulkStampMutation = useMutation({
    mutationFn: () => api.post(`/metadata/bulk-stamp/${projectId}`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["metadata", projectId] }),
  });

  const bulkGroupMutation = useMutation({
    mutationFn: () => api.post("/metadata/bulk-grouping", {
      project_id: projectId,
      table_filter: tableFilter,
      data_grouping: bulkGrouping,
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["metadata", projectId] });
      setShowBulkGrouping(false);
      setBulkGrouping("");
    },
  });

  async function handleRegenerate(recordId: string) {
    if (!aiReady) {
      setRegenError("AI generation is not configured. Open Settings > AI Setup and save an Ollama Cloud API key.");
      return;
    }
    setRegenError("");
    setRegenQueued((s) => new Set([...s, recordId]));
    try {
      await api.post("/metadata/regenerate-definition", { record_id: recordId });
      await qc.invalidateQueries({ queryKey: ["metadata", projectId] });
    } catch (e: any) {
      setRegenError(e.message || "Could not generate AI definition.");
    } finally {
      setRegenQueued((s) => { const n = new Set(s); n.delete(recordId); return n; });
    }
  }

  async function handleRegenAll() {
    if (!aiReady) {
      setRegenError("AI generation is not configured. Open Settings > AI Setup and save an Ollama Cloud API key.");
      return;
    }
    const targets = records.filter((r) => !r.business_definition || r.definition_status !== "ai_generated");
    if (!targets.length) return;
    setRegenError("");
    setRegenAllRunning(true);
    setRegenQueued(new Set(targets.map((r) => r.id)));
    try {
      let remaining = targets.length;
      const batchSize = Math.min(Math.max(aiStatus?.batch_size ?? 5, 1), 25);
      while (remaining > 0) {
        const result = await api.post<{ processed: number; failed: number; remaining: number; failures?: { error: string }[] }>(
          `/metadata/regenerate-all/${projectId}?limit=${batchSize}`,
          {},
        );
        remaining = result.remaining;
        await qc.invalidateQueries({ queryKey: ["metadata", projectId] });
        if (result.processed === 0 && result.failed > 0) {
          setRegenError(result.failures?.[0]?.error || "AI generation stopped after an error.");
          break;
        }
      }
    } catch (e: any) {
      setRegenError(e.message || "Could not generate AI definitions.");
    } finally {
      setRegenAllRunning(false);
      setRegenQueued(new Set());
      if (pollRef.current) { clearInterval(pollRef.current); pollRef.current = null; }
    }
  }

  // Stop auto-refetch when ALL records across the full dataset have definitions
  useEffect(() => {
    if (!regenAllRunning) return;
    if (!records.length) return; // guard: don't act on empty/loading data
    const pending = records.filter((r) => !r.business_definition || r.definition_status === "pending");
    setRegenQueued(new Set(pending.map((r) => r.id)));
    if (pending.length === 0) {
      setRegenAllRunning(false);
    }
  }, [records, regenAllRunning]);

  function setDraft(id: string, field: string, value: unknown) {
    setDrafts((d) => ({ ...d, [id]: { ...(d[id] ?? {}), [field]: value } }));
  }

  function getDraft<K extends keyof MetadataRecord>(record: MetadataRecord, field: K): MetadataRecord[K] {
    return (drafts[record.id]?.[field] ?? record[field]) as MetadataRecord[K];
  }

  const hasDrafts = Object.keys(drafts).length > 0;
  const dirtyIds = new Set(Object.keys(drafts));

  function handleExportExcel() {
    import("xlsx").then((XLSX) => {
      const projId   = project?.project_code ?? "";
      const projName = project?.project_name ?? "";
      const projYear = String(project?.project_year ?? "");
      const bizUsers = project?.customer_name ?? "";
      const lob      = project?.line_of_business ?? "";
      const steward  = dataSteward ? `${dataSteward.full_name} <${dataSteward.email}>` : "";
      const owner    = dataOwner   ? `${dataOwner.full_name} <${dataOwner.email}>`     : "";

      const headers = [
        "No", "Project ID", "Project Name", "Project Year", "Business Users",
        "Line of Business", "Data Steward", "Data Owner",
        "Table", "Table Type", "Data Year", "Grouping", "Level",
        "Attribute", "Sensitivity", "Business Term", "Business Definition",
        "Standard Format", "PK", "Nullable", "Sample", "Type",
        "Updated Date", "Updated By", "Remarks",
      ];
      const rows = filteredRecords.map((r, idx) => [
        idx + 1, projId, projName, projYear, bizUsers, lob, steward, owner,
        r.data_domain_table, r.table_type,
        r.data_year ?? new Date(r.created_at).getFullYear(),
        r.data_grouping ?? "", r.data_level, r.data_attribute, r.data_sensitivity,
        r.business_term ?? "", r.business_definition ?? "", r.standard_format ?? "",
        r.is_primary_key ? "Yes" : r.is_primary_key === false ? "No" : "",
        r.is_nullable    ? "Yes" : r.is_nullable    === false ? "No" : "",
        r.sample_data ?? "", r.data_type ?? "",
        r.updated_date ?? r.created_at.slice(0, 10),
        r.updated_by ? r.updated_by.split("<")[0].trim() : "",
        (r.remarks && r.remarks !== "-") ? r.remarks : "",
      ]);

      const ws = XLSX.utils.aoa_to_sheet([headers, ...rows]);
      // Auto column widths (rough estimate)
      ws["!cols"] = headers.map((h, i) => ({
        wch: Math.max(h.length, ...rows.map((r) => String(r[i] ?? "").length), 10),
      }));
      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, "Metadata");
      XLSX.writeFile(wb, `metadata_${projId || projectId}_${new Date().toISOString().slice(0, 10)}.xlsx`);
    });
  }

  function handleExportPDF() {
    const projId   = project?.project_code ?? "—";
    const projName = project?.project_name ?? "—";
    const projYear = String(project?.project_year ?? "—");
    const bizUsers = project?.customer_name ?? "—";
    const lob      = project?.line_of_business ?? "—";

    // ── Info strip ────────────────────────────────────────────────────────────
    const infoLabel = (text: string) =>
      `<div style="font-size:8px;font-weight:700;color:#6366f1;text-transform:uppercase;letter-spacing:0.07em;margin-bottom:3px">${text}</div>`;
    const infoVal = (text: string, bold = false, mono = false) =>
      `<div style="font-size:11px;color:#1e293b;${bold ? "font-weight:700;" : ""}${mono ? "font-family:'Courier New',monospace;" : ""}">${text}</div>`;
    const infoEmail = (email: string) =>
      `<div style="font-size:9px;color:#94a3b8;margin-top:1px">${email}</div>`;

    const infoHtml = `
      <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:12px 16px;padding:14px 18px;
                  border:1px solid #e2e8f0;border-radius:8px;margin-bottom:16px;
                  background:#ffffff;box-shadow:0 1px 3px rgba(0,0,0,0.06)">
        <div>${infoLabel("Project ID")}${infoVal(projId, true, true)}</div>
        <div>${infoLabel("Project Name")}${infoVal(projName, true)}</div>
        <div>${infoLabel("Project Year")}${infoVal(projYear)}</div>
        <div>${infoLabel("Business Users")}${infoVal(bizUsers)}</div>
        <div>${infoLabel("Line of Business")}${infoVal(lob)}</div>
        <div>${infoLabel("Data Steward")}${dataSteward
          ? `${infoVal(dataSteward.full_name)}${infoEmail(dataSteward.email)}`
          : `<span style="color:#94a3b8">—</span>`}
        </div>
        <div>${infoLabel("Data Owner")}${dataOwner
          ? `${infoVal(dataOwner.full_name)}${infoEmail(dataOwner.email)}`
          : `<span style="color:#94a3b8">—</span>`}
        </div>
      </div>`;

    // ── Sensitivity pill ──────────────────────────────────────────────────────
    const SENS_STYLE: Record<string, string> = {
      "Public":             "background:#dcfce7;color:#15803d;border-color:#bbf7d0",
      "Internal":           "background:#dbeafe;color:#1d4ed8;border-color:#bfdbfe",
      "Confidential":       "background:#fef9c3;color:#a16207;border-color:#fde047",
      "Highly Confidential":"background:#fee2e2;color:#b91c1c;border-color:#fecaca",
    };
    const sensPill = (s: string) => {
      const st = SENS_STYLE[s] ?? "background:#f1f5f9;color:#475569;border-color:#e2e8f0";
      return `<span style="display:inline-block;padding:2px 5px;border-radius:4px;font-size:7px;font-weight:700;border:1px solid;line-height:1.4;${st}">${s}</span>`;
    };

    // ── Table ─────────────────────────────────────────────────────────────────
    const cols = [
      { label: "#",                   w: "2%"  },
      { label: "Table",               w: "6%"  },
      { label: "Table Type",          w: "5%"  },
      { label: "Data Year",           w: "4%"  },
      { label: "Grouping",            w: "5%"  },
      { label: "Level",               w: "4%"  },
      { label: "Attribute",           w: "6%"  },
      { label: "Sensitivity",         w: "6%"  },
      { label: "Business Term",       w: "7%"  },
      { label: "Business Definition", w: "15%" },
      { label: "Standard Format",     w: "7%"  },
      { label: "PK",                  w: "3%"  },
      { label: "Null",                w: "3%"  },
      { label: "Sample",              w: "6%"  },
      { label: "Type",                w: "4%"  },
      { label: "Updated Date",        w: "5%"  },
      { label: "Updated By",          w: "6%"  },
      { label: "Remarks",             w: "6%"  },
    ];
    const colgroupHtml = `<colgroup>${cols.map((c) => `<col style="width:${c.w}">`).join("")}</colgroup>`;
    const theadHtml    = `<thead><tr>${cols.map((c) => `<th>${c.label}</th>`).join("")}</tr></thead>`;

    const tbodyHtml = `<tbody>${filteredRecords.map((r, idx) => {
      const isAI  = r.definition_status === "ai_generated";
      const defHtml = r.business_definition
        ? `${r.business_definition}${isAI ? ' <span style="display:inline-block;background:#ede9fe;color:#7c3aed;border:1px solid #ddd6fe;font-size:6px;font-weight:700;padding:1px 3px;border-radius:3px;vertical-align:middle">AI</span>' : ""}`
        : `<span style="color:#94a3b8;font-style:italic">—</span>`;
      const pkHtml   = r.is_primary_key
        ? `<span style="color:#2563eb;font-weight:700;font-size:8px">PK</span>`
        : `<span style="color:#e2e8f0">—</span>`;
      const nullHtml = r.is_nullable === null
        ? `<span style="color:#cbd5e1">—</span>`
        : r.is_nullable
          ? `<span style="color:#ef4444;font-weight:600">Yes</span>`
          : `<span style="color:#16a34a;font-weight:600">No</span>`;
      return `<tr>
        <td style="color:#94a3b8;text-align:center">${idx + 1}</td>
        <td style="font-family:'Courier New',monospace;color:#475569;font-size:7.5px">${r.data_domain_table}</td>
        <td style="color:#475569">${r.table_type}</td>
        <td style="color:#475569;text-align:center">${r.data_year ?? new Date(r.created_at).getFullYear()}</td>
        <td style="color:#475569">${r.data_grouping ?? ""}</td>
        <td style="color:#475569">${r.data_level}</td>
        <td style="font-family:'Courier New',monospace;font-weight:600;color:#1e293b;font-size:7.5px">${r.data_attribute}</td>
        <td>${sensPill(r.data_sensitivity)}</td>
        <td style="color:#334155">${r.business_term ?? ""}</td>
        <td style="line-height:1.5;color:#334155">${defHtml}</td>
        <td style="color:#334155">${r.standard_format ?? ""}</td>
        <td style="text-align:center">${pkHtml}</td>
        <td style="text-align:center">${nullHtml}</td>
        <td style="color:#64748b;font-family:'Courier New',monospace;font-size:7.5px">${r.sample_data ?? ""}</td>
        <td style="color:#475569">${r.data_type ?? ""}</td>
        <td style="color:#94a3b8">${r.updated_date ?? r.created_at.slice(0, 10)}</td>
        <td style="color:#94a3b8">${r.updated_by ? r.updated_by.split("<")[0].trim() : ""}</td>
        <td style="color:#334155">${(r.remarks && r.remarks !== "-") ? r.remarks : ""}</td>
      </tr>`;
    }).join("")}</tbody>`;

    const html = `<!DOCTYPE html><html><head><meta charset="utf-8"/>
    <title>Metadata — ${projId}</title>
    <style>
      @page { size: A3 landscape; margin: 12mm; }
      * { box-sizing: border-box; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; font-size: 9px; color: #1e293b; margin: 0; }
      h2 { font-size: 14px; font-weight: 700; margin: 0 0 12px; color: #0f172a; letter-spacing: -0.01em; }
      table { width: 100%; border-collapse: collapse; table-layout: fixed; }
      th { background: #f1f5f9; font-size: 7.5px; font-weight: 700; text-transform: uppercase;
           letter-spacing: 0.06em; padding: 6px 5px; border: 0.5px solid #e2e8f0;
           color: #475569; word-wrap: break-word; white-space: normal; }
      td { padding: 5px; border: 0.5px solid #e2e8f0; vertical-align: top;
           word-wrap: break-word; white-space: normal; font-size: 8px; color: #334155; }
      tbody tr:nth-child(odd)  td { background: #ffffff; }
      tbody tr:nth-child(even) td { background: #f8fafc; }
    </style></head><body>
    <h2>Metadata Attributes Report</h2>
    ${infoHtml}
    <table>${colgroupHtml}${theadHtml}${tbodyHtml}</table>
    </body></html>`;

    const win = window.open("", "_blank");
    if (!win) return;
    win.document.write(html);
    win.document.close();
    win.focus();
    setTimeout(() => { win.print(); }, 600);
  }

  const dataSteward = owners.find((o) => o.role_type === "lead_business_steward") ?? owners.find((o) => o.role_type === "business_steward");
  const dataOwner = owners.find((o) => o.role_type === "data_owner");

  return (
    <div className="flex flex-col h-full gap-4">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="min-w-0">
          <button onClick={() => router.push("/metadata")} className="text-surface-400 hover:text-surface-600 flex items-center gap-1 text-sm mb-1">
            <ChevronLeft className="h-4 w-4" /> Back to Metadata
          </button>
          <h1 className="text-xl font-bold text-surface-800">Metadata Attributes</h1>
          <p className="text-sm text-surface-500">{records.length} attributes · {allTables.length} tables</p>
        </div>
        <div className="flex gap-2 shrink-0">
          <div className="relative group">
            <Button variant="outline" disabled={filteredRecords.length === 0}>
              <Download className="h-4 w-4 mr-1" /> Export
            </Button>
            <div className="absolute right-0 top-full mt-1 w-36 bg-white border border-surface-200 rounded-lg shadow-lg z-20 hidden group-hover:block">
              <button onClick={handleExportExcel}
                className="w-full text-left px-4 py-2 text-sm text-surface-700 hover:bg-surface-50 rounded-t-lg">
                📊 Excel (.xlsx)
              </button>
              <button onClick={handleExportPDF}
                className="w-full text-left px-4 py-2 text-sm text-surface-700 hover:bg-surface-50 rounded-b-lg">
                📄 PDF
              </button>
            </div>
          </div>
          <Button
            variant="outline"
            onClick={handleRegenAll}
            disabled={regenAllRunning || records.length === 0 || !aiReady}
            title={aiReady ? `Using ${aiStatus?.provider ?? "AI"} ${aiStatus?.model_name ?? ""}` : "Configure Ollama Cloud in Settings > AI Setup"}
          >
            {regenAllRunning
              ? `Generating… (${regenQueued.size} queued)`
              : "✦ Generate All AI Definitions"}
          </Button>
          <Button
            variant="outline"
            onClick={() => bulkStampMutation.mutate()}
            disabled={bulkStampMutation.isPending || records.length === 0}
            title="Stamp today's date and your name as Updated By on all records"
          >
            {bulkStampMutation.isPending ? "Saving…" : "Save All"}
          </Button>
          {hasDrafts && (
            <Button onClick={() => batchSaveMutation.mutate()} disabled={batchSaveMutation.isPending}>
              {batchSaveMutation.isPending ? "Saving…" : `Save ${Object.keys(drafts).length} Changes`}
            </Button>
          )}
        </div>
      </div>

      {regenError && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
          {regenError}
        </div>
      )}

      {/* Project info strip */}
      {project && (
        <div className="bg-white border border-surface-200 rounded-xl shadow-sm px-6 py-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-x-4 gap-y-4">
          {[
            { label: "Project ID",       value: project.project_code ?? "—", mono: true,  bold: true },
            { label: "Project Name",     value: project.project_name,                      bold: true },
            { label: "Project Year",     value: String(project.project_year ?? "—"),       bold: false },
            { label: "Business Users",   value: project.customer_name || "—",              bold: false },
            { label: "Line of Business", value: project.line_of_business || "—",           bold: false },
          ].map(({ label, value, mono, bold }) => (
            <div key={label} className="min-w-0">
              <div className="text-[10px] font-semibold uppercase tracking-wider text-primary-500 truncate">{label}</div>
              <div className={`text-sm mt-1 truncate text-surface-800 ${bold ? "font-semibold" : "font-normal"} ${mono ? "font-mono" : ""}`} title={value}>{value}</div>
            </div>
          ))}
          <div className="min-w-0">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-primary-500">Data Steward</div>
            {dataSteward ? (
              <>
                <div className="text-sm font-normal text-surface-800 mt-1 truncate" title={dataSteward.full_name}>{dataSteward.full_name}</div>
                <div className="text-xs text-surface-500 truncate" title={dataSteward.email}>{dataSteward.email}</div>
              </>
            ) : <div className="text-sm text-surface-400 mt-1">—</div>}
          </div>
          <div className="min-w-0">
            <div className="text-[10px] font-semibold uppercase tracking-wider text-primary-500">Data Owner</div>
            {dataOwner ? (
              <>
                <div className="text-sm font-normal text-surface-800 mt-1 truncate" title={dataOwner.full_name}>{dataOwner.full_name}</div>
                <div className="text-xs text-surface-500 truncate" title={dataOwner.email}>{dataOwner.email}</div>
              </>
            ) : <div className="text-sm text-surface-400 mt-1">—</div>}
          </div>
        </div>
      )}

      {/* Filters toolbar */}
      <div className="flex flex-wrap items-center gap-2 mb-1">
        <Select value={tableFilter || "all"} onValueChange={(v) => setTableFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-10 flex-1 min-w-[160px] max-w-[220px] truncate"><SelectValue placeholder="All Tables" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Tables</SelectItem>
            {allTables.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={sensitivityFilter || "all"} onValueChange={(v) => setSensitivityFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-10 flex-1 min-w-[160px] max-w-[220px]"><SelectValue placeholder="All Sensitivity" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Sensitivity</SelectItem>
            <SelectItem value="Public">Public</SelectItem>
            <SelectItem value="Internal">Internal</SelectItem>
            <SelectItem value="Confidential">Confidential</SelectItem>
            <SelectItem value="Highly Confidential">Highly Confidential</SelectItem>
          </SelectContent>
        </Select>
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base h-10 pl-9 w-full" placeholder="Search attribute, term, or definition…"
            value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        {tableFilter && (
          <Button variant="outline" className="h-10 shrink-0" onClick={() => setShowBulkGrouping(true)}>
            Bulk Grouping
          </Button>
        )}
      </div>

      {/* Bulk grouping popover */}
      {showBulkGrouping && tableFilter && (
        <div className="bg-primary-50 border border-primary-200 rounded-lg p-4 flex items-center gap-3">
          <span className="text-sm text-primary-800 font-medium">Apply data_grouping to all rows in <strong>{tableFilter}</strong>:</span>
          <Input value={bulkGrouping} onChange={(e) => setBulkGrouping(e.target.value)}
            placeholder="Enter grouping label…" className="w-48" />
          <Button size="sm" disabled={!bulkGrouping || bulkGroupMutation.isPending}
            onClick={() => bulkGroupMutation.mutate()}>
            {bulkGroupMutation.isPending ? "Applying…" : "Apply"}
          </Button>
          <Button size="sm" variant="outline" onClick={() => setShowBulkGrouping(false)}>Cancel</Button>
        </div>
      )}

      {/* Legend — visible above the grid */}
      <div className="flex flex-wrap gap-4 text-xs text-surface-400 items-center">
        <span>✎ Edit row inline</span>
        <span className="flex items-center gap-1">
          <span className="text-violet-500">✦</span> Regenerate AI definition
        </span>
        <span className="flex items-center gap-1">
          <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-bold bg-violet-100 text-violet-700 border border-violet-300">AI</span>
          = AI-generated definition{aiStatus?.configured ? ` (${aiStatus.model_name})` : ""}
        </span>
        <span>Amber left border = unsaved changes</span>
      </div>

      {/* Unsaved indicator */}
      {hasDrafts && (
        <div className="bg-amber-50 border border-amber-200 rounded-lg p-2 text-xs text-amber-700 font-medium">
          {Object.keys(drafts).length} unsaved row{Object.keys(drafts).length > 1 ? "s" : ""} — highlighted in amber border
        </div>
      )}

      {/* Grid */}
      <div className="flex-1 min-h-0 bg-white rounded-xl border border-surface-200 overflow-hidden">
        <div className="overflow-auto h-full">
          <table className="min-w-full divide-y divide-surface-100 text-sm">
            <thead className="bg-surface-50 sticky top-0 z-10">
              <tr>
                {[
                  { label: "#",                   w: "w-10",  tip: "Running number" },
                  { label: "Table",               w: "w-40",  tip: "Name of the source or target table. e.g. customer_master, sales_fact, dim_product" },
                  { label: "Table Type",          w: "w-28",  tip: "Purpose of the table in this project. e.g. Source, Target, Lookup, Reference, Staging" },
                  { label: "Data Year",           w: "w-24",  tip: "The year the data was imported or processed for metadata. e.g. 2024, 2025, 2026" },
                  { label: "Grouping",            w: "w-32",  tip: "Business grouping this attribute belongs to. e.g. Customer Data, Financial Data, Product Master, Transaction" },
                  { label: "Level",               w: "w-24",  tip: "Processing level of the data. e.g. Raw (unprocessed), Staging (transformed), Aggregate (summarised)" },
                  { label: "Attribute",           w: "w-40",  tip: "The technical column or field name. e.g. customer_id, order_date, total_amount" },
                  { label: "Type",                w: "w-24",  tip: "Technical data type of the field. e.g. STRING, INTEGER, FLOAT, DATE, DATETIME, BOOLEAN" },
                  { label: "Sensitivity",         w: "w-36",  tip: "Data access sensitivity level. Public = no restriction · Internal = staff only · Confidential = limited access · Highly Confidential = PII/sensitive personal data" },
                  { label: "Business Term",       w: "w-36",  tip: "Organisation-wide standard name for this attribute. e.g. Customer Identifier, Order Date, Net Sales Amount" },
                  { label: "Business Definition", w: "w-64",  tip: "The business meaning of the field, independent of table context. e.g. 'Unique identifier assigned to each registered customer at the time of registration'" },
                  { label: "Standard Format",     w: "w-40",  tip: "Expected format or constraint for the value. e.g. YYYY-MM-DD for dates, 12 digits only for phone, 2 decimal places for amounts" },
                  { label: "PK",                  w: "w-10",  tip: "Primary Key — is this column the unique identifier for the table? Yes = uniquely identifies each row" },
                  { label: "Null",                w: "w-10",  tip: "Nullable — can this column contain empty or NULL values? Yes = optional field, No = required/mandatory" },
                  { label: "Sample",              w: "w-28",  tip: "A sample or representative value from the actual data. e.g. CUST-00123, 2024-06-01, 1500.00" },
                  { label: "Updated Date",        w: "w-28",  tip: "Date when the business metadata was last changed, displayed as yyyy-mm-dd. e.g. 2026-05-19. Defaults to the import date if never manually updated." },
                  { label: "Updated By",          w: "w-36",  tip: "Name of the person who last updated the business metadata. e.g. John Doe. Populated automatically on save." },
                  { label: "Remarks",             w: "w-40",  tip: "Free-text notes or additional context for this attribute. e.g. deprecated column, used only for legacy reports" },
                  { label: "",                    w: "w-20",  tip: "" },
                ].map((col) => (
                  <th key={col.label} className={`${col.w} px-3 py-2 text-left`}>
                    <div className="flex items-center gap-1 whitespace-nowrap">
                      <span className="text-xs font-semibold text-surface-600 uppercase tracking-wider">{col.label}</span>
                      {col.tip && (
                        <span title={col.tip} className="text-surface-300 hover:text-surface-500 cursor-help shrink-0">
                          <Info className="h-3 w-3" />
                        </span>
                      )}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-50">
              {isLoading ? (
                <tr><td colSpan={19} className="px-4 py-8 text-center text-surface-400">Loading…</td></tr>
              ) : !filteredRecords.length ? (
                <tr><td colSpan={19} className="px-4 py-8 text-center text-surface-400">No attributes found</td></tr>
              ) : filteredRecords.map((r, idx) => {
                const isDirty = dirtyIds.has(r.id);
                const isEditing = editingId === r.id;
                return (
                  <tr key={r.id}
                    className={`hover:bg-surface-50 transition-colors ${isDirty ? "border-l-4 border-amber-400 bg-amber-50/30" : ""}`}>

                    {/* # */}
                    <td className="px-3 py-2 text-surface-400 text-xs">{idx + 1}</td>

                    {/* Table */}
                    <td className="px-3 py-2 font-mono text-xs text-surface-600 max-w-[160px] truncate" title={r.data_domain_table}>{r.data_domain_table}</td>

                    {/* Table Type — editable dropdown */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <select value={getDraft(r, "table_type") as string}
                          onChange={(e) => setDraft(r.id, "table_type", e.target.value)}
                          className="text-xs border border-surface-300 rounded px-1.5 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400">
                          {["Source","Target","Lookup","Reference","Staging"].map((v) => <option key={v} value={v}>{v}</option>)}
                        </select>
                      ) : <span className="text-xs text-surface-600">{r.table_type}</span>}
                    </td>

                    {/* Data Year — editable, falls back to import year (created_at) */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <input type="number" value={getDraft(r, "data_year") as number ?? ""}
                          onChange={(e) => setDraft(r.id, "data_year", e.target.value ? parseInt(e.target.value) : null)}
                          className="text-xs border border-surface-300 rounded px-1.5 py-1 w-20 focus:outline-none focus:ring-1 focus:ring-primary-400" />
                      ) : <span className="text-xs text-surface-600 text-center block">{r.data_year ?? new Date(r.created_at).getFullYear()}</span>}
                    </td>

                    {/* Grouping — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <Input value={getDraft(r, "data_grouping") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "data_grouping", e.target.value)}
                          className="text-xs h-7 py-1" />
                      ) : <span className="text-surface-600 text-xs">{r.data_grouping ?? "—"}</span>}
                    </td>

                    {/* Level — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <select value={getDraft(r, "data_level") as string}
                          onChange={(e) => setDraft(r.id, "data_level", e.target.value)}
                          className="text-xs border border-surface-300 rounded px-1.5 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400">
                          {DATA_LEVEL_OPTIONS.map((l) => <option key={l} value={l}>{l}</option>)}
                        </select>
                      ) : <span className="text-xs text-surface-600">{r.data_level}</span>}
                    </td>

                    {/* Attribute */}
                    <td className="px-3 py-2 font-mono font-medium text-surface-800 text-xs">{r.data_attribute}</td>

                    {/* Type */}
                    <td className="px-3 py-2 text-surface-600 text-xs">{r.data_type ?? "—"}</td>

                    {/* Sensitivity — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <select value={getDraft(r, "data_sensitivity") as string}
                          onChange={(e) => setDraft(r.id, "data_sensitivity", e.target.value)}
                          className="text-xs border border-surface-300 rounded px-1.5 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400">
                          {SENSITIVITY_OPTIONS.map((s) => <option key={s} value={s}>{s}</option>)}
                        </select>
                      ) : <SensitivityPill value={getDraft(r, "data_sensitivity") as string} />}
                    </td>

                    {/* Business Term — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <Input value={getDraft(r, "business_term") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "business_term", e.target.value)}
                          className="text-xs h-7 py-1" />
                      ) : <span className="text-surface-700 text-xs">{r.business_term ?? "—"}</span>}
                    </td>

                    {/* Business Definition — editable with AI badge */}
                    <td className="px-3 py-2 max-w-[260px]">
                      {isEditing ? (
                        <textarea value={getDraft(r, "business_definition") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "business_definition", e.target.value)}
                          rows={2} className="w-full text-xs border border-surface-300 rounded px-2 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400 resize-none" />
                      ) : (
                        <div className="flex items-start gap-1">
                          <span className="text-surface-700 text-xs leading-relaxed line-clamp-2">
                            {(regenQueued.has(r.id) || (regenAllRunning && r.definition_status === "pending" && !r.business_definition))
                              ? <span className="text-violet-500 italic">Generating…</span>
                              : (r.business_definition ?? <span className="text-gray-400 italic">Not set</span>)}
                          </span>
                          <AiBadge status={r.definition_status} />
                        </div>
                      )}
                    </td>

                    {/* Standard Format — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <textarea value={getDraft(r, "standard_format") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "standard_format", e.target.value)}
                          rows={2} className="w-full text-xs border border-surface-300 rounded px-2 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400 resize-none min-w-[140px]" />
                      ) : <span className="text-xs text-surface-600 line-clamp-2">{r.standard_format ?? "—"}</span>}
                    </td>

                    {/* PK */}
                    <td className="px-3 py-2 text-center">
                      {r.is_primary_key ? <span className="text-blue-600 font-bold text-xs">PK</span> : <span className="text-gray-200">—</span>}
                    </td>

                    {/* Nullable — No=green (required field, good quality), Yes=red (nullable, quality risk) */}
                    <td className="px-3 py-2 text-center">
                      {r.is_nullable === null ? <span className="text-gray-300 text-xs">—</span>
                        : r.is_nullable
                          ? <span className="text-xs font-medium text-red-500">Yes</span>
                          : <span className="text-xs font-medium text-green-600">No</span>}
                    </td>

                    {/* Sample */}
                    <td className="px-3 py-2 text-xs text-gray-500 max-w-[110px] truncate" title={r.sample_data ?? ""}>{r.sample_data ?? "—"}</td>

                    {/* Updated Date — falls back to created_at date, yyyy-mm-dd */}
                    <td className="px-3 py-2 text-xs text-surface-400">
                      {r.updated_date ?? r.created_at.slice(0, 10)}
                    </td>

                    {/* Updated By — read-only */}
                    <td className="px-3 py-2 text-xs text-surface-400 max-w-[140px] truncate" title={r.updated_by ?? ""}>
                      {r.updated_by ? r.updated_by.split("<")[0].trim() : "—"}
                    </td>

                    {/* Remarks — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <textarea value={getDraft(r, "remarks") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "remarks", e.target.value)}
                          rows={2} className="w-full text-xs border border-surface-300 rounded px-2 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400 resize-none min-w-[140px]" />
                      ) : <span className="text-xs text-surface-600 line-clamp-2">{(r.remarks && r.remarks !== "-") ? r.remarks : "—"}</span>}
                    </td>

                    {/* Actions */}
                    <td className="px-3 py-2">
                      <div className="flex items-center gap-1">
                        {isEditing ? (
                          <>
                            <button className="text-xs text-primary-600 hover:underline"
                              onClick={() => updateMutation.mutate({ id: r.id, data: drafts[r.id] ?? {} })}>Save</button>
                            <button className="text-xs text-surface-400 hover:underline"
                              onClick={() => { setEditingId(null); setDrafts((d) => { const n = { ...d }; delete n[r.id]; return n; }); }}>✕</button>
                          </>
                        ) : (
                          <>
                            <button className="text-xs text-surface-500 hover:text-primary-600"
                              onClick={() => setEditingId(r.id)} title="Edit row">✎</button>
                            <button className="text-xs text-violet-500 hover:text-violet-700 disabled:opacity-40"
                              disabled={regenQueued.has(r.id) || !aiReady}
                              onClick={() => handleRegenerate(r.id)}
                              title={aiReady ? "Regenerate AI definition" : "Configure AI setup first"}>✦</button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}
