"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, X, AlertTriangle, Printer, FolderKanban, ShieldCheck, FileText } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { DetailModal } from "@/components/details/DetailModal";
import { ProjectDetailCards, ProjectDetailLike, UserOptionLike, OwnerRecordLike } from "@/components/details/ProjectDetailView";
import { printA4 } from "@/lib/exportPdf";
import { formatDate, formatDateTime } from "@/lib/utils";
import { useAuthStore } from "@/store/authStore";

interface BAPDApproval {
  id: string;
  step_order: number;
  approver_id: string;
  approver_name?: string;
  approver_role: string;
  status: string;
  comments: string | null;
  actioned_at: string | null;
}

interface BAPDDetail {
  id: string;
  project_id: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
  dataset_name: string;
  dataset_location: string;
  retention_policy_id: string | null;
  retention_policy_name: string | null;
  expiry_date: string;
  reason: string;
  responsible_party_id: string;
  responsible_party_name: string | null;
  status: string;
  pod_file_path: string | null;
  executed_at: string | null;
  executed_by: string | null;
  version: number;
  created_by: string;
  created_by_name: string | null;
  created_at: string;
  updated_at: string;
  approvals: BAPDApproval[];
}

const ROLE_LABELS: Record<string, string> = {
  data_owner: "Step 1: Data Owner Sign-Off",
  compliance_officer: "Step 2: Compliance Officer / DGO",
};

export default function BAPDDetailPage() {
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
  const [transitionTarget, setTransitionTarget] = useState("");
  const [transitionComment, setTransitionComment] = useState("");
  const [approvalComment, setApprovalComment] = useState<Record<number, string>>({});
  const [confirmExecute, setConfirmExecute] = useState(false);
  const [executeText, setExecuteText] = useState("");
  const [isProjectModalOpen, setIsProjectModalOpen] = useState(false);

  const { data: bapd, isLoading } = useQuery<BAPDDetail>({
    queryKey: ["bapd", id],
    queryFn: () => api.get<BAPDDetail>(`/bapd/${id}`),
  });

  const { data: project } = useQuery<ProjectDetailLike>({
    queryKey: ["project", bapd?.project_id],
    queryFn: () => api.get<ProjectDetailLike>(`/projects/${bapd?.project_id}`),
    enabled: !!bapd?.project_id,
  });

  const { data: projectUsers } = useQuery<UserOptionLike[]>({
    queryKey: ["project-users-options"],
    queryFn: () => api.get<UserOptionLike[]>("/projects/users/options"),
    enabled: isProjectModalOpen,
  });

  const { data: projectOwners } = useQuery<OwnerRecordLike[]>({
    queryKey: ["project-owners", bapd?.project_id],
    queryFn: () => api.get<OwnerRecordLike[]>(`/metadata/owners/${bapd?.project_id}`),
    enabled: isProjectModalOpen && !!bapd?.project_id,
  });

  const transitionMutation = useMutation({
    mutationFn: () => {
      toast.loading(`Moving BAPD to ${transitionTarget.replace("_", " ")}...`, { id: "bapd-trans" });
      return api.post(`/bapd/${id}/transition`, { target_status: transitionTarget, comments: transitionComment });
    },
    onSuccess: () => {
      toast.success("BAPD status updated!", { id: "bapd-trans" });
      qc.invalidateQueries({ queryKey: ["bapd", id] });
      qc.invalidateQueries({ queryKey: ["bapds"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setTransitionTarget("");
      setTransitionComment("");
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to update status", { id: "bapd-trans" });
    },
  });

  const approvalMutation = useMutation({
    mutationFn: ({ step, action }: { step: number; action: string }) => {
      const label = action === "approve" ? "Approving" : "Rejecting";
      toast.loading(`${label} Step ${step}...`, { id: "bapd-approval" });
      return api.post(`/bapd/${id}/approvals/${step}`, { action, comments: approvalComment[step] ?? "" });
    },
    onSuccess: (_, variables) => {
      const msg = variables.action === "approve" ? "Step approved successfully!" : "BAPD rejected.";
      toast.success(msg, { id: "bapd-approval" });
      qc.invalidateQueries({ queryKey: ["bapd", id] });
      qc.invalidateQueries({ queryKey: ["bapds"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setApprovalComment((prev) => ({ ...prev, [variables.step]: "" }));
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to action approval", { id: "bapd-approval" });
    },
  });

  const executeMutation = useMutation({
    mutationFn: () => {
      toast.loading("Executing permanent deletion & generating POD...", { id: "bapd-exec" });
      return api.post(`/bapd/${id}/execute`, {});
    },
    onSuccess: () => {
      toast.success("Dataset exterminated & POD certificate generated!", { id: "bapd-exec" });
      qc.invalidateQueries({ queryKey: ["bapd", id] });
      qc.invalidateQueries({ queryKey: ["bapds"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setConfirmExecute(false);
      setExecuteText("");
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to execute deletion", { id: "bapd-exec" });
    },
  });

  function handleExportPdf() {
    if (!bapd) return;
    const bodyHtml = `
      <div class="pdf-header">
        <div>
          <div class="brand">DATA GOVERNANCE &amp; PRIVACY COMPLIANCE</div>
          <div style="font-size: 9pt; color: #718096; margin-top: 2px;">Berita Acara Pemusnahan Data (BAPD) — UU PDP No. 27/2022</div>
        </div>
        <div class="meta">
          <div><strong>Doc No:</strong> BAPD-${bapd.id.slice(0, 8).toUpperCase()}</div>
          <div><strong>Status:</strong> ${bapd.status.toUpperCase()}</div>
          <div><strong>Date:</strong> ${formatDate(bapd.executed_at || bapd.updated_at || bapd.created_at)}</div>
        </div>
      </div>

      <h1 class="doc-title">BERITA ACARA PEMUSNAHAN DATA</h1>
      <div class="doc-subtitle">Official Certificate of Data Disposal &amp; Extermination — Version ${bapd.version}</div>

      <div class="section">
        <div class="section-title">1. Project &amp; Controller Identity</div>
        <div class="grid2">
          <div class="field"><div class="field-label">Project Code</div><div class="field-value">${bapd.project_code || "—"}</div></div>
          <div class="field"><div class="field-label">Project Name</div><div class="field-value">${bapd.project_name || "—"}</div></div>
          <div class="field"><div class="field-label">Data Controller / Client</div><div class="field-value">${bapd.customer_name || "—"}</div></div>
          <div class="field"><div class="field-label">Responsible Executing Party</div><div class="field-value">${bapd.responsible_party_name || "—"}</div></div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">2. Target Dataset &amp; Storage Identification</div>
        <div class="grid2">
          <div class="field"><div class="field-label">Dataset Name</div><div class="field-value font-mono">${bapd.dataset_name}</div></div>
          <div class="field"><div class="field-label">Retention Policy Category</div><div class="field-value">${bapd.retention_policy_name || "Manual Expiry"}</div></div>
          <div class="field full-width"><div class="field-label">Exact Storage Location URI</div><div class="field-value font-mono" style="font-size: 8.5pt;">${bapd.dataset_location}</div></div>
          <div class="field"><div class="field-label">Retention Expiry Date</div><div class="field-value">${formatDate(bapd.expiry_date)}</div></div>
          <div class="field"><div class="field-label">Extermination Execution Date</div><div class="field-value">${bapd.executed_at ? formatDateTime(bapd.executed_at) : "Pending Execution"}</div></div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">3. Disposal Justification &amp; Regulatory Basis</div>
        <div class="field full-width">
          <div class="field-label">Justification / Reason for Extermination</div>
          <div class="field-value" style="margin-top: 4px; line-height: 1.6;">${bapd.reason}</div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">4. Dual Sign-Off &amp; Approvals Registry</div>
        <table class="data-table">
          <thead>
            <tr>
              <th>Approval Step &amp; Role</th>
              <th>Designated Signatory</th>
              <th>Status</th>
              <th>Timestamp</th>
              <th>Review Comments</th>
            </tr>
          </thead>
          <tbody>
            ${bapd.approvals.map((a) => `
              <tr>
                <td style="font-weight: 600;">${ROLE_LABELS[a.approver_role] || a.approver_role}</td>
                <td>${a.approver_name || "—"}</td>
                <td><strong>${a.status.toUpperCase()}</strong></td>
                <td>${a.actioned_at ? formatDateTime(a.actioned_at) : "—"}</td>
                <td>${a.comments || "—"}</td>
              </tr>
            `).join("")}
          </tbody>
        </table>
      </div>

      ${bapd.pod_file_path ? `
        <div class="section">
          <div class="section-title">5. Proof of Deletion (POD) Verification</div>
          <div class="field full-width">
            <div class="field-label">POD Storage Reference</div>
            <div class="field-value font-mono" style="font-size: 8.5pt;">${bapd.pod_file_path}</div>
          </div>
        </div>
      ` : ""}
    `;
    printA4(`BAPD - ${bapd.dataset_name}`, bodyHtml);
  }

  if (isLoading) return <DetailSkeleton />;
  if (!bapd) return <div className="p-6 text-red-500 font-mono">BAPD record not found</div>;

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
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <div className="flex items-center gap-2.5">
            <button onClick={() => router.back()} className="text-slate-400 hover:text-slate-700 text-xs font-mono">← Back</button>
            <Badge variant={statusVariant(bapd.status)} className="text-[10px] font-mono uppercase">
              {bapd.status.replace("_", " ")}
            </Badge>
            <span className="text-[10px] text-slate-400 font-mono">v{bapd.version}</span>
            {bapd.project_code && (
              <button
                type="button"
                onClick={() => setIsProjectModalOpen(true)}
                className="inline-flex items-center gap-1 text-[11px] font-mono text-blue-600 bg-blue-50 px-2 py-0.5 rounded border border-blue-200 hover:bg-blue-100 transition-colors"
              >
                <FolderKanban className="h-3 w-3" />
                {bapd.project_code}
              </button>
            )}
          </div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1.5">{bapd.dataset_name}</h1>
          <p className="text-xs font-mono text-slate-500 mt-0.5">{bapd.dataset_location}</p>
          <p className="text-xs text-slate-400 font-mono mt-0.5">
            Created {formatDateTime(bapd.created_at)} {bapd.created_by_name ? `by ${bapd.created_by_name}` : ""}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {bapd.project_id && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setIsProjectModalOpen(true)}
              className="h-8 text-xs font-medium"
            >
              <FolderKanban className="h-3.5 w-3.5 mr-1.5 text-slate-500" />
              View Project
            </Button>
          )}
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={handleExportPdf}
            className="h-8 text-xs font-medium"
          >
            <Printer className="h-3.5 w-3.5 mr-1.5 text-slate-500" />
            Print BAPD (PDF)
          </Button>

          {nextStates.length > 0 && (
            <div className="flex items-center gap-1.5">
              <select
                value={transitionTarget}
                onChange={(e) => setTransitionTarget(e.target.value)}
                className="border border-slate-200 rounded-md px-2.5 py-1 text-xs font-mono focus:outline-none focus:ring-1 focus:ring-slate-400 bg-white h-8"
              >
                <option value="">Move to…</option>
                {nextStates.map((s) => <option key={s} value={s}>{s.replace("_", " ")}</option>)}
              </select>
              <Button
                size="sm"
                className="h-8 text-xs font-medium"
                disabled={!transitionTarget || transitionMutation.isPending}
                onClick={() => transitionMutation.mutate()}
              >
                Apply
              </Button>
            </div>
          )}
        </div>
      </div>

      {transitionTarget && (
        <Input
          placeholder="Optional comment for state transition…"
          value={transitionComment}
          onChange={(e) => setTransitionComment(e.target.value)}
          className="max-w-lg h-8 text-xs font-mono"
        />
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Left: details */}
        <div className="lg:col-span-2 space-y-4">
          <div className="bg-white rounded-md border border-slate-200 shadow-2xs p-4 space-y-3.5">
            <h2 className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800 border-b border-slate-100 pb-2">
              Extermination Request Details
            </h2>
            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-3.5 text-xs">
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Associated Project</dt>
                <dd className="font-medium text-slate-900 mt-0.5">
                  {bapd.project_name || "—"}{" "}
                  {bapd.customer_name ? <span className="text-slate-400 font-normal">({bapd.customer_name})</span> : null}
                </dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Responsible Executing Party</dt>
                <dd className="font-medium text-slate-900 mt-0.5">{bapd.responsible_party_name || "—"}</dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Retention Policy Match</dt>
                <dd className="font-medium text-slate-900 mt-0.5">
                  {bapd.retention_policy_name ? (
                    <span className="inline-block bg-slate-100 text-slate-800 text-[11px] px-2 py-0.5 rounded border border-slate-200 font-mono">
                      {bapd.retention_policy_name}
                    </span>
                  ) : (
                    <span className="text-slate-400">Manual Entry</span>
                  )}
                </dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Expiry Date</dt>
                <dd className="font-mono font-medium mt-0.5 text-rose-700">{formatDate(bapd.expiry_date)}</dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Retention Overdue Status</dt>
                <dd className="font-mono font-medium mt-0.5">
                  {(() => {
                    const d = Math.max(0, Math.floor((Date.now() - new Date(bapd.expiry_date).getTime()) / 86_400_000));
                    return d > 0 ? (
                      <span className="text-rose-700 font-bold tabular-nums">{d} days overdue</span>
                    ) : (
                      <span className="text-emerald-700">Active / Not Expired</span>
                    );
                  })()}
                </dd>
              </div>
              {bapd.executed_at && (
                <div>
                  <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Execution Timestamp</dt>
                  <dd className="font-mono font-medium mt-0.5 text-slate-900">{formatDateTime(bapd.executed_at)}</dd>
                </div>
              )}
              <div className="sm:col-span-2">
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Storage Location URI</dt>
                <dd className="font-mono text-xs text-slate-700 mt-0.5 bg-slate-50 p-2 rounded border border-slate-100 break-all">
                  {bapd.dataset_location}
                </dd>
              </div>
              <div className="sm:col-span-2 pt-1">
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Disposal Justification</dt>
                <dd className="text-xs mt-1 leading-relaxed text-slate-800 bg-slate-50 p-3 rounded-md border border-slate-100">
                  {bapd.reason}
                </dd>
              </div>
            </dl>
          </div>

          {/* Execute panel */}
          {canExecute && (
            <div className="bg-rose-50/50 border border-rose-200 rounded-md p-4 space-y-2.5">
              <div className="flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-rose-700 shrink-0" />
                <h2 className="text-xs font-semibold font-mono text-rose-900 uppercase tracking-wider">All Approvals Received — Ready to Execute</h2>
              </div>
              <p className="text-xs text-rose-800">
                Both approvals are complete. To permanently delete this dataset and generate the Proof of Deletion,
                type <strong className="font-mono">{CONFIRM_PHRASE}</strong> in the box below and click Execute.
              </p>
              {!confirmExecute ? (
                <Button size="sm" onClick={() => setConfirmExecute(true)} className="h-7.5 text-xs font-medium bg-rose-700 hover:bg-rose-800 text-white">
                  Proceed to Execute
                </Button>
              ) : (
                <div className="space-y-2.5">
                  <Input
                    value={executeText}
                    onChange={(e) => setExecuteText(e.target.value)}
                    placeholder={`Type "${CONFIRM_PHRASE}" to confirm`}
                    className="max-w-sm h-8 text-xs font-mono border-rose-300 focus:ring-rose-400"
                  />
                  <div className="flex gap-2">
                    <Button variant="outline" size="sm" className="h-7 text-xs" onClick={() => { setConfirmExecute(false); setExecuteText(""); }}>Cancel</Button>
                    <Button
                      size="sm"
                      disabled={executeText !== CONFIRM_PHRASE || executeMutation.isPending}
                      onClick={() => executeMutation.mutate()}
                      className="h-7 text-xs font-medium bg-rose-700 hover:bg-rose-800 text-white"
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
            <div className="bg-emerald-50/50 border border-emerald-200 rounded-md p-3.5 flex items-center justify-between">
              <div>
                <p className="text-xs font-semibold font-mono text-emerald-900 uppercase tracking-wider">Proof of Deletion Generated</p>
                <p className="text-xs text-emerald-800 font-mono mt-0.5">{bapd.pod_file_path}</p>
              </div>
              <a href={`/api/v1/bapd/${id}/pod`} target="_blank" rel="noreferrer">
                <Button variant="outline" size="sm" className="h-7.5 text-xs font-medium">Download POD</Button>
              </a>
            </div>
          )}
        </div>

        {/* Right: dual approval tracker */}
        <div className="space-y-4">
          <div className="bg-white rounded-md border border-slate-200 shadow-2xs p-4">
            <h2 className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800 border-b border-slate-100 pb-2 mb-3">Dual Approval</h2>
            {allApproved && (
              <div className="mb-3 bg-emerald-50 border border-emerald-200 rounded-md p-2 text-xs text-emerald-800 font-mono font-medium text-center">
                All approvals received
              </div>
            )}
            {anyRejected && (
              <div className="mb-3 bg-rose-50 border border-rose-200 rounded-md p-2 text-xs text-rose-800 font-mono font-medium text-center">
                Request rejected
              </div>
            )}

            <ol className="relative border-l border-slate-200 space-y-4 ml-3">
              {bapd.approvals.sort((a, b) => a.step_order - b.step_order).map((step) => {
                const isPendingAction = (step.status === "pending" || step.status === "requested") &&
                  ((step.step_order === 1 && (bapd.status === "submitted" || bapd.status === "under_review" || bapd.status === "draft")) ||
                   (step.step_order === 2 && (bapd.status === "under_review" || bapd.status === "submitted")));

                return (
                <li key={step.id} className="ml-3.5">
                  <div className={`absolute -left-1 w-2.5 h-2.5 rounded-full border border-white ${
                    step.status === "approved" ? "bg-emerald-600" :
                    step.status === "rejected" ? "bg-rose-600" :
                    isPendingAction ? "bg-slate-900" : "bg-slate-300"
                  }`} />
                  <div className="flex items-center justify-between gap-2 flex-wrap">
                    <p className="text-xs font-semibold font-mono text-slate-900">{ROLE_LABELS[step.approver_role] ?? step.approver_role}</p>
                    <Badge variant={step.status === "approved" ? "success" : step.status === "rejected" ? "danger" : isPendingAction ? "warning" : "default"}
                      className="text-[10px]">
                      {step.status === "approved" ? "Approved" : step.status === "rejected" ? "Rejected" : isPendingAction ? "Awaiting Action" : "Not Yet"}
                    </Badge>
                  </div>
                  {step.approver_name && (
                    <p className="text-xs text-slate-500 font-mono mt-0.5">{step.approver_name}</p>
                  )}
                  {step.comments && <p className="text-xs text-slate-600 mt-1 italic font-mono bg-slate-50 border border-slate-100 rounded p-1.5">&ldquo;{step.comments}&rdquo;</p>}
                  {step.actioned_at && <p className="text-[10px] text-slate-400 font-mono mt-0.5">Actioned on {formatDateTime(step.actioned_at)}</p>}

                  {/* Action buttons for active steps */}
                  {isPendingAction && (
                    canAction(step.approver_id) ? (
                      <div className="mt-2.5 p-3 rounded-md border border-slate-200 bg-slate-50/60 space-y-2 font-mono">
                        <textarea
                          rows={2}
                          placeholder="Add review notes or comments (optional)…"
                          value={approvalComment[step.step_order] ?? ""}
                          onChange={(e) => setApprovalComment((c) => ({ ...c, [step.step_order]: e.target.value }))}
                          className="input-base text-xs font-sans resize-none w-full bg-white"
                        />
                        <div className="flex items-center gap-2">
                          <Button size="sm" className="h-7 text-xs font-medium bg-slate-900 hover:bg-slate-800 text-white"
                            disabled={approvalMutation.isPending}
                            onClick={() => approvalMutation.mutate({ step: step.step_order, action: "approve" })}>
                            <Check className="h-3 w-3 mr-1" /> Approve
                          </Button>
                          <Button size="sm" variant="outline" className="text-rose-700 border-rose-200 hover:bg-rose-50 text-xs h-7 font-medium"
                            disabled={approvalMutation.isPending}
                            onClick={() => approvalMutation.mutate({ step: step.step_order, action: "reject" })}>
                            <X className="h-3 w-3 mr-1" /> Reject
                          </Button>
                        </div>
                      </div>
                    ) : (
                      <div className="mt-2 p-2.5 rounded bg-slate-50 border border-slate-200 text-xs text-slate-500 font-mono italic">
                        Waiting for {step.approver_name || "designated approver"} to review and sign-off.
                      </div>
                    )
                  )}
                </li>
              );
              })}
            </ol>
          </div>
        </div>
      </div>

      {/* Project Detail Modal */}
      {isProjectModalOpen && project && (
        <DetailModal
          onClose={() => setIsProjectModalOpen(false)}
          code={project.project_code}
          title={`Project Details — ${project.project_name}`}
        >
          <ProjectDetailCards
            project={project}
            users={projectUsers ?? []}
            owners={projectOwners ?? []}
          />
        </DetailModal>
      )}
    </div>
  );
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "neutral" | "info";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "default", submitted: "warning", under_review: "info",
    approved: "success", rejected: "danger", executed: "success", archived: "neutral",
  };
  return map[status] ?? "default";
}
