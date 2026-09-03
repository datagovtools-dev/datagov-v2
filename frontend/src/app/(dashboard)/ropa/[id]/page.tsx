"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import Link from "next/link";
import { ArrowLeft, Printer, FolderKanban, ShieldCheck, Database, FileText, CheckCircle2 } from "lucide-react";
import { api } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { DetailModal } from "@/components/details/DetailModal";
import { ProjectDetailCards, ProjectDetailLike, UserOptionLike, OwnerRecordLike } from "@/components/details/ProjectDetailView";
import { AssetSelectorModal, ProjectOption } from "@/components/ropa/AssetSelectorModal";
import { printA4 } from "@/lib/exportPdf";
import { toast } from "@/components/ui/Toast";
import { formatDate, formatDateTime } from "@/lib/utils";

interface ROPADetail {
  id: string;
  project_id: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
  process_name: string;
  purpose: string;
  data_category: string;
  data_subject: string;
  legal_basis: string;
  retention_period: string;
  recipient: string | null;
  linked_asset_ids: string[] | null;
  status: string;
  version: number;
  created_by: string;
  created_by_name: string | null;
  created_at: string;
  updated_at: string;
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "neutral" | "info";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "neutral",
    submitted: "warning",
    under_review: "info",
    approved: "success",
    rejected: "danger",
    archived: "default",
  };
  return map[status] ?? "default";
}

export default function ROPADetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const currentUser = useAuthStore((s) => s.user);
  const [transitionTarget, setTransitionTarget] = useState("");
  const [transitionComment, setTransitionComment] = useState("");
  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<ROPADetail>>({});
  const [editCustomAsset, setEditCustomAsset] = useState("");
  const [isProjectModalOpen, setIsProjectModalOpen] = useState(false);
  const [isAssetModalOpen, setIsAssetModalOpen] = useState(false);

  const { data: ropa, isLoading } = useQuery<ROPADetail>({
    queryKey: ["ropa", id],
    queryFn: () => api.get<ROPADetail>(`/ropa/${id}`),
  });

  const { data: project } = useQuery<ProjectDetailLike>({
    queryKey: ["project", ropa?.project_id],
    queryFn: () => api.get<ProjectDetailLike>(`/projects/${ropa?.project_id}`),
    enabled: !!ropa?.project_id,
  });

  const { data: projects = [] } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: projectUsers } = useQuery<UserOptionLike[]>({
    queryKey: ["project-users-options"],
    queryFn: () => api.get<UserOptionLike[]>("/projects/users/options"),
    enabled: isProjectModalOpen,
  });

  const { data: projectOwners } = useQuery<OwnerRecordLike[]>({
    queryKey: ["project-owners", ropa?.project_id],
    queryFn: () => api.get<OwnerRecordLike[]>(`/metadata/owners/${ropa?.project_id}`),
    enabled: isProjectModalOpen && !!ropa?.project_id,
  });

  const { data: legalBasisOptions } = useQuery<string[]>({
    queryKey: ["legal-basis-options"],
    queryFn: () => api.get<string[]>("/ropa/legal-basis-options"),
  });

  const transitionMutation = useMutation({
    mutationFn: () =>
      api.post(`/ropa/${id}/transition`, {
        target_status: transitionTarget,
        comments: transitionComment,
      }),
    onSuccess: () => {
      toast.success(`ROPA status moved to ${transitionTarget.replace("_", " ")}`);
      qc.invalidateQueries({ queryKey: ["ropa", id] });
      qc.invalidateQueries({ queryKey: ["ropas"] });
      setTransitionTarget("");
      setTransitionComment("");
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to transition ROPA status");
    },
  });

  const updateMutation = useMutation({
    mutationFn: () => api.put(`/ropa/${id}`, editForm),
    onSuccess: () => {
      toast.success("ROPA record updated successfully!");
      qc.invalidateQueries({ queryKey: ["ropa", id] });
      qc.invalidateQueries({ queryKey: ["ropas"] });
      setEditing(false);
      setEditForm({});
      setEditCustomAsset("");
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to update ROPA record");
    },
  });

  if (isLoading) return <div className="p-8 text-center text-slate-400 font-mono text-xs">Loading ROPA record…</div>;
  if (!ropa) return <div className="p-8 text-center text-rose-500 font-mono text-xs">Record not found</div>;

  const NEXT_STATES: Record<string, string[]> = {
    draft: ["submitted"],
    submitted: ["under_review", "rejected"],
    under_review: ["approved", "rejected"],
    approved: ["archived"],
    rejected: ["draft"],
  };
  const nextStates = NEXT_STATES[ropa.status] ?? [];
  const canEdit = ropa.status !== "approved" || (currentUser?.is_super_admin ?? false);

  function startEdit() {
    if (!ropa) return;
    setEditForm({
      process_name: ropa.process_name,
      purpose: ropa.purpose,
      data_category: ropa.data_category,
      data_subject: ropa.data_subject,
      legal_basis: ropa.legal_basis,
      retention_period: ropa.retention_period,
      recipient: ropa.recipient ?? "",
      linked_asset_ids: ropa.linked_asset_ids ? [...ropa.linked_asset_ids] : [],
    });
    setEditing(true);
  }

  function handleAddEditAsset() {
    const trimmed = editCustomAsset.trim();
    if (!trimmed) {
      setIsAssetModalOpen(true);
      return;
    }
    const current = editForm.linked_asset_ids ?? [];
    if (!current.includes(trimmed)) {
      setEditForm((f) => ({ ...f, linked_asset_ids: [...current, trimmed] }));
      toast.success(`Added asset: ${trimmed}`);
    } else {
      toast.info(`Asset "${trimmed}" is already added.`);
    }
    setEditCustomAsset("");
  }

  function handleRemoveEditAsset(assetName: string) {
    setEditForm((f) => ({
      ...f,
      linked_asset_ids: (f.linked_asset_ids ?? []).filter((a) => a !== assetName),
    }));
  }

  function handleExportPdf() {
    if (!ropa) return;
    const bodyHtml = `
      <div class="pdf-header">
        <div>
          <div class="brand">DATA GOVERNANCE &amp; PRIVACY COMPLIANCE</div>
          <div style="font-size: 9pt; color: #718096; margin-top: 2px;">Record of Processing Activities (ROPA) — UU PDP No. 27/2022 &amp; GDPR Art. 30</div>
        </div>
        <div class="meta">
          <div><strong>Version:</strong> v${ropa.version}</div>
          <div><strong>Status:</strong> ${ropa.status.toUpperCase()}</div>
          <div><strong>Date:</strong> ${formatDate(ropa.updated_at || ropa.created_at)}</div>
        </div>
      </div>

      <h1 class="doc-title">${ropa.process_name}</h1>
      <div class="doc-subtitle">Processing Activity Reference &amp; Lawful Registry</div>

      <div class="section">
        <div class="section-title">1. Project &amp; Controller Identity</div>
        <div class="grid2">
          <div class="field"><div class="field-label">Project Code</div><div class="field-value">${ropa.project_code || "—"}</div></div>
          <div class="field"><div class="field-label">Project Name</div><div class="field-value">${ropa.project_name || "—"}</div></div>
          <div class="field"><div class="field-label">Data Controller / Client</div><div class="field-value">${ropa.customer_name || "—"}</div></div>
          <div class="field"><div class="field-label">Created By</div><div class="field-value">${ropa.created_by_name || "—"}</div></div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">2. Processing Scope &amp; Business Purpose</div>
        <div class="field full-width">
          <div class="field-label">Purpose of Processing</div>
          <div class="field-value" style="margin-top: 4px; line-height: 1.6;">${ropa.purpose}</div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">3. Data Categories, Subjects &amp; Legal Framework</div>
        <div class="grid2">
          <div class="field"><div class="field-label">Data Category</div><div class="field-value">${ropa.data_category}</div></div>
          <div class="field"><div class="field-label">Data Subject Population</div><div class="field-value">${ropa.data_subject}</div></div>
          <div class="field"><div class="field-label">Lawful Legal Basis</div><div class="field-value">${ropa.legal_basis}</div></div>
          <div class="field"><div class="field-label">Retention Period</div><div class="field-value">${ropa.retention_period}</div></div>
        </div>
      </div>

      <div class="section">
        <div class="section-title">4. Third-Party Sharing &amp; Linked Assets</div>
        <div class="grid2">
          <div class="field full-width"><div class="field-label">Recipients / Processors</div><div class="field-value">${ropa.recipient || "None (Internal Only)"}</div></div>
          <div class="field full-width">
            <div class="field-label">Linked Catalogue Assets</div>
            <div class="field-value" style="font-family: monospace; font-size: 8.5pt; margin-top: 2px;">
              ${ropa.linked_asset_ids?.length ? ropa.linked_asset_ids.join(", ") : "—"}
            </div>
          </div>
        </div>
      </div>

      <div class="section" style="margin-top: 30px;">
        <div class="section-title">5. Sign-Off &amp; Governance Verification</div>
        <div class="sig-grid">
          <div class="sig-box">
            <div class="sig-title">Data Protection / Compliance Officer</div>
            <div style="margin-top: 35px; border-bottom: 1px solid #CBD5E0;"></div>
            <div class="sig-meta" style="margin-top: 4px;">Status: ${ropa.status === "approved" ? "APPROVED &amp; SIGNED" : ropa.status.toUpperCase()}</div>
          </div>
          <div class="sig-box">
            <div class="sig-title">Data Owner / Governance Officer</div>
            <div style="margin-top: 35px; border-bottom: 1px solid #CBD5E0;"></div>
            <div class="sig-meta" style="margin-top: 4px;">Date: ${formatDate(ropa.updated_at)}</div>
          </div>
        </div>
      </div>
    `;
    printA4(`ROPA-${ropa.process_name}`, bodyHtml);
  }

  return (
    <div className="space-y-4 w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-3 pb-3 border-b border-slate-200">
        <div>
          <div className="flex items-center gap-2.5">
            <Link href="/ropa" className="text-slate-500 hover:text-slate-800 text-xs font-mono flex items-center gap-1">
              <ArrowLeft className="h-3.5 w-3.5" /> Back to ROPA List
            </Link>
            <Badge variant={statusVariant(ropa.status)} className="text-[10px] uppercase font-mono">
              {ropa.status.replace("_", " ")}
            </Badge>
            <span className="text-[10px] bg-slate-100 text-slate-700 border border-slate-200 px-1.5 py-0.5 rounded-md font-mono">
              v{ropa.version}
            </span>
          </div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-1">{ropa.process_name}</h1>
          <p className="text-xs text-slate-500 font-mono mt-0.5">
            Created {formatDate(ropa.created_at)} by {ropa.created_by_name ?? "User"} · Last updated {formatDateTime(ropa.updated_at)}
          </p>
        </div>

        <div className="flex items-center gap-2 flex-wrap">
          <Button variant="outline" size="sm" className="h-8 text-xs font-medium" onClick={handleExportPdf}>
            <Printer className="h-3.5 w-3.5 mr-1" /> Export PDF
          </Button>

          {canEdit && !editing && (
            <Button variant="outline" size="sm" className="h-8 text-xs font-medium" onClick={startEdit}>
              Edit Activity
            </Button>
          )}

          {nextStates.length > 0 && (
            <div className="flex items-center gap-1.5">
              <select
                value={transitionTarget}
                onChange={(e) => setTransitionTarget(e.target.value)}
                className="border border-slate-200 rounded-md px-2 py-1.5 text-xs font-mono focus:outline-none focus:ring-1 focus:ring-slate-400 bg-white h-8"
              >
                <option value="">Move status to…</option>
                {nextStates.map((s) => (
                  <option key={s} value={s}>
                    {s.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
                  </option>
                ))}
              </select>
              <Button
                size="sm"
                className="h-8 text-xs font-medium"
                disabled={!transitionTarget || transitionMutation.isPending}
                onClick={() => transitionMutation.mutate()}
                loading={transitionMutation.isPending}
              >
                Apply Transition
              </Button>
            </div>
          )}
        </div>
      </div>

      {transitionTarget && (
        <div className="p-3 bg-blue-50 border border-blue-200 rounded-md">
          <label className="text-xs font-semibold text-blue-900 block mb-1">
            Optional Comments for Transition ({transitionTarget}):
          </label>
          <Input
            placeholder="Add transition notes or justification..."
            value={transitionComment}
            onChange={(e) => setTransitionComment(e.target.value)}
            className="h-8 text-xs bg-white"
          />
        </div>
      )}

      {/* Project Context Summary Card */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100 flex flex-row items-center justify-between">
          <div>
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800 flex items-center gap-2">
              <FolderKanban className="h-4 w-4 text-slate-500" />
              Associated Project Information
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Project details and data controller identity</CardDescription>
          </div>
          {ropa.project_id && (
            <Button
              variant="outline"
              size="sm"
              className="h-7 text-xs"
              onClick={() => setIsProjectModalOpen(true)}
            >
              View Full Project Details
            </Button>
          )}
        </CardHeader>
        <CardContent className="pt-4 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4 text-xs">
          <div>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono block">Project Code</span>
            <span className="font-semibold text-slate-900 font-mono mt-0.5 block">{ropa.project_code ?? "—"}</span>
          </div>
          <div>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono block">Project Name</span>
            <span className="font-medium text-slate-900 mt-0.5 block truncate" title={ropa.project_name}>{ropa.project_name ?? "—"}</span>
          </div>
          <div>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono block">Data Controller / Client</span>
            <span className="font-medium text-slate-900 mt-0.5 block truncate">{ropa.customer_name ?? "—"}</span>
          </div>
          <div>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono block">Compliance Framework</span>
            <span className="text-slate-700 mt-0.5 block font-mono text-[11px]">UU PDP &amp; GDPR Art. 30</span>
          </div>
        </CardContent>
      </Card>

      {/* Main Processing Activity Details */}
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100 flex flex-row items-center justify-between">
          <div>
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800 flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-slate-500" />
              Processing Activity Details
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Lawful basis, data categories, and retention schedule</CardDescription>
          </div>
          {editing && (
            <div className="flex gap-2">
              <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => { setEditing(false); setEditForm({}); }}>
                Cancel
              </Button>
              <Button size="sm" className="h-7 text-xs font-medium" disabled={updateMutation.isPending} onClick={() => updateMutation.mutate()} loading={updateMutation.isPending}>
                Save Changes
              </Button>
            </div>
          )}
        </CardHeader>
        <CardContent className="pt-4">
          {editing ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Processing Activity Name</label>
                <Input
                  value={editForm.process_name ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, process_name: e.target.value }))}
                  className="h-8 text-xs"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Legal Basis</label>
                <select
                  value={editForm.legal_basis ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, legal_basis: e.target.value }))}
                  className="w-full border border-slate-200 rounded-md px-2.5 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 bg-white h-8"
                >
                  {legalBasisOptions?.map((b) => <option key={b} value={b}>{b}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Data Category</label>
                <Input
                  value={editForm.data_category ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, data_category: e.target.value }))}
                  className="h-8 text-xs"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Data Subject Population</label>
                <Input
                  value={editForm.data_subject ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, data_subject: e.target.value }))}
                  className="h-8 text-xs"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Retention Period</label>
                <Input
                  value={editForm.retention_period ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, retention_period: e.target.value }))}
                  className="h-8 text-xs font-mono"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">Recipient Organizations / Third Parties</label>
                <Input
                  value={editForm.recipient ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, recipient: e.target.value }))}
                  className="h-8 text-xs"
                />
              </div>
              <div className="col-span-1 md:col-span-2">
                <label className="block text-xs font-semibold text-slate-700 mb-1">Purpose of Processing</label>
                <textarea
                  value={editForm.purpose ?? ""}
                  rows={3}
                  onChange={(e) => setEditForm((f) => ({ ...f, purpose: e.target.value }))}
                  className="w-full border border-slate-200 rounded-md px-2.5 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 resize-none font-sans"
                />
              </div>

              {/* Linked Assets Edit Section */}
              <div className="col-span-1 md:col-span-2 space-y-2 pt-2 border-t border-slate-100">
                <label className="block text-xs font-semibold text-slate-700">Linked Data Assets / Tables</label>
                <div className="flex flex-col sm:flex-row gap-2">
                  <Input
                    value={editCustomAsset}
                    onChange={(e) => setEditCustomAsset(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        handleAddEditAsset();
                      }
                    }}
                    placeholder="Type custom asset name and press Add..."
                    className="h-8 text-xs font-mono flex-1"
                  />
                  <div className="flex gap-2 shrink-0">
                    <Button type="button" size="sm" onClick={handleAddEditAsset} className="h-8 text-xs font-medium">
                      Add Asset
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => setIsAssetModalOpen(true)}
                      className="h-8 text-xs font-medium text-blue-700 border-blue-200 bg-blue-50/60 hover:bg-blue-100"
                    >
                      <Database className="h-3.5 w-3.5 mr-1.5 text-blue-600" /> Browse Catalog
                    </Button>
                  </div>
                </div>

                {/* Selected chips in edit mode */}
                {(editForm.linked_asset_ids ?? []).length > 0 ? (
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {(editForm.linked_asset_ids ?? []).map((asset) => (
                      <Badge
                        key={asset}
                        variant="info"
                        className="text-xs px-2.5 py-1 font-mono flex items-center gap-1.5 bg-blue-50 text-blue-700 border border-blue-200"
                      >
                        {asset}
                        <button
                          type="button"
                          onClick={() => handleRemoveEditAsset(asset)}
                          className="hover:text-blue-900 rounded-full"
                        >
                          ✕
                        </button>
                      </Badge>
                    ))}
                  </div>
                ) : (
                  <p className="text-[11px] text-slate-400 font-sans">No assets linked yet.</p>
                )}
              </div>
            </div>
          ) : (
            <dl className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4 text-xs">
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Data Category</dt>
                <dd className="font-medium text-slate-900 mt-0.5">{ropa.data_category}</dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Data Subject Population</dt>
                <dd className="font-medium text-slate-900 mt-0.5">{ropa.data_subject}</dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Lawful Legal Basis</dt>
                <dd className="mt-0.5">
                  <span className="inline-block bg-slate-100 text-slate-800 text-[11px] px-2 py-0.5 rounded-md border border-slate-200 font-mono font-medium">
                    {ropa.legal_basis}
                  </span>
                </dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Retention Period</dt>
                <dd className="font-mono font-medium text-slate-900 mt-0.5">{ropa.retention_period}</dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Recipients / Third Parties</dt>
                <dd className="text-slate-900 mt-0.5">{ropa.recipient || <span className="text-slate-400">None (Internal Only)</span>}</dd>
              </div>
              <div>
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Workflow Status</dt>
                <dd className="mt-0.5">
                  <Badge variant={statusVariant(ropa.status)} className="text-[10px] uppercase font-mono">
                    {ropa.status.replace("_", " ")}
                  </Badge>
                </dd>
              </div>
              <div className="col-span-1 md:col-span-2">
                <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">Purpose of Processing</dt>
                <dd className="mt-1 leading-relaxed text-slate-800 bg-slate-50 p-3 rounded-md border border-slate-100">{ropa.purpose}</dd>
              </div>
              {ropa.linked_asset_ids?.length ? (
                <div className="col-span-1 md:col-span-2">
                  <dt className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1.5 flex items-center gap-1.5">
                    <Database className="h-3.5 w-3.5 text-slate-500" />
                    Linked Data Assets &amp; Catalogue Tables
                  </dt>
                  <dd className="flex flex-wrap gap-1.5">
                    {ropa.linked_asset_ids.map((assetId) => (
                      <span key={assetId} className="font-mono text-xs bg-blue-50 text-blue-700 px-2.5 py-1 rounded-md border border-blue-200 font-medium">
                        {assetId}
                      </span>
                    ))}
                  </dd>
                </div>
              ) : null}
            </dl>
          )}
        </CardContent>
      </Card>

      {/* Version Governance Footer */}
      <div className="bg-slate-50 border border-slate-200 rounded-md p-3.5 text-xs text-slate-700 font-mono flex items-center justify-between">
        <div>
          <span className="font-semibold text-slate-900">Governance Version: v{ropa.version}</span>
          <p className="text-[11px] text-slate-500 mt-0.5 font-sans">
            Version increments automatically when the record is approved. Approved records are locked for regulatory integrity.
          </p>
        </div>
        {ropa.status === "approved" && (
          <span className="flex items-center gap-1 text-emerald-600 font-semibold text-xs">
            <CheckCircle2 className="h-4 w-4" /> Compliance Certified
          </span>
        )}
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
      {/* Asset Selector Catalog Modal */}
      <AssetSelectorModal
        isOpen={isAssetModalOpen}
        onClose={() => setIsAssetModalOpen(false)}
        selectedAssets={editForm.linked_asset_ids ?? []}
        onSave={(assets) => {
          setEditForm((f) => ({ ...f, linked_asset_ids: assets }));
          toast.success(`Updated linked assets (${assets.length} selected)`);
        }}
        initialProjectId={ropa.project_id}
        projects={projects}
      />
    </div>
  );
}
