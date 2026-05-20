"use client";

import { useEffect, useState } from "react";
import { CheckCircle2, KeyRound, RefreshCw, Save, XCircle } from "lucide-react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";

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
    mutationFn: () => api.put<AISettings>("/settings/ai", {
      ...form,
      timeout_seconds: Number(form.timeout_seconds),
      batch_size: Number(form.batch_size),
      api_key: apiKey.trim() || null,
      clear_api_key: clearKey,
    }),
    onSuccess: () => {
      setApiKey("");
      setClearKey(false);
      qc.invalidateQueries({ queryKey: ["ai-settings"] });
      qc.invalidateQueries({ queryKey: ["ai-settings-status"] });
    },
  });

  const testMutation = useMutation({
    mutationFn: () => api.post<TestResult>("/settings/ai/test", {
      ...form,
      timeout_seconds: Number(form.timeout_seconds),
      api_key: apiKey.trim() || null,
    }),
    onSuccess: (result) => setTestResult(result),
    onError: (e: any) => setTestResult({ ok: false, message: e.message, provider: form.provider, model_name: form.model_name }),
  });

  const configured = data?.api_key_configured && !clearKey;
  const statusReady = form.enabled && (configured || !!apiKey.trim());

  return (
    <div className="max-w-4xl space-y-5">
      <div className="page-header">
        <div>
          <h1>AI Setup</h1>
          <p className="text-sm text-surface-500 mt-0.5">Configure the provider used for metadata business definitions</p>
        </div>
        <Badge variant={statusReady ? "success" : "warning"}>
          {statusReady ? "Ready" : "Needs setup"}
        </Badge>
      </div>

      <Card>
        <CardHeader>
          <div>
            <CardTitle>Ollama Cloud</CardTitle>
            <CardDescription>Generation runs through the backend; the API key is never sent back to the browser.</CardDescription>
          </div>
        </CardHeader>
        <CardContent className="space-y-5">
          {isLoading ? (
            <div className="text-sm text-surface-400">Loading...</div>
          ) : (
            <>
              <div className="flex items-center justify-between rounded-md border border-surface-200 px-3 py-2">
                <div>
                  <div className="text-sm font-medium text-surface-800">AI generation</div>
                  <div className="text-xs text-surface-500">Controls the regenerate buttons in Metadata</div>
                </div>
                <button
                  type="button"
                  onClick={() => setForm((f) => ({ ...f, enabled: !f.enabled }))}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${form.enabled ? "bg-primary-600" : "bg-surface-200"}`}
                  aria-label="Toggle AI generation"
                >
                  <span className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform ${form.enabled ? "translate-x-5" : "translate-x-0.5"}`} />
                </button>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <Input label="Provider" value="Ollama" disabled />
                <Input label="Mode" value="Cloud" disabled />
                <Input
                  label="Base URL"
                  value={form.base_url}
                  onChange={(e) => setForm((f) => ({ ...f, base_url: e.target.value }))}
                  placeholder="https://ollama.com"
                />
                <Input
                  label="Model"
                  value={form.model_name}
                  onChange={(e) => setForm((f) => ({ ...f, model_name: e.target.value }))}
                  placeholder="gpt-oss:120b"
                />
                <Input
                  label="Timeout"
                  type="number"
                  min={5}
                  max={180}
                  value={form.timeout_seconds}
                  onChange={(e) => setForm((f) => ({ ...f, timeout_seconds: Number(e.target.value) }))}
                  hint="Seconds"
                />
                <Input
                  label="Batch size"
                  type="number"
                  min={1}
                  max={25}
                  value={form.batch_size}
                  onChange={(e) => setForm((f) => ({ ...f, batch_size: Number(e.target.value) }))}
                  hint="Definitions per bulk request"
                />
              </div>

              <div className="rounded-md border border-surface-200 p-4 space-y-3">
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2 text-sm font-medium text-surface-800">
                    <KeyRound className="h-4 w-4 text-primary-600" />
                    API key
                  </div>
                  {data?.api_key_configured && !clearKey ? (
                    <Badge variant="success">Saved ending {data.api_key_last4}</Badge>
                  ) : (
                    <Badge variant="warning">Not saved</Badge>
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
                />
                {data?.api_key_configured && (
                  <label className="flex items-center gap-2 text-sm text-surface-600">
                    <input
                      type="checkbox"
                      checked={clearKey}
                      onChange={(e) => {
                        setClearKey(e.target.checked);
                        if (e.target.checked) setApiKey("");
                      }}
                    />
                    Clear saved API key
                  </label>
                )}
              </div>

              {testResult && (
                <div className={`flex items-center gap-2 rounded-md border px-3 py-2 text-sm ${testResult.ok ? "border-green-200 bg-green-50 text-green-700" : "border-red-200 bg-red-50 text-red-700"}`}>
                  {testResult.ok ? <CheckCircle2 className="h-4 w-4" /> : <XCircle className="h-4 w-4" />}
                  {testResult.message}
                </div>
              )}

              {saveMutation.error && (
                <div className="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                  {(saveMutation.error as Error).message}
                </div>
              )}

              <div className="flex flex-wrap gap-2">
                <Button
                  variant="outline"
                  onClick={() => testMutation.mutate()}
                  loading={testMutation.isPending}
                >
                  <RefreshCw className="h-4 w-4" /> Test Connection
                </Button>
                <Button
                  onClick={() => saveMutation.mutate()}
                  loading={saveMutation.isPending}
                >
                  <Save className="h-4 w-4" /> Save AI Setup
                </Button>
                {saveMutation.isSuccess && <span className="self-center text-sm text-green-600">Saved</span>}
              </div>
            </>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
