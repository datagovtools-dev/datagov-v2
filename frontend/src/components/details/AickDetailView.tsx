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
  return <span className="text-surface-400">-</span>;
}

function statusVariant(status: string) {
  if (status === "approved") return "approved";
  if (status === "rejected") return "rejected";
  return "draft";
}

function statusLabel(status: string) {
  if (status === "approved") return "Approved";
  if (status === "rejected") return "Rejected";
  if (status === "pending") return "Not Yet";
  if (status === "requested") return "Requested";
  return status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function riskBadgeClass(level: "HIGH" | "MEDIUM" | "LOW") {
  return level === "HIGH" ? "bg-red-100 text-red-700 border border-red-200" :
    level === "MEDIUM" ? "bg-amber-100 text-amber-700 border border-amber-200" :
    "bg-green-100 text-green-700 border border-green-200";
}

function StatusBadge({ value }: { value?: string | null }) {
  return (
    <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${
      value === "Yes" ? "bg-green-100 text-green-700" :
      value === "No" ? "bg-red-100 text-red-700" :
      value === "In Progress" || value === "in_progress" ? "bg-amber-100 text-amber-700" :
      value === "N/A" || value === "na" ? "bg-surface-100 text-surface-500" :
      "bg-surface-100 text-surface-400"
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
      <CardHeader><CardTitle>Assessment Information</CardTitle></CardHeader>
      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <p className="text-xs text-surface-400 mb-0.5">Project ID</p>
            {onProjectClick ? (
              <button onClick={onProjectClick} className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                {dsr.project_code ?? dsr.project_id}
              </button>
            ) : (
              <p className="font-mono font-medium">{dsr.project_code ?? dsr.project_id}</p>
            )}
          </div>
          <div>
            <p className="text-xs text-surface-400 mb-0.5">DSR ID</p>
            {onDsrClick ? (
              <button onClick={onDsrClick} className="font-mono font-medium text-primary-600 hover:text-primary-800 hover:underline text-left">
                {dsr.tracking_id}
              </button>
            ) : (
              <p className="font-mono font-medium">{dsr.tracking_id}</p>
            )}
          </div>
          {docNumber && (
            <div>
              <p className="text-xs text-surface-400 mb-0.5">AICK ID</p>
              <p className="font-mono font-medium">{docNumber}</p>
            </div>
          )}
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
            <p className="font-medium">{dsr.duration_start ? formatDate(dsr.duration_start) : <EmptyValue />}</p>
          </div>
          <div>
            <p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p>
            <p className="font-medium">{dsr.project_end_date ? formatDate(dsr.project_end_date) : dsr.duration_end ? formatDate(dsr.duration_end) : <EmptyValue />}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export function AickApprovalTimelineCard({ approvals }: { approvals: AickApprovalLike[] }) {
  return (
    <Card>
      <CardHeader><CardTitle>Approval Timeline</CardTitle></CardHeader>
      <CardContent>
        <ol className="relative border-l border-surface-200 space-y-5 ml-3">
          {[...approvals].sort((a, b) => a.step_order - b.step_order).map((step) => (
            <li key={step.id} className="ml-4">
              <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                step.status === "approved" ? "bg-green-500" :
                step.status === "rejected" ? "bg-red-500" :
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
              <Badge variant={statusVariant(step.status)} className="mt-1 text-xs">
                {statusLabel(step.status)}
              </Badge>
              {step.actioned_at && (
                <p className="text-xs text-surface-400 mt-0.5">{formatDateTime(step.actioned_at)}</p>
              )}
            </li>
          ))}
          {approvals.length === 0 && (
            <li className="ml-4 text-sm text-surface-400 italic">No approval steps configured yet.</li>
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
      <CardHeader>
        <div>
          <CardTitle>GEN AI Protection Checklist</CardTitle>
          <p className="text-xs text-surface-400 mt-0.5 italic">
            Instructions: Please fill the checkbox with "Yes/No" based on assessment condition and leave any remarks if criteria are not met. This assessment checklist form only be used for this project.
          </p>
        </div>
        {isApproved && <Badge variant="approved">Approved</Badge>}
      </CardHeader>
      <CardContent className="p-0">
        <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 bg-surface-50 border-b border-surface-200 px-4 py-2">
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Assessment</p>
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide text-center">Risk Level</p>
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Risk Mitigation</p>
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide text-center">Status</p>
          <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">Remarks</p>
        </div>

        {areas.map((area) => (
          <div key={area.area}>
            <div className="bg-surface-100 px-4 py-2 border-b border-surface-200">
              <span className="text-sm font-semibold text-surface-700">{area.area}</span>
            </div>
            {area.items.map((item, idx) => {
              const value = items[item.id] ?? {};
              return (
                <div key={item.id} className={`px-4 py-3 border-b border-surface-100 ${idx === area.items.length - 1 ? "border-surface-200" : ""}`}>
                  <div className="lg:hidden space-y-2">
                    <p className="text-sm text-surface-700">{item.assessment}</p>
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${riskBadgeClass(item.risk_level)}`}>
                      {item.risk_level}
                    </span>
                    {item.mitigation && <p className="text-xs text-surface-500 leading-relaxed"><span className="font-medium text-surface-600">Mitigation: </span>{item.mitigation}</p>}
                    <div className="flex items-start gap-2">
                      <StatusBadge value={value.status} />
                      <p className="text-xs text-surface-400 italic">{value.remarks || "-"}</p>
                    </div>
                  </div>

                  <div className="hidden lg:grid grid-cols-[3fr_80px_2fr_96px_1.5fr] gap-3 items-start">
                    <p className="text-sm text-surface-700 leading-snug">{item.assessment}</p>
                    <div className="flex justify-center pt-0.5">
                      <span className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${riskBadgeClass(item.risk_level)}`}>
                        {item.risk_level}
                      </span>
                    </div>
                    <p className="text-xs text-surface-500 leading-relaxed">{item.mitigation ?? "-"}</p>
                    <div className="flex justify-center pt-0.5"><StatusBadge value={value.status} /></div>
                    <p className="text-xs text-surface-400 italic">{value.remarks || "-"}</p>
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
      <CardHeader>
        <div>
          <CardTitle>Sign Off</CardTitle>
          <p className="text-xs text-surface-400 mt-0.5">Complete all fields and draw signatures to finalise the assessment</p>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-surface-500 w-24 shrink-0">Approved?</span>
            <StatusBadge value={signOff.approved} />
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {(["prepared", "acknowledged"] as const).map((prefix) => (
              <div key={prefix} className="space-y-1">
                <p className="text-xs font-semibold text-surface-500 uppercase tracking-wide">
                  {prefix === "prepared" ? "Prepared By" : "Acknowledged By"}
                </p>
                <p className="font-medium text-sm">{signOff[`${prefix}_by`] || "-"}</p>
                <p className="text-xs text-surface-400">{signOff[`${prefix}_position`] || ""}</p>
                {signOff[`${prefix}_signature`]
                  ? <img src={signOff[`${prefix}_signature`]} alt="signature" className="h-12 border border-surface-200 rounded bg-white object-contain w-full mt-1" />
                  : <div className="h-12 border border-dashed border-surface-200 rounded flex items-center justify-center mt-1"><span className="text-xs text-surface-300">Not signed</span></div>}
                {signOff[`${prefix}_date`] && <p className="text-xs text-surface-400">Signed: {signOff[`${prefix}_date`]}</p>}
              </div>
            ))}
          </div>
          {signOff.remarks && (
            <div><p className="text-xs text-surface-500 mb-0.5">Remarks</p><p className="text-xs text-surface-700 italic">{signOff.remarks}</p></div>
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
    <div className="space-y-5">
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
