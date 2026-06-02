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
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between px-6 py-4 border-b border-surface-200 sticky top-0 bg-white rounded-t-xl">
          <div>
            {code && <p className="text-xs text-surface-400 font-mono">{code}</p>}
            {title && <h2 className="text-base font-semibold text-surface-900">{title}</h2>}
          </div>
          <button
            onClick={onClose}
            className="h-8 w-8 flex items-center justify-center rounded-md hover:bg-surface-100 text-surface-500"
            aria-label="Close"
          >
            X
          </button>
        </div>
        {loading ? (
          <p className="text-sm text-surface-400 text-center py-10">Loading...</p>
        ) : (
          <div className="px-6 py-5">
            {children}
          </div>
        )}
      </div>
    </div>
  );
}
