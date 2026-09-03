"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

export function Shimmer({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        "relative overflow-hidden bg-slate-200/70 rounded-xl before:absolute before:inset-0 before:-translate-x-full before:animate-[shimmer_1.8s_infinite] before:bg-gradient-to-r before:from-transparent before:via-white/50 before:to-transparent",
        className
      )}
    />
  );
}

export function DetailSkeleton() {
  return (
    <div className="w-full space-y-6 animate-pulse">
      {/* Top Breadcrumb & Action Row */}
      <div className="flex flex-wrap items-center justify-between gap-4 pb-4 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="h-9 w-9 rounded-xl bg-slate-200" />
          <div className="space-y-2">
            <div className="flex items-center gap-2">
              <div className="h-4 w-28 bg-slate-200 rounded-md" />
              <div className="h-4 w-16 bg-slate-200 rounded-full" />
            </div>
            <div className="h-6 w-56 bg-slate-300 rounded-md" />
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="h-9 w-24 bg-slate-200 rounded-xl" />
          <div className="h-9 w-28 bg-slate-200 rounded-xl" />
        </div>
      </div>

      {/* Main Content Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div className="rounded-2xl border border-slate-200/80 bg-white p-5 space-y-4 shadow-sm">
          <div className="h-5 w-40 bg-slate-200 rounded-md" />
          <div className="space-y-3 pt-2">
            <div className="h-10 bg-slate-100 rounded-xl" />
            <div className="h-10 bg-slate-100 rounded-xl" />
            <div className="h-20 bg-slate-100 rounded-xl" />
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200/80 bg-white p-5 space-y-4 shadow-sm">
          <div className="h-5 w-48 bg-slate-200 rounded-md" />
          <div className="space-y-3 pt-2">
            <div className="h-10 bg-slate-100 rounded-xl" />
            <div className="h-10 bg-slate-100 rounded-xl" />
            <div className="h-20 bg-slate-100 rounded-xl" />
          </div>
        </div>
      </div>

      {/* Wide Bottom Card */}
      <div className="rounded-2xl border border-slate-200/80 bg-white p-5 space-y-4 shadow-sm">
        <div className="h-5 w-56 bg-slate-200 rounded-md" />
        <div className="space-y-2 pt-2">
          <div className="h-12 bg-slate-50 rounded-xl" />
          <div className="h-12 bg-slate-50 rounded-xl" />
          <div className="h-12 bg-slate-50 rounded-xl" />
        </div>
      </div>
    </div>
  );
}

export function TableSkeleton({ rows = 5, cols = 6 }: { rows?: number; cols?: number }) {
  return (
    <div className="w-full space-y-3 animate-pulse p-4">
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 py-2 border-b border-slate-100">
          <div className="h-4 w-6 bg-slate-200 rounded shrink-0" />
          <div className="h-4 w-32 bg-slate-200 rounded" />
          <div className="h-4 w-48 bg-slate-100 rounded flex-1" />
          <div className="h-4 w-20 bg-slate-200 rounded-full" />
          <div className="h-4 w-24 bg-slate-100 rounded" />
        </div>
      ))}
    </div>
  );
}

export function CardSkeleton() {
  return (
    <div className="rounded-2xl border border-slate-200/80 bg-white p-5 space-y-4 shadow-sm animate-pulse">
      <div className="h-5 w-36 bg-slate-200 rounded-md" />
      <div className="h-4 w-full bg-slate-100 rounded" />
      <div className="h-4 w-2/3 bg-slate-100 rounded" />
    </div>
  );
}
