"use client";

import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Bell, Check, Mail, Shield } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";

interface Pref { module: string; in_app: boolean; email: boolean }

const ALL_MODULES = ["dsr", "dpia", "ropa", "bapd", "dq", "metadata", "auth", "rbac"];

const MODULE_LABELS: Record<string, { label: string; desc: string }> = {
  dsr: { label: "Data Sharing (DSR)", desc: "New sharing requests, review requests, and approvals" },
  dpia: { label: "Privacy Assessments (DPIA)", desc: "Risk matrix submissions and DPO sign-offs" },
  ropa: { label: "ROPA Records", desc: "Article 30 processing activity updates" },
  bapd: { label: "Data Extermination (BAPD)", desc: "Disposal requests and dual approvals" },
  dq: { label: "Data Quality Inspections", desc: "Anomaly alerts, threshold violations, and test runs" },
  metadata: { label: "Metadata & Lineage", desc: "Catalog syncs, AI definition changes, and schema updates" },
  auth: { label: "Authentication & Security", desc: "Login alerts, password changes, and sessions" },
  rbac: { label: "Role & Permission Changes", desc: "User provisioning and role assignments" },
};

export default function NotificationPreferencesPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery<Pref[]>({
    queryKey: ["notif-prefs"],
    queryFn: () => api.get<Pref[]>("/notifications/preferences"),
  });

  const [prefs, setPrefs] = useState<Record<string, Pref>>({});
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    if (!data) return;
    const map: Record<string, Pref> = {};
    ALL_MODULES.forEach((m) => {
      const found = data.find((p) => p.module === m);
      map[m] = found ?? { module: m, in_app: true, email: true };
    });
    setPrefs(map);
  }, [data]);

  const saveMutation = useMutation({
    mutationFn: () => api.put("/notifications/preferences", Object.values(prefs)),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["notif-prefs"] });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    },
  });

  function toggle(module: string, field: "in_app" | "email") {
    setPrefs((p) => ({
      ...p,
      [module]: { ...p[module], [field]: !p[module][field] },
    }));
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between pb-3 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">Notification Preferences</h1>
          <p className="text-xs text-slate-500 font-mono mt-0.5">
            Configure per-module in-app telemetry alerts and email notification channels
          </p>
        </div>
        <Badge variant="success" className="text-[10px] font-mono">
          Channels Active
        </Badge>
      </div>

      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
            Delivery Channels by Governance Module
          </CardTitle>
          <CardDescription className="text-xs text-slate-500">
            Toggle in-app notification drawer alerts and automated email dispatches
          </CardDescription>
        </CardHeader>
        <CardContent className="p-0">
          <div className="overflow-x-auto">
            <table className="w-full divide-y divide-slate-200 text-xs">
              <thead className="bg-slate-50/70">
                <tr>
                  <th className="px-4 py-2 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono">
                    Governance Module
                  </th>
                  <th className="px-4 py-2 text-center text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono w-28">
                    In-App Alert
                  </th>
                  <th className="px-4 py-2 text-center text-[10px] font-semibold text-slate-500 uppercase tracking-wider font-mono w-28">
                    Email Digest
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {isLoading ? (
                  <tr>
                    <td colSpan={3} className="px-4 py-8 text-center text-xs text-slate-400 font-mono">
                      Loading preferences...
                    </td>
                  </tr>
                ) : (
                  ALL_MODULES.map((m) => {
                    const info = MODULE_LABELS[m] ?? { label: m.toUpperCase(), desc: "" };
                    const p = prefs[m] ?? { in_app: true, email: true };

                    return (
                      <tr key={m} className="hover:bg-slate-50/60 transition-colors">
                        <td className="px-4 py-2.5">
                          <div className="font-semibold text-slate-900 font-mono text-xs">{info.label}</div>
                          <div className="text-[11px] text-slate-400 font-normal">{info.desc}</div>
                        </td>
                        <td className="px-4 py-2.5 text-center">
                          <button
                            type="button"
                            onClick={() => toggle(m, "in_app")}
                            className={`relative inline-flex h-4.5 w-8 items-center rounded-full transition-colors ${
                              p.in_app ? "bg-slate-900" : "bg-slate-300"
                            }`}
                            aria-label={`Toggle in-app for ${m}`}
                          >
                            <span
                              className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-2xs transition-transform ${
                                p.in_app ? "translate-x-4" : "translate-x-0.5"
                              }`}
                            />
                          </button>
                        </td>
                        <td className="px-4 py-2.5 text-center">
                          <button
                            type="button"
                            onClick={() => toggle(m, "email")}
                            className={`relative inline-flex h-4.5 w-8 items-center rounded-full transition-colors ${
                              p.email ? "bg-slate-900" : "bg-slate-300"
                            }`}
                            aria-label={`Toggle email for ${m}`}
                          >
                            <span
                              className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-2xs transition-transform ${
                                p.email ? "translate-x-4" : "translate-x-0.5"
                              }`}
                            />
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-100 bg-slate-50/30">
            {saved ? (
              <span className="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-700 font-mono">
                <Check className="h-3.5 w-3.5" /> Preferences saved successfully
              </span>
            ) : (
              <span className="text-xs text-slate-400 font-mono">Settings apply across your account</span>
            )}
            <Button
              size="sm"
              onClick={() => saveMutation.mutate()}
              loading={saveMutation.isPending}
              className="h-8 text-xs font-medium"
            >
              Save Preferences
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
