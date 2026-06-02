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
interface PaginatedProjects { items: ProjectItem[]; total: number; page: number; page_size: number; pages: number }
interface Filters { years: number[]; categories: string[]; clients: string[] }

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

  function handleSearch(v: string) { setSearch(v); setPage(1); }
  function handleClient(v: string) { setClient(v === "all" ? "" : v); setPage(1); }
  function handleCategory(v: string) { setCategory(v === "all" ? "" : v); setPage(1); }
  function handleYear(v: string) { setYear(v === "all" ? "" : v); setPage(1); }
  function handleMonetized(v: string) { setMonetized(v === "all" ? "" : v); setPage(1); }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Projects</h1>
          <p className="text-sm text-surface-500 mt-0.5">
            Manage and track all data governance projects
            {data ? ` · ${data.total} project${data.total !== 1 ? "s" : ""}` : ""}
          </p>
        </div>
        <Link href="/projects/new">
          <Button><Plus className="h-4 w-4 mr-1" /> New Project</Button>
        </Link>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-5">
        <div className="relative flex-1 min-w-[200px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
          <input className="input-base pl-9" placeholder="Search by project, client or project ID…"
            value={search} onChange={e => handleSearch(e.target.value)} />
        </div>
        <Select value={client || "all"} onValueChange={handleClient}>
          <SelectTrigger className="w-48"><SelectValue placeholder="All Clients" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Clients</SelectItem>
            {(filters?.clients ?? [] as string[]).map((c: string) => <SelectItem key={c} value={c}>{c}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={category || "all"} onValueChange={handleCategory}>
          <SelectTrigger className="w-44"><SelectValue placeholder="All Categories" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            {(filters?.categories ?? []).map(c => <SelectItem key={c} value={c}>{c}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={year || "all"} onValueChange={handleYear}>
          <SelectTrigger className="w-32"><SelectValue placeholder="All Years" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Years</SelectItem>
            {(filters?.years ?? [] as number[]).map((y: number) => <SelectItem key={y} value={String(y)}>{y}</SelectItem>)}
          </SelectContent>
        </Select>
        <Select value={monetized || "all"} onValueChange={handleMonetized}>
          <SelectTrigger className="w-44"><SelectValue placeholder="All Monetized" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Monetized</SelectItem>
            <SelectItem value="true">Monetized</SelectItem>
            <SelectItem value="false">Not Monetized</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Project ID</TableHead>
            <TableHead>Project Name</TableHead>
            <TableHead>Client</TableHead>
            <TableHead>Category</TableHead>
            <TableHead>Year</TableHead>
            <TableHead>Monetized</TableHead>
            <TableHead>Created</TableHead>
            <TableHead className="w-24">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={8} className="text-center py-10 text-surface-400">Loading…</TableCell></TableRow>
          ) : data?.items.length === 0 ? (
            <TableRow><TableCell colSpan={8} className="text-center py-10 text-surface-400">No projects found</TableCell></TableRow>
          ) : data?.items.map((p) => (
            <TableRow key={p.id}>
              <TableCell className="font-mono text-sm text-primary-700">
                {p.project_code ?? <span className="text-surface-400">—</span>}
              </TableCell>
              <TableCell className="max-w-[200px] truncate" title={p.project_name}>{p.project_name}</TableCell>
              <TableCell className="max-w-[160px] truncate text-surface-600" title={p.customer_name}>{p.customer_name}</TableCell>
              <TableCell><Badge variant="default">{p.project_category}</Badge></TableCell>
              <TableCell>{p.project_year}</TableCell>
              <TableCell>
                <Badge variant={p.is_monetized ? "approved" : "default"}>
                  {p.is_monetized ? "Yes" : "No"}
                </Badge>
              </TableCell>
              <TableCell>{formatDate(p.created_at)}</TableCell>
              <TableCell>
                <Link href={`/projects/${p.id}`}>
                  <Button size="sm" variant="outline">View</Button>
                </Link>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {data && data.pages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-surface-500">
            Page {data.page} of {data.pages} · {data.total} total
          </p>
          <div className="flex gap-1">
            <Button size="icon" variant="outline" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button size="icon" variant="outline" disabled={page >= data.pages} onClick={() => setPage(p => p + 1)}>
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
