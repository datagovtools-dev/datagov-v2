"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { Sparkles, TrendingUp, ShieldCheck } from "lucide-react";

export interface TrustScoreDimension {
  name: string;
  score: number;
  weight?: number;
  color: string;
}

export interface TrustScoreRingProps {
  score: number;
  delta?: number;
  label?: string;
  statusLabel?: string;
  size?: number;
  strokeWidth?: number;
  dimensions?: TrustScoreDimension[];
  className?: string;
}

export function TrustScoreRing({
  score,
  delta = 4.2,
  label = "Enterprise Data Trust Score",
  statusLabel = "Certified Healthy",
  size = 148,
  strokeWidth = 11,
  dimensions = [
    { name: "Metadata Completeness", score: 94, color: "#3B82F6" },
    { name: "Data Quality Health",   score: 89, color: "#10B981" },
    { name: "Accountable Ownership", score: 85, color: "#F59E0B" },
    { name: "Privacy & DPIA Matrix", score: 92, color: "#8B5CF6" },
    { name: "Retention Compliance",  score: 80, color: "#06B6D4" },
  ],
  className,
}: TrustScoreRingProps) {
  const center = size / 2;
  const radius = center - strokeWidth;
  const circumference = 2 * Math.PI * radius;

  // Segment calculations
  const segmentGap = 4; // gap between segments in degrees
  const totalGapLength = dimensions.length * ((segmentGap / 360) * circumference);
  const availableCircumference = circumference - totalGapLength;
  const segmentLength = availableCircumference / dimensions.length;

  let currentOffset = 0;

  return (
    <div className={cn("flex flex-col sm:flex-row items-center gap-6 w-full", className)}>
      {/* Interactive SVG Circular Ring */}
      <div className="relative shrink-0 flex items-center justify-center" style={{ width: size, height: size }}>
        {/* Soft glowing ambient background */}
        <div className="absolute inset-2 rounded-full bg-amber-500/5 blur-xl pointer-events-none" />

        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="rotate-[-90deg]">
          {/* Background track */}
          <circle
            cx={center}
            cy={center}
            r={radius}
            fill="none"
            stroke="#F1F5F9"
            strokeWidth={strokeWidth}
          />
          {/* Segmented dimension rings */}
          {dimensions.map((dim, i) => {
            const fillLength = (dim.score / 100) * segmentLength;
            const strokeDasharray = `${fillLength} ${circumference - fillLength}`;
            const strokeDashoffset = -currentOffset;
            currentOffset += segmentLength + (segmentGap / 360) * circumference;

            return (
              <circle
                key={i}
                cx={center}
                cy={center}
                r={radius}
                fill="none"
                stroke={dim.color}
                strokeWidth={strokeWidth}
                strokeDasharray={strokeDasharray}
                strokeDashoffset={strokeDashoffset}
                strokeLinecap="round"
                className="transition-all duration-700 ease-out"
              />
            );
          })}
        </svg>

        {/* Center score readout */}
        <div className="absolute inset-0 flex flex-col items-center justify-center text-center select-none">
          <span className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight leading-none tabular-nums">
            {score}
          </span>
          <span className="text-[10px] uppercase font-bold tracking-widest text-slate-400 mt-1">
            SCORE / 100
          </span>
          {delta !== undefined && (
            <span className="inline-flex items-center gap-0.5 text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full mt-1 border border-emerald-200/60 shadow-2xs">
              <TrendingUp className="h-3 w-3 text-emerald-600" /> +{delta}%
            </span>
          )}
        </div>
      </div>

      {/* Dimensional Breakdown Progress Bars */}
      <div className="space-y-2.5 w-full flex-1">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold uppercase tracking-wider text-slate-500">
            {label}
          </span>
          <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-amber-800 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200/60">
            <ShieldCheck className="h-3 w-3 text-amber-600" /> {statusLabel}
          </span>
        </div>

        <div className="space-y-2 pt-1">
          {dimensions.map((dim, idx) => (
            <div key={idx} className="space-y-1">
              <div className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: dim.color }} />
                  <span className="text-slate-600 font-medium truncate max-w-[150px] sm:max-w-none">
                    {dim.name}
                  </span>
                </div>
                <span className="font-bold text-slate-900 tabular-nums">{dim.score}%</span>
              </div>
              <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{ width: `${dim.score}%`, backgroundColor: dim.color }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
