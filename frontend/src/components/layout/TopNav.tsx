"use client";

import { Search, ChevronDown, LogOut, User } from "lucide-react";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/store/authStore";
import { NotificationDrawer } from "@/components/notifications/NotificationDrawer";

export function TopNav() {
  const { user, logout } = useAuthStore();

  return (
    <header className="flex h-[var(--topnav-height)] items-center justify-between px-6 bg-white border-b border-surface-200 shrink-0">
      {/* Search */}
      <div className="relative hidden md:flex items-center">
        <Search className="absolute left-3 h-4 w-4 text-surface-400 pointer-events-none" />
        <input
          type="search"
          placeholder="Search..."
          className="h-9 w-64 rounded-md border border-surface-200 bg-surface-50 pl-9 pr-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
        />
      </div>

      <div className="flex items-center gap-3 ml-auto">
        {/* Notifications */}
        <NotificationDrawer />

        {/* User menu */}
        <DropdownMenu.Root>
          <DropdownMenu.Trigger asChild>
            <button className="flex items-center gap-2 rounded-full pl-1 pr-2 py-1 hover:bg-surface-100 transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500">
              <div className="flex h-7 w-7 items-center justify-center rounded-full bg-primary-600 text-white text-xs font-semibold">
                {user?.full_name?.charAt(0).toUpperCase() ?? "U"}
              </div>
              <span className="hidden md:block text-sm font-medium text-surface-700 max-w-[120px] truncate">
                {user?.full_name ?? "User"}
              </span>
              <ChevronDown className="h-3 w-3 text-surface-400" />
            </button>
          </DropdownMenu.Trigger>

          <DropdownMenu.Portal>
            <DropdownMenu.Content
              sideOffset={8}
              align="end"
              className="z-50 min-w-[180px] rounded-lg border border-surface-200 bg-white shadow-card-hover p-1 animate-fade-in"
            >
              <DropdownMenu.Label className="px-3 py-2 text-xs text-surface-400">
                {user?.email}
              </DropdownMenu.Label>
              <DropdownMenu.Separator className="my-1 h-px bg-surface-100" />
              <DropdownMenu.Item
                className="flex items-center gap-2 rounded-md px-3 py-2 text-sm text-surface-700 cursor-pointer hover:bg-surface-50 focus:outline-none focus:bg-surface-50"
                onSelect={() => window.location.assign("/settings/profile")}
              >
                <User className="h-4 w-4" /> My Profile
              </DropdownMenu.Item>
              <DropdownMenu.Item
                className="flex items-center gap-2 rounded-md px-3 py-2 text-sm text-red-600 cursor-pointer hover:bg-red-50 focus:outline-none focus:bg-red-50"
                onSelect={logout}
              >
                <LogOut className="h-4 w-4" /> Sign Out
              </DropdownMenu.Item>
            </DropdownMenu.Content>
          </DropdownMenu.Portal>
        </DropdownMenu.Root>
      </div>
    </header>
  );
}
