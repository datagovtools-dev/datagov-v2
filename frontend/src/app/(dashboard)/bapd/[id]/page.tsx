"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, Printer, FolderKanban } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { toast } from "@/components/ui/Toast";
import { DetailSkeleton } from "@/components/ui/LoadingState";
import { DetailModal } from "@/components/details/DetailModal";
import { ProjectDetailCards, ProjectDetailLike, UserOptionLike, OwnerRecordLike } from "@/components/details/ProjectDetailView";
import { FinalApprovalSignOff, FinalApprovalSignOffValue } from "@/components/forms/FinalApprovalSignOff";
import { buildActorSignOffPayload } from "@/lib/bapdSignOff";
import { printA4 } from "@/lib/exportPdf";
import { formatDate, formatDateTime } from "@/lib/utils";
import { useAuthStore } from "@/store/authStore";

interface BAPDApproval {
  id: string;
  approver_name: string;
  approver_role: string;
  step_order: number;
  status: string;
  comments: string | null;
  actioned_at: string | null;
}

interface BAPDTargetDataset {
  id: string;
  dataset_name: string;
  dataset_location: string;
  source_type: string | null;
  display_order: number;
}

interface BAPDDetail {
  id: string;
  project_id: string;
  project_sme_id?: string | null;
  data_owner_registered: boolean;
  project_code: string | null;
  project_name: string;
  customer_name: string;
  dataset_name: string;
  dataset_location: string;
  datasets: BAPDTargetDataset[];
  retention_policy_id: string | null;
  retention_policy_name: string | null;
  expiry_date: string;
  reason: string;
  responsible_party_id: string;
  responsible_party_name: string | null;
  status: string;
  approval_method: string;
  sign_off: FinalApprovalSignOffValue;
  is_final_signed: boolean;
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

function escapeHtml(value: unknown): string {
  return String(value ?? "—").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[character] ?? character);
}

export default function BAPDDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const currentUser = useAuthStore(s => s.user);
  const [transitionTarget, setTransitionTarget] = useState("");
  const [transitionComment, setTransitionComment] = useState("");
  const [signOffDraft, setSignOffDraft] = useState<FinalApprovalSignOffValue>({});
  const [showSignOffErrors, setShowSignOffErrors] = useState(false);
  const [confirmExecute, setConfirmExecute] = useState(false);
  const [executeText, setExecuteText] = useState("");
  const [isProjectModalOpen, setIsProjectModalOpen] = useState(false);

  const { data: bapd, isLoading } = useQuery<BAPDDetail>({
    queryKey: ["bapd", id],
    queryFn: () => api.get<BAPDDetail>(`/bapd/${id}`),
  });

  useEffect(() => {
    if (bapd) setSignOffDraft(bapd.sign_off ?? {});
  }, [bapd?.id, bapd?.updated_at]);

  const { data: project } = useQuery<ProjectDetailLike>({
    queryKey: ["project", bapd?.project_id],
    queryFn: () => api.get<ProjectDetailLike>(`/projects/${bapd?.project_id}`),
    enabled: !!bapd?.project_id,
  });

  const { data: projectUsers } = useQuery<UserOptionLike[]>({
    queryKey: ["project-users-options"],
    queryFn: () => api.get<UserOptionLike[]>("/rbac/users/options"),
    enabled: !!bapd?.project_id,
  });

  const { data: projectOwners } = useQuery<OwnerRecordLike[]>({
    queryKey: ["project-owners", bapd?.project_id],
    queryFn: () => api.get<OwnerRecordLike[]>(`/metadata/owners/${bapd?.project_id}`),
    enabled: !!bapd?.project_id,
  });

  useEffect(() => {
    if (!bapd || !project) return;
    const dataOwner = projectOwners?.find((owner: OwnerRecordLike) => owner.role_type === "data_owner");
    const sme = projectUsers?.find((user: UserOptionLike) => user.id === project.sme_id);
    if (!dataOwner && !sme) return;
    setSignOffDraft((current: FinalApprovalSignOffValue) => {
      const next = { ...current };
      if (!next.prepared_by && dataOwner?.full_name) next.prepared_by = dataOwner.full_name;
      if (!next.prepared_position && dataOwner?.position) next.prepared_position = dataOwner.position;
      if (!next.acknowledged_by && sme) next.acknowledged_by = sme.full_name;
      if (!next.acknowledged_position && sme?.position) next.acknowledged_position = sme.position;
      return next;
    });
  }, [bapd?.id, project?.sme_id, projectOwners, projectUsers]);

  const isProjectSme = Boolean(currentUser?.id && project?.sme_id === currentUser.id);
  const canSmePrepareOnBehalf = Boolean(isProjectSme && bapd?.data_owner_registered === false);
  const configuredDataOwner = projectOwners?.find((owner) => owner.role_type === "data_owner");
  const isConfiguredDataOwner = Boolean(
    currentUser?.email && configuredDataOwner?.email &&
    currentUser.email.toLowerCase() === configuredDataOwner.email.toLowerCase()
  );
  const buildSignOffPayload = () => ({
    version: bapd?.version,
    sign_off: buildActorSignOffPayload(signOffDraft, {
      isProjectSme,
      isConfiguredDataOwner,
      canPrepareOnBehalf: canSmePrepareOnBehalf,
    }),
  });
  const canExecute = bapd?.status === "approved";

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

  const signOffMutation = useMutation({
    mutationFn: () => api.put(`/bapd/${id}/sign-off`, buildSignOffPayload()),
    onSuccess: () => {
      toast.success("BAPD sign-off saved!", { id: "bapd-signoff" });
      qc.invalidateQueries({ queryKey: ["bapd", id] });
      qc.invalidateQueries({ queryKey: ["bapds"] });
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to save BAPD sign-off", { id: "bapd-signoff" });
    },
  });

  const submitMutation = useMutation({
    mutationFn: async () => {
      toast.loading("Submitting BAPD Final Approval & Sign Off...", { id: "bapd-submit" });
      await api.put(`/bapd/${id}/sign-off`, buildSignOffPayload());
      return api.post(`/bapd/${id}/submit`, {});
    },
    onSuccess: () => {
      toast.success("BAPD approved through Final Approval & Sign Off!", { id: "bapd-submit" });
      qc.invalidateQueries({ queryKey: ["bapd", id] });
      qc.invalidateQueries({ queryKey: ["bapds"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
      setShowSignOffErrors(false);
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to submit BAPD sign-off", { id: "bapd-submit" });
    },
  });

  const legacyApprovalMutation = useMutation({
    mutationFn: ({ step, action }: { step: number; action: "approve" | "reject" }) =>
      api.post(`/bapd/${id}/approvals/${step}`, { action }),
    onSuccess: () => {
      toast.success("Legacy approval updated", { id: "bapd-legacy-approval" });
      qc.invalidateQueries({ queryKey: ["bapd", id] });
      qc.invalidateQueries({ queryKey: ["bapds"] });
      qc.invalidateQueries({ queryKey: ["dashboard"] });
    },
    onError: (e: any) => toast.error(e.message || "Failed to update legacy approval", { id: "bapd-legacy-approval" }),
  });

  const executeMutation = useMutation({
    mutationFn: () => {
      toast.loading("Executing permanent deletion & generating POD...", { id: "bapd-exec" });
      return api.post(`/bapd/${id}/execute`, { confirmation_phrase: CONFIRM_PHRASE });
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
    const datasetRowsHtml = (bapd.datasets.length ? bapd.datasets : [{ id: "legacy", dataset_name: bapd.dataset_name, dataset_location: bapd.dataset_location, source_type: null, display_order: 0 }]).map((dataset, index) => `<tr><td>${index + 1}</td><td>${escapeHtml(dataset.dataset_name)}</td><td class="font-mono">${escapeHtml(dataset.dataset_location)}</td><td>${escapeHtml(dataset.source_type || "—")}</td></tr>`).join("");
    const approvalMethodLabel = bapd.approval_method === "legacy_dual_approval" ? "Legacy Dual Approval" : "Form Sign-Off";
    const approvalSectionHtml = bapd.approval_method === "legacy_dual_approval"
      ? `<div class="section">
          <div class="section-title">4. Legacy Dual Approval History</div>
          <table>
            <thead><tr><th>Step</th><th>Role</th><th>Approver</th><th>Status</th><th>Actioned At</th><th>Comments</th></tr></thead>
            <tbody>${bapd.approvals.map((approval) => `<tr>
              <td>${escapeHtml(approval.step_order)}</td>
              <td>${escapeHtml(approval.approver_role.replace(/_/g, " "))}</td>
              <td>${escapeHtml(approval.approver_name)}</td>
              <td>${escapeHtml(approval.status)}</td>
              <td>${escapeHtml(approval.actioned_at ? formatDateTime(approval.actioned_at) : "—")}</td>
              <td>${escapeHtml(approval.comments)}</td>
            </tr>`).join("")}</tbody>
          </table>
        </div>`
      : `<div class="section">
          <div class="section-title">4. Final Approval &amp; Sign Off</div>
          <div class="grid2">
            <div class="field"><div class="field-label">Approved</div><div class="field-value">${escapeHtml(bapd.sign_off.approved || "Pending")}</div></div>
            <div class="field"><div class="field-label">Approval Method</div><div class="field-value">${escapeHtml(approvalMethodLabel)}</div></div>
            <div class="field"><div class="field-label">Prepared By</div><div class="field-value">${escapeHtml(bapd.sign_off.prepared_by)}</div></div>
            <div class="field"><div class="field-label">Prepared Position</div><div class="field-value">${escapeHtml(bapd.sign_off.prepared_position)}</div></div>
            <div class="field"><div class="field-label">Prepared Signature</div><div class="field-value">${bapd.sign_off.prepared_signature ? "Signed" : "Not signed"}</div></div>
            <div class="field"><div class="field-label">Prepared Date</div><div class="field-value">${escapeHtml(bapd.sign_off.prepared_date)}</div></div>
            <div class="field"><div class="field-label">Acknowledged By</div><div class="field-value">${escapeHtml(bapd.sign_off.acknowledged_by)}</div></div>
            <div class="field"><div class="field-label">Acknowledged Position</div><div class="field-value">${escapeHtml(bapd.sign_off.acknowledged_position)}</div></div>
            <div class="field"><div class="field-label">Acknowledged Signature</div><div class="field-value">${bapd.sign_off.acknowledged_signature ? "Signed" : "Not signed"}</div></div>
            <div class="field"><div class="field-label">Acknowledged Date</div><div class="field-value">${escapeHtml(bapd.sign_off.acknowledged_date)}</div></div>
          </div>
        </div>`;
    const bodyHtml = `
      <div class="pdf-header">
        <div>
          <div class="brand">DATA GOVERNANCE &amp; PRIVACY COMPLIANCE</div>
          <div style="font-size: 9pt; color: #718096; margin-top: 2px;">Berita Acara Pemusnahan Data (BAPD) — UU PDP No. 27/2022</div>
        </div>
        <div class="meta">
          <div><strong>Doc No:</strong> BAPD-${escapeHtml(bapd.id.slice(0, 8).toUpperCase())}</div>
          <div><strong>Status:</strong> ${escapeHtml(bapd.status.toUpperCase())}</div>
          <div><strong>Date:</strong> ${escapeHtml(formatDate(bapd.executed_at || bapd.updated_at || bapd.created_at))}</div>
        </div>
      </div>

      <h1 class="doc-title">BERITA ACARA PEMUSNAHAN DATA</h1>
      <div class="doc-subtitle">Official Certificate of Data Disposal &amp; Extermination — Version ${escapeHtml(bapd.version)}</div>

      <div class="section">
        <div class="section-title">1. Project &amp; Controller Identity</div>
        <div class="grid2">
          <div class="field"><div class="field-label">Project Code</div><div class="field-value">${escapeHtml(bapd.project_code)}</div></div>
          <div class="field"><div class="field-label">Project Name</div><div class="field-value">${escapeHtml(bapd.project_name)}</div></div>
          <div class="field"><div class="field-label">Data Controller / Client</div><div class="field-value">${escapeHtml(bapd.customer_name)}</div></div>
          <div class="field"><div class="field-label">Responsible Executing Party</div><div class="field-value">${escapeHtml(bapd.responsible_party_name)}</div></div>
        </div>
      </div>

        <div class="section">
          <div class="section-title">2. Target Dataset &amp; Storage Identification</div>
          <table>
            <thead><tr><th>No.</th><th>Dataset Name</th><th>Exact Storage Location URI</th><th>Source Type</th></tr></thead>
            <tbody>${datasetRowsHtml}</tbody>
          </table>
          <div class="grid2" style="margin-top: 10px;">
            <div class="field"><div class="field-label">Retention Policy Category</div><div class="field-value">${escapeHtml(bapd.retention_policy_name || "Manual Expiry")}</div></div>
            <div class="field"><div class="field-label">Retention Expiry Date</div><div class="field-value">${escapeHtml(formatDate(bapd.expiry_date))}</div></div>
            <div class="field full-width"><div class="field-label">Extermination Execution Date</div><div class="field-value">${escapeHtml(bapd.executed_at ? formatDateTime(bapd.executed_at) : "Pending Execution")}</div></div>
          </div>
        </div>

      <div class="section">
        <div class="section-title">3. Disposal Justification &amp; Regulatory Basis</div>
        <div class="field full-width">
          <div class="field-label">Justification / Reason for Extermination</div>
          <div class="field-value" style="margin-top: 4px; line-height: 1.6;">${escapeHtml(bapd.reason)}</div>
        </div>
      </div>

      ${approvalSectionHtml}

      ${bapd.pod_file_path ? `
        <div class="section">
          <div class="section-title">5. Proof of Deletion (POD) Verification</div>
          <div class="field full-width">
            <div class="field-label">POD Storage Reference</div>
            <div class="field-value font-mono" style="font-size: 8.5pt;">${escapeHtml(bapd.pod_file_path)}</div>
          </div>
        </div>
      ` : ""}
    `;
    printA4(`BAPD - ${escapeHtml(bapd.dataset_name)}`, bodyHtml);
  }

  if (isLoading) return <DetailSkeleton />;
  if (!bapd) return <div className="p-6 text-red-500 font-mono">BAPD record not found</div>;

  const isLegacyApproval = bapd.approval_method === "legacy_dual_approval";
  const NEXT_STATES: Record<string, string[]> = isLegacyApproval
    ? {
        draft: ["submitted"],
        submitted: ["under_review", "rejected"],
        executed: ["archived"],
      }
    : { executed: ["archived"] };
  const nextStates = NEXT_STATES[bapd.status] ?? [];
  const isDraft = bapd.status === "draft" && bapd.approval_method === "form_sign_off";
  const CONFIRM_PHRASE = "DELETE PERMANENTLY";

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
              {bapd.datasets.length > 1 && (
                <div className="sm:col-span-2">
                  <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">All Documented Datasets ({bapd.datasets.length})</dt>
                  <dd className="mt-1 space-y-1">
                    {bapd.datasets.map((dataset, index) => (
                      <div key={dataset.id} className="rounded border border-slate-100 bg-slate-50 p-2 text-xs">
                        <div className="font-medium text-slate-900">{index + 1}. {dataset.dataset_name}</div>
                        <div className="font-mono text-slate-600 break-all mt-0.5">{dataset.dataset_location}</div>
                      </div>
                    ))}
                  </dd>
                </div>
              )}
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
                <h2 className="text-xs font-semibold font-mono text-rose-900 uppercase tracking-wider">Final Approval &amp; Sign Off Complete — Ready to Execute</h2>
              </div>
              <p className="text-xs text-rose-800">
                Final sign-off is complete. To permanently delete all {bapd.datasets.length || 1} documented dataset{(bapd.datasets.length || 1) === 1 ? "" : "s"} and generate the Proof of Deletion,
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

        {/* Right: final sign-off */}
        <div className="space-y-4">
          <div className="bg-white rounded-md border border-slate-200 shadow-2xs p-4">
            {bapd.approval_method === "legacy_dual_approval" ? (
              <>
                <h2 className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800 border-b border-slate-100 pb-2 mb-3">Legacy Approval Record</h2>
                <p className="text-xs text-slate-600 leading-relaxed mb-3">
                  This BAPD uses the former dual-approval workflow. Historical approval data remains readable and actionable for authorized users.
                </p>
                <div className="space-y-2">
                  {bapd.approvals.map((approval) => (
                    <div key={approval.id} className="border border-slate-200 rounded-md p-2.5">
                      <div className="flex items-center justify-between gap-2">
                        <div>
                          <p className="text-xs font-semibold text-slate-800">Step {approval.step_order} · {approval.approver_role.replace(/_/g, " ")}</p>
                          <p className="text-[11px] text-slate-500">{approval.approver_name || "Unassigned approver"}</p>
                          {approval.actioned_at && <p className="text-[10px] text-slate-400">Actioned: {formatDateTime(approval.actioned_at)}</p>}
                          {approval.comments && <p className="text-[11px] text-slate-600 mt-1">Comment: {approval.comments}</p>}
                        </div>
                        <Badge variant={approval.status === "approved" ? "success" : approval.status === "rejected" ? "danger" : "warning"} className="text-[10px] uppercase">{approval.status}</Badge>
                      </div>
                      {(approval.status === "requested") && (
                        <div className="mt-2 flex gap-2">
                          <Button
                            type="button"
                            size="sm"
                            className="h-7 text-xs"
                            disabled={legacyApprovalMutation.isPending}
                            onClick={() => legacyApprovalMutation.mutate({ step: approval.step_order, action: "approve" })}
                          >Approve</Button>
                          <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            className="h-7 text-xs text-rose-700"
                            disabled={legacyApprovalMutation.isPending}
                            onClick={() => legacyApprovalMutation.mutate({ step: approval.step_order, action: "reject" })}
                          >Reject</Button>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <>
                <FinalApprovalSignOff
                  value={signOffDraft}
                  onChange={(field, value) => setSignOffDraft((current) => ({ ...current, [field]: value }))}
                  disabled={!isDraft || (!isProjectSme && !isConfiguredDataOwner)}
                  showErrors={showSignOffErrors}
                  approvalOnly={isProjectSme}
                  approvedReadOnly={!isProjectSme}
                  acknowledgedReadOnly={!isProjectSme}
                  acknowledgedSignatureReadOnly={!isProjectSme}
                  acknowledgedNameReadOnly={isProjectSme}
                  acknowledgedPositionReadOnly={isProjectSme}
                  preparedReadOnly={!isConfiguredDataOwner && !canSmePrepareOnBehalf}
                  prepareOnBehalf={canSmePrepareOnBehalf}
                  preparedNameReadOnly={Boolean(projectOwners?.some((owner) => owner.role_type === "data_owner")) || canSmePrepareOnBehalf}
                  preparedPositionReadOnly={Boolean(projectOwners?.find((owner) => owner.role_type === "data_owner")?.position) || canSmePrepareOnBehalf}
                />
                {isDraft && (isProjectSme || isConfiguredDataOwner) && (
                  <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-slate-100 pt-3">
                    {isConfiguredDataOwner && (
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="h-8 text-xs"
                        disabled={signOffMutation.isPending || submitMutation.isPending}
                        onClick={() => signOffMutation.mutate()}
                      >
                        {signOffMutation.isPending ? "Saving…" : "Save Prepared Sign-Off"}
                      </Button>
                    )}
                    {isProjectSme ? (
                      <Button
                        type="button"
                        size="sm"
                        className="h-8 text-xs font-medium"
                        disabled={signOffMutation.isPending || submitMutation.isPending}
                        onClick={() => {
                          setShowSignOffErrors(true);
                          submitMutation.mutate();
                        }}
                      >
                        {submitMutation.isPending ? "Approving…" : "Approve & Submit BAPD"}
                      </Button>
                    ) : (
                      <span className="text-[11px] text-slate-500 font-mono">Prepared sign-off is saved by the configured Project Data Owner.</span>
                    )}
                  </div>
                )}
                {isDraft && !isProjectSme && !isConfiguredDataOwner && (
                  <p className="mt-4 text-[11px] text-slate-500 font-mono border-t border-slate-100 pt-3">
                    View-only for this account. The Project Data Owner prepares the sign-off; the assigned Project SME approves and submits the BAPD.
                  </p>
                )}
                {bapd.is_final_signed && bapd.status === "draft" && (
                  <p className="mt-3 text-xs text-emerald-700 bg-emerald-50 border border-emerald-200 rounded p-2">
                    Sign-off is complete and awaiting final submission by the Project SME.
                  </p>
                )}
              </>
            )}
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
