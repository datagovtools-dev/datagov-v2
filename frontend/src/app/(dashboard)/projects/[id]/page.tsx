"use client";

import * as React from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Download, Pencil, Save, X } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { UserCombobox } from "@/components/ui/UserCombobox";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import {
  ProjectBasicInformationContent,
  ProjectOwnerStewardContent,
  ProjectTeamContent,
  retentionBasisText,
  type SourceFileRetentionLike,
} from "@/components/details/ProjectDetailView";
import { formatDate } from "@/lib/utils";
import { printA4, pdfField } from "@/lib/exportPdf";

interface UserOption { id: string; full_name: string; email: string }
interface OwnerRecord { id: string; role_type: string; full_name: string; email: string; position?: string | null }
interface ProjectOut {
  id: string; project_code: string | null; project_name: string; customer_name: string;
  line_of_business: string | null; use_case: string | null;
  project_year: number; project_category: string; is_monetized: boolean;
  start_date: string | null; end_date: string | null;
  sme_id: string | null;
  delivery_manager_id: string | null; project_manager_id: string | null;
  dgo_id: string | null; metadata_officer_id: string | null;
  dq_officer_id: string | null; pic_data_compliance_id: string | null;
  created_by: string; created_at: string; updated_at: string;
}

const CATEGORIES = ["AI / ML", "Analytics", "Data Governance", "Data Quality", "Integration", "Other"];
const CURRENT_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 6 }, (_, i) => CURRENT_YEAR - 2 + i);

export default function ProjectDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const [editing, setEditing] = React.useState(false);
  const [form, setForm] = React.useState<Record<string, string>>({});
  const [teamErrors, setTeamErrors] = React.useState<Record<string, string>>({});
  const [serverError, setServerError] = React.useState("");

  const { data: project, isLoading } = useQuery<ProjectOut>({
    queryKey: ["project", id],
    queryFn: () => api.get<ProjectOut>(`/projects/${id}`),
  });

  const { data: users = [] } = useQuery<UserOption[]>({
    queryKey: ["users-options"],
    queryFn: () => api.get<UserOption[]>("/rbac/users/options"),
  });

  const { data: owners = [] } = useQuery<OwnerRecord[]>({
    queryKey: ["project-owners", id],
    queryFn: () => api.get<OwnerRecord[]>(`/metadata/owners/${id}`),
    enabled: !!id,
  });

  // Until when uploaded source files are kept (end date + 30 days, or the approved ROPA retention period)
  const { data: retention } = useQuery<SourceFileRetentionLike>({
    queryKey: ["project-retention", id],
    queryFn: () => api.get<SourceFileRetentionLike>(`/projects/${id}/source-file-retention`),
    enabled: !!id,
  });

  const [ownerForms, setOwnerForms] = React.useState({
    lead_business_steward: { full_name: "", email: "", position: "" },
    data_owner:            { full_name: "", email: "", position: "" },
  });

  const userOptions = users.map(u => ({ value: u.id, label: u.full_name, sublabel: u.email }));

  function startEdit() {
    if (!project) return;
    setForm({
      project_code: project.project_code ?? "",
      project_name: project.project_name,
      customer_name: project.customer_name,
      line_of_business: project.line_of_business ?? "",
      use_case: project.use_case ?? "",
      project_year: String(project.project_year),
      project_category: project.project_category,
      is_monetized: String(project.is_monetized),
      start_date: project.start_date ?? "",
      end_date: project.end_date ?? "",
      sme_id: project.sme_id ?? "",
      delivery_manager_id: project.delivery_manager_id ?? "",
      project_manager_id: project.project_manager_id ?? "",
      dgo_id: project.dgo_id ?? "",
      metadata_officer_id: project.metadata_officer_id ?? "",
      dq_officer_id: project.dq_officer_id ?? "",
      pic_data_compliance_id: project.pic_data_compliance_id ?? "",
    });
    const steward = owners.find(o => o.role_type === "lead_business_steward") ?? owners.find(o => o.role_type === "business_steward");
    const owner   = owners.find(o => o.role_type === "data_owner");
    setOwnerForms({
      lead_business_steward: { full_name: steward?.full_name ?? "", email: steward?.email ?? "", position: steward?.position ?? "" },
      data_owner:            { full_name: owner?.full_name   ?? "", email: owner?.email   ?? "", position: owner?.position   ?? "" },
    });
    setEditing(true);
    setServerError("");
  }

  function set(key: string, val: string) {
    setForm(f => ({ ...f, [key]: val }));
    if (teamErrors[key]) setTeamErrors(e => { const n = { ...e }; delete n[key]; return n; });
  }

  const REQUIRED_TEAM_FIELDS: [string, string][] = [
    ["sme_id",                "Subject Matter Expert (SME)"],
    ["delivery_manager_id",   "Delivery Manager"],
    ["project_manager_id",    "Project Manager"],
    ["dgo_id",                "Data Governance Officer"],
    ["metadata_officer_id",   "Metadata Officer"],
    ["dq_officer_id",         "DQ Officer"],
    ["pic_data_compliance_id","PIC Data Compliance"],
  ];

  function validateAndSave() {
    const errs: Record<string, string> = {};
    for (const [field] of REQUIRED_TEAM_FIELDS) {
      if (!form[field]) errs[field] = "This field is required";
    }
    setTeamErrors(errs);
    if (Object.keys(errs).length > 0) return;
    update.mutate();
  }

  const saveOwnersMutation = useMutation({
    mutationFn: async () => {
      const roles: [string, { full_name: string; email: string; position: string }][] = [
        ["lead_business_steward", ownerForms.lead_business_steward],
        ["data_owner",            ownerForms.data_owner],
      ];
      for (const [role_type, data] of roles) {
        if (data.full_name.trim()) {
          await api.post(`/metadata/owners/${id}`, {
            role_type,
            full_name: data.full_name.trim(),
            email: data.email.trim(),
            position: data.position.trim() || null,
          });
        }
      }
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ["project-owners", id] }),
  });

  const update = useMutation({
    mutationFn: () => api.put(`/projects/${id}`, {
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
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["project", id] });
      qc.invalidateQueries({ queryKey: ["project-retention", id] });
      qc.invalidateQueries({ queryKey: ["projects"] });
      saveOwnersMutation.mutate();
      setEditing(false);
    },
    onError: (e: any) => setServerError(e.message),
  });

  if (isLoading) return <DetailSkeleton />;
  if (!project) return <div className="py-20 text-center text-surface-400">Project not found.</div>;

  function userName(uid: string | null) {
    if (!uid) return "—";
    const u = users.find(u => u.id === uid);
    return u ? u.full_name : "—";
  }

  function userEmail(uid: string | null) {
    if (!uid) return "";
    const u = users.find(u => u.id === uid);
    return u ? u.email : "";
  }

  function handleExportPDF() {
    if (!project) return;
    const dataStewardRec = owners.find(o => o.role_type === "lead_business_steward") ?? owners.find(o => o.role_type === "business_steward");
    const dataOwnerRec   = owners.find(o => o.role_type === "data_owner");

    const teamRows = [
      ["Subject Matter Expert (SME)", project.sme_id],
      ["Delivery Manager",        project.delivery_manager_id],
      ["Project Manager",         project.project_manager_id],
      ["Data Governance Officer", project.dgo_id],
      ["Metadata Officer",        project.metadata_officer_id],
      ["DQ Officer",              project.dq_officer_id],
      ["PIC Data Compliance",     project.pic_data_compliance_id],
    ].map(([label, uid]) => `
      <tr>
        <td>${label}</td>
        <td>${userName(uid as string | null)}</td>
        <td>${userEmail(uid as string | null)}</td>
      </tr>`).join("");

    const ownerRows = [
      ["Data Steward", dataStewardRec],
      ["Data Owner",   dataOwnerRec],
    ].map(([label, rec]) => `
      <tr>
        <td>${label}</td>
        <td>${(rec as OwnerRecord | undefined)?.full_name ?? "—"}${(rec as OwnerRecord | undefined)?.position ? `<br><span style="color:#64748b">${(rec as OwnerRecord).position}</span>` : ""}</td>
        <td>${(rec as OwnerRecord | undefined)?.email ?? ""}</td>
      </tr>`).join("");

    const body = `
      <h1 class="doc-title">${project.project_name}</h1>
      <div class="doc-subtitle">
        ${project.project_code ? `<strong>${project.project_code}</strong> &nbsp;·&nbsp;` : ""}
        ${project.customer_name} &nbsp;·&nbsp; ${project.project_year}
      </div>

      <div class="section">
        <div class="section-title">Basic Information</div>
        <div class="grid2">
          ${pdfField("Project ID", project.project_code)}
          ${pdfField("Customer / Client", project.customer_name)}
          ${pdfField("Project Name", project.project_name)}
          ${pdfField("Line of Business", project.line_of_business)}
          ${pdfField("Project Category", project.project_category)}
          ${pdfField("Project Year", String(project.project_year))}
          ${pdfField("Monetized", project.is_monetized ? "Yes" : "No")}
          ${pdfField("Start Date", project.start_date ? formatDate(project.start_date) : null)}
          ${pdfField("End Date", project.end_date ? formatDate(project.end_date) : null)}
          ${retention?.expiry_date ? pdfField("Uploaded Source Files Kept Until", `${formatDate(retention.expiry_date)} — ${retentionBasisText(retention)}`, true) : ""}
          ${project.use_case ? pdfField("Use Case / Description", project.use_case, true) : ""}
        </div>
      </div>

      <div class="section">
        <div class="section-title">Project Team</div>
        <table>
          <thead><tr><th>Role</th><th>Name</th><th>Email</th></tr></thead>
          <tbody>${teamRows}</tbody>
        </table>
      </div>

      <div class="section">
        <div class="section-title">Data Steward &amp; Data Owner</div>
        <table>
          <thead><tr><th>Role</th><th>Full Name</th><th>Email</th></tr></thead>
          <tbody>${ownerRows}</tbody>
        </table>
      </div>
    `;

    printA4(`${project.project_code ?? project.project_name} — Project`, body);
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-start gap-3 pb-3 border-b border-slate-200">
        <Link href="/projects" className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 mt-0.5 text-slate-600">
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 truncate">{project.project_name}</h1>
                {project.project_code && (
                  <span className="shrink-0 text-xs font-mono font-medium text-slate-700 bg-slate-100 border border-slate-200 rounded-md px-2 py-0.5">
                    {project.project_code}
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-500 font-mono mt-0.5">
                Created {formatDate(project.created_at)} · Last updated {formatDate(project.updated_at)}
              </p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium" onClick={handleExportPDF}>
                <Download className="h-3.5 w-3.5 mr-1" /> Export PDF
              </Button>
              {!editing ? (
                <Button size="sm" className="h-7.5 text-xs font-medium" onClick={startEdit}>
                  <Pencil className="h-3.5 w-3.5 mr-1" /> Edit
                </Button>
              ) : (
                <>
                  <Button variant="outline" size="sm" className="h-7.5 text-xs" onClick={() => { setEditing(false); setTeamErrors({}); setServerError(""); }}>
                    <X className="h-3.5 w-3.5 mr-1" /> Cancel
                  </Button>
                  <Button size="sm" className="h-7.5 text-xs font-medium" onClick={validateAndSave} loading={update.isPending}>
                    <Save className="h-3.5 w-3.5 mr-1" /> Save
                  </Button>
                </>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-4">
        {/* Basic Info */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Basic Information
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            {editing ? (
              <>
                <Input label="Project ID" value={form.project_code} readOnly disabled
                  hint="Assigned by the system (PRJ-<Project Year>-<number>). Changing the Project Year assigns a new ID." />
                <div className="hidden md:block" />
                <Input label="Project Name" value={form.project_name} onChange={e => set("project_name", e.target.value)} required />
                <Input label="Customer / Client Name" value={form.customer_name} onChange={e => set("customer_name", e.target.value)} required />
                <Input label="Line of Business" value={form.line_of_business} onChange={e => set("line_of_business", e.target.value)} placeholder="e.g. Retail Banking" />
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-semibold text-slate-700">Project Category</label>
                  <Select value={form.project_category} onValueChange={v => set("project_category", v)}>
                    <SelectTrigger className="h-8 text-xs"><SelectValue /></SelectTrigger>
                    <SelectContent>{CATEGORIES.map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}</SelectContent>
                  </Select>
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-semibold text-slate-700">Project Year</label>
                  <Select value={form.project_year} onValueChange={v => set("project_year", v)}>
                    <SelectTrigger className="h-8 text-xs"><SelectValue /></SelectTrigger>
                    <SelectContent>{YEARS.map(y => <SelectItem key={y} value={String(y)}>{y}</SelectItem>)}</SelectContent>
                  </Select>
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-semibold text-slate-700">Monetized Project?</label>
                  <Select value={form.is_monetized} onValueChange={v => set("is_monetized", v)}>
                    <SelectTrigger className="h-8 text-xs"><SelectValue /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="false">No</SelectItem>
                      <SelectItem value="true">Yes</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <Input label="Start Date" type="date" value={form.start_date} onChange={e => set("start_date", e.target.value)} className="h-8 text-xs font-mono" />
                <Input label="End Date" type="date" value={form.end_date} onChange={e => set("end_date", e.target.value)} className="h-8 text-xs font-mono" />
                <div className="md:col-span-2">
                  <label className="text-xs font-semibold text-slate-700 block mb-1">Use Case / Description</label>
                  <textarea className="input-base min-h-[70px] resize-y w-full text-xs font-sans" value={form.use_case}
                    onChange={e => set("use_case", e.target.value)} placeholder="Brief description…" />
                </div>
              </>
            ) : (
              <ProjectBasicInformationContent project={project} retention={retention} />
            )}
          </CardContent>
        </Card>

        {/* Project Team */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Project Team
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            {editing ? (
              <>
                <UserCombobox label="Subject Matter Expert (SME)" required options={userOptions} value={form.sme_id}                onChange={v => set("sme_id", v)}                error={teamErrors.sme_id} />
                <UserCombobox label="Delivery Manager"        required options={userOptions} value={form.delivery_manager_id}        onChange={v => set("delivery_manager_id", v)}        error={teamErrors.delivery_manager_id} />
                <UserCombobox label="Project Manager"         required options={userOptions} value={form.project_manager_id}         onChange={v => set("project_manager_id", v)}         error={teamErrors.project_manager_id} />
                <UserCombobox label="Data Governance Officer" required options={userOptions} value={form.dgo_id}                     onChange={v => set("dgo_id", v)}                     error={teamErrors.dgo_id} />
                <UserCombobox label="Metadata Officer"        required options={userOptions} value={form.metadata_officer_id}        onChange={v => set("metadata_officer_id", v)}        error={teamErrors.metadata_officer_id} />
                <UserCombobox label="DQ Officer"              required options={userOptions} value={form.dq_officer_id}              onChange={v => set("dq_officer_id", v)}              error={teamErrors.dq_officer_id} />
                <UserCombobox label="PIC Data Compliance"     required options={userOptions} value={form.pic_data_compliance_id}     onChange={v => set("pic_data_compliance_id", v)}     error={teamErrors.pic_data_compliance_id} />
              </>
            ) : (
              <ProjectTeamContent project={project} users={users} />
            )}
          </CardContent>
        </Card>

        {/* Data Steward & Data Owner */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Data Steward &amp; Data Owner
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-5">
            {editing ? (
              <>
                {/* Data Steward */}
                <div className="flex flex-col gap-2">
                  <p className="text-xs font-semibold text-slate-700 font-mono">Data Steward</p>
                  <Input
                    label="Full Name"
                    value={ownerForms.lead_business_steward.full_name}
                    onChange={e => setOwnerForms(f => ({ ...f, lead_business_steward: { ...f.lead_business_steward, full_name: e.target.value } }))}
                    placeholder="e.g. John Doe"
                    className="h-8 text-xs"
                  />
                  <Input
                    label="Email Address"
                    type="email"
                    value={ownerForms.lead_business_steward.email}
                    onChange={e => setOwnerForms(f => ({ ...f, lead_business_steward: { ...f.lead_business_steward, email: e.target.value } }))}
                    placeholder="e.g. john.doe@company.com"
                    className="h-8 text-xs font-mono"
                  />
                </div>
                {/* Data Owner */}
                <div className="flex flex-col gap-2">
                  <p className="text-xs font-semibold text-slate-700 font-mono">Data Owner</p>
                  <Input
                    label="Full Name"
                    value={ownerForms.data_owner.full_name}
                    onChange={e => setOwnerForms(f => ({ ...f, data_owner: { ...f.data_owner, full_name: e.target.value } }))}
                    placeholder="e.g. Jane Smith"
                    className="h-8 text-xs"
                  />
                  <Input
                    label="Position"
                    value={ownerForms.data_owner.position}
                    onChange={e => setOwnerForms(f => ({ ...f, data_owner: { ...f.data_owner, position: e.target.value } }))}
                    placeholder="e.g. CRM Department Head"
                    className="h-8 text-xs"
                  />
                  <Input
                    label="Email Address"
                    type="email"
                    value={ownerForms.data_owner.email}
                    onChange={e => setOwnerForms(f => ({ ...f, data_owner: { ...f.data_owner, email: e.target.value } }))}
                    placeholder="e.g. jane.smith@company.com"
                    className="h-8 text-xs font-mono"
                  />
                </div>
              </>
            ) : (
              <ProjectOwnerStewardContent owners={owners} />
            )}
          </CardContent>
        </Card>

        {serverError && (
          <p className="rounded-md bg-rose-50 border border-rose-200 px-3.5 py-2 text-xs text-rose-700 font-mono">{serverError}</p>
        )}
      </div>
    </div>
  );
}
