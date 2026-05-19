"use client";

import { useState, useEffect, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Bell, X, Check, CheckCheck, Settings } from "lucide-react";
import Link from "next/link";
import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { formatDateTime } from "@/lib/utils";

interface NotificationItem {
  id: string;
  module: string;
  event: string;
  title: string;
  body: string | null;
  entity_type: string | null;
  entity_id: string | null;
  is_read: boolean;
  created_at: string;
}

interface NotificationListResponse {
  items: NotificationItem[];
  unread_count: number;
}

const MODULE_COLORS: Record<string, "primary" | "warning" | "info" | "danger" | "success" | "default"> = {
  dsr: "warning", dpia: "info", ropa: "info", bapd: "danger",
  dq: "success", metadata: "success", auth: "default", rbac: "default",
};

export function NotificationDrawer() {
  const [open, setOpen] = useState(false);
  const drawerRef = useRef<HTMLDivElement>(null);
  const qc = useQueryClient();

  const { data } = useQuery<NotificationListResponse>({
    queryKey: ["notifications"],
    queryFn: () => api.get<NotificationListResponse>("/notifications?limit=50"),
    refetchInterval: 30_000,
  });

  const markRead = useMutation({
    mutationFn: (id: string) => api.put(`/notifications/${id}/read`, {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["notifications"] }),
  });

  const markAllRead = useMutation({
    mutationFn: () => api.put("/notifications/read-all", {}),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["notifications"] }),
  });

  // Close on outside click
  useEffect(() => {
    function onClickOutside(e: MouseEvent) {
      if (drawerRef.current && !drawerRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    if (open) document.addEventListener("mousedown", onClickOutside);
    return () => document.removeEventListener("mousedown", onClickOutside);
  }, [open]);

  // Auto-dismiss after 5s when opened (per spec)
  useEffect(() => {
    if (!open) return;
    const timer = setTimeout(() => setOpen(false), 5000);
    return () => clearTimeout(timer);
  }, [open]);

  const unread = data?.unread_count ?? 0;

  return (
    <div className="relative" ref={drawerRef}>
      {/* Bell button */}
      <button
        onClick={() => setOpen((o) => !o)}
        className="relative rounded-full p-2 text-surface-500 hover:bg-surface-100 transition-colors"
        aria-label="Notifications"
      >
        <Bell className="h-4 w-4" />
        {unread > 0 && (
          <span className="absolute top-1 right-1 min-w-[16px] h-4 rounded-full bg-red-500 text-white text-[10px] font-bold flex items-center justify-center px-0.5">
            {unread > 99 ? "99+" : unread}
          </span>
        )}
      </button>

      {/* Slide-in drawer */}
      {open && (
        <div
          className="absolute right-0 top-10 w-96 max-h-[560px] bg-white rounded-xl shadow-xl border border-gray-200 z-50 flex flex-col animate-slide-in-right overflow-hidden"
          style={{ animation: "slideInRight 300ms ease-out" }}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
            <h3 className="font-semibold text-gray-900 text-sm">Notifications</h3>
            <div className="flex items-center gap-1">
              {unread > 0 && (
                <button
                  onClick={() => markAllRead.mutate()}
                  className="flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800 px-2 py-1 rounded hover:bg-blue-50"
                >
                  <CheckCheck className="h-3 w-3" /> Mark all read
                </button>
              )}
              <Link href="/settings/notifications"
                className="p-1.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600">
                <Settings className="h-3.5 w-3.5" />
              </Link>
              <button onClick={() => setOpen(false)}
                className="p-1.5 rounded hover:bg-gray-100 text-gray-400">
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>

          {/* List */}
          <div className="overflow-y-auto flex-1">
            {!data?.items.length ? (
              <div className="flex flex-col items-center justify-center py-12 text-gray-400">
                <Bell className="h-8 w-8 mb-2 opacity-40" />
                <p className="text-sm">You're all caught up!</p>
              </div>
            ) : (
              data.items.map((n) => (
                <div key={n.id}
                  className={`flex gap-3 px-4 py-3 border-b border-gray-50 hover:bg-gray-50 transition-colors cursor-pointer ${!n.is_read ? "bg-blue-50/40" : ""}`}
                  onClick={() => !n.is_read && markRead.mutate(n.id)}
                >
                  {!n.is_read && <span className="mt-1.5 w-2 h-2 rounded-full bg-blue-500 shrink-0" />}
                  {n.is_read && <span className="mt-1.5 w-2 h-2 shrink-0" />}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <Badge variant={MODULE_COLORS[n.module] ?? "default"} className="text-[10px] capitalize">
                        {n.module}
                      </Badge>
                      <span className="text-[10px] text-gray-400">{formatDateTime(n.created_at)}</span>
                    </div>
                    <p className={`text-sm ${n.is_read ? "text-gray-600" : "text-gray-900 font-medium"}`}>{n.title}</p>
                    {n.body && <p className="text-xs text-gray-500 mt-0.5 line-clamp-2">{n.body}</p>}
                  </div>
                  {!n.is_read && (
                    <button
                      onClick={(e) => { e.stopPropagation(); markRead.mutate(n.id); }}
                      className="shrink-0 p-1 rounded hover:bg-blue-100 text-blue-500"
                    >
                      <Check className="h-3 w-3" />
                    </button>
                  )}
                </div>
              ))
            )}
          </div>

          {/* Footer */}
          <div className="px-4 py-2 border-t border-gray-100 bg-gray-50">
            <Link href="/settings/notifications"
              className="text-xs text-blue-600 hover:underline">
              Manage notification preferences →
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
