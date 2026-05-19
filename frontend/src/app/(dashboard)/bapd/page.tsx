"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { formatDate } from "@/lib/utils";

interface BAPDListItem {
  id: string;
  dataset_name: string;
  dataset_location: string;
  expiry_date: string;
  status: string;
  version: number;
  pod_file_path: string | null;
  executed_at: string | null;
  created_at: string;
}

interface PaginatedBAPD {
  items: BAPDListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

interface EligibleDataset {
  id: string;
  dataset_name: string;
  dataset_location: string;
  expiry_date: string;
  days_overdue: number;
  status: string;
  retention_policy_id?: string | null;
}

const STATUS_OPTIONS = ["draft", "submitted", "under_review", "approved", "executed", "archived", "rejected"];

export default function BAPDListPage() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data: eligible } = useQuery<EligibleDataset[]>({
    queryKey: ["bapd-eligible"],
    queryFn: () => api.get<EligibleDataset[]>("/bapd/eligible-datasets"),
  });

  const { data, isLoading } = useQuery<PaginatedBAPD>({
    queryKey: ["bapds", statusFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20" });
      if (statusFilter) params.set("status", statusFilter);
      return api.get<PaginatedBAPD>(`/bapd?${params}`);
    },
  });

  const filtered = data?.items.filter((r) =>
    !search || r.dataset_name.toLowerCase().includes(search.toLowerCase()) || r.dataset_location.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Bulk Archive / Purge of Data (BAPD)</h1>
          <p className="text-sm text-gray-500 mt-1">Manage data extermination requests with dual-approval workflow</p>
        </div>
        <Link href="/bapd/new">
          <Button>+ New BAPD Request</Button>
        </Link>
      </div>

      {/* Eligible datasets warning panel */}
      {eligible && eligible.length > 0 && (
        <div className="bg-amber-50 border border-amber-300 rounded-lg p-4 space-y-3">
          <div className="flex items-center gap-2">
            <span className="text-amber-600 font-bold text-lg">⚠</span>
            <h2 className="font-semibold text-amber-800">
              {eligible.length} Dataset{eligible.length > 1 ? "s" : ""} Eligible for Extermination
            </h2>
          </div>
          <p className="text-sm text-amber-700">The following datasets have exceeded their retention period and should be scheduled for deletion.</p>
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-amber-700 text-xs uppercase">
                  <th className="text-left py-1 pr-4">Dataset</th>
                  <th className="text-left py-1 pr-4">Location</th>
                  <th className="text-left py-1 pr-4">Expired</th>
                  <th className="text-left py-1 pr-4">Days Overdue</th>
                  <th className="text-left py-1" />
                </tr>
              </thead>
              <tbody className="divide-y divide-amber-100">
                {eligible.slice(0, 5).map((d) => (
                  <tr key={d.id} className="text-amber-900">
                    <td className="py-1.5 pr-4 font-medium">{d.dataset_name}</td>
                    <td className="py-1.5 pr-4 font-mono text-xs">{d.dataset_location}</td>
                    <td className="py-1.5 pr-4">{formatDate(d.expiry_date)}</td>
                    <td className="py-1.5 pr-4">
                      <span className="font-bold text-red-600">{d.days_overdue}d</span>
                    </td>
                    <td className="py-1.5">
                      <Link href={`/bapd/new?dataset=${encodeURIComponent(d.dataset_name)}&location=${encodeURIComponent(d.dataset_location)}&policy=${d.retention_policy_id ?? ""}&id=${d.id}`}>
                        <button className="text-xs text-blue-600 hover:underline">Create BAPD →</button>
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <Input
          placeholder="Search dataset or location…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-64"
        />
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
          className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All Statuses</option>
          {STATUS_OPTIONS.map((s) => <option key={s} value={s}>{s.replace("_", " ")}</option>)}
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dataset</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Location</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expiry Date</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">POD</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Executed</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">v</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {isLoading ? (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">Loading…</td></tr>
            ) : !filtered?.length ? (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">No BAPD records found</td></tr>
            ) : filtered.map((r) => (
              <tr key={r.id} className="hover:bg-gray-50">
                <td className="px-4 py-3">
                  <Link href={`/bapd/${r.id}`} className="text-blue-600 hover:underline text-sm font-medium">
                    {r.dataset_name}
                  </Link>
                </td>
                <td className="px-4 py-3 font-mono text-xs text-gray-600 max-w-[180px] truncate">{r.dataset_location}</td>
                <td className="px-4 py-3 text-sm text-gray-700">{formatDate(r.expiry_date)}</td>
                <td className="px-4 py-3"><Badge variant={statusVariant(r.status)}>{r.status.replace("_", " ")}</Badge></td>
                <td className="px-4 py-3">
                  {r.pod_file_path ? (
                    <a href={`/api/v1/bapd/${r.id}/pod`} target="_blank" rel="noreferrer"
                      className="text-xs text-blue-600 hover:underline">Download</a>
                  ) : "—"}
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">{r.executed_at ? formatDate(r.executed_at) : "—"}</td>
                <td className="px-4 py-3 text-sm text-gray-400">v{r.version}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {data && data.pages > 1 && (
        <div className="flex items-center justify-between text-sm text-gray-600">
          <span>{data.total} total records</span>
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

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "draft", submitted: "warning", under_review: "in-review",
    approved: "approved", rejected: "rejected", executed: "done", archived: "default",
  };
  return map[status] ?? "default";
}
