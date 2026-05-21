"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";

interface ProjectOption { id: string; project_code: string | null; project_name: string; }
interface SourceTableInfo {
  table_name: string;
  column_count: number;
  documented: boolean;
  row_count: number | null;
  source_type: string;
}

interface UploadedMetadataTable {
  table_name: string;
  columns: string[];
  sample_rows: unknown[][];
  row_count: number;
}

interface ProceedResponse {
  task_id: string;
  message: string;
  queued_records: number;
  processed_records?: number;
}

export default function MetadataHomePage() {
  const router = useRouter();
  const qc = useQueryClient();

  const [projectId, setProjectId] = useState("");
  const [sourceType, setSourceType] = useState<"gcp" | "postgresql" | "excel">("gcp");
  const [gcpProject, setGcpProject] = useState("");
  const [bqDataset, setBqDataset] = useState("");
  const [connectionString, setConnectionString] = useState("");
  const [pgSchema, setPgSchema] = useState("public");
  const [selectedTables, setSelectedTables] = useState<Set<string>>(new Set());
  const [proceeded, setProceeded] = useState(false);
  const [proceedResult, setProceedResult] = useState<ProceedResponse | null>(null);
  const [excelSheets, setExcelSheets] = useState<SourceTableInfo[]>([]);
  const [uploadedTables, setUploadedTables] = useState<UploadedMetadataTable[]>([]);
  const [tempFileKeys, setTempFileKeys] = useState<string[]>([]);
  const [uploading, setUploading] = useState(false);
  const [uploadedFileNames, setUploadedFileNames] = useState<string[]>([]);

  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: stats } = useQuery<{ projects: number; tables: number; attributes: number }>({
    queryKey: ["metadata-stats"],
    queryFn: () => api.get("/metadata/stats"),
  });

  // Live discovery query — only used when Discover Tables is clicked (GCP/PG)
  const { refetch: refetchTables } = useQuery<SourceTableInfo[]>({
    queryKey: ["meta-tables-discover", projectId, sourceType, gcpProject, bqDataset, connectionString, pgSchema],
    queryFn: () => {
      const p = new URLSearchParams({ source_type: sourceType });
      if (gcpProject) p.set("gcp_project", gcpProject);
      if (bqDataset) p.set("bq_dataset", bqDataset);
      if (connectionString) p.set("connection_string", connectionString);
      if (pgSchema) p.set("pg_schema", pgSchema);
      return api.get<SourceTableInfo[]>(`/metadata/tables/${projectId}?${p}`);
    },
    enabled: false,
  });

  // Source Tables section — always shows ALL documented tables for the project across all source types
  const { data: projectTables, isLoading: loadingAllTables } = useQuery<SourceTableInfo[]>({
    queryKey: ["meta-project-tables", projectId],
    queryFn: () => api.get<SourceTableInfo[]>(`/metadata/tables/${projectId}`),
    enabled: !!projectId,
  });

  const proceedMutation = useMutation({
    mutationFn: () => api.post<ProceedResponse>("/metadata/proceed", {
      project_id: projectId,
      source_type: sourceType,
      gcp_project: gcpProject || undefined,
      bq_dataset: bqDataset || undefined,
      table_names: selectedTables.size > 0 ? [...selectedTables] : undefined,
      connection_string: connectionString || undefined,
      pg_schema: pgSchema || undefined,
      temp_file_keys: tempFileKeys.length > 0 ? tempFileKeys : undefined,
      file_names: uploadedFileNames.length > 0 ? uploadedFileNames : undefined,
      uploaded_tables: sourceType === "excel"
        ? uploadedTables.filter((table) => selectedTables.has(table.table_name))
        : undefined,
    }),
    onSuccess: (result) => {
      setProceeded(true);
      setProceedResult(result);
      if (sourceType === "excel") {
        setExcelSheets((sheets) => sheets.map((sheet) => (
          selectedTables.has(sheet.table_name) ? { ...sheet, documented: true } : sheet
        )));
      }
      qc.invalidateQueries({ queryKey: ["meta-tables"] });
      qc.invalidateQueries({ queryKey: ["metadata", projectId] });
      qc.invalidateQueries({ queryKey: ["metadata-stats"] });
    },
  });

  async function handleExcelUpload(files: FileList | File[]) {
    const fileArr = Array.from(files);
    if (!fileArr.length) return;
    setUploading(true);
    setExcelSheets([]);
    setUploadedTables([]);
    setTempFileKeys([]);
    setUploadedFileNames([]);
    setSelectedTables(new Set());
    setProceeded(false);
    setProceedResult(null);
    try {
      const token = useAuthStore.getState().accessToken;
      const allSheets: SourceTableInfo[] = [];
      const allUploadedTables: UploadedMetadataTable[] = [];
      const keys: string[] = [];
      const names: string[] = [];
      for (const file of fileArr) {
        const formData = new FormData();
        formData.append("file", file);
        const res = await fetch("/api/v1/metadata/upload-excel", {
          method: "POST",
          body: formData,
          credentials: "include",
          headers: token ? { Authorization: `Bearer ${token}` } : {},
        });
        if (!res.ok) { const err = await res.json(); throw new Error(`${file.name}: ${err.detail ?? "Upload failed"}`); }
        const data = await res.json();
        keys.push(data.temp_key);
        names.push(file.name);
        const uploadedPayload = (data.tables ?? []) as UploadedMetadataTable[];
        for (const s of data.sheets as { sheet_name: string; column_count: number; row_count: number }[]) {
          const tableName = fileArr.length > 1 ? `${file.name} - ${s.sheet_name}` : s.sheet_name;
          allSheets.push({
            table_name: tableName,
            column_count: s.column_count,
            documented: false,
            row_count: s.row_count,
            source_type: "excel",
          });
          const payloadTable = uploadedPayload.find((table) => table.table_name === s.sheet_name);
          if (payloadTable) {
            allUploadedTables.push({ ...payloadTable, table_name: tableName });
          }
        }
      }
      setTempFileKeys(keys);
      setUploadedFileNames(names);
      setExcelSheets(allSheets);
      setUploadedTables(allUploadedTables);
    } catch (e: unknown) {
      alert(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  }

  const [statusFilter, setStatusFilter] = useState<"all" | "documented" | "undocumented">("all");

  // Source Tables: if a file was just uploaded show fresh sheets, otherwise show all DB tables for the project
  const allTables = excelSheets.length > 0 ? excelSheets : (projectTables ?? []);
  const displayTables = statusFilter === "all" ? allTables
    : statusFilter === "documented" ? allTables.filter((t) => t.documented)
    : allTables.filter((t) => !t.documented);
  const documented = allTables.filter((t) => t.documented).length;
  const total = allTables.length;

  function toggleTable(name: string) {
    setSelectedTables((s) => {
      const n = new Set(s);
      n.has(name) ? n.delete(name) : n.add(name);
      return n;
    });
  }

  function toggleAll() {
    const visibleNames = displayTables.map((t) => t.table_name);
    const allVisible = visibleNames.every((n) => selectedTables.has(n));
    if (allVisible && visibleNames.length > 0) {
      setSelectedTables((s) => { const n = new Set(s); visibleNames.forEach((name) => n.delete(name)); return n; });
    } else {
      setSelectedTables((s) => new Set([...s, ...visibleNames]));
    }
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Metadata Management</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Discover source tables, auto-populate attributes, and manage business definitions with AI assistance
          </p>
          {stats && (
            <div className="flex items-center gap-4 mt-1.5">
              <span className="text-sm text-surface-600">
                <span className="font-semibold text-surface-800">{stats.projects.toLocaleString()}</span> project{stats.projects !== 1 ? "s" : ""}
              </span>
              <span className="text-surface-300">·</span>
              <span className="text-sm text-surface-600">
                <span className="font-semibold text-surface-800">{stats.tables.toLocaleString()}</span> table{stats.tables !== 1 ? "s" : ""}
              </span>
              <span className="text-surface-300">·</span>
              <span className="text-sm text-surface-600">
                <span className="font-semibold text-surface-800">{stats.attributes.toLocaleString()}</span> attribute{stats.attributes !== 1 ? "s" : ""}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Source Configuration card */}
      <div className="bg-white rounded-xl border border-surface-200 p-5 space-y-4 mb-5">
        <h2 className="font-semibold text-surface-800">Source Configuration</h2>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-surface-700 mb-1">Project</label>
            <select
              value={projectId}
              onChange={(e) => { setProjectId(e.target.value); setSelectedTables(new Set()); setProceeded(false); setProceedResult(null); }}
              className="w-full border border-surface-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 text-surface-700"
            >
              <option value="">Select project…</option>
              {projects?.map((p) => <option key={p.id} value={p.id}>{p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-surface-700 mb-1">Source Type</label>
            <div className="flex gap-2">
              {(["gcp", "postgresql", "excel"] as const).map((t) => (
                <button key={t} onClick={() => { setSourceType(t); setProceeded(false); setProceedResult(null); }}
                  className={`flex-1 py-2 rounded-lg border text-sm font-medium transition-colors ${
                    sourceType === t
                      ? "border-primary-500 bg-primary-50 text-primary-700"
                      : "border-surface-200 text-surface-600 hover:border-surface-300"
                  }`}>
                  {t === "gcp" ? "☁ GCP BigQuery" : t === "postgresql" ? "🐘 PostgreSQL / Supabase" : "📊 Excel"}
                </button>
              ))}
            </div>
          </div>
          {sourceType === "gcp" && (
            <>
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">GCP Project</label>
                <Input value={gcpProject} onChange={(e) => setGcpProject(e.target.value)} placeholder="my-gcp-project" />
              </div>
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">BigQuery Dataset</label>
                <Input value={bqDataset} onChange={(e) => setBqDataset(e.target.value)} placeholder="my_dataset" />
              </div>
            </>
          )}
          {sourceType === "postgresql" && (
            <>
              <div className="col-span-2">
                <label className="block text-sm font-medium text-surface-700 mb-1">Connection String</label>
                <Input
                  type="password"
                  value={connectionString}
                  onChange={(e) => setConnectionString(e.target.value)}
                  placeholder="postgresql://user:password@host:5432/dbname"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Schema</label>
                <Input value={pgSchema} onChange={(e) => setPgSchema(e.target.value)} placeholder="public" />
              </div>
            </>
          )}
          {sourceType === "excel" && (
            <div className="col-span-2">
              <label className="block text-sm font-medium text-surface-700 mb-1">Excel File</label>
              <div
                className={`flex flex-col items-center justify-center w-full h-28 border-2 border-dashed rounded-lg cursor-pointer transition-colors ${
                  uploading ? "border-primary-300 bg-primary-50" : "border-surface-300 bg-surface-50 hover:border-primary-400 hover:bg-primary-50"
                }`}
                onClick={() => document.getElementById("excel-upload-input")?.click()}
                onDragOver={(e) => e.preventDefault()}
                onDrop={(e) => {
                  e.preventDefault();
                  if (e.dataTransfer.files?.length) handleExcelUpload(e.dataTransfer.files);
                }}
              >
                <input id="excel-upload-input" type="file" accept=".xlsx,.xls,.csv" multiple className="hidden"
                  onChange={(e) => { if (e.target.files?.length) handleExcelUpload(e.target.files); }} />
                {uploading ? (
                  <p className="text-sm text-primary-600 font-medium">Uploading and reading sheets…</p>
                ) : uploadedFileNames.length > 0 ? (
                  <div className="text-center">
                    <p className="text-sm font-medium text-primary-700">
                      ✓ {uploadedFileNames.length === 1 ? uploadedFileNames[0] : `${uploadedFileNames.length} files uploaded`}
                    </p>
                    <p className="text-xs text-surface-500 mt-0.5">
                      {excelSheets.length} sheet{excelSheets.length !== 1 ? "s" : ""} found · click to replace
                    </p>
                    {uploadedFileNames.length > 1 && (
                      <p className="text-xs text-surface-400 mt-0.5">{uploadedFileNames.join(", ")}</p>
                    )}
                  </div>
                ) : (
                  <div className="text-center">
                    <p className="text-sm font-medium text-surface-600">Click to upload or drag & drop from File Explorer</p>
                    <p className="text-xs text-surface-400 mt-0.5">.xlsx / .xls / .csv · select multiple files at once</p>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
        {sourceType !== "excel" && (
          <Button disabled={!projectId} onClick={() => refetchTables()} variant="outline">
            Discover Tables
          </Button>
        )}
      </div>

      {/* Documentation progress bar */}
      {displayTables.length > 0 && (
        <div className="bg-white rounded-xl border border-surface-200 p-4 flex items-center gap-4 mb-5">
          <div className="flex-1">
            <div className="flex justify-between text-sm mb-1.5">
              <span className="text-surface-600">Documentation Progress</span>
              <span className="font-semibold text-surface-800">{documented}/{total} tables documented</span>
            </div>
            <div className="bg-surface-100 rounded-full h-2.5">
              <div className="bg-primary-500 h-2.5 rounded-full transition-all"
                style={{ width: total > 0 ? `${(documented / total) * 100}%` : "0%" }} />
            </div>
          </div>
          <span className="text-sm font-bold text-primary-600">{total > 0 ? Math.round((documented / total) * 100) : 0}%</span>
        </div>
      )}

      {/* Source tables list */}
      {projectId && (
        <div className="bg-white rounded-xl border border-surface-200 overflow-hidden">
          <div className="flex items-center justify-between px-4 py-3 border-b border-surface-100">
            <div className="flex items-center gap-3">
              <h2 className="font-semibold text-surface-800">Source Tables</h2>
              {(loadingAllTables || uploading) && <span className="text-xs text-surface-400">{uploading ? "Reading sheets…" : "Loading…"}</span>}
              <div className="flex gap-1">
                {(["all", "undocumented", "documented"] as const).map((f) => (
                  <button key={f} onClick={() => setStatusFilter(f)}
                    className={`text-xs px-2.5 py-1 rounded-full font-medium transition-colors ${
                      statusFilter === f
                        ? f === "undocumented" ? "bg-amber-100 text-amber-700"
                          : f === "documented" ? "bg-green-100 text-green-700"
                          : "bg-primary-100 text-primary-700"
                        : "text-surface-500 hover:bg-surface-100"
                    }`}>
                    {f === "all" ? `All (${total})` : f === "undocumented" ? `Not Documented (${total - documented})` : `Documented (${documented})`}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex gap-2">
              {statusFilter === "undocumented" && displayTables.length > 0 && (
                <Button variant="outline" size="sm" onClick={() => setSelectedTables(new Set(displayTables.map((t) => t.table_name)))}>
                  Select All Undocumented
                </Button>
              )}
              <Button variant="outline" size="sm" onClick={toggleAll} disabled={!displayTables.length}>
                {selectedTables.size === displayTables.length && displayTables.length > 0 ? "Deselect All" : "Select All"}
              </Button>
              <Button size="sm"
                disabled={selectedTables.size === 0 || proceedMutation.isPending}
                onClick={() => proceedMutation.mutate()}>
                {proceedMutation.isPending ? "Processing…" : `Proceed Metadata (${selectedTables.size})`}
              </Button>
            </div>
          </div>

          {proceeded && (
            <div className="bg-primary-50 border-b border-primary-100 px-4 py-2 text-sm text-primary-700">
              {proceedResult?.message ?? "Metadata auto-population completed."}{" "}
              <button onClick={() => router.push(`/metadata/${projectId}`)} className="underline font-medium">Open attribute grid →</button>
            </div>
          )}

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-10">
                  <input type="checkbox" className="rounded"
                    checked={selectedTables.size === total && total > 0}
                    onChange={toggleAll} />
                </TableHead>
                <TableHead>Table Name</TableHead>
                <TableHead>Source</TableHead>
                <TableHead>Columns</TableHead>
                <TableHead>Rows</TableHead>
                <TableHead>Status</TableHead>
                <TableHead />
              </TableRow>
            </TableHeader>
            <TableBody>
              {!displayTables.length && !loadingAllTables && !uploading ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-10 text-surface-400">
                    {sourceType === "excel" && excelSheets.length === 0 ? "Upload an Excel file above to add new sheets, or no tables documented yet" : "No tables found"}
                  </TableCell>
                </TableRow>
              ) : displayTables.map((t) => (
                <TableRow key={t.table_name} className={selectedTables.has(t.table_name) ? "bg-primary-50" : ""}>
                  <TableCell>
                    <input type="checkbox" className="rounded"
                      checked={selectedTables.has(t.table_name)}
                      onChange={() => toggleTable(t.table_name)} />
                  </TableCell>
                  <TableCell className="font-mono text-sm font-medium text-surface-800">{t.table_name}</TableCell>
                  <TableCell>
                    <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded-full ${
                      t.source_type === "gcp" ? "bg-blue-50 text-blue-700" :
                      t.source_type === "postgresql" ? "bg-teal-50 text-teal-700" :
                      t.source_type === "excel" ? "bg-green-50 text-green-700" :
                      "bg-surface-100 text-surface-600"
                    }`}>
                      {t.source_type === "gcp" ? "☁ GCP" :
                       t.source_type === "postgresql" ? "🐘 PostgreSQL" :
                       t.source_type === "excel" ? "📊 Excel" : t.source_type}
                    </span>
                  </TableCell>
                  <TableCell className="text-surface-600">{t.column_count}</TableCell>
                  <TableCell className="text-surface-600">{t.row_count?.toLocaleString() ?? "—"}</TableCell>
                  <TableCell>
                    <Badge variant={t.documented ? "success" : "default"}>
                      {t.documented ? "Documented" : "Not Documented"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    {t.documented && (
                      <button
                        onClick={() => router.push(`/metadata/${projectId}?table=${encodeURIComponent(t.table_name)}`)}
                        className="text-xs text-primary-600 hover:underline">
                        Open Grid →
                      </button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
