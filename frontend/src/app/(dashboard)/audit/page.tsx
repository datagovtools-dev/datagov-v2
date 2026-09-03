"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { formatDateTime } from "@/lib/utils";

interface AuditLogItem {
  id: number;
  user_id: string | null;
  actor_name: string | null;
  module: string;
  action: string;
  entity_type: string | null;
  entity_id: string | null;
  details: Record<string, unknown> | null;
  ip_address: string | null;
  created_at: string;
}

interface AuditLogPage {
  items: AuditLogItem[];
  total: number;
  page: number;
  page_size: number;
}

const MODULE_COLORS: Record<string, "primary" | "warning" | "info" | "danger" | "success" | "default"> = {
  auth: "default", project: "default", dsr: "warning", dpia: "info",
  ropa: "info", bapd: "danger", metadata: "success", dq: "success",
  rbac: "default", audit: "default",
};

const MODULES = ["", "auth", "project", "dsr", "dpia", "ropa", "bapd", "dq", "metadata", "rbac"];

export default function AuditLogPage() {
  const [moduleFilter, setModuleFilter] = useState("");
  const [actionFilter, setActionFilter] = useState("");
  const [entityFilter, setEntityFilter] = useState("");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [page, setPage] = useState(1);
  const pageSize = 50;

  const { data, isLoading } = useQuery<AuditLogPage>({
    queryKey: ["audit-logs", moduleFilter, actionFilter, entityFilter, dateFrom, dateTo, page],
    queryFn: () => {
      const p = new URLSearchParams({ page: String(page), page_size: String(pageSize) });
      if (moduleFilter) p.set("module", moduleFilter);
      if (actionFilter) p.set("action", actionFilter);
      if (entityFilter) p.set("entity_id", entityFilter);
      if (dateFrom) p.set("date_from", dateFrom);
      if (dateTo) p.set("date_to", dateTo);
      return api.get<AuditLogPage>(`/audit-logs?${p}`);
    },
  });

  const totalPages = data ? Math.ceil(data.total / pageSize) : 1;

  function resetFilters() {
    setModuleFilter(""); setActionFilter(""); setEntityFilter("");
    setDateFrom(""); setDateTo(""); setPage(1);
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Audit Telemetry
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Immutable record of all governance operations and state transitions
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-md border border-slate-200 p-3 shadow-2xs space-y-2.5">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-2.5">
          <div>
            <label className="block text-[10px] font-semibold text-slate-500 font-mono uppercase mb-1">Module</label>
            <select
              value={moduleFilter}
              onChange={(e) => { setModuleFilter(e.target.value); setPage(1); }}
              className="w-full border border-slate-200 rounded-md px-2 py-1 text-xs bg-white text-slate-900 focus:outline-none focus:ring-1 focus:ring-slate-950 font-mono"
            >
              {MODULES.map((m) => <option key={m} value={m}>{m || "All Modules"}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-[10px] font-semibold text-slate-500 font-mono uppercase mb-1">Action</label>
            <Input
              value={actionFilter}
              onChange={(e) => { setActionFilter(e.target.value); setPage(1); }}
              placeholder="e.g. create, approve"
              className="h-7 text-xs font-mono"
            />
          </div>
          <div>
            <label className="block text-[10px] font-semibold text-slate-500 font-mono uppercase mb-1">Entity ID</label>
            <Input
              value={entityFilter}
              onChange={(e) => { setEntityFilter(e.target.value); setPage(1); }}
              placeholder="UUID or tracking ID"
              className="h-7 text-xs font-mono"
            />
          </div>
          <div>
            <label className="block text-[10px] font-semibold text-slate-500 font-mono uppercase mb-1">From</label>
            <Input
              type="datetime-local"
              value={dateFrom}
              onChange={(e) => { setDateFrom(e.target.value); setPage(1); }}
              className="h-7 text-xs font-mono"
            />
          </div>
          <div>
            <label className="block text-[10px] font-semibold text-slate-500 font-mono uppercase mb-1">To</label>
            <Input
              type="datetime-local"
              value={dateTo}
              onChange={(e) => { setDateTo(e.target.value); setPage(1); }}
              className="h-7 text-xs font-mono"
            />
          </div>
        </div>
        <div className="flex items-center justify-between pt-1 border-t border-slate-100">
          <Button variant="outline" size="sm" onClick={resetFilters} className="h-6.5 text-[11px]">
            Reset Filters
          </Button>
          {data && <span className="text-xs text-slate-500 font-mono">{data.total.toLocaleString()} entries recorded</span>}
        </div>
      </div>

      {/* Table */}
      <div className="rounded-md border border-slate-200 bg-white overflow-hidden shadow-2xs">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Timestamp</TableHead>
              <TableHead>Actor</TableHead>
              <TableHead>Module</TableHead>
              <TableHead>Action</TableHead>
              <TableHead>Entity</TableHead>
              <TableHead>Details</TableHead>
              <TableHead className="w-24">IP Address</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow><TableCell colSpan={7} className="text-center py-10 text-xs text-slate-400 font-mono">Loading…</TableCell></TableRow>
            ) : !data?.items.length ? (
              <TableRow><TableCell colSpan={7} className="text-center py-10 text-xs text-slate-400 font-mono">No audit entries match filters</TableCell></TableRow>
            ) : data.items.map((log) => (
              <TableRow key={log.id}>
                <TableCell className="font-mono text-xs text-slate-500 whitespace-nowrap">
                  {formatDateTime(log.created_at)}
                </TableCell>
                <TableCell className="font-medium text-slate-900 text-xs">
                  {log.actor_name || "System"}
                </TableCell>
                <TableCell>
                  <Badge variant={MODULE_COLORS[log.module] ?? "default"} className="capitalize text-[10px] font-mono">
                    {log.module}
                  </Badge>
                </TableCell>
                <TableCell className="font-mono text-xs text-slate-700">
                  {log.action.replace(/_/g, " ")}
                </TableCell>
                <TableCell>
                  {log.entity_id ? (
                    <span className="font-mono text-xs text-slate-600">
                      {log.entity_type && <span className="text-slate-400 mr-1">{log.entity_type}/</span>}
                      {log.entity_id.length > 16 ? `${log.entity_id.slice(0, 16)}…` : log.entity_id}
                    </span>
                  ) : <span className="text-slate-300 font-mono">—</span>}
                </TableCell>
                <TableCell className="max-w-xs">
                  {log.details ? (
                    <span className="text-[11px] text-slate-500 font-mono truncate block">{JSON.stringify(log.details)}</span>
                  ) : <span className="text-slate-300 font-mono">—</span>}
                </TableCell>
                <TableCell className="text-xs text-slate-400 font-mono">{log.ip_address || "—"}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-3 py-2 border-t border-slate-100 bg-slate-50/50">
            <span className="text-xs text-slate-500 font-mono">
              Page {page} of {totalPages} ({data?.total.toLocaleString()} total)
            </span>
            <div className="flex gap-1">
              <Button size="icon" variant="outline" className="h-7 w-7" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                <ChevronLeft className="h-3.5 w-3.5" />
              </Button>
              <Button size="icon" variant="outline" className="h-7 w-7" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>
                <ChevronRight className="h-3.5 w-3.5" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
