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

interface DQRunListItem {
  id: string;
  run_name: string;
  dataset_name: string;
  status: string;
  total_checks: number;
  passed_checks: number;
  failed_checks: number;
  overall_score: string | null;
  created_at: string;
  completed_at: string | null;
}

interface PaginatedDQRun {
  items: DQRunListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

const STATUS_OPTIONS = ["pending", "running", "completed", "under_review", "approved", "rejected", "failed"];

type BadgeVariant = "default" | "success" | "warning" | "danger" | "approved" | "rejected" | "draft" | "done" | "in-review";
function statusVariant(status: string): BadgeVariant {
  const map: Record<string, BadgeVariant> = {
    pending: "default", running: "warning", completed: "in-review",
    under_review: "in-review", approved: "approved", rejected: "rejected", failed: "danger",
  };
  return map[status] ?? "default";
}

function ScorePill({ score }: { score: string | null }) {
  if (!score) return <span className="text-surface-400">—</span>;
  const n = parseFloat(score);
  const color = n >= 90 ? "bg-green-100 text-green-700" : n >= 70 ? "bg-yellow-100 text-yellow-700" : "bg-red-100 text-red-700";
  return <span className={`inline-flex items-center px-2 py-0.5 rounded text-sm font-semibold ${color}`}>{n.toFixed(1)}%</span>;
}

export default function DQListPage() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<PaginatedDQRun>({
    queryKey: ["dq-runs", statusFilter, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20" });
      if (statusFilter) params.set("status", statusFilter);
      return api.get<PaginatedDQRun>(`/dq?${params}`);
    },
  });

  const filtered = data?.items.filter((r) =>
    !search ||
    r.run_name.toLowerCase().includes(search.toLowerCase()) ||
    r.dataset_name.toLowerCase().includes(search.toLowerCase())
  );

  function handleStatus(v: string) { setStatusFilter(v === "all" ? "" : v); setPage(1); }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Data Quality Runs</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Run automated completeness, uniqueness, and consistency checks against your datasets
            {data ? ` · ${data.total} run${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
        <Link href="/dq/new" className="shrink-0">
          <Button className="whitespace-nowrap"><Plus className="h-4 w-4 mr-1" /> New DQ Run</Button>
        </Link>
      </div>

      <div className="flex flex-wrap gap-3 mb-5">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base pl-9" placeholder="Search run name or dataset…"
            value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <Select value={statusFilter || "all"} onValueChange={handleStatus}>
          <SelectTrigger className="w-44"><SelectValue placeholder="All Statuses" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            {STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>{s.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Run Name</TableHead>
            <TableHead>Dataset</TableHead>
            <TableHead>Score</TableHead>
            <TableHead>Checks</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Completed</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={6} className="text-center py-10 text-surface-400">Loading…</TableCell></TableRow>
          ) : !filtered?.length ? (
            <TableRow><TableCell colSpan={6} className="text-center py-10 text-surface-400">No DQ runs found</TableCell></TableRow>
          ) : filtered.map((r) => (
            <TableRow key={r.id}>
              <TableCell>
                <Link href={`/dq/${r.id}`} className="font-medium text-primary-700 hover:underline text-sm">
                  {r.run_name}
                </Link>
              </TableCell>
              <TableCell className="max-w-[180px] truncate text-surface-600">{r.dataset_name}</TableCell>
              <TableCell><ScorePill score={r.overall_score} /></TableCell>
              <TableCell className="text-sm text-surface-600">
                <span className="text-green-600 font-medium">{r.passed_checks}✓</span>
                {" / "}
                <span className="text-red-500">{r.failed_checks}✗</span>
                {" / "}
                <span className="text-surface-400">{r.total_checks}</span>
              </TableCell>
              <TableCell>
                <Badge variant={statusVariant(r.status)}>
                  {r.status.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase())}
                </Badge>
              </TableCell>
              <TableCell className="text-surface-500">{r.completed_at ? formatDate(r.completed_at) : "—"}</TableCell>
            </TableRow>
          ))}
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
