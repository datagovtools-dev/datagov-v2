"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Search, ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
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

type BadgeVariant = "default" | "success" | "warning" | "danger" | "neutral" | "info";

function dpiaVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "neutral", submitted: "warning", under_review: "info",
    approved: "success", rejected: "danger", archived: "default",
  };
  return map[status] ?? "default";
}

function dsrVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    draft: "neutral", submitted: "warning", under_review: "info",
    approved: "success", rejected: "danger", expired: "danger",
  };
  return map[status] ?? "default";
}

function label(status: string) {
  return status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

export default function DPIAListPage() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [yearFilter, setYearFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data: filtersData } = useQuery<{ years: number[]; categories: string[] }>({
    queryKey: ["project-filters"],
    queryFn: () => api.get<{ years: number[]; categories: string[] }>("/projects/filters"),
  });
  const yearOptions: number[] = filtersData?.years ?? [];

  const { data, isLoading } = useQuery<PaginatedDPIA>({
    queryKey: ["dpias", search, statusFilter, yearFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20" });
      if (search) params.set("search", search);
      if (statusFilter) params.set("status", statusFilter);
      if (yearFilter) params.set("year", yearFilter);
      return api.get<PaginatedDPIA>(`/dpia?${params}`);
    },
  });

  function handleSearch(v: string) { setSearch(v); setPage(1); }
  function handleStatus(v: string) { setStatusFilter(v === "all" ? "" : v); setPage(1); }
  function handleYear(v: string) { setYearFilter(v === "all" ? "" : v); setPage(1); }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Privacy Impact Assessments (DPIA)
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Evaluate privacy risk matrices, data categories, and dual-step compliance approvals
            {data ? ` · ${data.total} record${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-2.5 p-2.5 rounded-md border border-slate-200 bg-white">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 pointer-events-none" />
          <input
            className="input-base pl-8 h-8 text-xs"
            placeholder="Search DPIA ID, DSR ID or project…"
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
          />
        </div>
        <Select value={statusFilter || "all"} onValueChange={handleStatus}>
          <SelectTrigger className="w-48 h-8 text-xs">
            <SelectValue placeholder="All DPIA Statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All DPIA Statuses</SelectItem>
            {DPIA_STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>{label(s)}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={yearFilter || "all"} onValueChange={handleYear}>
          <SelectTrigger className="w-32 h-8 text-xs">
            <SelectValue placeholder="All Years" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Years</SelectItem>
            {yearOptions.map((y) => (
              <SelectItem key={y} value={String(y)}>{y}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <div className="rounded-md border border-slate-200 bg-white overflow-hidden shadow-2xs">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>DPIA ID</TableHead>
              <TableHead>DSR ID</TableHead>
              <TableHead>Project Code</TableHead>
              <TableHead>Project Name</TableHead>
              <TableHead>Client</TableHead>
              <TableHead>DSR Status</TableHead>
              <TableHead>DPIA Status</TableHead>
              <TableHead>Sharing End</TableHead>
              <TableHead className="w-20 text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow><TableCell colSpan={9} className="text-center py-10 text-xs text-slate-400 font-mono">Loading…</TableCell></TableRow>
            ) : !data?.items.length ? (
              <TableRow>
                <TableCell colSpan={9} className="text-center py-10 text-xs text-slate-400 font-mono">
                  No assessments found.
                </TableCell>
              </TableRow>
            ) : data.items.map((d) => (
              <TableRow key={d.id}>
                <TableCell className="font-mono text-xs font-semibold text-slate-900">
                  <Link href={`/dpia/${d.id}`} className="hover:underline">
                    {d.tracking_id ?? d.id.slice(0, 8)}
                  </Link>
                </TableCell>
                <TableCell className="font-mono text-xs text-slate-700">
                  {d.dsr_tracking_id ?? <span className="text-slate-300">—</span>}
                </TableCell>
                <TableCell className="font-mono text-xs text-slate-500">
                  {d.project_code ?? <span className="text-slate-300">—</span>}
                </TableCell>
                <TableCell className="max-w-[160px] truncate font-medium text-slate-900" title={d.project_name ?? ""}>{d.project_name ?? "—"}</TableCell>
                <TableCell className="max-w-[140px] truncate text-slate-600" title={d.customer_name ?? ""}>{d.customer_name ?? "—"}</TableCell>
                <TableCell>
                  {d.dsr_status
                    ? <Badge variant={dsrVariant(d.dsr_status)} className="text-[10px]">{label(d.dsr_status)}</Badge>
                    : <span className="text-slate-300">—</span>
                  }
                </TableCell>
                <TableCell>
                  <Badge variant={dpiaVariant(d.status)} className="text-[10px]">{label(d.status)}</Badge>
                </TableCell>
                <TableCell className="text-xs text-slate-500 font-mono">
                  {d.dsr_sharing_end ? formatDate(d.dsr_sharing_end) : <span className="text-slate-300">—</span>}
                </TableCell>
                <TableCell className="text-right">
                  <Link href={`/dpia/${d.id}`}>
                    <Button size="sm" variant="outline" className="h-6.5 px-2 text-[11px]">View</Button>
                  </Link>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {/* Pagination */}
        {data && data.pages > 1 && (
          <div className="flex items-center justify-between px-3 py-2 border-t border-slate-100 bg-slate-50/50">
            <p className="text-xs text-slate-500 font-mono">Page <span className="font-semibold text-slate-900">{data.page}</span> of <span className="font-semibold text-slate-900">{data.pages}</span> · {data.total} total</p>
            <div className="flex gap-1">
              <Button size="icon" variant="outline" className="h-7 w-7" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                <ChevronLeft className="h-3.5 w-3.5" />
              </Button>
              <Button size="icon" variant="outline" className="h-7 w-7" disabled={page >= data.pages} onClick={() => setPage(p => p + 1)}>
                <ChevronRight className="h-3.5 w-3.5" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
