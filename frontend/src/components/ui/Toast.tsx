"use client";

import * as React from "react";
import { Check, AlertCircle, Info, AlertTriangle, X } from "lucide-react";
import { cn } from "@/lib/utils";

export type ToastType = "success" | "error" | "info" | "warning" | "loading";

export interface ToastOptions {
  id?: string;
  title?: string;
  description?: string;
  type?: ToastType;
  duration?: number;
}

export interface ToastItem extends ToastOptions {
  id: string;
  createdAt: number;
}

type ToastListener = (toasts: ToastItem[]) => void;

class ToastManager {
  private toasts: ToastItem[] = [];
  private listeners: Set<ToastListener> = new Set();

  subscribe(listener: ToastListener) {
    this.listeners.add(listener);
    listener(this.toasts);
    return () => {
      this.listeners.delete(listener);
    };
  }

  private notify() {
    this.listeners.forEach((l) => l([...this.toasts]));
  }

  show(message: string, options?: ToastOptions): string {
    const id = options?.id ?? Math.random().toString(36).substring(2, 9);
    const type = options?.type ?? "info";
    const duration = options?.duration ?? (type === "loading" ? 0 : 4000);

    const existingIndex = this.toasts.findIndex((t) => t.id === id);
    const item: ToastItem = {
      id,
      title: options?.title ?? message,
      description: options?.description,
      type,
      duration,
      createdAt: Date.now(),
    };

    if (existingIndex >= 0) {
      this.toasts[existingIndex] = item;
    } else {
      this.toasts.push(item);
    }

    this.notify();

    if (duration > 0) {
      setTimeout(() => {
        this.dismiss(id);
      }, duration);
    }

    return id;
  }

  success(message: string, options?: Omit<ToastOptions, "type">) {
    return this.show(message, { ...options, type: "success" });
  }

  error(message: string, options?: Omit<ToastOptions, "type">) {
    return this.show(message, { ...options, type: "error", duration: options?.duration ?? 5000 });
  }

  loading(message: string, options?: Omit<ToastOptions, "type">) {
    return this.show(message, { ...options, type: "loading", duration: 0 });
  }

  info(message: string, options?: Omit<ToastOptions, "type">) {
    return this.show(message, { ...options, type: "info" });
  }

  warning(message: string, options?: Omit<ToastOptions, "type">) {
    return this.show(message, { ...options, type: "warning" });
  }

  dismiss(id: string) {
    this.toasts = this.toasts.filter((t) => t.id !== id);
    this.notify();
  }

  dismissAll() {
    this.toasts = [];
    this.notify();
  }
}

export const toast = new ToastManager();

function AnimatedIcon({ type }: { type: ToastType }) {
  switch (type) {
    case "success":
      return (
        <div className="relative flex h-7 w-7 items-center justify-center rounded-full bg-emerald-100 text-emerald-600 shrink-0 shadow-[0_0_16px_rgba(16,185,129,0.3)] animate-spring-pop">
          <Check className="h-4 w-4 stroke-[3]" />
        </div>
      );
    case "error":
      return (
        <div className="relative flex h-7 w-7 items-center justify-center rounded-full bg-rose-100 text-rose-600 shrink-0 shadow-[0_0_16px_rgba(239,68,68,0.3)] animate-spring-pop">
          <AlertCircle className="h-4 w-4 stroke-[2.5]" />
        </div>
      );
    case "warning":
      return (
        <div className="relative flex h-7 w-7 items-center justify-center rounded-full bg-amber-100 text-amber-600 shrink-0 shadow-[0_0_16px_rgba(245,158,11,0.3)] animate-spring-pop">
          <AlertTriangle className="h-4 w-4 stroke-[2.5]" />
        </div>
      );
    case "loading":
      return (
        <div className="relative flex h-7 w-7 items-center justify-center shrink-0">
          <div className="absolute h-7 w-7 rounded-full border-2 border-amber-500/20 border-t-amber-500 animate-orbit-fast" />
          <div className="h-2 w-2 rounded-full bg-amber-500 animate-pulse-glow" />
        </div>
      );
    default:
      return (
        <div className="relative flex h-7 w-7 items-center justify-center rounded-full bg-blue-100 text-blue-600 shrink-0 shadow-[0_0_16px_rgba(59,130,246,0.3)] animate-spring-pop">
          <Info className="h-4 w-4 stroke-[2.5]" />
        </div>
      );
  }
}

const TOAST_STYLES: Record<ToastType, string> = {
  success: "border-emerald-200 bg-white/95 text-slate-900 shadow-[0_12px_32px_rgba(16,185,129,0.18)] ring-1 ring-emerald-500/20",
  error:   "border-rose-200 bg-white/95 text-slate-900 shadow-[0_12px_32px_rgba(239,68,68,0.18)] ring-1 ring-rose-500/20",
  warning: "border-amber-200 bg-white/95 text-slate-900 shadow-[0_12px_32px_rgba(245,158,11,0.18)] ring-1 ring-amber-500/20",
  info:    "border-blue-200 bg-white/95 text-slate-900 shadow-[0_12px_32px_rgba(59,130,246,0.18)] ring-1 ring-blue-500/20",
  loading: "border-amber-300/80 bg-white/95 text-slate-900 shadow-[0_16px_40px_rgba(245,158,11,0.22)] ring-2 ring-amber-500/30",
};

export function ToastContainer() {
  const [toasts, setToasts] = React.useState<ToastItem[]>([]);

  React.useEffect(() => {
    return toast.subscribe(setToasts);
  }, []);

  if (toasts.length === 0) return null;

  return (
    <div
      aria-live="polite"
      className="fixed bottom-6 right-6 z-[999999] flex flex-col gap-3 max-w-sm sm:max-w-md w-full pointer-events-none"
    >
      {toasts.map((t) => (
        <div
          key={t.id}
          className={cn(
            "pointer-events-auto relative overflow-hidden flex items-start gap-3.5 p-4 rounded-2xl border backdrop-blur-2xl transition-all duration-300 shadow-xl",
            TOAST_STYLES[t.type || "info"],
            "animate-in slide-in-from-bottom-5 fade-in-0 duration-300"
          )}
        >
          <AnimatedIcon type={t.type || "info"} />

          <div className="flex-1 min-w-0 pt-0.5">
            <h4 className="text-xs sm:text-sm font-bold text-slate-900 leading-snug">
              {t.title}
            </h4>
            {t.description && (
              <p className="text-[11px] text-slate-500 mt-1 leading-relaxed">
                {t.description}
              </p>
            )}
          </div>

          <button
            type="button"
            onClick={() => toast.dismiss(t.id)}
            className="text-slate-400 hover:text-slate-700 p-1 rounded-lg hover:bg-slate-100 transition-colors shrink-0"
            aria-label="Close notification"
          >
            <X className="h-3.5 w-3.5" />
          </button>

          {/* Bottom Countdown Line for Disappearing Toasts */}
          {t.duration && t.duration > 0 && (
            <div className="absolute bottom-0 left-0 right-0 h-[2.5px] bg-slate-100 overflow-hidden">
              <div
                className={cn(
                  "h-full w-full origin-left transition-transform",
                  t.type === "success" && "bg-emerald-500",
                  t.type === "error" && "bg-rose-500",
                  t.type === "warning" && "bg-amber-500",
                  t.type === "info" && "bg-blue-500"
                )}
                style={{
                  animation: `laserShimmer ${t.duration}ms linear forwards`,
                }}
              />
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
