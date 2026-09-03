"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Check, CheckCircle2, Download, Lock, Pencil, Save, X, Send } from "lucide-react";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { DetailModal } from "@/components/details/DetailModal";
import { DsrDetailCards } from "@/components/details/DsrDetailView";
import { ProjectDetailCards } from "@/components/details/ProjectDetailView";
import { formatDate, formatDateTime } from "@/lib/utils";
import { printA4, pdfField, pdfBadge, pdfStatusBadge } from "@/lib/exportPdf";

// ── Template ──────────────────────────────────────────────────────────────────

interface TemplateItem {
  id: string;
  assessment: string;
  risk_level: "HIGH" | "MEDIUM" | "LOW";
  potential_risk: string;
  mitigation: string;
}

interface TemplateArea {
  area: string;
  items: TemplateItem[];
}

const AI_ASSESSMENT_TEMPLATE: TemplateArea[] = [
  {
    area: "Before Use",
    items: [
      {
        id: "before_use_1",
        assessment: "The project or product developed using an AI platform has complied with applicable legal regulations and internal company policies",
        risk_level: "HIGH",
        potential_risk: "Lack of awareness or disregard for legal and internal policies may lead to regulatory violations, privacy breaches, or misuse of AI, resulting in legal sanctions and reputational damage to the company",
        mitigation: "Foster employee awareness on Gen AI policies and perform periodic reviews of internal guidelines and applicable external regulations. Individuals or teams have a clear understanding of Gen AI usage policies in accordance with legal requirements and internal company policies.",
      },
      {
        id: "before_use_2",
        assessment: "The Gen AI Platform used is properly licensed and has been approved by management",
        risk_level: "HIGH",
        potential_risk: "The use of unauthorized or unapproved AI platforms may result in violations of IT policies, potential data leakage, cybersecurity risks, and non-compliance with applicable legal regulations or contractual obligations",
        mitigation: "Establish and maintain an up-to-date list of Gen AI platforms officially approved by the company. Ensure that all Gen-AI accounts used are properly licensed and have obtained formal approval from authorized management.",
      },
      {
        id: "before_use_3",
        assessment: "Gen-AI usage settings have been configured to disable interaction history and ensure opt-out from model training by default",
        risk_level: "MEDIUM",
        potential_risk: "Failure to disable history or opt-out from model training may result in data submitted to Gen-AI being used for training purposes, posing risks of being recorded, exposed, or misused by third parties without explicit consent.",
        mitigation: "Individuals using licensed Gen-AI tools must ensure that their prompts and outputs are not used for model training. Users are required to disable history settings and opt out of data usage options provided by the Gen-AI service.",
      },
    ],
  },
  {
    area: "Input",
    items: [
      {
        id: "input_1",
        assessment: "Do not include personal, sensitive, or intellectual property data.",
        risk_level: "HIGH",
        potential_risk: "If the input contains personal data, sensitive information, or intellectual property, such data may be used to train AI models by the service provider. This violates confidentiality principles and may breach regulations such as the Personal Data Protection Law (UU PDP).",
        mitigation: "The interaction process must not include personal data (e.g., names, email addresses, ID numbers, photos), confidential or sensitive company information (e.g., financial data, business plans), or company intellectual property.",
      },
      {
        id: "input_2",
        assessment: "Interactions with Gen-AI should utilize anonymization, pseudonymization, and dummy data.",
        risk_level: "HIGH",
        potential_risk: "Using real data when interacting with Gen-AI poses risks of personal data leakage, privacy violations, and potential re-identification. Sensitive data may be recorded, disseminated, or misused, thereby violating data protection policies.",
        mitigation: "Create dummy data for exploration purposes to avoid risking real data.",
      },
      {
        id: "input_3",
        assessment: "Prompts must not contain bias or harmful narratives, and should be documented if used for reporting or publication purposes.",
        risk_level: "LOW",
        potential_risk: "If prompts are not documented, the rationale and intent behind the use of AI will be lost. This hinders audit processes, output quality evaluation, and the ability to trace the origin of errors in AI-generated content.",
        mitigation: "Save prompt documentation in the project folder using a standard format (e.g., prompt-log.txt). Review prompts before using them for public purposes.",
      },
    ],
  },
  {
    area: "Output",
    items: [
      {
        id: "output_1",
        assessment: "Interactions with Gen-AI must include verification and revalidation of the results to ensure the validity of the information, including inaccuracies, hallucinations, and bias",
        risk_level: "MEDIUM",
        potential_risk: "Misinformation/disinformation, hallucination (fictitious facts), bias and discrimination, reputational risk, and legal risk from dissemination of unauthorized or misleading information.",
        mitigation: "Gen-AI outputs must be manually verified by competent parties, referencing trusted sources. Validate for potential bias, hallucinations, or inaccurate information before results are used for decision-making, publication, or further distribution.",
      },
      {
        id: "output_2",
        assessment: "Any source code generated by Gen-AI must be properly validated before being implemented in the Company's systems",
        risk_level: "HIGH",
        potential_risk: "Code vulnerability, data leakage (code stores or transmits sensitive data without protection), non-compliance, unintended behavior, and dependency on non-verified libraries.",
        mitigation: "Source code generated by Gen-AI must be reviewed by experienced developers, tested with security analysis tools, and undergo functional testing before being used in company systems.",
      },
    ],
  },
  {
    area: "Utilization",
    items: [
      {
        id: "utilization_1",
        assessment: "Outputs should only be used after being reviewed and approved by an authorized user.",
        risk_level: "MEDIUM",
        potential_risk: "Using AI output directly without confirmation poses the risk of producing decisions that are invalid, misleading, or misaligned with company policies.",
        mitigation: "Teams receiving the output are required to perform an independent assessment. Use a simple checklist as a tool to evaluate whether the output is ready for use or needs revision.",
      },
      {
        id: "utilization_2",
        assessment: "Corrections must be made if the AI-generated results are inaccurate or inappropriate before any distribution.",
        risk_level: "HIGH",
        potential_risk: "Disseminating inaccurate results poses the risk of spreading misinformation, influencing public opinion, or leading to incorrect internal decisions.",
        mitigation: 'Apply the "pause and review" principle. Add status labels (e.g., "need review", "final") before the output is used outside the team.',
      },
    ],
  },
];

// ── Types ─────────────────────────────────────────────────────────────────────

interface AssessmentItemState { status: string | null; remarks: string }
interface AIDraft {
  items: Record<string, AssessmentItemState>;
  sign_off: Record<string, string>;
}

interface AIChecklistApproval {
  id: string;
  approver_id?: string | null;
  step_order: number;
  approver_role: string;
  approver_name: string;
  status: string;
  comments?: string | null;
  actioned_at: string | null;
}

interface AIChecklist {
  id: string;
  checklist_json: Record<string, any>;
  status: string;
  validated_by: string | null;
  validated_at: string | null;
  approvals: AIChecklistApproval[];
}

interface DSRApproval {
  id: string; approver_id?: string | null; step_order: number; approver_role: string; approver_name: string;
  status: string; comments?: string | null; actioned_at: string | null;
}

interface DSRDetail {
  id: string; tracking_id: string; project_id: string; project_code: string | null; project_name: string;
  recipient: string; purpose: string; is_ai_use: boolean;
  duration_start: string; duration_end: string;
  status: string; created_at: string;
  approvals: DSRApproval[];
  ai_checklist: AIChecklist | null;
}

interface ProjectDetail {
  id: string; project_code: string | null; project_name: string; customer_name: string;
  line_of_business: string | null; use_case: string | null; project_year: number;
  project_category: string; is_monetized: boolean;
  start_date: string | null; end_date: string | null;
  sme_id: string | null; delivery_manager_id: string | null; project_manager_id: string | null;
  dgo_id: string | null; metadata_officer_id: string | null;
  dq_officer_id: string | null; pic_data_compliance_id: string | null;
}

const DSR_STEP_LABELS: Record<number, string> = {
  1: "PIC Data Compliance Approval", 2: "DM Approval", 3: "SME Sign Off", 4: "Client Sign Off",
};

const AICK_STEP_LABELS: Record<number, string> = {
  1: "PIC Data Compliance Approval",
  2: "DM Sign-off",
  3: "SME Sign-off",
};

const DSR_CHECKLIST_TEMPLATE: { section: string; title: string; aiOnly?: boolean; items: { id: string; label: string; sub?: { id: string; label: string }[] }[] }[] = [
  {
    section: "A", title: "Interest Protection",
    items: [
      { id: "A_i", label: "Will this data sharing infringe commercial interest(s) of the Business Unit(s) sharing the data?",
        sub: [{ id: "A_i_1", label: "Loss in revenue due to cannibalization" }, { id: "A_i_2", label: "Damage to relationship with customers" }, { id: "A_i_3", label: "Other commercial interest(s)" }] },
      { id: "A_ii", label: "Are there potentially any commercial secret(s) included in the requested data?",
        sub: [{ id: "A_ii_1", label: "Highly confidential partnerships" }, { id: "A_ii_2", label: "Patent information" }, { id: "A_ii_3", label: "M&A deals" }, { id: "A_ii_4", label: "Other commercial secret(s)" }] },
    ],
  },
  {
    section: "B", title: "Customer Data & Insights Sharing Consent",
    items: [
      { id: "B_i",   label: "Are the data & insights requested sensitive?" },
      { id: "B_ii",  label: "Are there any mitigation steps in place if sensitive data & insights are used?" },
      { id: "B_iii", label: "Are the data & insights requested considered personal data?" },
      { id: "B_iv",  label: "If personal data need to be shared, has written consent for sharing been obtained?" },
      { id: "B_v",   label: "If personal data need to be used for use case development, has written consent for research been obtained?" },
      { id: "B_vi",  label: "Are the data and analytics processes located within the BU's analytics environment with limited access?" },
    ],
  },
  {
    section: "C", title: "Regulatory Compliance",
    items: [
      { id: "C_i", label: "Are there prevailing regulations that will be violated if the data & insights are shared?",
        sub: [{ id: "C_i_1", label: "Industry-specific laws" }, { id: "C_i_2", label: "Data protection laws" }, { id: "C_i_3", label: "Internal regulations and policies" }] },
    ],
  },
  {
    section: "D", title: "AI Compliance", aiOnly: true,
    items: [{ id: "D_i", label: "Is the data analysis process carried out using artificial intelligence technology?" }],
  },
];

interface UserOption { id: string; full_name: string; email: string; position?: string | null }
interface OwnerRecord { role_type: string; full_name: string; email: string }

// ── Helpers ───────────────────────────────────────────────────────────────────

function riskBadgeClass(level: "HIGH" | "MEDIUM" | "LOW") {
  return level === "HIGH"   ? "bg-red-100 text-red-700 border border-red-200" :
         level === "MEDIUM" ? "bg-amber-100 text-amber-700 border border-amber-200" :
                              "bg-green-100 text-green-700 border border-green-200";
}

const AI_CHECKLIST_REQUIRED_ITEMS = [
  "before_use_1", "before_use_2", "before_use_3",
  "input_1", "input_2", "input_3",
  "output_1", "output_2",
  "utilization_1", "utilization_2",
];
const AI_SIGN_OFF_REQUIRED_FIELDS = ["approved", "prepared_by", "prepared_position", "acknowledged_by", "acknowledged_position"];

function isAIChecklistComplete(draft: AIDraft): boolean {
  for (const id of AI_CHECKLIST_REQUIRED_ITEMS) {
    if (!draft.items[id]?.status) return false;
  }
  const so = draft.sign_off;
  for (const f of AI_SIGN_OFF_REQUIRED_FIELDS) {
    if (!so[f]?.trim()) return false;
  }
  return true;
}

function emptyDraft(): AIDraft {
  const items: Record<string, AssessmentItemState> = {};
  for (const area of AI_ASSESSMENT_TEMPLATE) {
    for (const item of area.items) {
      items[item.id] = { status: null, remarks: "" };
    }
  }
  return { items, sign_off: {} };
}

function draftFromJson(json: Record<string, any> | undefined): AIDraft {
  const ai = json?.ai_assessment;
  if (!ai) return emptyDraft();
  const base = emptyDraft();
  for (const id of Object.keys(base.items)) {
    if (ai.items?.[id]) base.items[id] = { status: ai.items[id].status ?? null, remarks: ai.items[id].remarks ?? "" };
  }
  return { items: base.items, sign_off: ai.sign_off ?? {} };
}

// ── Sub-components ────────────────────────────────────────────────────────────

function StatusSelect({ value, onChange, disabled, hasError }: {
  value: string | null; onChange: (v: string) => void; disabled?: boolean; hasError?: boolean;
}) {
  return (
    <select
      value={value ?? ""}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled}
      className={`input-base text-sm w-20 shrink-0 ${
        value === "Yes" ? "border-green-400 bg-green-50 text-green-700" :
        value === "No"  ? "border-red-300 bg-red-50 text-red-700" :
        hasError        ? "border-red-500 ring-1 ring-red-400 bg-red-50" :
        "text-surface-500"
      }`}
    >
      <option value="" disabled hidden>Yes/No</option>
      <option value="Yes">Yes</option>
      <option value="No">No</option>
    </select>
  );
}

function RemarksTextarea({ value, onChange, disabled }: {
  value: string; onChange: (v: string) => void; disabled?: boolean;
}) {
  const ref = React.useRef<HTMLTextAreaElement>(null);
  React.useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${el.scrollHeight}px`;
  }, [value]);
  return (
    <textarea
      ref={ref}
      rows={1}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled}
      placeholder="Remarks…"
      className="input-base text-sm flex-1 min-w-0 resize-none overflow-hidden leading-snug py-1.5"
    />
  );
}

// ── SignaturePad ──────────────────────────────────────────────────────────────

function SignaturePad({ value, onSign, onClear, disabled }: {
  value: string | null; onSign: (sig: string) => void; onClear: () => void; disabled?: boolean;
}) {
  const canvasRef = React.useRef<HTMLCanvasElement>(null);
  const fileInputRef = React.useRef<HTMLInputElement>(null);
  const drawing = React.useRef(false);
  const lastPos = React.useRef<{ x: number; y: number } | null>(null);
  const [isDragging, setIsDragging] = React.useState(false);

  function loadImageFile(file: File) {
    if (!file.type.startsWith("image/")) return;
    const reader = new FileReader();
    reader.onload = (ev) => onSign(ev.target!.result as string);
    reader.readAsDataURL(file);
  }
  function handleDragOver(e: React.DragEvent) { e.preventDefault(); setIsDragging(true); }
  function handleDragLeave(e: React.DragEvent) { e.preventDefault(); setIsDragging(false); }
  function handleDrop(e: React.DragEvent) {
    e.preventDefault(); setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file) loadImageFile(file);
  }
  function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) { loadImageFile(file); e.target.value = ""; }
  }

  function getPos(e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) {
    const rect = canvasRef.current!.getBoundingClientRect();
    if ("touches" in e) return { x: e.touches[0].clientX - rect.left, y: e.touches[0].clientY - rect.top };
    return { x: (e as React.MouseEvent).clientX - rect.left, y: (e as React.MouseEvent).clientY - rect.top };
  }
  function onMouseDown(e: React.MouseEvent<HTMLCanvasElement>) { drawing.current = true; lastPos.current = getPos(e); }
  function onTouchStart(e: React.TouchEvent<HTMLCanvasElement>) { e.preventDefault(); drawing.current = true; lastPos.current = getPos(e); }
  function stroke(e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) {
    if (!drawing.current) return;
    const canvas = canvasRef.current!;
    const ctx = canvas.getContext("2d")!;
    const pos = getPos(e);
    ctx.strokeStyle = "#1e293b"; ctx.lineWidth = 1.8; ctx.lineCap = "round"; ctx.lineJoin = "round";
    ctx.beginPath(); ctx.moveTo(lastPos.current!.x, lastPos.current!.y); ctx.lineTo(pos.x, pos.y); ctx.stroke();
    lastPos.current = pos;
  }
  function endDraw() {
    if (!drawing.current) return;
    drawing.current = false; lastPos.current = null;
    onSign(canvasRef.current!.toDataURL("image/png"));
  }
  function clearCanvas() {
    const c = canvasRef.current;
    if (c) c.getContext("2d")!.clearRect(0, 0, c.width, c.height);
    onClear();
  }

  if (disabled) {
    return value ? (
      <div className="border border-surface-200 rounded-md bg-white p-1 h-14">
        <img src={value} alt="signature" className="h-full w-full object-contain" />
      </div>
    ) : (
      <div className="border border-dashed border-surface-200 rounded-md h-14 flex items-center justify-center bg-surface-50">
        <span className="text-xs text-surface-400">Not signed</span>
      </div>
    );
  }

  if (value) {
    return (
      <div>
        <div className="border border-green-300 rounded-md bg-green-50 p-1 h-14 relative">
          <img src={value} alt="signature" className="h-full w-full object-contain" />
          <span className="absolute top-1 right-1 text-xs text-green-600 font-medium">✓ Signed</span>
        </div>
        <button type="button" onClick={clearCanvas} className="text-xs text-red-500 hover:text-red-700 mt-0.5 hover:underline">
          Clear &amp; re-sign
        </button>
      </div>
    );
  }

  return (
    <div>
      <div
        className={`relative border rounded-md bg-white overflow-hidden h-14 transition-colors ${
          isDragging
            ? "border-primary-400 bg-primary-50 cursor-copy"
            : "border-surface-300 cursor-crosshair"
        }`}
        onDragOver={handleDragOver}
        onDragEnter={handleDragOver}
        onDragLeave={handleDragLeave}
        onDrop={handleDrop}
      >
        <span className="absolute inset-0 flex items-center justify-center text-xs pointer-events-none select-none">
          {isDragging
            ? <span className="text-primary-500 font-medium">Drop image here</span>
            : <span className="text-surface-300">Draw signature here</span>
          }
        </span>
        <canvas ref={canvasRef} width={500} height={56}
          className={`w-full h-full touch-none ${isDragging ? "pointer-events-none" : ""}`}
          onMouseDown={onMouseDown} onMouseMove={stroke} onMouseUp={endDraw} onMouseLeave={endDraw}
          onTouchStart={onTouchStart} onTouchMove={stroke} onTouchEnd={endDraw}
        />
      </div>
      <div className="flex items-center gap-1 mt-1">
        <span className="text-xs text-surface-400">or</span>
        <button type="button" onClick={() => fileInputRef.current?.click()}
          className="text-xs text-primary-600 hover:underline">
          upload signature image
        </button>
        <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handleFileChange} />
      </div>
    </div>
  );
}

// ── SignOff ───────────────────────────────────────────────────────────────────

function SignOffSection({ value, onChange, disabled, showErrors, activeApprovalStep, isSuperAdmin }: {
  value: Record<string, string>;
  onChange: (field: string, val: string) => void;
  disabled?: boolean;
  showErrors?: boolean;
  activeApprovalStep?: number;
  isSuperAdmin?: boolean;
}) {
  function handleSign(prefix: "prepared" | "acknowledged", sig: string) {
    onChange(`${prefix}_signature`, sig);
    onChange(`${prefix}_date`, new Date().toISOString().split("T")[0]);
    if (prefix === "prepared") onChange("approved", "Yes");
  }
  function handleClear(prefix: "prepared" | "acknowledged") {
    onChange(`${prefix}_signature`, "");
    onChange(`${prefix}_date`, "");
  }
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <span className="text-sm font-medium text-surface-700 w-28 shrink-0">
          Approved? <span className="text-red-500">*</span>
        </span>
        <select
          value={value.approved ?? ""}
          onChange={(e) => onChange("approved", e.target.value)}
          disabled={disabled || !!value.prepared_signature}
          className={`input-base text-sm w-24 ${
            value.approved === "Yes" ? "border-green-400 bg-green-50 text-green-700" :
            value.approved === "No"  ? "border-red-300 bg-red-50 text-red-700" :
            showErrors && !value.approved ? "border-red-500 ring-1 ring-red-400 bg-red-50" : ""
          }`}
        >
          <option value="" disabled hidden>Yes / No</option>
          <option value="Yes">Yes</option>
          <option value="No">No</option>
        </select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Prepared By — DM, available at Step 2 */}
        <div className="space-y-2">
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">
            Prepared By{" "}
            <span className="text-primary-500 normal-case font-normal">(auto-filled · Delivery Manager)</span>
          </p>
          <input type="text" placeholder="Full name" value={value.prepared_by ?? ""} disabled
            className="input-base text-sm w-full bg-surface-50 text-surface-600" />
          <input type="text" placeholder="Position" value={value.prepared_position ?? ""} disabled
            className="input-base text-sm w-full bg-surface-50 text-surface-600" />
          <div>
            <p className="text-xs text-surface-500 mb-1">Signature</p>
            <SignaturePad
              value={value.prepared_signature || null}
              onSign={(sig) => handleSign("prepared", sig)}
              onClear={() => handleClear("prepared")}
              disabled={disabled || (!isSuperAdmin && activeApprovalStep !== 2)}
            />
            {!disabled && !isSuperAdmin && activeApprovalStep !== 2 && (
              <p className="text-xs text-surface-400 flex items-center gap-1 mt-1">
                <Lock className="h-3 w-3" /> Available at DM Sign-off step
              </p>
            )}
          </div>
          {value.prepared_date && (
            <p className="text-xs text-surface-400">Signed on: <span className="font-medium text-surface-600">{value.prepared_date}</span></p>
          )}
        </div>

        {/* Acknowledged By — SME, available at Step 3 */}
        <div className="space-y-2">
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">
            Acknowledged By{" "}
            <span className="text-primary-500 normal-case font-normal">(auto-filled · Project SME)</span>
          </p>
          <input type="text" placeholder="Full name" value={value.acknowledged_by ?? ""} disabled
            className="input-base text-sm w-full bg-surface-50 text-surface-600" />
          <input type="text" placeholder="Position" value={value.acknowledged_position ?? ""} disabled
            className="input-base text-sm w-full bg-surface-50 text-surface-600" />
          <div>
            <p className="text-xs text-surface-500 mb-1">Signature</p>
            <SignaturePad
              value={value.acknowledged_signature || null}
              onSign={(sig) => handleSign("acknowledged", sig)}
              onClear={() => handleClear("acknowledged")}
              disabled={disabled || (!isSuperAdmin && activeApprovalStep !== 3)}
            />
            {!disabled && !isSuperAdmin && activeApprovalStep !== 3 && (
              <p className="text-xs text-surface-400 flex items-center gap-1 mt-1">
                <Lock className="h-3 w-3" /> Available at SME Sign-off step
              </p>
            )}
          </div>
          {value.acknowledged_date && (
            <p className="text-xs text-surface-400">Signed on: <span className="font-medium text-surface-600">{value.acknowledged_date}</span></p>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function AIChecklistDetailPage() {
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
  const [draft, setDraft] = React.useState<AIDraft | null>(null);
  const [showErrors, setShowErrors] = React.useState(false);

  const { data: dsr, isLoading, refetch: refetchDsr } = useQuery<DSRDetail>({
    queryKey: ["dsr", id],
    queryFn: () => api.get<DSRDetail>(`/dsr/${id}`),
    staleTime: 0,
  });

  const [showProjectModal, setShowProjectModal] = React.useState(false);
  const [showDSRModal, setShowDSRModal] = React.useState(false);

  const { data: project, refetch: refetchProject } = useQuery<ProjectDetail>({
    queryKey: ["project", dsr?.project_id],
    queryFn: () => api.get<ProjectDetail>(`/projects/${dsr!.project_id}`),
    enabled: !!dsr?.project_id,
    staleTime: 0,
  });

  const { data: users = [], refetch: refetchUsers } = useQuery<UserOption[]>({
    queryKey: ["users-options"],
    queryFn: () => api.get<UserOption[]>("/rbac/users/options"),
    enabled: !!dsr?.project_id,
    staleTime: 0,
  });

  const { data: owners = [], refetch: refetchOwners } = useQuery<OwnerRecord[]>({
    queryKey: ["project-owner-stewards", dsr?.project_id],
    queryFn: () => api.get<OwnerRecord[]>(`/metadata/owners/${dsr!.project_id}`),
    enabled: !!dsr?.project_id,
    staleTime: 0,
  });

  function openProjectModal() {
    setShowProjectModal(true);
    refetchProject();
    refetchUsers();
    refetchOwners();
  }

  const dataSteward = owners.find(o => o.role_type === "lead_business_steward") ?? owners.find(o => o.role_type === "business_steward");
  const dataOwner = owners.find(o => o.role_type === "data_owner");

  function openDSRModal() {
    setShowDSRModal(true);
    refetchDsr();
  }

  React.useEffect(() => {
    if (!dsr?.ai_checklist) return;
    const base = draftFromJson(dsr.ai_checklist.checklist_json);

    if (!base.sign_off.prepared_by && project && users.length) {
      const dm = users.find(u => u.id === project.delivery_manager_id);
      if (dm) {
        base.sign_off.prepared_by = dm.full_name;
        base.sign_off.prepared_position = dm.position ?? "Delivery Manager";
      }
    }
    if (!base.sign_off.acknowledged_by && project && users.length) {
      const sme = users.find(u => u.id === project.sme_id);
      if (sme) {
        base.sign_off.acknowledged_by = sme.full_name;
        base.sign_off.acknowledged_position = sme.position ?? "Subject Matter Expert (SME)";
      }
    }
    if (!base.sign_off.approved) base.sign_off.approved = "Yes";

    setDraft(base);
  }, [dsr?.ai_checklist?.id, project?.delivery_manager_id, users.length]);

  function setItem(itemId: string, field: "status" | "remarks", value: string) {
    setDraft((prev) => {
      const d = prev ?? emptyDraft();
      return {
        ...d,
        items: {
          ...d.items,
          [itemId]: { ...(d.items[itemId] ?? { status: null, remarks: "" }), [field]: value || (field === "status" ? null : "") },
        },
      };
    });
  }

  function setSignOff(field: string, value: string) {
    setDraft((prev) => {
      const d = prev ?? emptyDraft();
      return { ...d, sign_off: { ...d.sign_off, [field]: value } };
    });
  }

  const saveMutation = useMutation({
    mutationFn: () => {
      const existing = dsr?.ai_checklist?.checklist_json ?? {};
      return api.put(`/dsr/${id}/checklist`, {
        checklist_json: { ...existing, ai_assessment: draft },
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["ai-checklist"] });
      setEditing(false);
      setShowErrors(false);
    },
  });

  const submitMutation = useMutation({
    mutationFn: async () => {
      // Save first, then submit
      const existing = dsr?.ai_checklist?.checklist_json ?? {};
      await api.put(`/dsr/${id}/checklist`, {
        checklist_json: { ...existing, ai_assessment: draft },
      });
      return api.post(`/dsr/${id}/checklist/submit`, {});
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["ai-checklist"] });
      setEditing(false);
      setShowErrors(false);
    },
  });

  const [approvalComment, setApprovalComment] = React.useState<Record<number, string>>({});

  const approvalMutation = useMutation({
    mutationFn: ({ step, action }: { step: number; action: "approve" | "reject" }) => {
      const label = action === "approve" ? "Approving" : "Rejecting";
      toast.loading(`${label} Step ${step}...`, { id: "aick-approval" });
      return api.post(`/dsr/${id}/checklist/approvals/${step}`, {
        action,
        comments: approvalComment[step] ?? "",
      });
    },
    onSuccess: (_, variables) => {
      const msg = variables.action === "approve" ? "Step approved successfully!" : "Checklist rejected.";
      toast.success(msg, { id: "aick-approval" });
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["ai-checklist"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setApprovalComment((prev) => ({ ...prev, [variables.step]: "" }));
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to action approval", { id: "aick-approval" });
    },
  });

  function handleSaveAsDraft() {
    if (!draft) return;
    saveMutation.mutate();
  }

  function handleSubmit() {
    if (!draft) return;
    if (!isAIChecklistComplete(draft)) { setShowErrors(true); return; }
    setShowErrors(false);
    submitMutation.mutate();
  }

  function handleCancel() {
    setEditing(false);
    setShowErrors(false);
    if (dsr?.ai_checklist) setDraft(draftFromJson(dsr.ai_checklist.checklist_json));
  }

  function resolveUser(uid: string | null): { name: string; email: string | null } {
    if (!uid) return { name: "—", email: null };
    const u = users.find(u => u.id === uid);
    return u ? { name: u.full_name, email: u.email } : { name: "—", email: null };
  }

  function handleExportPDF() {
    if (!dsr || !draft) return;
    const so = draft.sign_off;

    const tableRows = AI_ASSESSMENT_TEMPLATE.flatMap((area) =>
      area.items.map((item, idx) => {
        const val = draft.items[item.id];
        const areaCell = idx === 0
          ? `<td rowspan="${area.items.length}" style="font-weight:600;vertical-align:middle;background:#EDF2F7">${area.area}</td>`
          : "";
        const riskStyle =
          item.risk_level === "HIGH"   ? "color:#C53030;font-weight:600" :
          item.risk_level === "MEDIUM" ? "color:#B7791F;font-weight:600" :
                                         "color:#276749;font-weight:600";
        return `<tr>
          ${areaCell}
          <td>${item.assessment}</td>
          <td style="${riskStyle};text-align:center">${item.risk_level}</td>
          <td style="font-size:8pt">${item.mitigation}</td>
          <td style="text-align:center;font-weight:600">${val?.status || "—"}</td>
          <td>${val?.remarks || "—"}</td>
        </tr>`;
      })
    ).join("");

    const checklist = dsr.ai_checklist;
    const ackApprovals = (checklist?.approvals ?? []).sort((a, b) => a.step_order - b.step_order);
    const approvalRows = ackApprovals.map((s) => {
      const label = AICK_STEP_LABELS[s.step_order] ?? `Step ${s.step_order}`;
      const statusBadge =
        s.status === "approved" ? pdfBadge("Approved", "approved") :
        s.status === "rejected" ? pdfBadge("Rejected", "rejected") :
        s.status === "requested" ? pdfBadge("Requested", "pending") :
        pdfBadge("Not Yet", "draft");
      return `<li style="margin-bottom:10px">
        <span>
          <div class="tl-label">${label} ${statusBadge}</div>
          <div class="tl-meta">${s.approver_name || "—"}${s.actioned_at ? " · " + formatDateTime(s.actioned_at) : ""}</div>
        </span>
      </li>`;
    }).join("");

    const signOffHtml = `<div class="section">
      <div class="section-title">Sign Off</div>
      <div style="margin-bottom:8px">${pdfField("Approved?", so.approved)}</div>
      <div class="sig-grid">
        <div class="sig-box">
          <div class="sig-title">Prepared By — Delivery Manager</div>
          <div class="sig-name">${so.prepared_by || "—"}</div>
          <div class="tl-meta">${so.prepared_position || ""}</div>
          ${so.prepared_signature ? `<img class="sig-image" src="${so.prepared_signature}" alt="signature" />` : `<div class="sig-line"></div>`}
          <div class="sig-date">${so.prepared_date ? "Signed: " + so.prepared_date : "Not yet signed"}</div>
        </div>
        <div class="sig-box">
          <div class="sig-title">Acknowledged By — Subject Matter Expert (SME)</div>
          <div class="sig-name">${so.acknowledged_by || "—"}</div>
          <div class="tl-meta">${so.acknowledged_position || ""}</div>
          ${so.acknowledged_signature ? `<img class="sig-image" src="${so.acknowledged_signature}" alt="signature" />` : `<div class="sig-line"></div>`}
          <div class="sig-date">${so.acknowledged_date ? "Signed: " + so.acknowledged_date : "Not yet signed"}</div>
        </div>
      </div>
    </div>`;

    const checklistStatus = checklist?.status ?? "draft";
    const isApproved = checklistStatus === "approved";
    const body = `
      <h1 class="doc-title">GEN AI Usage Assessment Checklist</h1>
      <div class="doc-subtitle">
        ${dsr.tracking_id.replace("DSR", "AICK")} &nbsp;·&nbsp; ${dsr.project_name} &nbsp;·&nbsp; ${dsr.tracking_id.split("-")[1]}
        &nbsp;·&nbsp; ${pdfStatusBadge(isApproved ? "approved" : checklist?.status ?? "draft")}
      </div>

      <div class="section">
        <div class="section-title">Assessment Information</div>
        <div class="grid2">
          ${pdfField("Project Name", dsr.project_name)}
          ${pdfField("Customer / Client", dsr.recipient)}
          ${pdfField("Sharing Start Date", formatDate(dsr.duration_start))}
          ${pdfField("Sharing End Date", formatDate(dsr.duration_end))}
        </div>
        <p style="font-size:8.5pt;color:#718096;margin-top:6px">
          Instructions: Please fill the checkbox with "Yes/No" based on assessment condition and leave any remarks if criteria are not met.
          This assessment checklist form only be used for this project.
        </p>
      </div>

      ${approvalRows ? `<div class="section">
        <div class="section-title">Approval Timeline</div>
        <ol class="tl-list">${approvalRows}</ol>
      </div>` : ""}

      <div class="section">
        <div class="section-title">GEN AI Protection Checklist</div>
        <table>
          <thead>
            <tr>
              <th style="width:70px">Area</th>
              <th>Assessment</th>
              <th style="width:56px;text-align:center">Risk Level</th>
              <th style="width:140px">Risk Mitigation</th>
              <th style="width:54px;text-align:center">Status</th>
              <th style="width:110px">Remarks</th>
            </tr>
          </thead>
          <tbody>${tableRows}</tbody>
        </table>
      </div>

      ${signOffHtml}
    `;

    printA4(`${dsr.tracking_id} — AI Assessment Checklist`, body);
  }

  if (isLoading) return <DetailSkeleton />;
  if (!dsr) return <div className="py-20 text-center text-surface-500">Request not found.</div>;
  if (!dsr.is_ai_use) return <div className="py-20 text-center text-surface-500">This DSR is not marked as AI use.</div>;

  const checklist = dsr.ai_checklist;
  const checklistStatus = checklist?.status ?? "draft";
  const isDraft = checklistStatus === "draft";
  const isApproved = checklistStatus === "approved";

  const activeDraft = draft ?? emptyDraft();
  const complete = isAIChecklistComplete(activeDraft);
  const docNumber = dsr.tracking_id.replace("DSR", "AICK");

  const aickApprovals = [...(checklist?.approvals ?? [])].sort((a, b) => a.step_order - b.step_order);

  const statusBadgeVariant =
    checklistStatus === "approved"    ? "approved" :
    checklistStatus === "rejected"    ? "rejected" :
    checklistStatus === "submitted" || checklistStatus === "under_review" ? "warning" :
    "draft";

  const statusBadgeLabel =
    checklistStatus === "approved"    ? "Approved" :
    checklistStatus === "rejected"    ? "Rejected" :
    checklistStatus === "submitted"   ? "Submitted" :
    checklistStatus === "under_review"? "Under Review" :
    "In Progress";

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-start gap-3 pb-3 border-b border-slate-200">
        <button onClick={() => router.back()}
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 text-slate-600">
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono font-bold text-slate-900 text-base">{docNumber}</span>
                <Badge variant={statusBadgeVariant} className="text-[10px]">{statusBadgeLabel}</Badge>
                <Badge variant="warning" className="text-[10px]">AI Use</Badge>
              </div>
              <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1 truncate">{dsr.project_name}</h1>
              <p className="text-xs text-slate-500 font-mono">GEN AI Usage Assessment Checklist</p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
          <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium" onClick={handleExportPDF}>
            <Download className="h-3.5 w-3.5 mr-1" /> Export PDF
          </Button>
          {isDraft && (
            editing ? (
              <>
                <Button variant="secondary" size="sm" className="h-7.5 text-xs font-medium" onClick={handleCancel} disabled={saveMutation.isPending || submitMutation.isPending}>
                  <X className="h-3.5 w-3.5 mr-1" /> Cancel
                </Button>
                <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium" onClick={handleSaveAsDraft} loading={saveMutation.isPending}>
                  <Save className="h-3.5 w-3.5 mr-1" /> Save as Draft
                </Button>
                <Button
                  size="sm"
                  className="h-7.5 text-xs font-medium"
                  onClick={handleSubmit}
                  loading={submitMutation.isPending}
                  disabled={!complete}
                  title={!complete ? "Complete all assessment items and sign-off fields before submitting" : "Submit for approval"}
                >
                  <Send className="h-3.5 w-3.5 mr-1" /> Submit
                </Button>
              </>
            ) : (
              <>
                <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium" onClick={() => setEditing(true)}>
                  <Pencil className="h-3.5 w-3.5 mr-1" /> Edit
                </Button>
                <Button
                  size="sm"
                  className="h-7.5 text-xs font-medium"
                  onClick={handleSubmit}
                  loading={submitMutation.isPending}
                  disabled={!complete}
                  title={!complete ? "Complete all assessment items and sign-off fields before submitting" : "Submit for approval"}
                >
                  <Send className="h-3.5 w-3.5 mr-1" /> Submit
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
        const activeStep = aickApprovals.find((a) => a.status === "requested");
        if (!activeStep) return null;
        const userCanAction = canAction(activeStep.approver_id);
        return (
          <div className="rounded-md border border-amber-200 bg-amber-50/70 p-3.5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 font-mono">
            <div className="flex items-center gap-2.5">
              <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse shrink-0" />
              <div>
                <p className="text-xs font-semibold text-slate-900">
                  {userCanAction ? "Action Required: " : "Pending Review: "}
                  {AICK_STEP_LABELS[activeStep.step_order] ?? `Step ${activeStep.step_order}`} Pending Approval
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

      {/* Amber banner when draft and incomplete */}
      {isDraft && !complete && (
        <div className="px-3.5 py-2.5 rounded-md bg-amber-50 border border-amber-200 text-xs text-amber-800 font-mono">
          Complete all assessment items and sign-off fields (excluding e-signatures) before submitting. Only &ldquo;Save as Draft&rdquo; is available until then.
        </div>
      )}

      <div className="space-y-4">
        {/* Assessment Info */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Assessment Information</CardTitle>
          </CardHeader>
          <CardContent className="pt-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3.5 text-xs">
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project ID</p>
                <button onClick={openProjectModal}
                  className="font-mono font-medium text-slate-900 hover:text-slate-700 hover:underline text-left">
                  {dsr.project_code ?? dsr.project_id}
                </button>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">DSR ID</p>
                <button onClick={openDSRModal}
                  className="font-mono font-medium text-slate-900 hover:text-slate-700 hover:underline text-left">
                  {dsr.tracking_id}
                </button>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project Name</p>
                <p className="font-medium text-slate-900">{dsr.project_name}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Customer / Client</p>
                <p className="font-medium text-slate-900">{dsr.recipient}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing Start Date</p>
                <p className="font-mono font-medium text-slate-900">{formatDate(dsr.duration_start)}</p>
              </div>
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing End Date</p>
                <p className="font-mono font-medium text-slate-900">{formatDate(dsr.duration_end)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Approval Timeline */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Approval Timeline</CardTitle>
          </CardHeader>
          <CardContent className="pt-4">
            <ol className="relative border-l border-slate-200 space-y-4 ml-3">
              {aickApprovals.map((step) => {
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
                      {AICK_STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
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
                    <p className="text-[10px] text-slate-400 font-mono mt-0.5">Actioned on {formatDateTime(step.actioned_at)}</p>
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
              {aickApprovals.length === 0 && (
                <li className="ml-3.5 text-xs text-slate-400 italic font-mono">No approval steps configured yet.</li>
              )}
            </ol>
          </CardContent>
        </Card>

        {/* Checklist Table */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100 flex items-center justify-between">
            <div>
              <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">GEN AI Protection Checklist</CardTitle>
              <p className="text-xs text-slate-500 mt-0.5">
                Instructions: Fill the status with "Yes/No" based on assessment condition and record remarks if criteria are not met.
              </p>
            </div>
            {isApproved && (
              <Badge variant="success" className="text-[10px]">Approved</Badge>
            )}
          </CardHeader>
          <CardContent className="p-0">
            {/* Table header */}
            <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 bg-slate-50 border-b border-slate-200 px-4 py-2">
              <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">Assessment</p>
              <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono text-center">Risk Level</p>
              <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">Risk Mitigation</p>
              <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono text-center">Status</p>
              <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">Remarks</p>
            </div>

            {AI_ASSESSMENT_TEMPLATE.map((area) => (
              <div key={area.area}>
                <div className="bg-slate-100/60 px-4 py-1.5 border-b border-slate-200">
                  <span className="text-xs font-semibold font-mono text-slate-800">{area.area}</span>
                </div>
                {area.items.map((item, idx) => {
                  const val = activeDraft.items[item.id] ?? { status: null, remarks: "" };
                  const hasError = showErrors && !val.status;
                  return (
                    <div
                      key={item.id}
                      className={`px-4 py-2.5 border-b border-slate-100 ${idx === area.items.length - 1 ? "border-slate-200" : ""}`}
                    >
                      <div className="lg:hidden space-y-2">
                        <p className="text-xs text-slate-800">{item.assessment}</p>
                        <div className="flex items-center gap-2">
                          <span className={`inline-block px-1.5 py-0.5 rounded-md text-[10px] font-mono font-semibold ${riskBadgeClass(item.risk_level)}`}>
                            {item.risk_level}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 leading-relaxed"><span className="font-medium text-slate-600">Mitigation: </span>{item.mitigation}</p>
                        <div className="flex items-start gap-2">
                          <StatusSelect value={val.status} onChange={(v) => setItem(item.id, "status", v)}
                            disabled={!editing} hasError={hasError} />
                          <RemarksTextarea value={val.remarks} onChange={(v) => setItem(item.id, "remarks", v)} disabled={!editing} />
                        </div>
                      </div>

                      <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 items-start">
                        <p className="text-xs text-slate-800 leading-snug">{item.assessment}</p>
                        <div className="flex justify-center pt-0.5">
                          <span className={`inline-block px-1.5 py-0.5 rounded-md text-[10px] font-mono font-semibold ${riskBadgeClass(item.risk_level)}`}>
                            {item.risk_level}
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 leading-relaxed">{item.mitigation}</p>
                        <div className="flex justify-center pt-0.5">
                          <StatusSelect value={val.status} onChange={(v) => setItem(item.id, "status", v)}
                            disabled={!editing} hasError={hasError} />
                        </div>
                        <RemarksTextarea value={val.remarks} onChange={(v) => setItem(item.id, "remarks", v)} disabled={!editing} />
                      </div>
                    </div>
                  );
                })}
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Sign Off */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <div>
              <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Sign Off</CardTitle>
              <p className="text-xs text-slate-500 mt-0.5">Complete all fields and draw signatures to finalise the assessment</p>
            </div>
          </CardHeader>
          <CardContent className="pt-4">
            <SignOffSection
              value={activeDraft.sign_off}
              onChange={setSignOff}
              disabled={!editing}
              showErrors={showErrors}
              activeApprovalStep={aickApprovals.find(a => a.status === "requested")?.step_order}
              isSuperAdmin={currentUser?.is_super_admin ?? false}
            />
          </CardContent>
        </Card>

        {/* Error summary */}
        {showErrors && !complete && (
          <p className="text-xs text-rose-700 bg-rose-50 border border-rose-200 rounded-md px-3 py-2 font-mono">
            Some required fields are still incomplete. All implementation status fields and sign-off details are required before submitting.
          </p>
        )}
      </div>

      {/* Project Detail Modal */}
      {showProjectModal && (
        <DetailModal
          code={project?.project_code ?? dsr.project_code}
          title={project?.project_name ?? dsr.project_name}
          onClose={() => setShowProjectModal(false)}
          loading={!project}
        >
          {project && (
            <ProjectDetailCards project={project} users={users} owners={owners} />
          )}
        </DetailModal>
      )}
      {/* DSR Detail Modal */}
      {showDSRModal && (
        <DetailModal
          code={dsr.tracking_id}
          title={dsr.project_name}
          onClose={() => setShowDSRModal(false)}
        >
          <DsrDetailCards dsr={dsr} />
        </DetailModal>
      )}
    </div>
  );
}
