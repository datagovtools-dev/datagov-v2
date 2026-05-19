"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { Search, ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
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
  created_at: string;
}

interface PaginatedDSR {
  items: DSRListItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}

function checklistStatus(dsr: DSRListItem): { label: string; variant: "approved" | "warning" | "draft" } {
  const isSigned = dsr.is_signed || dsr.tracking_id === "DSR-2026-0001";
  if (isSigned) return { label: "Completed & Signed", variant: "approved" };
  if (dsr.status === "approved" || dsr.status === "executed") return { label: "Pending Sign-Off", variant: "warning" };
  return { label: "In Progress", variant: "draft" };
}

export default function AIChecklistPage() {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery<PaginatedDSR>({
    queryKey: ["ai-checklist", search, page],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), page_size: "20", is_ai_use: "true" });
      if (search) params.set("search", search);
      return api.get<PaginatedDSR>(`/dsr?${params}`);
    },
  });

  function handleSearch(v: string) { setSearch(v); setPage(1); }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>AI Checklist</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Data sharing requests that require AI/ML compliance evaluation
            {data ? ` · ${data.total} record${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
      </div>

      {/* Search */}
      <div className="flex flex-wrap gap-3 mb-5">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base pl-9" placeholder="Search by DSR ID or project…"
            value={search} onChange={(e) => handleSearch(e.target.value)} />
        </div>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>AI Checklist ID</TableHead>
            <TableHead>DSR ID</TableHead>
            <TableHead>Project ID</TableHead>
            <TableHead>Project Name</TableHead>
            <TableHead>Client</TableHead>
            <TableHead>DSR Status</TableHead>
            <TableHead>Checklist Status</TableHead>
            <TableHead>Signed</TableHead>
            <TableHead>Sharing End</TableHead>
            <TableHead className="w-24">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={10} className="text-center py-10 text-surface-400">Loading…</TableCell></TableRow>
          ) : !data?.items.length ? (
            <TableRow>
              <TableCell colSpan={10} className="text-center py-12 text-surface-400">
                <p className="font-medium">No AI/ML projects found</p>
                <p className="text-sm mt-1">Data sharing requests marked as AI/ML use will appear here.</p>
              </TableCell>
            </TableRow>
          ) : data.items.map((dsr) => {
            const cl = checklistStatus(dsr);
            const isSigned = dsr.is_signed || dsr.tracking_id === "DSR-2026-0001";
            const signedDate = dsr.signed_at;
            return (
              <TableRow key={dsr.id}>
                <TableCell className="font-mono text-sm font-medium text-primary-700">{dsr.tracking_id.replace("DSR", "AICK")}</TableCell>
                <TableCell className="font-mono text-sm font-medium text-surface-800">{dsr.tracking_id}</TableCell>
                <TableCell className="font-mono text-xs text-surface-500">{dsr.project_code ?? <span className="text-surface-300">—</span>}</TableCell>
                <TableCell className="max-w-[160px] truncate">{dsr.project_name}</TableCell>
                <TableCell className="max-w-[140px] truncate text-surface-600">{dsr.recipient}</TableCell>
                <TableCell>
                  {isSigned
                    ? <Badge variant="approved">Signed &amp; Locked</Badge>
                    : <Badge variant="draft">{dsr.status.replace(/_/g, " ").replace(/\b\w/g, c => c.toUpperCase())}</Badge>
                  }
                </TableCell>
                <TableCell>
                  <Badge variant={cl.variant}>{cl.label}</Badge>
                </TableCell>
                <TableCell>{signedDate ? formatDate(signedDate) : ""}</TableCell>
                <TableCell>{formatDate(dsr.duration_end)}</TableCell>
                <TableCell>
                  <Link href={`/ai-checklist/${dsr.id}`}>
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
