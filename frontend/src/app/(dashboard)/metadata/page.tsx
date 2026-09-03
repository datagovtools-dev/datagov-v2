"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import {
  Database,
  Cloud,
  FileSpreadsheet,
  Server,
  UploadCloud,
  CheckCircle2,
  Sparkles,
  ArrowRight,
  Filter,
} from "lucide-react";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";

interface ProjectOption {
  id: string;
  project_code: string | null;
  project_name: string;
}
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
  const { refetch: refetchTables, isFetching: discovering } = useQuery<SourceTableInfo[]>({
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
    mutationFn: () =>
      api.post<ProceedResponse>("/metadata/proceed", {
        project_id: projectId,
        source_type: sourceType,
        gcp_project: gcpProject || undefined,
        bq_dataset: bqDataset || undefined,
        table_names: selectedTables.size > 0 ? [...selectedTables] : undefined,
        connection_string: connectionString || undefined,
        pg_schema: pgSchema || undefined,
        temp_file_keys: tempFileKeys.length > 0 ? tempFileKeys : undefined,
        file_names: uploadedFileNames.length > 0 ? uploadedFileNames : undefined,
        uploaded_tables:
          sourceType === "excel"
            ? uploadedTables.filter((table) => selectedTables.has(table.table_name))
            : undefined,
      }),
    onSuccess: (result) => {
      setProceeded(true);
      setProceedResult(result);
      if (sourceType === "excel") {
        setExcelSheets((sheets) =>
          sheets.map((sheet) =>
            selectedTables.has(sheet.table_name) ? { ...sheet, documented: true } : sheet
          )
        );
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
        if (!res.ok) {
          const err = await res.json();
          throw new Error(`${file.name}: ${err.detail ?? "Upload failed"}`);
        }
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

  const allTables = excelSheets.length > 0 ? excelSheets : projectTables ?? [];
  const displayTables =
    statusFilter === "all"
      ? allTables
      : statusFilter === "documented"
      ? allTables.filter((t) => t.documented)
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
      setSelectedTables((s) => {
        const n = new Set(s);
        visibleNames.forEach((name) => n.delete(name));
        return n;
      });
    } else {
      setSelectedTables((s) => new Set([...s, ...visibleNames]));
    }
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Metadata Management
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Discover source schemas, auto-populate column attributes, and catalog business definitions
          </p>
          {stats && (
            <div className="flex items-center gap-2.5 mt-1 text-xs text-slate-500 font-mono">
              <span>
                <span className="font-semibold text-slate-900">{stats.projects.toLocaleString()}</span> projects
              </span>
              <span className="text-slate-300">·</span>
              <span>
                <span className="font-semibold text-slate-900">{stats.tables.toLocaleString()}</span> tables
              </span>
              <span className="text-slate-300">·</span>
              <span>
                <span className="font-semibold text-slate-900">{stats.attributes.toLocaleString()}</span> attributes
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Source Configuration Card */}
      <div className="rounded-md border border-slate-200 bg-white p-4 shadow-2xs space-y-3.5">
        <div className="flex items-center justify-between pb-2.5 border-b border-slate-100">
          <div>
            <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-700 font-mono">
              Source Configuration
            </h2>
            <p className="text-[11px] text-slate-500">Select project and data source connector</p>
          </div>
          <Badge variant="default" className="text-[10px] font-mono">Ingestion Engine</Badge>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Select Governance Project
            </label>
            <select
              value={projectId}
              onChange={(e) => {
                setProjectId(e.target.value);
                setSelectedTables(new Set());
                setProceeded(false);
                setProceedResult(null);
              }}
              className="w-full border border-slate-200 rounded-md px-2.5 py-1.5 text-xs bg-white text-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-950 font-mono"
            >
              <option value="">Choose a project...</option>
              {projects?.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Data Source Connector
            </label>
            <div className="grid grid-cols-3 gap-1.5">
              <button
                type="button"
                onClick={() => {
                  setSourceType("gcp");
                  setProceeded(false);
                  setProceedResult(null);
                }}
                className={`flex items-center justify-center gap-1.5 py-1.5 rounded-md border text-xs font-medium transition-colors ${
                  sourceType === "gcp"
                    ? "border-slate-900 bg-slate-900 text-white font-semibold"
                    : "border-slate-200 text-slate-600 hover:bg-slate-50"
                }`}
              >
                <Cloud className="h-3.5 w-3.5" /> BigQuery
              </button>
              <button
                type="button"
                onClick={() => {
                  setSourceType("postgresql");
                  setProceeded(false);
                  setProceedResult(null);
                }}
                className={`flex items-center justify-center gap-1.5 py-1.5 rounded-md border text-xs font-medium transition-colors ${
                  sourceType === "postgresql"
                    ? "border-slate-900 bg-slate-900 text-white font-semibold"
                    : "border-slate-200 text-slate-600 hover:bg-slate-50"
                }`}
              >
                <Server className="h-3.5 w-3.5" /> Postgres
              </button>
              <button
                type="button"
                onClick={() => {
                  setSourceType("excel");
                  setProceeded(false);
                  setProceedResult(null);
                }}
                className={`flex items-center justify-center gap-1.5 py-1.5 rounded-md border text-xs font-medium transition-colors ${
                  sourceType === "excel"
                    ? "border-slate-900 bg-slate-900 text-white font-semibold"
                    : "border-slate-200 text-slate-600 hover:bg-slate-50"
                }`}
              >
                <FileSpreadsheet className="h-3.5 w-3.5" /> Excel / CSV
              </button>
            </div>
          </div>

          {sourceType === "gcp" && (
            <>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">GCP Project ID</label>
                <Input
                  value={gcpProject}
                  onChange={(e) => setGcpProject(e.target.value)}
                  placeholder="e.g. data-warehouse-prod"
                  className="h-8 text-xs font-mono"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">BigQuery Dataset</label>
                <Input
                  value={bqDataset}
                  onChange={(e) => setBqDataset(e.target.value)}
                  placeholder="e.g. customer_analytics"
                  className="h-8 text-xs font-mono"
                />
              </div>
            </>
          )}

          {sourceType === "postgresql" && (
            <>
              <div className="md:col-span-2">
                <label className="block text-xs font-semibold text-slate-700 mb-1">Connection String</label>
                <Input
                  type="password"
                  value={connectionString}
                  onChange={(e) => setConnectionString(e.target.value)}
                  placeholder="postgresql://user:password@host:5432/dbname"
                  className="h-8 text-xs font-mono"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Schema</label>
                <Input value={pgSchema} onChange={(e) => setPgSchema(e.target.value)} placeholder="public" className="h-8 text-xs font-mono" />
              </div>
            </>
          )}

          {sourceType === "excel" && (
            <div className="md:col-span-2">
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Upload File (.xlsx, .xls, .csv)
              </label>
              <div
                className={`flex flex-col items-center justify-center w-full h-28 border border-dashed rounded-md cursor-pointer transition-colors ${
                  uploading
                    ? "border-slate-400 bg-slate-50"
                    : "border-slate-200 bg-slate-50/50 hover:border-slate-300 hover:bg-slate-50"
                }`}
                onClick={() => document.getElementById("excel-upload-input")?.click()}
                onDragOver={(e) => e.preventDefault()}
                onDrop={(e) => {
                  e.preventDefault();
                  if (e.dataTransfer.files?.length) handleExcelUpload(e.dataTransfer.files);
                }}
              >
                <input
                  id="excel-upload-input"
                  type="file"
                  accept=".xlsx,.xls,.csv"
                  multiple
                  className="hidden"
                  onChange={(e) => {
                    if (e.target.files?.length) handleExcelUpload(e.target.files);
                  }}
                />
                <UploadCloud
                  className={`h-5 w-5 mb-1.5 ${
                    uploading ? "text-slate-700 animate-bounce" : "text-slate-400"
                  }`}
                />
                {uploading ? (
                  <p className="text-xs font-medium text-slate-700 font-mono">
                    Reading sheets and parsing schema...
                  </p>
                ) : uploadedFileNames.length > 0 ? (
                  <div className="text-center">
                    <p className="text-xs font-semibold text-emerald-700 font-mono">
                      ✓ {uploadedFileNames.length === 1 ? uploadedFileNames[0] : `${uploadedFileNames.length} files uploaded`}
                    </p>
                    <p className="text-[11px] text-slate-500 mt-0.5">
                      {excelSheets.length} sheet{excelSheets.length !== 1 ? "s" : ""} found · click to replace
                    </p>
                  </div>
                ) : (
                  <div className="text-center">
                    <p className="text-xs font-medium text-slate-700">
                      Click to upload or drag & drop spreadsheets
                    </p>
                    <p className="text-[10px] text-slate-400 font-mono mt-0.5">
                      Supports multi-sheet Excel & CSV files
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {sourceType !== "excel" && (
          <div className="pt-1">
            <Button
              disabled={!projectId || discovering}
              loading={discovering}
              onClick={() => refetchTables()}
              variant="outline"
              size="sm"
              className="h-7.5 text-xs font-medium"
            >
              Discover Source Tables
            </Button>
          </div>
        )}
      </div>

      {/* Documentation Progress */}
      {displayTables.length > 0 && (
        <div className="rounded-md border border-slate-200 bg-white p-3.5 flex items-center gap-4 shadow-2xs">
          <div className="flex-1">
            <div className="flex justify-between text-xs mb-1">
              <span className="text-slate-500 font-medium font-mono text-[11px]">Metadata Catalog Completion</span>
              <span className="font-semibold text-slate-900 font-mono text-[11px]">
                {documented}/{total} tables documented
              </span>
            </div>
            <div className="bg-slate-100 rounded-md h-2 overflow-hidden">
              <div
                className="bg-slate-900 h-2 rounded-md transition-all duration-200"
                style={{ width: total > 0 ? `${(documented / total) * 100}%` : "0%" }}
              />
            </div>
          </div>
          <span className="text-xs font-bold text-slate-900 tabular-nums font-mono">
            {total > 0 ? Math.round((documented / total) * 100) : 0}%
          </span>
        </div>
      )}

      {/* Source Tables List */}
      {projectId && (
        <div className="rounded-md border border-slate-200 bg-white shadow-2xs overflow-hidden">
          <div className="flex flex-wrap items-center justify-between gap-2.5 px-3.5 py-2.5 border-b border-slate-200 bg-slate-50/50">
            <div className="flex items-center gap-3">
              <h2 className="text-xs font-semibold uppercase tracking-wider text-slate-700 font-mono">
                Discovered Tables
              </h2>
              <div className="flex gap-1">
                {(["all", "undocumented", "documented"] as const).map((f) => (
                  <button
                    key={f}
                    onClick={() => setStatusFilter(f)}
                    className={`text-[10px] font-mono px-2 py-0.5 rounded-md font-medium transition-colors ${
                      statusFilter === f
                        ? "bg-slate-900 text-white font-semibold"
                        : "text-slate-600 hover:bg-slate-200/60"
                    }`}
                  >
                    {f === "all"
                      ? `All (${total})`
                      : f === "undocumented"
                      ? `Pending (${total - documented})`
                      : `Documented (${documented})`}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                className="h-6.5 text-[11px]"
                onClick={toggleAll}
                disabled={!displayTables.length}
              >
                {selectedTables.size === displayTables.length && displayTables.length > 0
                  ? "Deselect All"
                  : "Select All"}
              </Button>
              {documented > 0 && (
                <Button
                  variant="outline"
                  size="sm"
                  className="h-6.5 text-[11px]"
                  onClick={() => router.push(`/metadata/${projectId}`)}
                >
                  Open Dictionary <ArrowRight className="h-3 w-3 ml-1" />
                </Button>
              )}
              <Button
                size="sm"
                className="h-6.5 text-[11px] font-medium"
                disabled={selectedTables.size === 0 || proceedMutation.isPending}
                loading={proceedMutation.isPending}
                onClick={() => proceedMutation.mutate()}
              >
                Proceed Metadata ({selectedTables.size})
              </Button>
            </div>
          </div>

          {proceeded && (
            <div className="bg-emerald-50 border-b border-emerald-200 px-3.5 py-2 text-xs text-emerald-800 flex items-center justify-between font-mono">
              <span className="flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                {proceedResult?.message ?? "Metadata auto-population completed."}
              </span>
              <button
                onClick={() => router.push(`/metadata/${projectId}`)}
                className="underline font-semibold hover:text-emerald-950"
              >
                Open attribute grid →
              </button>
            </div>
          )}

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-10">
                  <input
                    type="checkbox"
                    className="rounded-sm border-slate-300"
                    checked={selectedTables.size === total && total > 0}
                    onChange={toggleAll}
                  />
                </TableHead>
                <TableHead>Table Name</TableHead>
                <TableHead>Source Connector</TableHead>
                <TableHead>Columns</TableHead>
                <TableHead>Rows</TableHead>
                <TableHead>Catalog Status</TableHead>
                <TableHead className="text-right w-24">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {!displayTables.length && !loadingAllTables && !uploading ? (
                <TableRow>
                  <TableCell colSpan={7} className="text-center py-10 text-xs text-slate-400 font-mono">
                    {sourceType === "excel" && excelSheets.length === 0
                      ? "Upload an Excel file above to add new sheets, or no tables documented yet."
                      : "No tables found."}
                  </TableCell>
                </TableRow>
              ) : (
                displayTables.map((t) => (
                  <TableRow
                    key={t.table_name}
                    className={selectedTables.has(t.table_name) ? "bg-slate-50" : ""}
                  >
                    <TableCell>
                      <input
                        type="checkbox"
                        className="rounded-sm border-slate-300"
                        checked={selectedTables.has(t.table_name)}
                        onChange={() => toggleTable(t.table_name)}
                      />
                    </TableCell>
                    <TableCell className="font-mono text-xs font-semibold text-slate-900">
                      {t.table_name}
                    </TableCell>
                    <TableCell>
                      <Badge variant="default" className="text-[10px] font-mono">
                        {t.source_type === "gcp"
                          ? "BigQuery"
                          : t.source_type === "postgresql"
                          ? "Postgres"
                          : t.source_type === "excel"
                          ? "Excel"
                          : t.source_type}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-xs text-slate-600 tabular-nums font-mono">{t.column_count}</TableCell>
                    <TableCell className="text-xs text-slate-600 tabular-nums font-mono">
                      {t.row_count?.toLocaleString() ?? "—"}
                    </TableCell>
                    <TableCell>
                      <Badge variant={t.documented ? "success" : "neutral"} className="text-[10px]">
                        {t.documented ? "Documented" : "Pending"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      {t.documented && (
                        <button
                          onClick={() =>
                            router.push(
                              `/metadata/${projectId}?table=${encodeURIComponent(t.table_name)}`
                            )
                          }
                          className="text-xs font-medium text-slate-700 hover:text-slate-900 hover:underline"
                        >
                          Grid →
                        </button>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      )}
    </div>
  );
}
