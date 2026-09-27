"use client";

import { useState, useEffect, useRef, Suspense } from "react";
import { useParams, useSearchParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronLeft, ChevronDown, Search, Download, Info } from "lucide-react";
import { api } from "@/lib/api";
import { ProjectInfoStrip } from "@/components/details/ProjectInfoStrip";
import { ExpandableText } from "@/components/dq/DQReportParts";
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
  distinct_values: string | null;
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

// Seconds per definition before the first batch is measured (llama3.2:3b on CPU took ~25 s; cloud ~5 s)
const REGEN_PRIOR_SECONDS = { local: 25, cloud: 5 };

interface RegenProgress {
  total: number;
  done: number;
  startedAt: number;      // ms
  updatedAt: number;      // ms, when `done` last changed
  secondsPerItem: number; // measured once a batch has finished, else the prior
}

function formatDuration(totalSeconds: number): string {
  const s = Math.max(Math.round(totalSeconds), 0);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}` : `${m}:${String(sec).padStart(2, "0")}`;
}

// Estimated seconds left, counted down locally between batch answers
function regenSecondsLeft(p: RegenProgress, now: number): number {
  return Math.max((p.total - p.done) * p.secondsPerItem - (now - p.updatedAt) / 1000, 0);
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
  "Public": "bg-slate-100 text-slate-700 border-slate-200",
  "Internal": "bg-slate-100 text-slate-700 border-slate-200",
  "Confidential": "bg-amber-50 text-amber-700 border-amber-200",
  "Highly Confidential": "bg-rose-50 text-rose-700 border-rose-200",
};

const SF_GROUPS = [
  {
    group: "Boolean",
    options: [
      "Boolean (Yes / No)",
      "Boolean (True / False)",
      "Boolean (1 / 0)",
      "Boolean (Y / N)",
      "Boolean (T / F)",
    ],
  },
  {
    group: "Categorical",
    options: [
      "Category: ",
    ],
  },
  {
    group: "Date & Time",
    options: [
      "Date (YYYY-MM-DD)",
      "Date (DD/MM/YYYY)",
      "Date (DD-MM-YYYY)",
      "Date (YYYY/MM/DD)",
      "Datetime (YYYY-MM-DD HH:MM:SS)",
    ],
  },
  {
    group: "Contact",
    options: [
      "Email (name@domain.com)",
      "Phone number",
    ],
  },
  {
    group: "Numeric",
    options: [
      "Integer (whole number)",
      "Decimal number",
      "Decimal (1 decimal place)",
      "Decimal (2 decimal places)",
      "Decimal (3 decimal places)",
    ],
  },
  {
    group: "Identifier",
    options: ["ID / Code"],
  },
  {
    group: "Text",
    options: [
      "Free text",
      "Free text (long description)",
    ],
  },
];

function StandardFormatCombobox({
  value,
  onChange,
  distinctValues,
}: {
  value: string;
  onChange: (v: string) => void;
  distinctValues?: string | null;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, []);

  function pick(opt: string) {
    if (opt === "Category: " && distinctValues) {
      onChange(`Category: ${distinctValues}`);
    } else {
      onChange(opt);
    }
    setOpen(false);
  }

  return (
    <div ref={ref} className="relative min-w-[160px]">
      <div className="flex items-stretch border border-slate-200 rounded-md overflow-hidden focus-within:ring-1 focus-within:ring-slate-950">
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          rows={2}
          className="flex-1 text-xs px-2 py-1 resize-none focus:outline-none bg-white text-slate-900 font-mono"
        />
        <button
          type="button"
          onMouseDown={(e) => { e.preventDefault(); setOpen((o) => !o); }}
          className="px-1.5 bg-slate-50 hover:bg-slate-100 border-l border-slate-200 text-slate-400 hover:text-slate-600 shrink-0"
          tabIndex={-1}
        >
          <ChevronDown className="h-3.5 w-3.5" />
        </button>
      </div>

      {open && (
        <div className="absolute z-50 left-0 top-full mt-0.5 w-56 bg-white border border-slate-200 rounded-md shadow-lg max-h-72 overflow-y-auto">
          {SF_GROUPS.map(({ group, options }) => (
            <div key={group}>
              <div className="px-3 pt-2 pb-0.5 text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">
                {group}
              </div>
              {options.map((opt) => (
                <button
                  key={opt}
                  type="button"
                  onMouseDown={(e) => { e.preventDefault(); pick(opt); }}
                  className="w-full text-left px-3 py-1.5 text-xs text-slate-700 hover:bg-slate-50 hover:text-slate-900 font-mono"
                >
                  {opt === "Category: " ? "Category: [type values…]" : opt}
                </button>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function SensitivityPill({ value }: { value: string }) {
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-mono border ${SENSITIVITY_COLORS[value] ?? "bg-slate-100 text-slate-600 border-slate-200"}`}>
      {value}
    </span>
  );
}

function AiBadge({ status }: { status: string }) {
  if (status !== "ai_generated") return null;
  return (
    <span className="ml-1 inline-flex items-center px-1.5 py-0.2 rounded-md text-[9px] font-mono font-medium bg-slate-100 text-slate-700 border border-slate-200">
      ai
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
  // Generate AI Definitions progress: countdown like the DQ Generate step
  const [regenProgress, setRegenProgress] = useState<RegenProgress | null>(null);
  const [nowTick, setNowTick] = useState(() => Date.now());
  const regenActive = regenProgress !== null; // cleared only when the whole run ends
  useEffect(() => {
    if (!regenActive) return;
    const t = setInterval(() => setNowTick(Date.now()), 1000);
    return () => clearInterval(t);
  }, [regenActive]);
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
    const startedAt = Date.now();
    const prior = aiStatus?.mode === "local" ? REGEN_PRIOR_SECONDS.local : REGEN_PRIOR_SECONDS.cloud;
    setRegenProgress({ total: targets.length, done: 0, startedAt, updatedAt: startedAt, secondsPerItem: prior });
    try {
      let remaining = targets.length;
      let processedSoFar = 0;
      const batchSize = Math.min(Math.max(aiStatus?.batch_size ?? 5, 1), 25);
      while (remaining > 0) {
        const result = await api.post<{ processed: number; failed: number; remaining: number; failures?: { error: string }[] }>(
          `/metadata/regenerate-all/${projectId}?limit=${batchSize}`,
          {},
        );
        remaining = result.remaining;
        processedSoFar += result.processed;
        // The server works through the whole project (the page may show one table), so count from its answer
        const now = Date.now();
        const done = processedSoFar;
        setRegenProgress((p) => p && {
          ...p,
          done,
          total: done + result.remaining,
          updatedAt: now,
          secondsPerItem: done > 0 ? (now - p.startedAt) / 1000 / done : p.secondsPerItem,
        });
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
      setRegenProgress(null);
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

  // Table-level fields: propagate to every row that shares the same data_domain_table
  function setTableDraft(record: MetadataRecord, field: string, value: unknown) {
    setDrafts((d) => {
      const next = { ...d };
      for (const sibling of records.filter((r: MetadataRecord) => r.data_domain_table === record.data_domain_table)) {
        next[sibling.id] = { ...(next[sibling.id] ?? {}), [field]: value };
      }
      return next;
    });
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
    <div className="flex flex-col h-full gap-3.5">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-slate-200">
        <div className="min-w-0">
          <button onClick={() => router.push("/metadata")} className="text-slate-400 hover:text-slate-700 flex items-center gap-1 text-xs mb-0.5 font-mono">
            <ChevronLeft className="h-3.5 w-3.5" /> Back to Metadata
          </button>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">Metadata Attributes</h1>
          <p className="text-xs text-slate-500 font-mono">{records.length} attributes · {allTables.length} tables</p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <div className="relative group">
            <Button variant="outline" size="sm" disabled={filteredRecords.length === 0} className="h-7.5 text-xs font-medium">
              <Download className="h-3.5 w-3.5 mr-1" /> Export
            </Button>
            <div className="absolute right-0 top-full mt-1 w-36 bg-white border border-slate-200 rounded-md shadow-md z-20 hidden group-hover:block overflow-hidden">
              <button onClick={handleExportExcel}
                className="w-full text-left px-3 py-1.5 text-xs text-slate-700 hover:bg-slate-50 font-mono">
                Excel (.xlsx)
              </button>
              <button onClick={handleExportPDF}
                className="w-full text-left px-3 py-1.5 text-xs text-slate-700 hover:bg-slate-50 font-mono border-t border-slate-100">
                PDF
              </button>
            </div>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={handleRegenAll}
            className="h-7.5 text-xs font-medium"
            disabled={regenAllRunning || regenActive || records.length === 0 || !aiReady || (records.length > 0 && records.every((r) => r.business_definition && r.definition_status === "ai_generated"))}
            title={aiReady ? `Using ${aiStatus?.provider ?? "AI"} ${aiStatus?.model_name ?? ""}` : "Configure Ollama Cloud in Settings > AI Setup"}
          >
            {regenAllRunning
              ? `Generating… (${regenQueued.size} queued)`
              : "Generate AI Definitions"}
          </Button>
          <Button
            variant="outline"
            size="sm"
            className="h-7.5 text-xs font-medium"
            onClick={() => bulkStampMutation.mutate()}
            disabled={bulkStampMutation.isPending || records.length === 0}
            title="Stamp today's date and your name as Updated By on all records"
          >
            {bulkStampMutation.isPending ? "Saving…" : "Save All"}
          </Button>
          {hasDrafts && (
            <Button
              size="sm"
              className="h-7.5 text-xs font-medium"
              onClick={() => batchSaveMutation.mutate()}
              disabled={batchSaveMutation.isPending}
            >
              {batchSaveMutation.isPending ? "Saving…" : `Save ${Object.keys(drafts).length} Changes`}
            </Button>
          )}
        </div>
      </div>

      {regenProgress && (() => {
        const left = regenSecondsLeft(regenProgress, nowTick);
        const pct = regenProgress.total ? Math.round((regenProgress.done / regenProgress.total) * 100) : 0;
        const measured = regenProgress.done > 0;
        return (
          <div className="rounded-lg border border-blue-100 bg-blue-50/40 px-4 py-3 space-y-2">
            <div className="flex items-center justify-between gap-4">
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-4 h-4 flex-shrink-0 rounded-full border-2 border-blue-200 border-t-blue-600 animate-spin" />
                <div className="min-w-0">
                  <p className="text-sm font-semibold text-slate-800">Generating AI definitions…</p>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {regenProgress.done} / {regenProgress.total} definitions generated · {aiStatus?.model_name ?? "AI model"}, {aiStatus?.batch_size ?? 5} per batch
                    {" · "}elapsed {formatDuration((nowTick - regenProgress.startedAt) / 1000)}
                  </p>
                  <p className="text-[11px] text-slate-400 mt-0.5">
                    {measured
                      ? `Estimate from the speed so far (≈ ${Math.round(regenProgress.secondsPerItem)} s per definition).`
                      : `First estimate (≈ ${regenProgress.secondsPerItem} s per definition); it is corrected after the first batch.`}
                    {" "}Keep this page open until it finishes.
                  </p>
                </div>
              </div>
              <div className="text-right flex-shrink-0" title="Estimated time until all definitions are generated">
                <p className="text-[10px] uppercase tracking-wider text-slate-400 font-mono">Time left</p>
                <p className="text-lg font-bold font-mono text-slate-800">≈ {formatDuration(left)}</p>
              </div>
            </div>
            <div className="h-1.5 rounded-full bg-blue-100 overflow-hidden">
              <div className="h-full bg-blue-600 transition-all duration-500" style={{ width: `${pct}%` }} />
            </div>
          </div>
        );
      })()}

      {regenError && (
        <div className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 font-mono">
          {regenError}
        </div>
      )}

      {/* Project info strip */}
      <ProjectInfoStrip projectId={projectId} />

      {/* Filters toolbar */}
      <div className="flex flex-wrap items-center gap-2 mb-0.5">
        <Select value={tableFilter || "all"} onValueChange={(v) => setTableFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-8 flex-1 min-w-[150px] max-w-[200px] text-xs font-mono truncate"><SelectValue placeholder="All Tables" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Tables</SelectItem>
            {allTables.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={sensitivityFilter || "all"} onValueChange={(v) => setSensitivityFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="h-8 flex-1 min-w-[140px] max-w-[180px] text-xs font-mono"><SelectValue placeholder="All Sensitivity" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Sensitivity</SelectItem>
            <SelectItem value="Public">Public</SelectItem>
            <SelectItem value="Internal">Internal</SelectItem>
            <SelectItem value="Confidential">Confidential</SelectItem>
            <SelectItem value="Highly Confidential">Highly Confidential</SelectItem>
          </SelectContent>
        </Select>
        <div className="relative flex-1 min-w-[180px]">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 pointer-events-none" />
          <input className="input-base h-8 pl-8 text-xs font-mono w-full" placeholder="Search attribute, term, or definition…"
            value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        {tableFilter && (
          <Button variant="outline" size="sm" className="h-8 shrink-0 text-xs font-medium" onClick={() => setShowBulkGrouping(true)}>
            Bulk Grouping
          </Button>
        )}
      </div>

      {/* Bulk grouping popover */}
      {showBulkGrouping && tableFilter && (
        <div className="bg-slate-50 border border-slate-200 rounded-md p-3 flex items-center gap-2.5">
          <span className="text-xs text-slate-700 font-mono">Apply grouping to rows in <strong>{tableFilter}</strong>:</span>
          <Input value={bulkGrouping} onChange={(e) => setBulkGrouping(e.target.value)}
            placeholder="Enter grouping label…" className="w-48 h-7 text-xs font-mono" />
          <Button size="sm" className="h-7 text-xs font-medium" disabled={!bulkGrouping || bulkGroupMutation.isPending}
            onClick={() => bulkGroupMutation.mutate()}>
            {bulkGroupMutation.isPending ? "Applying…" : "Apply"}
          </Button>
          <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => setShowBulkGrouping(false)}>Cancel</Button>
        </div>
      )}

      {/* Unsaved indicator */}
      {hasDrafts && (
        <div className="bg-amber-50 border border-amber-200 rounded-md px-3 py-1.5 text-xs text-amber-800 font-mono font-medium">
          {Object.keys(drafts).length} unsaved row{Object.keys(drafts).length > 1 ? "s" : ""} — highlighted in amber
        </div>
      )}

      {/* Grid */}
      <div className="flex-1 min-h-0 bg-white rounded-md border border-slate-200 shadow-2xs overflow-hidden">
        <div className="overflow-auto h-full">
          <table className="min-w-full divide-y divide-slate-100 text-xs">
            <thead className="bg-slate-50 sticky top-0 z-10 border-b border-slate-200">
              <tr>
                {[
                  { label: "#",                   w: "w-10",  tip: "Running number" },
                  { label: "Table",               w: "w-40",  tip: "Name of the source or target table. e.g. customer_master, sales_fact, dim_product" },
                  { label: "Table Type",          w: "w-28",  tip: "Table-level — editing one row updates all columns in the same table. Purpose of the table. e.g. Source, Target, Lookup, Reference, Staging" },
                  { label: "Data Year",           w: "w-24",  tip: "Table-level — editing one row updates all columns in the same table. Year the data was imported or processed. e.g. 2024, 2025, 2026" },
                  { label: "Grouping",            w: "w-32",  tip: "Table-level — editing one row updates all columns in the same table. Business grouping. e.g. Customer Data, Financial Data, Product Master, Transaction" },
                  { label: "Level",               w: "w-24",  tip: "Table-level — editing one row updates all columns in the same table. Processing level. e.g. Raw (unprocessed), Staging (transformed), Aggregate (summarised)" },
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
                  <th key={col.label} className={`${col.w} px-2.5 py-2 text-left font-semibold text-slate-600 font-mono text-[10px] uppercase tracking-wider`}>
                    <div className="flex items-center gap-1 whitespace-nowrap">
                      <span>{col.label}</span>
                      {col.tip && (
                        <span title={col.tip} className="text-slate-300 hover:text-slate-500 cursor-help shrink-0">
                          <Info className="h-3 w-3" />
                        </span>
                      )}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr><td colSpan={19} className="px-4 py-8 text-center text-slate-400 font-mono">Loading…</td></tr>
              ) : !filteredRecords.length ? (
                <tr><td colSpan={19} className="px-4 py-8 text-center text-slate-400 font-mono">No attributes found</td></tr>
              ) : filteredRecords.map((r, idx) => {
                const isDirty = dirtyIds.has(r.id);
                const isEditing = editingId === r.id;
                return (
                  <tr key={r.id}
                    className={`hover:bg-slate-50 transition-colors ${isDirty ? "bg-amber-50/40" : ""}`}>

                    {/* # */}
                    <td className="px-2.5 py-1.5 text-slate-400 font-mono text-[11px]">{idx + 1}</td>

                    {/* Table */}
                    <td className="px-2.5 py-1.5 font-mono text-[11px] text-slate-600 min-w-[140px] max-w-[180px] whitespace-normal break-all">{r.data_domain_table}</td>

                    {/* Table Type */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <select value={getDraft(r, "table_type") as string}
                          onChange={(e) => setTableDraft(r, "table_type", e.target.value)}
                          className="text-xs border border-slate-200 rounded-md px-1.5 py-0.5 focus:outline-none focus:ring-1 focus:ring-slate-950 font-mono">
                          {["Source","Target","Lookup","Reference","Staging"].map((v) => <option key={v} value={v}>{v}</option>)}
                        </select>
                      ) : <span className="text-xs text-slate-600 font-mono">{r.table_type}</span>}
                    </td>

                    {/* Data Year */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <input type="number" value={getDraft(r, "data_year") as number ?? ""}
                          onChange={(e) => setTableDraft(r, "data_year", e.target.value ? parseInt(e.target.value) : null)}
                          className="text-xs border border-slate-200 rounded-md px-1.5 py-0.5 w-20 focus:outline-none focus:ring-1 focus:ring-slate-950 font-mono" />
                      ) : <span className="text-xs text-slate-600 font-mono text-center block">{r.data_year ?? new Date(r.created_at).getFullYear()}</span>}
                    </td>

                    {/* Grouping */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <Input value={getDraft(r, "data_grouping") as string ?? ""}
                          onChange={(e) => setTableDraft(r, "data_grouping", e.target.value)}
                          className="text-xs h-6.5 py-0.5 font-mono" />
                      ) : <span className="text-slate-600 text-xs font-mono">{r.data_grouping ?? "—"}</span>}
                    </td>

                    {/* Level */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <select value={getDraft(r, "data_level") as string}
                          onChange={(e) => setTableDraft(r, "data_level", e.target.value)}
                          className="text-xs border border-slate-200 rounded-md px-1.5 py-0.5 focus:outline-none focus:ring-1 focus:ring-slate-950 font-mono">
                          {DATA_LEVEL_OPTIONS.map((l) => <option key={l} value={l}>{l}</option>)}
                        </select>
                      ) : <span className="text-xs text-slate-600 font-mono">{r.data_level}</span>}
                    </td>

                    {/* Attribute */}
                    <td className="px-2.5 py-1.5 font-mono font-medium text-slate-900 text-xs">{r.data_attribute}</td>

                    {/* Type */}
                    <td className="px-2.5 py-1.5 text-slate-600 font-mono text-xs">{r.data_type ?? "—"}</td>

                    {/* Sensitivity */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <select value={getDraft(r, "data_sensitivity") as string}
                          onChange={(e) => setDraft(r.id, "data_sensitivity", e.target.value)}
                          className="text-xs border border-slate-200 rounded-md px-1.5 py-0.5 focus:outline-none focus:ring-1 focus:ring-slate-950 font-mono">
                          {SENSITIVITY_OPTIONS.map((s) => <option key={s} value={s}>{s}</option>)}
                        </select>
                      ) : <SensitivityPill value={getDraft(r, "data_sensitivity") as string} />}
                    </td>

                    {/* Business Term */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <Input value={getDraft(r, "business_term") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "business_term", e.target.value)}
                          className="text-xs h-6.5 py-0.5 font-mono" />
                      ) : <span className="text-slate-800 text-xs font-mono">{r.business_term ?? "—"}</span>}
                    </td>

                    {/* Business Definition */}
                    <td className="px-2.5 py-1.5 max-w-[260px]">
                      {isEditing ? (
                        <textarea value={getDraft(r, "business_definition") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "business_definition", e.target.value)}
                          rows={2} className="w-full text-xs border border-slate-200 rounded-md px-2 py-1 focus:outline-none focus:ring-1 focus:ring-slate-950 resize-none font-sans" />
                      ) : (
                        <div className="flex items-start gap-1">
                          <span className="text-slate-700 text-xs leading-relaxed">
                            {(regenQueued.has(r.id) || (regenAllRunning && r.definition_status === "pending" && !r.business_definition))
                              ? <span className="text-slate-400 italic font-mono">Generating…</span>
                              : r.business_definition
                                ? <ExpandableText text={r.business_definition} maxLen={80} />
                                : <span className="text-slate-300 italic font-mono">—</span>}
                          </span>
                          <AiBadge status={r.definition_status} />
                        </div>
                      )}
                    </td>

                    {/* Standard Format */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <StandardFormatCombobox
                          value={(getDraft(r, "standard_format") as string) ?? ""}
                          onChange={(v) => setDraft(r.id, "standard_format", v)}
                          distinctValues={r.distinct_values}
                        />
                      ) : <span className="text-xs text-slate-600 font-mono break-words">
                        {r.standard_format ? <ExpandableText text={r.standard_format} maxLen={40} /> : "—"}
                      </span>}
                    </td>

                    {/* PK */}
                    <td className="px-2.5 py-1.5 text-center">
                      {r.is_primary_key ? <span className="text-slate-900 font-bold font-mono text-[11px]">PK</span> : <span className="text-slate-200 font-mono">—</span>}
                    </td>

                    {/* Nullable */}
                    <td className="px-2.5 py-1.5 text-center">
                      {r.is_nullable === null ? <span className="text-slate-300 text-xs font-mono">—</span>
                        : r.is_nullable
                          ? <span className="text-xs font-medium text-rose-700 font-mono">Yes</span>
                          : <span className="text-xs font-medium text-emerald-700 font-mono">No</span>}
                    </td>

                    {/* Sample */}
                    <td className="px-2.5 py-1.5 text-xs font-mono text-slate-500 min-w-[140px] max-w-[200px] break-all">
                      {r.sample_data ? <ExpandableText text={r.sample_data} maxLen={30} /> : "—"}
                    </td>

                    {/* Updated Date */}
                    <td className="px-2.5 py-1.5 text-xs font-mono text-slate-400">
                      {r.updated_date ?? r.created_at.slice(0, 10)}
                    </td>

                    {/* Updated By */}
                    <td className="px-2.5 py-1.5 text-xs font-mono text-slate-400 max-w-[140px] truncate" title={r.updated_by ?? ""}>
                      {r.updated_by ? r.updated_by.split("<")[0].trim() : "—"}
                    </td>

                    {/* Remarks */}
                    <td className="px-2.5 py-1.5">
                      {isEditing ? (
                        <textarea value={getDraft(r, "remarks") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "remarks", e.target.value)}
                          rows={2} className="w-full text-xs border border-slate-200 rounded-md px-2 py-1 focus:outline-none focus:ring-1 focus:ring-slate-950 resize-none min-w-[140px]" />
                      ) : <span className="text-xs text-slate-600 line-clamp-2">{(r.remarks && r.remarks !== "-") ? r.remarks : "—"}</span>}
                    </td>

                    {/* Actions */}
                    <td className="px-2.5 py-1.5">
                      <div className="flex items-center gap-1">
                        {isEditing ? (
                          <>
                            <button className="text-xs text-slate-900 font-semibold hover:underline"
                              onClick={() => updateMutation.mutate({ id: r.id, data: drafts[r.id] ?? {} })}>Save</button>
                            <button className="text-xs text-slate-400 hover:underline"
                              onClick={() => { setEditingId(null); setDrafts((d) => { const n = { ...d }; delete n[r.id]; return n; }); }}>✕</button>
                          </>
                        ) : (
                          <>
                            <button className="text-xs text-slate-500 hover:text-slate-900"
                              onClick={() => setEditingId(r.id)} title="Edit row">✎</button>
                            <button className="text-xs text-slate-400 hover:text-slate-900 disabled:opacity-40"
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
