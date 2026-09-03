import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva("badge", {
  variants: {
    variant: {
      default:      "bg-slate-100 text-slate-700 border-slate-200",
      primary:      "bg-slate-900 text-white border-slate-900",
      secondary:    "bg-slate-100 text-slate-700 border-slate-200",
      success:      "bg-emerald-50 text-emerald-700 border-emerald-200",
      warning:      "bg-amber-50 text-amber-700 border-amber-200",
      danger:       "bg-rose-50 text-rose-700 border-rose-200",
      info:         "bg-sky-50 text-sky-700 border-sky-200",
      neutral:      "bg-slate-50 text-slate-600 border-slate-200",
      // Health & Governance status tokens
      trusted:      "bg-emerald-50 text-emerald-700 border-emerald-200 font-medium",
      healthy:      "bg-emerald-50 text-emerald-700 border-emerald-200",
      review:       "bg-amber-50 text-amber-700 border-amber-200",
      risk:         "bg-rose-50 text-rose-700 border-rose-200",
      cde:          "bg-amber-50 text-amber-800 border-amber-200 font-semibold",
      // Workflow state mappings
      draft:        "bg-slate-100 text-slate-600 border-slate-200",
      pending:      "bg-amber-50 text-amber-700 border-amber-200",
      "in-review":  "bg-blue-50 text-blue-700 border-blue-200",
      approved:     "bg-emerald-50 text-emerald-700 border-emerald-200",
      rejected:     "bg-rose-50 text-rose-700 border-rose-200",
      done:         "bg-emerald-50 text-emerald-700 border-emerald-200",
      // Data Sensitivity tiers
      public:       "bg-emerald-50 text-emerald-700 border-emerald-200",
      internal:     "bg-slate-100 text-slate-700 border-slate-200",
      confidential: "bg-amber-50 text-amber-700 border-amber-200",
      restricted:   "bg-rose-50 text-rose-700 border-rose-200",
      // Categories
      metadata:     "bg-blue-50 text-blue-700 border-blue-200",
      lineage:      "bg-purple-50 text-purple-700 border-purple-200",
    },
  },
  defaultVariants: { variant: "default" },
});

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };
