"use client";

import { Suspense, useCallback, useEffect, useRef, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";

interface ProjectOption { id: string; project_code: string | null; project_name: string; }

interface ProjectFileItem {
  id: string;
  project_id: string;
  source_type: string;
  original_filename: string;
  stored_path: string;
  file_size: number | null;
  uploaded_at: string;
  uploaded_by: string | null;
}

interface ProjectFilePreview {
  file_id: string;
  filename: string;
  source_type: string;
  sheet_name: string;
  row_count: number;
  columns: string[];
  preview_rows: Record<string, string | null>[];
  file_size: number | null;
  uploaded_at: string;
}

// ── Step labels ────────────────────────────────────────────────────────────────
const STEPS = [
  { n: 1, label: "Source" },
  { n: 2, label: "Connect" },
  { n: 3, label: "Preview" },
  { n: 4, label: "Generate" },
  { n: 5, label: "Results" },
  { n: 6, label: "Archive" },
];

// ── Step indicator ─────────────────────────────────────────────────────────────
function StepBar({ current }: { current: number }) {
  return (
    <div className="flex items-center gap-0">
      {STEPS.map((s, i) => (
        <div key={s.n} className="flex items-center">
          <div className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
            s.n === current ? "bg-blue-600 text-white" :
            s.n < current ? "bg-blue-100 text-blue-700" : "bg-gray-100 text-gray-400"
          }`}>
            <span className={`w-5 h-5 rounded-full text-xs flex items-center justify-center font-bold ${
              s.n === current ? "bg-white text-blue-600" :
              s.n < current ? "bg-blue-500 text-white" : "bg-gray-300 text-gray-500"
            }`}>{s.n < current ? "✓" : s.n}</span>
            {s.label}
          </div>
          {i < STEPS.length - 1 && <div className={`w-6 h-0.5 ${s.n < current ? "bg-blue-400" : "bg-gray-200"}`} />}
        </div>
      ))}
    </div>
  );
}

function formatBytes(bytes: number | null): string {
  if (!bytes) return "—";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function DQWizardPage() {
  const router = useRouter();
  const qc = useQueryClient();
  const searchParams = useSearchParams();

  const initialProject = searchParams.get("project") ?? "";
  const initialFile    = searchParams.get("file") ?? "";

  const [step, setStep] = useState(initialProject && initialFile ? 2 : 1);
  const [sourceType, setSourceType] = useState<"gcp" | "excel" | "postgres" | "project_file">(
    initialFile ? "project_file" : "gcp"
  );
  const [project_id, setProjectId] = useState(initialProject);
  const initialFileRef = useRef(initialFile);
  const [runName, setRunName] = useState("");

  // GCP params
  const [gcp, setGcp] = useState({ project: "", dataset: "", table: "" });
  const [gcpValid, setGcpValid] = useState<{ valid: boolean; message: string; columns?: string[]; row_count?: number } | null>(null);
  const [validating, setValidating] = useState(false);

  // Excel params
  const [uploadResult, setUploadResult] = useState<{
    filename: string; sheet_name: string; row_count: number;
    columns: string[]; preview_rows: Record<string, string | null>[]; temp_file_key: string;
  } | null>(null);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // PostgreSQL / Supabase params
  const [pg, setPg] = useState({ connection_string: "", table: "" });
  const [pgValid, setPgValid] = useState<{ valid: boolean; message: string; columns?: string[]; row_count?: number } | null>(null);
  const [pgValidating, setPgValidating] = useState(false);

  // Project file params (multi-select)
  const [selectedProjectFiles, setSelectedProjectFiles] = useState<Set<string>>(new Set());
  const [selectedProjectFileItems, setSelectedProjectFileItems] = useState<ProjectFileItem[]>([]);
  // Batch state — runInitiated flips to true the moment the button is clicked (guaranteed sync)
  const [runInitiated, setRunInitiated] = useState(false);
  const [batchLaunching, setBatchLaunching] = useState(false);
  const [batchRunIds, setBatchRunIds] = useState<string[]>([]);
  const [batchRunFiles, setBatchRunFiles] = useState<Array<{ id: string; filename: string }>>([]);
  const [batchRunStatuses, setBatchRunStatuses] = useState<Record<string, string>>({});

  // Step 4 — run polling
  const [runId, setRunId] = useState<string | null>(null);
  const [runStatus, setRunStatus] = useState<{ status: string; progress_pct: number; overall_score: string | null; message: string } | null>(null);

  // Reset source-specific selection when source type changes
  useEffect(() => {
    setSelectedProjectFiles(new Set());
    setSelectedProjectFileItems([]);
    setUploadResult(null);
    setGcpValid(null);
    setPgValid(null);
  }, [sourceType]);


  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: projectFiles, isLoading: projectFilesLoading } = useQuery<ProjectFileItem[]>({
    queryKey: ["dq-project-sources", project_id],
    queryFn: () => api.get<ProjectFileItem[]>(`/dq/project/${project_id}/sources`),
    enabled: sourceType === "project_file" && !!project_id,
  });

  // Pre-select file when arriving from the DQ list page via ?project=&file= params
  useEffect(() => {
    if (!initialFileRef.current || !projectFiles) return;
    const file = projectFiles.find((f: ProjectFileItem) => f.id === initialFileRef.current);
    if (!file) return;
    setSelectedProjectFiles(new Set([file.id]));
    setSelectedProjectFileItems([file]);
    initialFileRef.current = "";
  }, [projectFiles]);

  const firstSelectedFile = selectedProjectFileItems[0] ?? null;

  const { data: projectFilePreview, isLoading: previewLoading } = useQuery<ProjectFilePreview>({
    queryKey: ["dq-file-preview", firstSelectedFile?.id],
    queryFn: () => api.get<ProjectFilePreview>(`/dq/project-sources/${firstSelectedFile!.id}/preview`),
    enabled: !!firstSelectedFile,
  });

  const { data: runDetail } = useQuery({
    queryKey: ["dq-run", runId],
    queryFn: () => api.get<{ id: string; overall_score: string; results: unknown[]; status: string }>(`/dq/${runId}`),
    enabled: !!runId && (step === 5 || step === 6),
    refetchInterval: (q) => (q.state.data?.status === "completed" || q.state.data?.status === "approved") ? false : 5000,
  });

  // Poll status while generating
  useEffect(() => {
    if (!runId || step !== 4) return;
    let cancelled = false;
    const poll = async () => {
      while (!cancelled) {
        try {
          const s = await api.get<typeof runStatus>(`/dq/${runId}/status`);
          setRunStatus(s);
          if (s && (s.status === "completed" || s.status === "failed")) {
            if (s.status === "completed") setTimeout(() => setStep(5), 600);
            break;
          }
        } catch { break; }
        await new Promise((r) => setTimeout(r, 3000));
      }
    };
    poll();
    return () => { cancelled = true; };
  }, [runId, step]);

  // Poll all batch run statuses while on step 4
  useEffect(() => {
    if (!batchRunIds.length || step !== 4 || batchLaunching) return;
    let cancelled = false;
    const poll = async () => {
      while (!cancelled) {
        const statuses: Record<string, string> = {};
        await Promise.all(
          batchRunIds.map(async (id: string) => {
            try {
              const s = await api.get<{ status: string }>(`/dq/${id}/status`);
              statuses[id] = s?.status ?? "pending";
            } catch { statuses[id] = "pending"; }
          })
        );
        setBatchRunStatuses({ ...statuses });
        const allDone = Object.values(statuses).every((s) => s === "completed" || s === "failed");
        if (allDone || cancelled) break;
        await new Promise((r) => setTimeout(r, 4000));
      }
    };
    poll();
    return () => { cancelled = true; };
  }, [batchRunIds, step, batchLaunching]);

  const createRunMutation = useMutation({
    mutationFn: (payload: Record<string, unknown>) => api.post<{ id: string }>("/dq", payload),
    onSuccess: (data) => { setRunId(data.id); setStep(4); },
  });

  const reviewMutation = useMutation({
    mutationFn: ({ action, comments }: { action: string; comments?: string }) =>
      api.post(`/dq/${runId}/review`, { action, comments }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["dq-run", runId] }); setStep(6); },
  });

  const archiveMutation = useMutation({
    mutationFn: () => api.post(`/dq/${runId}/archive`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dq-run", runId] }),
  });

  // ── Handlers ────────────────────────────────────────────────────────────────
  async function handleValidateGCP() {
    setValidating(true);
    setGcpValid(null);
    try {
      const result = await api.post<typeof gcpValid>("/dq/validate-gcp", {
        gcp_project: gcp.project, bq_dataset: gcp.dataset, bq_table: gcp.table,
      });
      setGcpValid(result);
    } catch {
      setGcpValid({ valid: false, message: "Validation request failed" });
    } finally {
      setValidating(false);
    }
  }

  async function handleValidatePostgres() {
    setPgValidating(true);
    setPgValid(null);
    try {
      const result = await api.post<typeof pgValid>("/dq/validate-postgres", {
        connection_string: pg.connection_string, table_name: pg.table,
      });
      setPgValid(result);
    } catch {
      setPgValid({ valid: false, message: "Validation request failed" });
    } finally {
      setPgValidating(false);
    }
  }

  async function handleUploadExcel(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    const formData = new FormData();
    formData.append("file", file);
    try {
      const res = await fetch("/api/v1/dq/upload-excel", {
        method: "POST",
        body: formData,
        headers: { Authorization: `Bearer ${localStorage.getItem("access_token") ?? ""}` },
      });
      if (!res.ok) throw new Error(await res.text());
      setUploadResult(await res.json());
    } catch (err) {
      alert("Upload failed: " + String(err));
    } finally {
      setUploading(false);
    }
  }

  function handleLaunchRun() {
    const base = {
      project_id, run_name: runName || `DQ Run — ${new Date().toISOString().slice(0, 10)}`,
      source_type: sourceType,
    };
    if (sourceType === "gcp") {
      createRunMutation.mutate({
        ...base,
        dataset_name: `${gcp.project}.${gcp.dataset}.${gcp.table}`,
        dataset_location: `bigquery://${gcp.project}.${gcp.dataset}.${gcp.table}`,
        gcp_project: gcp.project, bq_dataset: gcp.dataset, bq_table: gcp.table,
      });
    } else if (sourceType === "postgres") {
      createRunMutation.mutate({
        ...base,
        dataset_name: pg.table,
        dataset_location: `postgres://${pg.table}`,
        postgres_connection_string: pg.connection_string,
        postgres_table: pg.table,
      });
    } else if (sourceType === "project_file") {
      if (selectedProjectFileItems.length === 1) {
        const f = selectedProjectFileItems[0];
        createRunMutation.mutate({
          ...base,
          dataset_name: f.original_filename,
          dataset_location: `project_file://${f.id}`,
          source_file_id: f.id,
        });
      } else if (selectedProjectFileItems.length > 1) {
        const items = [...selectedProjectFileItems];
        setBatchLaunching(true);
        setBatchRunIds([]);
        setBatchRunFiles([]);
        setBatchRunStatuses({});
        setStep(4);
        (async () => {
          const ids: string[] = [];
          const runFiles: Array<{ id: string; filename: string }> = [];
          for (const f of items) {
            try {
              const result = await api.post<{ id: string }>("/dq", {
                ...base,
                run_name: runName ? `${runName} (${f.original_filename})` : `DQ Run — ${f.original_filename.replace(/\.[^.]+$/, "")}`,
                dataset_name: f.original_filename,
                dataset_location: `project_file://${f.id}`,
                source_file_id: f.id,
              });
              ids.push(result.id);
              runFiles.push({ id: result.id, filename: f.original_filename });
            } catch { /* continue with remaining files */ }
          }
          setBatchRunFiles(runFiles);
          setBatchRunIds(ids);
          setBatchLaunching(false);
        })();
      }
      return;
    } else {
      createRunMutation.mutate({
        ...base,
        dataset_name: uploadResult!.filename,
        dataset_location: uploadResult!.filename,
        temp_file_key: uploadResult!.temp_file_key,
        sheet_name: uploadResult!.sheet_name,
      });
    }
  }

  const canProceedStep2 = sourceType === "gcp"
    ? (gcpValid?.valid ?? false)
    : sourceType === "postgres"
    ? (pgValid?.valid ?? false)
    : sourceType === "project_file"
    ? selectedProjectFiles.size > 0
    : !!uploadResult;

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="p-6 max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">New Data Quality Run</h1>
        <p className="text-sm text-gray-500 mt-1">
          6-step wizard — connect a data source, generate DQ checks, review, and archive to GCP
        </p>
      </div>

      <StepBar current={step} />

      {/* ── Step 1: Source selection ── */}
      {step === 1 && (
        <div className="bg-white rounded-lg shadow p-6 space-y-6">
          <h2 className="font-semibold text-gray-800">Step 1 — Choose Data Source</h2>
          <div className="grid grid-cols-2 gap-4">
            {([
              { type: "project_file", icon: "📁", label: "From Project Files",    desc: "Use data already imported via the Metadata module — no re-upload needed" },
              { type: "excel",        icon: "📊", label: "Excel (.xlsx)",          desc: "Upload a local .xlsx file for analysis" },
              { type: "gcp",         icon: "☁",  label: "GCP BigQuery",           desc: "Connect to a BigQuery table using a service account" },
              { type: "postgres",    icon: "🐘", label: "PostgreSQL / Supabase",   desc: "Connect directly via a PostgreSQL connection string" },
            ] as const).map(({ type, icon, label, desc }) => (
              <button key={type} onClick={() => setSourceType(type)}
                className={`p-5 rounded-xl border-2 text-left transition-all ${
                  sourceType === type ? "border-blue-500 bg-blue-50" : "border-gray-200 hover:border-gray-300"
                }`}>
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-2xl">{icon}</span>
                  {type === "project_file" && (
                    <span className="text-xs font-semibold bg-green-100 text-green-700 px-2 py-0.5 rounded-full">Recommended</span>
                  )}
                </div>
                <p className="font-semibold text-gray-800">{label}</p>
                <p className="text-sm text-gray-500 mt-1">{desc}</p>
              </button>
            ))}
          </div>
          <div className="grid grid-cols-2 gap-4 pt-2">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Project <span className="text-red-500">*</span></label>
              <select value={project_id} onChange={(e) => setProjectId(e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">Select project…</option>
                {projects?.map((p) => <option key={p.id} value={p.id}>{p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Run Name</label>
              <Input value={runName} onChange={(e) => setRunName(e.target.value)} placeholder="Auto-generated if blank" />
            </div>
          </div>
          <div className="flex justify-end">
            <Button disabled={!project_id} onClick={() => setStep(2)}>Next →</Button>
          </div>
        </div>
      )}

      {/* ── Step 2: Connect / Upload / Select ── */}
      {step === 2 && (
        <div className="bg-white rounded-lg shadow p-6 space-y-5">
          <h2 className="font-semibold text-gray-800">
            Step 2 — {
              sourceType === "gcp" ? "Connect to BigQuery" :
              sourceType === "postgres" ? "Connect to PostgreSQL / Supabase" :
              sourceType === "project_file" ? "Select Project Files" :
              "Upload Excel File"
            }
          </h2>

          {/* ── From Project Files ── */}
          {sourceType === "project_file" && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <p className="text-sm text-gray-500">
                  Files imported via the Metadata module. Select one or more — each generates a separate DQ run.
                </p>
                {projectFiles && projectFiles.length > 0 && (
                  <button
                    onClick={() => {
                      if (selectedProjectFiles.size === projectFiles.length) {
                        setSelectedProjectFiles(new Set());
                        setSelectedProjectFileItems([]);
                      } else {
                        setSelectedProjectFiles(new Set(projectFiles.map((f: ProjectFileItem) => f.id)));
                        setSelectedProjectFileItems([...projectFiles]);
                      }
                    }}
                    className="text-xs font-medium text-blue-600 hover:text-blue-800 whitespace-nowrap ml-4"
                  >
                    {selectedProjectFiles.size === projectFiles.length ? "Deselect All" : "Select All"}
                  </button>
                )}
              </div>
              {projectFilesLoading ? (
                <div className="text-sm text-blue-600 text-center py-6">Loading project files…</div>
              ) : !projectFiles || projectFiles.length === 0 ? (
                <div className="border-2 border-dashed border-gray-200 rounded-xl p-8 text-center">
                  <div className="text-4xl mb-2">📂</div>
                  <p className="font-medium text-gray-500">No files imported yet</p>
                  <p className="text-sm text-gray-400 mt-1">
                    Import data in the Metadata module first, then return here to run DQ on it.
                  </p>
                </div>
              ) : (
                <div className="space-y-2 max-h-80 overflow-y-auto pr-1">
                  {projectFiles.map((f: ProjectFileItem) => {
                    const isSelected = selectedProjectFiles.has(f.id);
                    return (
                      <button
                        key={f.id}
                        onClick={() => {
                          setSelectedProjectFiles((prev) => {
                            const next = new Set(prev);
                            if (next.has(f.id)) next.delete(f.id); else next.add(f.id);
                            return next;
                          });
                          setSelectedProjectFileItems((prev) =>
                            prev.some((x) => x.id === f.id)
                              ? prev.filter((x) => x.id !== f.id)
                              : [...prev, f]
                          );
                        }}
                        className={`w-full text-left p-4 rounded-lg border-2 transition-all ${
                          isSelected ? "border-blue-500 bg-blue-50" : "border-gray-200 hover:border-gray-300 bg-white"
                        }`}
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex items-center gap-2 min-w-0">
                            <div className={`w-5 h-5 rounded border-2 flex items-center justify-center flex-shrink-0 ${
                              isSelected ? "bg-blue-500 border-blue-500" : "border-gray-300"
                            }`}>
                              {isSelected && <span className="text-white text-xs font-bold">✓</span>}
                            </div>
                            <span className="text-xl flex-shrink-0">📄</span>
                            <div className="min-w-0">
                              <p className="font-medium text-gray-800 truncate">{f.original_filename}</p>
                              <p className="text-xs text-gray-400 mt-0.5">
                                {formatBytes(f.file_size)} · Imported {new Date(f.uploaded_at).toLocaleDateString()}
                                {f.uploaded_by && ` by ${f.uploaded_by}`}
                              </p>
                            </div>
                          </div>
                        </div>
                      </button>
                    );
                  })}
                </div>
              )}
              {selectedProjectFiles.size > 0 && (
                <div className="bg-green-50 border border-green-200 rounded p-3 text-sm text-green-800">
                  {selectedProjectFiles.size === 1
                    ? `✓ Selected: ${firstSelectedFile?.original_filename} (${formatBytes(firstSelectedFile?.file_size ?? null)})`
                    : `✓ ${selectedProjectFiles.size} files selected — ${selectedProjectFiles.size} DQ runs will be queued`}
                </div>
              )}
            </div>
          )}

          {/* ── PostgreSQL ── */}
          {sourceType === "postgres" && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Connection String <span className="text-red-500">*</span>
                </label>
                <input
                  type="password"
                  value={pg.connection_string}
                  onChange={(e) => setPg((p) => ({ ...p, connection_string: e.target.value }))}
                  placeholder="postgresql://postgres:[password]@db.[ref].supabase.co:5432/postgres"
                  className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <p className="text-xs text-gray-400 mt-1">
                  Find this in Supabase → Project Settings → Database → Connection string (URI mode)
                </p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Table Name <span className="text-red-500">*</span>
                </label>
                <Input
                  value={pg.table}
                  onChange={(e) => setPg((p) => ({ ...p, table: e.target.value }))}
                  placeholder="e.g. customer"
                />
              </div>
              <Button
                variant="outline"
                disabled={!pg.connection_string || !pg.table || pgValidating}
                onClick={handleValidatePostgres}
              >
                {pgValidating ? "Validating…" : "Test Connection"}
              </Button>
              {pgValid && (
                <div className={`p-3 rounded-lg border text-sm ${pgValid.valid ? "bg-green-50 border-green-300 text-green-800" : "bg-red-50 border-red-300 text-red-800"}`}>
                  {pgValid.valid ? "✓ " : "✗ "}{pgValid.message}
                  {pgValid.valid && pgValid.columns && (
                    <p className="mt-1 text-xs text-green-600">{pgValid.columns.length} columns detected</p>
                  )}
                </div>
              )}
            </div>
          )}

          {/* ── GCP BigQuery ── */}
          {sourceType === "gcp" && (
            <div className="space-y-4">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">GCP Project</label>
                  <Input value={gcp.project} onChange={(e) => setGcp((g) => ({ ...g, project: e.target.value }))} placeholder="my-gcp-project" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Dataset</label>
                  <Input value={gcp.dataset} onChange={(e) => setGcp((g) => ({ ...g, dataset: e.target.value }))} placeholder="my_dataset" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Table</label>
                  <Input value={gcp.table} onChange={(e) => setGcp((g) => ({ ...g, table: e.target.value }))} placeholder="my_table" />
                </div>
              </div>
              <Button variant="outline" disabled={!gcp.project || !gcp.dataset || !gcp.table || validating}
                onClick={handleValidateGCP}>
                {validating ? "Validating…" : "Validate Connection"}
              </Button>
              {gcpValid && (
                <div className={`p-3 rounded-lg border ${gcpValid.valid ? "bg-green-50 border-green-300 text-green-800" : "bg-red-50 border-red-300 text-red-800"} text-sm`}>
                  {gcpValid.valid ? "✓ " : "✗ "}{gcpValid.message}
                  {gcpValid.valid && gcpValid.columns && (
                    <p className="mt-1 text-xs text-green-600">{gcpValid.columns.length} columns detected</p>
                  )}
                </div>
              )}
            </div>
          )}

          {/* ── Excel upload ── */}
          {sourceType === "excel" && (
            <div className="space-y-4">
              <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center cursor-pointer hover:border-blue-400 transition-colors"
                onClick={() => fileInputRef.current?.click()}>
                <input ref={fileInputRef} type="file" accept=".xlsx,.xls" className="hidden" onChange={handleUploadExcel} />
                <div className="text-4xl mb-2">📎</div>
                <p className="font-medium text-gray-700">Click to upload or drag & drop</p>
                <p className="text-sm text-gray-400 mt-1">.xlsx or .xls files only</p>
              </div>
              {uploading && <p className="text-sm text-blue-600 text-center">Uploading and parsing…</p>}
              {uploadResult && (
                <div className="bg-green-50 border border-green-200 rounded p-3 text-sm text-green-800">
                  ✓ <strong>{uploadResult.filename}</strong> — {uploadResult.row_count.toLocaleString()} rows,{" "}
                  {uploadResult.columns.length} columns (sheet: {uploadResult.sheet_name})
                </div>
              )}
            </div>
          )}

          <div className="flex justify-between pt-2">
            <Button variant="outline" onClick={() => setStep(1)}>← Back</Button>
            <Button disabled={!canProceedStep2} onClick={() => setStep(3)}>Next →</Button>
          </div>
        </div>
      )}

      {/* ── Step 3: Preview ── */}
      {step === 3 && (
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <h2 className="font-semibold text-gray-800">Step 3 — Data Preview</h2>

          {/* Project file preview */}
          {sourceType === "project_file" && selectedProjectFiles.size > 0 && (
            <div className="space-y-3">
              {selectedProjectFiles.size > 1 ? (
                <div className="space-y-2">
                  <div className="bg-blue-50 border border-blue-200 rounded p-3 text-sm text-blue-800">
                    {selectedProjectFiles.size} files selected — {selectedProjectFiles.size} separate DQ runs will be queued on launch.
                  </div>
                  {selectedProjectFileItems.map((f: ProjectFileItem) => (
                    <div key={f.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded border border-gray-200 text-sm">
                      <span>📄</span>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-gray-800 truncate">{f.original_filename}</p>
                        <p className="text-xs text-gray-500">{formatBytes(f.file_size)} · {new Date(f.uploaded_at).toLocaleDateString()}</p>
                      </div>
                      <span className="text-green-600 font-bold text-xs">✓ queued</span>
                    </div>
                  ))}
                </div>
              ) : firstSelectedFile && (
                <div className="space-y-3">
                  <div className="flex gap-4 text-sm text-gray-600 flex-wrap">
                    <span><strong>File:</strong> {firstSelectedFile.original_filename}</span>
                    <span><strong>Size:</strong> {formatBytes(firstSelectedFile.file_size)}</span>
                    <span><strong>Imported:</strong> {new Date(firstSelectedFile.uploaded_at).toLocaleDateString()}</span>
                    {projectFilePreview && (
                      <span><strong>Sheet:</strong> {projectFilePreview.sheet_name} · {projectFilePreview.row_count.toLocaleString()} rows · {projectFilePreview.columns.length} columns</span>
                    )}
                  </div>
                  {previewLoading ? (
                    <div className="text-sm text-blue-600 text-center py-4">Loading preview…</div>
                  ) : projectFilePreview && projectFilePreview.columns.length > 0 ? (
                    <div className="space-y-1">
                      <div className="overflow-x-auto rounded border border-gray-200">
                        <table className="min-w-full text-xs">
                          <thead className="bg-gray-50">
                            <tr>
                              {projectFilePreview.columns.map((c) => (
                                <th key={c} className="px-3 py-2 text-left font-medium text-gray-600 whitespace-nowrap border-r border-gray-200 last:border-r-0">{c}</th>
                              ))}
                            </tr>
                          </thead>
                          <tbody>
                            {projectFilePreview.preview_rows.map((row, i) => (
                              <tr key={i} className={i % 2 === 0 ? "bg-white" : "bg-gray-50"}>
                                {projectFilePreview.columns.map((c) => (
                                  <td key={c} className="px-3 py-1.5 border-r border-gray-100 last:border-r-0 text-gray-700 max-w-[120px] truncate">
                                    {row[c] ?? <span className="text-gray-300 italic">null</span>}
                                  </td>
                                ))}
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                      <p className="text-xs text-gray-400">Showing first 10 rows from {projectFilePreview.sheet_name}</p>
                    </div>
                  ) : (
                    <div className="bg-yellow-50 border border-yellow-200 rounded p-3 text-sm text-yellow-800">
                      Preview unavailable — the file will be read directly during DQ generation.
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* Excel preview */}
          {sourceType === "excel" && uploadResult && (
            <div className="space-y-3">
              <div className="flex gap-4 text-sm text-gray-600">
                <span><strong>File:</strong> {uploadResult.filename}</span>
                <span><strong>Sheet:</strong> {uploadResult.sheet_name}</span>
                <span><strong>Rows:</strong> {uploadResult.row_count.toLocaleString()}</span>
                <span><strong>Columns:</strong> {uploadResult.columns.length}</span>
              </div>
              <div className="overflow-x-auto rounded border border-gray-200">
                <table className="min-w-full text-xs">
                  <thead className="bg-gray-50">
                    <tr>
                      {uploadResult.columns.map((c) => (
                        <th key={c} className="px-3 py-2 text-left font-medium text-gray-600 whitespace-nowrap border-r border-gray-200 last:border-r-0">
                          {c}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {uploadResult.preview_rows.map((row, i) => (
                      <tr key={i} className={i % 2 === 0 ? "bg-white" : "bg-gray-50"}>
                        {uploadResult.columns.map((c) => (
                          <td key={c} className="px-3 py-1.5 border-r border-gray-100 last:border-r-0 text-gray-700 max-w-[120px] truncate">
                            {row[c] ?? <span className="text-gray-300 italic">null</span>}
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <p className="text-xs text-gray-400">Showing first 10 rows</p>
            </div>
          )}

          {/* PostgreSQL preview */}
          {sourceType === "postgres" && pgValid?.columns && (
            <div className="space-y-3">
              <div className="flex gap-4 text-sm text-gray-600">
                <span><strong>Table:</strong> {pg.table}</span>
                <span><strong>Rows:</strong> {pgValid.row_count?.toLocaleString()}</span>
                <span><strong>Columns:</strong> {pgValid.columns.length}</span>
              </div>
              <div className="flex flex-wrap gap-2">
                {pgValid.columns.map((c) => (
                  <span key={c} className="bg-purple-50 text-purple-700 text-xs px-2 py-1 rounded border border-purple-200 font-mono">{c}</span>
                ))}
              </div>
              <p className="text-xs text-gray-400">Full data preview available after DQ run completes</p>
            </div>
          )}

          {/* GCP preview */}
          {sourceType === "gcp" && gcpValid?.columns && (
            <div className="space-y-3">
              <div className="flex gap-4 text-sm text-gray-600">
                <span><strong>Table:</strong> {gcp.project}.{gcp.dataset}.{gcp.table}</span>
                <span><strong>Rows:</strong> {gcpValid.row_count?.toLocaleString()}</span>
                <span><strong>Columns:</strong> {gcpValid.columns.length}</span>
              </div>
              <div className="flex flex-wrap gap-2">
                {gcpValid.columns.map((c) => (
                  <span key={c} className="bg-blue-50 text-blue-700 text-xs px-2 py-1 rounded border border-blue-200 font-mono">{c}</span>
                ))}
              </div>
              <p className="text-xs text-gray-400">Full data preview requires BigQuery live connection</p>
            </div>
          )}

          <div className="flex justify-between pt-2">
            <Button variant="outline" onClick={() => setStep(2)}>← Back</Button>
            <Button onClick={() => setStep(4)}>Next →</Button>
          </div>
        </div>
      )}

      {/* ── Step 4: Generate ── */}
      {step === 4 && (
        <div className="bg-white rounded-lg shadow p-6 space-y-6">
          <h2 className="font-semibold text-gray-800 text-center">Step 4 — Generate DQ Checks</h2>

          {/* Batch mode: runInitiated flips synchronously on button click → guaranteed immediate UI change */}
          {sourceType === "project_file" && selectedProjectFileItems.length > 1 ? (
            runInitiated ? (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-gray-800">
                      {batchLaunching
                        ? `Queuing ${selectedProjectFileItems.length} DQ runs…`
                        : batchRunFiles.length > 0
                        ? (() => {
                            const done = batchRunFiles.filter((r) => ["completed","failed"].includes(batchRunStatuses[r.id] ?? "")).length;
                            const allDone = done === batchRunFiles.length;
                            return allDone ? `All ${batchRunFiles.length} runs completed` : `Processing — ${done} / ${batchRunFiles.length} done`;
                          })()
                        : "Runs queued — processing in background"}
                    </p>
                    <p className="text-xs text-gray-400 mt-0.5">Each file is analysed independently. DQ checks run in parallel.</p>
                  </div>
                  <Button size="sm" variant="outline" onClick={() => router.push("/dq")}>View DQ Runs</Button>
                </div>

                {/* Progress bar — shows 0 while queuing, fills as runs complete */}
                {batchRunFiles.length > 0 && (
                  <div className="w-full bg-gray-100 rounded-full h-2">
                    <div className="bg-blue-500 h-2 rounded-full transition-all duration-700"
                      style={{ width: `${(batchRunFiles.filter((r) => ["completed","failed"].includes(batchRunStatuses[r.id] ?? "")).length / batchRunFiles.length) * 100}%` }} />
                  </div>
                )}

                {/* Per-run status rows */}
                <div className="space-y-2">
                  {(batchRunFiles.length > 0 ? batchRunFiles.map((r) => ({ id: r.id, filename: r.filename, status: batchRunStatuses[r.id] ?? "pending" }))
                    : selectedProjectFileItems.map((f) => ({ id: f.id, filename: f.original_filename, status: "queuing" }))
                  ).map((row) => (
                    <div key={row.id} className="flex items-center gap-3 px-4 py-3 rounded-lg border border-gray-100 bg-gray-50">
                      <div className="w-5 flex-shrink-0 flex items-center justify-center">
                        {row.status === "completed" && <span className="text-green-600 font-bold">✓</span>}
                        {row.status === "failed"    && <span className="text-red-500 font-bold">✗</span>}
                        {(row.status === "running" || row.status === "queuing") &&
                          <div className="w-4 h-4 rounded-full border-2 border-blue-200 border-t-blue-600 animate-spin" />}
                        {row.status === "pending"  && <div className="w-4 h-4 rounded-full border-2 border-gray-300 bg-white" />}
                      </div>
                      <span className="text-sm text-gray-700 flex-1 min-w-0 truncate">📄 {row.filename}</span>
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize whitespace-nowrap ${
                        row.status === "completed" ? "bg-green-100 text-green-700" :
                        row.status === "failed"    ? "bg-red-100 text-red-700" :
                        row.status === "running"   ? "bg-blue-100 text-blue-700" :
                        row.status === "queuing"   ? "bg-yellow-100 text-yellow-700" :
                        "bg-gray-100 text-gray-500"
                      }`}>{row.status}</span>
                    </div>
                  ))}
                </div>

                {batchRunFiles.length > 0 && batchRunFiles.every((r) => ["completed","failed"].includes(batchRunStatuses[r.id] ?? "")) && (
                  <div className="bg-green-50 border border-green-200 rounded-lg p-3 text-sm text-green-800 text-center">
                    All runs finished. Open each run from the DQ list to review and approve.
                  </div>
                )}
              </div>
            ) : (
              <div className="space-y-4 text-center">
                <p className="text-gray-500 text-sm">
                  {selectedProjectFileItems.length} files selected. Each file will generate a separate DQ run with completeness, uniqueness, consistency, and latency checks.
                </p>
                <div className="space-y-1.5 max-w-sm mx-auto">
                  {selectedProjectFileItems.map((f) => (
                    <div key={f.id} className="flex items-center gap-2 text-sm text-gray-600 bg-gray-50 rounded px-3 py-2">
                      <span>📄</span>
                      <span className="truncate">{f.original_filename}</span>
                      <span className="ml-auto text-xs text-gray-400">{formatBytes(f.file_size)}</span>
                    </div>
                  ))}
                </div>
                <Button
                  onClick={() => { setRunInitiated(true); handleLaunchRun(); }}
                  disabled={createRunMutation.isPending}
                  className="mx-auto"
                >
                  Generate DQ Checks
                </Button>
              </div>
            )
          ) : !runId ? (
            <div className="space-y-4 text-center">
              <p className="text-gray-600 text-sm">
                Click Generate to start the async DQ analysis. The system will compute completeness, uniqueness, and consistency for every column.
              </p>
              <Button onClick={handleLaunchRun} disabled={createRunMutation.isPending} className="mx-auto">
                {createRunMutation.isPending ? "Starting…" : "Generate DQ Checks"}
              </Button>
            </div>
          ) : (
            <div className="space-y-5">
              <div className="flex flex-col items-center gap-3">
                {runStatus?.status === "running" && (
                  <div className="w-12 h-12 rounded-full border-4 border-blue-200 border-t-blue-600 animate-spin" />
                )}
                {runStatus?.status === "completed" && (
                  <div className="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center text-2xl">✓</div>
                )}
                {runStatus?.status === "failed" && (
                  <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center text-2xl">✗</div>
                )}
                <p className="font-medium text-gray-800">{runStatus?.message ?? "Queued…"}</p>
                {runStatus?.overall_score && (
                  <p className="text-3xl font-bold text-blue-600">{parseFloat(runStatus.overall_score).toFixed(1)}%</p>
                )}
              </div>
              <div className="bg-gray-100 rounded-full h-3 max-w-sm mx-auto overflow-hidden">
                <div className="bg-blue-500 h-full transition-all duration-500 rounded-full"
                  style={{ width: `${runStatus?.progress_pct ?? 0}%` }} />
              </div>
            </div>
          )}
        </div>
      )}

      {/* ── Step 5: Results ── */}
      {step === 5 && runDetail && (
        <ResultsPanel
          run={runDetail as RunDetailType}
          onApprove={(c) => reviewMutation.mutate({ action: "approve", comments: c })}
          onReject={(c) => reviewMutation.mutate({ action: "reject", comments: c })}
          onRequestRevision={(c) => reviewMutation.mutate({ action: "request_revision", comments: c })}
          reviewing={reviewMutation.isPending}
        />
      )}

      {/* ── Step 6: Archive ── */}
      {step === 6 && runDetail && (
        <ArchivePanel
          run={runDetail as RunDetailType}
          onArchive={() => archiveMutation.mutate()}
          archiving={archiveMutation.isPending}
          onFinish={() => router.push(`/dq/${runId}`)}
        />
      )}
    </div>
  );
}

// ── Results panel (Step 5) ─────────────────────────────────────────────────────
type RunDetailType = {
  id: string; overall_score: string | null; status: string;
  results: Array<{
    id: string; check_name: string; check_type: string; column_name: string | null;
    status: string; actual_value: string | null; row_count: number | null;
    failed_count: number | null; details: Record<string, unknown> | null;
    findings: Array<{ id: string; severity: string; description: string; recommendation: string | null; status: string }>;
  }>;
};

type ResultsTab = "score" | "rules" | "findings";

function ResultsPanel({ run, onApprove, onReject, onRequestRevision, reviewing }: {
  run: RunDetailType;
  onApprove: (c: string) => void;
  onReject: (c: string) => void;
  onRequestRevision: (c: string) => void;
  reviewing: boolean;
}) {
  const [tab, setTab] = useState<ResultsTab>("score");
  const [comment, setComment] = useState("");

  const score = run.overall_score ? parseFloat(run.overall_score) : null;
  const allFindings = run.results.flatMap((r) => r.findings ?? []);
  const byType = run.results.reduce<Record<string, { pass: number; fail: number; warn: number }>>((acc, r) => {
    const t = r.check_type;
    acc[t] = acc[t] ?? { pass: 0, fail: 0, warn: 0 };
    if (r.status === "pass") acc[t].pass++;
    else if (r.status === "fail") acc[t].fail++;
    else acc[t].warn++;
    return acc;
  }, {});

  return (
    <div className="bg-white rounded-lg shadow overflow-hidden">
      <div className="p-5 border-b border-gray-100">
        <div className="flex items-center justify-between">
          <h2 className="font-semibold text-gray-800">Step 5 — Review Results</h2>
          {score !== null && (
            <span className={`text-2xl font-bold ${score >= 90 ? "text-green-600" : score >= 70 ? "text-yellow-600" : "text-red-600"}`}>
              {score.toFixed(1)}% overall
            </span>
          )}
        </div>
      </div>

      {/* Tab bar */}
      <div className="flex border-b border-gray-100">
        {(["score", "rules", "findings"] as ResultsTab[]).map((t) => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-5 py-3 text-sm font-medium capitalize transition-colors border-b-2 -mb-px ${
              tab === t ? "border-blue-500 text-blue-600" : "border-transparent text-gray-500 hover:text-gray-700"
            }`}>
            {t}{t === "findings" && allFindings.length > 0 && (
              <span className="ml-1 bg-red-100 text-red-600 text-xs px-1.5 py-0.5 rounded-full">{allFindings.length}</span>
            )}
          </button>
        ))}
      </div>

      <div className="p-5">
        {tab === "score" && (
          <div className="grid grid-cols-3 gap-4">
            {Object.entries(byType).map(([type, counts]) => (
              <div key={type} className="bg-gray-50 rounded-lg p-4 space-y-2">
                <p className="font-medium text-gray-700 capitalize">{type}</p>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between"><span className="text-green-600">Pass</span><span className="font-bold">{counts.pass}</span></div>
                  <div className="flex justify-between"><span className="text-yellow-600">Warning</span><span className="font-bold">{counts.warn}</span></div>
                  <div className="flex justify-between"><span className="text-red-600">Fail</span><span className="font-bold">{counts.fail}</span></div>
                </div>
              </div>
            ))}
          </div>
        )}

        {tab === "rules" && (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm divide-y divide-gray-100">
              <thead className="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th className="px-3 py-2 text-left">Column</th>
                  <th className="px-3 py-2 text-left">Check</th>
                  <th className="px-3 py-2 text-left">Score</th>
                  <th className="px-3 py-2 text-left">Rows</th>
                  <th className="px-3 py-2 text-left">Failed</th>
                  <th className="px-3 py-2 text-left">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {run.results.map((r) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="px-3 py-2 font-mono text-xs">{r.column_name ?? "—"}</td>
                    <td className="px-3 py-2 capitalize text-gray-700">{r.check_type}</td>
                    <td className="px-3 py-2 font-semibold">
                      {r.actual_value ? `${parseFloat(r.actual_value).toFixed(1)}%` : "—"}
                    </td>
                    <td className="px-3 py-2 text-gray-500">{r.row_count?.toLocaleString()}</td>
                    <td className="px-3 py-2 text-red-500">{r.failed_count ?? 0}</td>
                    <td className="px-3 py-2">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded ${
                        r.status === "pass" ? "bg-green-100 text-green-700" :
                        r.status === "fail" ? "bg-red-100 text-red-700" : "bg-yellow-100 text-yellow-700"
                      }`}>{r.status}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {tab === "findings" && (
          <div className="space-y-3">
            {allFindings.length === 0 ? (
              <p className="text-gray-400 text-center py-4">No findings — all checks passed</p>
            ) : allFindings.map((f) => (
              <div key={f.id} className={`p-3 rounded-lg border-l-4 ${
                f.severity === "critical" ? "bg-red-50 border-red-500" : "bg-yellow-50 border-yellow-400"
              }`}>
                <p className={`text-xs font-bold uppercase mb-1 ${f.severity === "critical" ? "text-red-600" : "text-yellow-700"}`}>
                  {f.severity}
                </p>
                <p className="text-sm text-gray-800">{f.description}</p>
                {f.recommendation && <p className="text-xs text-gray-600 mt-1">→ {f.recommendation}</p>}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Review actions */}
      <div className="px-5 pb-5 space-y-3 border-t border-gray-100 pt-4">
        <Input placeholder="Review comment (optional)…" value={comment} onChange={(e) => setComment(e.target.value)} />
        <div className="flex gap-2 justify-end">
          <Button variant="outline" size="sm" disabled={reviewing} onClick={() => onRequestRevision(comment)}>Request Revision</Button>
          <Button variant="outline" size="sm" disabled={reviewing}
            className="text-red-700 border-red-300 hover:bg-red-50" onClick={() => onReject(comment)}>Reject</Button>
          <Button size="sm" disabled={reviewing} onClick={() => onApprove(comment)}>Approve & Archive →</Button>
        </div>
      </div>
    </div>
  );
}

export default function DQNewPage() {
  return (
    <Suspense fallback={null}>
      <DQWizardPage />
    </Suspense>
  );
}

// ── Archive confirmation panel (Step 6) ───────────────────────────────────────
function ArchivePanel({ run, onArchive, archiving, onFinish }: {
  run: RunDetailType; onArchive: () => void; archiving: boolean; onFinish: () => void;
}) {
  return (
    <div className="bg-white rounded-lg shadow p-6 space-y-5">
      <h2 className="font-semibold text-gray-800">Step 6 — Archive to GCP</h2>
      <div className="bg-green-50 border border-green-200 rounded-lg p-4">
        <p className="font-medium text-green-800">Run Approved ✓</p>
        <p className="text-sm text-green-700 mt-1">
          The DQ run has been approved. Clicking Archive below will write the summary to BigQuery{" "}
          <strong>dq_governance.run_summaries</strong> and upload the report files to{" "}
          <strong>gs://dq-governance-outputs/{run.id}/</strong>.
        </p>
      </div>
      <div className="grid grid-cols-3 gap-3 text-sm">
        <div className="bg-gray-50 rounded p-3">
          <p className="text-gray-500 text-xs">BigQuery Table</p>
          <p className="font-mono font-medium">dq_governance.run_summaries</p>
        </div>
        <div className="bg-gray-50 rounded p-3">
          <p className="text-gray-500 text-xs">GCS Report Path</p>
          <p className="font-mono font-medium text-xs truncate">gs://dq-governance-outputs/{run.id}/</p>
        </div>
        <div className="bg-gray-50 rounded p-3">
          <p className="text-gray-500 text-xs">Run ID</p>
          <p className="font-mono text-xs truncate">{run.id}</p>
        </div>
      </div>
      <div className="flex gap-3 justify-end">
        <Button variant="outline" onClick={onFinish}>Skip — View Results</Button>
        <Button onClick={onArchive} disabled={archiving}>
          {archiving ? "Archiving…" : "Archive to GCP"}
        </Button>
        {!archiving && <Button variant="outline" onClick={onFinish}>Done</Button>}
      </div>
    </div>
  );
}
