"use client";

import { useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { formatDate, formatDateTime } from "@/lib/utils";

interface ROPADetail {
  id: string;
  project_id: string;
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
  created_at: string;
  updated_at: string;
}

export default function ROPADetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const qc = useQueryClient();
  const [transitionTarget, setTransitionTarget] = useState("");
  const [transitionComment, setTransitionComment] = useState("");
  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<ROPADetail>>({});

  const { data: ropa, isLoading } = useQuery<ROPADetail>({
    queryKey: ["ropa", id],
    queryFn: () => api.get<ROPADetail>(`/ropa/${id}`),
  });

  const { data: legalBasisOptions } = useQuery<string[]>({
    queryKey: ["legal-basis-options"],
    queryFn: () => api.get<string[]>("/ropa/legal-basis-options"),
  });

  const transitionMutation = useMutation({
    mutationFn: () => api.post(`/ropa/${id}/transition`, { target_status: transitionTarget, comments: transitionComment }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["ropa", id] }); setTransitionTarget(""); },
  });

  const updateMutation = useMutation({
    mutationFn: () => api.put(`/ropa/${id}`, editForm),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["ropa", id] }); setEditing(false); setEditForm({}); },
  });

  if (isLoading) return <div className="p-6 text-gray-400">Loading…</div>;
  if (!ropa) return <div className="p-6 text-red-500">Record not found</div>;

  const NEXT_STATES: Record<string, string[]> = {
    draft: ["submitted"],
    submitted: ["under_review", "rejected"],
    under_review: ["approved", "rejected"],
    approved: ["archived"],
    rejected: ["draft"],
  };
  const nextStates = NEXT_STATES[ropa.status] ?? [];
  const canEdit = ropa.status !== "approved";

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
    });
    setEditing(true);
  }

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <div className="flex items-center gap-3">
            <button onClick={() => router.back()} className="text-gray-400 hover:text-gray-600 text-sm">← Back</button>
            <Badge variant={statusVariant(ropa.status)}>{ropa.status.replace("_", " ")}</Badge>
            <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded font-mono">v{ropa.version}</span>
          </div>
          <h1 className="text-2xl font-bold text-gray-900 mt-1">{ropa.process_name}</h1>
          <p className="text-sm text-gray-500">Created {formatDate(ropa.created_at)} · Last updated {formatDateTime(ropa.updated_at)}</p>
        </div>
        <div className="flex items-end gap-2 flex-shrink-0">
          {canEdit && !editing && (
            <Button variant="outline" size="sm" onClick={startEdit}>Edit</Button>
          )}
          {nextStates.length > 0 && (
            <>
              <select value={transitionTarget} onChange={(e) => setTransitionTarget(e.target.value)}
                className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">Move to…</option>
                {nextStates.map((s) => <option key={s} value={s}>{s.replace("_", " ")}</option>)}
              </select>
              <Button size="sm" disabled={!transitionTarget || transitionMutation.isPending}
                onClick={() => transitionMutation.mutate()}>Apply</Button>
            </>
          )}
        </div>
      </div>

      {transitionTarget && (
        <Input placeholder="Optional comment…" value={transitionComment}
          onChange={(e) => setTransitionComment(e.target.value)} className="max-w-lg" />
      )}

      {/* Main record */}
      <div className="bg-white rounded-lg shadow p-5 space-y-4">
        <div className="flex items-center justify-between border-b pb-3">
          <h2 className="font-semibold text-gray-800">Processing Activity Details</h2>
          {editing && (
            <div className="flex gap-2">
              <Button size="sm" variant="outline" onClick={() => { setEditing(false); setEditForm({}); }}>Cancel</Button>
              <Button size="sm" disabled={updateMutation.isPending} onClick={() => updateMutation.mutate()}>
                {updateMutation.isPending ? "Saving…" : "Save Changes"}
              </Button>
            </div>
          )}
        </div>

        {editing ? (
          <div className="grid grid-cols-2 gap-4">
            {[
              { field: "process_name", label: "Process Name" },
              { field: "data_category", label: "Data Category" },
              { field: "data_subject", label: "Data Subject" },
              { field: "retention_period", label: "Retention Period" },
              { field: "recipient", label: "Recipient" },
            ].map(({ field, label }) => (
              <div key={field}>
                <label className="block text-xs font-medium text-gray-500 mb-1">{label}</label>
                <Input
                  value={(editForm as Record<string, string>)[field] ?? ""}
                  onChange={(e) => setEditForm((f) => ({ ...f, [field]: e.target.value }))}
                />
              </div>
            ))}
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Legal Basis</label>
              <select value={editForm.legal_basis ?? ""}
                onChange={(e) => setEditForm((f) => ({ ...f, legal_basis: e.target.value }))}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                {legalBasisOptions?.map((b) => <option key={b} value={b}>{b}</option>)}
              </select>
            </div>
            <div className="col-span-2">
              <label className="block text-xs font-medium text-gray-500 mb-1">Purpose</label>
              <textarea value={editForm.purpose ?? ""} rows={3}
                onChange={(e) => setEditForm((f) => ({ ...f, purpose: e.target.value }))}
                className="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none" />
            </div>
          </div>
        ) : (
          <dl className="grid grid-cols-2 gap-x-6 gap-y-4 text-sm">
            <div><dt className="text-gray-500">Data Category</dt><dd className="font-medium mt-0.5">{ropa.data_category}</dd></div>
            <div><dt className="text-gray-500">Data Subject</dt><dd className="font-medium mt-0.5">{ropa.data_subject}</dd></div>
            <div>
              <dt className="text-gray-500">Legal Basis</dt>
              <dd className="mt-0.5">
                <span className="inline-block bg-blue-50 text-blue-700 text-xs px-2 py-0.5 rounded-full border border-blue-200 font-medium">
                  {ropa.legal_basis}
                </span>
              </dd>
            </div>
            <div><dt className="text-gray-500">Retention Period</dt><dd className="font-medium mt-0.5">{ropa.retention_period}</dd></div>
            <div><dt className="text-gray-500">Recipient</dt><dd className="mt-0.5">{ropa.recipient ?? "—"}</dd></div>
            <div className="col-span-2">
              <dt className="text-gray-500">Purpose</dt>
              <dd className="mt-1 leading-relaxed">{ropa.purpose}</dd>
            </div>
            {ropa.linked_asset_ids?.length ? (
              <div className="col-span-2">
                <dt className="text-gray-500 mb-1">Linked Assets</dt>
                <dd className="flex flex-wrap gap-1">
                  {ropa.linked_asset_ids.map((assetId) => (
                    <span key={assetId} className="font-mono text-xs bg-gray-100 text-gray-700 px-2 py-0.5 rounded border">
                      {assetId}
                    </span>
                  ))}
                </dd>
              </div>
            ) : null}
          </dl>
        )}
      </div>

      {/* Version history note */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-sm text-blue-700">
        <span className="font-medium">Version {ropa.version}</span>
        {" — "}Version increments automatically when this record is approved. Approved records cannot be edited; reject to draft to make changes.
      </div>
    </div>
  );
}

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "draft", submitted: "warning", under_review: "in-review",
    approved: "approved", rejected: "rejected", archived: "default",
  };
  return map[status] ?? "default";
}
