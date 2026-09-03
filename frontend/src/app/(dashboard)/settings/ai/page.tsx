"use client";

import { useEffect, useState } from "react";
import { CheckCircle2, KeyRound, RefreshCw, Save, XCircle } from "lucide-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { toast } from "@/components/ui/Toast";

interface AISettings {
  id: string | null;
  provider: string;
  mode: string;
  enabled: boolean;
  base_url: string;
  model_name: string;
  timeout_seconds: number;
  batch_size: number;
  api_key_configured: boolean;
  api_key_last4: string | null;
  updated_at: string | null;
  updated_by: string | null;
}

interface TestResult {
  ok: boolean;
  message: string;
  provider: string;
  model_name: string;
}

const DEFAULT_FORM = {
  provider: "ollama",
  mode: "cloud",
  enabled: false,
  base_url: "https://ollama.com",
  model_name: "gpt-oss:120b",
  timeout_seconds: 60,
  batch_size: 5,
};

export default function AISettingsPage() {
  const qc = useQueryClient();
  const [form, setForm] = useState(DEFAULT_FORM);
  const [apiKey, setApiKey] = useState("");
  const [clearKey, setClearKey] = useState(false);
  const [testResult, setTestResult] = useState<TestResult | null>(null);

  const { data, isLoading } = useQuery<AISettings>({
    queryKey: ["ai-settings"],
    queryFn: () => api.get<AISettings>("/settings/ai"),
  });

  useEffect(() => {
    if (!data) return;
    setForm({
      provider: data.provider,
      mode: data.mode,
      enabled: data.enabled,
      base_url: data.base_url,
      model_name: data.model_name,
      timeout_seconds: data.timeout_seconds,
      batch_size: data.batch_size,
    });
  }, [data]);

  const saveMutation = useMutation({
    mutationFn: () => {
      toast.loading("Saving AI Provider configuration...", { id: "ai-settings" });
      return api.put<AISettings>("/settings/ai", {
        ...form,
        timeout_seconds: Number(form.timeout_seconds),
        batch_size: Number(form.batch_size),
        api_key: apiKey.trim() || null,
        clear_api_key: clearKey,
      });
    },
    onSuccess: () => {
      setApiKey("");
      setClearKey(false);
      qc.invalidateQueries({ queryKey: ["ai-settings"] });
      qc.invalidateQueries({ queryKey: ["ai-settings-status"] });
      toast.success("AI Configuration updated successfully!", { id: "ai-settings" });
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to save AI configuration", { id: "ai-settings" });
    },
  });

  const testMutation = useMutation({
    mutationFn: () => {
      toast.loading("Testing Ollama AI connection...", { id: "ai-test" });
      return api.post<TestResult>("/settings/ai/test", {
        ...form,
        timeout_seconds: Number(form.timeout_seconds),
        api_key: apiKey.trim() || null,
      });
    },
    onSuccess: (result) => {
      setTestResult(result);
      if (result.ok) {
        toast.success("AI Provider connection verified successfully!", { id: "ai-test" });
      } else {
        toast.error(result.message || "AI Provider test failed", { id: "ai-test" });
      }
    },
    onError: (e: any) => {
      setTestResult({ ok: false, message: e.message, provider: form.provider, model_name: form.model_name });
      toast.error(e.message || "AI Provider test failed", { id: "ai-test" });
    },
  });

  const configured = data?.api_key_configured && !clearKey;
  const statusReady = form.enabled && (configured || !!apiKey.trim());

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between pb-3 border-b border-slate-200">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-bold uppercase font-mono tracking-wider text-slate-500">
              Intelligence Engine Configuration
            </span>
          </div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900 mt-0.5">AI Setup &amp; LLM Provider</h1>
          <p className="text-xs text-slate-500 font-mono mt-0.5">
            Configure the local or cloud Ollama provider used for Metadata definitions and DQ AI rules
          </p>
        </div>
        <Badge variant={statusReady ? "success" : "warning"} className="text-[10px] font-mono">
          {statusReady ? "AI Ready" : "Needs setup"}
        </Badge>
      </div>

      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <div>
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Ollama Provider Configuration</CardTitle>
            <CardDescription className="text-xs text-slate-500">
              Generation runs locally or via cloud endpoint; credentials are securely encrypted.
            </CardDescription>
          </div>
        </CardHeader>
        <CardContent className="space-y-4 pt-4">
          {isLoading ? (
            <div className="text-xs text-slate-400 py-6 text-center font-mono">Loading settings...</div>
          ) : (
            <>
              <div className="flex items-center justify-between rounded-md border border-slate-200 bg-slate-50/50 p-3">
                <div>
                  <div className="text-xs font-semibold text-slate-900">Enable AI generation</div>
                  <div className="text-[11px] text-slate-500">
                    Powers automatic Metadata business definitions and Data Quality consistency pattern matching
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setForm((f) => ({ ...f, enabled: !f.enabled }))}
                  className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${
                    form.enabled ? "bg-slate-900" : "bg-slate-300"
                  }`}
                  aria-label="Toggle AI generation"
                >
                  <span
                    className={`inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-2xs transition-transform ${
                      form.enabled ? "translate-x-4.5" : "translate-x-0.5"
                    }`}
                  />
                </button>
              </div>

              <div className="grid gap-3.5 md:grid-cols-2">
                <Input label="Provider" value="Ollama" disabled className="h-8 text-xs font-mono" />
                <Input label="Mode" value={form.mode || "Local / Host"} disabled className="h-8 text-xs font-mono" />
                <Input
                  label="Base URL"
                  value={form.base_url}
                  onChange={(e) => setForm((f) => ({ ...f, base_url: e.target.value }))}
                  placeholder="https://ollama.com"
                  className="h-8 text-xs font-mono"
                />
                <Input
                  label="Model"
                  value={form.model_name}
                  onChange={(e) => setForm((f) => ({ ...f, model_name: e.target.value }))}
                  placeholder="gpt-oss:120b"
                  className="h-8 text-xs font-mono"
                />
                <Input
                  label="Timeout"
                  type="number"
                  min={5}
                  max={180}
                  value={form.timeout_seconds}
                  onChange={(e) => setForm((f) => ({ ...f, timeout_seconds: Number(e.target.value) }))}
                  hint="Seconds"
                  className="h-8 text-xs font-mono"
                />
                <Input
                  label="Batch size"
                  type="number"
                  min={1}
                  max={25}
                  value={form.batch_size}
                  onChange={(e) => setForm((f) => ({ ...f, batch_size: Number(e.target.value) }))}
                  hint="Definitions per bulk request"
                  className="h-8 text-xs font-mono"
                />
              </div>

              <div className="rounded-md border border-slate-200 p-3.5 space-y-2.5">
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-1.5 text-xs font-semibold text-slate-800 font-mono">
                    <KeyRound className="h-3.5 w-3.5 text-slate-700" />
                    API Key
                  </div>
                  {data?.api_key_configured && !clearKey ? (
                    <Badge variant="success" className="text-[10px] font-mono">Saved ending {data.api_key_last4}</Badge>
                  ) : (
                    <Badge variant="warning" className="text-[10px] font-mono">Not saved</Badge>
                  )}
                </div>
                <Input
                  type="password"
                  value={apiKey}
                  onChange={(e) => {
                    setApiKey(e.target.value);
                    if (e.target.value) setClearKey(false);
                  }}
                  placeholder={data?.api_key_configured ? "Leave blank to keep saved key" : "Paste Ollama Cloud API key"}
                  className="h-8 text-xs font-mono"
                />
                {data?.api_key_configured && (
                  <label className="flex items-center gap-2 text-xs text-slate-600 font-mono">
                    <input
                      type="checkbox"
                      checked={clearKey}
                      onChange={(e) => {
                        setClearKey(e.target.checked);
                        if (e.target.checked) setApiKey("");
                      }}
                      className="rounded border-slate-300"
                    />
                    Clear saved API key
                  </label>
                )}
              </div>

              {testResult && (
                <div className={`flex items-center gap-2 rounded-md border px-3 py-2 text-xs font-mono ${testResult.ok ? "border-emerald-200 bg-emerald-50 text-emerald-800" : "border-rose-200 bg-rose-50 text-rose-800"}`}>
                  {testResult.ok ? <CheckCircle2 className="h-3.5 w-3.5 shrink-0" /> : <XCircle className="h-3.5 w-3.5 shrink-0" />}
                  {testResult.message}
                </div>
              )}

              {saveMutation.error && (
                <div className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700 font-mono">
                  {(saveMutation.error as Error).message}
                </div>
              )}

              <div className="flex flex-wrap items-center gap-2 pt-1">
                <Button
                  variant="outline"
                  size="sm"
                  className="h-8 text-xs font-medium"
                  onClick={() => testMutation.mutate()}
                  loading={testMutation.isPending}
                >
                  <RefreshCw className="h-3.5 w-3.5 mr-1" /> Test Connection
                </Button>
                <Button
                  size="sm"
                  className="h-8 text-xs font-medium"
                  onClick={() => saveMutation.mutate()}
                  loading={saveMutation.isPending}
                >
                  <Save className="h-3.5 w-3.5 mr-1" /> Save AI Setup
                </Button>
                {saveMutation.isSuccess && <span className="text-xs text-emerald-700 font-mono">Saved</span>}
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
