"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Plus, Search, ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { formatDate } from "@/lib/utils";

interface ROPAListItem {
  id: string;
  project_id?: string | null;
  project_code?: string | null;
  project_name?: string | null;
  customer_name?: string | null;
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

type BadgeVariant = "default" | "success" | "warning" | "danger" | "neutral" | "info";

function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "neutral", submitted: "warning", under_review: "info",
    approved: "success", rejected: "danger", archived: "default",
  };
  return map[status] ?? "default";
}

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
    const q = search.toLowerCase();
    const matchSearch = !search ||
      r.process_name.toLowerCase().includes(q) ||
      r.data_category.toLowerCase().includes(q) ||
      (r.project_name && r.project_name.toLowerCase().includes(q)) ||
      (r.project_code && r.project_code.toLowerCase().includes(q)) ||
      (r.customer_name && r.customer_name.toLowerCase().includes(q));
    const matchBasis = !legalBasisFilter || r.legal_basis === legalBasisFilter;
    return matchSearch && matchBasis;
  });

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Records of Processing Activities (ROPA)
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Maintain register of data processing activities, categories, and lawful bases under UU PDP &amp; GDPR Art. 30
            {data ? ` · ${data.total} record${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
        <Link href="/ropa/new">
          <Button size="sm" className="font-medium">
            <Plus className="h-3.5 w-3.5 mr-1" /> New Record
          </Button>
        </Link>
      </div>

      {/* Filter Toolbar */}
      <div className="flex flex-wrap items-center gap-2.5 p-2.5 rounded-md border border-slate-200 bg-white">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 pointer-events-none" />
          <input
            className="input-base pl-8 h-8 text-xs"
            placeholder="Search process, project, category…"
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
        <Select value={legalBasisFilter || "all"} onValueChange={(v) => { setLegalBasisFilter(v === "all" ? "" : v); setPage(1); }}>
          <SelectTrigger className="w-48 h-8 text-xs">
            <SelectValue placeholder="All Legal Bases" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Legal Bases</SelectItem>
            {legalBasisOptions?.map((b) => (
              <SelectItem key={b} value={b}>{b}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <div className="rounded-md border border-slate-200 bg-white overflow-hidden shadow-2xs">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Project</TableHead>
              <TableHead>Process Name</TableHead>
              <TableHead>Data Category</TableHead>
              <TableHead>Legal Basis</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Version</TableHead>
              <TableHead>Created</TableHead>
              <TableHead className="w-20 text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow><TableCell colSpan={8} className="text-center py-10 text-xs text-slate-400 font-mono">Loading…</TableCell></TableRow>
            ) : !filtered?.length ? (
              <TableRow><TableCell colSpan={8} className="text-center py-10 text-xs text-slate-400 font-mono">No records found.</TableCell></TableRow>
            ) : (
              filtered.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-mono text-xs text-slate-700">
                    <span className="font-semibold text-slate-900">{r.project_code ?? "—"}</span>
                    {r.project_name && (
                      <span className="block text-[11px] text-slate-500 font-sans truncate max-w-[150px]" title={r.project_name}>
                        {r.project_name}
                      </span>
                    )}
                  </TableCell>
                  <TableCell className="font-medium text-slate-900">
                    <Link href={`/ropa/${r.id}`} className="hover:underline">
                      {r.process_name}
                    </Link>
                  </TableCell>
                  <TableCell className="text-slate-600 text-xs">{r.data_category}</TableCell>
                  <TableCell>
                    <span className="inline-block bg-slate-100 text-slate-700 text-[10px] font-mono px-2 py-0.5 rounded-md border border-slate-200">
                      {r.legal_basis}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Badge variant={statusVariant(r.status)} className="text-[10px]">
                      {r.status.replace("_", " ")}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-slate-500 font-mono">v{r.version}</TableCell>
                  <TableCell className="text-xs text-slate-500 font-mono">{formatDate(r.created_at)}</TableCell>
                  <TableCell className="text-right">
                    <Link href={`/ropa/${r.id}`}>
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
