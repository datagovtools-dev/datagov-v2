"use client";

import * as React from "react";
import { Sidebar } from "./Sidebar";
import { TopNav } from "./TopNav";
import { Footer } from "./Footer";
import { useAuthStore } from "@/store/authStore";

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = React.useState(false);

  React.useEffect(() => {
    // The backend bypass is local-host-only. Hydrate the UI identity only on
    // local browsers; public/tunnel sessions must continue through login.
    const hostname = window.location.hostname.toLowerCase();
    if (!["localhost", "127.0.0.1", "::1"].includes(hostname)) return;

    let active = true;
    fetch("/api/v1/auth/me", { credentials: "include" })
      .then(async (response) => {
        if (!active || !response.ok) return;
        const user = await response.json();
        if (active) useAuthStore.getState().setAuth(user, "");
      })
      .catch(() => null);
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50 text-slate-900 relative">
      {/* Sidebar Navigation */}
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((c) => !c)} />

      {/* Main Content Area */}
      <div className="flex flex-1 flex-col overflow-hidden min-w-0 relative">
        <TopNav />
        <main className="flex-1 overflow-y-auto p-4 sm:p-5 max-w-[1600px] w-full mx-auto relative z-10">
          {children}
        </main>
        <Footer />
      </div>
    </div>
  );
}
