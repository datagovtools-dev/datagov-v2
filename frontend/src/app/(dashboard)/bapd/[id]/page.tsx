"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { formatDate, formatDateTime } from "@/lib/utils";

interface BAPDApproval {
  id: string;
  step_order: number;
  approver_role: string;
  status: string;
  comments: string | null;
  actioned_at: string | null;
}

interface BAPDDetail {
  id: string;
  project_id: string;
  dataset_name: string;
  dataset_location: string;
  expiry_date: string;
  reason: string;
  status: string;
  pod_file_path: string | null;
  executed_at: string | null;
  executed_by: string | null;
  version: number;
  created_by: string;
  created_at: string;
  updated_at: string;
  approvals: BAPDApproval[];
}

const ROLE_LABELS: Record<string, string> = {
  data_owner: "Data Owner",
  compliance_officer: "Compliance Officer",
};

export default function BAPDDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const [transitionTarget, setTransitionTarget] = useState("");
  const [transitionComment, setTransitionComment] = useState("");
  const [approvalComment, setApprovalComment] = useState<Record<number, string>>({});
  const [confirmExecute, setConfirmExecute] = useState(false);
  const [executeText, setExecuteText] = useState("");

  const { data: bapd, isLoading } = useQuery<BAPDDetail>({
    queryKey: ["bapd", id],
    queryFn: () => api.get<BAPDDetail>(`/bapd/${id}`),
  });

  const transitionMutation = useMutation({
    mutationFn: () => api.post(`/bapd/${id}/transition`, { target_status: transitionTarget, comments: transitionComment }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["bapd", id] }); setTransitionTarget(""); setTransitionComment(""); },
  });

  const approvalMutation = useMutation({
    mutationFn: ({ step, action }: { step: number; action: string }) =>
      api.post(`/bapd/${id}/approvals/${step}`, { action, comments: approvalComment[step] ?? "" }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["bapd", id] }); },
  });

  const executeMutation = useMutation({
    mutationFn: () => api.post(`/bapd/${id}/execute`, {}),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["bapd", id] }); setConfirmExecute(false); setExecuteText(""); },
  });

  if (isLoading) return <div className="p-6 text-gray-400">Loading…</div>;
  if (!bapd) return <div className="p-6 text-red-500">BAPD record not found</div>;

  const NEXT_STATES: Record<string, string[]> = {
    draft: ["submitted"],
    submitted: ["under_review", "rejected"],
    under_review: [],
    approved: [],
    executed: ["archived"],
    rejected: ["draft", "archived"],
  };
  const nextStates = NEXT_STATES[bapd.status] ?? [];
  const canExecute = bapd.status === "approved";
  const CONFIRM_PHRASE = "DELETE PERMANENTLY";

  const allApproved = bapd.approvals.length > 0 && bapd.approvals.every((a) => a.status === "approved");
  const anyRejected = bapd.approvals.some((a) => a.status === "rejected");

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-3">
            <button onClick={() => router.back()} className="text-gray-400 hover:text-gray-600 text-sm">← Back</button>
            <Badge variant={statusVariant(bapd.status)}>{bapd.status.replace("_", " ")}</Badge>
            <span className="text-xs text-gray-400 font-mono">v{bapd.version}</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mt-1">{bapd.dataset_name}</h1>
          <p className="text-sm font-mono text-gray-500">{bapd.dataset_location}</p>
          <p className="text-sm text-gray-400 mt-0.5">Created {formatDateTime(bapd.created_at)}</p>
        </div>

        {nextStates.length > 0 && (
          <div className="flex items-end gap-2 flex-shrink-0">
            <select value={transitionTarget} onChange={(e) => setTransitionTarget(e.target.value)}
              className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
              <option value="">Move to…</option>
              {nextStates.map((s) => <option key={s} value={s}>{s.replace("_", " ")}</option>)}
            </select>
            <Button size="sm" disabled={!transitionTarget || transitionMutation.isPending}
              onClick={() => transitionMutation.mutate()}>Apply</Button>
          </div>
        )}
      </div>

      {transitionTarget && (
        <Input placeholder="Optional comment…" value={transitionComment}
          onChange={(e) => setTransitionComment(e.target.value)} className="max-w-lg" />
      )}

      <div className="grid grid-cols-3 gap-6">
        {/* Left: details */}
        <div className="col-span-2 space-y-4">
          <div className="bg-white rounded-lg shadow p-5 space-y-3">
            <h2 className="font-semibold text-gray-800 border-b pb-2">Request Details</h2>
            <dl className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
              <div><dt className="text-gray-500">Expiry Date</dt><dd className="font-medium mt-0.5 text-red-600">{formatDate(bapd.expiry_date)}</dd></div>
              <div><dt className="text-gray-500">Days Since Expiry</dt>
                <dd className="font-medium mt-0.5">
                  {(() => {
                    const d = Math.max(0, Math.floor((Date.now() - new Date(bapd.expiry_date).getTime()) / 86_400_000));
                    return d > 0 ? <span className="text-red-600 font-bold">{d} days overdue</span> : <span className="text-green-600">Not yet expired</span>;
                  })()}
                </dd>
              </div>
              {bapd.executed_at && (
                <div><dt className="text-gray-500">Executed At</dt><dd className="font-medium mt-0.5">{formatDateTime(bapd.executed_at)}</dd></div>
              )}
            </dl>
            <div className="pt-1">
              <dt className="text-sm text-gray-500">Justification</dt>
              <dd className="text-sm mt-1 leading-relaxed text-gray-800">{bapd.reason}</dd>
            </div>
          </div>

          {/* Execute panel */}
          {canExecute && (
            <div className="bg-red-50 border-2 border-red-400 rounded-lg p-5 space-y-3">
              <div className="flex items-center gap-2">
                <span className="text-red-500 text-xl font-bold">⚠</span>
                <h2 className="font-semibold text-red-800">All Approvals Received — Ready to Execute</h2>
              </div>
              <p className="text-sm text-red-700">
                Both approvals are complete. To permanently delete this dataset and generate the Proof of Deletion,
                type <strong>{CONFIRM_PHRASE}</strong> in the box below and click Execute.
              </p>
              {!confirmExecute ? (
                <Button onClick={() => setConfirmExecute(true)} className="bg-red-600 hover:bg-red-700 text-white">
                  Proceed to Execute
                </Button>
              ) : (
                <div className="space-y-3">
                  <Input
                    value={executeText}
                    onChange={(e) => setExecuteText(e.target.value)}
                    placeholder={`Type "${CONFIRM_PHRASE}" to confirm`}
                    className="max-w-sm border-red-300 focus:ring-red-500"
                  />
                  <div className="flex gap-2">
                    <Button variant="outline" size="sm" onClick={() => { setConfirmExecute(false); setExecuteText(""); }}>Cancel</Button>
                    <Button
                      size="sm"
                      disabled={executeText !== CONFIRM_PHRASE || executeMutation.isPending}
                      onClick={() => executeMutation.mutate()}
                      className="bg-red-600 hover:bg-red-700 text-white"
                    >
                      {executeMutation.isPending ? "Executing…" : "Execute Deletion"}
                    </Button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* POD download */}
          {bapd.pod_file_path && (
            <div className="bg-green-50 border border-green-300 rounded-lg p-4 flex items-center justify-between">
              <div>
                <p className="font-semibold text-green-800">Proof of Deletion Generated</p>
                <p className="text-sm text-green-700 font-mono mt-0.5">{bapd.pod_file_path}</p>
              </div>
              <a href={`/api/v1/bapd/${id}/pod`} target="_blank" rel="noreferrer">
                <Button variant="outline" size="sm">Download POD</Button>
              </a>
            </div>
          )}
        </div>

        {/* Right: dual approval tracker */}
        <div className="space-y-4">
          <div className="bg-white rounded-lg shadow p-5">
            <h2 className="font-semibold text-gray-800 border-b pb-2 mb-4">Dual Approval</h2>
            {allApproved && (
              <div className="mb-4 bg-green-50 border border-green-200 rounded p-2 text-xs text-green-700 font-medium text-center">
                All approvals received
              </div>
            )}
            {anyRejected && (
              <div className="mb-4 bg-red-50 border border-red-200 rounded p-2 text-xs text-red-700 font-medium text-center">
                Request rejected
              </div>
            )}

            <ol className="relative border-l border-gray-200 space-y-6 ml-3">
              {bapd.approvals.sort((a, b) => a.step_order - b.step_order).map((step) => (
                <li key={step.id} className="ml-4">
                  <div className={`absolute -left-1.5 w-3 h-3 rounded-full border-2 border-white ${
                    step.status === "approved" ? "bg-green-500" :
                    step.status === "rejected" ? "bg-red-500" : "bg-gray-300"
                  }`} />
                  <p className="text-sm font-medium text-gray-800">{ROLE_LABELS[step.approver_role] ?? step.approver_role}</p>
                  <Badge variant={step.status === "approved" ? "approved" : step.status === "rejected" ? "rejected" : "default"}
                    className="mt-1 text-xs">{step.status}</Badge>
                  {step.comments && <p className="text-xs text-gray-600 mt-1 italic">"{step.comments}"</p>}
                  {step.actioned_at && <p className="text-xs text-gray-400">{formatDate(step.actioned_at)}</p>}

                  {/* Action buttons for pending steps */}
                  {step.status === "pending" && bapd.status === "submitted" && step.step_order === 1 && (
                    <div className="mt-2 space-y-2">
                      <Input
                        placeholder="Optional comment…"
                        value={approvalComment[step.step_order] ?? ""}
                        onChange={(e) => setApprovalComment((c) => ({ ...c, [step.step_order]: e.target.value }))}
                        className="text-xs"
                      />
                      <div className="flex gap-1">
                        <Button size="sm" variant="outline" className="text-green-700 border-green-400 hover:bg-green-50 text-xs"
                          disabled={approvalMutation.isPending}
                          onClick={() => approvalMutation.mutate({ step: step.step_order, action: "approve" })}>
                          Approve
                        </Button>
                        <Button size="sm" variant="outline" className="text-red-700 border-red-400 hover:bg-red-50 text-xs"
                          disabled={approvalMutation.isPending}
                          onClick={() => approvalMutation.mutate({ step: step.step_order, action: "reject" })}>
                          Reject
                        </Button>
                      </div>
                    </div>
                  )}

                  {step.status === "pending" && bapd.status === "under_review" && step.step_order === 2 && (
                    <div className="mt-2 space-y-2">
                      <Input
                        placeholder="Optional comment…"
                        value={approvalComment[step.step_order] ?? ""}
                        onChange={(e) => setApprovalComment((c) => ({ ...c, [step.step_order]: e.target.value }))}
                        className="text-xs"
                      />
                      <div className="flex gap-1">
                        <Button size="sm" variant="outline" className="text-green-700 border-green-400 hover:bg-green-50 text-xs"
                          disabled={approvalMutation.isPending}
                          onClick={() => approvalMutation.mutate({ step: step.step_order, action: "approve" })}>
                          Approve
                        </Button>
                        <Button size="sm" variant="outline" className="text-red-700 border-red-400 hover:bg-red-50 text-xs"
                          disabled={approvalMutation.isPending}
                          onClick={() => approvalMutation.mutate({ step: step.step_order, action: "reject" })}>
                          Reject
                        </Button>
                      </div>
                    </div>
                  )}
                </li>
              ))}
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "draft", submitted: "warning", under_review: "in-review",
    approved: "approved", rejected: "rejected", executed: "done", archived: "default",
  };
  return map[status] ?? "default";
}
