"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Download, Pencil, Save, Send, X } from "lucide-react";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { formatDate } from "@/lib/utils";
import { printA4, pdfField, pdfBadge, pdfStatusBadge } from "@/lib/exportPdf";

// ── Types ─────────────────────────────────────────────────────────────────────

interface GovernanceItem {
  id: string;
  item: string;
  responsible: "Internal" | "Client";
  status: "" | "yes" | "no" | "in_progress" | "na";
  remarks: string;
}

interface GovernanceJson {
  access: GovernanceItem[];
  secure_data: GovernanceItem[];
  secure_sharing_environment: GovernanceItem[];
  data_definition: GovernanceItem[];
}

interface ProjectDetail {
  id: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
  project_category: string;
  line_of_business: string | null;
  project_year: number;
  start_date: string | null;
  end_date: string | null;
  is_monetized: boolean;
  use_case: string | null;
  delivery_manager_id: string | null;
  project_manager_id: string | null;
  sme_id: string | null;
  dgo_id: string | null;
  metadata_officer_id: string | null;
  dq_officer_id: string | null;
  pic_data_compliance_id: string | null;
}

interface UserOption {
  id: string;
  full_name: string;
  email: string;
  position: string | null;
}

interface DPIAApproval {
  id: string;
  step_order: number;
  approver_id: string;
  approver_role: string;
  approver_name: string;
  status: string;
  comments: string | null;
  actioned_at: string | null;
}

interface DPIADetail {
  id: string;
  tracking_id: string | null;
  project_id: string;
  project_code: string | null;
  project_name: string | null;
  customer_name: string | null;
  process_name: string;
  purpose: string;
  data_category: string;
  risk_description: string;
  mitigation_measures: string | null;
  residual_risk: string | null;
  likelihood_score: number | null;
  impact_score: number | null;
  risk_score: number | null;
  assessment_date: string;
  responsible_party_id: string;
  status: string;
  version: number;
  governance_json: GovernanceJson | null;
  approvals: DPIAApproval[];
  created_at: string;
  updated_at: string;
}

// ── Constants ─────────────────────────────────────────────────────────────────

const REGULATORY_REFS = [
  { pasal: "Pasal 34", desc: "Activity of evaluating, scoring and monitoring of Data Subject considered as High-Risk Activity" },
  { pasal: "Pasal 35–39", desc: "Designing and operating technical measures to protect personal data" },
  { pasal: "Pasal 42–44", desc: "Exterminating personal data after the objective is achieved" },
  { pasal: "Pasal 29", desc: "Accuracy of data to be measured and validated" },
];

const GOVERNANCE_SECTIONS: { key: keyof GovernanceJson; label: string; code: string }[] = [
  { key: "access", label: "Access", code: "A" },
  { key: "secure_data", label: "Secure Data", code: "B" },
  { key: "secure_sharing_environment", label: "Secure Sharing Environment", code: "C" },
  { key: "data_definition", label: "Data Definition", code: "D" },
];

const RESIDUAL_RISK_META: Record<string, { dot: string; text: string; border: string; bg: string; desc: string }> = {
  Low:      { dot: "bg-green-500",  text: "text-green-800",  border: "border-green-300",  bg: "bg-green-50",  desc: "Well-controlled. Acceptable with current safeguards." },
  Medium:   { dot: "bg-amber-500",  text: "text-amber-800",  border: "border-amber-300",  bg: "bg-amber-50",  desc: "Some risk remains. Additional monitoring may be needed." },
  High:     { dot: "bg-orange-500", text: "text-orange-800", border: "border-orange-300", bg: "bg-orange-50", desc: "Significant risk. Immediate action or escalation recommended." },
  Critical: { dot: "bg-red-500",    text: "text-red-800",    border: "border-red-300",    bg: "bg-red-50",    desc: "Unacceptable. Do not proceed without executive sign-off." },
};

const DATA_CATEGORY_GROUPS: { group: string; items: string[] }[] = [
  { group: "Personal Identity", items: ["Full Name", "National ID / IC Number", "Passport Number", "Date of Birth", "Gender", "Nationality", "Photograph", "Biometric Data"] },
  { group: "Contact Information", items: ["Email Address", "Phone Number", "Home / Residential Address", "Postal Code", "Emergency Contact"] },
  { group: "Financial", items: ["Bank Account Details", "Credit / Debit Card Data", "Transaction History", "Credit Score / Rating", "Loan & Debt Records", "Income / Salary Data", "Tax Records", "Insurance Data", "Investment & Portfolio Data"] },
  { group: "Employment & HR", items: ["Employee ID", "Job Title & Position", "Employment History", "Performance Records", "Payroll Data", "Attendance & Leave Records", "Disciplinary Records", "Contract Terms"] },
  { group: "Health & Medical", items: ["Medical Records", "Health Status & Diagnosis", "Prescription & Medication", "Mental Health Records", "Medical Insurance Claims", "Disability Status"] },
  { group: "Digital & Behavioural", items: ["IP Address & Device ID", "Browser & App Usage Logs", "GPS & Location Data", "Online Purchase Behaviour", "Cookies & Tracking Data", "Social Media Activity", "Click & Interaction Data"] },
  { group: "Education & Academic", items: ["Academic Records & Grades", "Certifications & Credentials", "Training & Development History", "Student ID"] },
  { group: "Legal & Compliance", items: ["Criminal Records", "KYC / AML Records", "Legal Case History", "Regulatory Filings", "Sanctions & Watchlist Data"] },
  { group: "Business & Commercial", items: ["Business Registration Data", "Contract & Agreement Data", "Customer Relationship (CRM)", "Vendor & Supplier Data", "Product & Pricing Data", "Marketing Preferences"] },
  { group: "Special Category (Sensitive)", items: ["Racial / Ethnic Origin", "Political Opinions", "Religious / Philosophical Beliefs", "Trade Union Membership", "Genetic Data", "Sexual Orientation"] },
];


const DSR_CHECKLIST_SECTIONS: { section: string; title: string; aiOnly?: boolean; items: { id: string; label: string; sub?: { id: string; label: string }[] }[] }[] = [
  { section: "A", title: "Interest Protection", items: [
    { id: "A_i", label: "Will this data sharing infringe commercial interest(s) of the Business Unit(s)?",
      sub: [{ id: "A_i_1", label: "Loss in revenue due to cannibalization" }, { id: "A_i_2", label: "Damage to relationship with customers" }, { id: "A_i_3", label: "Other commercial interest(s)" }] },
    { id: "A_ii", label: "Are there potentially any commercial secret(s) included in the requested data?",
      sub: [{ id: "A_ii_1", label: "Highly confidential partnerships" }, { id: "A_ii_2", label: "Patent information" }, { id: "A_ii_3", label: "M&A deals" }, { id: "A_ii_4", label: "Other commercial secret(s)" }] },
  ] },
  { section: "B", title: "Customer Data & Insights Sharing Consent", items: [
    { id: "B_i",   label: "Are the data & insights requested sensitive?" },
    { id: "B_ii",  label: "Are there any mitigation steps in place if sensitive data & insights are used?" },
    { id: "B_iii", label: "Are the data & insights requested considered personal data?" },
    { id: "B_iv",  label: "If personal data need to be shared, has written consent for sharing been obtained?" },
    { id: "B_v",   label: "If personal data need to be used for use case development, has written consent for research been obtained?" },
    { id: "B_vi",  label: "Are the data and analytics processes located within the BU's analytics environment with limited access?" },
  ] },
  { section: "C", title: "Regulatory Compliance", items: [
    { id: "C_i", label: "Are there prevailing regulations that will be violated if the data & insights are shared?",
      sub: [{ id: "C_i_1", label: "Industry-specific laws" }, { id: "C_i_2", label: "Data protection laws" }, { id: "C_i_3", label: "Internal regulations and policies" }] },
  ] },
  { section: "D", title: "AI Compliance", aiOnly: true, items: [
    { id: "D_i", label: "Is the data analysis process carried out using artificial intelligence technology?" },
  ] },
];

const AICK_AREAS_DEF: { area: string; items: { id: string; assessment: string; risk_level: "HIGH" | "MEDIUM" | "LOW" }[] }[] = [
  { area: "Before Use", items: [
    { id: "before_use_1", assessment: "The project or product has complied with applicable legal regulations and internal company policies", risk_level: "HIGH" },
    { id: "before_use_2", assessment: "The Gen AI Platform used is properly licensed and has been approved by management", risk_level: "HIGH" },
    { id: "before_use_3", assessment: "Gen-AI usage settings configured to disable interaction history and opt-out from model training by default", risk_level: "MEDIUM" },
  ] },
  { area: "Input", items: [
    { id: "input_1", assessment: "Do not include personal, sensitive, or intellectual property data.", risk_level: "HIGH" },
    { id: "input_2", assessment: "Interactions with Gen-AI should utilize anonymization, pseudonymization, and dummy data.", risk_level: "HIGH" },
    { id: "input_3", assessment: "Prompts must not contain bias or harmful narratives, and should be documented if used for reporting or publication.", risk_level: "LOW" },
  ] },
  { area: "Output", items: [
    { id: "output_1", assessment: "Interactions with Gen-AI must include verification and revalidation of results to ensure validity, including inaccuracies, hallucinations, and bias", risk_level: "MEDIUM" },
    { id: "output_2", assessment: "Any source code generated by Gen-AI must be properly validated before being implemented in Company systems", risk_level: "HIGH" },
  ] },
  { area: "Utilization", items: [
    { id: "utilization_1", assessment: "Outputs should only be used after being reviewed and approved by an authorized user.", risk_level: "MEDIUM" },
    { id: "utilization_2", assessment: "Corrections must be made if AI-generated results are inaccurate or inappropriate before any distribution.", risk_level: "HIGH" },
  ] },
];

const DSR_STEP_LABELS_MAP: Record<number, string> = {
  1: "PIC Data Compliance Approval", 2: "DM Approval", 3: "SME Sign Off", 4: "Client Sign Off",
};

const AICK_STEP_LABELS_MAP: Record<number, string> = {
  1: "PIC Data Compliance Approval", 2: "DM Sign-off", 3: "SME Sign-off",
};

// ── Helper components ─────────────────────────────────────────────────────────

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    yes: "bg-green-100 text-green-700",
    no: "bg-red-100 text-red-700",
    in_progress: "bg-amber-100 text-amber-700",
    na: "bg-surface-100 text-surface-500",
  };
  const labels: Record<string, string> = { yes: "Yes", no: "No", in_progress: "In Progress", na: "N/A" };
  if (!status) return <span className="text-surface-400 text-xs">—</span>;
  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold ${map[status] ?? "bg-surface-100 text-surface-500"}`}>
      {labels[status] ?? status}
    </span>
  );
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(s: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "draft", submitted: "warning", under_review: "in-review",
    approved: "approved", rejected: "rejected", archived: "default",
  };
  return map[s] ?? "default";
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function DPIADetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();

  const [editing, setEditing] = React.useState(false);
  const [form, setForm] = React.useState<Partial<DPIADetail>>({});
  const [selectedCategories, setSelectedCategories] = React.useState<string[]>([]);
  const [govDraft, setGovDraft] = React.useState<GovernanceJson | null>(null);
  const [showProjectModal, setShowProjectModal] = React.useState(false);
  const [showDsrModal, setShowDsrModal] = React.useState(false);
  const [showAickModal, setShowAickModal] = React.useState(false);
  const govContainerRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
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

  const { data: dpia, isLoading } = useQuery<DPIADetail>({
    queryKey: ["dpia", id],
    queryFn: () => api.get<DPIADetail>(`/dpia/${id}`),
    staleTime: 0,
  });

  const { data: project, refetch: refetchProject } = useQuery<ProjectDetail>({
    queryKey: ["project", dpia?.project_id],
    queryFn: () => api.get<ProjectDetail>(`/projects/${dpia!.project_id}`),
    enabled: !!dpia?.project_id,
    staleTime: 0,
  });

  const { data: users = [], refetch: refetchUsers } = useQuery<UserOption[]>({
    queryKey: ["users-options"],
    queryFn: () => api.get<UserOption[]>("/rbac/users/options"),
    staleTime: 0,
  });

  const { data: dsrForDpia } = useQuery({
    queryKey: ["dsr-for-dpia", dpia?.project_id],
    queryFn: async () => {
      const list = await api.get<{ items: { id: string; tracking_id: string; status: string }[] }>(
        `/dsr?project_id=${dpia!.project_id}&page_size=1`
      );
      if (!list.items.length) return null;
      const dsr = list.items[0];
      return api.get<{
        id: string; tracking_id: string; status: string;
        dataset_name: string; purpose: string;
        duration_start: string; duration_end: string; project_end_date: string | null;
        recipient: string; is_ai_use: boolean; is_signed: boolean; signed_at: string | null;
        created_at: string;
        approvals: { id: string; step_order: number; approver_name: string; status: string; actioned_at: string | null }[];
        ai_checklist: { id: string; status: string; validated_at: string | null; checklist_json: Record<string, any>; approvals: { id: string; step_order: number; approver_name: string; status: string; actioned_at: string | null }[] } | null;
      }>(`/dsr/${dsr.id}`);
    },
    enabled: !!dpia?.project_id,
    staleTime: 0,
  });

  function openProjectModal() {
    setShowProjectModal(true);
    refetchProject();
    refetchUsers();
  }

  function resolveUser(uid: string | null) {
    if (!uid) return { name: "—", email: null };
    const u = users.find((x) => x.id === uid);
    return u ? { name: u.full_name, email: u.email } : { name: "—", email: null };
  }

  const saveMutation = useMutation({
    mutationFn: (payload: Record<string, unknown>) =>
      api.put<DPIADetail>(`/dpia/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dpia", id] });
      setEditing(false);
    },
  });


  const currentUser = useAuthStore(s => s.user);

  const submitMutation = useMutation({
    mutationFn: () => api.post(`/dpia/${id}/submit`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dpia", id] }),
    onError: (e: any) => alert(e.message ?? "Failed to submit"),
  });

  const approvalMutation = useMutation({
    mutationFn: ({ step, action, comments }: { step: number; action: string; comments?: string }) =>
      api.post(`/dpia/${id}/approvals/${step}`, { action, comments }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dpia", id] }),
    onError: (e: any) => alert(e.message ?? "Failed to action approval"),
  });

  function startEdit() {
    if (!dpia) return;
    setForm({
      process_name: dpia.process_name,
      risk_description: dpia.risk_description,
      mitigation_measures: dpia.mitigation_measures ?? "",
      residual_risk: dpia.residual_risk ?? "",
    });
    setSelectedCategories((dpia.data_category || "").split(", ").filter(Boolean));
    setGovDraft(dpia.governance_json ? JSON.parse(JSON.stringify(dpia.governance_json)) : null);
    setEditing(true);
  }

  function cancelEdit() { setEditing(false); setForm({}); setSelectedCategories([]); setGovDraft(null); }

  function setF(field: string, value: unknown) {
    setForm((f) => ({ ...f, [field]: value }));
  }

  function updateGovItem(section: keyof GovernanceJson, itemId: string, field: "item" | "responsible" | "status" | "remarks", value: string) {
    setGovDraft((prev) => {
      if (!prev) return prev;
      return {
        ...prev,
        [section]: prev[section].map((item: GovernanceItem) =>
          item.id === itemId ? { ...item, [field]: value } : item
        ),
      };
    });
  }

  function handleSave() {
    const payload: Record<string, unknown> = {
      process_name: form.process_name,
      data_category: selectedCategories.join(", "),
      risk_description: form.risk_description,
      mitigation_measures: form.mitigation_measures || null,
      residual_risk: form.residual_risk || null,
      governance_json: govDraft,
    };
    saveMutation.mutate(payload);
  }

  function handleExportPDF() {
    if (!dpia) return;

    const STEP_LABELS: Record<number, string> = { 1: "PIC Data Compliance Approval", 2: "DM Approval" };

    const sharingEnd = dsrForDpia?.project_end_date ?? dsrForDpia?.duration_end ?? null;
    const aickId = dsrForDpia?.ai_checklist ? dsrForDpia.tracking_id.replace("DSR", "AICK") : null;
    const projectInfoHtml = `<div class="section">
      <div class="section-title">Project Information</div>
      <div class="grid2">
        ${pdfField("Project ID", project?.project_code ?? dpia.project_code)}
        ${pdfField("PII Flag", piiLabel)}
        ${pdfField("DSR ID", dsrForDpia?.tracking_id)}
        ${pdfField("AICK ID", aickId)}
        ${pdfField("Project Name", project?.project_name ?? dpia.project_name)}
        ${pdfField("Customer / Client", project?.customer_name ?? dpia.customer_name)}
        ${pdfField("Sharing Start Date", dsrForDpia?.duration_start ? formatDate(dsrForDpia.duration_start) : null)}
        ${pdfField("Sharing End Date", sharingEnd ? formatDate(sharingEnd) : null)}
      </div>
    </div>`;

    const piiList = piiCats.length > 0
      ? `<ul style="list-style:disc;padding-left:16px;font-size:9pt;color:#1a202c;column-count:2;column-gap:16px">${piiCats.map((c: string) => `<li>${c}</li>`).join("")}</ul>`
      : `<span style="color:#a0aec0">No data categories selected.</span>`;
    const piiBg = hasHighPii ? "background:#FED7D7;color:#742A2A" : hasPii ? "background:#FEFCBF;color:#744210" : "background:#C6F6D5;color:#22543D";
    const dataCatHtml = `<div class="section">
      <div class="section-title">Data Categories Involved</div>
      <div style="margin-bottom:6px"><span style="font-size:8pt;font-weight:600;padding:2px 10px;border-radius:9999px;${piiBg}">${piiLabel}</span></div>
      ${piiList}
    </div>`;

    const regHtml = `<div class="section">
      <div class="section-title">Regulatory References</div>
      <p style="font-size:8pt;color:#718096;margin-bottom:6px">Based on Undang-Undang Pelindungan Data Pribadi (UU PDP) No. 27/2022:</p>
      <table><thead><tr><th>Pasal</th><th>Description</th></tr></thead><tbody>
        ${REGULATORY_REFS.map((r) => `<tr><td style="font-weight:600;color:#1B2A4A;white-space:nowrap">${r.pasal}</td><td>${r.desc}</td></tr>`).join("")}
      </tbody></table>
    </div>`;

    const govTablesHtml = GOVERNANCE_SECTIONS.map(({ key, label, code }) => {
      const items = (dpia.governance_json?.[key] ?? []) as GovernanceItem[];
      const rows = items.map((item) => {
        const statusLabel: Record<string, string> = { yes: "Yes", no: "No", in_progress: "In Progress", na: "N/A", "": "—" };
        const responsible = item.responsible === "Internal" ? "ADI-DI" : (project?.customer_name ?? dpia.customer_name ?? "Client");
        return `<tr><td>${item.item}</td><td>${responsible}</td><td>${statusLabel[item.status] ?? item.status}</td><td>${item.remarks || "—"}</td></tr>`;
      }).join("");
      return `<p style="font-size:9pt;font-weight:600;margin:10px 0 4px">[${code}] ${label}</p>
        <table style="table-layout:fixed;width:100%">
          <colgroup><col style="width:42%"><col style="width:18%"><col style="width:12%"><col style="width:28%"></colgroup>
          <thead><tr><th>Activity</th><th>Responsible</th><th>Status</th><th>Remarks</th></tr></thead>
          <tbody>${rows}</tbody>
        </table>`;
    }).join("");
    const govHtml = `<div class="section"><div class="section-title">Governance Activities</div>${govTablesHtml}</div>`;

    const riskHtml = `<div class="section">
      <div class="section-title">Risk Assessment</div>
      <div class="grid2">${pdfField("Risk Description", dpia.risk_description, true)}</div>
    </div>`;

    const mitigationHtml = `<div class="section">
      <div class="section-title">Mitigation &amp; Residual Risk</div>
      <div class="grid2">
        ${pdfField("Mitigation Measures", dpia.mitigation_measures, true)}
        ${pdfField("Residual Risk Level", dpia.residual_risk)}
      </div>
    </div>`;

    const timelineItems = [...(dpia.approvals ?? [])].sort((a, b) => a.step_order - b.step_order).map((step) => {
      const statusBadge =
        step.status === "approved" ? pdfBadge("Approved", "approved") :
        step.status === "rejected" ? pdfBadge("Rejected", "rejected") :
        pdfBadge(step.status === "pending" ? "Not Yet" : "Requested", "pending");
      const actioned = step.actioned_at
        ? `<div class="tl-meta">${new Date(step.actioned_at).toLocaleString("en-GB", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}</div>`
        : "";
      return `<li><span class="tl-step">${step.step_order}.</span><div>
        <div class="tl-label">${STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}</div>
        <div class="tl-meta">${step.approver_name || "—"}</div>
        <div style="margin-top:2px">${statusBadge}</div>${actioned}
      </div></li>`;
    }).join("");
    const timelineHtml = `<div class="section">
      <div class="section-title">Approval Timeline</div>
      <ul class="timeline">${timelineItems}</ul>
    </div>`;

    const dpiaYear = dpia.tracking_id?.split("-")[1] ?? String(new Date().getFullYear());
    const piiBadgeHtml = hasHighPii
      ? "&nbsp;·&nbsp;" + pdfBadge("High PII Risk", "danger")
      : hasPii
      ? "&nbsp;·&nbsp;" + pdfBadge("Contains PII", "warning")
      : "";

    const body = `
      <h1 class="doc-title">Data Protection Impact Assessment</h1>
      <div class="doc-subtitle">
        ${dpia.tracking_id ?? "DPIA"} &nbsp;·&nbsp; ${dpia.process_name} &nbsp;·&nbsp; ${dpiaYear}
        &nbsp;·&nbsp; ${pdfStatusBadge(dpia.status)}
        ${piiBadgeHtml}
        &nbsp;·&nbsp; v${dpia.version}
      </div>
      ${projectInfoHtml}
      ${dataCatHtml}
      ${timelineHtml}
      ${regHtml}
      ${govHtml}
      ${riskHtml}
      ${mitigationHtml}
    `;
    printA4(`${dpia.tracking_id ?? "DPIA"} — DPIA`, body);
  }

  if (isLoading) return <div className="p-6 text-surface-400">Loading…</div>;
  if (!dpia) return <div className="p-6 text-red-500">DPIA not found</div>;

  const govData = editing ? govDraft : dpia.governance_json;

  const piiCats = (dpia.data_category || "").split(", ").filter(Boolean);
  const sensitiveItems = DATA_CATEGORY_GROUPS.find((g) => g.group === "Special Category (Sensitive)")?.items ?? [];
  const hasHighPii = piiCats.some((c) => sensitiveItems.includes(c));
  const hasPii = piiCats.length > 0;
  const piiLabel = hasHighPii ? "High PII Risk" : hasPii ? "Contains PII" : "No PII Data";
  const piiBadgeCls = hasHighPii
    ? "bg-red-100 text-red-700 border border-red-300"
    : hasPii
    ? "bg-amber-100 text-amber-700 border border-amber-300"
    : "bg-green-100 text-green-700 border border-green-300";
  const piiDotCls = hasHighPii ? "bg-red-500" : hasPii ? "bg-amber-500" : "bg-green-500";

  const dsrCj = dsrForDpia?.ai_checklist?.checklist_json as Record<string, any> | undefined;
  const dsrSignOff = dsrCj?.sign_off as Record<string, string> | undefined;
  const aickRaw = dsrCj?.ai_assessment as Record<string, any> | undefined;
  const aickItems = (aickRaw?.items ?? {}) as Record<string, { status: string | null; remarks: string }>;
  const aickSignOff = aickRaw?.sign_off as Record<string, string> | undefined;
  const aickApprovals = (dsrForDpia?.ai_checklist?.approvals ?? []) as { id: string; step_order: number; approver_name: string; status: string; actioned_at: string | null }[];
  const dsrApprovals = (dsrForDpia?.approvals ?? []) as { id: string; step_order: number; approver_name: string; status: string; actioned_at: string | null }[];

  return (
    <div className="p-6 space-y-5">
      {/* Header */}
      <div className="flex items-start gap-3 mb-6">
        <button onClick={() => router.back()}
          className="inline-flex items-center justify-center h-9 w-9 rounded-md hover:bg-surface-100 shrink-0 mt-0.5">
          <ArrowLeft size={18} />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono font-bold text-surface-800 text-lg">{dpia.tracking_id ?? "DPIA"}</span>
                <Badge variant={statusVariant(dpia.status)}>
                  {dpia.status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
                </Badge>
                <span className="text-xs text-surface-400">v{dpia.version}</span>
              </div>
              <h1 className="mt-0.5 truncate">{dpia.process_name}</h1>
              <p className="text-sm text-surface-500">Data Protection Impact Assessment</p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <Button variant="outline" size="sm" onClick={handleExportPDF}>
                <Download size={14} className="mr-1.5" />Export PDF
              </Button>
              {dpia.status === "draft" && (
                editing ? (
                  <>
                    <Button variant="outline" size="sm" onClick={cancelEdit}>
                      <X size={14} className="mr-1.5" />Cancel
                    </Button>
                    <Button size="sm" onClick={handleSave} disabled={saveMutation.isPending}>
                      <Save size={14} className="mr-1.5" />{saveMutation.isPending ? "Saving…" : "Save"}
                    </Button>
                  </>
                ) : (
                  <>
                    <Button variant="outline" size="sm" onClick={startEdit}>
                      <Pencil size={14} className="mr-1.5" />Edit
                    </Button>
                    <Button size="sm" onClick={() => submitMutation.mutate()} disabled={submitMutation.isPending}>
                      <Send size={14} className="mr-1.5" />{submitMutation.isPending ? "Submitting…" : "Submit"}
                    </Button>
                  </>
                )
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Amber banner when draft */}
      {dpia.status === "draft" && !editing && (
        <div className="mb-4 px-4 py-3 rounded-md bg-amber-50 border border-amber-200 text-sm text-amber-800">
          This DPIA is in draft. Complete the details below and submit for approval when ready.
        </div>
      )}

      {/* Project Information */}
      <Card>
        <CardHeader><CardTitle>Project Information</CardTitle></CardHeader>
        <CardContent>
          {!editing ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Project ID</p>
                <button onClick={openProjectModal}
                  className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                  {project?.project_code ?? dpia.project_code ?? dpia.project_id.slice(0, 8)}
                </button>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-1">PII Flag</p>
                <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold ${piiBadgeCls}`}>
                  <span className={`w-1.5 h-1.5 rounded-full ${piiDotCls}`} />
                  {piiLabel}
                </span>
                {piiCats.length > 0 && (
                  <p className="text-[11px] text-surface-400 mt-1">{piiCats.length} categor{piiCats.length === 1 ? "y" : "ies"} selected</p>
                )}
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">DSR ID</p>
                {dsrForDpia ? (
                  <button onClick={() => setShowDsrModal(true)}
                    className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                    {dsrForDpia.tracking_id}
                  </button>
                ) : (
                  <span className="font-mono text-surface-400">—</span>
                )}
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">AICK ID</p>
                {dsrForDpia?.ai_checklist ? (
                  <button onClick={() => setShowAickModal(true)}
                    className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                    {dsrForDpia.tracking_id.replace("DSR", "AICK")}
                  </button>
                ) : (
                  <span className="font-mono text-surface-400">—</span>
                )}
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Project Name</p>
                <p className="font-medium">{project?.project_name ?? dpia.project_name ?? "—"}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Customer / Client</p>
                <p className="font-medium">{project?.customer_name ?? dpia.customer_name ?? "—"}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p>
                <p className="font-medium">{dsrForDpia?.duration_start ? formatDate(dsrForDpia.duration_start) : "—"}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p>
                <p className="font-medium">
                  {dsrForDpia?.project_end_date
                    ? formatDate(dsrForDpia.project_end_date)
                    : dsrForDpia?.duration_end
                    ? formatDate(dsrForDpia.duration_end)
                    : "—"}
                </p>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              {/* Row 1: Project ID | PII Flag */}
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Project ID</p>
                <p className="font-mono font-medium text-surface-700">{project?.project_code ?? dpia.project_code ?? "—"}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-1">PII Flag</p>
                <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold ${piiBadgeCls}`}>
                  <span className={`w-1.5 h-1.5 rounded-full ${piiDotCls}`} />
                  {piiLabel}
                </span>
                {piiCats.length > 0 && (
                  <p className="text-[11px] text-surface-400 mt-1">{piiCats.length} categor{piiCats.length === 1 ? "y" : "ies"} selected</p>
                )}
              </div>
              {/* Row 2: DSR ID | AICK ID */}
              <div>
                <p className="text-xs text-surface-400 mb-0.5">DSR ID</p>
                {dsrForDpia ? (
                  <button onClick={() => setShowDsrModal(true)}
                    className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                    {dsrForDpia.tracking_id}
                  </button>
                ) : (
                  <span className="font-mono text-surface-400">—</span>
                )}
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">AICK ID</p>
                {dsrForDpia?.ai_checklist ? (
                  <button onClick={() => setShowAickModal(true)}
                    className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                    {dsrForDpia.tracking_id.replace("DSR", "AICK")}
                  </button>
                ) : (
                  <span className="font-mono text-surface-400">—</span>
                )}
              </div>
              {/* Row 3: Project Name | Customer/Client */}
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Project Name</p>
                <p className="font-medium">{project?.project_name ?? dpia.project_name ?? "—"}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Customer / Client</p>
                <p className="font-medium">{project?.customer_name ?? dpia.customer_name ?? "—"}</p>
              </div>
              {/* Row 4: Sharing Start | Sharing End */}
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p>
                <p className="font-medium">{dsrForDpia?.duration_start ? formatDate(dsrForDpia.duration_start) : "—"}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p>
                <p className="font-medium">
                  {dsrForDpia?.project_end_date
                    ? formatDate(dsrForDpia.project_end_date)
                    : dsrForDpia?.duration_end
                    ? formatDate(dsrForDpia.duration_end)
                    : "—"}
                </p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Data Categories Involved */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-2">
            <CardTitle>Data Categories Involved</CardTitle>
            {!editing && piiCats.length > 0 && (
              <span className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold ${piiBadgeCls}`}>
                <span className={`w-1.5 h-1.5 rounded-full ${piiDotCls}`} />
                {piiLabel} · {piiCats.length} categor{piiCats.length === 1 ? "y" : "ies"}
              </span>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {editing ? (
            <>
              <div className="grid grid-cols-5 gap-2">
                {DATA_CATEGORY_GROUPS.map(({ group, items }) => (
                  <div key={group} className="rounded-lg border border-surface-200 bg-surface-50 px-3 py-2.5">
                    <p className="text-[10px] font-semibold text-surface-400 uppercase tracking-wide mb-1.5">{group}</p>
                    <div className="flex flex-wrap gap-1">
                      {items.map((item) => {
                        const sel = selectedCategories.includes(item);
                        return (
                          <button key={item} type="button"
                            onClick={() => setSelectedCategories((prev) => sel ? prev.filter((c) => c !== item) : [...prev, item])}
                            className={`px-1.5 py-0.5 rounded-full text-[11px] font-medium border transition-all ${sel ? "bg-primary-600 border-primary-600 text-white" : "bg-white border-surface-200 text-surface-600 hover:border-primary-400 hover:text-primary-600"}`}>
                            {sel && "✓ "}{item}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
              {selectedCategories.length > 0 && (
                <p className="text-xs text-primary-600 mt-3 font-medium">
                  {selectedCategories.length} categor{selectedCategories.length === 1 ? "y" : "ies"} selected
                  <button type="button" onClick={() => setSelectedCategories([])} className="ml-2 text-surface-400 hover:text-red-500 font-normal">Clear all</button>
                </p>
              )}
            </>
          ) : piiCats.length > 0 ? (
            <div className="grid grid-cols-5 gap-2">
              {DATA_CATEGORY_GROUPS.filter((g) => g.items.some((i) => piiCats.includes(i))).map(({ group, items }) => (
                <div key={group} className="rounded-lg border border-surface-200 bg-surface-50 px-3 py-2.5">
                  <p className="text-[10px] font-semibold text-surface-400 uppercase tracking-wide mb-1.5">{group}</p>
                  <div className="flex flex-wrap gap-1">
                    {items.filter((i) => piiCats.includes(i)).map((item) => (
                      <span key={item} className="px-1.5 py-0.5 rounded-full text-[11px] font-medium border bg-primary-600 border-primary-600 text-white">
                        {item}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-surface-400 italic">No data categories selected.</p>
          )}
        </CardContent>
      </Card>

      {/* Approval Timeline */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between flex-wrap gap-2">
            <CardTitle>Approval Timeline</CardTitle>
            <Badge variant={
              dpia.status === "approved" ? "approved" :
              dpia.status === "rejected" ? "rejected" :
              dpia.status === "submitted" || dpia.status === "under_review" ? "warning" : "draft"
            }>
              {dpia.status === "approved" ? "Approved" :
               dpia.status === "rejected" ? "Rejected" :
               dpia.status === "submitted" ? "Submitted" :
               dpia.status === "under_review" ? "Under Review" : "Draft"}
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <ol className="relative border-l border-surface-200 space-y-5 ml-3">
            {[...(dpia.approvals ?? [])].sort((a, b) => a.step_order - b.step_order).map((step) => {
              const STEP_LABELS: Record<number, string> = { 1: "PIC Data Compliance Approval", 2: "DM Approval" };
              const isActive = step.status === "requested";
              const canAction = isActive && currentUser?.id === step.approver_id;
              return (
                <li key={step.id} className="ml-4">
                  <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                    step.status === "approved"  ? "bg-green-500" :
                    step.status === "rejected"  ? "bg-red-500" :
                    step.status === "requested" ? "bg-primary-500" :
                    "bg-surface-300"
                  }`} />
                  <p className={`text-sm font-semibold ${step.status === "pending" ? "text-surface-400" : "text-surface-800"}`}>
                    {STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
                  </p>
                  {step.approver_name && (
                    <p className={`text-xs ${step.status === "pending" ? "text-surface-400" : "text-surface-500"}`}>
                      {step.approver_name}
                    </p>
                  )}
                  <Badge
                    variant={step.status === "approved" ? "approved" : step.status === "rejected" ? "rejected" : "draft"}
                    className="mt-1 text-xs">
                    {step.status === "approved" ? "Approved" :
                     step.status === "rejected"  ? "Rejected" :
                     step.status === "pending"   ? "Not Yet" : "Requested"}
                  </Badge>
                  {step.actioned_at && (
                    <p className="text-xs text-surface-400 mt-0.5">{new Date(step.actioned_at).toLocaleString("en-GB", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}</p>
                  )}
                  {canAction && (
                    <div className="flex items-center gap-2 mt-2">
                      <Button size="sm" variant="default"
                        onClick={() => approvalMutation.mutate({ step: step.step_order, action: "approve" })}
                        disabled={approvalMutation.isPending}>
                        Approve
                      </Button>
                      <Button size="sm" variant="outline"
                        onClick={() => approvalMutation.mutate({ step: step.step_order, action: "reject" })}
                        disabled={approvalMutation.isPending}
                        className="text-red-600 border-red-300 hover:bg-red-50">
                        Reject
                      </Button>
                    </div>
                  )}
                </li>
              );
            })}
          </ol>
        </CardContent>
      </Card>

      {/* Regulatory References */}
      <Card>
        <CardHeader><CardTitle>Regulatory References</CardTitle></CardHeader>
        <CardContent>
          <p className="text-xs text-surface-500 mb-3">
            Based on Undang-Undang Pelindungan Data Pribadi (UU PDP) No. 27/2022:
          </p>
          <ol className="space-y-2">
            {REGULATORY_REFS.map((ref, idx) => (
              <li key={idx} className="flex gap-3 text-sm">
                <span className="font-semibold text-primary-700 min-w-[80px]">{ref.pasal}</span>
                <span className="text-surface-600">{ref.desc}</span>
              </li>
            ))}
          </ol>
        </CardContent>
      </Card>

      {/* Governance Activities */}
      <Card>
        <CardHeader><CardTitle>Governance Activities</CardTitle></CardHeader>
        <CardContent className="space-y-6">
          <div ref={govContainerRef}>
          {GOVERNANCE_SECTIONS.map(({ key, label, code }) => {
            const items = (govData?.[key] ?? []) as GovernanceItem[];
            return (
              <div key={key}>
                <p className="text-sm font-semibold text-surface-700 mb-2 flex items-center gap-2">
                  <span className="inline-flex items-center justify-center w-5 h-5 rounded-full bg-primary-100 text-primary-700 text-xs font-bold">{code}</span>
                  {label}
                </p>
                <div className="overflow-x-auto">
                  <table className="w-full text-sm border border-surface-200 rounded-lg overflow-hidden">
                    <thead className="bg-surface-50">
                      <tr>
                        <th className="px-3 py-2 text-left text-xs font-semibold text-surface-500 w-1/2">Activity</th>
                        <th className="px-3 py-2 text-left text-xs font-semibold text-surface-500 w-40">Responsible</th>
                        <th className="px-3 py-2 text-left text-xs font-semibold text-surface-500 w-32">Status</th>
                        <th className="px-3 py-2 text-left text-xs font-semibold text-surface-500">Remarks</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-surface-100">
                      {items.map((item) => (
                        <tr key={item.id} className="hover:bg-surface-50">
                          <td className="px-3 py-2.5 text-surface-700 leading-snug">
                            {item.item}
                          </td>
                          <td className="px-3 py-2.5">
                            {editing ? (
                              <div className={`flex items-stretch rounded-md border overflow-hidden transition-opacity ${
                                item.status === "no" ? "opacity-40 pointer-events-none border-surface-100" : "border-surface-200"
                              }`}>
                                <button type="button"
                                  onClick={() => updateGovItem(key, item.id, "responsible", "Internal")}
                                  className={`px-2 py-1 text-xs font-medium text-center transition-colors ${
                                    item.responsible === "Internal" ? "bg-blue-600 text-white" : "bg-white text-surface-500 hover:bg-surface-50"
                                  }`}>
                                  ADI-DI
                                </button>
                                <button type="button"
                                  onClick={() => updateGovItem(key, item.id, "responsible", "Client")}
                                  className={`px-2 py-1 text-xs font-medium text-center transition-colors border-l border-surface-200 ${
                                    item.responsible === "Client" ? "bg-purple-600 text-white" : "bg-white text-surface-500 hover:bg-surface-50"
                                  }`}>
                                  {project?.customer_name ?? dpia.customer_name ?? "Client"}
                                </button>
                              </div>
                            ) : (
                              <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium whitespace-nowrap ${
                                item.status === "no"
                                  ? "opacity-40 bg-surface-100 text-surface-400"
                                  : item.responsible === "Internal"
                                  ? "bg-blue-50 text-blue-700"
                                  : "bg-purple-50 text-purple-700"
                              }`}>
                                {item.status === "no" ? "N/A" : item.responsible === "Internal" ? "ADI-DI" : (project?.customer_name ?? dpia.customer_name ?? "Client")}
                              </span>
                            )}
                          </td>
                          <td className="px-3 py-2.5">
                            {editing ? (
                              <select
                                value={item.status}
                                onChange={(e) => updateGovItem(key, item.id, "status", e.target.value)}
                                className="border border-surface-200 rounded px-2 py-1 text-xs w-full focus:outline-none focus:ring-1 focus:ring-primary-500">
                                <option value="">—</option>
                                <option value="yes">Yes</option>
                                <option value="no">No</option>
                              </select>
                            ) : (
                              <StatusBadge status={item.status} />
                            )}
                          </td>
                          <td className="px-3 py-2.5">
                            {editing ? (
                              <textarea
                                value={item.remarks}
                                rows={1}
                                onChange={(e) => {
                                  updateGovItem(key, item.id, "remarks", e.target.value);
                                  e.target.style.height = "auto";
                                  e.target.style.height = e.target.scrollHeight + "px";
                                }}
                                ref={(el) => { if (el) { requestAnimationFrame(() => { el.style.height = "auto"; el.style.height = el.scrollHeight + "px"; }); } }}
                                placeholder="Add remarks…"
                                className="border border-surface-200 rounded px-2 py-1 text-xs w-full focus:outline-none focus:ring-1 focus:ring-primary-500 resize-none overflow-hidden" />
                            ) : (
                              <span className="text-surface-500 text-xs whitespace-pre-wrap">{item.remarks || "—"}</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            );
          })}
          </div>
        </CardContent>
      </Card>

      {/* Risk Assessment */}
      <Card>
        <CardHeader><CardTitle>Risk Assessment</CardTitle></CardHeader>
        <CardContent className="text-sm">
          {editing ? (
            <>
              <label className="block text-sm font-medium text-surface-700 mb-1">Risk Description</label>
              <p className="text-xs text-surface-400 mb-1.5">
                Identify the privacy risk and potential impact on data subjects if it materialises.<br />
                <span className="text-surface-500 italic">
                  e.g. &quot;Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm.&quot;
                </span>
              </p>
              <textarea value={form.risk_description as string} rows={5}
                onChange={(e) => setF("risk_description", e.target.value)}
                className="w-full border border-surface-200 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none"
                placeholder="Describe the privacy risk and potential harm to data subjects…" />
            </>
          ) : (
            <div>
              <p className="text-xs text-surface-400 mb-1">Risk Description</p>
              <p className="text-surface-700 leading-relaxed">{dpia.risk_description || "—"}</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Mitigation & Residual Risk */}
      <Card>
        <CardHeader><CardTitle>Mitigation &amp; Residual Risk</CardTitle></CardHeader>
        <CardContent className="space-y-5 text-sm">
          <div>
            {editing ? (
              <>
                <label className="block text-sm font-medium text-surface-700 mb-1">Mitigation Measures</label>
                <p className="text-xs text-surface-400 mb-1.5">
                  Describe controls and safeguards in place to reduce the risk.<br />
                  <span className="text-surface-500 italic">
                    e.g. &quot;Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable.&quot;
                  </span>
                </p>
                <textarea value={form.mitigation_measures as string} rows={4}
                  onChange={(e) => setF("mitigation_measures", e.target.value)}
                  className="w-full border border-surface-200 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 resize-none"
                  placeholder="Describe controls and safeguards in place…" />
              </>
            ) : (
              <>
                <p className="text-xs text-surface-400 mb-1">Mitigation Measures</p>
                <p className="text-surface-700 leading-relaxed">{dpia.mitigation_measures || "—"}</p>
              </>
            )}
          </div>
          <div>
            {editing ? (
              <>
                <label className="block text-sm font-medium text-surface-700 mb-1">Residual Risk Level</label>
                <p className="text-xs text-surface-400 mb-2">
                  Level of risk remaining <span className="font-medium text-surface-600">after</span> mitigations are applied.
                </p>
                <div className="grid grid-cols-2 gap-2">
                  {([
                    { level: "Low",      idle: "border-green-200 bg-green-50 hover:bg-green-100",    active: "border-green-500 bg-green-100 ring-2 ring-green-400",    dot: "bg-green-500",  text: "text-green-800",  desc: "Well-controlled. Acceptable with current safeguards." },
                    { level: "Medium",   idle: "border-amber-200 bg-amber-50 hover:bg-amber-100",    active: "border-amber-500 bg-amber-100 ring-2 ring-amber-400",    dot: "bg-amber-500",  text: "text-amber-800",  desc: "Some risk remains. Additional monitoring may be needed." },
                    { level: "High",     idle: "border-orange-200 bg-orange-50 hover:bg-orange-100", active: "border-orange-500 bg-orange-100 ring-2 ring-orange-400", dot: "bg-orange-500", text: "text-orange-800", desc: "Significant risk. Immediate action or escalation recommended." },
                    { level: "Critical", idle: "border-red-200 bg-red-50 hover:bg-red-100",          active: "border-red-500 bg-red-100 ring-2 ring-red-400",          dot: "bg-red-500",    text: "text-red-800",    desc: "Unacceptable. Do not proceed without executive sign-off." },
                  ] as { level: string; idle: string; active: string; dot: string; text: string; desc: string }[]).map(({ level, idle, active, dot, text, desc }) => {
                    const selected = (form.residual_risk as string) === level;
                    return (
                      <button key={level} type="button"
                        onClick={() => setF("residual_risk", selected ? "" : level)}
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
              </>
            ) : (
              <>
                <p className="text-xs text-surface-400 mb-1">Residual Risk</p>
                {dpia.residual_risk && RESIDUAL_RISK_META[dpia.residual_risk] ? (
                  <div className={`inline-flex items-start gap-2 rounded-lg border-2 px-2.5 py-2 ${RESIDUAL_RISK_META[dpia.residual_risk].border} ${RESIDUAL_RISK_META[dpia.residual_risk].bg}`}>
                    <span className={`mt-0.5 w-2 h-2 rounded-full shrink-0 ${RESIDUAL_RISK_META[dpia.residual_risk].dot}`} />
                    <div className={RESIDUAL_RISK_META[dpia.residual_risk].text}>
                      <p className="text-xs font-bold">{dpia.residual_risk}</p>
                      <p className="text-[11px] leading-snug opacity-75 mt-0.5">{RESIDUAL_RISK_META[dpia.residual_risk].desc}</p>
                    </div>
                  </div>
                ) : <span className="text-surface-400">—</span>}
              </>
            )}
          </div>
        </CardContent>
      </Card>

      {/* DSR Detail Modal */}
      {showDsrModal && dsrForDpia && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowDsrModal(false)} />
          <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
              <div>
                <p className="text-xs text-surface-400 font-mono">{dsrForDpia.tracking_id}</p>
                <h2 className="text-base font-semibold text-surface-900">{dpia.project_name ?? project?.project_name}</h2>
              </div>
              <button onClick={() => setShowDsrModal(false)} className="h-8 w-8 flex items-center justify-center rounded-md hover:bg-surface-100 text-surface-500">✕</button>
            </div>
            <div className="px-6 py-5 space-y-6 text-sm">
              <div>
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Request Details</p>
                <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                  <div><p className="text-xs text-surface-400 mb-0.5">Project ID</p><p className="font-mono font-medium">{dpia.project_code ?? project?.project_code ?? "—"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Status</p><p className="font-medium capitalize">{dsrForDpia.status.replace(/_/g, " ")}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Customer / Client</p><p className="font-medium">{dsrForDpia.recipient}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">AI / ML Use</p><p className="font-medium">{dsrForDpia.is_ai_use ? "Yes" : "No"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p><p className="font-medium">{dsrForDpia.duration_start ? formatDate(dsrForDpia.duration_start) : "—"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p><p className="font-medium">{dsrForDpia.project_end_date ? formatDate(dsrForDpia.project_end_date) : dsrForDpia.duration_end ? formatDate(dsrForDpia.duration_end) : "—"}</p></div>
                  {dsrForDpia.purpose && (
                    <div className="col-span-2"><p className="text-xs text-surface-400 mb-0.5">Purpose / Justification</p><p className="text-surface-700 leading-relaxed">{dsrForDpia.purpose}</p></div>
                  )}
                </div>
              </div>
              <div>
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">DSR Approval Timeline</p>
                <ol className="relative border-l border-surface-200 space-y-5 ml-3">
                  {[...dsrApprovals].sort((a, b) => a.step_order - b.step_order).map((step) => (
                    <li key={step.id} className="ml-4">
                      <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                        step.status === "approved" ? "bg-green-500" : step.status === "rejected" ? "bg-red-500" : "bg-surface-300"
                      }`} />
                      <p className="text-sm font-medium text-surface-800">{DSR_STEP_LABELS_MAP[step.step_order] ?? `Step ${step.step_order}`}</p>
                      <p className="text-xs text-surface-500">{step.approver_name || "Not yet actioned"}</p>
                      <span className={`inline-block mt-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                        step.status === "approved" ? "bg-green-100 text-green-700" :
                        step.status === "rejected" ? "bg-red-100 text-red-700" : "bg-surface-100 text-surface-500"
                      }`}>
                        {step.status === "approved" ? "Approved" : step.status === "rejected" ? "Rejected" : "Requested"}
                      </span>
                      {step.actioned_at && (
                        <p className="text-xs text-surface-400 mt-0.5">{new Date(step.actioned_at).toLocaleString()}</p>
                      )}
                    </li>
                  ))}
                </ol>
              </div>
              {dsrCj && (
                <>
                  <div>
                    <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Data &amp; Insights Sharing Evaluation Checklist</p>
                    <div className="space-y-3">
                      {DSR_CHECKLIST_SECTIONS.filter((s) => !s.aiOnly || dsrForDpia.is_ai_use).map((sec) => (
                        <div key={sec.section}>
                          <p className="text-xs font-semibold text-surface-700 bg-surface-100 px-2 py-1.5 rounded-t border border-surface-200">
                            {sec.section}. {sec.title}
                          </p>
                          <div className="border border-t-0 border-surface-200 rounded-b divide-y divide-surface-100">
                            {sec.items.map((item) => {
                              const rows = item.sub
                                ? item.sub.map((s) => ({ id: s.id, label: s.label, val: (dsrCj[s.id] ?? {}) as { answer?: string; remarks?: string } }))
                                : [{ id: item.id, label: item.label, val: (dsrCj[item.id] ?? {}) as { answer?: string; remarks?: string } }];
                              return (
                                <div key={item.id} className="px-3 py-2 space-y-1.5">
                                  {item.sub && <p className="text-xs font-medium text-surface-600">{item.label}</p>}
                                  {rows.map((r) => (
                                    <div key={r.id} className={`flex items-start gap-2 ${item.sub ? "pl-2 border-l-2 border-surface-200" : ""}`}>
                                      <span className={`shrink-0 inline-block px-2 py-0.5 rounded text-xs font-semibold mt-0.5 ${
                                        r.val.answer === "Yes" ? "bg-green-100 text-green-700" :
                                        r.val.answer === "No"  ? "bg-red-100 text-red-700" :
                                        "bg-surface-100 text-surface-400"
                                      }`}>{r.val.answer || "—"}</span>
                                      <div>
                                        <p className="text-xs text-surface-600">{r.label}</p>
                                        {r.val.remarks && <p className="text-xs text-surface-400 italic mt-0.5">{r.val.remarks}</p>}
                                      </div>
                                    </div>
                                  ))}
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                  {dsrSignOff && (
                    <div>
                      <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Sign Off</p>
                      <div className="space-y-3">
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-surface-500 w-24 shrink-0">Approved?</span>
                          <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${
                            dsrSignOff.approved === "Yes" ? "bg-green-100 text-green-700" :
                            dsrSignOff.approved === "No"  ? "bg-red-100 text-red-700" : "bg-surface-100 text-surface-400"
                          }`}>{dsrSignOff.approved || "—"}</span>
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                          <div className="space-y-1">
                            <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Prepared By</p>
                            <p className="font-medium text-sm">{dsrSignOff.prepared_by || "—"}</p>
                            <p className="text-xs text-surface-400">{dsrSignOff.prepared_position || ""}</p>
                            {dsrSignOff.prepared_signature
                              ? <img src={dsrSignOff.prepared_signature} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                              : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                            {dsrSignOff.prepared_date && <p className="text-xs text-surface-400">Signed: {dsrSignOff.prepared_date}</p>}
                          </div>
                          <div className="space-y-1">
                            <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Acknowledged By</p>
                            <p className="font-medium text-sm">{dsrSignOff.acknowledged_by || "—"}</p>
                            <p className="text-xs text-surface-400">{dsrSignOff.acknowledged_position || ""}</p>
                            {dsrSignOff.acknowledged_signature
                              ? <img src={dsrSignOff.acknowledged_signature} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                              : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                            {dsrSignOff.acknowledged_date && <p className="text-xs text-surface-400">Signed: {dsrSignOff.acknowledged_date}</p>}
                          </div>
                        </div>
                        {dsrSignOff.remarks && (
                          <div><p className="text-xs text-surface-500 mb-0.5">Remarks</p><p className="text-xs text-surface-700 italic">{dsrSignOff.remarks}</p></div>
                        )}
                      </div>
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* AICK Detail Modal */}
      {showAickModal && dsrForDpia?.ai_checklist && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowAickModal(false)} />
          <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
              <div>
                <p className="text-xs text-surface-400 font-mono">{dsrForDpia.tracking_id.replace("DSR", "AICK")}</p>
                <h2 className="text-base font-semibold text-surface-900">{dpia.project_name ?? project?.project_name}</h2>
              </div>
              <button onClick={() => setShowAickModal(false)} className="h-8 w-8 flex items-center justify-center rounded-md hover:bg-surface-100 text-surface-500">✕</button>
            </div>
            <div className="px-6 py-5 space-y-6 text-sm">
              <div>
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Assessment Information</p>
                <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                  <div><p className="text-xs text-surface-400 mb-0.5">Project ID</p><p className="font-mono font-medium">{dpia.project_code ?? project?.project_code ?? "—"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Status</p><p className="font-medium capitalize">{dsrForDpia.ai_checklist.status.replace(/_/g, " ")}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Customer / Client</p><p className="font-medium">{dsrForDpia.recipient}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">AI / ML Use</p><p className="font-medium">{dsrForDpia.is_ai_use ? "Yes" : "No"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p><p className="font-medium">{dsrForDpia.duration_start ? formatDate(dsrForDpia.duration_start) : "—"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p><p className="font-medium">{dsrForDpia.project_end_date ? formatDate(dsrForDpia.project_end_date) : dsrForDpia.duration_end ? formatDate(dsrForDpia.duration_end) : "—"}</p></div>
                </div>
              </div>
              {aickApprovals.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Approval Timeline</p>
                  <ol className="relative border-l border-surface-200 space-y-5 ml-3">
                    {[...aickApprovals].sort((a, b) => a.step_order - b.step_order).map((step) => (
                      <li key={step.id} className="ml-4">
                        <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                          step.status === "approved" ? "bg-green-500" : step.status === "rejected" ? "bg-red-500" : "bg-surface-300"
                        }`} />
                        <p className={`text-sm font-medium ${step.status === "pending" ? "text-surface-400" : "text-surface-800"}`}>{AICK_STEP_LABELS_MAP[step.step_order] ?? `Step ${step.step_order}`}</p>
                        {step.approver_name && <p className={`text-xs ${step.status === "pending" ? "text-surface-400" : "text-surface-500"}`}>{step.approver_name}</p>}
                        <span className={`inline-block mt-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                          step.status === "approved" ? "bg-green-100 text-green-700" :
                          step.status === "rejected" ? "bg-red-100 text-red-700" : "bg-surface-100 text-surface-500"
                        }`}>
                          {step.status === "approved" ? "Approved" : step.status === "rejected" ? "Rejected" : step.status === "pending" ? "Not Yet" : "Requested"}
                        </span>
                        {step.actioned_at && (
                          <p className="text-xs text-surface-400 mt-0.5">{new Date(step.actioned_at).toLocaleString()}</p>
                        )}
                      </li>
                    ))}
                  </ol>
                </div>
              )}
              <div>
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">GEN AI Protection Checklist</p>
                <div className="hidden md:grid grid-cols-[3fr_64px_80px_1.5fr] gap-2 bg-surface-50 border border-surface-200 rounded-t px-3 py-2">
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Assessment</p>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide text-center">Risk</p>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide text-center">Status</p>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Remarks</p>
                </div>
                {AICK_AREAS_DEF.map((areaGroup) => (
                  <div key={areaGroup.area}>
                    <div className="bg-surface-100 px-3 py-1.5 border border-t-0 border-surface-200">
                      <span className="text-xs font-semibold text-surface-700">{areaGroup.area}</span>
                    </div>
                    {areaGroup.items.map((item) => {
                      const state = aickItems[item.id];
                      return (
                        <div key={item.id} className="px-3 py-2 border border-t-0 border-surface-200 md:grid grid-cols-[3fr_64px_80px_1.5fr] gap-2 items-start">
                          <p className="text-xs text-surface-700 leading-snug mb-1 md:mb-0">{item.assessment}</p>
                          <div className="flex md:justify-center mb-1 md:mb-0">
                            <span className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-semibold ${item.risk_level === "HIGH" ? "bg-red-100 text-red-700" : item.risk_level === "MEDIUM" ? "bg-amber-100 text-amber-700" : "bg-green-100 text-green-700"}`}>{item.risk_level}</span>
                          </div>
                          <div className="flex md:justify-center mb-1 md:mb-0">
                            <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${state?.status === "Yes" ? "bg-green-100 text-green-700" : state?.status === "No" ? "bg-red-100 text-red-700" : "bg-surface-100 text-surface-400"}`}>{state?.status || "—"}</span>
                          </div>
                          <p className="text-xs text-surface-400 italic">{state?.remarks || "—"}</p>
                        </div>
                      );
                    })}
                  </div>
                ))}
              </div>
              {aickSignOff && (
                <div>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Sign Off</p>
                  <div className="space-y-3">
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-surface-500 w-24 shrink-0">Approved?</span>
                      <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${
                        aickSignOff.approved === "Yes" ? "bg-green-100 text-green-700" :
                        aickSignOff.approved === "No"  ? "bg-red-100 text-red-700" : "bg-surface-100 text-surface-400"
                      }`}>{aickSignOff.approved || "—"}</span>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-1">
                        <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Prepared By</p>
                        <p className="font-medium text-sm">{aickSignOff.prepared_by || "—"}</p>
                        <p className="text-xs text-surface-400">{aickSignOff.prepared_position || ""}</p>
                        {aickSignOff.prepared_signature
                          ? <img src={aickSignOff.prepared_signature} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                          : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                        {aickSignOff.prepared_date && <p className="text-xs text-surface-400">Signed: {aickSignOff.prepared_date}</p>}
                      </div>
                      <div className="space-y-1">
                        <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Acknowledged By</p>
                        <p className="font-medium text-sm">{aickSignOff.acknowledged_by || "—"}</p>
                        <p className="text-xs text-surface-400">{aickSignOff.acknowledged_position || ""}</p>
                        {aickSignOff.acknowledged_signature
                          ? <img src={aickSignOff.acknowledged_signature} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                          : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                        {aickSignOff.acknowledged_date && <p className="text-xs text-surface-400">Signed: {aickSignOff.acknowledged_date}</p>}
                      </div>
                    </div>
                    {aickSignOff.remarks && (
                      <div><p className="text-xs text-surface-500 mb-0.5">Remarks</p><p className="text-xs text-surface-700 italic">{aickSignOff.remarks}</p></div>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Project Detail Modal */}
      {showProjectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowProjectModal(false)} />
          <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
              <div>
                <p className="text-xs text-surface-400 font-mono">{project?.project_code ?? dpia.project_code}</p>
                <h2 className="text-base font-semibold text-surface-900">{project?.project_name ?? dpia.project_name}</h2>
              </div>
              <button onClick={() => setShowProjectModal(false)}
                className="h-8 w-8 flex items-center justify-center rounded-md hover:bg-surface-100 text-surface-500">✕</button>
            </div>
            {!project ? (
              <p className="text-sm text-surface-400 text-center py-10">Loading…</p>
            ) : (
              <div className="px-6 py-5 space-y-6 text-sm">
                <div>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Project Information</p>
                  <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                    <div><p className="text-xs text-surface-400 mb-0.5">Customer / Client</p><p className="font-medium">{project.customer_name}</p></div>
                    <div><p className="text-xs text-surface-400 mb-0.5">Category</p><p className="font-medium">{project.project_category}</p></div>
                    <div><p className="text-xs text-surface-400 mb-0.5">Line of Business</p><p className="font-medium">{project.line_of_business ?? "—"}</p></div>
                    <div><p className="text-xs text-surface-400 mb-0.5">Year</p><p className="font-medium">{project.project_year}</p></div>
                    <div><p className="text-xs text-surface-400 mb-0.5">Start Date</p><p className="font-medium">{project.start_date ? formatDate(project.start_date) : "—"}</p></div>
                    <div><p className="text-xs text-surface-400 mb-0.5">End Date</p><p className="font-medium">{project.end_date ? formatDate(project.end_date) : "—"}</p></div>
                    {project.use_case && (
                      <div className="col-span-2"><p className="text-xs text-surface-400 mb-0.5">Use Case</p><p className="text-surface-700 leading-relaxed">{project.use_case}</p></div>
                    )}
                  </div>
                </div>
                <div>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Project Team</p>
                  <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                    {([
                      ["Delivery Manager",        project.delivery_manager_id],
                      ["Project Manager",         project.project_manager_id],
                      ["Subject Matter Expert",   project.sme_id],
                      ["Data Governance Officer", project.dgo_id],
                      ["PIC Data Compliance",     project.pic_data_compliance_id],
                    ] as [string, string | null][]).map(([lbl, uid]) => {
                      const u = resolveUser(uid);
                      return (
                        <div key={lbl}>
                          <p className="text-xs text-surface-400 mb-0.5">{lbl}</p>
                          <p className="font-medium">{u.name}</p>
                          {u.email && <p className="text-xs text-surface-400">{u.email}</p>}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
