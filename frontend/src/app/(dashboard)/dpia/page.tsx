"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { formatDate } from "@/lib/utils";

interface DPIAListItem {
  id: string;
  tracking_id: string | null;
  project_code: string | null;
  project_name: string | null;
  customer_name: string | null;
  status: string;
  dsr_tracking_id: string | null;
  dsr_status: string | null;
  dsr_sharing_end: string | null;
}

interface PaginatedDPIA {
  items: DPIAListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

const DPIA_STATUS_OPTIONS = ["draft", "submitted", "under_review", "approved", "rejected", "archived"];

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";

function dpiaVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "draft", submitted: "warning", under_review: "in-review",
    approved: "approved", rejected: "rejected", archived: "default",
  };
  return map[status] ?? "default";
}

function dsrVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "draft", submitted: "warning", under_review: "in-review",
    approved: "approved", rejected: "rejected", expired: "danger",
  };
  return map[status] ?? "default";
}

function label(status: string) {
  return status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

export default function DPIAListPage() {
  const [search, setSearch] = useState("");
  const [dpiaStatusFilter, setDpiaStatusFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<PaginatedDPIA>({
    queryKey: ["dpias", dpiaStatusFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20" });
      if (dpiaStatusFilter) params.set("status", dpiaStatusFilter);
      return api.get<PaginatedDPIA>(`/dpia?${params}`);
    },
  });

  const filtered = search
    ? data?.items.filter((d) =>
        (d.tracking_id ?? "").toLowerCase().includes(search.toLowerCase()) ||
        (d.dsr_tracking_id ?? "").toLowerCase().includes(search.toLowerCase()) ||
        (d.project_code ?? "").toLowerCase().includes(search.toLowerCase()) ||
        (d.project_name ?? "").toLowerCase().includes(search.toLowerCase()) ||
        (d.customer_name ?? "").toLowerCase().includes(search.toLowerCase())
      )
    : data?.items;

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-surface-900">Data Protection Impact Assessment</h1>
        <p className="text-sm text-surface-500 mt-1">Identify and mitigate privacy risks in data processing activities</p>
      </div>

      <div className="flex gap-3 flex-wrap">
        <Input
          placeholder="Search DPIA ID, DSR ID, project…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-72"
        />
        <select
          value={dpiaStatusFilter}
          onChange={(e) => { setDpiaStatusFilter(e.target.value); setPage(1); }}
          className="border border-surface-200 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        >
          <option value="">All DPIA Statuses</option>
          {DPIA_STATUS_OPTIONS.map((s) => (
            <option key={s} value={s}>{label(s)}</option>
          ))}
        </select>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-surface-200 overflow-auto">
        <table className="min-w-full divide-y divide-surface-100">
          <thead className="bg-surface-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">DPIA ID</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">DSR ID</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">Project ID</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">Project Name</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">Client</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">DSR Status</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">DPIA Status</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">Sharing End</th>
              <th className="px-4 py-3 text-left text-xs font-semibold text-surface-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-100">
            {isLoading ? (
              <tr><td colSpan={9} className="px-4 py-8 text-center text-surface-400">Loading…</td></tr>
            ) : !filtered?.length ? (
              <tr><td colSpan={9} className="px-4 py-8 text-center text-surface-400">No assessments found</td></tr>
            ) : filtered.map((d) => (
              <tr key={d.id} className="hover:bg-surface-50">
                <td className="px-4 py-3">
                  <Link href={`/dpia/${d.id}`} className="font-mono text-sm font-medium text-primary-600 hover:underline">
                    {d.tracking_id ?? d.id.slice(0, 8)}
                  </Link>
                </td>
                <td className="px-4 py-3">
                  {d.dsr_tracking_id ? (
                    <span className="font-mono text-sm text-surface-700">{d.dsr_tracking_id}</span>
                  ) : (
                    <span className="text-surface-400 text-sm">—</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <span className="font-mono text-xs text-surface-500">{d.project_code ?? "—"}</span>
                </td>
                <td className="px-4 py-3 text-sm font-medium text-surface-800">{d.project_name ?? "—"}</td>
                <td className="px-4 py-3 text-sm text-surface-600">{d.customer_name ?? "—"}</td>
                <td className="px-4 py-3">
                  {d.dsr_status ? (
                    <Badge variant={dsrVariant(d.dsr_status)}>{label(d.dsr_status)}</Badge>
                  ) : (
                    <span className="text-surface-400 text-sm">—</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <Badge variant={dpiaVariant(d.status)}>{label(d.status)}</Badge>
                </td>
                <td className="px-4 py-3 text-sm text-surface-500">
                  {d.dsr_sharing_end ? formatDate(d.dsr_sharing_end) : "—"}
                </td>
                <td className="px-4 py-3">
                  <Link href={`/dpia/${d.id}`}>
                    <Button variant="outline" size="sm">View</Button>
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {data && data.pages > 1 && (
        <div className="flex items-center justify-between text-sm text-surface-600">
          <span>{data.total} total assessments</span>
          <div className="flex gap-2">
            <Button variant="outline" size="sm" disabled={page === 1} onClick={() => setPage(page - 1)}>Previous</Button>
            <span className="px-3 py-1">Page {page} of {data.pages}</span>
            <Button variant="outline" size="sm" disabled={page === data.pages} onClick={() => setPage(page + 1)}>Next</Button>
          </div>
        </div>
      )}
    </div>
  );
}
