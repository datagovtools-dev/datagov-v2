"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";

interface ProjectOption {
  id: string;
  project_name: string;
  project_code: string | null;
  customer_name: string;
  start_date: string | null;
  end_date: string | null;
}

export default function NewDSRPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    project_id: "",
    dataset_name: "",
    purpose: "",
    recipient: "",
    is_ai_use: false,
    duration_start: "",
    duration_end: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [serverError, setServerError] = useState("");

  const { data: projects = [] } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () =>
      api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: existingDsrs = [] } = useQuery<{ project_id: string }[]>({
    queryKey: ["dsr-project-ids"],
    queryFn: () =>
      api.get<{ items: { project_id: string }[] }>("/dsr?page_size=100").then((r) => r.items),
  });

  const usedProjectIds = new Set(existingDsrs.map((d) => d.project_id));
  const availableProjects = projects.filter((p) => !usedProjectIds.has(p.id));

  const mutation = useMutation({
    mutationFn: () =>
      api.post<{ id: string }>("/dsr", {
        project_id: form.project_id,
        dataset_name: form.dataset_name,
        purpose: form.purpose,
        recipient: form.recipient,
        is_ai_use: form.is_ai_use,
        duration_start: form.duration_start,
        duration_end: form.duration_end,
      }),
    onSuccess: (data) => router.push(`/dsr/${data.id}`),
    onError: (e: any) => setServerError(e.message),
  });

  function set(field: string, value: unknown) {
    setForm((f) => ({ ...f, [field]: value }));
    setErrors((e) => { const n = { ...e }; delete n[field]; return n; });
  }

  function validate() {
    const e: Record<string, string> = {};
    if (!form.project_id) e.project_id = "Required";
    if (!form.dataset_name.trim()) e.dataset_name = "Required";
    if (!form.purpose.trim()) e.purpose = "Required";
    if (!form.recipient.trim()) e.recipient = "Required";
    if (!form.duration_start) e.duration_start = "Required";
    if (!form.duration_end) e.duration_end = "Required";
    if (form.duration_start && form.duration_end && form.duration_end < form.duration_start)
      e.duration_end = "End date must be after start date";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (validate()) mutation.mutate();
  }

  return (
    <div className="max-w-3xl">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/dsr" className="inline-flex items-center justify-center h-9 w-9 rounded-md hover:bg-surface-100">
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1>New Data Sharing Request</h1>
          <p className="text-sm text-surface-500 mt-0.5">Submit a new request to share or access data</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Request Details */}
        <Card>
          <CardHeader><CardTitle>Request Details</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="flex flex-col gap-1">
              <label className="text-sm font-medium text-surface-700">Project <span className="text-red-500">*</span></label>
              <Select value={form.project_id} onValueChange={(v) => {
                const p = projects.find((p) => p.id === v);
                setForm((f) => ({
                  ...f,
                  project_id: v,
                  recipient: p?.customer_name ?? f.recipient,
                  duration_start: p?.start_date ?? f.duration_start,
                  duration_end: p?.end_date ?? f.duration_end,
                }));
                setErrors((e) => { const n = { ...e }; delete n.project_id; delete n.recipient; return n; });
              }}>
                <SelectTrigger error={!!errors.project_id}><SelectValue placeholder="Select project…" /></SelectTrigger>
                <SelectContent>
                  {availableProjects.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.project_id && <p className="text-xs text-red-500">{errors.project_id}</p>}
            </div>
            <Input label="Dataset Name" value={form.dataset_name}
              onChange={(e) => set("dataset_name", e.target.value)} required error={errors.dataset_name} />
            <Input label="Recipient Organisation" value={form.recipient}
              onChange={(e) => set("recipient", e.target.value)} required error={errors.recipient}
              placeholder="e.g. PT Bank Central Asia" className="md:col-span-2"
              hint={form.project_id && form.recipient ? "Auto-filled from project customer" : undefined} />
            <div className="md:col-span-2 flex flex-col gap-1">
              <label className="text-sm font-medium text-surface-700">Purpose / Justification <span className="text-red-500">*</span></label>
              <textarea
                value={form.purpose}
                onChange={(e) => set("purpose", e.target.value)}
                rows={3}
                className={`input-base resize-none w-full${errors.purpose ? " border-red-400 focus:ring-red-400" : ""}`}
                placeholder="Describe why this data needs to be shared…"
              />
              {errors.purpose && <p className="text-xs text-red-500">{errors.purpose}</p>}
            </div>
          </CardContent>
        </Card>

        {/* Timeline & Agreement */}
        <Card>
          <CardHeader><CardTitle>Timeline</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label="Sharing Start Date" type="date" value={form.duration_start}
              onChange={(e) => set("duration_start", e.target.value)} required error={errors.duration_start}
              hint={form.project_id && form.duration_start ? "Auto-filled from project" : undefined} />
            <Input label="Sharing End Date" type="date" value={form.duration_end}
              onChange={(e) => set("duration_end", e.target.value)} required error={errors.duration_end}
              hint={form.project_id && form.duration_end ? "Auto-filled from project" : undefined} />
            <div className="md:col-span-2 flex items-center gap-3 pt-1">
              <input
                id="is_ai_use"
                type="checkbox"
                checked={form.is_ai_use}
                onChange={(e) => set("is_ai_use", e.target.checked)}
                className="h-4 w-4 rounded border-surface-300 text-primary-600 focus:ring-primary-500"
              />
              <label htmlFor="is_ai_use" className="text-sm font-medium text-surface-700">
                This data will be used for AI / ML purposes
                <span className="ml-2 text-xs text-surface-400">(auto-creates AI compliance checklist)</span>
              </label>
            </div>
          </CardContent>
        </Card>

        {serverError && (
          <p className="rounded-md bg-red-50 border border-red-200 px-4 py-2 text-sm text-red-600">{serverError}</p>
        )}

        <div className="flex justify-end gap-3">
          <Button type="button" variant="secondary" onClick={() => router.back()}>Cancel</Button>
          <Button type="submit" loading={mutation.isPending}>Create Request</Button>
        </div>
      </form>
    </div>
  );
}
