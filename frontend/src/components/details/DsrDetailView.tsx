"use client";

import * as React from "react";
import { Badge } from "@/components/ui/Badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { formatDate, formatDateTime } from "@/lib/utils";

export interface DsrApprovalLike {
  id: string;
  step_order: number;
  approver_name?: string | null;
  status: string;
  actioned_at: string | null;
}

export interface DsrChecklistLike {
  checklist_json: Record<string, any>;
  validated_at?: string | null;
}

export interface DsrDetailLike {
  id?: string;
  tracking_id: string;
  project_id: string;
  project_code: string | null;
  project_name: string;
  dataset_name?: string;
  recipient: string;
  purpose: string;
  is_ai_use: boolean;
  duration_start: string | null;
  duration_end: string | null;
  project_end_date?: string | null;
  status: string;
  approvals: DsrApprovalLike[];
  ai_checklist?: DsrChecklistLike | null;
}

const STEP_LABELS: Record<number, string> = {
  1: "PIC Data Compliance Approval",
  2: "DM Approval",
  3: "SME Sign Off",
  4: "Client Sign Off",
};

const CHECKLIST_TEMPLATE: { section: string; title: string; aiOnly?: boolean; items: { id: string; label: string; sub?: { id: string; label: string }[] }[] }[] = [
  {
    section: "A", title: "Interest Protection",
    items: [
      { id: "A_i", label: "Will this data sharing infringe the following commercial interest(s) of the Business Unit(s) sharing the data?", sub: [
        { id: "A_i_1", label: "Loss in revenue due to cannibalization" },
        { id: "A_i_2", label: "Damage to relationship with customers" },
        { id: "A_i_3", label: "Other commercial interest(s)" },
      ] },
      { id: "A_ii", label: "Are there potentially any of the following commercial secret(s) included in the requested data?", sub: [
        { id: "A_ii_1", label: "Highly confidential partnerships" },
        { id: "A_ii_2", label: "Patent information" },
        { id: "A_ii_3", label: "M&A deals" },
        { id: "A_ii_4", label: "Other commercial secret(s)" },
      ] },
    ],
  },
  {
    section: "B", title: "Customer Data & Insights Sharing Consent",
    items: [
      { id: "B_i", label: "Are the data & insights requested sensitive?" },
      { id: "B_ii", label: "Are there any mitigation steps in place if sensitive data & insights are used?" },
      { id: "B_iii", label: "Are the data & insights requested considered personal data?" },
      { id: "B_iv", label: "If personal data need to be shared, has written consent for sharing been obtained?" },
      { id: "B_v", label: "If personal data need to be used for use case development, has written consent for research been obtained?" },
      { id: "B_vi", label: "Are the data and analytics processes located within the BU's analytics environment with limited access?" },
    ],
  },
  {
    section: "C", title: "Regulatory Compliance",
    items: [
      { id: "C_i", label: "Are there prevailing regulations that will be violated if the data & insights are shared?", sub: [
        { id: "C_i_1", label: "Industry-specific laws" },
        { id: "C_i_2", label: "Data protection laws" },
        { id: "C_i_3", label: "Internal regulations and policies" },
      ] },
    ],
  },
  {
    section: "D", title: "AI Compliance", aiOnly: true,
    items: [{ id: "D_i", label: "Is the data analysis process carried out using artificial intelligence technology?" }],
  },
];

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

function AnswerBadge({ value }: { value?: string }) {
  return (
    <span className={`shrink-0 inline-block px-2 py-0.5 rounded text-xs font-semibold mt-0.5 ${
      value === "Yes" ? "bg-green-100 text-green-700" :
      value === "No" ? "bg-red-100 text-red-700" :
      "bg-surface-100 text-surface-400"
    }`}>
      {value || "-"}
    </span>
  );
}

export function DsrRequestDetailsCard({
  dsr,
  onProjectClick,
}: {
  dsr: DsrDetailLike;
  onProjectClick?: () => void;
}) {
  return (
    <Card>
      <CardHeader><CardTitle>Request Details</CardTitle></CardHeader>
      <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
          <p className="text-xs text-surface-400 mb-0.5">Project Name</p>
          <p className="font-medium">{dsr.project_name}</p>
        </div>
        <div>
          <p className="text-xs text-surface-400 mb-0.5">Customer / Client</p>
          <p className="font-medium">{dsr.recipient}</p>
        </div>
        <div>
          <p className="text-xs text-surface-400 mb-0.5">AI / ML Use</p>
          {dsr.is_ai_use ? <Badge variant="warning">Yes - AI Use</Badge> : <span className="text-surface-500">No</span>}
        </div>
        {dsr.dataset_name !== undefined && (
          <div>
            <p className="text-xs text-surface-400 mb-0.5">Dataset / Data Name</p>
            <p className="font-medium">{dsr.dataset_name || <EmptyValue />}</p>
          </div>
        )}
        <div>
          <p className="text-xs text-surface-400 mb-0.5">Sharing Start Date</p>
          <p className="font-medium">{dsr.duration_start ? formatDate(dsr.duration_start) : <EmptyValue />}</p>
        </div>
        <div>
          <p className="text-xs text-surface-400 mb-0.5">Sharing End Date</p>
          <p className="font-medium">{dsr.project_end_date ? formatDate(dsr.project_end_date) : dsr.duration_end ? formatDate(dsr.duration_end) : <EmptyValue />}</p>
        </div>
        <div className="md:col-span-2">
          <p className="text-xs text-surface-400 mb-0.5">Purpose / Justification</p>
          <p className="text-surface-800 leading-relaxed">{dsr.purpose || <EmptyValue />}</p>
        </div>
      </CardContent>
    </Card>
  );
}

export function DsrApprovalTimelineCard({
  approvals,
  signOff,
}: {
  approvals: DsrApprovalLike[];
  signOff?: Record<string, string>;
}) {
  return (
    <Card>
      <CardHeader><CardTitle>Approval Timeline</CardTitle></CardHeader>
      <CardContent>
        <ol className="relative border-l border-surface-200 space-y-6 ml-3">
          {[...approvals].sort((a, b) => a.step_order - b.step_order).map((step) => {
            const displayName = step.step_order === 4 ? (signOff?.prepared_by || step.approver_name) : step.approver_name;
            return (
              <li key={step.id} className="ml-4">
                <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                  step.status === "approved" ? "bg-green-500" :
                  step.status === "rejected" ? "bg-red-500" :
                  step.status === "requested" ? "bg-primary-500" :
                  "bg-surface-200"
                }`} />
                <p className={`text-sm font-medium ${step.status === "pending" ? "text-surface-400" : "text-surface-800"}`}>
                  {STEP_LABELS[step.step_order] ?? `Step ${step.step_order}`}
                </p>
                {displayName && (
                  <p className={`text-xs ${step.status === "pending" ? "text-surface-400" : "text-surface-500"}`}>
                    {displayName}
                  </p>
                )}
                <Badge variant={statusVariant(step.status)} className="mt-1 text-xs">
                  {statusLabel(step.status)}
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
  );
}

export function DsrChecklistReadOnlyCard({ dsr }: { dsr: DsrDetailLike }) {
  const checklist = dsr.ai_checklist;
  if (!checklist) return null;
  const cj = checklist.checklist_json ?? {};
  const signOff = (cj.sign_off ?? {}) as Record<string, string>;

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between flex-wrap gap-2">
          <div>
            <CardTitle>Data &amp; Insights Sharing Evaluation Checklist</CardTitle>
            <p className="text-xs text-surface-400 mt-0.5">
              Instructions: Fill the checkbox with "Yes" / "No" based on data condition and leave remarks if criteria are not met.
            </p>
          </div>
          {checklist.validated_at && <Badge variant="approved">Signed off {formatDate(checklist.validated_at)}</Badge>}
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {CHECKLIST_TEMPLATE.filter((s) => !s.aiOnly || dsr.is_ai_use).map((section) => (
          <div key={section.section}>
            <h3 className="text-sm font-semibold text-surface-800 bg-surface-100 px-3 py-2 rounded-t-md border border-surface-200">
              {section.section}. {section.title}
            </h3>
            <div className="border border-t-0 border-surface-200 rounded-b-md divide-y divide-surface-100">
              {section.items.map((item) => {
                const rows = item.sub
                  ? item.sub.map((sub) => ({ id: sub.id, label: sub.label, val: (cj[sub.id] ?? {}) as { answer?: string; remarks?: string } }))
                  : [{ id: item.id, label: item.label, val: (cj[item.id] ?? {}) as { answer?: string; remarks?: string } }];
                return (
                  <div key={item.id} className="p-3 space-y-2">
                    {item.sub && <p className="text-sm font-medium text-surface-700">{item.label}</p>}
                    {rows.map((row) => (
                      <div key={row.id} className={`flex items-start gap-2 ${item.sub ? "pl-3 border-l-2 border-surface-200" : ""}`}>
                        <AnswerBadge value={row.val.answer} />
                        <div>
                          <p className="text-sm text-surface-700">{row.label}</p>
                          {row.val.remarks && <p className="text-xs text-surface-400 italic mt-0.5">{row.val.remarks}</p>}
                        </div>
                      </div>
                    ))}
                  </div>
                );
              })}
            </div>
          </div>
        ))}

        <div>
          <h3 className="text-sm font-semibold text-surface-800 bg-surface-100 px-3 py-2 rounded-t-md border border-surface-200">Sign Off</h3>
          <div className="border border-t-0 border-surface-200 rounded-b-md p-3 space-y-3">
            <div className="flex items-center gap-3">
              <span className="text-sm font-medium text-surface-700 w-28 shrink-0">Approved?</span>
              <AnswerBadge value={signOff.approved} />
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
        </div>
      </CardContent>
    </Card>
  );
}

export function DsrDetailCards({
  dsr,
  onProjectClick,
}: {
  dsr: DsrDetailLike;
  onProjectClick?: () => void;
}) {
  const signOff = (dsr.ai_checklist?.checklist_json?.sign_off ?? {}) as Record<string, string>;

  return (
    <div className="space-y-5">
      <DsrRequestDetailsCard dsr={dsr} onProjectClick={onProjectClick} />
      <DsrApprovalTimelineCard approvals={dsr.approvals} signOff={signOff} />
      <DsrChecklistReadOnlyCard dsr={dsr} />
    </div>
  );
}
