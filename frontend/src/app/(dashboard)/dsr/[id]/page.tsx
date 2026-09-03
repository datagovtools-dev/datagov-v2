"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Check, CheckCircle2, Download, Lock, MessageSquare, Pencil, Save, X } from "lucide-react";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { DetailModal } from "@/components/details/DetailModal";
import { ProjectDetailCards } from "@/components/details/ProjectDetailView";
import { formatDate, formatDateTime } from "@/lib/utils";
import { printA4, pdfField, pdfBadge, pdfStatusBadge } from "@/lib/exportPdf";

// ── Types ─────────────────────────────────────────────────────────────────────

interface DSRApproval {
  id: string; approver_id?: string | null; step_order: number; approver_role: string; approver_name: string;
  status: string; comments: string | null; actioned_at: string | null;
}

interface AIChecklist {
  id: string;
  checklist_json: Record<string, any>;
  validated_by: string | null;
  validated_at: string | null;
}

interface DSRDetail {
  id: string; tracking_id: string; project_id: string; project_code: string | null; project_name: string; requester_id: string;
  dataset_name: string; recipient: string; purpose: string; is_ai_use: boolean;
  duration_start: string; duration_end: string; project_end_date: string | null; status: string;
  created_at: string; updated_at: string;
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

interface UserOption { id: string; full_name: string; email: string; position?: string | null }
interface OwnerRecord { role_type: string; full_name: string; email: string }

type StatusVariant = "draft" | "pending" | "in-review" | "approved" | "rejected" | "done" | "default";

function statusVariant(s: string): StatusVariant {
  const m: Record<string, StatusVariant> = {
    draft: "draft", submitted: "pending", under_review: "in-review",
    approved: "approved", rejected: "rejected", executed: "done", archived: "default",
  };
  return m[s] ?? "default";
}

function statusLabel(s: string) {
  return s.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

const STEP_LABELS: Record<number, string> = {
  1: "PIC Data Compliance Approval",
  2: "DM Approval",
  3: "SME Sign Off",
  4: "Client Sign Off",
};

// ── Checklist template definition ─────────────────────────────────────────────

type ChecklistItem = {
  id: string;
  label: string;
  note?: string;
  sub?: { id: string; label: string }[];
};

type ChecklistSection = {
  section: string;
  title: string;
  aiOnly?: boolean;
  items: ChecklistItem[];
};

const CHECKLIST_TEMPLATE: ChecklistSection[] = [
  {
    section: "A", title: "Interest Protection",
    items: [
      {
        id: "A_i",
        label: "Will this data sharing infringe the following commercial interest(s) of the Business Unit(s) sharing the data?",
        sub: [
          { id: "A_i_1", label: "Loss in revenue due to cannibalization" },
          { id: "A_i_2", label: "Damage to relationship with customers" },
          { id: "A_i_3", label: "Other commercial interest(s)" },
        ],
      },
      {
        id: "A_ii",
        label: "Are there potentially any of the following commercial secret(s) included in the requested data?",
        sub: [
          { id: "A_ii_1", label: "Highly confidential partnerships" },
          { id: "A_ii_2", label: "Patent information" },
          { id: "A_ii_3", label: "M&A deals" },
          { id: "A_ii_4", label: "Other commercial secret(s)" },
        ],
      },
    ],
  },
  {
    section: "B", title: "Customer Data & Insights Sharing Consent",
    items: [
      { id: "B_i",   label: "Are the data & insights requested sensitive?", note: "Examples: personal data related to religion, health, physical/mental conditions, sexual life, personal financial data." },
      { id: "B_ii",  label: "Are there any mitigation steps in place if sensitive data & insights are used?", note: "Name, phone number, email, VIN, police reg. number need to be mitigated." },
      { id: "B_iii", label: "Are the data & insights requested considered personal data?" },
      { id: "B_iv",  label: "If personal data need to be shared, has written consent for sharing been obtained?", note: "If consent is unclear, Legal Team should be consulted before proceeding." },
      { id: "B_v",   label: "If personal data need to be used for use case development, has written consent for research been obtained?", note: "Ensure no customers have ended customer consent. If unclear, consult Legal Team." },
      { id: "B_vi",  label: "Are the data and analytics processes located within the BU's analytics environment with limited access to the working team?", note: "Highly recommended to use BU's analytics environment and provide limited access." },
    ],
  },
  {
    section: "C", title: "Regulatory Compliance",
    items: [
      {
        id: "C_i",
        label: "Are there prevailing regulations that will be violated for the Business Units / Astra International if the data & insights are shared?",
        note: "If violation of regulations is unclear, Legal Team should be consulted before proceeding.",
        sub: [
          { id: "C_i_1", label: "Industry-specific laws" },
          { id: "C_i_2", label: "Data protection laws" },
          { id: "C_i_3", label: "Internal regulations and policies" },
        ],
      },
    ],
  },
  {
    section: "D", title: "AI Compliance", aiOnly: true,
    items: [
      { id: "D_i", label: "Is the data analysis process carried out using artificial intelligence technology?", note: "If Yes, explain the reason/condition. Internally please complete the Excel AI Checklist Assessment." },
    ],
  },
];

// ── Validation ────────────────────────────────────────────────────────────────

function getChecklistErrors(draft: Record<string, any>, isAiUse: boolean): Set<string> {
  const errors = new Set<string>();
  for (const section of CHECKLIST_TEMPLATE.filter((s) => !s.aiOnly || isAiUse)) {
    for (const item of section.items) {
      const ids = item.sub ? item.sub.map((s) => s.id) : [item.id];
      for (const iid of ids) {
        const v = draft[iid] ?? {};
        if (!v.answer) errors.add(iid);
        if (!v.remarks?.trim()) errors.add(`${iid}_r`);
      }
    }
  }
  const so = draft.sign_off ?? {};
  if (!so.approved) errors.add("so_approved");
  if (!so.prepared_by?.trim()) errors.add("so_prepared_by");
  if (!so.prepared_position?.trim()) errors.add("so_prepared_position");
  if (!so.acknowledged_by?.trim()) errors.add("so_acknowledged_by");
  if (!so.acknowledged_position?.trim()) errors.add("so_acknowledged_position");
  return errors;
}

// ── Checklist sub-components ──────────────────────────────────────────────────

function AnswerSelect({
  value, onChange, disabled, hasError,
}: { value: string | null; onChange: (v: string) => void; disabled?: boolean; hasError?: boolean }) {
  return (
    <select
      value={value ?? ""}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled}
      className={`input-base text-sm w-20 ${
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

function RemarksInput({
  value, onChange, disabled, hasError,
}: { value: string; onChange: (v: string) => void; disabled?: boolean; hasError?: boolean }) {
  const ref = React.useRef<HTMLTextAreaElement>(null);
  React.useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    requestAnimationFrame(() => {
      el.style.height = "auto";
      el.style.height = `${el.scrollHeight}px`;
    });
  }, [value]);
  return (
    <textarea
      ref={ref}
      rows={1}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled}
      placeholder={hasError ? 'Required — use "-" if none' : "Remarks…"}
      className={`input-base text-sm flex-1 min-w-0 resize-none overflow-hidden leading-snug py-1.5 ${hasError ? "border-red-500 ring-1 ring-red-400 placeholder:text-red-400" : ""}`}
    />
  );
}

// ── ChecklistSection component ────────────────────────────────────────────────

function ChecklistSectionBlock({
  section, draft, onChange, disabled, showErrors,
}: {
  section: ChecklistSection;
  draft: Record<string, any>;
  onChange: (id: string, field: "answer" | "remarks", value: string) => void;
  disabled?: boolean;
  showErrors?: boolean;
}) {
  function getVal(id: string) {
    return draft[id] ?? { answer: null, remarks: "" };
  }

  return (
    <div>
      <h3 className="text-sm font-semibold text-surface-800 bg-surface-100 px-3 py-2 rounded-t-md border border-surface-200">
        {section.section}. {section.title}
      </h3>
      <div className="border border-t-0 border-surface-200 rounded-b-md divide-y divide-surface-100">
        {section.items.map((item) =>
          item.sub ? (
            <div key={item.id} className="px-3 py-2">
              <p className="text-sm font-medium text-surface-700 mb-1">{item.label}</p>
              {item.note && <p className="text-xs text-surface-400 italic mb-2 leading-relaxed">{item.note}</p>}
              {item.sub.map((sub) => {
                const v = getVal(sub.id);
                return (
                  <div key={sub.id} className="pl-3 border-l-2 border-surface-200 mb-2 space-y-1.5">
                    <p className="text-xs font-medium text-surface-700">{sub.label}</p>
                    <div className="flex items-start gap-2">
                      <AnswerSelect value={v.answer} onChange={(val) => onChange(sub.id, "answer", val)}
                        disabled={disabled} hasError={showErrors && !v.answer} />
                      <RemarksInput value={v.remarks} onChange={(val) => onChange(sub.id, "remarks", val)}
                        disabled={disabled} hasError={showErrors && !v.remarks?.trim()} />
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div key={item.id} className="px-3 py-2.5 space-y-2">
              <p className="text-sm font-medium text-surface-700">{item.label}</p>
              {item.note && (
                <p className="text-xs text-surface-400 italic leading-relaxed">{item.note}</p>
              )}
              <div className="flex items-start gap-2">
                <AnswerSelect value={getVal(item.id).answer} onChange={(val) => onChange(item.id, "answer", val)}
                  disabled={disabled} hasError={showErrors && !getVal(item.id).answer} />
                <RemarksInput value={getVal(item.id).remarks} onChange={(val) => onChange(item.id, "remarks", val)}
                  disabled={disabled} hasError={showErrors && !getVal(item.id).remarks?.trim()} />
              </div>
            </div>
          )
        )}
      </div>
    </div>
  );
}

// ── SignaturePad ──────────────────────────────────────────────────────────────

function SignaturePad({
  value, onSign, onClear, disabled,
}: {
  value: string | null;
  onSign: (sig: string) => void;
  onClear: () => void;
  disabled?: boolean;
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
    if ("touches" in e) {
      return { x: e.touches[0].clientX - rect.left, y: e.touches[0].clientY - rect.top };
    }
    return { x: (e as React.MouseEvent).clientX - rect.left, y: (e as React.MouseEvent).clientY - rect.top };
  }

  function onMouseDown(e: React.MouseEvent<HTMLCanvasElement>) {
    drawing.current = true;
    lastPos.current = getPos(e);
  }
  function onTouchStart(e: React.TouchEvent<HTMLCanvasElement>) {
    e.preventDefault();
    drawing.current = true;
    lastPos.current = getPos(e);
  }
  function stroke(e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) {
    if (!drawing.current) return;
    const canvas = canvasRef.current!;
    const ctx = canvas.getContext("2d")!;
    const pos = getPos(e);
    ctx.strokeStyle = "#1e293b";
    ctx.lineWidth = 1.8;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.beginPath();
    ctx.moveTo(lastPos.current!.x, lastPos.current!.y);
    ctx.lineTo(pos.x, pos.y);
    ctx.stroke();
    lastPos.current = pos;
  }
  function endDraw() {
    if (!drawing.current) return;
    drawing.current = false;
    lastPos.current = null;
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
        <button type="button" onClick={clearCanvas}
          className="text-xs text-red-500 hover:text-red-700 mt-0.5 hover:underline">
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
          onMouseDown={onMouseDown} onMouseMove={stroke}
          onMouseUp={endDraw} onMouseLeave={endDraw}
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

// ── SignOff component ─────────────────────────────────────────────────────────

function SignOffBlock({
  value, onChange, disabled, showErrors, acknowledgedReadOnly, activeApprovalStep, isSuperAdmin,
}: {
  value: Record<string, string>;
  onChange: (field: string, val: string) => void;
  disabled?: boolean;
  showErrors?: boolean;
  acknowledgedReadOnly?: boolean;
  activeApprovalStep?: number;
  isSuperAdmin?: boolean;
}) {
  function err(field: string) {
    return showErrors && !value[field]?.trim() ? "border-red-500 ring-1 ring-red-400" : "";
  }

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
    <div>
      <h3 className="text-sm font-semibold text-surface-800 bg-surface-100 px-3 py-2 rounded-t-md border border-surface-200">
        Sign Off
      </h3>
      <div className="border border-t-0 border-surface-200 rounded-b-md p-3 space-y-3">
        {/* Approved */}
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
            <option value="" disabled hidden>Yes/No</option>
            <option value="Yes">Yes</option>
            <option value="No">No</option>
          </select>
        </div>

        {/* Two-column: Prepared By / Acknowledged By */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Prepared By */}
          <div className="space-y-2">
            <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">
              Prepared By{" "}
              <span className="text-surface-400 normal-case font-normal">(client representative · required)</span>
            </p>
            <input type="text" placeholder="Full name" value={value.prepared_by ?? ""} disabled={disabled}
              onChange={(e) => onChange("prepared_by", e.target.value)}
              className={`input-base text-sm w-full ${err("prepared_by")}`} />
            <input type="text" placeholder="Position only (e.g. Head of Analytics)" value={value.prepared_position ?? ""} disabled={disabled}
              onChange={(e) => onChange("prepared_position", e.target.value)}
              className={`input-base text-sm w-full ${err("prepared_position")}`} />
            <div>
              <p className="text-xs text-surface-500 mb-1">Signature</p>
              <SignaturePad
                value={value.prepared_signature || null}
                onSign={(sig) => handleSign("prepared", sig)}
                onClear={() => handleClear("prepared")}
                disabled={disabled || (!isSuperAdmin && activeApprovalStep !== 4)}
              />
              {!disabled && !isSuperAdmin && activeApprovalStep !== 4 && (
                <p className="text-xs text-surface-400 flex items-center gap-1 mt-1">
                  <Lock className="h-3 w-3" /> Available at Client Sign Off step
                </p>
              )}
            </div>
            {value.prepared_signature && value.prepared_date && (
              <p className="text-xs text-surface-400">Signed on: <span className="font-medium text-surface-600">{value.prepared_date}</span></p>
            )}
          </div>

          {/* Acknowledged By */}
          <div className="space-y-2">
            <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">
              Acknowledged By{" "}
              {acknowledgedReadOnly
                ? <span className="text-primary-500 normal-case font-normal">(auto-filled · Project SME)</span>
                : <span className="text-surface-400 normal-case font-normal">(internal project SME)</span>
              }
            </p>
            <input type="text" placeholder="Full name" value={value.acknowledged_by ?? ""}
              disabled={disabled || acknowledgedReadOnly}
              onChange={(e) => onChange("acknowledged_by", e.target.value)}
              className={`input-base text-sm w-full ${disabled || acknowledgedReadOnly ? "bg-surface-50 text-surface-600" : err("acknowledged_by")}`} />
            <input type="text" placeholder="Position only (e.g. Senior Data Scientist)" value={value.acknowledged_position ?? ""}
              disabled={disabled || acknowledgedReadOnly}
              onChange={(e) => onChange("acknowledged_position", e.target.value)}
              className={`input-base text-sm w-full ${disabled || acknowledgedReadOnly ? "bg-surface-50 text-surface-600" : err("acknowledged_position")}`} />
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
                  <Lock className="h-3 w-3" /> Available at SME Sign Off step
                </p>
              )}
            </div>
            {value.acknowledged_signature && value.acknowledged_date && (
              <p className="text-xs text-surface-400">Signed on: <span className="font-medium text-surface-600">{value.acknowledged_date}</span></p>
            )}
          </div>
        </div>

        {/* Remarks */}
        <div>
          <p className="text-xs font-medium text-surface-700 mb-1">Remarks</p>
          <textarea rows={2} placeholder="Additional remarks…" value={value.remarks ?? ""} disabled={disabled}
            onChange={(e) => onChange("remarks", e.target.value)}
            className="input-base text-sm w-full resize-none" />
        </div>
      </div>
    </div>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────

export default function DSRDetailPage() {
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
  const [form, setForm] = React.useState<Record<string, string | boolean>>({});
  const [serverError, setServerError] = React.useState("");

  // Checklist draft mirrors checklist_json + sign_off
  const [checklistDraft, setChecklistDraft] = React.useState<Record<string, any> | null>(null);
  const [showErrors, setShowErrors] = React.useState(false);
  const [showProjectModal, setShowProjectModal] = React.useState(false);

  const { data: dsr, isLoading } = useQuery<DSRDetail>({
    queryKey: ["dsr", id],
    queryFn: () => api.get<DSRDetail>(`/dsr/${id}`),
  });

  const { data: projectDetail, refetch: refetchProject } = useQuery<ProjectDetail>({
    queryKey: ["project-detail-modal", dsr?.project_id],
    queryFn: () => api.get<ProjectDetail>(`/projects/${dsr!.project_id}`),
    enabled: !!dsr?.project_id,
    staleTime: 0,
  });

  const { data: allUsers = [], refetch: refetchUsers } = useQuery<UserOption[]>({
    queryKey: ["users-options-modal"],
    queryFn: () => api.get<UserOption[]>("/rbac/users/options"),
    enabled: !!dsr,
    staleTime: 0,
  });

  const { data: owners = [], refetch: refetchOwners } = useQuery<OwnerRecord[]>({
    queryKey: ["project-owner-stewards-modal", dsr?.project_id],
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

  function resolveUser(id: string | null): { name: string; email: string | null; position: string | null } {
    if (!id) return { name: "—", email: null, position: null };
    const u = allUsers.find(u => u.id === id);
    return u ? { name: u.full_name, email: u.email, position: u.position ?? null } : { name: "—", email: null, position: null };
  }

  const dataSteward = owners.find(o => o.role_type === "lead_business_steward") ?? owners.find(o => o.role_type === "business_steward");
  const dataOwner = owners.find(o => o.role_type === "data_owner");

  function startEdit() {
    if (!dsr || isSigned) return;
    setForm({
      dataset_name: dsr.dataset_name, recipient: dsr.recipient,
      purpose: dsr.purpose, is_ai_use: dsr.is_ai_use,
      duration_start: dsr.duration_start, duration_end: dsr.duration_end,
    });
    // Always sync acknowledged_by from project SME
    if (projectDetail?.sme_id) {
      const sme = resolveUser(projectDetail.sme_id);
      if (sme.name !== "—") {
        setChecklistDraft((prev) => {
          const current = prev ?? {};
          const so = { ...(current.sign_off ?? {}) };
          so.acknowledged_by = sme.name;
          so.acknowledged_position = sme.position ?? "";
          return { ...current, sign_off: so };
        });
      }
    }
    setEditing(true);
    setServerError("");
  }

  function set(key: string, val: string | boolean) {
    setForm((f) => ({ ...f, [key]: val }));
  }

  // Initialize checklist draft when DSR loads
  React.useEffect(() => {
    if (dsr?.ai_checklist) {
      const cj = dsr.ai_checklist.checklist_json ?? {};
      const so = { ...(cj.sign_off ?? {}) };
      if (!so.approved) so.approved = "Yes";
      setChecklistDraft({ ...cj, sign_off: so });
    }
  }, [dsr?.ai_checklist?.id]);

  function setChecklistItem(itemId: string, field: "answer" | "remarks", value: string) {
    setChecklistDraft((prev) => {
      const current = prev ?? {};
      return {
        ...current,
        [itemId]: { ...(current[itemId] ?? { answer: null, remarks: "" }), [field]: value || (field === "answer" ? null : "") },
      };
    });
  }

  function setSignOff(field: string, value: string) {
    setChecklistDraft((prev) => {
      const current = prev ?? {};
      return { ...current, sign_off: { ...(current.sign_off ?? {}), [field]: value } };
    });
  }

  const [isSaving, setIsSaving] = React.useState(false);

  const updateMutation = useMutation({
    mutationFn: () =>
      api.put(`/dsr/${id}`, {
        dataset_name: form.dataset_name,
        recipient: form.recipient,
        purpose: form.purpose,
        is_ai_use: form.is_ai_use,
        duration_start: form.duration_start,
        duration_end: form.duration_end,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["dsrs"] });
    },
    onError: (e: any) => setServerError(e.message),
  });

  const checklistMutation = useMutation({
    mutationFn: (jsonPayload?: Record<string, any>) =>
      api.put(`/dsr/${id}/checklist`, {
        checklist_json: jsonPayload ?? activeDraft,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dsr", id] }),
    onError: (e: any) => setServerError(e.message),
  });

  const submitMutation = useMutation({
    mutationFn: () => {
      toast.loading("Submitting DSR for approval workflow...", { id: "submit-dsr" });
      return api.post(`/dsr/${id}/submit`, {});
    },
    onSuccess: () => {
      toast.success("DSR submitted successfully for review!", { id: "submit-dsr" });
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["dsrs"] });
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to submit DSR", { id: "submit-dsr" });
      setServerError(e.message);
    },
  });

  const [approvalComment, setApprovalComment] = React.useState<Record<number, string>>({});

  const approvalMutation = useMutation({
    mutationFn: ({ step, action }: { step: number; action: "approve" | "reject" }) => {
      const label = action === "approve" ? "Approving" : "Rejecting";
      toast.loading(`${label} Step ${step}...`, { id: "action-approval" });
      return api.post(`/dsr/${id}/approvals/${step}`, {
        action,
        comments: approvalComment[step] ?? "",
      });
    },
    onSuccess: (_, variables) => {
      const msg = variables.action === "approve" ? "Step approved successfully!" : "Request rejected.";
      toast.success(msg, { id: "action-approval" });
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["dsrs"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setApprovalComment((prev) => ({ ...prev, [variables.step]: "" }));
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to action approval", { id: "action-approval" });
    },
  });

  async function handleSave(currentDraft: Record<string, any>, aiUse: boolean) {
    setIsSaving(true);
    toast.loading("Saving DSR draft changes...", { id: "save-dsr" });

    try {
      const promises: Promise<any>[] = [];

      // Save top-level DSR details if in edit mode
      if (editing) {
        promises.push(
          api.put(`/dsr/${id}`, {
            dataset_name: form.dataset_name,
            recipient: form.recipient,
            purpose: form.purpose,
            is_ai_use: form.is_ai_use,
            duration_start: form.duration_start,
            duration_end: form.duration_end,
          })
        );
      }

      // Save checklist JSON state
      promises.push(
        api.put(`/dsr/${id}/checklist`, {
          checklist_json: currentDraft,
        })
      );

      await Promise.all(promises);

      await qc.invalidateQueries({ queryKey: ["dsr", id] });
      await qc.invalidateQueries({ queryKey: ["dsrs"] });

      toast.success("DSR Draft saved successfully!", { id: "save-dsr" });
      setEditing(false);
      setShowErrors(false);
    } catch (e: any) {
      toast.error(e.message || "Failed to save draft", { id: "save-dsr" });
      setServerError(e.message);
    } finally {
      setIsSaving(false);
    }
  }

  function handleCancel() {
    setEditing(false);
    if (dsr?.ai_checklist) setChecklistDraft(dsr.ai_checklist.checklist_json ?? {});
    setShowErrors(false);
  }

  if (isLoading) return <DetailSkeleton />;
  if (!dsr) return <div className="py-20 text-center text-surface-500">Request not found.</div>;

  const checklist = dsr.ai_checklist;
  const activeDraft = checklistDraft ?? checklist?.checklist_json ?? {};
  const signOffDraft = (activeDraft.sign_off ?? {}) as Record<string, string>;
  const isChecklistDirty = JSON.stringify(activeDraft) !== JSON.stringify(checklist?.checklist_json ?? {});

  // Lock editing once at least one signature has been saved to the server
  const savedSignOff = checklist?.checklist_json?.sign_off ?? {};
  const isSigned = !!(savedSignOff.prepared_signature || savedSignOff.acknowledged_signature);

  // Submit is only allowed when the saved checklist is fully filled
  const isChecklistComplete = getChecklistErrors(checklist?.checklist_json ?? {}, dsr.is_ai_use).size === 0;

  function handleExportPDF() {
    if (!dsr) return;
    const cj = checklist?.checklist_json ?? {};
    const so = (cj.sign_off ?? {}) as Record<string, string>;

    const effectiveApprovals = [...dsr.approvals].sort((a, b) => a.step_order - b.step_order);

    const approvalRows = effectiveApprovals
      .map((s) => {
        const displayName = s.step_order === 4 ? (so.prepared_by || s.approver_name) : s.approver_name;
        const label = STEP_LABELS[s.step_order] ?? `Step ${s.step_order}`;
        const statusBadge =
          s.status === "approved" ? pdfBadge("Approved", "approved") :
          s.status === "rejected" ? pdfBadge("Rejected", "rejected") :
          pdfBadge("Requested", "pending");
        return `<li>
          <span class="tl-step">${s.step_order}.</span>
          <span>
            <div class="tl-label">${label} ${statusBadge}</div>
            <div class="tl-meta">${displayName || "—"}${s.actioned_at ? " · " + formatDateTime(s.actioned_at) : ""}</div>
          </span>
        </li>`;
      }).join("");

    const checklistSections = CHECKLIST_TEMPLATE
      .filter((s) => !s.aiOnly || dsr.is_ai_use)
      .map((sec) => {
        const rows = sec.items.flatMap((item) => {
          if (item.sub) {
            const parentRow = `<tr><td colspan="3" style="font-weight:600;background:#EDF2F7">${item.label}</td></tr>`;
            const subRows = item.sub.map((sub) => {
              const v = cj[sub.id] ?? {};
              return `<tr><td style="padding-left:16px">${sub.label}</td>
                <td style="width:60px;text-align:center">${v.answer || "—"}</td>
                <td>${v.remarks || "—"}</td></tr>`;
            }).join("");
            return parentRow + subRows;
          }
          const v = cj[item.id] ?? {};
          return `<tr><td>${item.label}</td>
            <td style="width:60px;text-align:center">${v.answer || "—"}</td>
            <td>${v.remarks || "—"}</td></tr>`;
        }).join("");
        return `<div class="section">
          <div class="section-title">${sec.section}. ${sec.title}</div>
          <table><thead><tr><th>Item</th><th>Answer</th><th>Remarks</th></tr></thead>
          <tbody>${rows}</tbody></table>
        </div>`;
      }).join("");

    const signOffHtml = `<div class="section">
      <div class="section-title">Sign Off</div>
      <div class="grid2" style="margin-bottom:8px">
        ${pdfField("Approved?", so.approved)}
      </div>
      <div class="sig-grid">
        <div class="sig-box">
          <div class="sig-title">Prepared By</div>
          <div class="sig-name">${so.prepared_by || "—"}</div>
          <div class="tl-meta">${so.prepared_position || ""}</div>
          ${so.prepared_signature
            ? `<img class="sig-image" src="${so.prepared_signature}" alt="signature" />`
            : `<div class="sig-line"></div>`}
          <div class="sig-date">${so.prepared_date ? "Signed: " + so.prepared_date : "Not yet signed"}</div>
        </div>
        <div class="sig-box">
          <div class="sig-title">Acknowledged By</div>
          <div class="sig-name">${so.acknowledged_by || "—"}</div>
          <div class="tl-meta">${so.acknowledged_position || ""}</div>
          ${so.acknowledged_signature
            ? `<img class="sig-image" src="${so.acknowledged_signature}" alt="signature" />`
            : `<div class="sig-line"></div>`}
          <div class="sig-date">${so.acknowledged_date ? "Signed: " + so.acknowledged_date : "Not yet signed"}</div>
        </div>
      </div>
    </div>`;

    const body = `
      <h1 class="doc-title">Data Sharing Request</h1>
      <div class="doc-subtitle">
        ${dsr.tracking_id} &nbsp;·&nbsp; ${dsr.project_name} &nbsp;·&nbsp; ${dsr.tracking_id.split("-")[1]}
        &nbsp;·&nbsp; ${pdfStatusBadge(dsr.status, isSigned)}
        ${dsr.is_ai_use ? "&nbsp;" + pdfBadge("AI Use", "ai") : ""}
      </div>

      <div class="section">
        <div class="section-title">Request Details</div>
        <div class="grid2">
          ${pdfField("Project Name", dsr.project_name)}
          ${pdfField("Customer / Client", dsr.recipient)}
          ${pdfField("Dataset / Data Name", dsr.dataset_name)}
          ${pdfField("AI / ML Use", dsr.is_ai_use ? "Yes" : "No")}
          ${pdfField("Sharing Start Date", formatDate(dsr.duration_start))}
          ${pdfField("Sharing End Date", dsr.project_end_date ? formatDate(dsr.project_end_date) : formatDate(dsr.duration_end))}
          ${pdfField("Purpose / Justification", dsr.purpose, true)}
        </div>
      </div>

      <div class="section">
        <div class="section-title">Approval Timeline</div>
        <ul class="timeline">${approvalRows}</ul>
      </div>

      ${checklist ? checklistSections : ""}
      ${checklist ? signOffHtml : ""}
    `;

    printA4(`${dsr.tracking_id} — DSR`, body);
  }

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
                <span className="font-mono font-bold text-slate-900 text-sm">{dsr.tracking_id}</span>
                {isSigned
                  ? <Badge variant="success" className="text-[10px]">Signed &amp; Locked</Badge>
                  : <Badge variant={statusVariant(dsr.status)} className="text-[10px]">{statusLabel(dsr.status)}</Badge>
                }
                {dsr.is_ai_use && <Badge variant="warning" className="text-[10px]">AI Use</Badge>}
              </div>
              <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1 truncate">{dsr.project_name}</h1>
              <p className="text-xs text-slate-500 font-mono mt-0.5">
                Created {formatDateTime(dsr.created_at)} · Last updated {formatDateTime(dsr.updated_at)}
              </p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium" onClick={handleExportPDF}>
                <Download className="h-3.5 w-3.5 mr-1" /> Export PDF
              </Button>
              {!isSigned && (
                editing ? (
                  <>
                    <Button variant="outline" size="sm" className="h-7.5 text-xs" onClick={handleCancel}>
                      <X className="h-3.5 w-3.5 mr-1" /> Cancel
                    </Button>
                    <Button
                      size="sm"
                      className="h-7.5 text-xs font-medium"
                      onClick={() => handleSave(activeDraft, dsr.is_ai_use)}
                      loading={isSaving || updateMutation.isPending || checklistMutation.isPending}
                    >
                      <Save className="h-3.5 w-3.5 mr-1" /> Save as Draft
                    </Button>
                  </>
                ) : (
                  <>
                    {dsr.status === "draft" && (
                      <Button
                        size="sm"
                        className="h-7.5 text-xs font-medium"
                        onClick={() => submitMutation.mutate()}
                        loading={submitMutation.isPending}
                        disabled={!isChecklistComplete}
                        title={!isChecklistComplete ? "Complete all checklist sections and sign-off fields before submitting" : undefined}
                      >
                        Submit
                      </Button>
                    )}
                    <Button size="sm" className="h-7.5 text-xs font-medium" onClick={startEdit}>
                      <Pencil className="h-3.5 w-3.5 mr-1" /> Edit
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
        const activeStep = dsr.approvals.find((a) => a.status === "requested");
        if (!activeStep) return null;
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

      {dsr.status === "draft" && !isChecklistComplete && (
        <div className="rounded-md bg-amber-50 border border-amber-200 px-3.5 py-2 text-xs text-amber-800 font-mono">
          Complete all checklist sections A–D and sign-off fields (excluding e-signatures) before submitting. Only &ldquo;Save as Draft&rdquo; is available until then.
        </div>
      )}

      <div className="space-y-4">
        {/* Request Details */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Request Details</CardTitle>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            {editing ? (
              <>
                <Input label="Dataset / Data Name" value={form.dataset_name as string}
                  onChange={(e) => set("dataset_name", e.target.value)} required className="h-8 text-xs" />
                <Input label="Customer / Client" value={form.recipient as string}
                  onChange={(e) => set("recipient", e.target.value)} required className="h-8 text-xs" />
                <Input label="Sharing Start Date" type="date" value={form.duration_start as string}
                  onChange={(e) => set("duration_start", e.target.value)} required className="h-8 text-xs font-mono" />
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-semibold text-slate-700">Sharing End Date</label>
                  <p className="text-xs font-mono font-medium text-slate-800 py-1.5">{dsr.project_end_date ? formatDate(dsr.project_end_date) : formatDate(dsr.duration_end)}</p>
                  <p className="text-[10px] text-slate-400 font-mono">Auto-filled from project end date</p>
                </div>
                <div className="md:col-span-2 flex flex-col gap-1">
                  <label className="text-xs font-semibold text-slate-700">Purpose / Justification <span className="text-rose-500">*</span></label>
                  <textarea value={form.purpose as string} onChange={(e) => set("purpose", e.target.value)}
                    rows={3} className="input-base resize-none w-full text-xs font-sans" placeholder="Describe why this data needs to be shared…" />
                </div>
                <div className="md:col-span-2 flex items-center gap-2.5">
                  <input id="is_ai_use_edit" type="checkbox" checked={form.is_ai_use as boolean}
                    onChange={(e) => set("is_ai_use", e.target.checked)}
                    className="h-4 w-4 rounded-md border-slate-300 text-slate-900 focus:ring-slate-400" />
                  <label htmlFor="is_ai_use_edit" className="text-xs font-medium text-slate-700">
                    This data will be used for AI / ML purposes
                  </label>
                </div>
              </>
            ) : (
              <>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project ID</p>
                  <button
                    onClick={openProjectModal}
                    className="font-mono text-xs font-medium text-slate-900 hover:underline text-left"
                  >
                    {dsr.project_code ?? dsr.project_id}
                  </button>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project Name</p>
                  <p className="text-xs font-medium text-slate-900">{dsr.project_name}</p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Customer / Client</p>
                  <p className="text-xs font-medium text-slate-900">{dsr.recipient}</p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">AI / ML Use</p>
                  {dsr.is_ai_use ? <Badge variant="warning" className="text-[10px]">Yes — AI Use</Badge> : <span className="text-xs font-mono text-slate-500">No</span>}
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing Start Date</p>
                  <p className="text-xs font-mono font-medium text-slate-900">{formatDate(dsr.duration_start)}</p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing End Date</p>
                  <p className="text-xs font-mono font-medium text-slate-900">{dsr.project_end_date ? formatDate(dsr.project_end_date) : formatDate(dsr.duration_end)}</p>
                </div>
                <div className="md:col-span-2">
                  <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Purpose / Justification</p>
                  <p className="text-xs text-slate-800 leading-relaxed">{dsr.purpose}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {serverError && (
          <div className="rounded-md bg-rose-50 border border-rose-200 p-3 text-xs font-medium text-rose-700 flex items-center justify-between font-mono">
            <div className="flex items-center gap-2">
              <span className="flex h-4 w-4 items-center justify-center rounded-md bg-rose-200 text-rose-800 shrink-0 text-[10px] font-bold">!</span>
              <span>
                {serverError.includes("500") || serverError.includes("HTTP 500")
                  ? "Terjadi kendala saat menyimpan draf ke database. Sistem telah mengoptimalkan koneksi penyimpanan, silakan coba klik Simpan Draf kembali."
                  : serverError}
              </span>
            </div>
            <button
              type="button"
              onClick={() => setServerError("")}
              className="text-rose-500 hover:text-rose-700 p-1"
            >
              <X className="h-3 w-3" />
            </button>
          </div>
        )}

        {/* Approval Timeline */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Approval Timeline</CardTitle>
          </CardHeader>
          <CardContent className="pt-4">
            <ol className="relative border-l border-slate-200 space-y-4 ml-3">
              {[...dsr.approvals].sort((a, b) => a.step_order - b.step_order).map((step) => {
                const savedPreparedBy = checklist?.checklist_json?.sign_off?.prepared_by as string | undefined;
                const displayName = step.step_order === 4 ? (savedPreparedBy || step.approver_name) : step.approver_name;
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
                  {displayName && (
                    <p className={`text-xs ${step.status === "pending" ? "text-slate-400" : "text-slate-600"}`}>
                      {displayName}
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
                        Waiting for {displayName || step.approver_name || "designated approver"} to review and take action.
                      </div>
                    )
                  )}
                </li>
              );
              })}
            </ol>
          </CardContent>
        </Card>

        {/* Data & Insights Sharing Evaluation Checklist */}
        {checklist && (
          <Card>
            <CardHeader className="pb-3 border-b border-slate-100">
              <div className="flex items-center justify-between flex-wrap gap-2">
                <div>
                  <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Data &amp; Insights Sharing Evaluation Checklist</CardTitle>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Instructions: Fill the checkbox with "Yes" / "No" based on data condition and leave remarks if criteria are not met.
                  </p>
                </div>
                {checklist.validated_at && (
                  <Badge variant="success" className="text-[10px]">Signed off {formatDate(checklist.validated_at)}</Badge>
                )}
              </div>
            </CardHeader>
            <CardContent className="pt-4 space-y-4">
              {CHECKLIST_TEMPLATE.filter((s) => !s.aiOnly || dsr.is_ai_use).map((section) => (
                <ChecklistSectionBlock
                  key={section.section}
                  section={section}
                  draft={activeDraft}
                  onChange={setChecklistItem}
                  disabled={!editing}
                  showErrors={showErrors}
                />
              ))}

              {/* Sign Off */}
              <SignOffBlock
                value={signOffDraft}
                onChange={setSignOff}
                disabled={!editing}
                showErrors={showErrors}
                acknowledgedReadOnly={editing}
                activeApprovalStep={dsr.approvals.find(a => a.status === "requested")?.step_order}
                isSuperAdmin={currentUser?.is_super_admin ?? false}
              />

              {/* Validation error summary */}
              {showErrors && (() => {
                const errCount = getChecklistErrors(activeDraft, dsr.is_ai_use).size;
                return errCount > 0 ? (
                  <p className="text-xs text-rose-700 bg-rose-50 border border-rose-200 rounded-md px-3 py-2 font-mono">
                    {errCount} required field{errCount !== 1 ? "s" : ""} still incomplete. All checkboxes and remarks are required — use &quot;-&quot; if there is nothing to add.
                  </p>
                ) : null;
              })()}

            </CardContent>
          </Card>
        )}
      </div>

      {/* Project Detail Modal */}
      {showProjectModal && (
        <DetailModal
          code={projectDetail?.project_code ?? dsr.project_code}
          title={projectDetail?.project_name ?? dsr.project_name}
          onClose={() => setShowProjectModal(false)}
          loading={!projectDetail}
        >
          {projectDetail && (
            <ProjectDetailCards project={projectDetail} users={allUsers} owners={owners} />
          )}
        </DetailModal>
      )}
    </div>
  );
}
