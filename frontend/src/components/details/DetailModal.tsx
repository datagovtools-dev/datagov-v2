"use client";

import * as React from "react";

interface DetailModalProps {
  code?: string | null;
  title?: string | null;
  onClose: () => void;
  children: React.ReactNode;
  loading?: boolean;
}

export function DetailModal({ code, title, onClose, children, loading }: DetailModalProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-slate-900/40 backdrop-blur-xs" onClick={onClose} />
      <div className="relative bg-white rounded-md border border-slate-200 shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between px-5 py-3.5 border-b border-slate-100 sticky top-0 bg-white z-10">
          <div>
            {code && <p className="text-[10px] text-slate-400 font-mono">{code}</p>}
            {title && <h2 className="text-sm font-bold text-slate-900">{title}</h2>}
          </div>
          <button
            onClick={onClose}
            className="h-7 w-7 flex items-center justify-center rounded-md hover:bg-slate-100 text-slate-500 text-xs font-mono"
            aria-label="Close"
          >
            ✕
          </button>
        </div>
        {loading ? (
          <p className="text-xs text-slate-400 text-center py-10 font-mono">Loading details...</p>
        ) : (
          <div className="p-5">
            {children}
          </div>
        )}
      </div>
    </div>
  );
}
