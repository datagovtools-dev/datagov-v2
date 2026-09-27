"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";

interface ProjectSummary {
  id: string;
  project_code: string | null;
  project_name: string;
  project_year: number;
  customer_name: string;
  line_of_business: string | null;
}

interface ProjectOwner {
  role_type: string;
  full_name: string;
  email: string;
}

// Name and email only; the Data Owner position is shown in the Data Assets Catalog and used in the DSR
function PersonCell({ label, person }: { label: string; person?: ProjectOwner }) {
  return (
    <div className="min-w-0">
      <div className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono">{label}</div>
      {person ? (
        <>
          <div className="text-xs font-normal text-slate-800 mt-0.5 truncate" title={person.full_name}>{person.full_name}</div>
          <div className="text-[10px] text-slate-400 font-mono truncate" title={person.email}>{person.email}</div>
        </>
      ) : <div className="text-xs text-slate-300 mt-0.5 font-mono">—</div>}
    </div>
  );
}

/**
 * Project info strip: Project ID, Name, Year, Business Users, Line of Business,
 * Data Steward and Data Owner. Shared by the Metadata attributes page and the DQ pages.
 */
export function ProjectInfoStrip({ projectId }: { projectId: string }) {
  const { data: project } = useQuery<ProjectSummary>({
    queryKey: ["project", projectId],
    queryFn: () => api.get(`/projects/${projectId}`),
    enabled: !!projectId,
  });

  const { data: owners = [] } = useQuery<ProjectOwner[]>({
    queryKey: ["metadata-owners", projectId],
    queryFn: () => api.get(`/metadata/owners/${projectId}`),
    enabled: !!projectId,
  });

  if (!project) return null;

  const dataSteward = owners.find((o) => o.role_type === "lead_business_steward") ?? owners.find((o) => o.role_type === "business_steward");
  const dataOwner = owners.find((o) => o.role_type === "data_owner");

  return (
    <div className="bg-white border border-slate-200 rounded-md shadow-2xs px-4 py-3 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-7 gap-x-3 gap-y-2">
      {[
        { label: "Project ID",       value: project.project_code ?? "—", mono: true,  bold: true },
        { label: "Project Name",     value: project.project_name,                      bold: true },
        { label: "Project Year",     value: String(project.project_year ?? "—"),       bold: false },
        { label: "Business Users",   value: project.customer_name || "—",              bold: false },
        { label: "Line of Business", value: project.line_of_business || "—",           bold: false },
      ].map(({ label, value, mono, bold }) => (
        <div key={label} className="min-w-0">
          <div className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono truncate">{label}</div>
          <div className={`text-xs mt-0.5 truncate text-slate-800 ${bold ? "font-semibold" : "font-normal"} ${mono ? "font-mono" : ""}`} title={value}>{value}</div>
        </div>
      ))}
      <PersonCell label="Data Steward" person={dataSteward} />
      <PersonCell label="Data Owner" person={dataOwner} />
    </div>
  );
}
