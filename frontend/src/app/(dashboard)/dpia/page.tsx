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
    <div>
      <div className="page-header">
        <div>
          <h1>Data Protection Impact Assessment</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Identify and mitigate privacy risks in data processing activities
            {data ? ` · ${data.total} record${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-5">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base pl-9" placeholder="Search by DPIA ID, DSR ID or project…"
            value={search} onChange={(e) => handleSearch(e.target.value)} />
        </div>
        <Select value={statusFilter || "all"} onValueChange={handleStatus}>
          <SelectTrigger className="w-48"><SelectValue placeholder="All DPIA Statuses" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All DPIA Statuses</SelectItem>
            {DPIA_STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>{label(s)}</SelectItem>
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
            <TableHead>DPIA ID</TableHead>
            <TableHead>DSR ID</TableHead>
            <TableHead>Project ID</TableHead>
            <TableHead>Project Name</TableHead>
            <TableHead>Client</TableHead>
            <TableHead>DSR Status</TableHead>
            <TableHead>DPIA Status</TableHead>
            <TableHead>Sharing End</TableHead>
            <TableHead className="w-24">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={9} className="text-center py-10 text-surface-400">Loading…</TableCell></TableRow>
          ) : !data?.items.length ? (
            <TableRow>
              <TableCell colSpan={9} className="text-center py-12 text-surface-400">
                <p className="font-medium">No assessments found</p>
                <p className="text-sm mt-1">DPIA records will appear here once created.</p>
              </TableCell>
            </TableRow>
          ) : data.items.map((d) => (
            <TableRow key={d.id}>
              <TableCell>
                <Link href={`/dpia/${d.id}`} className="font-mono text-sm font-medium text-primary-700 hover:underline">
                  {d.tracking_id ?? d.id.slice(0, 8)}
                </Link>
              </TableCell>
              <TableCell className="font-mono text-sm text-surface-700">
                {d.dsr_tracking_id ?? <span className="text-surface-300">—</span>}
              </TableCell>
              <TableCell className="font-mono text-xs text-surface-500">
                {d.project_code ?? <span className="text-surface-300">—</span>}
              </TableCell>
              <TableCell className="max-w-[160px] truncate" title={d.project_name ?? ""}>{d.project_name ?? "—"}</TableCell>
              <TableCell className="max-w-[140px] truncate text-surface-600" title={d.customer_name ?? ""}>{d.customer_name ?? "—"}</TableCell>
              <TableCell>
                {d.dsr_status
                  ? <Badge variant={dsrVariant(d.dsr_status)}>{label(d.dsr_status)}</Badge>
                  : <span className="text-surface-300">—</span>
                }
              </TableCell>
              <TableCell>
                <Badge variant={dpiaVariant(d.status)}>{label(d.status)}</Badge>
              </TableCell>
              <TableCell className="text-surface-500">
                {d.dsr_sharing_end ? formatDate(d.dsr_sharing_end) : <span className="text-surface-300">—</span>}
              </TableCell>
              <TableCell>
                <Link href={`/dpia/${d.id}`}>
                  <Button size="sm" variant="outline">View</Button>
                </Link>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {data && data.pages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-surface-500">Page {data.page} of {data.pages} · {data.total} total</p>
          <div className="flex gap-1">
            <Button size="icon" variant="outline" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button size="icon" variant="outline" disabled={page >= data.pages} onClick={() => setPage(p => p + 1)}>
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
