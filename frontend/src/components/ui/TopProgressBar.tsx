"use client";

import * as React from "react";
import { useIsFetching, useIsMutating } from "@tanstack/react-query";
import { cn } from "@/lib/utils";

export function TopProgressBar() {
  const isFetching = useIsFetching();
  const isMutating = useIsMutating();
  const active = isFetching > 0 || isMutating > 0;
  const [visible, setVisible] = React.useState(false);

  React.useEffect(() => {
    let timeout: NodeJS.Timeout;
    if (active) {
      setVisible(true);
    } else {
      timeout = setTimeout(() => setVisible(false), 300);
    }
    return () => clearTimeout(timeout);
  }, [active]);

  if (!visible) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-[999999] h-[3px] overflow-hidden pointer-events-none">
      <div
        className={cn(
          "h-full w-full animate-laser-shimmer shadow-[0_0_12px_rgba(245,158,11,0.9),0_0_24px_rgba(16,185,129,0.7)]"
        )}
      />
    </div>
  );
}
