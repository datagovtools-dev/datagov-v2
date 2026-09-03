"use client";

import * as React from "react";
import { Badge } from "@/components/ui/Badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { formatDate, formatDateTime } from "@/lib/utils";

export interface AickApprovalLike {
  id: string;
  step_order: number;
  approver_name?: string | null;
  status: string;
  comments?: string | null;
  actioned_at: string | null;
}

export interface AickChecklistLike {
  status: string;
  validated_at?: string | null;
  checklist_json: Record<string, any>;
  approvals?: AickApprovalLike[];
}

export interface AickDsrLike {
  tracking_id: string;
  project_id: string;
  project_code: string | null;
  project_name: string;
  recipient: string;
  is_ai_use: boolean;
  duration_start: string | null;
  duration_end: string | null;
  project_end_date?: string | null;
  ai_checklist: AickChecklistLike | null;
}

export interface AickAreaLike {
  area: string;
  items: {
    id: string;
    assessment: string;
    risk_level: "HIGH" | "MEDIUM" | "LOW";
    mitigation?: string;
  }[];
}

const STEP_LABELS: Record<number, string> = {
  1: "PIC Data Compliance Approval",
  2: "DM Sign-off",
  3: "SME Sign-off",
};

function EmptyValue() {
  return <span className="text-slate-400 font-mono">-</span>;
}

function statusVariant(status: string) {
  if (status === "approved") return "success";
  if (status === "rejected") return "danger";
  return "default";
}

function statusLabel(status: string) {
  if (status === "approved") return "Approved";
  if (status === "rejected") return "Rejected";
  if (status === "pending") return "Not Yet";
  if (status === "requested") return "Requested";
  return status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function riskBadgeClass(level: "HIGH" | "MEDIUM" | "LOW") {
  return level === "HIGH" ? "bg-rose-50 text-rose-700 border border-rose-200" :
    level === "MEDIUM" ? "bg-amber-50 text-amber-700 border border-amber-200" :
    "bg-emerald-50 text-emerald-700 border border-emerald-200";
}

function StatusBadge({ value }: { value?: string | null }) {
  return (
    <span className={`inline-block px-1.5 py-0.5 rounded-md text-[10px] font-mono font-semibold ${
      value === "Yes" ? "bg-emerald-50 text-emerald-700 border border-emerald-200" :
      value === "No" ? "bg-rose-50 text-rose-700 border border-rose-200" :
      value === "In Progress" || value === "in_progress" ? "bg-amber-50 text-amber-700 border border-amber-200" :
      "bg-slate-100 text-slate-500 border border-slate-200"
    }`}>
      {value || "-"}
    </span>
  );
}

export function AickAssessmentInformationCard({
  dsr,
  docNumber,
  onProjectClick,
  onDsrClick,
}: {
  dsr: AickDsrLike;
  docNumber?: string;
  onProjectClick?: () => void;
  onDsrClick?: () => void;
}) {
  return (
    <Card>
      <CardHeader className="pb-3 border-b border-slate-100">
        <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Assessment Information</CardTitle>
      </CardHeader>
      <CardContent className="pt-4">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5 text-xs">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project ID</p>
            {onProjectClick ? (
              <button onClick={onProjectClick} className="font-mono font-medium text-slate-900 hover:text-slate-700 hover:underline text-left">
                {dsr.project_code ?? dsr.project_id}
              </button>
            ) : (
              <p className="font-mono font-medium text-slate-900">{dsr.project_code ?? dsr.project_id}</p>
            )}
          </div>
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">DSR ID</p>
            {onDsrClick ? (
              <button onClick={onDsrClick} className="font-mono font-medium text-slate-900 hover:text-slate-700 hover:underline text-left">
                {dsr.tracking_id}
              </button>
            ) : (
              <p className="font-mono font-medium text-slate-900">{dsr.tracking_id}</p>
            )}
          </div>
          {docNumber && (
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">AICK ID</p>
              <p className="font-mono font-medium text-slate-900">{docNumber}</p>
            </div>
          )}
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
            <p className="font-mono font-medium text-slate-900">{dsr.duration_start ? formatDate(dsr.duration_start) : <EmptyValue />}</p>
          </div>
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Sharing End Date</p>
            <p className="font-mono font-medium text-slate-900">{dsr.project_end_date ? formatDate(dsr.project_end_date) : dsr.duration_end ? formatDate(dsr.duration_end) : <EmptyValue />}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export function AickApprovalTimelineCard({ approvals }: { approvals: AickApprovalLike[] }) {
  return (
    <Card>
      <CardHeader className="pb-3 border-b border-slate-100">
        <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Approval Timeline</CardTitle>
      </CardHeader>
      <CardContent className="pt-4">
        <ol className="relative border-l border-slate-200 space-y-4 ml-3">
          {[...approvals].sort((a, b) => a.step_order - b.step_order).map((step) => (
            <li key={step.id} className="ml-3.5">
              <div className={`absolute -left-1 w-2.5 h-2.5 rounded-full border border-white ${
                step.status === "approved" ? "bg-emerald-600" :
                step.status === "rejected" ? "bg-rose-600" :
                step.status === "requested" ? "bg-slate-900" :
                "bg-slate-300"
              }`} />
              <p className={`text-xs font-semibold font-mono ${step.status === "pending" ? "text-slate-400" : "text-slate-900"}`}>
                {STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
              </p>
              {step.approver_name && (
                <p className={`text-xs ${step.status === "pending" ? "text-slate-400" : "text-slate-500"}`}>
                  {step.approver_name}
                </p>
              )}
              <Badge variant={statusVariant(step.status)} className="mt-1 text-[10px]">
                {statusLabel(step.status)}
              </Badge>
              {step.actioned_at && (
                <p className="text-[10px] text-slate-400 font-mono mt-0.5">{formatDateTime(step.actioned_at)}</p>
              )}
              {step.comments && (
                <p className="text-xs text-slate-600 italic font-mono mt-1 bg-slate-50 border border-slate-100 rounded p-1.5">&ldquo;{step.comments}&rdquo;</p>
              )}
            </li>
          ))}
          {approvals.length === 0 && (
            <li className="ml-3.5 text-xs text-slate-400 italic font-mono">No approval steps configured yet.</li>
          )}
        </ol>
      </CardContent>
    </Card>
  );
}

export function AickChecklistReadOnlyCard({
  areas,
  items,
  isApproved,
}: {
  areas: AickAreaLike[];
  items: Record<string, { status?: string | null; remarks?: string }>;
  isApproved?: boolean;
}) {
  return (
    <Card>
      <CardHeader className="pb-3 border-b border-slate-100 flex items-center justify-between">
        <div>
          <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">GEN AI Protection Checklist</CardTitle>
          <p className="text-xs text-slate-500 mt-0.5">
            Instructions: Form contains validated assessment conditions and recorded remarks for this project.
          </p>
        </div>
        {isApproved && <Badge variant="success" className="text-[10px]">Approved</Badge>}
      </CardHeader>
      <CardContent className="p-0">
        <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 bg-slate-50 border-b border-slate-200 px-4 py-2">
          <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">Assessment</p>
          <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono text-center">Risk Level</p>
          <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">Risk Mitigation</p>
          <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono text-center">Status</p>
          <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">Remarks</p>
        </div>

        {areas.map((area) => (
          <div key={area.area}>
            <div className="bg-slate-100/60 px-4 py-1.5 border-b border-slate-200">
              <span className="text-xs font-semibold font-mono text-slate-800">{area.area}</span>
            </div>
            {area.items.map((item, idx) => {
              const value = items[item.id] ?? {};
              return (
                <div key={item.id} className={`px-4 py-2.5 border-b border-slate-100 ${idx === area.items.length - 1 ? "border-slate-200" : ""}`}>
                  <div className="lg:hidden space-y-2">
                    <p className="text-xs text-slate-800">{item.assessment}</p>
                    <span className={`inline-block px-1.5 py-0.5 rounded-md text-[10px] font-mono font-semibold ${riskBadgeClass(item.risk_level)}`}>
                      {item.risk_level}
                    </span>
                    {item.mitigation && <p className="text-[11px] text-slate-500 leading-relaxed"><span className="font-medium text-slate-600">Mitigation: </span>{item.mitigation}</p>}
                    <div className="flex items-start gap-2">
                      <StatusBadge value={value.status} />
                      <p className="text-xs text-slate-400 italic font-mono">{value.remarks || "-"}</p>
                    </div>
                  </div>

                  <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 items-start">
                    <p className="text-xs text-slate-800 leading-snug">{item.assessment}</p>
                    <div className="flex justify-center pt-0.5">
                      <span className={`inline-block px-1.5 py-0.5 rounded-md text-[10px] font-mono font-semibold ${riskBadgeClass(item.risk_level)}`}>
                        {item.risk_level}
                      </span>
                    </div>
                    <p className="text-[11px] text-slate-500 leading-relaxed">{item.mitigation ?? "-"}</p>
                    <div className="flex justify-center pt-0.5"><StatusBadge value={value.status} /></div>
                    <p className="text-xs text-slate-400 italic font-mono">{value.remarks || "-"}</p>
                  </div>
                </div>
              );
            })}
          </div>
        ))}
      </CardContent>
    </Card>
  );
}

export function AickSignOffReadOnlyCard({ signOff }: { signOff: Record<string, string> }) {
  return (
    <Card>
      <CardHeader className="pb-3 border-b border-slate-100">
        <div>
          <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Sign Off</CardTitle>
          <p className="text-xs text-slate-500 mt-0.5">Complete assessment sign-off details</p>
        </div>
      </CardHeader>
      <CardContent className="pt-4">
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-500 font-mono w-24 shrink-0">Approved?</span>
            <StatusBadge value={signOff.approved} />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {(["prepared", "acknowledged"] as const).map((prefix) => (
              <div key={prefix} className="space-y-1">
                <p className="text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">
                  {prefix === "prepared" ? "Prepared By" : "Acknowledged By"}
                </p>
                <p className="font-semibold text-xs text-slate-900">{signOff[`${prefix}_by`] || "-"}</p>
                <p className="text-xs text-slate-400 font-mono">{signOff[`${prefix}_position`] || ""}</p>
                {signOff[`${prefix}_signature`]
                  ? <img src={signOff[`${prefix}_signature`]} alt="signature" className="h-12 border border-slate-200 rounded-md bg-white object-contain w-full mt-1" />
                  : <div className="h-12 border border-dashed border-slate-200 rounded-md flex items-center justify-center mt-1"><span className="text-xs text-slate-400 font-mono">Not signed</span></div>}
                {signOff[`${prefix}_date`] && <p className="text-[10px] text-slate-400 font-mono">Signed: {signOff[`${prefix}_date`]}</p>}
              </div>
            ))}
          </div>
          {signOff.remarks && (
            <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-500 font-mono mb-0.5">Remarks</p><p className="text-xs text-slate-700 italic">{signOff.remarks}</p></div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export function AickDetailCards({
  dsr,
  areas,
  onProjectClick,
  onDsrClick,
}: {
  dsr: AickDsrLike;
  areas: AickAreaLike[];
  onProjectClick?: () => void;
  onDsrClick?: () => void;
}) {
  const checklist = dsr.ai_checklist;
  if (!checklist) return null;
  const draft = checklist.checklist_json ?? {};
  const signOff = (draft.sign_off ?? {}) as Record<string, string>;

  return (
    <div className="space-y-4">
      <AickAssessmentInformationCard
        dsr={dsr}
        docNumber={dsr.tracking_id.replace("DSR", "AICK")}
        onProjectClick={onProjectClick}
        onDsrClick={onDsrClick}
      />
      <AickApprovalTimelineCard approvals={checklist.approvals ?? []} />
      <AickChecklistReadOnlyCard
        areas={areas}
        items={(draft.items ?? {}) as Record<string, { status?: string | null; remarks?: string }>}
        isApproved={checklist.status === "approved"}
      />
      <AickSignOffReadOnlyCard signOff={signOff} />
    </div>
  );
}
