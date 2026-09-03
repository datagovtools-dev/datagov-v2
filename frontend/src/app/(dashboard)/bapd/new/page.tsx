"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { ArrowLeft, AlertTriangle, Trash2, ShieldAlert, Database } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { toast } from "@/components/ui/Toast";

interface ProjectOption {
  id: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
}
interface UserOption { id: string; full_name: string; email: string; }
interface RetentionPolicy { id: string; dataset_type: string; retention_days: number; policy_reference: string | null; }
interface TableInfo { table_name: string; column_count: number; source_type: string; }

export default function NewBAPDPage() {
  return <Suspense><NewBAPDForm /></Suspense>;
}

function NewBAPDForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [form, setForm] = useState({
    project_id: "",
    dataset_name: params.get("dataset") ?? "",
    dataset_location: params.get("location") ?? "",
    retention_policy_id: params.get("policy") ?? "",
    expiry_date: "",
    reason: "",
    responsible_party_id: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [confirmed, setConfirmed] = useState(false);

  const { data: projects = [] } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: users = [] } = useQuery<UserOption[]>({
    queryKey: ["users-select"],
    queryFn: () => api.get<UserOption[]>("/rbac/users"),
  });

  const { data: policies = [] } = useQuery<RetentionPolicy[]>({
    queryKey: ["retention-policies"],
    queryFn: () => api.get<RetentionPolicy[]>("/bapd/retention-policies"),
  });

  const { data: projectTables = [] } = useQuery<TableInfo[]>({
    queryKey: ["project-tables", form.project_id],
    queryFn: () => api.get<TableInfo[]>(`/metadata/tables?project_id=${form.project_id}`),
    enabled: !!form.project_id,
  });

  // Auto-fill expiry_date from selected retention policy
  useEffect(() => {
    const policy = policies?.find((p) => p.id === form.retention_policy_id);
    if (policy && !form.expiry_date) {
      const exp = new Date();
      exp.setDate(exp.getDate() + policy.retention_days);
      setForm((f) => ({ ...f, expiry_date: exp.toISOString().slice(0, 10) }));
    }
  }, [form.retention_policy_id, policies]);

  const mutation = useMutation({
    mutationFn: (payload: typeof form) => {
      toast.loading("Submitting Extermination Request...", { id: "create-bapd" });
      const body = { ...payload };
      if (!body.retention_policy_id) delete (body as Partial<typeof form>).retention_policy_id;
      return api.post<{ id: string }>("/bapd", body);
    },
    onSuccess: (data: { id: string }) => {
      toast.success("BAPD request submitted successfully!", { id: "create-bapd" });
      router.push(`/bapd/${data.id}`);
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to submit BAPD request", { id: "create-bapd" });
    },
  });

  function set(field: string, value: unknown) {
    setForm((f) => ({ ...f, [field]: value }));
    setErrors((e) => { const n = { ...e }; delete n[field]; return n; });
  }

  function validate() {
    const e: Record<string, string> = {};
    if (!form.project_id) e.project_id = "Required";
    if (!form.dataset_name.trim()) e.dataset_name = "Required";
    if (!form.dataset_location.trim()) e.dataset_location = "Required";
    if (!form.expiry_date) e.expiry_date = "Required";
    if (!form.responsible_party_id) e.responsible_party_id = "Required";
    if (!form.reason.trim()) e.reason = "Required";
    if (!confirmed) e.confirmed = "You must confirm the irreversibility of this action";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;
    mutation.mutate(form);
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-3 pb-3 border-b border-slate-200">
        <Link
          href="/bapd"
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 text-slate-600"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">New Data Extermination Request (BAPD)</h1>
          <p className="text-xs text-slate-500 mt-0.5 font-mono">
            Submit a formal Berita Acara Pemusnahan Data for expired datasets
          </p>
        </div>
      </div>

      {/* Irreversible Action Warning Callout */}
      <div className="rounded-md border border-rose-200 bg-rose-50/60 p-3.5 flex items-start gap-2.5">
        <AlertTriangle className="h-4 w-4 text-rose-700 shrink-0 mt-0.5" />
        <div>
          <h4 className="text-xs font-semibold font-mono uppercase tracking-wider text-rose-900">
            Irreversible Permanent Deletion Action
          </h4>
          <p className="text-xs text-rose-800 mt-0.5 leading-relaxed">
            A BAPD request will permanently purge the specified dataset once dual approval is granted. Sign-off from both the designated Data Owner and Data Compliance Officer is strictly mandatory.
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Dataset Information */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Dataset Identity &amp; Target Location
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Specify the project, dataset name, and exact URI/storage path</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Project <span className="text-rose-500">*</span>
              </label>
              <Select value={form.project_id} onValueChange={(v) => set("project_id", v)}>
                <SelectTrigger className="h-8 text-xs" error={!!errors.project_id}>
                  <SelectValue placeholder="Select project..." />
                </SelectTrigger>
                <SelectContent>
                  {projects.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.project_code ? `[${p.project_code}] ` : ""}{p.project_name} {p.customer_name ? `(${p.customer_name})` : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.project_id && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.project_id}</p>
              )}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Dataset Name"
                value={form.dataset_name}
                onChange={(e) => set("dataset_name", e.target.value)}
                required
                error={errors.dataset_name}
                placeholder="e.g. customer_crm_archive or click table below"
                className="h-8 text-xs font-mono"
              />
              {projectTables.length > 0 && (
                <div className="flex flex-wrap items-center gap-1 pt-1">
                  <span className="text-[10px] text-slate-400 font-mono flex items-center gap-0.5">
                    <Database className="h-2.5 w-2.5" /> Project Tables:
                  </span>
                  {projectTables.map((t) => (
                    <button
                      key={t.table_name}
                      type="button"
                      onClick={() => {
                        set("dataset_name", t.table_name);
                        if (!form.dataset_location) {
                          set("dataset_location", `db://${t.source_type.toLowerCase()}/${t.table_name}`);
                        }
                      }}
                      className="text-[10px] px-1.5 py-0.5 rounded bg-slate-100 hover:bg-blue-50 hover:text-blue-700 font-mono text-slate-600 border border-slate-200 transition-colors"
                    >
                      {t.table_name}
                    </button>
                  ))}
                </div>
              )}
            </div>
            <div className="md:col-span-2">
              <Input
                label="Dataset Location / Storage URI"
                value={form.dataset_location}
                onChange={(e) => set("dataset_location", e.target.value)}
                required
                error={errors.dataset_location}
                placeholder="e.g. gs://archive-bucket/data/ or bigquery://analytics.historical_logs"
                className="h-8 text-xs font-mono"
              />
            </div>
          </CardContent>
        </Card>

        {/* Retention Policy & Schedule */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Retention Schedule &amp; Signatory
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Retention policy match, expiry date, and executing party</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">Retention Policy</label>
              <Select
                value={form.retention_policy_id}
                onValueChange={(v) => set("retention_policy_id", v)}
              >
                <SelectTrigger className="h-8 text-xs">
                  <SelectValue placeholder="None / Manual entry" />
                </SelectTrigger>
                <SelectContent>
                  {policies?.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.dataset_type} ({p.retention_days} days)
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <Input
              label="Expiry Date"
              type="date"
              value={form.expiry_date}
              onChange={(e) => set("expiry_date", e.target.value)}
              required
              error={errors.expiry_date}
              className="h-8 text-xs font-mono"
            />
            <div className="md:col-span-2 flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Responsible Executing Party <span className="text-rose-500">*</span>
              </label>
              <Select
                value={form.responsible_party_id}
                onValueChange={(v) => set("responsible_party_id", v)}
              >
                <SelectTrigger className="h-8 text-xs" error={!!errors.responsible_party_id}>
                  <SelectValue placeholder="Select responsible party..." />
                </SelectTrigger>
                <SelectContent>
                  {users?.map((u) => (
                    <SelectItem key={u.id} value={u.id}>
                      {u.full_name} ({u.email})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.responsible_party_id && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.responsible_party_id}</p>
              )}
            </div>
            <div className="md:col-span-2 flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Disposal Justification &amp; Reason <span className="text-rose-500">*</span>
              </label>
              <textarea
                value={form.reason}
                onChange={(e) => set("reason", e.target.value)}
                rows={3}
                className={`input-base resize-none w-full text-xs font-sans${
                  errors.reason ? " border-rose-300 bg-rose-50/40 text-rose-900" : ""
                }`}
                placeholder="State the legal justification for extermination (e.g. retention policy expiry, DSR withdrawal, contract conclusion)..."
              />
              {errors.reason && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.reason}</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Confirmation Checkbox */}
        <div className="p-3.5 rounded-md border border-slate-200 bg-slate-50/60 flex items-start gap-2.5">
          <input
            id="confirm"
            type="checkbox"
            checked={confirmed}
            onChange={(e) => {
              setConfirmed(e.target.checked);
              setErrors((errs) => {
                const n = { ...errs };
                delete n.confirmed;
                return n;
              });
            }}
            className="mt-0.5 h-3.5 w-3.5 rounded border-slate-300 text-slate-900 focus:ring-slate-900"
          />
          <div className="flex-1">
            <label htmlFor="confirm" className="text-xs font-semibold text-slate-800 cursor-pointer">
              I understand and confirm that this BAPD action is permanent and legally binding
            </label>
            <p className="text-[11px] text-slate-500 mt-0.5 font-mono">
              Once dual approval is executed, all associated data tables, backups, and artifacts will be permanently purged.
            </p>
            {errors.confirmed && (
              <p className="text-[11px] font-medium text-rose-600 font-mono mt-1">{errors.confirmed}</p>
            )}
          </div>
        </div>

        {mutation.isError && (
          <div className="rounded-md bg-rose-50 border border-rose-200 p-3 text-xs font-mono text-rose-700">
            Failed to create BAPD request. Please verify required fields.
          </div>
        )}

        <div className="flex items-center justify-end gap-2.5 pt-1">
          <Button type="button" variant="outline" size="sm" className="h-8 text-xs" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button type="submit" size="sm" loading={mutation.isPending} className="h-8 text-xs font-medium bg-rose-700 hover:bg-rose-800 text-white">
            <Trash2 className="h-3.5 w-3.5 mr-1" /> Submit Extermination Request
          </Button>
        </div>
      </form>
    </div>
  );
}
