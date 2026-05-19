"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
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
  auth: "default", project: "primary", dsr: "warning", dpia: "info",
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
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Audit Log</h1>
        <p className="text-sm text-gray-500 mt-1">Immutable record of all governance actions across modules</p>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 space-y-3">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Module</label>
            <select value={moduleFilter} onChange={(e) => { setModuleFilter(e.target.value); setPage(1); }}
              className="w-full border border-gray-300 rounded-md px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
              {MODULES.map((m) => <option key={m} value={m}>{m || "All Modules"}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Action</label>
            <Input value={actionFilter} onChange={(e) => { setActionFilter(e.target.value); setPage(1); }}
              placeholder="e.g. create, approve" className="h-8 text-sm" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Entity ID</label>
            <Input value={entityFilter} onChange={(e) => { setEntityFilter(e.target.value); setPage(1); }}
              placeholder="UUID or tracking ID" className="h-8 text-sm" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">From</label>
            <Input type="datetime-local" value={dateFrom}
              onChange={(e) => { setDateFrom(e.target.value); setPage(1); }} className="h-8 text-sm" />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">To</label>
            <Input type="datetime-local" value={dateTo}
              onChange={(e) => { setDateTo(e.target.value); setPage(1); }} className="h-8 text-sm" />
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={resetFilters}>Reset Filters</Button>
          {data && <span className="text-xs text-gray-500">{data.total.toLocaleString()} entries found</span>}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-100 text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Timestamp</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actor</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Module</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Entity</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Details</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">IP</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {isLoading ? (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">Loading…</td></tr>
            ) : !data?.items.length ? (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">No audit entries match the current filters</td></tr>
            ) : data.items.map((log) => (
              <tr key={log.id} className="hover:bg-gray-50">
                <td className="px-4 py-2.5 whitespace-nowrap text-xs text-gray-500 font-mono">
                  {formatDateTime(log.created_at)}
                </td>
                <td className="px-4 py-2.5">
                  <span className="text-sm font-medium text-gray-800">{log.actor_name || "System"}</span>
                </td>
                <td className="px-4 py-2.5">
                  <Badge variant={MODULE_COLORS[log.module] ?? "default"} className="capitalize">{log.module}</Badge>
                </td>
                <td className="px-4 py-2.5 text-sm text-gray-700 font-mono">
                  {log.action.replace(/_/g, " ")}
                </td>
                <td className="px-4 py-2.5">
                  {log.entity_id ? (
                    <span className="font-mono text-xs text-gray-600">
                      {log.entity_type && <span className="text-gray-400 mr-1">{log.entity_type}/</span>}
                      {log.entity_id.length > 16 ? `${log.entity_id.slice(0, 16)}…` : log.entity_id}
                    </span>
                  ) : <span className="text-gray-300">—</span>}
                </td>
                <td className="px-4 py-2.5 max-w-xs">
                  {log.details ? (
                    <span className="text-xs text-gray-500 font-mono truncate block">{JSON.stringify(log.details)}</span>
                  ) : <span className="text-gray-300">—</span>}
                </td>
                <td className="px-4 py-2.5 text-xs text-gray-400 font-mono">{log.ip_address || "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-gray-50">
            <span className="text-xs text-gray-500">
              Page {page} of {totalPages} ({data?.total.toLocaleString()} total)
            </span>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>← Prev</Button>
              <Button variant="outline" size="sm" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Next →</Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
