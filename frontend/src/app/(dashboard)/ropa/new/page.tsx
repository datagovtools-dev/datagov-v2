"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useMutation, useQuery } from "@tanstack/react-query";
import Link from "next/link";
import { ArrowLeft, Database, Plus, X } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { Badge } from "@/components/ui/Badge";
import { toast } from "@/components/ui/Toast";
import { AssetSelectorModal, ProjectOption, SourceTableInfo } from "@/components/ropa/AssetSelectorModal";

export default function NewROPAPage() {
  const router = useRouter();
  const [form, setForm] = useState({
    project_id: "",
    process_name: "",
    purpose: "",
    data_category: "",
    data_subject: "",
    legal_basis: "",
    retention_period: "",
    recipient: "",
    linked_asset_ids: [] as string[],
  });
  const [customAssetInput, setCustomAssetInput] = useState("");
  const [isAssetModalOpen, setIsAssetModalOpen] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const { data: projects = [] } = useQuery<ProjectOption[]>({
    queryKey: ["projects-select"],
    queryFn: () => api.get<{ items: ProjectOption[] }>("/projects?page_size=100").then((r) => r.items),
  });

  const { data: legalBasisOptions } = useQuery<string[]>({
    queryKey: ["legal-basis-options"],
    queryFn: () => api.get<string[]>("/ropa/legal-basis-options"),
  });

  // Query metadata catalogue tables for the selected project
  const { data: projectTables = [] } = useQuery<SourceTableInfo[]>({
    queryKey: ["metadata-tables", form.project_id],
    queryFn: () => form.project_id ? api.get<SourceTableInfo[]>(`/metadata/tables?project_id=${form.project_id}`) : Promise.resolve([]),
    enabled: !!form.project_id,
  });

  const mutation = useMutation({
    mutationFn: (payload: typeof form) => {
      toast.loading("Creating ROPA processing record...", { id: "create-ropa" });
      const body = { ...payload };
      if (!body.recipient) delete (body as Partial<typeof form>).recipient;
      if (!body.linked_asset_ids?.length) delete (body as Partial<typeof form>).linked_asset_ids;
      return api.post<{ id: string }>("/ropa", body);
    },
    onSuccess: (data: { id: string }) => {
      toast.success("ROPA record created successfully!", { id: "create-ropa" });
      router.push(`/ropa/${data.id}`);
    },
    onError: (e: any) => {
      toast.error(e.message || "Failed to create ROPA record", { id: "create-ropa" });
    },
  });

  function set(field: string, value: unknown) {
    setForm((f) => ({ ...f, [field]: value }));
    setErrors((e) => { const n = { ...e }; delete n[field]; return n; });
  }

  function toggleAsset(assetName: string) {
    if (!assetName.trim()) return;
    setForm((f) => {
      const exists = f.linked_asset_ids.includes(assetName);
      const updated = exists
        ? f.linked_asset_ids.filter((a) => a !== assetName)
        : [...f.linked_asset_ids, assetName];
      return { ...f, linked_asset_ids: updated };
    });
  }

  function addCustomAsset() {
    const trimmed = customAssetInput.trim();
    if (!trimmed) {
      // If user clicked "+ Add Asset" with empty input, open the Catalogue Selector Modal!
      setIsAssetModalOpen(true);
      return;
    }
    if (!form.linked_asset_ids.includes(trimmed)) {
      setForm((f) => ({ ...f, linked_asset_ids: [...f.linked_asset_ids, trimmed] }));
      toast.success(`Added asset: ${trimmed}`);
    } else {
      toast.info(`Asset "${trimmed}" is already added.`);
    }
    setCustomAssetInput("");
  }

  function validate() {
    const e: Record<string, string> = {};
    if (!form.project_id) e.project_id = "Required";
    if (!form.process_name.trim()) e.process_name = "Required";
    if (!form.purpose.trim()) e.purpose = "Required";
    if (!form.data_category.trim()) e.data_category = "Required";
    if (!form.data_subject.trim()) e.data_subject = "Required";
    if (!form.legal_basis) e.legal_basis = "Required";
    if (!form.retention_period.trim()) e.retention_period = "Required";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) return;
    mutation.mutate(form);
  }

  return (
    <div className="space-y-4 w-full">
      {/* Header */}
      <div className="flex items-center gap-3 pb-3 border-b border-slate-200">
        <Link
          href="/ropa"
          className="inline-flex items-center justify-center h-8 w-8 rounded-md border border-slate-200 hover:bg-slate-100 shrink-0 text-slate-600"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">New Processing Activity Record (ROPA)</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Document data processing activities under GDPR Article 30 and PDP Law compliance
          </p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Activity Information */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Activity Scope &amp; Business Purpose
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Core processing identity, associated project, and lawful justification</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Project <span className="text-rose-500">*</span>
              </label>
              <Select value={form.project_id} onValueChange={(v) => set("project_id", v)}>
                <SelectTrigger className="h-8 text-xs" error={!!errors.project_id}>
                  <SelectValue placeholder="Select project..." />
                </SelectTrigger>
                <SelectContent>
                  {projects?.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.project_code ? `[${p.project_code}] ` : ""}{p.project_name} {p.customer_name ? `(${p.customer_name})` : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.project_id && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.project_id}</p>
              )}
            </div>

            <Input
              label="Processing Activity Name"
              value={form.process_name}
              onChange={(e) => set("process_name", e.target.value)}
              required
              error={errors.process_name}
              placeholder="e.g. Customer Credit Scoring & Risk Profiling"
              className="h-8 text-xs"
            />

            <div className="md:col-span-2 flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Purpose of Processing <span className="text-rose-500">*</span>
              </label>
              <textarea
                value={form.purpose}
                onChange={(e) => set("purpose", e.target.value)}
                rows={3}
                className={`input-base resize-none w-full text-xs font-sans${
                  errors.purpose ? " border-rose-300 bg-rose-50/40 text-rose-900" : ""
                }`}
                placeholder="Explain the lawful business necessity, operational objectives, and technical scope for processing this data..."
              />
              {errors.purpose && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.purpose}</p>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Data Details */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Data Categories &amp; Legal Framework
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">Data subjects, lawful bases, and retention policies</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
            <Input
              label="Data Category"
              value={form.data_category}
              onChange={(e) => set("data_category", e.target.value)}
              required
              error={errors.data_category}
              placeholder="e.g. Personal Identity, Financial, Behavioral Telemetry"
              className="h-8 text-xs"
            />
            <Input
              label="Data Subject Population"
              value={form.data_subject}
              onChange={(e) => set("data_subject", e.target.value)}
              required
              error={errors.data_subject}
              placeholder="e.g. Active Retail Banking Customers, Employees"
              className="h-8 text-xs"
            />
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-slate-700">
                Legal Basis <span className="text-rose-500">*</span>
              </label>
              <Select value={form.legal_basis} onValueChange={(v) => set("legal_basis", v)}>
                <SelectTrigger className="h-8 text-xs" error={!!errors.legal_basis}>
                  <SelectValue placeholder="Select legal basis..." />
                </SelectTrigger>
                <SelectContent>
                  {legalBasisOptions?.map((b) => (
                    <SelectItem key={b} value={b}>
                      {b}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {errors.legal_basis && (
                <p className="text-[11px] font-medium text-rose-600 font-mono">{errors.legal_basis}</p>
              )}
            </div>
            <Input
              label="Retention Period"
              value={form.retention_period}
              onChange={(e) => set("retention_period", e.target.value)}
              required
              error={errors.retention_period}
              placeholder="e.g. 5 Years from Account Termination"
              hint="Start with a duration (e.g. 5 Years, 18 Months). Once approved, the project's uploaded files are kept until the project end date + this period instead of 30 days."
              className="h-8 text-xs font-mono"
            />
          </CardContent>
        </Card>

        {/* Recipients & Linked Assets */}
        <Card>
          <CardHeader className="pb-3 border-b border-slate-100">
            <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Downstream Recipients &amp; Linked Assets
            </CardTitle>
            <CardDescription className="text-xs text-slate-500">External recipient organizations and linked data catalogue tables</CardDescription>
          </CardHeader>
          <CardContent className="pt-4 space-y-4">
            <Input
              label="Recipient Organizations / Third Parties (Optional)"
              value={form.recipient}
              onChange={(e) => set("recipient", e.target.value)}
              placeholder="e.g. Third-party auditors, External Credit Rating Agency, Cloud Vendor"
              className="h-8 text-xs"
            />

            <div className="space-y-2">
              <label className="text-xs font-semibold text-slate-700 flex items-center gap-1.5">
                <Database className="h-3.5 w-3.5 text-slate-500" />
                Linked Data Assets / Tables
              </label>

              {/* Display project metadata tables if available */}
              {projectTables && projectTables.length > 0 && (
                <div className="p-3 bg-slate-50 rounded-md border border-slate-200 space-y-1.5">
                  <p className="text-[11px] text-slate-600 font-medium">Available Catalogue Tables for Selected Project:</p>
                  <div className="flex flex-wrap gap-1.5 max-h-36 overflow-y-auto pt-1">
                    {projectTables.map((tbl) => {
                      const isSelected = form.linked_asset_ids.includes(tbl.table_name);
                      return (
                        <button
                          key={tbl.table_name}
                          type="button"
                          onClick={() => toggleAsset(tbl.table_name)}
                          className={`text-xs px-2 py-1 rounded border transition-colors flex items-center gap-1 font-mono ${
                            isSelected
                              ? "bg-blue-600 text-white border-blue-600 shadow-2xs"
                              : "bg-white text-slate-700 border-slate-200 hover:bg-slate-100"
                          }`}
                        >
                          {tbl.table_name}
                          {isSelected ? <X className="h-3 w-3" /> : <Plus className="h-3 w-3 text-slate-400" />}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Custom table/asset name input & Catalog Browser buttons */}
              <div className="flex flex-col sm:flex-row gap-2">
                <div className="relative flex-1">
                  <Input
                    value={customAssetInput}
                    onChange={(e) => setCustomAssetInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        addCustomAsset();
                      }
                    }}
                    placeholder="Type custom asset name (e.g. customer_crm_table) and press Add..."
                    className="h-8 text-xs font-mono w-full"
                  />
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <Button
                    type="button"
                    variant="default"
                    size="sm"
                    onClick={addCustomAsset}
                    className="h-8 text-xs font-medium"
                  >
                    <Plus className="h-3.5 w-3.5 mr-1" /> Add Asset
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setIsAssetModalOpen(true)}
                    className="h-8 text-xs font-medium text-blue-700 border-blue-200 bg-blue-50/60 hover:bg-blue-100"
                  >
                    <Database className="h-3.5 w-3.5 mr-1.5 text-blue-600" /> Browse Catalog
                  </Button>
                </div>
              </div>

              {/* Selected Assets Display */}
              {form.linked_asset_ids.length > 0 ? (
                <div className="space-y-1.5 pt-1">
                  <div className="flex items-center justify-between text-[11px] text-slate-500 font-mono">
                    <span>{form.linked_asset_ids.length} Linked Asset{form.linked_asset_ids.length === 1 ? "" : "s"}:</span>
                    <button
                      type="button"
                      onClick={() => setForm((f) => ({ ...f, linked_asset_ids: [] }))}
                      className="text-rose-600 hover:text-rose-800 text-[11px] font-sans"
                    >
                      Clear All Assets
                    </button>
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    {form.linked_asset_ids.map((asset) => (
                      <Badge
                        key={asset}
                        variant="info"
                        className="text-xs px-2.5 py-1 font-mono flex items-center gap-1.5 bg-blue-50 text-blue-700 border border-blue-200"
                      >
                        {asset}
                        <button
                          type="button"
                          onClick={() => toggleAsset(asset)}
                          className="hover:text-blue-900 rounded-full"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </Badge>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="p-3 bg-slate-50 border border-dashed border-slate-200 rounded-md text-center">
                  <p className="text-xs text-slate-500 font-sans">
                    No data assets linked yet. Use{" "}
                    <button
                      type="button"
                      onClick={() => setIsAssetModalOpen(true)}
                      className="text-blue-600 font-medium underline"
                    >
                      Browse Catalog
                    </button>{" "}
                    or type an asset name above.
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {mutation.isError && (
          <div className="rounded-md bg-rose-50 border border-rose-200 p-3 text-xs font-mono text-rose-700">
            Failed to create ROPA record. Please verify required fields.
          </div>
        )}

        <div className="flex items-center justify-end gap-2.5 pt-1">
          <Button type="button" variant="outline" size="sm" className="h-8 text-xs" onClick={() => router.back()}>
            Cancel
          </Button>
          <Button type="submit" size="sm" loading={mutation.isPending} className="h-8 text-xs font-medium">
            Create ROPA Record
          </Button>
        </div>
      </form>

      {/* Asset Selector Catalog Modal */}
      <AssetSelectorModal
        isOpen={isAssetModalOpen}
        onClose={() => setIsAssetModalOpen(false)}
        selectedAssets={form.linked_asset_ids}
        onSave={(assets) => {
          setForm((f) => ({ ...f, linked_asset_ids: assets }));
          toast.success(`Updated linked assets (${assets.length} selected)`);
        }}
        initialProjectId={form.project_id}
        projects={projects}
      />
    </div>
  );
}
