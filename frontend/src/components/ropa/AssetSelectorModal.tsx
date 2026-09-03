"use client";

import React, { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { Search, Database, Check, Plus, X } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Badge } from "@/components/ui/Badge";

export interface ProjectOption {
  id: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
}

export interface SourceTableInfo {
  table_name: string;
  column_count: number;
  documented: boolean;
  row_count: number | null;
  source_type: string;
}

interface AssetSelectorModalProps {
  isOpen: boolean;
  onClose: () => void;
  selectedAssets: string[];
  onSave: (assets: string[]) => void;
  initialProjectId?: string;
  projects?: ProjectOption[];
}

export function AssetSelectorModal({
  isOpen,
  onClose,
  selectedAssets,
  onSave,
  initialProjectId = "",
  projects = [],
}: AssetSelectorModalProps) {
  const [filterProjectId, setFilterProjectId] = useState<string>(initialProjectId);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [tempSelected, setTempSelected] = useState<string[]>(selectedAssets);
  const [customInput, setCustomInput] = useState<string>("");

  // Sync initial state when modal opens
  React.useEffect(() => {
    if (isOpen) {
      setTempSelected(selectedAssets);
      setFilterProjectId(initialProjectId);
      setSearchQuery("");
      setCustomInput("");
    }
  }, [isOpen, selectedAssets, initialProjectId]);

  // Fetch metadata tables based on project filter
  const { data: tables = [], isLoading } = useQuery<SourceTableInfo[]>({
    queryKey: ["metadata-tables-selector", filterProjectId],
    queryFn: () => {
      const url = filterProjectId ? `/metadata/tables?project_id=${filterProjectId}` : "/metadata/tables";
      return api.get<SourceTableInfo[]>(url);
    },
    enabled: isOpen,
  });

  const filteredTables = useMemo(() => {
    if (!searchQuery.trim()) return tables;
    const q = searchQuery.toLowerCase();
    return tables.filter((t) => t.table_name.toLowerCase().includes(q));
  }, [tables, searchQuery]);

  function toggleItem(name: string) {
    setTempSelected((prev) =>
      prev.includes(name) ? prev.filter((x) => x !== name) : [...prev, name]
    );
  }

  function handleAddCustom() {
    if (!customInput.trim()) return;
    const name = customInput.trim();
    if (!tempSelected.includes(name)) {
      setTempSelected((prev) => [...prev, name]);
    }
    setCustomInput("");
  }

  function handleSelectAll() {
    const tableNames = filteredTables.map((t) => t.table_name);
    const combined = Array.from(new Set([...tempSelected, ...tableNames]));
    setTempSelected(combined);
  }

  function handleDeselectAll() {
    const tableNames = new Set(filteredTables.map((t) => t.table_name));
    setTempSelected((prev) => prev.filter((x) => !tableNames.has(x)));
  }

  function handleApply() {
    onSave(tempSelected);
    onClose();
  }

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-xs" onClick={onClose} />
      <div className="relative bg-white rounded-lg border border-slate-200 shadow-2xl w-full max-w-2xl max-h-[90vh] flex flex-col overflow-hidden animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100 bg-slate-50/50">
          <div className="flex items-center gap-2">
            <div className="h-8 w-8 rounded-md bg-blue-100 text-blue-700 flex items-center justify-center">
              <Database className="h-4 w-4" />
            </div>
            <div>
              <h2 className="text-sm font-bold text-slate-900">Select Data Assets &amp; Catalogue Tables</h2>
              <p className="text-xs text-slate-500">Browse catalogue tables or add custom data assets to this ROPA</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="h-7 w-7 flex items-center justify-center rounded-md hover:bg-slate-200 text-slate-500 text-xs font-mono transition-colors"
          >
            ✕
          </button>
        </div>

        {/* Filters & Search */}
        <div className="p-4 border-b border-slate-100 bg-white space-y-3">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            <div>
              <label className="text-[11px] font-semibold text-slate-600 block mb-1">Filter by Project</label>
              <select
                value={filterProjectId}
                onChange={(e) => setFilterProjectId(e.target.value)}
                className="w-full border border-slate-200 rounded-md px-2.5 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-slate-400 bg-white h-8"
              >
                <option value="">All Projects (Global Catalog)</option>
                {projects.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.project_code ? `[${p.project_code}] ` : ""}{p.project_name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="text-[11px] font-semibold text-slate-600 block mb-1">Search Tables</label>
              <div className="relative">
                <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-slate-400" />
                <Input
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search table or asset name..."
                  className="pl-8 h-8 text-xs"
                />
              </div>
            </div>
          </div>

          {/* Quick Custom Asset Adder */}
          <div className="flex gap-2 pt-1 border-t border-slate-100">
            <Input
              value={customInput}
              onChange={(e) => setCustomInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault();
                  handleAddCustom();
                }
              }}
              placeholder="Or type custom asset name (e.g. customer_crm_export)..."
              className="h-8 text-xs font-mono flex-1"
            />
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={handleAddCustom}
              disabled={!customInput.trim()}
              className="h-8 text-xs"
            >
              <Plus className="h-3 w-3 mr-1" /> Add Custom
            </Button>
          </div>
        </div>

        {/* Selected preview chips */}
        {tempSelected.length > 0 && (
          <div className="px-4 py-2.5 bg-blue-50/50 border-b border-blue-100 flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5 flex-wrap max-h-20 overflow-y-auto">
              <span className="text-[11px] font-semibold text-blue-900 font-mono">
                {tempSelected.length} Selected:
              </span>
              {tempSelected.map((name) => (
                <Badge
                  key={name}
                  variant="info"
                  className="text-[11px] px-2 py-0.5 font-mono flex items-center gap-1 bg-white text-blue-800 border border-blue-200"
                >
                  {name}
                  <button
                    type="button"
                    onClick={() => toggleItem(name)}
                    className="hover:text-rose-600 rounded-full"
                  >
                    <X className="h-3 w-3" />
                  </button>
                </Badge>
              ))}
            </div>
            <button
              type="button"
              onClick={() => setTempSelected([])}
              className="text-[11px] text-rose-600 hover:text-rose-800 font-medium whitespace-nowrap"
            >
              Clear All
            </button>
          </div>
        )}

        {/* Table list */}
        <div className="p-4 flex-1 overflow-y-auto space-y-2 min-h-[220px]">
          <div className="flex items-center justify-between text-xs text-slate-500 pb-1">
            <span>
              {isLoading ? "Loading tables..." : `${filteredTables.length} tables found`}
            </span>
            {filteredTables.length > 0 && (
              <div className="flex gap-2 text-[11px]">
                <button
                  type="button"
                  onClick={handleSelectAll}
                  className="text-blue-600 hover:underline font-medium"
                >
                  Select All
                </button>
                <span>·</span>
                <button
                  type="button"
                  onClick={handleDeselectAll}
                  className="text-slate-500 hover:underline"
                >
                  Deselect Visible
                </button>
              </div>
            )}
          </div>

          {isLoading ? (
            <div className="py-12 text-center text-xs text-slate-400 font-mono">Loading data catalogue...</div>
          ) : filteredTables.length === 0 ? (
            <div className="py-12 text-center text-slate-400 space-y-2">
              <Database className="h-8 w-8 mx-auto text-slate-300" />
              <p className="text-xs">No catalogue tables found matching your search.</p>
              <p className="text-[11px] text-slate-400">You can type a custom asset name above and click "Add Custom".</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
              {filteredTables.map((tbl) => {
                const isSelected = tempSelected.includes(tbl.table_name);
                return (
                  <div
                    key={tbl.table_name}
                    onClick={() => toggleItem(tbl.table_name)}
                    className={`p-2.5 rounded-md border text-xs cursor-pointer transition-all flex items-start justify-between gap-2 ${
                      isSelected
                        ? "bg-blue-50 border-blue-300 text-blue-900 shadow-2xs"
                        : "bg-white border-slate-200 text-slate-700 hover:bg-slate-50"
                    }`}
                  >
                    <div className="flex items-start gap-2.5 min-w-0">
                      <div
                        className={`h-4 w-4 mt-0.5 rounded border flex items-center justify-center shrink-0 ${
                          isSelected ? "bg-blue-600 border-blue-600 text-white" : "border-slate-300 bg-white"
                        }`}
                      >
                        {isSelected && <Check className="h-3 w-3" />}
                      </div>
                      <div className="min-w-0">
                        <p className="font-mono font-semibold truncate text-[12px]" title={tbl.table_name}>
                          {tbl.table_name}
                        </p>
                        <p className="text-[10px] text-slate-500 font-mono mt-0.5">
                          {tbl.column_count} columns · {tbl.source_type.toUpperCase()}
                          {tbl.row_count !== null ? ` · ${tbl.row_count.toLocaleString()} rows` : ""}
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-slate-100 bg-slate-50 flex items-center justify-between">
          <span className="text-xs text-slate-500 font-mono">
            {tempSelected.length} asset{tempSelected.length === 1 ? "" : "s"} selected
          </span>
          <div className="flex items-center gap-2">
            <Button type="button" variant="outline" size="sm" onClick={onClose} className="h-8 text-xs">
              Cancel
            </Button>
            <Button
              type="button"
              size="sm"
              onClick={handleApply}
              className="h-8 text-xs font-medium bg-blue-600 hover:bg-blue-700 text-white"
            >
              Apply Selection ({tempSelected.length})
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
