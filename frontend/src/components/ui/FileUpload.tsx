"use client";

import * as React from "react";
import { Upload, X, FileText, CheckCircle2, AlertCircle } from "lucide-react";
import { cn } from "@/lib/utils";

interface FileUploadProps {
  accept?: string;
  maxSizeMb?: number;
  onChange?: (file: File | null) => void;
  label?: string;
  error?: string;
  className?: string;
}

export function FileUpload({
  accept,
  maxSizeMb = 10,
  onChange,
  label,
  error,
  className,
}: FileUploadProps) {
  const [file, setFile] = React.useState<File | null>(null);
  const [dragOver, setDragOver] = React.useState(false);
  const [sizeError, setSizeError] = React.useState<string | null>(null);
  const inputRef = React.useRef<HTMLInputElement>(null);

  function handleFile(f: File) {
    if (f.size > maxSizeMb * 1024 * 1024) {
      setSizeError(`File exceeds ${maxSizeMb} MB limit`);
      return;
    }
    setSizeError(null);
    setFile(f);
    onChange?.(f);
  }

  function clear(e: React.MouseEvent) {
    e.stopPropagation();
    setFile(null);
    setSizeError(null);
    onChange?.(null);
    if (inputRef.current) inputRef.current.value = "";
  }

  return (
    <div className={cn("flex flex-col gap-1.5 w-full", className)}>
      {label && <span className="text-xs font-bold text-slate-700">{label}</span>}
      <div
        role="button"
        tabIndex={0}
        onClick={() => inputRef.current?.click()}
        onKeyDown={(e) => e.key === "Enter" && inputRef.current?.click()}
        onDragOver={(e) => {
          e.preventDefault();
          setDragOver(true);
        }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragOver(false);
          const dropped = e.dataTransfer.files[0];
          if (dropped) handleFile(dropped);
        }}
        className={cn(
          "flex flex-col items-center justify-center gap-2.5 rounded-2xl border-2 border-dashed p-6 cursor-pointer transition-all duration-200",
          dragOver
            ? "border-amber-500 bg-amber-500/10 scale-[1.01]"
            : "border-slate-200 bg-slate-50/60 hover:border-amber-500/50 hover:bg-amber-500/5",
          (error || sizeError) && "border-rose-300 bg-rose-50/30"
        )}
      >
        {file ? (
          <div className="flex items-center gap-3 text-xs sm:text-sm font-semibold text-slate-800 bg-white px-3.5 py-2 rounded-xl border border-slate-200 shadow-xs animate-in zoom-in-95">
            <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
            <span className="truncate max-w-[220px]">{file.name}</span>
            <span className="text-[11px] text-slate-400 font-mono">
              ({(file.size / (1024 * 1024)).toFixed(2)} MB)
            </span>
            <button
              onClick={clear}
              className="ml-1 text-slate-400 hover:text-rose-600 p-1 rounded-lg hover:bg-rose-50 transition-colors"
              aria-label="Remove file"
            >
              <X className="h-3.5 w-3.5" />
            </button>
          </div>
        ) : (
          <>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white border border-slate-200 shadow-2xs text-slate-500">
              <Upload className="h-5 w-5 text-amber-600" />
            </div>
            <div className="text-center">
              <p className="text-xs sm:text-sm text-slate-600 font-medium">
                Drag and drop file here, or{" "}
                <span className="text-amber-700 font-bold hover:underline">browse</span>
              </p>
              <p className="text-[11px] text-slate-400 mt-0.5">
                Maximum size {maxSizeMb} MB {accept ? `· Supported: ${accept}` : ""}
              </p>
            </div>
          </>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className="hidden"
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) handleFile(f);
        }}
      />
      {(error || sizeError) && (
        <p className="flex items-center gap-1 text-[11px] font-medium text-rose-600 animate-in fade-in-50">
          <AlertCircle className="h-3 w-3 shrink-0" />
          <span>{error ?? sizeError}</span>
        </p>
      )}
    </div>
  );
}
