"use client";

import * as React from "react";
import { Sidebar } from "./Sidebar";
import { TopNav } from "./TopNav";
import { Footer } from "./Footer";

export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = React.useState(false);

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
