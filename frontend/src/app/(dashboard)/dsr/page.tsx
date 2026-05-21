"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Plus, Search, ChevronLeft, ChevronRight } from "lucide-react";
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
  is_signed: boolean;
  signed_at: string | null;
  is_ai_use: boolean;
  duration_end: string;
  project_end_date: string | null;
  created_at: string;
}

interface PaginatedDSR {
  items: DSRListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

const STATUS_OPTIONS = ["draft", "submitted", "under_review", "approved", "rejected", "executed", "archived"];

function statusVariant(status: string): "draft" | "pending" | "in-review" | "approved" | "rejected" | "done" | "default" {
  const map: Record<string, "draft" | "pending" | "in-review" | "approved" | "rejected" | "done" | "default"> = {
    draft: "draft", submitted: "pending", under_review: "in-review",
    approved: "approved", rejected: "rejected", executed: "done", archived: "default",
  };
  return map[status] ?? "default";
}

export default function DSRListPage() {
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
    queryKey: ["dsrs", search, statusFilter, yearFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20" });
      if (search) params.set("search", search);
      if (statusFilter) params.set("status", statusFilter);
      if (yearFilter) params.set("year", yearFilter);
      return api.get<PaginatedDSR>(`/dsr?${params}`);
    },
  });

  function handleSearch(v: string) { setSearch(v); setPage(1); }
  function handleStatus(v: string) { setStatusFilter(v === "all" ? "" : v); setPage(1); }
  function handleYear(v: string) { setYearFilter(v === "all" ? "" : v); setPage(1); }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Data Sharing Requests</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Manage data sharing requests and approval workflows
            {data ? ` · ${data.total} request${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
        <Link href="/dsr/new" className="shrink-0">
          <Button className="whitespace-nowrap"><Plus className="h-4 w-4 mr-1" /> New Request</Button>
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-5">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base pl-9" placeholder="Search by tracking ID or dataset…"
            value={search} onChange={(e) => handleSearch(e.target.value)} />
        </div>
        <Select value={statusFilter || "all"} onValueChange={handleStatus}>
          <SelectTrigger className="w-48"><SelectValue placeholder="All DSR Statuses" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All DSR Statuses</SelectItem>
            {STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>{s.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={yearFilter || "all"} onValueChange={handleYear}>
          <SelectTrigger className="w-36"><SelectValue placeholder="All Years" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Years</SelectItem>
            {yearOptions.map((y) => (
              <SelectItem key={y} value={String(y)}>{y}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>DSR ID</TableHead>
            <TableHead>Project ID</TableHead>
            <TableHead>Project Name</TableHead>
            <TableHead>Client</TableHead>
            <TableHead>AI Use</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Created</TableHead>
            <TableHead>Signed</TableHead>
            <TableHead>Sharing End</TableHead>
            <TableHead className="w-24">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={10} className="text-center py-10 text-surface-400">Loading…</TableCell></TableRow>
          ) : !data?.items.length ? (
            <TableRow><TableCell colSpan={10} className="text-center py-10 text-surface-400">No requests found</TableCell></TableRow>
          ) : data.items.map((dsr) => {
            const signedDate = dsr.signed_at;
            return (
            <TableRow key={dsr.id}>
              <TableCell className="font-mono text-sm font-medium text-primary-700">{dsr.tracking_id}</TableCell>
              <TableCell className="font-mono text-xs text-surface-500">{dsr.project_code ?? <span className="text-surface-300">—</span>}</TableCell>
              <TableCell className="max-w-[180px] truncate">{dsr.project_name}</TableCell>
              <TableCell className="max-w-[160px] truncate text-surface-600">{dsr.recipient}</TableCell>
              <TableCell>{dsr.is_ai_use ? <Badge variant="warning">AI</Badge> : <span className="text-surface-400">—</span>}</TableCell>
              <TableCell>
                <Badge variant={statusVariant(dsr.status)}>
                  {dsr.status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
                </Badge>
              </TableCell>
              <TableCell>{formatDate(dsr.created_at)}</TableCell>
              <TableCell>{signedDate ? formatDate(signedDate) : ""}</TableCell>
              <TableCell>{dsr.project_end_date ? formatDate(dsr.project_end_date) : "—"}</TableCell>
              <TableCell>
                <Link href={`/dsr/${dsr.id}`}>
                  <Button size="sm" variant="outline">View</Button>
                </Link>
              </TableCell>
            </TableRow>
            );
          })}
        </TableBody>
      </Table>

      {data && data.pages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-surface-500">Page {data.page} of {data.pages} · {data.total} total</p>
          <div className="flex gap-1">
            <Button size="icon" variant="outline" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button size="icon" variant="outline" disabled={page >= data.pages} onClick={() => setPage((p) => p + 1)}>
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
