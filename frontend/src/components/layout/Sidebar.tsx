"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  FolderOpen,
  Share2,
  Bot,
  ShieldCheck,
  ClipboardList,
  Database,
  BarChart2,
  Trash2,
  History,
  Settings,
  Sparkles,
  ChevronLeft,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface NavGroup {
  title?: string;
  items: {
    label: string;
    href: string;
    icon: React.ComponentType<{ className?: string }>;
    badge?: string;
  }[];
}

const NAV_GROUPS: NavGroup[] = [
  {
    items: [{ label: "Executive Dashboard", href: "/dashboard", icon: LayoutDashboard }],
  },
  {
    title: "DISCOVER",
    items: [
      { label: "Data Assets Catalog", href: "/projects", icon: FolderOpen },
      { label: "Metadata Management", href: "/metadata", icon: Database },
    ],
  },
  {
    title: "GOVERN",
    items: [
      { label: "Data Sharing (DSR)", href: "/dsr", icon: Share2 },
      { label: "AI/ML Checklist (AICK)", href: "/ai-checklist", icon: Bot },
      { label: "Privacy Impact (DPIA)", href: "/dpia", icon: ShieldCheck },
      { label: "ROPA Records", href: "/ropa", icon: ClipboardList },
    ],
  },
  {
    title: "QUALITY",
    items: [{ label: "Data Quality Control", href: "/dq", icon: BarChart2 }],
  },
  {
    title: "CONTROL",
    items: [
      { label: "Extermination (BAPD)", href: "/bapd", icon: Trash2 },
      { label: "Audit Telemetry", href: "/audit", icon: History },
    ],
  },
  {
    title: "SYSTEM",
    items: [
      { label: "AI Setup & Ollama", href: "/settings/ai", icon: Sparkles },
      { label: "Settings & Access", href: "/settings", icon: Settings },
    ],
  },
];

interface SidebarProps {
  collapsed?: boolean;
  onToggle?: () => void;
}

export function Sidebar({ collapsed = false, onToggle }: SidebarProps) {
  const pathname = usePathname();

  return (
    <aside
      className={cn(
        "flex flex-col h-full bg-white border-r border-slate-200 transition-all duration-200 z-20 shrink-0 select-none",
        collapsed ? "w-14" : "w-[var(--sidebar-width)]"
      )}
    >
      {/* Brand Header */}
      <div className="flex items-center gap-2.5 px-3.5 h-[var(--topnav-height)] border-b border-slate-200 shrink-0">
        <div className="flex h-7 w-7 items-center justify-center rounded-md bg-slate-900 text-white font-mono font-bold text-xs shrink-0">
          DG
        </div>
        {!collapsed && (
          <div className="flex flex-col min-w-0">
            <span className="font-bold text-slate-900 text-xs tracking-tight truncate leading-tight">
              AI Governance
            </span>
            <span className="text-[10px] text-slate-500 font-mono tracking-tight leading-none mt-0.5">
              Control Plane
            </span>
          </div>
        )}
      </div>

      {/* Grouped Navigation */}
      <nav className="flex-1 overflow-y-auto py-3 px-2 space-y-3">
        {NAV_GROUPS.map((group, gIdx) => (
          <div key={gIdx} className="space-y-0.5">
            {group.title && !collapsed && (
              <div className="px-2 pt-1 pb-1 text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">
                {group.title}
              </div>
            )}
            {group.items.map((item) => {
              const active =
                item.href === "/dashboard"
                  ? pathname === "/dashboard"
                  : pathname.startsWith(item.href);

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "group flex items-center gap-2.5 rounded-md px-2.5 py-1.5 text-xs font-medium transition-colors",
                    active
                      ? "bg-slate-100 text-slate-900 font-semibold border-l-2 border-slate-900 pl-2"
                      : "text-slate-600 hover:bg-slate-50 hover:text-slate-900",
                    collapsed && "justify-center border-l-0 pl-2.5"
                  )}
                  title={collapsed ? item.label : undefined}
                >
                  <item.icon
                    className={cn(
                      "h-3.5 w-3.5 shrink-0 transition-colors",
                      active ? "text-slate-900" : "text-slate-400 group-hover:text-slate-600"
                    )}
                  />
                  {!collapsed && <span className="truncate">{item.label}</span>}
                  {!collapsed && item.badge && (
                    <span className="ml-auto rounded-md bg-slate-100 px-1.5 py-0.2 text-[10px] font-mono text-slate-700 border border-slate-200">
                      {item.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Collapse Action */}
      <div className="border-t border-slate-200 p-2">
        <button
          onClick={onToggle}
          className={cn(
            "flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-xs font-medium text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors",
            collapsed && "justify-center"
          )}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          <ChevronLeft
            className={cn(
              "h-3.5 w-3.5 shrink-0 transition-transform duration-200",
              collapsed && "rotate-180"
            )}
          />
          {!collapsed && <span>Collapse</span>}
        </button>
      </div>
    </aside>
  );
}
