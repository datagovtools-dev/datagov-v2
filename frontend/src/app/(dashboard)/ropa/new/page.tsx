"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";

interface ProjectOption { id: string; name: string; }

export default function NewROPAPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    project_id: "",
    process_name: "",
    purpose: "",
    data_category: "",
    data_subject: "",
    legal_basis: "",
    retention_period: "",
    recipient: "",
    linked_asset_ids: [] as string[],
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: legalBasisOptions } = useQuery<string[]>({
    queryKey: ["legal-basis-options"],
    queryFn: () => api.get<string[]>("/ropa/legal-basis-options"),
  });

  const mutation = useMutation({
    mutationFn: (payload: typeof form) => {
      const body = { ...payload };
      if (!body.recipient) delete (body as Partial<typeof form>).recipient;
      if (!body.linked_asset_ids?.length) delete (body as Partial<typeof form>).linked_asset_ids;
      return api.post<{ id: string }>("/ropa", body);
    },
    onSuccess: (data: { id: string }) => router.push(`/ropa/${data.id}`),
  });

  function set(field: string, value: unknown) {
    setForm((f) => ({ ...f, [field]: value }));
    setErrors((e) => { const n = { ...e }; delete n[field]; return n; });
  }

  function validate() {
    const e: Record<string, string> = {};
    if (!form.project_id) e.project_id = "Required";
    if (!form.process_name.trim()) e.process_name = "Required";
    if (!form.purpose.trim()) e.purpose = "Required";
    if (!form.data_category.trim()) e.data_category = "Required";
    if (!form.data_subject.trim()) e.data_subject = "Required";
    if (!form.legal_basis) e.legal_basis = "Required";
    if (!form.retention_period.trim()) e.retention_period = "Required";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;
    mutation.mutate(form);
  }

  const RequiredLabel = ({ label }: { label: string }) => (
    <label className="block text-sm font-medium text-gray-700 mb-1">
      {label}<span className="text-red-500 ml-1">*</span>
    </label>
  );

  return (
    <div className="p-6 max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">New Processing Activity Record</h1>
        <p className="text-sm text-gray-500 mt-1">Document a data processing activity under GDPR Article 30</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Information */}
        <div className="bg-white rounded-lg shadow p-5 space-y-4">
          <h2 className="font-semibold text-gray-800">Activity Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <RequiredLabel label="Project" />
              <select value={form.project_id} onChange={(e) => set("project_id", e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">Select project…</option>
                {projects?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
              {errors.project_id && <p className="text-xs text-red-500 mt-1">{errors.project_id}</p>}
            </div>
            <div>
              <RequiredLabel label="Process Name" />
              <Input value={form.process_name} onChange={(e) => set("process_name", e.target.value)} />
              {errors.process_name && <p className="text-xs text-red-500 mt-1">{errors.process_name}</p>}
            </div>
          </div>
          <div>
            <RequiredLabel label="Purpose of Processing" />
            <textarea value={form.purpose} onChange={(e) => set("purpose", e.target.value)} rows={3}
              className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
              placeholder="Why is this data being processed?" />
            {errors.purpose && <p className="text-xs text-red-500 mt-1">{errors.purpose}</p>}
          </div>
        </div>

        {/* Data Details */}
        <div className="bg-white rounded-lg shadow p-5 space-y-4">
          <h2 className="font-semibold text-gray-800">Data Details</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <RequiredLabel label="Data Category" />
              <Input value={form.data_category} onChange={(e) => set("data_category", e.target.value)}
                placeholder="e.g. Personal, Sensitive, Financial" />
              {errors.data_category && <p className="text-xs text-red-500 mt-1">{errors.data_category}</p>}
            </div>
            <div>
              <RequiredLabel label="Data Subject" />
              <Input value={form.data_subject} onChange={(e) => set("data_subject", e.target.value)}
                placeholder="e.g. Customers, Employees, Minors" />
              {errors.data_subject && <p className="text-xs text-red-500 mt-1">{errors.data_subject}</p>}
            </div>
            <div>
              <RequiredLabel label="Legal Basis" />
              <select value={form.legal_basis} onChange={(e) => set("legal_basis", e.target.value)}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">Select legal basis…</option>
                {legalBasisOptions?.map((b) => <option key={b} value={b}>{b}</option>)}
              </select>
              {errors.legal_basis && <p className="text-xs text-red-500 mt-1">{errors.legal_basis}</p>}
            </div>
            <div>
              <RequiredLabel label="Retention Period" />
              <Input value={form.retention_period} onChange={(e) => set("retention_period", e.target.value)}
                placeholder="e.g. 7 years, 90 days after contract end" />
              {errors.retention_period && <p className="text-xs text-red-500 mt-1">{errors.retention_period}</p>}
            </div>
          </div>
        </div>

        {/* Recipients & Links */}
        <div className="bg-white rounded-lg shadow p-5 space-y-4">
          <h2 className="font-semibold text-gray-800">Recipients & Asset Links</h2>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Recipient (Optional)</label>
            <Input value={form.recipient} onChange={(e) => set("recipient", e.target.value)}
              placeholder="Third parties or organisations receiving this data" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Linked Asset IDs (Optional)</label>
            <Input
              value={form.linked_asset_ids.join(", ")}
              onChange={(e) => set("linked_asset_ids", e.target.value.split(",").map((s) => s.trim()).filter(Boolean))}
              placeholder="Comma-separated asset IDs from Data Catalogue" />
            <p className="text-xs text-gray-400 mt-1">Enter asset UUIDs separated by commas</p>
          </div>
        </div>

        {mutation.isError && (
          <p className="text-sm text-red-600 bg-red-50 px-4 py-2 rounded">Failed to create record. Please check all fields.</p>
        )}

        <div className="flex justify-end gap-3">
          <Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button>
          <Button type="submit" disabled={mutation.isPending}>{mutation.isPending ? "Creating…" : "Create Record"}</Button>
        </div>
      </form>
    </div>
  );
}
