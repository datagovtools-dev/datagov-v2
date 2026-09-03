"use client";

import Link from "next/link";
import {
  Bell,
  Bot,
  Shield,
  Users,
  SlidersHorizontal,
  ArrowRight,
  ShieldCheck,
  Sparkles,
} from "lucide-react";
import { Card, CardContent } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";

const SETTINGS_ITEMS = [
  {
    href: "/settings/users",
    label: "Manajemen Pengguna & Akses",
    description: "Kelola akun pengguna, penugasan role, dan inspeksi hak akses menu & aktivitas.",
    icon: Users,
    badge: "Directory",
    color: "from-blue-500/10 to-indigo-500/10 text-blue-700 border-blue-200",
    iconBg: "bg-blue-100 text-blue-700",
  },
  {
    href: "/settings/roles",
    label: "Katalog Role & Matriks Akses",
    description: "Definisi role platform, matriks izin navigasi menu, dan kapabilitas aktivitas bisnis.",
    icon: Shield,
    badge: "RBAC Matrix",
    color: "from-amber-500/10 to-orange-500/10 text-amber-700 border-amber-200",
    iconBg: "bg-amber-100 text-amber-700",
  },
  {
    href: "/settings/ai",
    label: "AI Setup & LLM Provider",
    description: "Konfigurasi provider Ollama Cloud, pemilihan model AI, dan parameter inferensi.",
    icon: Bot,
    badge: "AI Engine",
    color: "from-purple-500/10 to-pink-500/10 text-purple-700 border-purple-200",
    iconBg: "bg-purple-100 text-purple-700",
  },
  {
    href: "/settings/notifications",
    label: "Preferensi Notifikasi",
    description: "Pengaturan pengiriman notifikasi persetujuan via email dan in-app alert.",
    icon: Bell,
    badge: "Telemetry",
    color: "from-emerald-500/10 to-teal-500/10 text-emerald-700 border-emerald-200",
    iconBg: "bg-emerald-100 text-emerald-700",
  },
];

export default function SettingsPage() {
  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="border-b border-slate-200 pb-3">
        <div className="flex items-center gap-2">
          <h1 className="text-lg sm:text-xl font-bold text-slate-900 tracking-tight">System Settings &amp; Administration</h1>
          <Badge variant="neutral" className="text-[10px] font-mono">Control Plane</Badge>
        </div>
        <p className="text-xs text-slate-500 font-mono mt-0.5">
          Governance configuration control plane, RBAC directory, and AI engine telemetry
        </p>
      </div>

      {/* Settings Grid */}
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {SETTINGS_ITEMS.map((item) => (
          <Link key={item.href} href={item.href} className="group">
            <Card className="h-full hover:border-slate-400 transition-colors bg-white">
              <CardContent className="p-4 flex flex-col justify-between h-full gap-3">
                <div className="space-y-2.5">
                  <div className="flex items-center justify-between">
                    <div className="flex h-8 w-8 items-center justify-center rounded-md bg-slate-100 text-slate-800 border border-slate-200">
                      <item.icon className="h-4 w-4" />
                    </div>
                    <span className="text-[10px] font-mono font-semibold uppercase tracking-wider px-1.5 py-0.5 rounded-md bg-slate-100 text-slate-600 border border-slate-200">
                      {item.badge}
                    </span>
                  </div>
                  <div>
                    <h2 className="text-xs font-bold text-slate-900 group-hover:text-slate-700 transition-colors font-mono">
                      {item.label}
                    </h2>
                    <p className="text-xs text-slate-500 mt-1 leading-relaxed">
                      {item.description}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1 text-xs font-mono font-medium text-slate-700 pt-2 border-t border-slate-100">
                  <span>Open Configuration</span>
                  <ArrowRight className="h-3 w-3 group-hover:translate-x-0.5 transition-transform" />
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      {/* RBAC Highlights Banner */}
      <div className="rounded-md bg-slate-50 border border-slate-200 p-4 flex flex-col md:flex-row items-start md:items-center justify-between gap-3 shadow-2xs">
        <div className="flex items-start gap-3">
          <div className="h-9 w-9 rounded-md bg-slate-900 text-white flex items-center justify-center shrink-0">
            <ShieldCheck className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-xs font-bold font-mono text-slate-900 uppercase tracking-wider">
              Role-Based Access Control (RBAC) &amp; Granular Matrix
            </h3>
            <p className="text-xs text-slate-600 mt-0.5 max-w-2xl leading-relaxed">
              System maps platform roles across 12 navigation modules and 22 business capabilities. Inspect user permissions directly or compare live role permissions.
            </p>
          </div>
        </div>
        <Link href="/settings/roles">
          <button
            type="button"
            className="shrink-0 px-3 py-1.5 rounded-md bg-slate-900 text-white text-xs font-mono font-medium hover:bg-slate-800 transition-colors flex items-center gap-1.5"
          >
            <SlidersHorizontal className="h-3.5 w-3.5" />
            Access Matrix
          </button>
        </Link>
      </div>
    </div>
  );
}

