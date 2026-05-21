"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Download, Lock, Pencil, Save, X, Send } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
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
  step_order: number;
  approver_role: string;
  approver_name: string;
  status: string;
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
  id: string; step_order: number; approver_role: string; approver_name: string;
  status: string; actioned_at: string | null;
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

function SignOffSection({ value, onChange, disabled, showErrors, activeApprovalStep }: {
  value: Record<string, string>;
  onChange: (field: string, val: string) => void;
  disabled?: boolean;
  showErrors?: boolean;
  activeApprovalStep?: number;
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
              disabled={disabled || activeApprovalStep !== 2}
            />
            {!disabled && activeApprovalStep !== 2 && (
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
              disabled={disabled || activeApprovalStep !== 3}
            />
            {!disabled && activeApprovalStep !== 3 && (
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

  function openProjectModal() {
    setShowProjectModal(true);
    refetchProject();
    refetchUsers();
  }

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

  if (isLoading) return <div className="py-20 text-center text-surface-400">Loading…</div>;
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
    <div>
      {/* Header */}
      <div className="flex items-start gap-3 mb-6">
        <button onClick={() => router.back()}
          className="inline-flex items-center justify-center h-9 w-9 rounded-md hover:bg-surface-100 shrink-0 mt-0.5">
          <ArrowLeft className="h-4 w-4" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-start justify-between gap-2">
            <div className="min-w-0">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono font-bold text-surface-800 text-lg">{docNumber}</span>
                <Badge variant={statusBadgeVariant}>{statusBadgeLabel}</Badge>
                <Badge variant="warning">AI Use</Badge>
              </div>
              <h1 className="mt-0.5 truncate">{dsr.project_name}</h1>
              <p className="text-sm text-surface-500">GEN AI Usage Assessment Checklist</p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
          <Button variant="outline" size="sm" onClick={handleExportPDF}>
            <Download className="h-4 w-4 mr-1" /> Export PDF
          </Button>
          {isDraft && (
            editing ? (
              <>
                <Button variant="secondary" onClick={handleCancel} disabled={saveMutation.isPending || submitMutation.isPending}>
                  <X className="h-4 w-4 mr-1" /> Cancel
                </Button>
                <Button variant="outline" onClick={handleSaveAsDraft} loading={saveMutation.isPending}>
                  <Save className="h-4 w-4 mr-1" /> Save as Draft
                </Button>
                <Button
                  onClick={handleSubmit}
                  loading={submitMutation.isPending}
                  disabled={!complete}
                  title={!complete ? "Complete all assessment items and sign-off fields before submitting" : "Submit for approval"}
                >
                  <Send className="h-4 w-4 mr-1" /> Submit
                </Button>
              </>
            ) : (
              <>
                <Button variant="outline" onClick={() => setEditing(true)}>
                  <Pencil className="h-4 w-4 mr-1" /> Edit
                </Button>
                <Button
                  onClick={handleSubmit}
                  loading={submitMutation.isPending}
                  disabled={!complete}
                  title={!complete ? "Complete all assessment items and sign-off fields before submitting" : "Submit for approval"}
                >
                  <Send className="h-4 w-4 mr-1" /> Submit
                </Button>
              </>
            )
          )}
            </div>
          </div>
        </div>
      </div>

      {/* Amber banner when draft and incomplete */}
      {isDraft && !complete && (
        <div className="mb-4 px-4 py-3 rounded-md bg-amber-50 border border-amber-200 text-sm text-amber-800">
          Complete all assessment items and sign-off fields (excluding e-signatures) before submitting. Only &ldquo;Save as Draft&rdquo; is available until then.
        </div>
      )}

      <div className="space-y-5">
        {/* Assessment Info */}
        <Card>
          <CardHeader><CardTitle>Assessment Information</CardTitle></CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Project ID</p>
                <button onClick={openProjectModal}
                  className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                  {dsr.project_code ?? dsr.project_id}
                </button>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">DSR ID</p>
                <button onClick={openDSRModal}
                  className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                  {dsr.tracking_id}
                </button>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Project Name</p>
                <p className="font-medium">{dsr.project_name}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Customer / Client</p>
                <p className="font-medium">{dsr.recipient}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p>
                <p className="font-medium">{formatDate(dsr.duration_start)}</p>
              </div>
              <div>
                <p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p>
                <p className="font-medium">{formatDate(dsr.duration_end)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Approval Timeline */}
        <Card>
          <CardHeader><CardTitle>Approval Timeline</CardTitle></CardHeader>
          <CardContent>
            <ol className="relative border-l border-surface-200 space-y-5 ml-3">
              {aickApprovals.map((step) => (
                <li key={step.id} className="ml-4">
                  <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                    step.status === "approved"  ? "bg-green-500" :
                    step.status === "rejected"  ? "bg-red-500" :
                    step.status === "requested" ? "bg-primary-500" :
                    "bg-surface-300"
                  }`} />
                  <p className={`text-sm font-semibold ${step.status === "pending" ? "text-surface-400" : "text-surface-800"}`}>
                    {AICK_STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
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
                     step.status === "pending"   ? "Not Yet" :
                     "Requested"}
                  </Badge>
                  {step.actioned_at && (
                    <p className="text-xs text-surface-400 mt-0.5">{formatDateTime(step.actioned_at)}</p>
                  )}
                </li>
              ))}
              {aickApprovals.length === 0 && (
                <li className="ml-4 text-sm text-surface-400 italic">No approval steps configured yet.</li>
              )}
            </ol>
          </CardContent>
        </Card>

        {/* Checklist Table */}
        <Card>
          <CardHeader>
            <div>
              <CardTitle>GEN AI Protection Checklist</CardTitle>
              <p className="text-xs text-surface-400 mt-0.5 italic">
                Instructions: Please fill the checkbox with "Yes/No" based on assessment condition and leave any remarks if criteria are not met. This assessment checklist form only be used for this project.
              </p>
            </div>
            {isApproved && (
              <Badge variant="approved">Approved</Badge>
            )}
          </CardHeader>
          <CardContent className="p-0">
            {/* Table header */}
            <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 bg-surface-50 border-b border-surface-200 px-4 py-2">
              <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Assessment</p>
              <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide text-center">Risk Level</p>
              <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Risk Mitigation</p>
              <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide text-center">Status</p>
              <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Remarks</p>
            </div>

            {AI_ASSESSMENT_TEMPLATE.map((area) => (
              <div key={area.area}>
                <div className="bg-surface-100 px-4 py-2 border-b border-surface-200">
                  <span className="text-sm font-semibold text-surface-700">{area.area}</span>
                </div>
                {area.items.map((item, idx) => {
                  const val = activeDraft.items[item.id] ?? { status: null, remarks: "" };
                  const hasError = showErrors && !val.status;
                  return (
                    <div
                      key={item.id}
                      className={`px-4 py-3 border-b border-surface-100 ${idx === area.items.length - 1 ? "border-surface-200" : ""}`}
                    >
                      <div className="lg:hidden space-y-2">
                        <p className="text-sm text-surface-700">{item.assessment}</p>
                        <div className="flex items-center gap-2">
                          <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${riskBadgeClass(item.risk_level)}`}>
                            {item.risk_level}
                          </span>
                        </div>
                        <p className="text-xs text-surface-500 leading-relaxed"><span className="font-medium text-surface-600">Mitigation: </span>{item.mitigation}</p>
                        <div className="flex items-start gap-2">
                          <StatusSelect value={val.status} onChange={(v) => setItem(item.id, "status", v)}
                            disabled={!editing} hasError={hasError} />
                          <RemarksTextarea value={val.remarks} onChange={(v) => setItem(item.id, "remarks", v)} disabled={!editing} />
                        </div>
                      </div>

                      <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 items-start">
                        <p className="text-sm text-surface-700 leading-snug">{item.assessment}</p>
                        <div className="flex justify-center pt-0.5">
                          <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${riskBadgeClass(item.risk_level)}`}>
                            {item.risk_level}
                          </span>
                        </div>
                        <p className="text-xs text-surface-500 leading-relaxed">{item.mitigation}</p>
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
          <CardHeader>
            <div>
              <CardTitle>Sign Off</CardTitle>
              <p className="text-xs text-surface-400 mt-0.5">Complete all fields and draw signatures to finalise the assessment</p>
            </div>
          </CardHeader>
          <CardContent>
            <SignOffSection
              value={activeDraft.sign_off}
              onChange={setSignOff}
              disabled={!editing}
              showErrors={showErrors}
              activeApprovalStep={aickApprovals.find(a => a.status === "requested")?.step_order}
            />
          </CardContent>
        </Card>

        {/* Error summary */}
        {showErrors && !complete && (
          <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-md px-3 py-2">
            Some required fields are still incomplete. All implementation status fields and sign-off details are required before submitting.
          </p>
        )}
      </div>

      {/* Project Detail Modal */}
      {showProjectModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowProjectModal(false)} />
          <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
              <div>
                <p className="text-xs text-surface-400 font-mono">{project?.project_code ?? dsr.project_code}</p>
                <h2 className="text-base font-semibold text-surface-900">{project?.project_name ?? dsr.project_name}</h2>
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
                    <div><p className="text-xs text-surface-400 mb-0.5">Monetized</p><p className="font-medium">{project.is_monetized ? "Yes" : "No"}</p></div>
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
                      ["Metadata Officer",        project.metadata_officer_id],
                      ["Data Quality Officer",    project.dq_officer_id],
                      ["PIC Data Compliance",     project.pic_data_compliance_id],
                    ] as [string, string | null][]).map(([label, uid]) => {
                      const u = resolveUser(uid);
                      return (
                        <div key={label}>
                          <p className="text-xs text-surface-400 mb-0.5">{label}</p>
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

      {/* DSR Detail Modal */}
      {showDSRModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowDSRModal(false)} />
          <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
              <div>
                <p className="text-xs text-surface-400 font-mono">{dsr.tracking_id}</p>
                <h2 className="text-base font-semibold text-surface-900">{dsr.project_name}</h2>
              </div>
              <button onClick={() => setShowDSRModal(false)}
                className="h-8 w-8 flex items-center justify-center rounded-md hover:bg-surface-100 text-surface-500">✕</button>
            </div>
            <div className="px-6 py-5 space-y-6 text-sm">
              <div>
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Request Details</p>
                <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                  <div><p className="text-xs text-surface-400 mb-0.5">Project ID</p><p className="font-mono font-medium">{dsr.project_code ?? dsr.project_id}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Status</p><p className="font-medium capitalize">{dsr.status.replace(/_/g, " ")}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Customer / Client</p><p className="font-medium">{dsr.recipient}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">AI / ML Use</p><p className="font-medium">{dsr.is_ai_use ? "Yes" : "No"}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p><p className="font-medium">{formatDate(dsr.duration_start)}</p></div>
                  <div><p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p><p className="font-medium">{formatDate(dsr.duration_end)}</p></div>
                  <div className="col-span-2"><p className="text-xs text-surface-400 mb-0.5">Purpose / Justification</p><p className="text-surface-700 leading-relaxed">{dsr.purpose}</p></div>
                </div>
              </div>
              <div>
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">DSR Approval Timeline</p>
                <ol className="relative border-l border-surface-200 space-y-5 ml-3">
                  {[...dsr.approvals].sort((a, b) => a.step_order - b.step_order).map((step) => (
                    <li key={step.id} className="ml-4">
                      <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                        step.status === "approved" ? "bg-green-500" : step.status === "rejected" ? "bg-red-500" : "bg-surface-300"
                      }`} />
                      <p className="text-sm font-medium text-surface-800">{DSR_STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}</p>
                      <p className="text-xs text-surface-500">{step.approver_name || <span className="italic text-surface-400">Not yet actioned</span>}</p>
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

              {dsr.ai_checklist && (() => {
                const cj = dsr.ai_checklist.checklist_json ?? {};
                const so = (cj.sign_off ?? {}) as Record<string, string>;
                return (
                  <>
                    <div>
                      <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Data & Insights Sharing Evaluation Checklist</p>
                      <div className="space-y-3">
                        {DSR_CHECKLIST_TEMPLATE.filter(s => !s.aiOnly || dsr.is_ai_use).map((sec) => (
                          <div key={sec.section}>
                            <p className="text-xs font-semibold text-surface-700 bg-surface-100 px-2 py-1.5 rounded-t border border-surface-200">
                              {sec.section}. {sec.title}
                            </p>
                            <div className="border border-t-0 border-surface-200 rounded-b divide-y divide-surface-100">
                              {sec.items.map((item) => {
                                const rows = item.sub
                                  ? item.sub.map(s => ({ id: s.id, label: s.label, val: cj[s.id] ?? {} }))
                                  : [{ id: item.id, label: item.label, val: cj[item.id] ?? {} }];
                                return (
                                  <div key={item.id} className="px-3 py-2 space-y-1.5">
                                    {item.sub && <p className="text-xs font-medium text-surface-600">{item.label}</p>}
                                    {rows.map(r => (
                                      <div key={r.id} className={`flex items-start gap-2 ${item.sub ? "pl-2 border-l-2 border-surface-200" : ""}`}>
                                        <span className={`shrink-0 inline-block px-2 py-0.5 rounded text-xs font-semibold mt-0.5 ${
                                          r.val.answer === "Yes" ? "bg-green-100 text-green-700" :
                                          r.val.answer === "No"  ? "bg-red-100 text-red-700" :
                                          "bg-surface-100 text-surface-400"
                                        }`}>{r.val.answer || "—"}</span>
                                        <div>
                                          {!item.sub && <p className="text-xs text-surface-600">{r.label}</p>}
                                          {item.sub && <p className="text-xs text-surface-600">{r.label}</p>}
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

                    <div>
                      <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Sign Off</p>
                      <div className="space-y-3">
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-surface-500 w-24 shrink-0">Approved?</span>
                          <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${
                            so.approved === "Yes" ? "bg-green-100 text-green-700" :
                            so.approved === "No"  ? "bg-red-100 text-red-700" : "bg-surface-100 text-surface-400"
                          }`}>{so.approved || "—"}</span>
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                          <div className="space-y-1">
                            <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Prepared By</p>
                            <p className="font-medium text-sm">{so.prepared_by || "—"}</p>
                            <p className="text-xs text-surface-400">{so.prepared_position || ""}</p>
                            {so.prepared_signature
                              ? <img src={so.prepared_signature} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                              : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                            {so.prepared_date && <p className="text-xs text-surface-400">Signed: {so.prepared_date}</p>}
                          </div>
                          <div className="space-y-1">
                            <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Acknowledged By</p>
                            <p className="font-medium text-sm">{so.acknowledged_by || "—"}</p>
                            <p className="text-xs text-surface-400">{so.acknowledged_position || ""}</p>
                            {so.acknowledged_signature
                              ? <img src={so.acknowledged_signature} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                              : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                            {so.acknowledged_date && <p className="text-xs text-surface-400">Signed: {so.acknowledged_date}</p>}
                          </div>
                        </div>
                        {so.remarks && (
                          <div><p className="text-xs text-surface-500 mb-0.5">Remarks</p><p className="text-xs text-surface-700 italic">{so.remarks}</p></div>
                        )}
                      </div>
                    </div>
                  </>
                );
              })()}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
