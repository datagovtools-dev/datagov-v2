"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { UserCombobox } from "@/components/ui/UserCombobox";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";

interface UserOption { id: string; full_name: string; email: string }

const CATEGORIES = ["AI / ML", "Analytics", "Data Governance", "Data Quality", "Integration", "Other"];
const CURRENT_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 6 }, (_, i) => CURRENT_YEAR - 2 + i);

export default function NewProjectPage() {
  const router = useRouter();
  const [form, setForm] = React.useState({
    project_code: "",
    project_name: "",
    customer_name: "",
    line_of_business: "",
    use_case: "",
    project_year: String(CURRENT_YEAR),
    project_category: "",
    is_monetized: "false",
    start_date: "",
    end_date: "",
    sme_id: "",
    delivery_manager_id: "",
    project_manager_id: "",
    dgo_id: "",
    metadata_officer_id: "",
    dq_officer_id: "",
    pic_data_compliance_id: "",
  });
  const [errors, setErrors] = React.useState<Record<string, string>>({});
  const [serverError, setServerError] = React.useState("");

  const { data: users = [] } = useQuery<UserOption[]>({
    queryKey: ["users-options"],
    queryFn: () => api.get<UserOption[]>("/rbac/users/options"),
  });

  const create = useMutation({
    mutationFn: () => {
      const payload = {
        project_code: form.project_code || null,
        project_name: form.project_name,
        customer_name: form.customer_name,
        line_of_business: form.line_of_business || null,
        use_case: form.use_case || null,
        project_year: Number(form.project_year),
        project_category: form.project_category,
        is_monetized: form.is_monetized === "true",
        start_date: form.start_date || null,
        end_date: form.end_date || null,
        sme_id: form.sme_id || null,
        delivery_manager_id: form.delivery_manager_id || null,
        project_manager_id: form.project_manager_id || null,
        dgo_id: form.dgo_id || null,
        metadata_officer_id: form.metadata_officer_id || null,
        dq_officer_id: form.dq_officer_id || null,
        pic_data_compliance_id: form.pic_data_compliance_id || null,
      };
      return api.post("/projects", payload);
    },
    onSuccess: () => router.push("/projects"),
    onError: (e: any) => setServerError(e.message),
  });

  function set(key: string, val: string) {
    setForm(f => ({ ...f, [key]: val }));
    setErrors(e => { const n = { ...e }; delete n[key]; return n; });
  }

  function validate() {
    const errs: Record<string, string> = {};
    if (!form.project_name.trim()) errs.project_name = "Required";
    if (!form.customer_name.trim()) errs.customer_name = "Required";
    if (!form.project_category) errs.project_category = "Required";
    setErrors(errs);
    return Object.keys(errs).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (validate()) create.mutate();
  }

  const userOptions = users.map(u => ({ value: u.id, label: u.full_name, sublabel: u.email }));

  return (
    <div className="max-w-3xl">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/projects" className="inline-flex items-center justify-center h-9 w-9 rounded-md hover:bg-surface-100">
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1>New Project</h1>
          <p className="text-sm text-surface-500 mt-0.5">Fill in the project details below</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">
        <Card>
          <CardHeader><CardTitle>Basic Information</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input label="Project ID" value={form.project_code}
              onChange={e => set("project_code", e.target.value)}
              placeholder="e.g. PRJ-2026-001"
              hint="Unique identifier from BDP and Finance Team" />
            <div className="hidden md:block" />
            <Input label="Project Name" value={form.project_name}
              onChange={e => set("project_name", e.target.value)} required error={errors.project_name} />
            <Input label="Customer / Client Name" value={form.customer_name}
              onChange={e => set("customer_name", e.target.value)} required error={errors.customer_name} />
            <Input label="Line of Business" value={form.line_of_business}
              onChange={e => set("line_of_business", e.target.value)} placeholder="e.g. Retail Banking" />
            <div className="flex flex-col gap-1">
              <label className="text-sm font-medium text-surface-700">Project Category <span className="text-red-500">*</span></label>
              <Select value={form.project_category} onValueChange={v => set("project_category", v)}>
                <SelectTrigger error={!!errors.project_category}><SelectValue placeholder="Select category…" /></SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}
                </SelectContent>
              </Select>
              {errors.project_category && <p className="text-xs text-red-500">{errors.project_category}</p>}
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-sm font-medium text-surface-700">Project Year</label>
              <Select value={form.project_year} onValueChange={v => set("project_year", v)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {YEARS.map(y => <SelectItem key={y} value={String(y)}>{y}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-sm font-medium text-surface-700">Monetized Project?</label>
              <Select value={form.is_monetized} onValueChange={v => set("is_monetized", v)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="false">No</SelectItem>
                  <SelectItem value="true">Yes</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Input label="Start Date" type="date" value={form.start_date}
              onChange={e => set("start_date", e.target.value)} />
            <Input label="End Date" type="date" value={form.end_date}
              onChange={e => set("end_date", e.target.value)} />
            <div className="md:col-span-2">
              <label className="text-sm font-medium text-surface-700 block mb-1">Use Case / Description</label>
              <textarea className="input-base min-h-[80px] resize-y w-full"
                value={form.use_case} onChange={e => set("use_case", e.target.value)}
                placeholder="Brief description of this governance project…" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Project Team</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <UserCombobox label="Subject Matter Expert (SME)" options={userOptions} value={form.sme_id}               onChange={v => set("sme_id", v)} />
            <UserCombobox label="Delivery Manager"        options={userOptions} value={form.delivery_manager_id}        onChange={v => set("delivery_manager_id", v)} />
            <UserCombobox label="Project Manager"         options={userOptions} value={form.project_manager_id}         onChange={v => set("project_manager_id", v)} />
            <UserCombobox label="Data Governance Officer" options={userOptions} value={form.dgo_id}                     onChange={v => set("dgo_id", v)} />
            <UserCombobox label="Metadata Officer"        options={userOptions} value={form.metadata_officer_id}        onChange={v => set("metadata_officer_id", v)} />
            <UserCombobox label="DQ Officer"              options={userOptions} value={form.dq_officer_id}              onChange={v => set("dq_officer_id", v)} />
            <UserCombobox label="PIC Data Compliance"     options={userOptions} value={form.pic_data_compliance_id}     onChange={v => set("pic_data_compliance_id", v)} />
          </CardContent>
        </Card>

        {serverError && (
          <p className="rounded-md bg-red-50 border border-red-200 px-4 py-2 text-sm text-red-600">{serverError}</p>
        )}

        <div className="flex justify-end gap-3">
          <Button variant="secondary" type="button" onClick={() => router.back()}>Cancel</Button>
          <Button type="submit" loading={create.isPending}>Create Project</Button>
        </div>
      </form>
    </div>
  );
}
