"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { ShieldCheck, Sparkles, CheckCircle2, Lock, ArrowRight } from "lucide-react";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import { useAuthStore } from "@/store/authStore";
import { errorDetail } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const { setAuth } = useAuthStore();
  const [email, setEmail] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState<string | null>(null);
  const [loading, setLoading] = React.useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await fetch("/api/v1/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) throw new Error(await errorDetail(res));
      const { access_token } = await res.json();

      const meRes = await fetch("/api/v1/auth/me", {
        headers: { Authorization: `Bearer ${access_token}` },
      });
      const user = await meRes.json();
      setAuth(user, access_token);
      router.replace("/dashboard");
    } catch (err: any) {
      setError(err.message ?? "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-slate-50">
      <div className="w-full max-w-sm space-y-4">
        {/* Brand Header */}
        <div className="flex flex-col items-center text-center">
          <div className="flex h-9 w-9 items-center justify-center rounded-md bg-slate-900 text-white font-mono font-bold text-sm mb-3">
            DG
          </div>
          <h1 className="text-xl font-bold tracking-tight text-slate-900">
            Data Governance Control Plane
          </h1>
          <p className="text-xs text-slate-500 font-mono mt-0.5">
            Enterprise Data Asset Discovery, Metadata &amp; Quality Assurance
          </p>
        </div>

        {/* Login Card */}
        <div className="rounded-md border border-slate-200 bg-white p-6 shadow-2xs">
          <div className="flex items-center justify-between pb-3 mb-4 border-b border-slate-100">
            <span className="text-xs font-semibold font-mono uppercase tracking-wider text-slate-900 flex items-center gap-1.5">
              <Lock className="h-3.5 w-3.5 text-slate-700" /> Secure Sign In
            </span>
            <span className="text-[10px] font-mono text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded-md font-semibold border border-emerald-200 flex items-center gap-1">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-600 animate-pulse" />
              Operational
            </span>
          </div>

          <form onSubmit={handleSubmit} className="space-y-3.5">
            <Input
              label="Enterprise Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoFocus
              placeholder="admin@governance.local"
              className="h-8.5 text-xs font-mono"
            />
            <Input
              label="Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="••••••••"
              className="h-8.5 text-xs font-mono"
            />

            {error && (
              <div className="rounded-md bg-rose-50 border border-rose-200 px-3 py-2 text-xs font-mono text-rose-700 leading-relaxed">
                {error}
              </div>
            )}

            <Button type="submit" loading={loading} className="w-full h-8.5 mt-2 font-semibold text-xs">
              Sign In <ArrowRight className="h-3.5 w-3.5 ml-1" />
            </Button>
          </form>
        </div>

        {/* Security & System Trust Footnote */}
        <div className="flex items-center justify-center gap-3 text-[11px] text-slate-400 font-mono">
          <span className="flex items-center gap-1">
            <ShieldCheck className="h-3.5 w-3.5 text-slate-600" /> 256-bit TLS Encrypted
          </span>
          <span>•</span>
          <span>Control Plane v2.0</span>
        </div>
      </div>
    </div>
  );
}
