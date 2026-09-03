"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { toast } from "@/components/ui/Toast";

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
    mutationFn: () => {
      toast.loading("Submitting Data Sharing Request...", { id: "create-dsr" });
      return api.post<{ id: string }>("/dsr", {
        project_id: form.project_id,
        dataset_name: form.dataset_name,
        purpose: form.purpose,
        recipient: form.recipient,
        is_ai_use: form.is_ai_use,
        duration_start: form.duration_start,
        duration_end: form.duration_end,
      });
    },
    onSuccess: (data) => {
      toast.success("DSR submitted successfully!", { id: "create-dsr" });
      router.push(`/dsr/${data.id}`);
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to submit DSR", { id: "create-dsr" });
      setServerError(e.message);
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
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-3 pb-3 border-b border-slate-200">
        <Link
          href="/dsr"
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 text-slate-600"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">New Data Sharing Request (DSR)</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Submit a formal request to share, transfer, or access enterprise data assets
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Request Details */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Sharing Scope &amp; Parties
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Target dataset, recipient organization, and lawful justification</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Source Project <span className="text-rose-500">*</span>
              </label>
              <Select
                value={form.project_id}
                onValueChange={(v) => {
                  const p = projects.find((p) => p.id === v);
                  setForm((f) => ({
                    ...f,
                    project_id: v,
                    recipient: p?.customer_name ?? f.recipient,
                    duration_start: p?.start_date ?? f.duration_start,
                    duration_end: p?.end_date ?? f.duration_end,
                  }));
                  setErrors((e) => {
                    const n = { ...e };
                    delete n.project_id;
                    delete n.recipient;
                    return n;
                  });
                }}
              >
                <SelectTrigger className="h-8 text-xs" error={!!errors.project_id}>
                  <SelectValue placeholder="Select project asset..." />
                </SelectTrigger>
                <SelectContent>
                  {availableProjects.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.project_code ? `${p.project_code} — ${p.project_name}` : p.project_name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.project_id && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.project_id}</p>
              )}
            </div>
            <Input
              label="Dataset Name"
              value={form.dataset_name}
              onChange={(e) => set("dataset_name", e.target.value)}
              required
              error={errors.dataset_name}
              placeholder="e.g. Credit Card Transaction Logs (Masked)"
              className="h-8 text-xs"
            />
            <Input
              label="Recipient Organisation"
              value={form.recipient}
              onChange={(e) => set("recipient", e.target.value)}
              required
              error={errors.recipient}
              placeholder="e.g. PT Bank Central Asia"
              className="md:col-span-2 h-8 text-xs"
              hint={form.project_id && form.recipient ? "Auto-filled from project client" : undefined}
            />
            <div className="md:col-span-2 flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Purpose &amp; Legal Justification <span className="text-rose-500">*</span>
              </label>
              <textarea
                value={form.purpose}
                onChange={(e) => set("purpose", e.target.value)}
                rows={3}
                className={`input-base resize-none w-full text-xs font-sans${
                  errors.purpose ? " border-rose-300 bg-rose-50/40 text-rose-900" : ""
                }`}
                placeholder="Detail the business justification, legal basis, and expected security controls for sharing this data..."
              />
              {errors.purpose && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.purpose}</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Timeline & AI Check */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Duration &amp; AI Usage Policy
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Sharing validity window and automated AI governance checklist trigger</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            <Input
              label="Sharing Start Date"
              type="date"
              value={form.duration_start}
              onChange={(e) => set("duration_start", e.target.value)}
              required
              error={errors.duration_start}
              hint={form.project_id && form.duration_start ? "Auto-filled from project start" : undefined}
              className="h-8 text-xs font-mono"
            />
            <Input
              label="Sharing End Date"
              type="date"
              value={form.duration_end}
              onChange={(e) => set("duration_end", e.target.value)}
              required
              error={errors.duration_end}
              hint={form.project_id && form.duration_end ? "Auto-filled from project end" : undefined}
              className="h-8 text-xs font-mono"
            />
            <div className="md:col-span-2 flex items-center gap-2.5 p-3 rounded-md border border-slate-200 bg-slate-50/50">
              <input
                id="is_ai_use"
                type="checkbox"
                checked={form.is_ai_use}
                onChange={(e) => set("is_ai_use", e.target.checked)}
                className="h-4 w-4 rounded-md border-slate-300 text-slate-900 focus:ring-slate-400"
              />
              <label htmlFor="is_ai_use" className="text-xs font-medium text-slate-900 cursor-pointer">
                This dataset will be consumed for AI / Machine Learning workflows
                <span className="block text-[11px] text-slate-500 font-normal mt-0.5">
                  Automatically initializes an AI Checklist (AICK) compliance review
                </span>
              </label>
            </div>
          </CardContent>
        </Card>

        {serverError && (
          <div className="rounded-md bg-rose-50 border border-rose-200 p-3 text-xs font-mono text-rose-700">
            {serverError}
          </div>
        )}

        <div className="flex items-center justify-end gap-2.5 pt-1">
          <Button type="button" variant="outline" size="sm" className="h-8 text-xs" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button type="submit" size="sm" loading={mutation.isPending} className="h-8 text-xs font-medium">
            Create Data Sharing Request
          </Button>
        </div>
      </form>
    </div>
  );
}
