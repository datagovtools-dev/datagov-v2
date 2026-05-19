"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard, Share2, ShieldCheck, ClipboardList,
  BookOpen, Trash2, Database, BarChart2, Bot, Settings, ChevronLeft,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface NavItem {
  label: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
}

const NAV_ITEMS: NavItem[] = [
  { label: "Dashboard",           href: "/dashboard",      icon: LayoutDashboard },
  { label: "Projects",            href: "/projects",       icon: Database },
  { label: "Data Sharing",        href: "/dsr",            icon: Share2 },
  { label: "AI Checklist",        href: "/ai-checklist",   icon: Bot },
  { label: "DPIA",                href: "/dpia",           icon: ShieldCheck },
  { label: "Metadata",            href: "/metadata",    icon: BookOpen },
  { label: "Data Quality",        href: "/dq",          icon: BarChart2 },
  { label: "ROPA",                href: "/ropa",        icon: ClipboardList },
  { label: "BAPD",                href: "/bapd",        icon: Trash2 },
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
        "flex flex-col h-full bg-white border-r border-surface-200 shadow-sidebar transition-[width] duration-200",
        collapsed ? "w-16" : "w-[var(--sidebar-width)]",
      )}
    >
      {/* Logo */}
      <div className="flex items-center gap-2 px-4 h-[var(--topnav-height)] border-b border-surface-200 shrink-0">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary-600 text-white text-xs font-bold shrink-0">
          DG
        </div>
        {!collapsed && (
          <span className="font-semibold text-surface-900 text-sm leading-tight">
            AI Governance<br />
            <span className="text-primary-600 font-bold">Tools</span>
          </span>
        )}
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto py-3 px-2 space-y-0.5">
        {NAV_ITEMS.map((item) => {
          const active = pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-md px-2 py-2 text-sm font-medium transition-colors",
                active
                  ? "bg-primary-50 text-primary-700"
                  : "text-surface-600 hover:bg-surface-50 hover:text-surface-900",
                collapsed && "justify-center",
              )}
              title={collapsed ? item.label : undefined}
            >
              <item.icon className={cn("h-4 w-4 shrink-0", active && "text-primary-600")} />
              {!collapsed && <span>{item.label}</span>}
              {!collapsed && item.badge && (
                <span className="ml-auto rounded-full bg-primary-100 px-1.5 py-0.5 text-2xs font-semibold text-primary-700">
                  {item.badge}
                </span>
              )}
            </Link>
          );
        })}
      </nav>

      {/* Settings + collapse toggle */}
      <div className="border-t border-surface-200 px-2 py-3 space-y-0.5">
        <Link
          href="/settings"
          className={cn(
            "flex items-center gap-3 rounded-md px-2 py-2 text-sm font-medium text-surface-600 hover:bg-surface-50 hover:text-surface-900 transition-colors",
            collapsed && "justify-center",
          )}
        >
          <Settings className="h-4 w-4 shrink-0" />
          {!collapsed && <span>Settings</span>}
        </Link>
        <button
          onClick={onToggle}
          className={cn(
            "flex w-full items-center gap-3 rounded-md px-2 py-2 text-sm font-medium text-surface-400 hover:bg-surface-50 hover:text-surface-700 transition-colors",
            collapsed && "justify-center",
          )}
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
        >
          <ChevronLeft className={cn("h-4 w-4 shrink-0 transition-transform", collapsed && "rotate-180")} />
          {!collapsed && <span>Collapse</span>}
        </button>
      </div>
    </aside>
  );
}
