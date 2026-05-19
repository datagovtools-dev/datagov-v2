"use client";

import * as React from "react";
import { useRouter } from "next/navigation";
import { Input } from "@/components/ui/Input";
import { Button } from "@/components/ui/Button";
import { useAuthStore } from "@/store/authStore";

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
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        const detail = data.detail;
        const msg = typeof detail === "string"
          ? detail
          : Array.isArray(detail)
          ? detail.map((e: any) => e.msg ?? JSON.stringify(e)).join(", ")
          : "Login failed";
        throw new Error(msg);
      }
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
    <div className="min-h-screen flex items-center justify-center bg-surface-50 px-4">
      <div className="w-full max-w-sm">
        <div className="flex flex-col items-center mb-8 gap-2">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary-600 text-white font-bold text-lg">
            DG
          </div>
          <h1 className="text-xl font-semibold text-surface-900">AI Governance Tools</h1>
          <p className="text-sm text-surface-500">Sign in to your account</p>
        </div>

        <form onSubmit={handleSubmit} className="card flex flex-col gap-4">
          <Input
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
            autoFocus
            placeholder="you@example.com"
          />
          <Input
            label="Password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            placeholder="••••••••"
          />
          {error && (
            <p className="rounded-md bg-red-50 border border-red-200 px-3 py-2 text-sm text-red-600">
              {error}
            </p>
          )}
          <Button type="submit" loading={loading} className="w-full mt-1">
            Sign In
          </Button>
        </form>
      </div>
    </div>
  );
}
