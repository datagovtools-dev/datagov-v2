"use client";

import * as React from "react";
import { format, isValid, parseISO } from "date-fns";
import { CalendarIcon } from "lucide-react";
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

export function DatePicker({ value, onChange, label, error, disabled, required, min, max, className }: DatePickerProps) {
  const id = React.useId();
  const display = value && isValid(parseISO(value)) ? format(parseISO(value), "dd MMM yyyy") : "";

  return (
    <div className={cn("flex flex-col gap-1", className)}>
      {label && (
        <label htmlFor={id} className="text-sm font-medium text-surface-700">
          {label}
          {required && <span className="ml-1 text-red-500">*</span>}
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
            error && "border-red-400 focus:ring-red-400",
          )}
        />
        <CalendarIcon className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400" />
      </div>
      {error && <p className="text-xs text-red-500">{error}</p>}
    </div>
  );
}
