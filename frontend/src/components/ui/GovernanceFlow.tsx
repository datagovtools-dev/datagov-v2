"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { Check, Sparkles, AlertCircle } from "lucide-react";

export interface GovernanceStep {
  id: string;
  label: string;
  sublabel?: string;
  status: "completed" | "active" | "pending" | "warning";
}

export interface GovernanceFlowProps {
  steps?: GovernanceStep[];
  currentStepId?: string;
  className?: string;
  interactive?: boolean;
  onStepClick?: (step: GovernanceStep) => void;
}

const DEFAULT_GOVERNANCE_STEPS: GovernanceStep[] = [
  { id: "discover",   label: "Discover",   sublabel: "Data Assets",  status: "completed" },
  { id: "understand", label: "Understand", sublabel: "Metadata",     status: "completed" },
  { id: "own",        label: "Own",        sublabel: "Stewardship",  status: "active" },
  { id: "govern",     label: "Govern",     sublabel: "DSR & DPIA",   status: "pending" },
  { id: "measure",    label: "Measure",    sublabel: "Data Quality", status: "pending" },
  { id: "trust",      label: "Trust",      sublabel: "Certified",    status: "pending" },
];

export function GovernanceFlow({
  steps = DEFAULT_GOVERNANCE_STEPS,
  currentStepId,
  className,
  interactive = false,
  onStepClick,
}: GovernanceFlowProps) {
  const activeIndex = steps.findIndex(
    (s) => s.status === "active" || s.id === currentStepId
  );
  const progressPct =
    activeIndex >= 0
      ? (activeIndex / Math.max(1, steps.length - 1)) * 100
      : 50;

  return (
    <div className={cn("w-full py-4 px-2", className)}>
      <div className="relative flex items-center justify-between">
        {/* Background Track Line */}
        <div className="absolute left-3 right-3 top-1/2 -translate-y-1/2 h-[3px] bg-slate-200 rounded-full z-0" />

        {/* Animated Signal Progress Fill Line */}
        <div
          className="absolute left-3 top-1/2 -translate-y-1/2 h-[3px] bg-gradient-to-r from-blue-500 via-amber-500 to-emerald-500 rounded-full z-0 transition-all duration-700 shadow-[0_0_12px_rgba(245,158,11,0.5)]"
          style={{ width: `calc(${progressPct}% + 6px)` }}
        />

        {/* Interactive Governance Nodes */}
        {steps.map((step, idx) => {
          const isCompleted = step.status === "completed";
          const isActive = step.status === "active" || step.id === currentStepId;
          const isWarning = step.status === "warning";

          return (
            <div
              key={step.id}
              onClick={() => interactive && onStepClick?.(step)}
              className={cn(
                "relative z-10 flex flex-col items-center group transition-all duration-200",
                interactive && "cursor-pointer hover:scale-110"
              )}
            >
              {/* Circular Signal Node */}
              <div
                className={cn(
                  "w-7 h-7 rounded-full border-2 flex items-center justify-center transition-all duration-300 shadow-sm",
                  isCompleted &&
                    "border-emerald-500 bg-emerald-500 text-white shadow-emerald-500/25",
                  isActive &&
                    "border-amber-500 bg-white ring-4 ring-amber-500/20 scale-110 shadow-amber-500/30",
                  isWarning &&
                    "border-rose-500 bg-rose-500 text-white shadow-rose-500/25",
                  !isCompleted &&
                    !isActive &&
                    !isWarning &&
                    "border-slate-300 bg-slate-100 text-slate-400"
                )}
              >
                {isCompleted && <Check className="w-4 h-4 stroke-[2.5]" />}
                {isActive && (
                  <span className="w-2.5 h-2.5 rounded-full bg-amber-500 animate-pulse" />
                )}
                {isWarning && <AlertCircle className="w-4 h-4" />}
              </div>

              {/* Node Title & Subtitle */}
              <div className="absolute top-9 flex flex-col items-center text-center whitespace-nowrap">
                <span
                  className={cn(
                    "text-xs font-bold tracking-tight transition-colors",
                    isActive
                      ? "text-amber-800 font-extrabold"
                      : isCompleted
                      ? "text-slate-800 font-semibold"
                      : "text-slate-400"
                  )}
                >
                  {step.label}
                </span>
                {step.sublabel && (
                  <span className="text-[10px] text-slate-500 hidden sm:inline-block font-medium">
                    {step.sublabel}
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
