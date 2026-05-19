"use client";

import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";

interface Pref { module: string; in_app: boolean; email: boolean }

const ALL_MODULES = ["dsr", "dpia", "ropa", "bapd", "dq", "metadata", "auth", "rbac"];

export default function NotificationPreferencesPage() {
  const qc = useQueryClient();
  const { data, isLoading } = useQuery<Pref[]>({
    queryKey: ["notif-prefs"],
    queryFn: () => api.get<Pref[]>("/notifications/preferences"),
  });

  const [prefs, setPrefs] = useState<Record<string, Pref>>({});

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
    onSuccess: () => qc.invalidateQueries({ queryKey: ["notif-prefs"] }),
  });

  function toggle(module: string, field: "in_app" | "email") {
    setPrefs((p) => ({
      ...p,
      [module]: { ...p[module], [field]: !p[module][field] },
    }));
  }

  return (
    <div className="p-6 max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Notification Preferences</h1>
        <p className="text-sm text-gray-500 mt-1">Configure per-module in-app and email notification settings</p>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-100 text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-5 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Module</th>
              <th className="px-5 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">In-App</th>
              <th className="px-5 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50">
            {isLoading ? (
              <tr><td colSpan={3} className="px-5 py-8 text-center text-gray-400">Loading…</td></tr>
            ) : ALL_MODULES.map((mod) => (
              <tr key={mod} className="hover:bg-gray-50">
                <td className="px-5 py-3 font-medium text-gray-800 capitalize">{mod.toUpperCase()}</td>
                <td className="px-5 py-3 text-center">
                  <button onClick={() => toggle(mod, "in_app")}
                    className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none ${prefs[mod]?.in_app ? "bg-blue-600" : "bg-gray-200"}`}>
                    <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${prefs[mod]?.in_app ? "translate-x-4" : "translate-x-0.5"}`} />
                  </button>
                </td>
                <td className="px-5 py-3 text-center">
                  <button onClick={() => toggle(mod, "email")}
                    className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none ${prefs[mod]?.email ? "bg-blue-600" : "bg-gray-200"}`}>
                    <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${prefs[mod]?.email ? "translate-x-4" : "translate-x-0.5"}`} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex gap-3">
        <Button onClick={() => saveMutation.mutate()} disabled={saveMutation.isPending}>
          {saveMutation.isPending ? "Saving…" : "Save Preferences"}
        </Button>
        {saveMutation.isSuccess && <span className="text-sm text-green-600 self-center">Saved!</span>}
      </div>
    </div>
  );
}
