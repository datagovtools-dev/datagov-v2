"use client";

import * as React from "react";
import { Upload, X, FileText } from "lucide-react";
import { cn } from "@/lib/utils";

interface FileUploadProps {
  accept?: string;
  maxSizeMb?: number;
  onChange?: (file: File | null) => void;
  label?: string;
  error?: string;
  className?: string;
}

export function FileUpload({ accept, maxSizeMb = 10, onChange, label, error, className }: FileUploadProps) {
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
    <div className={cn("flex flex-col gap-1", className)}>
      {label && <span className="text-sm font-medium text-surface-700">{label}</span>}
      <div
        role="button"
        tabIndex={0}
        onClick={() => inputRef.current?.click()}
        onKeyDown={(e) => e.key === "Enter" && inputRef.current?.click()}
        onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragOver(false);
          const dropped = e.dataTransfer.files[0];
          if (dropped) handleFile(dropped);
        }}
        className={cn(
          "flex flex-col items-center justify-center gap-2 rounded-lg border-2 border-dashed p-6 cursor-pointer transition-colors",
          dragOver ? "border-primary-400 bg-primary-50" : "border-surface-200 bg-surface-50 hover:border-primary-300",
          (error || sizeError) && "border-red-300",
        )}
      >
        {file ? (
          <div className="flex items-center gap-2 text-sm text-surface-700">
            <FileText className="h-4 w-4 text-primary-500" />
            <span className="truncate max-w-[200px]">{file.name}</span>
            <button onClick={clear} className="ml-1 text-surface-400 hover:text-red-500">
              <X className="h-4 w-4" />
            </button>
          </div>
        ) : (
          <>
            <Upload className="h-6 w-6 text-surface-400" />
            <p className="text-sm text-surface-500">
              Drag & drop or <span className="text-primary-600 font-medium">browse</span>
            </p>
            <p className="text-xs text-surface-400">Max {maxSizeMb} MB{accept ? ` · ${accept}` : ""}</p>
          </>
        )}
      </div>
      <input ref={inputRef} type="file" accept={accept} className="hidden" onChange={(e) => {
        const f = e.target.files?.[0];
        if (f) handleFile(f);
      }} />
      {(error || sizeError) && <p className="text-xs text-red-500">{error ?? sizeError}</p>}
    </div>
  );
}
