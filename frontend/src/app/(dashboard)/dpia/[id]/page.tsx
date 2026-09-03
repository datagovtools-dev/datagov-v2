"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Check, CheckCircle2, Download, Pencil, Save, Send, X } from "lucide-react";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { AickDetailCards } from "@/components/details/AickDetailView";
import { DetailModal } from "@/components/details/DetailModal";
import { DsrDetailCards } from "@/components/details/DsrDetailView";
import { ProjectDetailCards } from "@/components/details/ProjectDetailView";
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
interface OwnerRecord { role_type: string; full_name: string; email: string }

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
  const currentUser = useAuthStore(s => s.user);
  const isSuperAdmin = Boolean(
    currentUser?.roles?.some((r: any) => (typeof r === "string" ? r : r.name) === "super_admin") ||
    currentUser?.is_super_admin
  );
  const canAction = (approverId?: string | null) => {
    if (!currentUser) return false;
    if (isSuperAdmin) return true;
    return Boolean(approverId && currentUser.id === approverId);
  };

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

  const { data: owners = [], refetch: refetchOwners } = useQuery<OwnerRecord[]>({
    queryKey: ["project-owner-stewards", dpia?.project_id],
    queryFn: () => api.get<OwnerRecord[]>(`/metadata/owners/${dpia!.project_id}`),
    enabled: !!dpia?.project_id,
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
    refetchOwners();
  }

  function resolveUser(uid: string | null) {
    if (!uid) return { name: "—", email: null };
    const u = users.find((x) => x.id === uid);
    return u ? { name: u.full_name, email: u.email } : { name: "—", email: null };
  }

  const dataSteward = owners.find(o => o.role_type === "lead_business_steward") ?? owners.find(o => o.role_type === "business_steward");
  const dataOwner = owners.find(o => o.role_type === "data_owner");

  const saveMutation = useMutation({
    mutationFn: (payload: Record<string, unknown>) =>
      api.put<DPIADetail>(`/dpia/${id}`, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dpia", id] });
      setEditing(false);
    },
  });

  const [approvalComment, setApprovalComment] = React.useState<Record<number, string>>({});

  const submitMutation = useMutation({
    mutationFn: () => {
      toast.loading("Submitting DPIA assessment for review...", { id: "dpia-action" });
      return api.post(`/dpia/${id}/submit`, {});
    },
    onSuccess: () => {
      toast.success("DPIA submitted successfully for review!", { id: "dpia-action" });
      qc.invalidateQueries({ queryKey: ["dpia", id] });
      qc.invalidateQueries({ queryKey: ["dpias"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
    },
    onError: (e: any) => {
      toast.error(e.message ?? "Failed to submit DPIA", { id: "dpia-action" });
    },
  });

  const approvalMutation = useMutation({
    mutationFn: ({ step, action, comments }: { step: number; action: string; comments?: string }) => {
      const label = action === "approve" ? "Approving" : "Rejecting";
      toast.loading(`${label} Step ${step}...`, { id: "dpia-approval" });
      return api.post(`/dpia/${id}/approvals/${step}`, { action, comments: comments ?? approvalComment[step] ?? "" });
    },
    onSuccess: (_, variables) => {
      const msg = variables.action === "approve" ? "Step approved successfully!" : "DPIA rejected.";
      toast.success(msg, { id: "dpia-approval" });
      qc.invalidateQueries({ queryKey: ["dpia", id] });
      qc.invalidateQueries({ queryKey: ["dpias"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setApprovalComment((prev) => ({ ...prev, [variables.step]: "" }));
    },
    onError: (e: any) => {
      toast.error(e.message ?? "Failed to action approval", { id: "dpia-approval" });
    },
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

  if (isLoading) return <DetailSkeleton />;
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
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-start gap-3 pb-3 border-b border-slate-200">
        <button onClick={() => router.back()}
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 mt-0.5 text-slate-600">
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono font-bold text-slate-900 text-sm">{dpia.tracking_id ?? "DPIA"}</span>
                <Badge variant={statusVariant(dpia.status)} className="text-[10px]">
                  {dpia.status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
                </Badge>
                <span className="text-[10px] font-mono text-slate-400">v{dpia.version}</span>
              </div>
              <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1 truncate">{dpia.process_name}</h1>
              <p className="text-xs text-slate-500 font-mono mt-0.5">Data Protection Impact Assessment</p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium" onClick={handleExportPDF}>
                <Download className="h-3.5 w-3.5 mr-1" />Export PDF
              </Button>
              {dpia.status === "draft" && (
                editing ? (
                  <>
                    <Button variant="outline" size="sm" className="h-7.5 text-xs" onClick={cancelEdit}>
                      <X className="h-3.5 w-3.5 mr-1" />Cancel
                    </Button>
                    <Button size="sm" className="h-7.5 text-xs font-medium" onClick={handleSave} disabled={saveMutation.isPending}>
                      <Save className="h-3.5 w-3.5 mr-1" />{saveMutation.isPending ? "Saving…" : "Save"}
                    </Button>
                  </>
                ) : (
                  <>
                    <Button variant="outline" size="sm" className="h-7.5 text-xs" onClick={startEdit}>
                      <Pencil className="h-3.5 w-3.5 mr-1" />Edit
                    </Button>
                    <Button size="sm" className="h-7.5 text-xs font-medium" onClick={() => submitMutation.mutate()} disabled={submitMutation.isPending}>
                      <Send className="h-3.5 w-3.5 mr-1" />{submitMutation.isPending ? "Submitting…" : "Submit"}
                    </Button>
                  </>
                )
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Top Banner: Action Required when awaiting approval */}
      {(() => {
        const activeStep = (dpia.approvals ?? []).find((a) => a.status === "requested");
        if (!activeStep) return null;
        const STEP_LABELS: Record<number, string> = { 1: "PIC Data Compliance Approval", 2: "DM Approval" };
        const userCanAction = canAction(activeStep.approver_id);
        return (
          <div className="rounded-md border border-amber-200 bg-amber-50/70 p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 font-mono">
            <div className="flex items-center gap-2.5">
              <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse shrink-0" />
              <div>
                <p className="text-xs font-semibold text-slate-900">
                  {userCanAction ? "Action Required: " : "Pending Review: "}
                  {STEP_LABELS[activeStep.step_order] ?? `Step ${activeStep.step_order}`} Pending Approval
                </p>
                <p className="text-[11px] text-slate-500">
                  Assigned Approver: {activeStep.approver_name || "Project Approver"}
                </p>
              </div>
            </div>
            {userCanAction ? (
              <div className="flex items-center gap-2 shrink-0">
                <Button
                  size="sm"
                  variant="outline"
                  className="h-7.5 text-xs text-rose-700 hover:bg-rose-50 border-rose-200 font-medium"
                  onClick={() => approvalMutation.mutate({ step: activeStep.step_order, action: "reject" })}
                  disabled={approvalMutation.isPending}
                >
                  <X className="h-3 w-3 mr-1" /> Reject
                </Button>
                <Button
                  size="sm"
                  className="h-7.5 text-xs bg-slate-900 hover:bg-slate-800 text-white font-medium"
                  onClick={() => approvalMutation.mutate({ step: activeStep.step_order, action: "approve" })}
                  disabled={approvalMutation.isPending}
                >
                  <Check className="h-3 w-3 mr-1" /> Approve Step
                </Button>
              </div>
            ) : (
              <div className="text-xs text-slate-500 italic shrink-0">
                Waiting for {activeStep.approver_name || "designated approver"} to sign-off
              </div>
            )}
          </div>
        );
      })()}

      {/* Amber banner when draft */}
      {dpia.status === "draft" && !editing && (
        <div className="px-3.5 py-2 rounded-md bg-amber-50 border border-amber-200 text-xs text-amber-800 font-mono">
          This DPIA is in draft. Complete the details below and submit for approval when ready.
        </div>
      )}

      {/* Project Information */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100"><CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Project Information</CardTitle></CardHeader>
        <CardContent className="pt-4">
          {!editing ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5 text-xs">
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project ID</p>
                <button onClick={openProjectModal}
                  className="font-mono text-xs font-medium text-slate-900 hover:underline text-left">
                  {project?.project_code ?? dpia.project_code ?? dpia.project_id.slice(0, 8)}
                </button>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">PII Flag</p>
                <Badge variant={hasHighPii ? "danger" : hasPii ? "warning" : "success"} className="text-[10px]">
                  {piiLabel}
                </Badge>
                {piiCats.length > 0 && (
                  <p className="text-[10px] text-slate-400 font-mono mt-0.5">{piiCats.length} categor{piiCats.length === 1 ? "y" : "ies"} selected</p>
                )}
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">DSR ID</p>
                {dsrForDpia ? (
                  <button onClick={() => setShowDsrModal(true)}
                    className="font-mono text-xs font-medium text-slate-900 hover:underline text-left">
                    {dsrForDpia.tracking_id}
                  </button>
                ) : (
                  <span className="font-mono text-slate-400">—</span>
                )}
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">AICK ID</p>
                {dsrForDpia?.ai_checklist ? (
                  <button onClick={() => setShowAickModal(true)}
                    className="font-mono text-xs font-medium text-slate-900 hover:underline text-left">
                    {dsrForDpia.tracking_id.replace("DSR", "AICK")}
                  </button>
                ) : (
                  <span className="font-mono text-slate-400">—</span>
                )}
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project Name</p>
                <p className="text-xs font-medium text-slate-900">{project?.project_name ?? dpia.project_name ?? "—"}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Customer / Client</p>
                <p className="text-xs font-medium text-slate-900">{project?.customer_name ?? dpia.customer_name ?? "—"}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing Start Date</p>
                <p className="text-xs font-mono font-medium text-slate-900">{dsrForDpia?.duration_start ? formatDate(dsrForDpia.duration_start) : "—"}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing End Date</p>
                <p className="text-xs font-mono font-medium text-slate-900">
                  {dsrForDpia?.project_end_date
                    ? formatDate(dsrForDpia.project_end_date)
                    : dsrForDpia?.duration_end
                    ? formatDate(dsrForDpia.duration_end)
                    : "—"}
                </p>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5 text-xs">
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project ID</p>
                <p className="font-mono font-medium text-slate-700">{project?.project_code ?? dpia.project_code ?? "—"}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">PII Flag</p>
                <Badge variant={hasHighPii ? "danger" : hasPii ? "warning" : "success"} className="text-[10px]">
                  {piiLabel}
                </Badge>
                {piiCats.length > 0 && (
                  <p className="text-[10px] text-slate-400 font-mono mt-0.5">{piiCats.length} categor{piiCats.length === 1 ? "y" : "ies"} selected</p>
                )}
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">DSR ID</p>
                {dsrForDpia ? (
                  <button onClick={() => setShowDsrModal(true)}
                    className="font-mono text-xs font-medium text-slate-900 hover:underline text-left">
                    {dsrForDpia.tracking_id}
                  </button>
                ) : (
                  <span className="font-mono text-slate-400">—</span>
                )}
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">AICK ID</p>
                {dsrForDpia?.ai_checklist ? (
                  <button onClick={() => setShowAickModal(true)}
                    className="font-mono text-xs font-medium text-slate-900 hover:underline text-left">
                    {dsrForDpia.tracking_id.replace("DSR", "AICK")}
                  </button>
                ) : (
                  <span className="font-mono text-slate-400">—</span>
                )}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Data Categories Involved */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <div className="flex items-center justify-between gap-2">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Data Categories Involved</CardTitle>
            {!editing && piiCats.length > 0 && (
              <Badge variant={hasHighPii ? "danger" : hasPii ? "warning" : "success"} className="text-[10px]">
                {piiLabel} · {piiCats.length} categor{piiCats.length === 1 ? "y" : "ies"}
              </Badge>
            )}
          </div>
        </CardHeader>
        <CardContent className="pt-4">
          {editing ? (
            <>
              <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
                {DATA_CATEGORY_GROUPS.map(({ group, items }) => (
                  <div key={group} className="rounded-md border border-slate-200 bg-slate-50/50 p-2.5">
                    <p className="text-[10px] font-semibold text-slate-500 uppercase font-mono tracking-wide mb-1.5">{group}</p>
                    <div className="flex flex-wrap gap-1">
                      {items.map((item) => {
                        const sel = selectedCategories.includes(item);
                        return (
                          <button key={item} type="button"
                            onClick={() => setSelectedCategories((prev) => sel ? prev.filter((c) => c !== item) : [...prev, item])}
                            className={`px-1.5 py-0.5 rounded-md text-[10px] font-mono transition-colors border ${sel ? "bg-slate-900 border-slate-900 text-white font-medium" : "bg-white border-slate-200 text-slate-600 hover:border-slate-400"}`}>
                            {sel && "✓ "}{item}
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
                  <button type="button" onClick={() => setSelectedCategories([])} className="ml-2 text-slate-400 hover:text-rose-600 font-normal">Clear all</button>
                </p>
              )}
            </>
          ) : piiCats.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
              {DATA_CATEGORY_GROUPS.filter((g) => g.items.some((i) => piiCats.includes(i))).map(({ group, items }) => (
                <div key={group} className="rounded-md border border-slate-200 bg-slate-50/50 p-2.5">
                  <p className="text-[10px] font-semibold text-slate-500 uppercase font-mono tracking-wide mb-1.5">{group}</p>
                  <div className="flex flex-wrap gap-1">
                    {items.filter((i) => piiCats.includes(i)).map((item) => (
                      <span key={item} className="px-1.5 py-0.5 rounded-md text-[10px] font-mono border bg-slate-900 border-slate-900 text-white font-medium">
                        {item}
                      </span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-xs text-slate-400 italic font-mono">No data categories selected.</p>
          )}
        </CardContent>
      </Card>

      {/* Approval Timeline */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <div className="flex items-center justify-between flex-wrap gap-2">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Approval Timeline</CardTitle>
            <Badge variant={
              dpia.status === "approved" ? "success" :
              dpia.status === "rejected" ? "danger" :
              dpia.status === "submitted" || dpia.status === "under_review" ? "warning" : "default"
            } className="text-[10px]">
              {dpia.status === "approved" ? "Approved" :
               dpia.status === "rejected" ? "Rejected" :
               dpia.status === "submitted" ? "Submitted" :
               dpia.status === "under_review" ? "Under Review" : "Draft"}
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="pt-4">
          <ol className="relative border-l border-slate-200 space-y-4 ml-3">
            {[...(dpia.approvals ?? [])].sort((a, b) => a.step_order - b.step_order).map((step) => {
              const STEP_LABELS: Record<number, string> = { 1: "PIC Data Compliance Approval", 2: "DM Approval" };
              const isRequested = step.status === "requested";

              return (
                <li key={step.id} className="ml-3.5">
                  <div className={`absolute -left-1 w-2.5 h-2.5 rounded-full border border-white ${
                    step.status === "approved"  ? "bg-emerald-600" :
                    step.status === "rejected"  ? "bg-rose-600" :
                    isRequested ? "bg-slate-900" :
                    "bg-slate-300"
                  }`} />
                  <div className="flex items-center justify-between gap-2 flex-wrap">
                    <p className={`text-xs font-semibold font-mono ${step.status === "pending" ? "text-slate-400" : "text-slate-900"}`}>
                      {STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
                    </p>
                    <Badge
                      variant={step.status === "approved" ? "success" : step.status === "rejected" ? "danger" : isRequested ? "warning" : "default"}
                      className="text-[10px]">
                      {step.status === "approved" ? "Approved" :
                       step.status === "rejected"  ? "Rejected" :
                       isRequested ? "Awaiting Action" :
                       "Not Yet"}
                    </Badge>
                  </div>
                  {step.approver_name && (
                    <p className={`text-xs ${step.status === "pending" ? "text-slate-400" : "text-slate-600"}`}>
                      {step.approver_name}
                    </p>
                  )}
                  {step.actioned_at && (
                    <p className="text-[10px] text-slate-400 font-mono mt-0.5">Actioned on {new Date(step.actioned_at).toLocaleString("en-GB", { day: "2-digit", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" })}</p>
                  )}
                  {step.comments && (
                    <p className="text-xs text-slate-600 italic mt-1 bg-slate-50 border border-slate-100 rounded p-1.5 font-mono">
                      &ldquo;{step.comments}&rdquo;
                    </p>
                  )}

                  {/* Interactive Approval Controls for Active Requested Step */}
                  {isRequested && (
                    canAction(step.approver_id) ? (
                      <div className="mt-2.5 p-3 rounded-md border border-slate-200 bg-slate-50/60 space-y-2.5 font-mono">
                        <textarea
                          rows={2}
                          className="input-base text-xs font-sans resize-none w-full bg-white"
                          placeholder="Add review comments or sign-off notes (optional)…"
                          value={approvalComment[step.step_order] ?? ""}
                          onChange={(e) =>
                            setApprovalComment((prev) => ({ ...prev, [step.step_order]: e.target.value }))
                          }
                        />
                        <div className="flex items-center gap-2">
                          <Button
                            size="sm"
                            className="h-7.5 text-xs bg-slate-900 hover:bg-slate-800 text-white font-medium"
                            disabled={approvalMutation.isPending}
                            onClick={() => approvalMutation.mutate({ step: step.step_order, action: "approve" })}
                          >
                            <Check className="h-3 w-3 mr-1" /> Approve Step
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            className="h-7.5 text-xs text-rose-700 hover:bg-rose-50 border-rose-200 font-medium"
                            disabled={approvalMutation.isPending}
                            onClick={() => approvalMutation.mutate({ step: step.step_order, action: "reject" })}
                          >
                            <X className="h-3 w-3 mr-1" /> Reject Request
                          </Button>
                        </div>
                      </div>
                    ) : (
                      <div className="mt-2 p-2.5 rounded bg-slate-50 border border-slate-200 text-xs text-slate-500 font-mono italic">
                        Waiting for {step.approver_name || "designated approver"} to review and take action.
                      </div>
                    )
                  )}
                </li>
              );
            })}
          </ol>
        </CardContent>
      </Card>

      {/* Regulatory References */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100"><CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Regulatory References</CardTitle></CardHeader>
        <CardContent className="pt-4">
          <p className="text-xs text-slate-500 font-mono mb-2.5">
            Based on Undang-Undang Pelindungan Data Pribadi (UU PDP) No. 27/2022:
          </p>
          <ol className="space-y-2">
            {REGULATORY_REFS.map((ref, idx) => (
              <li key={idx} className="flex gap-2.5 text-xs">
                <span className="font-semibold font-mono text-slate-900 min-w-[75px]">{ref.pasal}</span>
                <span className="text-slate-600">{ref.desc}</span>
              </li>
            ))}
          </ol>
        </CardContent>
      </Card>

      {/* Governance Activities */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100"><CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Governance Activities</CardTitle></CardHeader>
        <CardContent className="pt-4 space-y-5">
          <div ref={govContainerRef} className="space-y-4">
          {GOVERNANCE_SECTIONS.map(({ key, label, code }) => {
            const items = (govData?.[key] ?? []) as GovernanceItem[];
            return (
              <div key={key}>
                <p className="text-xs font-semibold font-mono text-slate-900 mb-2 flex items-center gap-1.5">
                  <span className="inline-flex items-center justify-center w-4 h-4 rounded-md bg-slate-900 text-white text-[10px] font-bold">{code}</span>
                  {label}
                </p>
                <div className="overflow-x-auto rounded-md border border-slate-200">
                  <table className="w-full text-xs divide-y divide-slate-100">
                    <thead className="bg-slate-50 text-[10px] uppercase font-mono text-slate-500 border-b border-slate-200">
                      <tr>
                        <th className="px-3 py-2 text-left w-1/2">Activity</th>
                        <th className="px-3 py-2 text-left w-36">Responsible</th>
                        <th className="px-3 py-2 text-left w-28">Status</th>
                        <th className="px-3 py-2 text-left">Remarks</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {items.map((item) => (
                        <tr key={item.id} className="hover:bg-slate-50">
                          <td className="px-3 py-2 text-slate-800 leading-snug">
                            {item.item}
                          </td>
                          <td className="px-3 py-2">
                            {editing ? (
                              <div className={`flex items-stretch rounded-md border overflow-hidden transition-opacity ${
                                item.status === "no" ? "opacity-40 pointer-events-none border-slate-100" : "border-slate-200"
                              }`}>
                                <button type="button"
                                  onClick={() => updateGovItem(key, item.id, "responsible", "Internal")}
                                  className={`px-2 py-0.5 text-[10px] font-mono transition-colors ${
                                    item.responsible === "Internal" ? "bg-slate-900 text-white font-medium" : "bg-white text-slate-500 hover:bg-slate-50"
                                  }`}>
                                  ADI-DI
                                </button>
                                <button type="button"
                                  onClick={() => updateGovItem(key, item.id, "responsible", "Client")}
                                  className={`px-2 py-0.5 text-[10px] font-mono transition-colors border-l border-slate-200 ${
                                    item.responsible === "Client" ? "bg-slate-700 text-white font-medium" : "bg-white text-slate-500 hover:bg-slate-50"
                                  }`}>
                                  {project?.customer_name ?? dpia.customer_name ?? "Client"}
                                </button>
                              </div>
                            ) : (
                              <span className={`inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-mono font-medium whitespace-nowrap border ${
                                item.status === "no"
                                  ? "opacity-40 bg-slate-100 text-slate-400 border-slate-200"
                                  : item.responsible === "Internal"
                                  ? "bg-slate-100 text-slate-800 border-slate-200"
                                  : "bg-slate-50 text-slate-700 border-slate-200"
                              }`}>
                                {item.status === "no" ? "N/A" : item.responsible === "Internal" ? "ADI-DI" : (project?.customer_name ?? dpia.customer_name ?? "Client")}
                              </span>
                            )}
                          </td>
                          <td className="px-3 py-2">
                            {editing ? (
                              <select
                                value={item.status}
                                onChange={(e) => updateGovItem(key, item.id, "status", e.target.value)}
                                className="border border-slate-200 rounded-md px-2 py-0.5 text-xs w-full font-mono focus:outline-none focus:ring-1 focus:ring-slate-400">
                                <option value="">—</option>
                                <option value="yes">Yes</option>
                                <option value="no">No</option>
                              </select>
                            ) : (
                              <StatusBadge status={item.status} />
                            )}
                          </td>
                          <td className="px-3 py-2">
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
                                className="border border-slate-200 rounded-md px-2 py-0.5 text-xs w-full focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none overflow-hidden" />
                            ) : (
                              <span className="text-slate-500 text-xs whitespace-pre-wrap">{item.remarks || "—"}</span>
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
        <CardHeader className="pb-3 border-b border-slate-100"><CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Risk Assessment</CardTitle></CardHeader>
        <CardContent className="pt-4 text-xs">
          {editing ? (
            <>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Risk Description</label>
              <p className="text-[11px] text-slate-500 mb-1.5">
                Identify the privacy risk and potential impact on data subjects if it materialises.<br />
                <span className="text-slate-400 italic">
                  e.g. &quot;Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm.&quot;
                </span>
              </p>
              <textarea value={form.risk_description as string} rows={4}
                onChange={(e) => setF("risk_description", e.target.value)}
                className="w-full border border-slate-200 rounded-md px-3 py-2 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none"
                placeholder="Describe the privacy risk and potential harm to data subjects…" />
            </>
          ) : (
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Risk Description</p>
              <p className="text-slate-800 leading-relaxed">{dpia.risk_description || "—"}</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Mitigation & Residual Risk */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100"><CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Mitigation &amp; Residual Risk</CardTitle></CardHeader>
        <CardContent className="pt-4 space-y-4 text-xs">
          <div>
            {editing ? (
              <>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Mitigation Measures</label>
                <p className="text-[11px] text-slate-500 mb-1.5">
                  Describe controls and safeguards in place to reduce the risk.<br />
                  <span className="text-slate-400 italic">
                    e.g. &quot;Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable.&quot;
                  </span>
                </p>
                <textarea value={form.mitigation_measures as string} rows={3}
                  onChange={(e) => setF("mitigation_measures", e.target.value)}
                  className="w-full border border-slate-200 rounded-md px-3 py-2 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none"
                  placeholder="Describe controls and safeguards in place…" />
              </>
            ) : (
              <>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Mitigation Measures</p>
                <p className="text-slate-800 leading-relaxed">{dpia.mitigation_measures || "—"}</p>
              </>
            )}
          </div>
          <div>
            {editing ? (
              <>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Residual Risk Level</label>
                <p className="text-[11px] text-slate-500 mb-2 font-mono">
                  Level of risk remaining after mitigations are applied.
                </p>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {([
                    { level: "Low",      desc: "Well-controlled. Acceptable with current safeguards." },
                    { level: "Medium",   desc: "Some risk remains. Additional monitoring may be needed." },
                    { level: "High",     desc: "Significant risk. Escalation recommended." },
                    { level: "Critical", desc: "Unacceptable. Executive sign-off required." },
                  ] as { level: string; desc: string }[]).map(({ level, desc }) => {
                    const selected = (form.residual_risk as string) === level;
                    return (
                      <button key={level} type="button"
                        onClick={() => setF("residual_risk", selected ? "" : level)}
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
              </>
            ) : (
              <>
              </>
            )}
          </div>
        </CardContent>
      </Card>

      {/* DSR Detail Modal */}
      {showDsrModal && dsrForDpia && (
        <DetailModal
          code={dsrForDpia.tracking_id}
          title={dpia.project_name ?? project?.project_name}
          onClose={() => setShowDsrModal(false)}
        >
          <DsrDetailCards
            dsr={{
              ...dsrForDpia,
              project_id: dpia.project_id,
              project_code: dpia.project_code ?? project?.project_code ?? null,
              project_name: dpia.project_name ?? project?.project_name ?? "-",
              approvals: dsrApprovals,
            }}
          />
        </DetailModal>
      )}
      {/* AICK Detail Modal */}
      {showAickModal && dsrForDpia?.ai_checklist && (
        <DetailModal
          code={dsrForDpia.tracking_id.replace("DSR", "AICK")}
          title={dpia.project_name ?? project?.project_name}
          onClose={() => setShowAickModal(false)}
        >
          <AickDetailCards
            dsr={{
              ...dsrForDpia,
              project_id: dpia.project_id,
              project_code: dpia.project_code ?? project?.project_code ?? null,
              project_name: dpia.project_name ?? project?.project_name ?? "-",
              ai_checklist: {
                ...dsrForDpia.ai_checklist,
                approvals: aickApprovals,
              },
            }}
            areas={AICK_AREAS_DEF}
          />
        </DetailModal>
      )}
      {/* Project Detail Modal */}
      {showProjectModal && (
        <DetailModal
          code={project?.project_code ?? dpia.project_code}
          title={project?.project_name ?? dpia.project_name}
          onClose={() => setShowProjectModal(false)}
          loading={!project}
        >
          {project && (
            <ProjectDetailCards project={project} users={users} owners={owners} />
          )}
        </DetailModal>
      )}
    </div>
  );
}
