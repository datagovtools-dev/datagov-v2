import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva("badge", {
  variants: {
    variant: {
      default:     "bg-surface-100 text-surface-700",
      primary:     "bg-primary-100 text-primary-700",
      success:     "bg-green-100 text-green-700",
      warning:     "bg-amber-100 text-amber-700",
      danger:      "bg-red-100 text-red-700",
      info:        "bg-blue-100 text-blue-700",
      // workflow statuses
      draft:       "bg-surface-100 text-surface-500",
      pending:     "bg-amber-100 text-amber-700",
      "in-review": "bg-blue-100 text-blue-700",
      approved:    "bg-green-100 text-green-700",
      rejected:    "bg-red-100 text-red-700",
      done:        "bg-primary-100 text-primary-700",
      // sensitivity
      public:       "bg-green-100 text-green-700",
      internal:     "bg-blue-100 text-blue-700",
      confidential: "bg-amber-100 text-amber-700",
      restricted:   "bg-red-100 text-red-700",
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
