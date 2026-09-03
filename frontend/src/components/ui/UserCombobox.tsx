"use client";

import * as React from "react";
import * as Popover from "@radix-ui/react-popover";
import { Check, ChevronsUpDown, X, Search, User } from "lucide-react";
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

export function UserCombobox({
  label,
  options,
  value,
  onChange,
  placeholder = "Search employee...",
  required,
  error,
}: UserComboboxProps) {
  const [open, setOpen] = React.useState(false);
  const [query, setQuery] = React.useState("");
  const inputRef = React.useRef<HTMLInputElement>(null);

  const selected = options.find((o) => o.value === value);

  const filtered = query.trim()
    ? options.filter(
        (o) =>
          o.label.toLowerCase().includes(query.toLowerCase()) ||
          (o.sublabel ?? "").toLowerCase().includes(query.toLowerCase())
      )
    : options;

  function handleOpenChange(isOpen: boolean) {
    setOpen(isOpen);
    if (isOpen) {
      setQuery("");
      setTimeout(() => inputRef.current?.focus(), 50);
    }
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
    <div className="flex flex-col gap-1.5 w-full">
      <label className="text-xs font-bold text-slate-700 flex items-center justify-between">
        <span>
          {label}
          {required && <span className="text-rose-500 ml-1 font-bold">*</span>}
        </span>
      </label>

      <Popover.Root open={open} onOpenChange={handleOpenChange}>
        <Popover.Trigger asChild>
          <button
            type="button"
            className={cn(
              "input-base flex items-center justify-between w-full text-left",
              open && "border-amber-500 ring-2 ring-amber-500/20",
              error && !open && "border-rose-300 ring-1 ring-rose-300 bg-rose-50/40 text-rose-900"
            )}
          >
            <span
              className={cn(
                "truncate text-xs sm:text-sm font-medium",
                !selected && "text-slate-400 font-normal"
              )}
            >
              {selected ? (
                <span className="flex items-center gap-2">
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-amber-100 text-[10px] font-bold text-amber-800 shrink-0">
                    {selected.label.charAt(0).toUpperCase()}
                  </span>
                  <span className="truncate">{selected.label}</span>
                </span>
              ) : (
                "— Select assignee —"
              )}
            </span>
            <span className="flex items-center gap-1 ml-2 shrink-0">
              {selected && (
                <span
                  onClick={handleClear}
                  className="rounded-lg hover:bg-slate-100 p-1 text-slate-400 hover:text-slate-600"
                >
                  <X className="h-3 w-3" />
                </span>
              )}
              <ChevronsUpDown className="h-4 w-4 text-slate-400" />
            </span>
          </button>
        </Popover.Trigger>

        {error && <p className="mt-1 text-[11px] font-medium text-rose-600">{error}</p>}

        <Popover.Portal>
          <Popover.Content
            sideOffset={6}
            align="start"
            side="bottom"
            avoidCollisions={true}
            collisionPadding={16}
            className="z-[9999] w-[var(--radix-popover-trigger-width)] min-w-[260px] max-w-[420px] rounded-2xl border border-slate-200 bg-white shadow-[0_16px_36px_rgba(0,0,0,0.15)] p-1.5 animate-in fade-in-0 zoom-in-95"
          >
            {/* Search Box */}
            <div className="flex items-center px-2.5 py-2 border-b border-slate-100 mb-1 gap-2 bg-slate-50/70 rounded-xl">
              <Search className="h-3.5 w-3.5 text-slate-400 shrink-0" />
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder={placeholder}
                className="w-full text-xs outline-none bg-transparent placeholder:text-slate-400 text-slate-800"
              />
              {query && (
                <button
                  type="button"
                  onClick={() => setQuery("")}
                  className="text-slate-400 hover:text-slate-600 p-0.5"
                >
                  <X className="h-3 w-3" />
                </button>
              )}
            </div>

            {/* List of Options */}
            <ul className="max-h-60 overflow-y-auto py-1 space-y-0.5">
              <li
                onClick={() => handleSelect("")}
                className="flex items-center gap-2 px-2.5 py-1.5 text-xs rounded-xl cursor-pointer hover:bg-slate-50 text-slate-400 font-medium"
              >
                <span className="w-4" />
                — None (Unassigned) —
              </li>

              {filtered.length === 0 && options.length === 0 && (
                <li className="px-3 py-6 text-xs text-slate-400 text-center">
                  No employees in system yet
                </li>
              )}

              {filtered.length === 0 && options.length > 0 && (
                <li className="px-3 py-6 text-xs text-slate-400 text-center">
                  No match found for &ldquo;{query}&rdquo;
                </li>
              )}

              {filtered.map((o) => (
                <li
                  key={o.value}
                  onClick={() => handleSelect(o.value)}
                  className="flex items-center gap-2.5 px-2.5 py-2 text-xs rounded-xl cursor-pointer hover:bg-amber-500/10 transition-colors group"
                >
                  <Check
                    className={cn(
                      "h-3.5 w-3.5 text-amber-600 shrink-0 font-bold",
                      value === o.value ? "opacity-100" : "opacity-0"
                    )}
                  />
                  <div className="flex items-center gap-2.5 min-w-0">
                    <span className="flex h-6 w-6 items-center justify-center rounded-full bg-slate-100 text-[10px] font-bold text-slate-700 shrink-0 group-hover:bg-amber-100 group-hover:text-amber-900">
                      {o.label.charAt(0).toUpperCase()}
                    </span>
                    <div className="flex flex-col min-w-0">
                      <span className="font-semibold text-slate-900 truncate">{o.label}</span>
                      {o.sublabel && (
                        <span className="text-[10px] text-slate-400 truncate font-normal">
                          {o.sublabel}
                        </span>
                      )}
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </Popover.Content>
        </Popover.Portal>
      </Popover.Root>
    </div>
  );
}
