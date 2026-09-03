"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Plus, Search, ChevronLeft, ChevronRight, AlertTriangle } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { formatDate } from "@/lib/utils";

interface BAPDListItem {
  id: string;
  project_id?: string | null;
  project_code?: string | null;
  project_name?: string | null;
  customer_name?: string | null;
  dataset_name: string;
  dataset_location: string;
  expiry_date: string;
  status: string;
  version: number;
  responsible_party_name?: string | null;
  created_by_name?: string | null;
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

type BadgeVariant = "default" | "success" | "warning" | "danger" | "neutral" | "info";

function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "neutral", submitted: "warning", under_review: "info",
    approved: "success", rejected: "danger", executed: "success", archived: "default",
  };
  return map[status] ?? "default";
}

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
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Extermination Records (BAPD)
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Bulk archive & purge of data with dual mandatory sign-offs and Proof of Deletion (POD)
            {data ? ` · ${data.total} record${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
        <Link href="/bapd/new">
          <Button size="sm" className="font-medium">
            <Plus className="h-3.5 w-3.5 mr-1" /> New BAPD Request
          </Button>
        </Link>
      </div>

      {/* Eligible datasets warning banner */}
      {eligible && eligible.length > 0 && (
        <div className="bg-amber-50/70 border border-amber-200 rounded-md p-3 space-y-2">
          <div className="flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 text-amber-700 shrink-0" />
            <h2 className="text-xs font-semibold text-amber-900 font-mono">
              {eligible.length} Dataset{eligible.length > 1 ? "s" : ""} Overdue for Extermination
            </h2>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full text-xs">
              <thead>
                <tr className="text-slate-500 text-[10px] uppercase font-mono border-b border-amber-200/60">
                  <th className="text-left py-1 pr-3">Dataset</th>
                  <th className="text-left py-1 pr-3">Location</th>
                  <th className="text-left py-1 pr-3">Expired</th>
                  <th className="text-left py-1 pr-3">Overdue</th>
                  <th className="text-right py-1">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-amber-100">
                {eligible.slice(0, 5).map((d) => (
                  <tr key={d.id} className="text-slate-800">
                    <td className="py-1 pr-3 font-medium">{d.dataset_name}</td>
                    <td className="py-1 pr-3 font-mono text-[11px] text-slate-500">{d.dataset_location}</td>
                    <td className="py-1 pr-3 font-mono text-[11px]">{formatDate(d.expiry_date)}</td>
                    <td className="py-1 pr-3 font-mono text-[11px] font-semibold text-rose-700">{d.days_overdue}d</td>
                    <td className="py-1 text-right">
                      <Link href={`/bapd/new?dataset=${encodeURIComponent(d.dataset_name)}&location=${encodeURIComponent(d.dataset_location)}&policy=${d.retention_policy_id ?? ""}&id=${d.id}`}>
                        <Button size="sm" variant="outline" className="h-5.5 px-1.5 text-[10px]">
                          Create BAPD →
                        </Button>
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Filter Toolbar */}
      <div className="flex flex-wrap items-center gap-2.5 p-2.5 rounded-md border border-slate-200 bg-white">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 pointer-events-none" />
          <input
            className="input-base pl-8 h-8 text-xs"
            placeholder="Search dataset or location…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <Select value={statusFilter || "all"} onValueChange={(v) => { setStatusFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-44 h-8 text-xs">
            <SelectValue placeholder="All Statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            {STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>{s.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <div className="rounded-md border border-slate-200 bg-white overflow-hidden shadow-2xs">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Dataset Name</TableHead>
              <TableHead>Project</TableHead>
              <TableHead>Location</TableHead>
              <TableHead>Expiry Date</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>POD Proof</TableHead>
              <TableHead>Executed</TableHead>
              <TableHead>Version</TableHead>
              <TableHead className="w-20 text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow><TableCell colSpan={9} className="text-center py-10 text-xs text-slate-400 font-mono">Loading…</TableCell></TableRow>
            ) : !filtered?.length ? (
              <TableRow><TableCell colSpan={9} className="text-center py-10 text-xs text-slate-400 font-mono">No BAPD records found.</TableCell></TableRow>
            ) : (
              filtered.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-medium text-slate-900">
                    <Link href={`/bapd/${r.id}`} className="hover:underline font-semibold">
                      {r.dataset_name}
                    </Link>
                  </TableCell>
                  <TableCell className="text-xs text-slate-700">
                    {r.project_code ? (
                      <span className="font-mono text-[11px] bg-slate-100 px-1.5 py-0.5 rounded border border-slate-200">
                        {r.project_code}
                      </span>
                    ) : r.project_name ? (
                      <span className="truncate max-w-[120px] block">{r.project_name}</span>
                    ) : (
                      <span className="text-slate-300 font-mono">—</span>
                    )}
                  </TableCell>
                  <TableCell className="font-mono text-xs text-slate-500 max-w-[160px] truncate">{r.dataset_location}</TableCell>
                  <TableCell className="text-xs text-slate-600 font-mono">{formatDate(r.expiry_date)}</TableCell>
                  <TableCell>
                    <Badge variant={statusVariant(r.status)} className="text-[10px] uppercase font-mono">
                      {r.status.replace("_", " ")}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    {r.pod_file_path ? (
                      <a href={`/api/v1/bapd/${r.id}/pod`} target="_blank" rel="noreferrer"
                        className="text-xs font-mono text-blue-600 hover:underline">Download</a>
                    ) : <span className="text-slate-300 font-mono">—</span>}
                  </TableCell>
                  <TableCell className="text-xs text-slate-500 font-mono">{r.executed_at ? formatDate(r.executed_at) : "—"}</TableCell>
                  <TableCell className="text-xs text-slate-400 font-mono">v{r.version}</TableCell>
                  <TableCell className="text-right">
                    <Link href={`/bapd/${r.id}`}>
                      <Button size="sm" variant="outline" className="h-6.5 px-2 text-[11px]">View</Button>
                    </Link>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>

        {/* Pagination */}
        {data && data.pages > 1 && (
          <div className="flex items-center justify-between px-3 py-2 border-t border-slate-100 bg-slate-50/50">
            <p className="text-xs text-slate-500 font-mono">
              Page <span className="font-semibold text-slate-900">{data.page}</span> of <span className="font-semibold text-slate-900">{data.pages}</span> · {data.total} total
            </p>
            <div className="flex gap-1">
              <Button size="icon" variant="outline" className="h-7 w-7" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
                <ChevronLeft className="h-3.5 w-3.5" />
              </Button>
              <Button size="icon" variant="outline" className="h-7 w-7" disabled={page >= data.pages} onClick={() => setPage((p) => p + 1)}>
                <ChevronRight className="h-3.5 w-3.5" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
