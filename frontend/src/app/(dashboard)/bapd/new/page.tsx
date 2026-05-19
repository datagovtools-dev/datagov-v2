"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";

interface ProjectOption { id: string; name: string; }
interface UserOption { id: string; full_name: string; email: string; }
interface RetentionPolicy { id: string; dataset_type: string; retention_days: number; policy_reference: string | null; }

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

  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: users } = useQuery<UserOption[]>({
    queryKey: ["users-select"],
    queryFn: () => api.get<UserOption[]>("/rbac/users"),
  });

  const { data: policies } = useQuery<RetentionPolicy[]>({
    queryKey: ["retention-policies"],
    queryFn: () => api.get<RetentionPolicy[]>("/bapd/retention-policies"),
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
      const body = { ...payload };
      if (!body.retention_policy_id) delete (body as Partial<typeof form>).retention_policy_id;
      return api.post<{ id: string }>("/bapd", body);
    },
    onSuccess: (data: { id: string }) => router.push(`/bapd/${data.id}`),
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
    if (!form.reason.trim()) e.reason = "Required";
    if (!form.responsible_party_id) e.responsible_party_id = "Required";
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
    <div className="p-6 max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">New Data Extermination Request</h1>
        <p className="text-sm text-gray-500 mt-1">Submit a formal request to permanently delete an expired dataset</p>
      </div>

      {/* Danger notice */}
      <div className="bg-red-50 border border-red-300 rounded-lg p-4 flex gap-3">
        <span className="text-red-500 font-bold text-xl flex-shrink-0">⚠</span>
        <div>
          <p className="font-semibold text-red-800">This action is irreversible</p>
          <p className="text-sm text-red-700 mt-1">
            A BAPD request will trigger permanent deletion of the specified dataset once dual approval is received.
            This request requires sign-off from both the Data Owner and a Compliance Officer.
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Dataset Info */}
        <div className="bg-white rounded-lg shadow p-5 space-y-4">
          <h2 className="font-semibold text-gray-800">Dataset Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Project <span className="text-red-500">*</span></label>
              <select value={form.project_id} onChange={(e) => set("project_id", e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">Select project…</option>
                {projects?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
              {errors.project_id && <p className="text-xs text-red-500 mt-1">{errors.project_id}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Dataset Name <span className="text-red-500">*</span></label>
              <Input value={form.dataset_name} onChange={(e) => set("dataset_name", e.target.value)} />
              {errors.dataset_name && <p className="text-xs text-red-500 mt-1">{errors.dataset_name}</p>}
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Dataset Location <span className="text-red-500">*</span></label>
              <Input value={form.dataset_location} onChange={(e) => set("dataset_location", e.target.value)}
                placeholder="e.g. gs://my-bucket/dataset/ or bigquery://project.dataset.table" />
              {errors.dataset_location && <p className="text-xs text-red-500 mt-1">{errors.dataset_location}</p>}
            </div>
          </div>
        </div>

        {/* Retention & Schedule */}
        <div className="bg-white rounded-lg shadow p-5 space-y-4">
          <h2 className="font-semibold text-gray-800">Retention Policy & Schedule</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Retention Policy</label>
              <select value={form.retention_policy_id} onChange={(e) => set("retention_policy_id", e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">None / Manual entry</option>
                {policies?.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.dataset_type} ({p.retention_days} days){p.policy_reference ? ` — ${p.policy_reference}` : ""}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Expiry Date <span className="text-red-500">*</span></label>
              <Input type="date" value={form.expiry_date} onChange={(e) => set("expiry_date", e.target.value)} />
              {errors.expiry_date && <p className="text-xs text-red-500 mt-1">{errors.expiry_date}</p>}
            </div>
            <div className="col-span-2">
              <label className="block text-sm font-medium text-gray-700 mb-1">Responsible Party <span className="text-red-500">*</span></label>
              <select value={form.responsible_party_id} onChange={(e) => set("responsible_party_id", e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">Select responsible person…</option>
                {users?.map((u) => <option key={u.id} value={u.id}>{u.full_name} ({u.email})</option>)}
              </select>
              {errors.responsible_party_id && <p className="text-xs text-red-500 mt-1">{errors.responsible_party_id}</p>}
            </div>
          </div>
        </div>

        {/* Reason / Justification */}
        <div className="bg-white rounded-lg shadow p-5 space-y-4">
          <h2 className="font-semibold text-gray-800">Justification</h2>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Reason for Extermination <span className="text-red-500">*</span></label>
            <textarea value={form.reason} onChange={(e) => set("reason", e.target.value)} rows={4}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
              placeholder="Provide a detailed justification for the data extermination request…" />
            {errors.reason && <p className="text-xs text-red-500 mt-1">{errors.reason}</p>}
          </div>
        </div>

        {/* Confirmation */}
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <input id="confirm" type="checkbox" checked={confirmed} onChange={(e) => setConfirmed(e.target.checked)}
              className="mt-0.5 h-4 w-4 rounded border-gray-300 text-red-600 focus:ring-red-500" />
            <label htmlFor="confirm" className="text-sm text-red-800">
              I understand that this action will permanently and irreversibly delete the specified dataset upon dual approval.
              I confirm that this dataset has exceeded its retention period and must be exterminated.
            </label>
          </div>
          {errors.confirmed && <p className="text-xs text-red-500 mt-2 ml-7">{errors.confirmed}</p>}
        </div>

        {mutation.isError && (
          <p className="text-sm text-red-600 bg-red-50 px-4 py-2 rounded">Failed to create request. Please check all fields.</p>
        )}

        <div className="flex justify-end gap-3">
          <Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button>
          <Button type="submit" disabled={mutation.isPending}
            className="bg-red-600 hover:bg-red-700 text-white">
            {mutation.isPending ? "Creating…" : "Submit Extermination Request"}
          </Button>
        </div>
      </form>
    </div>
  );
}
