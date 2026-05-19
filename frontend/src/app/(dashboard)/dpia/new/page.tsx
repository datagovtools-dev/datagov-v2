"use client";

import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";

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
      const body: Record<string, unknown> = { ...payload };
      if (!body.mitigation_measures) delete body.mitigation_measures;
      if (!body.residual_risk) delete body.residual_risk;
      return api.post<{ id: string }>("/dpia", body);
    },
    onSuccess: (data: { id: string }) => router.push(`/dpia/${data.id}`),
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
    <div className="p-6 space-y-5">
      <div>
        <button onClick={() => router.back()} className="text-sm text-surface-400 hover:text-surface-600 mb-2">← Back</button>
        <h1 className="text-2xl font-bold text-surface-900">New Data Protection Impact Assessment</h1>
        <p className="text-sm text-surface-500 mt-1">Document privacy risks and governance activities for a data processing activity</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-5">

        {/* Process Information */}
        <Card>
          <CardHeader><CardTitle>Process Information</CardTitle></CardHeader>
          <CardContent>
            <div>
              <label className="block text-sm font-medium text-surface-700 mb-1">Project <span className="text-red-500">*</span></label>
              <select value={form.project_id} onChange={(e) => { set("project_id", e.target.value); const p = projects?.find((p) => p.id === e.target.value); if (p) set("process_name", p.project_name); }}
                className="w-full border border-surface-200 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500">
                <option value="">Select project…</option>
                {projects?.map((p) => (
                  <option key={p.id} value={p.id}>{p.project_code ? `${p.project_code} — ` : ""}{p.project_name} ({p.customer_name})</option>
                ))}
              </select>
              {errors.project_id && <p className="text-xs text-red-500 mt-1">{errors.project_id}</p>}
              {selectedProject && (
                <p className="text-xs text-surface-400 mt-1">Customer / Client: {selectedProject.customer_name}</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Data Categories — full width */}
        <Card>
          <CardHeader>
            <CardTitle>Data Categories Involved <span className="text-red-500 text-sm font-normal">*</span></CardTitle>
            <p className="text-xs text-surface-500 mt-0.5">Select all categories that apply. You may choose from multiple groups.</p>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-5 gap-2">
              {DATA_CATEGORY_GROUPS.map(({ group, items }) => (
                <div key={group} className="rounded-lg border border-surface-200 bg-surface-50 px-3 py-2.5">
                  <p className="text-[10px] font-semibold text-surface-400 uppercase tracking-wide mb-1.5">{group}</p>
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
                          className={`px-1.5 py-0.5 rounded-full text-[11px] font-medium border transition-all ${
                            selected
                              ? "bg-primary-600 border-primary-600 text-white"
                              : "bg-white border-surface-200 text-surface-600 hover:border-primary-400 hover:text-primary-600"
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
              <p className="text-xs text-primary-600 mt-2 font-medium">
                {selectedCategories.length} categor{selectedCategories.length === 1 ? "y" : "ies"} selected
                <button type="button" onClick={() => setSelectedCategories([])}
                  className="ml-2 text-surface-400 hover:text-red-500 font-normal">Clear all</button>
              </p>
            )}
            {errors.data_category && <p className="text-xs text-red-500 mt-1">{errors.data_category}</p>}
          </CardContent>
        </Card>

        {/* Risk Assessment */}
        <Card>
            <CardHeader><CardTitle>Risk Assessment</CardTitle></CardHeader>
            <CardContent>
              <label className="block text-sm font-medium text-surface-700 mb-1">
                Risk Description <span className="text-red-500">*</span>
              </label>
              <p className="text-xs text-surface-400 mb-1.5">
                Identify the privacy risk and potential impact on data subjects if it materialises.<br />
                <span className="text-surface-500 italic">
                  e.g. "Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm."
                </span>
              </p>
              <textarea value={form.risk_description} onChange={(e) => set("risk_description", e.target.value)} rows={5}
                className="w-full border border-surface-200 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none"
                placeholder="Describe the privacy risk and potential harm to data subjects…" />
              {errors.risk_description && <p className="text-xs text-red-500 mt-1">{errors.risk_description}</p>}
            </CardContent>
          </Card>

          <Card>
            <CardHeader><CardTitle>Mitigation &amp; Residual Risk</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Mitigation Measures</label>
                <p className="text-xs text-surface-400 mb-1.5">
                  Describe controls and safeguards in place to reduce the risk.<br />
                  <span className="text-surface-500 italic">
                    e.g. "Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable."
                  </span>
                </p>
                <textarea value={form.mitigation_measures} onChange={(e) => set("mitigation_measures", e.target.value)} rows={3}
                  className="w-full border border-surface-200 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none"
                  placeholder="Describe controls and safeguards in place…" />
              </div>
              <div>
                <label className="block text-sm font-medium text-surface-700 mb-1">Residual Risk Level</label>
                <p className="text-xs text-surface-400 mb-2">
                  Level of risk remaining <span className="font-medium text-surface-600">after</span> mitigations are applied.
                </p>
                <div className="grid grid-cols-2 gap-2">
                  {[
                    { level: "Low",      idle: "border-green-200 bg-green-50 hover:bg-green-100",    active: "border-green-500 bg-green-100 ring-2 ring-green-400",    dot: "bg-green-500",  text: "text-green-800",  desc: "Well-controlled. Acceptable with current safeguards." },
                    { level: "Medium",   idle: "border-amber-200 bg-amber-50 hover:bg-amber-100",    active: "border-amber-500 bg-amber-100 ring-2 ring-amber-400",    dot: "bg-amber-500",  text: "text-amber-800",  desc: "Some risk remains. Additional monitoring may be needed." },
                    { level: "High",     idle: "border-orange-200 bg-orange-50 hover:bg-orange-100", active: "border-orange-500 bg-orange-100 ring-2 ring-orange-400", dot: "bg-orange-500", text: "text-orange-800", desc: "Significant risk. Immediate action or escalation recommended." },
                    { level: "Critical", idle: "border-red-200 bg-red-50 hover:bg-red-100",          active: "border-red-500 bg-red-100 ring-2 ring-red-400",          dot: "bg-red-500",    text: "text-red-800",    desc: "Unacceptable. Do not proceed without executive sign-off." },
                  ].map(({ level, idle, active, dot, text, desc }) => {
                    const selected = form.residual_risk === level;
                    return (
                      <button key={level} type="button"
                        onClick={() => set("residual_risk", selected ? "" : level)}
                        className={`flex items-start gap-2 rounded-lg border-2 px-2.5 py-2 text-left transition-all ${selected ? active : idle}`}>
                        <span className={`mt-0.5 w-2 h-2 rounded-full shrink-0 ${dot}`} />
                        <div className={text}>
                          <p className={`text-xs font-bold ${selected ? "" : "opacity-80"}`}>{level}{selected && " ✓"}</p>
                          <p className="text-[11px] leading-snug opacity-75 mt-0.5">{desc}</p>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            </CardContent>
          </Card>

        {/* Governance Activities Template */}
        <Card>
          <CardHeader>
            <CardTitle>Governance Activities</CardTitle>
            <p className="text-xs text-surface-500 mt-0.5">
              Pre-filled from the standard template. Edit activity descriptions and responsible party as needed.
            </p>
          </CardHeader>
          <CardContent className="space-y-6">
            <div ref={govContainerRef} className="space-y-6">
            {GOVERNANCE_SECTIONS.map(({ key, label, code }) => {
              const items = governance[key];
              return (
                <div key={key}>
                  <p className="text-sm font-semibold text-surface-700 mb-2 flex items-center gap-2">
                    <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-primary-100 text-primary-700 text-xs font-bold">{code}</span>
                    {label}
                  </p>
                  <div className="space-y-2">
                    {items.map((item, idx) => (
                      <div key={item.id} className="flex items-stretch gap-2 p-2.5 rounded-lg border border-surface-200 bg-surface-50 min-w-0">
                        <span className="text-xs text-surface-400 font-mono self-start pt-2 min-w-[20px] shrink-0">{idx + 1}.</span>
                        <div className="flex-1 min-w-0 flex items-stretch">
                          <textarea
                            value={item.item}
                            rows={1}
                            onChange={(e) => {
                              updateItem(key, item.id, "item", e.target.value);
                              e.target.style.height = "auto";
                              e.target.style.height = e.target.scrollHeight + "px";
                            }}
                            ref={(el) => { if (el) { requestAnimationFrame(() => { el.style.height = "auto"; el.style.height = el.scrollHeight + "px"; }); } }}
                            className="w-full border border-surface-200 rounded px-2.5 py-1.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none overflow-hidden"
                          />
                        </div>
                        <div className="flex items-stretch self-stretch rounded-md border border-surface-200 overflow-hidden">
                          <button
                            type="button"
                            onClick={() => updateItem(key, item.id, "responsible", "Internal")}
                            className={`px-2.5 flex items-center justify-center text-xs font-medium text-center transition-colors ${
                              item.responsible === "Internal"
                                ? "bg-blue-600 text-white"
                                : "bg-white text-surface-500 hover:bg-surface-50"
                            }`}
                          >
                            ADI-DI
                          </button>
                          <button
                            type="button"
                            onClick={() => updateItem(key, item.id, "responsible", "Client")}
                            className={`px-2.5 flex items-center justify-center text-xs font-medium text-center transition-colors border-l border-surface-200 ${
                              item.responsible === "Client"
                                ? "bg-purple-600 text-white"
                                : "bg-white text-surface-500 hover:bg-surface-50"
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
            <p className="text-xs text-surface-400">
              Status and remarks for each activity can be tracked on the detail page after creation.
            </p>
            </div>
          </CardContent>
        </Card>

        {mutation.isError && (
          <p className="text-sm text-red-600 bg-red-50 px-4 py-2 rounded border border-red-200">
            Failed to create DPIA. Please check all required fields.
          </p>
        )}

        <div className="flex justify-end gap-3">
          <Button type="button" variant="outline" onClick={() => router.back()}>Cancel</Button>
          <Button type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? "Creating…" : "Create DPIA"}
          </Button>
        </div>
      </form>
    </div>
  );
}
