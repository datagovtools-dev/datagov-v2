import * as React from "react";
import { cn } from "@/lib/utils";
import { AlertCircle } from "lucide-react";

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, hint, id, ...props }, ref) => {
    const inputId = id ?? label?.toLowerCase().replace(/\s+/g, "-");
    return (
      <div className="flex flex-col gap-1.5 w-full">
        {label && (
          <label htmlFor={inputId} className="text-xs font-bold text-slate-700 flex items-center justify-between">
            <span>
              {label}
              {props.required && <span className="ml-1 text-rose-500 font-bold">*</span>}
            </span>
          </label>
        )}
        <div className="relative">
          <input
            ref={ref}
            id={inputId}
            className={cn(
              "input-base",
              error && "border-rose-300 bg-rose-50/40 text-rose-900 focus:border-rose-500 focus:ring-rose-500/20",
              className
            )}
            {...props}
          />
        </div>
        {error && (
          <p className="flex items-center gap-1 text-[11px] font-medium text-rose-600 animate-in fade-in-50">
            <AlertCircle className="h-3 w-3 shrink-0" />
            <span>{error}</span>
          </p>
        )}
        {!error && hint && (
          <p className="text-[11px] text-slate-400 font-medium">{hint}</p>
        )}
      </div>
    );
  }
);
Input.displayName = "Input";

export { Input };
