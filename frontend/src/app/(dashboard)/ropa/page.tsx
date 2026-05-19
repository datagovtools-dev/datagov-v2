"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { formatDate, formatDateTime } from "@/lib/utils";

interface ROPAListItem {
  id: string;
  process_name: string;
  data_category: string;
  legal_basis: string;
  status: string;
  version: number;
  created_at: string;
}

interface PaginatedROPA {
  items: ROPAListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

const STATUS_OPTIONS = ["draft", "submitted", "under_review", "approved", "rejected", "archived"];

export default function ROPAListPage() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [legalBasisFilter, setLegalBasisFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data: legalBasisOptions } = useQuery<string[]>({
    queryKey: ["legal-basis-options"],
    queryFn: () => api.get<string[]>("/ropa/legal-basis-options"),
  });

  const { data, isLoading } = useQuery<PaginatedROPA>({
    queryKey: ["ropas", statusFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20" });
      if (statusFilter) params.set("status", statusFilter);
      return api.get<PaginatedROPA>(`/ropa?${params}`);
    },
  });

  const filtered = data?.items.filter((r) => {
    const matchSearch = !search ||
      r.process_name.toLowerCase().includes(search.toLowerCase()) ||
      r.data_category.toLowerCase().includes(search.toLowerCase());
    const matchBasis = !legalBasisFilter || r.legal_basis === legalBasisFilter;
    return matchSearch && matchBasis;
  });

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Records of Processing Activities</h1>
          <p className="text-sm text-gray-500 mt-1">GDPR Article 30 — maintain a register of all data processing activities</p>
        </div>
        <Link href="/ropa/new">
          <Button>+ New Record</Button>
        </Link>
      </div>

      <div className="flex gap-3 flex-wrap">
        <Input
          placeholder="Search process or category…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-56"
        />
        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
          className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All Statuses</option>
          {STATUS_OPTIONS.map((s) => <option key={s} value={s}>{s.replace("_", " ")}</option>)}
        </select>
        <select
          value={legalBasisFilter}
          onChange={(e) => setLegalBasisFilter(e.target.value)}
          className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">All Legal Bases</option>
          {legalBasisOptions?.map((b) => <option key={b} value={b}>{b}</option>)}
        </select>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Process Name</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data Category</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Legal Basis</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Version</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Created</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {isLoading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Loading…</td></tr>
            ) : !filtered?.length ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">No records found</td></tr>
            ) : filtered.map((r) => (
              <tr key={r.id} className="hover:bg-gray-50">
                <td className="px-4 py-3">
                  <Link href={`/ropa/${r.id}`} className="text-blue-600 hover:underline text-sm font-medium">
                    {r.process_name}
                  </Link>
                </td>
                <td className="px-4 py-3 text-sm text-gray-700">{r.data_category}</td>
                <td className="px-4 py-3">
                  <span className="inline-block bg-blue-50 text-blue-700 text-xs px-2 py-0.5 rounded-full border border-blue-200">
                    {r.legal_basis}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <Badge variant={statusVariant(r.status)}>{r.status.replace("_", " ")}</Badge>
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">v{r.version}</td>
                <td className="px-4 py-3 text-sm text-gray-500">{formatDate(r.created_at)}</td>
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
    approved: "approved", rejected: "rejected", archived: "default",
  };
  return map[status] ?? "default";
}
