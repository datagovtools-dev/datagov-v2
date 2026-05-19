"use client";

import { useState, useEffect, useRef, Suspense } from "react";
import { useParams, useSearchParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ChevronLeft, Search } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";

interface MetadataRecord {
  id: string;
  seq_no: number;
  data_domain_table: string;
  data_attribute: string;
  data_type: string | null;
  data_sensitivity: string;
  data_grouping: string | null;
  business_term: string | null;
  business_definition: string | null;
  definition_status: string;
  standard_format: string | null;
  is_primary_key: boolean | null;
  is_nullable: boolean | null;
  sample_data: string | null;
  data_level: string;
  updated_date: string | null;
  updated_by: string | null;
  remarks: string;
  table_type: string;
  line_of_business: string | null;
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
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const { data: project } = useQuery<{ id: string; project_code: string | null; project_name: string }>({
    queryKey: ["project", projectId],
    queryFn: () => api.get(`/projects/${projectId}`),
    enabled: !!projectId,
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
    setRegenQueued((s) => new Set([...s, recordId]));
    try {
      await api.post("/metadata/regenerate-definition", { record_id: recordId });
      setTimeout(() => {
        qc.invalidateQueries({ queryKey: ["metadata", projectId] });
        setRegenQueued((s) => { const n = new Set(s); n.delete(recordId); return n; });
      }, 8000);
    } catch {
      setRegenQueued((s) => { const n = new Set(s); n.delete(recordId); return n; });
    }
  }

  async function handleRegenAll() {
    const targets = records.filter((r) => !r.business_definition || r.definition_status !== "ai_generated");
    if (!targets.length) return;
    setRegenAllRunning(true);
    setRegenQueued(new Set(targets.map((r) => r.id)));
    // Single server-side call queues all pending tasks at once — avoids connection pool exhaustion
    await api.post(`/metadata/regenerate-all/${projectId}`, {});
    // refetchInterval (5s) takes over — clear any leftover manual interval
    if (pollRef.current) { clearInterval(pollRef.current); pollRef.current = null; }
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

  return (
    <div className="flex flex-col h-full gap-4">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="min-w-0">
          <button onClick={() => router.push("/metadata")} className="text-surface-400 hover:text-surface-600 flex items-center gap-1 text-sm mb-1">
            <ChevronLeft className="h-4 w-4" /> Back to Metadata
          </button>
          <h1 className="text-xl font-bold text-surface-800">Metadata Attributes</h1>
          {project && (
            <p className="text-sm font-medium text-primary-700 mt-0.5">
              {project.project_code && <span className="font-mono mr-1">{project.project_code}</span>}
              — {project.project_name}
            </p>
          )}
          <p className="text-sm text-surface-500">{records.length} attributes · {allTables.length} tables</p>
        </div>
        <div className="flex gap-2 shrink-0">
          <Button
            variant="outline"
            onClick={handleRegenAll}
            disabled={regenAllRunning || records.length === 0}
          >
            {regenAllRunning
              ? `Generating… (${regenQueued.size} queued)`
              : "✦ Generate All AI Definitions"}
          </Button>
          {hasDrafts && (
            <Button onClick={() => batchSaveMutation.mutate()} disabled={batchSaveMutation.isPending}>
              {batchSaveMutation.isPending ? "Saving…" : `Save ${Object.keys(drafts).length} Changes`}
            </Button>
          )}
        </div>
      </div>

      {/* Filters toolbar */}
      <div className="flex flex-wrap gap-3 mb-1">
        <Select value={tableFilter || "all"} onValueChange={(v) => setTableFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="w-52"><SelectValue placeholder="All Tables" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Tables</SelectItem>
            {allTables.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={sensitivityFilter || "all"} onValueChange={(v) => setSensitivityFilter(v === "all" ? "" : v)}>
          <SelectTrigger className="w-52"><SelectValue placeholder="All Sensitivity" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Sensitivity</SelectItem>
            <SelectItem value="Public">Public</SelectItem>
            <SelectItem value="Internal">Internal</SelectItem>
            <SelectItem value="Confidential">Confidential</SelectItem>
            <SelectItem value="Highly Confidential">Highly Confidential</SelectItem>
          </SelectContent>
        </Select>
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base pl-9" placeholder="Search attribute, term, or definition…"
            value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        {tableFilter && (
          <Button variant="outline" size="sm" onClick={() => setShowBulkGrouping(true)}>
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
      <div className="flex flex-wrap gap-4 text-xs text-surface-400">
        <span>✎ Edit row inline</span>
        <span>✦ Regenerate AI definition (violet)</span>
        <span>AI badge = Ollama-generated definition</span>
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
                  { label: "#", w: "w-10" },
                  { label: "Table", w: "w-36" },
                  { label: "Attribute", w: "w-40" },
                  { label: "Type", w: "w-24" },
                  { label: "Sensitivity", w: "w-36" },
                  { label: "Grouping", w: "w-32" },
                  { label: "Business Term", w: "w-36" },
                  { label: "Business Definition", w: "w-64" },
                  { label: "PK", w: "w-10" },
                  { label: "Null", w: "w-10" },
                  { label: "Sample", w: "w-28" },
                  { label: "Level", w: "w-24" },
                  { label: "Updated By", w: "w-36" },
                  { label: "", w: "w-20" },
                ].map((col) => (
                  <th key={col.label} className={`${col.w} px-3 py-2 text-left text-xs font-medium text-surface-500 uppercase tracking-wider whitespace-nowrap`}>
                    {col.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-50">
              {isLoading ? (
                <tr><td colSpan={14} className="px-4 py-8 text-center text-surface-400">Loading…</td></tr>
              ) : !filteredRecords.length ? (
                <tr><td colSpan={14} className="px-4 py-8 text-center text-surface-400">No attributes found</td></tr>
              ) : filteredRecords.map((r, idx) => {
                const isDirty = dirtyIds.has(r.id);
                const isEditing = editingId === r.id;
                return (
                  <tr key={r.id}
                    className={`hover:bg-surface-50 transition-colors ${isDirty ? "border-l-4 border-amber-400 bg-amber-50/30" : ""}`}>
                    <td className="px-3 py-2 text-surface-400 text-xs">{idx + 1}</td>
                    <td className="px-3 py-2 font-mono text-xs text-surface-600 max-w-[140px] truncate" title={r.data_domain_table}>
                      {r.data_domain_table}
                    </td>
                    <td className="px-3 py-2 font-mono font-medium text-surface-800">{r.data_attribute}</td>
                    <td className="px-3 py-2 text-surface-600 text-xs">{r.data_type ?? "—"}</td>

                    {/* Sensitivity — editable dropdown */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <select value={getDraft(r, "data_sensitivity")}
                          onChange={(e) => setDraft(r.id, "data_sensitivity", e.target.value)}
                          className="text-xs border border-surface-300 rounded px-1.5 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400">
                          {SENSITIVITY_OPTIONS.map((s) => <option key={s} value={s}>{s}</option>)}
                        </select>
                      ) : (
                        <SensitivityPill value={getDraft(r, "data_sensitivity") as string} />
                      )}
                    </td>

                    {/* Grouping — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <Input value={getDraft(r, "data_grouping") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "data_grouping", e.target.value)}
                          className="text-xs h-7 py-1" />
                      ) : (
                        <span className="text-surface-600 text-xs">{r.data_grouping ?? "—"}</span>
                      )}
                    </td>

                    {/* Business Term — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <Input value={getDraft(r, "business_term") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "business_term", e.target.value)}
                          className="text-xs h-7 py-1" />
                      ) : (
                        <span className="text-surface-700 text-xs">{r.business_term ?? "—"}</span>
                      )}
                    </td>

                    {/* Business Definition — editable with AI badge and regenerate button */}
                    <td className="px-3 py-2 max-w-[260px]">
                      {isEditing ? (
                        <textarea
                          value={getDraft(r, "business_definition") as string ?? ""}
                          onChange={(e) => setDraft(r.id, "business_definition", e.target.value)}
                          rows={2}
                          className="w-full text-xs border border-surface-300 rounded px-2 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400 resize-none"
                        />
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

                    {/* PK / Nullable indicators */}
                    <td className="px-3 py-2 text-center">
                      {r.is_primary_key ? <span className="text-blue-600 font-bold text-xs">PK</span> : <span className="text-gray-200">—</span>}
                    </td>
                    <td className="px-3 py-2 text-center">
                      {r.is_nullable ? <span className="text-gray-400 text-xs">✓</span> : <span className="text-gray-200">—</span>}
                    </td>

                    {/* Sample data */}
                    <td className="px-3 py-2 text-xs text-gray-500 max-w-[110px] truncate" title={r.sample_data ?? ""}>
                      {r.sample_data ?? "—"}
                    </td>

                    {/* Level — editable */}
                    <td className="px-3 py-2">
                      {isEditing ? (
                        <select value={getDraft(r, "data_level") as string}
                          onChange={(e) => setDraft(r.id, "data_level", e.target.value)}
                          className="text-xs border border-surface-300 rounded px-1.5 py-1 focus:outline-none focus:ring-1 focus:ring-primary-400">
                          {DATA_LEVEL_OPTIONS.map((l) => <option key={l} value={l}>{l}</option>)}
                        </select>
                      ) : (
                        <span className="text-xs text-surface-600">{r.data_level}</span>
                      )}
                    </td>

                    {/* Updated by */}
                    <td className="px-3 py-2 text-xs text-surface-400 max-w-[140px] truncate" title={r.updated_by ?? ""}>
                      {r.updated_by ? r.updated_by.split("<")[0].trim() : "—"}
                    </td>

                    {/* Actions */}
                    <td className="px-3 py-2">
                      <div className="flex items-center gap-1">
                        {isEditing ? (
                          <>
                            <button
                              className="text-xs text-primary-600 hover:underline"
                              onClick={() => updateMutation.mutate({ id: r.id, data: drafts[r.id] ?? {} })}>
                              Save
                            </button>
                            <button
                              className="text-xs text-surface-400 hover:underline"
                              onClick={() => { setEditingId(null); setDrafts((d) => { const n = { ...d }; delete n[r.id]; return n; }); }}>
                              ✕
                            </button>
                          </>
                        ) : (
                          <>
                            <button className="text-xs text-surface-500 hover:text-primary-600"
                              onClick={() => setEditingId(r.id)} title="Edit row">✎</button>
                            <button
                              className="text-xs text-violet-500 hover:text-violet-700 disabled:opacity-40"
                              disabled={regenQueued.has(r.id)}
                              onClick={() => handleRegenerate(r.id)}
                              title="Regenerate AI definition">✦</button>
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
