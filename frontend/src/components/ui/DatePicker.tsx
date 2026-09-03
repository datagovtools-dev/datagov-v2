"use client";

import * as React from "react";
import { format, isValid, parseISO } from "date-fns";
import { CalendarIcon, AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";

interface DatePickerProps {
  value?: string;       // ISO date string "YYYY-MM-DD"
  onChange?: (value: string) => void;
  label?: string;
  error?: string;
  disabled?: boolean;
  required?: boolean;
  min?: string;
  max?: string;
  className?: string;
}

export function DatePicker({
  value,
  onChange,
  label,
  error,
  disabled,
  required,
  min,
  max,
  className,
}: DatePickerProps) {
  const id = React.useId();

  return (
    <div className={cn("flex flex-col gap-1.5 w-full", className)}>
      {label && (
        <label htmlFor={id} className="text-xs font-bold text-slate-700 flex items-center justify-between">
          <span>
            {label}
            {required && <span className="ml-1 text-rose-500 font-bold">*</span>}
          </span>
        </label>
      )}
      <div className="relative">
        <input
          id={id}
          type="date"
          value={value ?? ""}
          min={min}
          max={max}
          disabled={disabled}
          required={required}
          onChange={(e) => onChange?.(e.target.value)}
          className={cn(
            "input-base pr-10",
            error && "border-rose-300 bg-rose-50/40 text-rose-900 focus:border-rose-500 focus:ring-rose-500/20"
          )}
        />
        <CalendarIcon className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
      </div>
      {error && (
        <p className="flex items-center gap-1 text-[11px] font-medium text-rose-600 animate-in fade-in-50">
          <AlertCircle className="h-3 w-3 shrink-0" />
          <span>{error}</span>
        </p>
      )}
    </div>
  );
}
