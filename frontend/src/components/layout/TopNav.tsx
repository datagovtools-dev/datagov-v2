"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Search,
  ChevronDown,
  LogOut,
  User,
  Plus,
  FolderOpen,
  Share2,
  ShieldAlert,
  BarChart2,
  Command,
} from "lucide-react";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/store/authStore";
import { NotificationDrawer } from "@/components/notifications/NotificationDrawer";
import { CommandPalette } from "@/components/ui/CommandPalette";

export function TopNav() {
  const router = useRouter();
  const { user, logout } = useAuthStore();
  const [commandOpen, setCommandOpen] = React.useState(false);
  const [createMenuOpen, setCreateMenuOpen] = React.useState(false);

  return (
    <>
      <header className="flex h-[var(--topnav-height)] items-center justify-between px-4 sm:px-6 bg-white border-b border-slate-200 shrink-0 sticky top-0 z-30 transition-colors">
        {/* Workspace Context */}
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-slate-100 border border-slate-200 text-xs font-mono text-slate-700">
            <span className="font-semibold">control-plane</span>
            <span className="text-slate-400">/</span>
            <span className="text-slate-500">production</span>
          </div>
        </div>

        {/* Global Search Command Trigger */}
        <button
          onClick={() => setCommandOpen(true)}
          className="hidden md:flex items-center gap-2.5 h-7.5 w-64 lg:w-80 rounded-md border border-slate-200 bg-slate-50/50 px-2.5 text-xs text-slate-400 hover:bg-white hover:border-slate-300 hover:text-slate-600 transition-colors mx-4"
        >
          <Search className="h-3.5 w-3.5 text-slate-400 shrink-0" />
          <span className="truncate">Search assets, glossary, rules...</span>
          <div className="ml-auto flex items-center">
            <kbd className="inline-flex items-center gap-0.5 rounded border border-slate-200 bg-white px-1 py-0.2 text-[10px] font-mono text-slate-500 shadow-2xs">
              <Command className="h-2.5 w-2.5" /> K
            </kbd>
          </div>
        </button>

        {/* Right actions: + Create, Notifications, User Avatar */}
        <div className="flex items-center gap-2">
          {/* Quick Create Action */}
          <DropdownMenu.Root open={createMenuOpen} onOpenChange={setCreateMenuOpen}>
            <DropdownMenu.Trigger asChild>
              <button
                className={cn(
                  "flex items-center gap-1 h-7.5 px-2.5 rounded-md text-xs font-medium bg-slate-900 text-white shadow-2xs hover:bg-slate-800 transition-colors focus:outline-none focus:ring-1 focus:ring-slate-950",
                  createMenuOpen && "bg-slate-800"
                )}
              >
                <Plus className="h-3.5 w-3.5" />
                <span className="hidden sm:inline">Create</span>
              </button>
            </DropdownMenu.Trigger>

            <DropdownMenu.Portal>
              <DropdownMenu.Content
                sideOffset={6}
                align="end"
                className="z-50 min-w-[200px] rounded-md border border-slate-200 bg-white p-1 shadow-floating animate-in fade-in-0 zoom-in-95"
              >
                <div className="px-2 py-1 text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">
                  Direct Workflows
                </div>
                <DropdownMenu.Item
                  className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs text-slate-800 cursor-pointer hover:bg-slate-100 transition-colors outline-none"
                  onSelect={() => router.push("/projects/new")}
                >
                  <FolderOpen className="h-3.5 w-3.5 text-slate-600 shrink-0" />
                  <div>
                    <div className="font-medium">New Data Asset</div>
                    <div className="text-[10px] text-slate-400">Register project & assets</div>
                  </div>
                </DropdownMenu.Item>
                <DropdownMenu.Item
                  className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs text-slate-800 cursor-pointer hover:bg-slate-100 transition-colors outline-none"
                  onSelect={() => router.push("/dsr/new")}
                >
                  <Share2 className="h-3.5 w-3.5 text-slate-600 shrink-0" />
                  <div>
                    <div className="font-medium">Data Sharing Request</div>
                    <div className="text-[10px] text-slate-400">Initiate DSR sharing flow</div>
                  </div>
                </DropdownMenu.Item>
                <DropdownMenu.Item
                  className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs text-slate-800 cursor-pointer hover:bg-slate-100 transition-colors outline-none"
                  onSelect={() => router.push("/dq/new")}
                >
                  <BarChart2 className="h-3.5 w-3.5 text-slate-600 shrink-0" />
                  <div>
                    <div className="font-medium">Data Quality Run</div>
                    <div className="text-[10px] text-slate-400">Run quality rules</div>
                  </div>
                </DropdownMenu.Item>
                <DropdownMenu.Item
                  className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs text-slate-800 cursor-pointer hover:bg-slate-100 transition-colors outline-none"
                  onSelect={() => router.push("/dpia/new")}
                >
                  <ShieldAlert className="h-3.5 w-3.5 text-slate-600 shrink-0" />
                  <div>
                    <div className="font-medium">DPIA Assessment</div>
                    <div className="text-[10px] text-slate-400">Evaluate privacy risk</div>
                  </div>
                </DropdownMenu.Item>
              </DropdownMenu.Content>
            </DropdownMenu.Portal>
          </DropdownMenu.Root>

          {/* Notification Center */}
          <NotificationDrawer />

          {/* User Profile */}
          <DropdownMenu.Root>
            <DropdownMenu.Trigger asChild>
              <button className="flex items-center gap-2 rounded-md px-2 py-1 hover:bg-slate-100 transition-colors focus:outline-none focus:ring-1 focus:ring-slate-950 border border-transparent hover:border-slate-200">
                <div className="flex h-6 w-6 items-center justify-center rounded-md bg-slate-900 text-white text-xs font-mono font-medium">
                  {user?.full_name?.charAt(0).toUpperCase() ?? "U"}
                </div>
                <div className="hidden md:flex flex-col text-left">
                  <span className="text-xs font-medium text-slate-900 max-w-[120px] truncate leading-tight">
                    {user?.full_name ?? "User"}
                  </span>
                  <span className="text-[10px] text-slate-400 truncate capitalize font-mono">
                    {user?.is_super_admin ? "Super Admin" : "Officer"}
                  </span>
                </div>
                <ChevronDown className="h-3 w-3 text-slate-400" />
              </button>
            </DropdownMenu.Trigger>

            <DropdownMenu.Portal>
              <DropdownMenu.Content
                sideOffset={6}
                align="end"
                className="z-50 min-w-[180px] rounded-md border border-slate-200 bg-white shadow-floating p-1 animate-in fade-in-0 zoom-in-95"
              >
                <div className="px-2.5 py-1.5 border-b border-slate-100 mb-0.5">
                  <div className="text-xs font-medium text-slate-900 truncate">
                    {user?.full_name}
                  </div>
                  <div className="text-[10px] text-slate-400 font-mono truncate">{user?.email}</div>
                </div>
                <DropdownMenu.Item
                  className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs text-slate-700 cursor-pointer hover:bg-slate-100 transition-colors outline-none"
                  onSelect={() => router.push("/settings/users")}
                >
                  <User className="h-3.5 w-3.5 text-slate-400" /> Account Settings
                </DropdownMenu.Item>
                <DropdownMenu.Item
                  className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs text-rose-600 cursor-pointer hover:bg-rose-50 transition-colors outline-none font-medium"
                  onSelect={logout}
                >
                  <LogOut className="h-3.5 w-3.5" /> Sign Out
                </DropdownMenu.Item>
              </DropdownMenu.Content>
            </DropdownMenu.Portal>
          </DropdownMenu.Root>
        </div>
      </header>

      {/* Global Command Search Palette */}
      <CommandPalette open={commandOpen} onOpenChange={setCommandOpen} />
    </>
  );
}
