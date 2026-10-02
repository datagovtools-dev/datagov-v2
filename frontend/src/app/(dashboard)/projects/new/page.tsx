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
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { toast } from "@/components/ui/Toast";

interface UserOption { id: string; full_name: string; email: string }

const CATEGORIES = ["AI / ML", "Analytics", "Data Governance", "Data Quality", "Integration", "Other"];
const CURRENT_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 6 }, (_, i) => CURRENT_YEAR - 2 + i);

export default function NewProjectPage() {
  const router = useRouter();
  const [form, setForm] = React.useState({
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
  const [ownerForms, setOwnerForms] = React.useState({
    lead_business_steward: { full_name: "", email: "", position: "" },
    data_owner:            { full_name: "", email: "", position: "" },
  });
  const [errors, setErrors] = React.useState<Record<string, string>>({});
  const [serverError, setServerError] = React.useState("");

  const { data: users = [] } = useQuery<UserOption[]>({
    queryKey: ["users-options"],
    queryFn: () => api.get<UserOption[]>("/rbac/users/options"),
  });

  // Project ID is assigned by the system (PRJ-<Project Year>-<next number>); this is only a preview
  const { data: nextCode } = useQuery<{ project_year: number; project_code: string }>({
    queryKey: ["projects-next-code", form.project_year],
    queryFn: () => api.get(`/projects/next-code?year=${form.project_year}`),
    enabled: /^\d{4}$/.test(form.project_year),
  });

  const create = useMutation({
    mutationFn: () => {
      toast.loading("Registering data asset...", { id: "create-project" });
      const payload = {
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
      return api.post<{ id: string; project_code: string }>("/projects", payload);
    },
    onSuccess: async (created) => {
      const roles: [string, { full_name: string; email: string; position: string }][] = [
        ["lead_business_steward", ownerForms.lead_business_steward],
        ["data_owner",            ownerForms.data_owner],
      ];
      for (const [role_type, data] of roles) {
        if (data.full_name.trim()) {
          await api.post(`/metadata/owners/${created.id}`, {
            role_type,
            full_name: data.full_name.trim(),
            email: data.email.trim(),
            position: data.position.trim() || null,
          });
        }
      }
      toast.success(`Data asset ${created.project_code} registered successfully!`, { id: "create-project" });
      router.push("/projects");
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to register data asset", { id: "create-project" });
      setServerError(e.message);
    },
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
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-3 pb-3 border-b border-slate-200">
        <Link
          href="/projects"
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 text-slate-600"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">Register New Data Asset</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Configure project identity, classification, accountable stewards, and delivery team
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Asset Identity & Scope
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Core identifiers and business domain categorization</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
            <Input
              label="Project ID / Code"
              value={nextCode?.project_code ?? ""}
              readOnly
              disabled
              placeholder="Assigned on save"
              hint="Assigned automatically on save: PRJ-<Project Year>-<next number>"
              className="h-8 text-xs font-mono"
            />
            <div className="hidden md:block" />
            <Input
              label="Project / Asset Name"
              value={form.project_name}
              onChange={(e) => set("project_name", e.target.value)}
              required
              error={errors.project_name}
              placeholder="e.g. Customer 360 Golden Record"
              className="h-8 text-xs"
            />
            <Input
              label="Customer / Client Name"
              value={form.customer_name}
              onChange={(e) => set("customer_name", e.target.value)}
              required
              error={errors.customer_name}
              placeholder="e.g. PT Bank Central Asia"
              className="h-8 text-xs"
            />
            <Input
              label="Line of Business"
              value={form.line_of_business}
              onChange={(e) => set("line_of_business", e.target.value)}
              placeholder="e.g. Retail Banking & Wealth Management"
              className="h-8 text-xs"
            />
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Project Category <span className="text-rose-500">*</span>
              </label>
              <Select value={form.project_category} onValueChange={(v) => set("project_category", v)}>
                <SelectTrigger className="h-8 text-xs" error={!!errors.project_category}>
                  <SelectValue placeholder="Select category..." />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map((c) => (
                    <SelectItem key={c} value={c}>
                      {c}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.project_category && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.project_category}</p>
              )}
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">Project Year</label>
              <Select value={form.project_year} onValueChange={(v) => set("project_year", v)}>
                <SelectTrigger className="h-8 text-xs font-mono">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {YEARS.map((y) => (
                    <SelectItem key={y} value={String(y)}>
                      {y}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">Monetization Status</label>
              <Select value={form.is_monetized} onValueChange={(v) => set("is_monetized", v)}>
                <SelectTrigger className="h-8 text-xs">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="false">Internal Governance</SelectItem>
                  <SelectItem value="true">Monetized Commercial Asset</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Input
              label="Start Date"
              type="date"
              value={form.start_date}
              onChange={(e) => set("start_date", e.target.value)}
              className="h-8 text-xs font-mono"
            />
            <Input
              label="End Date"
              type="date"
              value={form.end_date}
              onChange={(e) => set("end_date", e.target.value)}
              className="h-8 text-xs font-mono"
            />
            <div className="md:col-span-2 lg:col-span-3 flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">Use Case & Governance Description</label>
              <textarea
                className="input-base min-h-[70px] resize-y w-full text-xs font-sans"
                value={form.use_case}
                onChange={(e) => set("use_case", e.target.value)}
                placeholder="Describe business purpose, target consumers, and data architecture..."
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Delivery & Governance Team
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Assign responsible officers and technical contacts</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3.5">
            <UserCombobox label="Subject Matter Expert (SME)" options={userOptions} value={form.sme_id} onChange={(v) => set("sme_id", v)} />
            <UserCombobox label="Delivery Manager" options={userOptions} value={form.delivery_manager_id} onChange={(v) => set("delivery_manager_id", v)} />
            <UserCombobox label="Project Manager" options={userOptions} value={form.project_manager_id} onChange={(v) => set("project_manager_id", v)} />
            <UserCombobox label="Data Governance Officer (DGO)" options={userOptions} value={form.dgo_id} onChange={(v) => set("dgo_id", v)} />
            <UserCombobox label="Metadata Officer" options={userOptions} value={form.metadata_officer_id} onChange={(v) => set("metadata_officer_id", v)} />
            <UserCombobox label="Data Quality Officer (DQO)" options={userOptions} value={form.dq_officer_id} onChange={(v) => set("dq_officer_id", v)} />
            <UserCombobox label="PIC Data Compliance" options={userOptions} value={form.pic_data_compliance_id} onChange={(v) => set("pic_data_compliance_id", v)} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Accountable Stewardship & Ownership
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Formal business owners designated under data governance policy</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="flex flex-col gap-2.5 p-3.5 rounded-md border border-slate-200 bg-slate-50/50">
              <span className="text-xs font-semibold font-mono uppercase tracking-wider text-slate-700">Lead Business Steward</span>
              <Input
                label="Full Name"
                value={ownerForms.lead_business_steward.full_name}
                onChange={(e) =>
                  setOwnerForms((f) => ({
                    ...f,
                    lead_business_steward: { ...f.lead_business_steward, full_name: e.target.value },
                  }))
                }
                placeholder="e.g. John Doe"
                className="h-8 text-xs"
              />
              <Input
                label="Email Address"
                type="email"
                value={ownerForms.lead_business_steward.email}
                onChange={(e) =>
                  setOwnerForms((f) => ({
                    ...f,
                    lead_business_steward: { ...f.lead_business_steward, email: e.target.value },
                  }))
                }
                placeholder="e.g. john.doe@company.com"
                className="h-8 text-xs font-mono"
              />
            </div>
            <div className="flex flex-col gap-2.5 p-3.5 rounded-md border border-slate-200 bg-slate-50/50">
              <span className="text-xs font-semibold font-mono uppercase tracking-wider text-slate-700">Data Owner</span>
              <Input
                label="Full Name"
                value={ownerForms.data_owner.full_name}
                onChange={(e) =>
                  setOwnerForms((f) => ({
                    ...f,
                    data_owner: { ...f.data_owner, full_name: e.target.value },
                  }))
                }
                placeholder="e.g. Jane Smith"
                className="h-8 text-xs"
              />
              <Input
                label="Position"
                value={ownerForms.data_owner.position}
                onChange={(e) =>
                  setOwnerForms((f) => ({
                    ...f,
                    data_owner: { ...f.data_owner, position: e.target.value },
                  }))
                }
                placeholder="e.g. CRM Department Head"
                className="h-8 text-xs"
              />
              <Input
                label="Email Address"
                type="email"
                value={ownerForms.data_owner.email}
                onChange={(e) =>
                  setOwnerForms((f) => ({
                    ...f,
                    data_owner: { ...f.data_owner, email: e.target.value },
                  }))
                }
                placeholder="e.g. jane.smith@company.com"
                className="h-8 text-xs font-mono"
              />
            </div>
          </CardContent>
        </Card>

        {serverError && (
          <div className="rounded-md bg-rose-50 border border-rose-200 p-3 text-xs font-mono text-rose-700">
            {serverError}
          </div>
        )}

        <div className="flex items-center justify-end gap-2.5 pt-1">
          <Button variant="outline" size="sm" type="button" className="h-8 text-xs" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button size="sm" type="submit" loading={create.isPending} className="h-8 text-xs font-medium">
            Create Data Asset
          </Button>
        </div>
      </form>
    </div>
  );
}
