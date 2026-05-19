"use client";

import * as React from "react";
import { Check, ChevronsUpDown, X } from "lucide-react";
import { cn } from "@/lib/utils";

export interface UserOption {
  value: string;
  label: string;
  sublabel?: string;
}

interface UserComboboxProps {
  label: string;
  options: UserOption[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
  error?: string;
}

export function UserCombobox({ label, options, value, onChange, placeholder = "Search employee…", required, error }: UserComboboxProps) {
  const [open, setOpen] = React.useState(false);
  const [query, setQuery] = React.useState("");
  const containerRef = React.useRef<HTMLDivElement>(null);
  const inputRef = React.useRef<HTMLInputElement>(null);

  const selected = options.find(o => o.value === value);

  const filtered = query.trim()
    ? options.filter(o => o.label.toLowerCase().includes(query.toLowerCase()) || (o.sublabel ?? "").toLowerCase().includes(query.toLowerCase()))
    : options;

  // Close on outside click
  React.useEffect(() => {
    function handle(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
        setQuery("");
      }
    }
    document.addEventListener("mousedown", handle);
    return () => document.removeEventListener("mousedown", handle);
  }, []);

  function handleOpen() {
    setOpen(true);
    setQuery("");
    setTimeout(() => inputRef.current?.focus(), 50);
  }

  function handleSelect(val: string) {
    onChange(val === value ? "" : val);
    setOpen(false);
    setQuery("");
  }

  function handleClear(e: React.MouseEvent) {
    e.stopPropagation();
    onChange("");
    setOpen(false);
    setQuery("");
  }

  return (
    <div className="flex flex-col gap-1" ref={containerRef}>
      <label className="text-sm font-medium text-surface-700">
        {label}{required && <span className="text-red-500 ml-0.5">*</span>}
      </label>
      <div className="relative">
        {/* Trigger */}
        <button
          type="button"
          onClick={handleOpen}
          className={cn(
            "input-base flex items-center justify-between w-full text-left",
            open && "border-primary-500 ring-1 ring-primary-500",
            error && !open && "border-red-400 ring-1 ring-red-300 bg-red-50",
          )}
        >
          <span className={cn("truncate text-sm", !selected && "text-surface-400")}>
            {selected ? selected.label : "— None —"}
          </span>
          <span className="flex items-center gap-1 ml-2 shrink-0">
            {selected && (
              <span onClick={handleClear} className="rounded hover:bg-surface-100 p-0.5">
                <X className="h-3 w-3 text-surface-400" />
              </span>
            )}
            <ChevronsUpDown className="h-4 w-4 text-surface-400" />
          </span>
        </button>

        {error && <p className="mt-1 text-xs text-red-500">{error}</p>}

        {/* Dropdown */}
        {open && (
          <div className="absolute z-50 mt-1 w-full rounded-md border border-surface-200 bg-white shadow-lg">
            <div className="p-2 border-b border-surface-100">
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={e => setQuery(e.target.value)}
                placeholder={placeholder}
                className="w-full text-sm px-2 py-1.5 rounded border border-surface-200 outline-none focus:border-primary-400"
              />
            </div>
            <ul className="max-h-56 overflow-y-auto py-1">
              <li
                onClick={() => handleSelect("")}
                className="flex items-center gap-2 px-3 py-2 text-sm cursor-pointer hover:bg-surface-50 text-surface-500"
              >
                <span className="w-4" />
                — None —
              </li>
              {filtered.length === 0 && options.length === 0 && (
                <li className="px-3 py-2 text-sm text-surface-400 text-center">No employees in system yet</li>
              )}
              {filtered.length === 0 && options.length > 0 && (
                <li className="px-3 py-2 text-sm text-surface-400 text-center">No match for &ldquo;{query}&rdquo;</li>
              )}
              {filtered.map(o => (
                <li
                  key={o.value}
                  onClick={() => handleSelect(o.value)}
                  className="flex items-center gap-2 px-3 py-2 text-sm cursor-pointer hover:bg-surface-50"
                >
                  <Check className={cn("h-4 w-4 text-primary-600 shrink-0", value === o.value ? "opacity-100" : "opacity-0")} />
                  <span className="flex flex-col min-w-0">
                    <span className="font-medium truncate">{o.label}</span>
                    {o.sublabel && <span className="text-xs text-surface-400 truncate">{o.sublabel}</span>}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
