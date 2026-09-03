"use client";

import * as React from "react";
import Link from "next/link";
import { AlertTriangle, ArrowRight, CheckCircle, Info, ShieldAlert, X } from "lucide-react";
import { cn } from "@/lib/utils";

export interface FloatingCardProps {
  type?: "warning" | "risk" | "info" | "success" | "recommendation";
  title: string;
  subtitle?: string;
  description: string;
  actionLabel?: string;
  actionHref?: string;
  onAction?: () => void;
  onDismiss?: () => void;
  className?: string;
}

export function FloatingCard({
  type = "warning",
  title,
  subtitle,
  description,
  actionLabel,
  actionHref,
  onAction,
  onDismiss,
  className,
}: FloatingCardProps) {
  const iconMap = {
    warning: <AlertTriangle className="h-4 w-4 text-warning-orange shrink-0" />,
    risk: <ShieldAlert className="h-4 w-4 text-risk-red shrink-0" />,
    info: <Info className="h-4 w-4 text-info-cyan shrink-0" />,
    success: <CheckCircle className="h-4 w-4 text-quality-green shrink-0" />,
    recommendation: <Info className="h-4 w-4 text-governance-amber shrink-0" />,
  };

  const borderMap = {
    warning: "border-l-warning-orange bg-warning-orange-soft/40",
    risk: "border-l-risk-red bg-risk-red-soft/40",
    info: "border-l-info-cyan bg-info-cyan-soft/40",
    success: "border-l-quality-green bg-quality-green-soft/40",
    recommendation: "border-l-governance-amber bg-governance-amber-soft/40",
  };

  return (
    <div
      className={cn(
        "rounded-xl border border-border-subtle bg-white p-4 shadow-floating transition-all duration-standard border-l-4 hover:-translate-y-0.5",
        borderMap[type],
        className
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-2">
          {iconMap[type]}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wider text-ink-primary">
              {title}
            </h4>
            {subtitle && (
              <span className="text-2xs font-mono text-ink-secondary block">
                {subtitle}
              </span>
            )}
          </div>
        </div>
        {onDismiss && (
          <button
            onClick={onDismiss}
            className="text-ink-muted hover:text-ink-primary p-0.5 rounded transition-colors"
            aria-label="Dismiss"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        )}
      </div>

      <p className="text-xs text-ink-secondary mt-2 leading-relaxed">
        {description}
      </p>

      {(actionLabel || actionHref || onAction) && (
        <div className="mt-3 pt-2 border-t border-border-subtle/60 flex justify-end">
          {actionHref ? (
            <Link
              href={actionHref}
              className="inline-flex items-center gap-1 text-xs font-semibold text-governance-amber-dark hover:text-governance-amber transition-colors"
            >
              {actionLabel || "Investigate"} <ArrowRight className="h-3 w-3" />
            </Link>
          ) : (
            <button
              onClick={onAction}
              className="inline-flex items-center gap-1 text-xs font-semibold text-governance-amber-dark hover:text-governance-amber transition-colors"
            >
              {actionLabel || "Resolve"} <ArrowRight className="h-3 w-3" />
            </button>
          )}
        </div>
      )}
    </div>
  );
}
