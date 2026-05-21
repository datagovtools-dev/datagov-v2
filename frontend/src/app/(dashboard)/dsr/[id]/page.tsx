"use client";

import * as React from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Download, Lock, Pencil, Save, X } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { formatDate, formatDateTime } from "@/lib/utils";
import { printA4, pdfField, pdfBadge, pdfStatusBadge } from "@/lib/exportPdf";

// ── Types ─────────────────────────────────────────────────────────────────────

interface DSRApproval {
  id: string; step_order: number; approver_role: string; approver_name: string;
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
  value, onChange, disabled, showErrors, acknowledgedReadOnly, activeApprovalStep,
}: {
  value: Record<string, string>;
  onChange: (field: string, val: string) => void;
  disabled?: boolean;
  showErrors?: boolean;
  acknowledgedReadOnly?: boolean;
  activeApprovalStep?: number;
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
                disabled={disabled || activeApprovalStep !== 4}
              />
              {!disabled && activeApprovalStep !== 4 && (
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
                disabled={disabled || activeApprovalStep !== 3}
              />
              {!disabled && activeApprovalStep !== 3 && (
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

  function openProjectModal() {
    setShowProjectModal(true);
    refetchProject();
    refetchUsers();
  }

  function resolveUser(id: string | null): { name: string; email: string | null; position: string | null } {
    if (!id) return { name: "—", email: null, position: null };
    const u = allUsers.find(u => u.id === id);
    return u ? { name: u.full_name, email: u.email, position: u.position ?? null } : { name: "—", email: null, position: null };
  }

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

  const updateMutation = useMutation({
    mutationFn: () => api.put(`/dsr/${id}`, {
      dataset_name: form.dataset_name, recipient: form.recipient,
      purpose: form.purpose, is_ai_use: form.is_ai_use,
      duration_start: form.duration_start, duration_end: form.duration_end,
    }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["dsrs"] });
      setEditing(false);
    },
    onError: (e: any) => setServerError(e.message),
  });

  const checklistMutation = useMutation({
    mutationFn: () => api.put(`/dsr/${id}/checklist`, { checklist_json: checklistDraft }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["dsr", id] }),
  });

  const submitMutation = useMutation({
    mutationFn: () => api.post(`/dsr/${id}/submit`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["dsr", id] });
      qc.invalidateQueries({ queryKey: ["dsrs"] });
    },
    onError: (e: any) => setServerError(e.message),
  });

  function handleSave(currentDraft: Record<string, any>, aiUse: boolean) {
    if (isChecklistDirty) {
      const errors = getChecklistErrors(currentDraft, aiUse);
      if (errors.size > 0) { setShowErrors(true); return; }
    }
    setShowErrors(false);
    if (editing) updateMutation.mutate();
    if (isChecklistDirty) checklistMutation.mutate();
  }

  function handleCancel() {
    setEditing(false);
    if (dsr?.ai_checklist) setChecklistDraft(dsr.ai_checklist.checklist_json ?? {});
    setShowErrors(false);
  }

  if (isLoading) return <div className="py-20 text-center text-surface-400">Loading…</div>;
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
                <span className="font-mono font-bold text-surface-800 text-lg">{dsr.tracking_id}</span>
                {isSigned
                  ? <Badge variant="approved">Signed &amp; Locked</Badge>
                  : <Badge variant={statusVariant(dsr.status)}>{statusLabel(dsr.status)}</Badge>
                }
                {dsr.is_ai_use && <Badge variant="warning">AI Use</Badge>}
              </div>
              <h1 className="mt-0.5 truncate">{dsr.project_name}</h1>
              <p className="text-sm text-surface-500">
                Created {formatDateTime(dsr.created_at)} · Last updated {formatDateTime(dsr.updated_at)}
              </p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
          <Button variant="outline" size="sm" onClick={handleExportPDF}>
            <Download className="h-4 w-4 mr-1" /> Export PDF
          </Button>
          {!isSigned && (
            editing ? (
              <>
                <Button variant="secondary" onClick={handleCancel}>
                  <X className="h-4 w-4 mr-1" /> Cancel
                </Button>
                <Button
                  onClick={() => handleSave(activeDraft, dsr.is_ai_use)}
                  loading={updateMutation.isPending || checklistMutation.isPending}
                >
                  <Save className="h-4 w-4 mr-1" /> Save as Draft
                </Button>
              </>
            ) : (
              <>
                {dsr.status === "draft" && (
                  <Button
                    onClick={() => submitMutation.mutate()}
                    loading={submitMutation.isPending}
                    disabled={!isChecklistComplete}
                    title={!isChecklistComplete ? "Complete all checklist sections and sign-off fields before submitting" : undefined}
                  >
                    Submit
                  </Button>
                )}
                <Button variant="outline" onClick={startEdit}>
                  <Pencil className="h-4 w-4 mr-1" /> Edit
                </Button>
              </>
            )
          )}
            </div>
          </div>
        </div>
      </div>

      {dsr.status === "draft" && !isChecklistComplete && (
        <div className="rounded-md bg-amber-50 border border-amber-200 px-4 py-2 text-sm text-amber-700 mb-4">
          Complete all checklist sections A–D and sign-off fields (excluding e-signatures) before submitting. Only &ldquo;Save as Draft&rdquo; is available until then.
        </div>
      )}

      <div className="space-y-5">
        {/* Request Details */}
        <Card>
          <CardHeader><CardTitle>Request Details</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {editing ? (
              <>
                <Input label="Dataset / Data Name" value={form.dataset_name as string}
                  onChange={(e) => set("dataset_name", e.target.value)} required />
                <Input label="Customer / Client" value={form.recipient as string}
                  onChange={(e) => set("recipient", e.target.value)} required />
                <Input label="Sharing Start Date" type="date" value={form.duration_start as string}
                  onChange={(e) => set("duration_start", e.target.value)} required />
                <div className="flex flex-col gap-1">
                  <label className="text-sm font-medium text-surface-700">Sharing End Date</label>
                  <p className="text-sm font-medium text-surface-800 py-1.5">{dsr.project_end_date ? formatDate(dsr.project_end_date) : formatDate(dsr.duration_end)}</p>
                  <p className="text-xs text-surface-400">Auto-filled from project end date</p>
                </div>
                <div className="md:col-span-2 flex flex-col gap-1">
                  <label className="text-sm font-medium text-surface-700">Purpose / Justification <span className="text-red-500">*</span></label>
                  <textarea value={form.purpose as string} onChange={(e) => set("purpose", e.target.value)}
                    rows={3} className="input-base resize-none w-full" placeholder="Describe why this data needs to be shared…" />
                </div>
                <div className="md:col-span-2 flex items-center gap-3">
                  <input id="is_ai_use_edit" type="checkbox" checked={form.is_ai_use as boolean}
                    onChange={(e) => set("is_ai_use", e.target.checked)}
                    className="h-4 w-4 rounded border-surface-300 text-primary-600 focus:ring-primary-500" />
                  <label htmlFor="is_ai_use_edit" className="text-sm font-medium text-surface-700">
                    This data will be used for AI / ML purposes
                  </label>
                </div>
              </>
            ) : (
              <>
                <div>
                  <p className="text-xs text-surface-400 mb-0.5">Project ID</p>
                  <button
                    onClick={openProjectModal}
                    className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left"
                  >
                    {dsr.project_code ?? dsr.project_id}
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
                  <p className="text-xs text-surface-400 mb-0.5">AI / ML Use</p>
                  {dsr.is_ai_use ? <Badge variant="warning">Yes — AI Use</Badge> : <span className="text-surface-500">No</span>}
                </div>
                <div>
                  <p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p>
                  <p className="font-medium">{formatDate(dsr.duration_start)}</p>
                </div>
                <div>
                  <p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p>
                  <p className="font-medium">{dsr.project_end_date ? formatDate(dsr.project_end_date) : formatDate(dsr.duration_end)}</p>
                </div>
                <div className="md:col-span-2">
                  <p className="text-xs text-surface-400 mb-0.5">Purpose / Justification</p>
                  <p className="text-surface-800 leading-relaxed">{dsr.purpose}</p>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {serverError && (
          <p className="rounded-md bg-red-50 border border-red-200 px-4 py-2 text-sm text-red-600">{serverError}</p>
        )}


        {/* Approval Timeline */}
        <Card>
          <CardHeader><CardTitle>Approval Timeline</CardTitle></CardHeader>
          <CardContent>
            <ol className="relative border-l border-surface-200 space-y-6 ml-3">
              {[...dsr.approvals].sort((a, b) => a.step_order - b.step_order).map((step) => {
                const savedPreparedBy = checklist?.checklist_json?.sign_off?.prepared_by as string | undefined;
                const displayName = step.step_order === 4 ? (savedPreparedBy || step.approver_name) : step.approver_name;
                return (
                <li key={step.id} className="ml-4">
                  <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                    step.status === "approved" ? "bg-green-500" :
                    step.status === "rejected"  ? "bg-red-500" :
                    step.status === "pending"   ? "bg-surface-200" :
                    "bg-surface-300"
                  }`} />
                  <p className={`text-sm font-medium ${step.status === "pending" ? "text-surface-400" : "text-surface-800"}`}>
                    {STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
                  </p>
                  {displayName && (
                    <p className={`text-xs ${step.status === "pending" ? "text-surface-400" : "text-surface-500"}`}>
                      {displayName}
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
              );
              })}
            </ol>
          </CardContent>
        </Card>

        {/* Data & Insights Sharing Evaluation Checklist */}
        {checklist && (
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between flex-wrap gap-2">
                <div>
                  <CardTitle>Data & Insights Sharing Evaluation Checklist</CardTitle>
                  <p className="text-xs text-surface-400 mt-0.5">
                    Instructions: Fill the checkbox with "Yes" / "No" based on data condition and leave remarks if criteria are not met.
                  </p>
                </div>
                {checklist.validated_at && (
                  <Badge variant="approved">Signed off {formatDate(checklist.validated_at)}</Badge>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
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
              />

              {/* Validation error summary */}
              {showErrors && (() => {
                const errCount = getChecklistErrors(activeDraft, dsr.is_ai_use).size;
                return errCount > 0 ? (
                  <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-md px-3 py-2">
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
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowProjectModal(false)} />
          <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            {/* Modal header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
              <div>
                <p className="text-xs text-surface-400 font-mono">{projectDetail?.project_code ?? dsr.project_code}</p>
                <h2 className="text-base font-semibold text-surface-900">{projectDetail?.project_name ?? dsr.project_name}</h2>
              </div>
              <button onClick={() => setShowProjectModal(false)}
                className="h-8 w-8 flex items-center justify-center rounded-md hover:bg-surface-100 text-surface-500">
                ✕
              </button>
            </div>

            {!projectDetail ? (
              <p className="text-sm text-surface-400 text-center py-10">Loading…</p>
            ) : (
              <div className="px-6 py-5 space-y-6 text-sm">
                {/* Project Info */}
                <div>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Project Information</p>
                  <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">Customer / Client</p>
                      <p className="font-medium">{projectDetail.customer_name}</p>
                    </div>
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">Category</p>
                      <p className="font-medium">{projectDetail.project_category}</p>
                    </div>
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">Line of Business</p>
                      <p className="font-medium">{projectDetail.line_of_business ?? "—"}</p>
                    </div>
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">Year</p>
                      <p className="font-medium">{projectDetail.project_year}</p>
                    </div>
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">Start Date</p>
                      <p className="font-medium">{projectDetail.start_date ? formatDate(projectDetail.start_date) : "—"}</p>
                    </div>
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">End Date</p>
                      <p className="font-medium">{projectDetail.end_date ? formatDate(projectDetail.end_date) : "—"}</p>
                    </div>
                    <div>
                      <p className="text-xs text-surface-400 mb-0.5">Monetized</p>
                      <p className="font-medium">{projectDetail.is_monetized ? "Yes" : "No"}</p>
                    </div>
                    {projectDetail.use_case && (
                      <div className="col-span-2">
                        <p className="text-xs text-surface-400 mb-0.5">Use Case</p>
                        <p className="text-surface-700 leading-relaxed">{projectDetail.use_case}</p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Project Team */}
                <div>
                  <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide mb-3">Project Team</p>
                  <div className="grid grid-cols-2 gap-x-6 gap-y-3">
                    {([
                      ["Delivery Manager",       projectDetail.delivery_manager_id],
                      ["Project Manager",        projectDetail.project_manager_id],
                      ["Subject Matter Expert",  projectDetail.sme_id],
                      ["Data Governance Officer",projectDetail.dgo_id],
                      ["Metadata Officer",       projectDetail.metadata_officer_id],
                      ["Data Quality Officer",   projectDetail.dq_officer_id],
                      ["PIC Data Compliance",    projectDetail.pic_data_compliance_id],
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
    </div>
  );
}
