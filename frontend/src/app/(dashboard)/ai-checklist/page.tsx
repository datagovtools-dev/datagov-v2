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

interface DSRListItem {
  id: string;
  tracking_id: string;
  project_code: string | null;
  project_name: string;
  recipient: string;
  status: string;
  checklist_status?: string | null;
  is_signed: boolean;
  signed_at: string | null;
  is_ai_use: boolean;
  duration_end: string;
  created_at: string;
}

interface PaginatedDSR {
  items: DSRListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

const CHECKLIST_STATUS_OPTIONS = [
  { value: "in_progress",      label: "In Progress / Draft" },
  { value: "submitted",        label: "Submitted (awaiting PIC Data Compliance)" },
  { value: "under_review",     label: "Under Review" },
  { value: "pending_signoff",  label: "Approved (Ready for Sign-Off)" },
  { value: "signed",           label: "Completed & Signed" },
  { value: "rejected",         label: "Rejected" },
];

// AICK status from the checklist's own approval flow (same meaning as the DSR status):
// Submitted until PIC Data Compliance approves step 1, then Under Review until the last step.
function checklistStatus(dsr: DSRListItem): { label: string; variant: "success" | "warning" | "neutral" | "info" | "danger" } {
  if (dsr.is_signed) return { label: "Completed & Signed", variant: "success" };
  switch (dsr.checklist_status) {
    case "rejected":     return { label: "Rejected", variant: "danger" };
    case "approved":     return { label: "Approved (Ready for Sign-Off)", variant: "info" };
    case "under_review": return { label: "Under Review", variant: "warning" };
    case "submitted":    return { label: "Submitted", variant: "info" };
    default:             return { label: "In Progress", variant: "neutral" };
  }
}

export default function AIChecklistPage() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [yearFilter, setYearFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data: filtersData } = useQuery<{ years: number[]; categories: string[] }>({
    queryKey: ["project-filters"],
    queryFn: () => api.get<{ years: number[]; categories: string[] }>("/projects/filters"),
  });
  const yearOptions: number[] = filtersData?.years ?? [];

  const { data, isLoading } = useQuery<PaginatedDSR>({
    queryKey: ["ai-checklist", search, statusFilter, yearFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20", is_ai_use: "true" });
      if (search) params.set("search", search);
      if (statusFilter) params.set("checklist_status", statusFilter);
      if (yearFilter) params.set("year", yearFilter);
      return api.get<PaginatedDSR>(`/dsr?${params}`);
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
            AI/ML Checklist (AICK)
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Data sharing initiatives evaluated for ethical AI and model compliance
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
            placeholder="Search DSR ID or project…"
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
          />
        </div>
        <Select value={statusFilter || "all"} onValueChange={handleStatus}>
          <SelectTrigger className="w-48 h-8 text-xs">
            <SelectValue placeholder="All Checklist Statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Checklist Statuses</SelectItem>
            {CHECKLIST_STATUS_OPTIONS.map((s) => (
              <SelectItem key={s.value} value={s.value}>{s.label}</SelectItem>
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
              <TableHead>Checklist ID</TableHead>
              <TableHead>DSR ID</TableHead>
              <TableHead>Project Code</TableHead>
              <TableHead>Project Name</TableHead>
              <TableHead>Client</TableHead>
              <TableHead>DSR Status</TableHead>
              <TableHead>Checklist Status</TableHead>
              <TableHead>Signed</TableHead>
              <TableHead>Sharing End</TableHead>
              <TableHead className="w-20 text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow><TableCell colSpan={10} className="text-center py-10 text-xs text-slate-400 font-mono">Loading…</TableCell></TableRow>
            ) : !data?.items.length ? (
              <TableRow>
                <TableCell colSpan={10} className="text-center py-10 text-xs text-slate-400 font-mono">
                  No AI/ML projects found.
                </TableCell>
              </TableRow>
            ) : data.items.map((dsr) => {
              const cl = checklistStatus(dsr);
              return (
                <TableRow key={dsr.id}>
                  <TableCell className="font-mono text-xs font-semibold text-slate-900">{dsr.tracking_id.replace("DSR", "AICK")}</TableCell>
                  <TableCell className="font-mono text-xs text-slate-700">{dsr.tracking_id}</TableCell>
                  <TableCell className="font-mono text-xs text-slate-500">{dsr.project_code ?? <span className="text-slate-300">—</span>}</TableCell>
                  <TableCell className="max-w-[160px] truncate font-medium text-slate-900" title={dsr.project_name}>{dsr.project_name}</TableCell>
                  <TableCell className="max-w-[140px] truncate text-slate-600" title={dsr.recipient}>{dsr.recipient}</TableCell>
                  <TableCell>
                    {dsr.is_signed
                      ? <Badge variant="success" className="text-[10px]">Signed &amp; Locked</Badge>
                      : <Badge variant="neutral" className="text-[10px]">{dsr.status.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())}</Badge>
                    }
                  </TableCell>
                  <TableCell>
                    <Badge variant={cl.variant} className="text-[10px]">{cl.label}</Badge>
                  </TableCell>
                  <TableCell className="text-xs text-slate-500 font-mono">{dsr.signed_at ? formatDate(dsr.signed_at) : <span className="text-slate-300">—</span>}</TableCell>
                  <TableCell className="text-xs text-slate-500 font-mono">{formatDate(dsr.duration_end)}</TableCell>
                  <TableCell className="text-right">
                    <Link href={`/ai-checklist/${dsr.id}`}>
                      <Button size="sm" variant="outline" className="h-6.5 px-2 text-[11px]">View</Button>
                    </Link>
                  </TableCell>
                </TableRow>
              );
            })}
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
