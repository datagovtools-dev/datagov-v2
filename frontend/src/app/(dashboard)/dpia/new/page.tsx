"use client";

import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { toast } from "@/components/ui/Toast";

interface ProjectOption { id: string; project_code: string | null; project_name: string; customer_name: string; }
interface GovItem { id: string; item: string; responsible: "Internal" | "Client"; status: string; remarks: string; }
interface GovernanceJson { access: GovItem[]; secure_data: GovItem[]; secure_sharing_environment: GovItem[]; data_definition: GovItem[]; }


const GOVERNANCE_SECTIONS: { key: keyof GovernanceJson; label: string; code: string }[] = [
  { key: "access", label: "Access", code: "A" },
  { key: "secure_data", label: "Secure Data", code: "B" },
  { key: "secure_sharing_environment", label: "Secure Sharing Environment", code: "C" },
  { key: "data_definition", label: "Data Definition", code: "D" },
];

const DEFAULT_GOVERNANCE: GovernanceJson = {
  access: [
    { id: "access_1", item: "Data Sharing Request Document", responsible: "Internal", status: "", remarks: "" },
    { id: "access_2", item: "Revoke / Extermination Documentation", responsible: "Internal", status: "", remarks: "" },
    { id: "access_3", item: "Data Activity Records Documentation (during project)", responsible: "Internal", status: "", remarks: "" },
    { id: "access_4", item: "Role-Based Access Control Document", responsible: "Internal", status: "", remarks: "" },
    { id: "access_5", item: "Assess and Approve Documentation Above", responsible: "Client", status: "", remarks: "" },
    { id: "access_6", item: "Grant Access to Project Team Only (per RBAC document)", responsible: "Client", status: "", remarks: "" },
  ],
  secure_data: [
    { id: "secure_data_1", item: "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", responsible: "Client", status: "", remarks: "" },
  ],
  secure_sharing_environment: [
    { id: "secure_env_1", item: "Provide Secure Environment or Schema to Enable Data Sharing", responsible: "Client", status: "", remarks: "" },
  ],
  data_definition: [
    { id: "data_def_1", item: "Create Metadata Documentation", responsible: "Internal", status: "", remarks: "" },
    { id: "data_def_2", item: "Measure Data Quality Index", responsible: "Internal", status: "", remarks: "" },
    { id: "data_def_3", item: "Assess and Approve Metadata Definition", responsible: "Client", status: "", remarks: "" },
    { id: "data_def_4", item: "Assess and Approve Data Quality Measurement Approach and Index", responsible: "Client", status: "", remarks: "" },
  ],
};

function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}

const DATA_CATEGORY_GROUPS: { group: string; items: string[] }[] = [
  {
    group: "Personal Identity",
    items: ["Full Name", "National ID / IC Number", "Passport Number", "Date of Birth", "Gender", "Nationality", "Photograph", "Biometric Data"],
  },
  {
    group: "Contact Information",
    items: ["Email Address", "Phone Number", "Home / Residential Address", "Postal Code", "Emergency Contact"],
  },
  {
    group: "Financial",
    items: ["Bank Account Details", "Credit / Debit Card Data", "Transaction History", "Credit Score / Rating", "Loan & Debt Records", "Income / Salary Data", "Tax Records", "Insurance Data", "Investment & Portfolio Data"],
  },
  {
    group: "Employment & HR",
    items: ["Employee ID", "Job Title & Position", "Employment History", "Performance Records", "Payroll Data", "Attendance & Leave Records", "Disciplinary Records", "Contract Terms"],
  },
  {
    group: "Health & Medical",
    items: ["Medical Records", "Health Status & Diagnosis", "Prescription & Medication", "Mental Health Records", "Medical Insurance Claims", "Disability Status"],
  },
  {
    group: "Digital & Behavioural",
    items: ["IP Address & Device ID", "Browser & App Usage Logs", "GPS & Location Data", "Online Purchase Behaviour", "Cookies & Tracking Data", "Social Media Activity", "Click & Interaction Data"],
  },
  {
    group: "Education & Academic",
    items: ["Academic Records & Grades", "Certifications & Credentials", "Training & Development History", "Student ID"],
  },
  {
    group: "Legal & Compliance",
    items: ["Criminal Records", "KYC / AML Records", "Legal Case History", "Regulatory Filings", "Sanctions & Watchlist Data"],
  },
  {
    group: "Business & Commercial",
    items: ["Business Registration Data", "Contract & Agreement Data", "Customer Relationship (CRM)", "Vendor & Supplier Data", "Product & Pricing Data", "Marketing Preferences"],
  },
  {
    group: "Special Category (Sensitive)",
    items: ["Racial / Ethnic Origin", "Political Opinions", "Religious / Philosophical Beliefs", "Trade Union Membership", "Genetic Data", "Sexual Orientation"],
  },
];

export default function NewDPIAPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    project_id: "",
    process_name: "",
    risk_description: "",
    mitigation_measures: "",
    residual_risk: "",
  });
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [governance, setGovernance] = useState<GovernanceJson>(deepClone(DEFAULT_GOVERNANCE));
  const [errors, setErrors] = useState<Record<string, string>>({});
  const govContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = govContainerRef.current;
    if (!el) return;
    const observer = new ResizeObserver(() => {
      requestAnimationFrame(() => {
        el.querySelectorAll<HTMLTextAreaElement>("textarea").forEach((ta) => {
          ta.style.height = "auto";
          ta.style.height = ta.scrollHeight + "px";
        });
      });
    });
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const { data: projects } = useQuery<ProjectOption[]>({
    queryKey: ["projects-dpia-select"],
    queryFn: () =>
      api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const mutation = useMutation({
    mutationFn: (payload: typeof form & { data_category: string; governance_json: GovernanceJson }) => {
      toast.loading("Creating DPIA Privacy Assessment...", { id: "create-dpia" });
      const body: Record<string, unknown> = { ...payload };
      if (!body.mitigation_measures) delete body.mitigation_measures;
      if (!body.residual_risk) delete body.residual_risk;
      return api.post<{ id: string }>("/dpia", body);
    },
    onSuccess: (data: { id: string }) => {
      toast.success("DPIA Assessment created successfully!", { id: "create-dpia" });
      router.push(`/dpia/${data.id}`);
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to create DPIA Assessment", { id: "create-dpia" });
    },
  });

  function set(field: string, value: unknown) {
    setForm((f) => ({ ...f, [field]: value }));
    setErrors((e) => { const n = { ...e }; delete n[field]; return n; });
  }

  function updateItem(section: keyof GovernanceJson, itemId: string, field: "item" | "responsible", value: string) {
    setGovernance((prev) => ({
      ...prev,
      [section]: prev[section].map((it) =>
        it.id === itemId ? { ...it, [field]: value } : it
      ),
    }));
  }

  function validate() {
    const e: Record<string, string> = {};
    if (!form.project_id) e.project_id = "Required";
    if (selectedCategories.length === 0) e.data_category = "Select at least one data category";
    if (!form.risk_description.trim()) e.risk_description = "Required";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;
    mutation.mutate({ ...form, data_category: selectedCategories.join(", "), governance_json: governance });
  }

  const selectedProject = projects?.find((p) => p.id === form.project_id);

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center gap-3 pb-3 border-b border-slate-200">
        <Link
          href="/dpia"
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 text-slate-600"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            New Privacy Impact Assessment (DPIA)
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Evaluate privacy risks, data categories, and governance activity controls
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Process Information */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Process Information
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Project Asset <span className="text-rose-500">*</span>
              </label>
              <Select
                value={form.project_id}
                onValueChange={(v) => {
                  set("project_id", v);
                  const p = projects?.find((p) => p.id === v);
                  if (p) set("process_name", p.project_name);
                }}
              >
                <SelectTrigger className="h-8 text-xs" error={!!errors.project_id}>
                  <SelectValue placeholder="Select project asset..." />
                </SelectTrigger>
                <SelectContent>
                  {projects?.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.project_code ? `${p.project_code} — ` : ""}
                      {p.project_name} ({p.customer_name})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.project_id && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.project_id}</p>
              )}
              {selectedProject && (
                <p className="text-[11px] text-slate-500 font-mono mt-1">
                  Customer / Client: <span className="font-semibold text-slate-800">{selectedProject.customer_name}</span>
                </p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Data Categories — full width */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Data Categories Involved <span className="text-rose-500 text-xs font-normal">*</span>
            </CardTitle>
            <p className="text-xs text-slate-500 mt-0.5">Select all categories that apply. You may choose from multiple groups.</p>
          </CardHeader>
          <CardContent className="pt-4">
            <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
              {DATA_CATEGORY_GROUPS.map(({ group, items }) => (
                <div key={group} className="rounded-md border border-slate-200 bg-slate-50/50 p-2.5">
                  <p className="text-[10px] font-semibold text-slate-500 uppercase font-mono tracking-wide mb-1.5">{group}</p>
                  <div className="flex flex-wrap gap-1">
                    {items.map((item) => {
                      const selected = selectedCategories.includes(item);
                      return (
                        <button key={item} type="button"
                          onClick={() =>
                            setSelectedCategories((prev) =>
                              selected ? prev.filter((c) => c !== item) : [...prev, item]
                            )
                          }
                          className={`px-1.5 py-0.5 rounded-md text-[10px] font-mono transition-colors border ${
                            selected
                              ? "bg-slate-900 border-slate-900 text-white font-medium"
                              : "bg-white border-slate-200 text-slate-600 hover:border-slate-400"
                          }`}>
                          {selected && "✓ "}{item}
                        </button>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
            {selectedCategories.length > 0 && (
              <p className="text-xs text-slate-600 mt-2.5 font-mono">
                {selectedCategories.length} categor{selectedCategories.length === 1 ? "y" : "ies"} selected
                <button type="button" onClick={() => setSelectedCategories([])}
                  className="ml-2 text-slate-400 hover:text-rose-600 font-normal">Clear all</button>
              </p>
            )}
            {errors.data_category && <p className="text-xs text-rose-600 font-mono mt-1">{errors.data_category}</p>}
          </CardContent>
        </Card>

        {/* Risk Assessment */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Risk Assessment
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4 text-xs">
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Risk Description <span className="text-rose-500">*</span>
            </label>
            <p className="text-[11px] text-slate-500 mb-1.5">
              Identify the privacy risk and potential impact on data subjects if it materialises.<br />
              <span className="text-slate-400 italic">
                e.g. "Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm."
              </span>
            </p>
            <textarea value={form.risk_description} onChange={(e) => set("risk_description", e.target.value)} rows={4}
              className="w-full border border-slate-200 rounded-md px-3 py-2 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none"
              placeholder="Describe the privacy risk and potential harm to data subjects…" />
            {errors.risk_description && <p className="text-xs text-rose-600 font-mono mt-1">{errors.risk_description}</p>}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Mitigation &amp; Residual Risk
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-4 space-y-4 text-xs">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Mitigation Measures</label>
              <p className="text-[11px] text-slate-500 mb-1.5">
                Describe controls and safeguards in place to reduce the risk.<br />
                <span className="text-slate-400 italic">
                  e.g. "Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable."
                </span>
              </p>
              <textarea value={form.mitigation_measures} onChange={(e) => set("mitigation_measures", e.target.value)} rows={3}
                className="w-full border border-slate-200 rounded-md px-3 py-2 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none"
                placeholder="Describe controls and safeguards in place…" />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Residual Risk Level</label>
              <p className="text-[11px] text-slate-500 mb-2 font-mono">
                Level of risk remaining after mitigations are applied.
              </p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {[
                  { level: "Low",      desc: "Well-controlled. Acceptable with current safeguards." },
                  { level: "Medium",   desc: "Some risk remains. Additional monitoring may be needed." },
                  { level: "High",     desc: "Significant risk. Escalation recommended." },
                  { level: "Critical", desc: "Unacceptable. Executive sign-off required." },
                ].map(({ level, desc }) => {
                  const selected = form.residual_risk === level;
                  return (
                    <button key={level} type="button"
                      onClick={() => set("residual_risk", selected ? "" : level)}
                      className={`flex flex-col rounded-md border p-2 text-left transition-colors font-mono ${
                        selected
                          ? "border-slate-900 bg-slate-900 text-white"
                          : "border-slate-200 bg-slate-50/50 hover:bg-slate-100 text-slate-700"
                      }`}>
                      <p className="text-xs font-bold">{level}{selected && " ✓"}</p>
                      <p className={`text-[10px] mt-0.5 ${selected ? "text-slate-300" : "text-slate-500"}`}>{desc}</p>
                    </button>
                  );
                })}
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Governance Activities Template */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Governance Activities
            </CardTitle>
            <p className="text-xs text-slate-500 mt-0.5">
              Pre-filled from the standard template. Edit activity descriptions and responsible party as needed.
            </p>
          </CardHeader>
          <CardContent className="pt-4 space-y-4">
            <div ref={govContainerRef} className="space-y-4">
            {GOVERNANCE_SECTIONS.map(({ key, label, code }) => {
              const items = governance[key];
              return (
                <div key={key}>
                  <p className="text-xs font-semibold font-mono text-slate-900 mb-2 flex items-center gap-1.5">
                    <span className="inline-flex items-center justify-center w-4 h-4 rounded-md bg-slate-900 text-white text-[10px] font-bold">{code}</span>
                    {label}
                  </p>
                  <div className="space-y-1.5">
                    {items.map((item, idx) => (
                      <div key={item.id} className="flex items-center gap-2 p-2 rounded-md border border-slate-200 bg-slate-50/30 min-w-0">
                        <span className="text-[10px] text-slate-400 font-mono min-w-[18px] shrink-0">{idx + 1}.</span>
                        <div className="flex-1 min-w-0 flex items-center">
                          <textarea
                            value={item.item}
                            rows={1}
                            onChange={(e) => {
                              updateItem(key, item.id, "item", e.target.value);
                              e.target.style.height = "auto";
                              e.target.style.height = e.target.scrollHeight + "px";
                            }}
                            ref={(el) => { if (el) { requestAnimationFrame(() => { el.style.height = "auto"; el.style.height = el.scrollHeight + "px"; }); } }}
                            className="w-full border border-slate-200 rounded-md px-2.5 py-1 text-xs bg-white focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none overflow-hidden"
                          />
                        </div>
                        <div className="flex items-stretch rounded-md border border-slate-200 overflow-hidden shrink-0">
                          <button
                            type="button"
                            onClick={() => updateItem(key, item.id, "responsible", "Internal")}
                            className={`px-2 py-1 text-[10px] font-mono transition-colors ${
                              item.responsible === "Internal"
                                ? "bg-slate-900 text-white font-medium"
                                : "bg-white text-slate-500 hover:bg-slate-50"
                            }`}
                          >
                            ADI-DI
                          </button>
                          <button
                            type="button"
                            onClick={() => updateItem(key, item.id, "responsible", "Client")}
                            className={`px-2 py-1 text-[10px] font-mono transition-colors border-l border-slate-200 ${
                              item.responsible === "Client"
                                ? "bg-slate-700 text-white font-medium"
                                : "bg-white text-slate-500 hover:bg-slate-50"
                            }`}
                          >
                            {selectedProject?.customer_name || "Client"}
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              );
            })}
            <p className="text-[11px] text-slate-400 font-mono">
              Status and remarks for each activity can be tracked on the detail page after creation.
            </p>
            </div>
          </CardContent>
        </Card>

        {mutation.isError && (
          <div className="rounded-md bg-rose-50 border border-rose-200 p-3 text-xs font-mono text-rose-700">
            Failed to create DPIA. Please check all required fields.
          </div>
        )}

        <div className="flex items-center justify-end gap-2.5 pt-1">
          <Button type="button" variant="outline" size="sm" className="h-8 text-xs" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button type="submit" size="sm" loading={mutation.isPending} className="h-8 text-xs font-medium">
            Create DPIA Assessment
          </Button>
        </div>
      </form>
    </div>
  );
}
