"use client";

import * as React from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Plus, Search, ChevronLeft, ChevronRight } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { formatDate } from "@/lib/utils";

interface ProjectItem {
  id: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
  project_year: number;
  project_category: string;
  is_monetized: boolean;
  created_at: string;
}
interface PaginatedProjects {
  items: ProjectItem[];
  total: number;
  page: number;
  page_size: number;
  pages: number;
}
interface Filters {
  years: number[];
  categories: string[];
  clients: string[];
}

export default function ProjectsPage() {
  const [search, setSearch] = React.useState("");
  const [client, setClient] = React.useState("");
  const [category, setCategory] = React.useState("");
  const [year, setYear] = React.useState("");
  const [monetized, setMonetized] = React.useState("");
  const [page, setPage] = React.useState(1);

  const { data: filters } = useQuery<Filters>({
    queryKey: ["project-filters"],
    queryFn: () => api.get<Filters>("/projects/filters"),
  });

  const params = new URLSearchParams({
    ...(search ? { search } : {}),
    ...(year ? { year } : {}),
    ...(category ? { category } : {}),
    ...(client ? { client } : {}),
    ...(monetized ? { is_monetized: monetized } : {}),
    page: String(page),
    page_size: "20",
  });

  const { data, isLoading } = useQuery<PaginatedProjects>({
    queryKey: ["projects", search, year, category, client, monetized, page],
    queryFn: () => api.get<PaginatedProjects>(`/projects?${params}`),
  });

  function handleSearch(v: string) {
    setSearch(v);
    setPage(1);
  }
  function handleClient(v: string) {
    setClient(v === "all" ? "" : v);
    setPage(1);
  }
  function handleCategory(v: string) {
    setCategory(v === "all" ? "" : v);
    setPage(1);
  }
  function handleYear(v: string) {
    setYear(v === "all" ? "" : v);
    setPage(1);
  }
  function handleMonetized(v: string) {
    setMonetized(v === "all" ? "" : v);
    setPage(1);
  }

  return (
    <div className="space-y-4">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3.5 border-b border-slate-200">
        <div>
          <h1 className="text-lg sm:text-xl font-bold tracking-tight text-slate-900">
            Data Assets Catalog
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Registered enterprise data initiatives
            {data ? ` · ${data.total} registered asset${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
        <Link href="/projects/new">
          <Button size="sm" className="font-medium">
            <Plus className="h-3.5 w-3.5 mr-1" /> New Data Asset
          </Button>
        </Link>
      </div>

      {/* Filter Toolbar */}
      <div className="flex flex-wrap items-center gap-2.5 p-2.5 rounded-md border border-slate-200 bg-white">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400 pointer-events-none" />
          <input
            className="input-base pl-8 h-8 text-xs"
            placeholder="Search name, client, code..."
            value={search}
            onChange={(e) => handleSearch(e.target.value)}
          />
        </div>
        <Select value={client || "all"} onValueChange={handleClient}>
          <SelectTrigger className="w-40 h-8 text-xs">
            <SelectValue placeholder="All Clients" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Clients</SelectItem>
            {(filters?.clients ?? []).map((c: string) => (
              <SelectItem key={c} value={c}>
                {c}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={category || "all"} onValueChange={handleCategory}>
          <SelectTrigger className="w-36 h-8 text-xs">
            <SelectValue placeholder="All Categories" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            {(filters?.categories ?? []).map((c) => (
              <SelectItem key={c} value={c}>
                {c}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={year || "all"} onValueChange={handleYear}>
          <SelectTrigger className="w-28 h-8 text-xs">
            <SelectValue placeholder="All Years" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Years</SelectItem>
            {(filters?.years ?? []).map((y: number) => (
              <SelectItem key={y} value={String(y)}>
                {y}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={monetized || "all"} onValueChange={handleMonetized}>
          <SelectTrigger className="w-32 h-8 text-xs">
            <SelectValue placeholder="Monetization" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="true">Monetized</SelectItem>
            <SelectItem value="false">Internal</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Asset Table */}
      <div className="rounded-md border border-slate-200 bg-white overflow-hidden shadow-2xs">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Asset Code</TableHead>
              <TableHead>Asset / Project Name</TableHead>
              <TableHead>Client / Domain</TableHead>
              <TableHead>Category</TableHead>
              <TableHead>Year</TableHead>
              <TableHead>Monetized</TableHead>
              <TableHead>Created</TableHead>
              <TableHead className="w-20 text-right">Action</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-10 text-xs text-slate-400 font-mono">
                  Loading assets inventory...
                </TableCell>
              </TableRow>
            ) : data?.items.length === 0 ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-10 text-xs text-slate-400 font-mono">
                  No data governance assets found.
                </TableCell>
              </TableRow>
            ) : (
              data?.items.map((p) => (
                <TableRow key={p.id}>
                  <TableCell className="font-mono text-xs font-semibold text-slate-900">
                    {p.project_code ?? <span className="text-slate-400">—</span>}
                  </TableCell>
                  <TableCell className="max-w-[240px] truncate font-medium text-slate-900" title={p.project_name}>
                    {p.project_name}
                  </TableCell>
                  <TableCell className="max-w-[160px] truncate text-slate-600" title={p.customer_name}>
                    {p.customer_name}
                  </TableCell>
                  <TableCell>
                    <Badge variant="default" className="text-[10px]">
                      {p.project_category}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-slate-600 tabular-nums font-mono">{p.project_year}</TableCell>
                  <TableCell>
                    <Badge variant={p.is_monetized ? "success" : "neutral"} className="text-[10px]">
                      {p.is_monetized ? "Monetized" : "Internal"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-slate-500 font-mono">{formatDate(p.created_at)}</TableCell>
                  <TableCell className="text-right">
                    <Link href={`/projects/${p.id}`}>
                      <Button size="sm" variant="outline" className="h-6.5 px-2 text-[11px]">
                        Inspect
                      </Button>
                    </Link>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>

        {/* Pagination */}
        {data && data.pages > 1 && (
          <div className="flex items-center justify-between px-3 py-2 border-t border-slate-100 bg-slate-50/50">
            <p className="text-xs text-slate-500 font-mono">
              Page <span className="font-semibold text-slate-900">{data.page}</span> of{" "}
              <span className="font-semibold text-slate-900">{data.pages}</span> · {data.total} total
            </p>
            <div className="flex items-center gap-1">
              <Button
                size="icon"
                variant="outline"
                className="h-7 w-7"
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                <ChevronLeft className="h-3.5 w-3.5" />
              </Button>
              <Button
                size="icon"
                variant="outline"
                className="h-7 w-7"
                disabled={page >= data.pages}
                onClick={() => setPage((p) => p + 1)}
              >
                <ChevronRight className="h-3.5 w-3.5" />
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
