import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-1.5 rounded-md text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-slate-950 disabled:pointer-events-none disabled:opacity-50 select-none",
  {
    variants: {
      variant: {
        default:     "bg-slate-900 text-white shadow-2xs hover:bg-slate-800 border border-slate-900 active:bg-slate-950",
        primary:     "bg-slate-900 text-white shadow-2xs hover:bg-slate-800 border border-slate-900 active:bg-slate-950",
        secondary:   "bg-slate-100 text-slate-900 border border-slate-200 hover:bg-slate-200/70",
        outline:     "border border-slate-200 bg-white text-slate-800 shadow-2xs hover:bg-slate-50 hover:border-slate-300",
        ghost:       "text-slate-600 hover:bg-slate-100 hover:text-slate-900",
        destructive: "bg-rose-600 text-white shadow-2xs hover:bg-rose-700 border border-rose-600",
        link:        "text-slate-900 underline-offset-4 hover:underline p-0 h-auto",
        amber:       "bg-amber-50 text-amber-800 border border-amber-200 hover:bg-amber-100/80",
      },
      size: {
        sm:   "h-7.5 px-2.5 text-xs",
        md:   "h-8.5 px-3 text-xs sm:text-sm",
        lg:   "h-9.5 px-4 text-sm",
        icon: "h-8 w-8",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "md",
    },
  },
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, loading, children, disabled, ...props }, ref) => (
    <button
      ref={ref}
      disabled={disabled || loading}
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    >
      {loading && (
        <svg className="animate-spin h-3.5 w-3.5 shrink-0" viewBox="0 0 24 24" fill="none">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
        </svg>
      )}
      {children}
    </button>
  ),
);
Button.displayName = "Button";

export { Button, buttonVariants };
