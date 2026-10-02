"use client";

import * as React from "react";
import { Badge } from "@/components/ui/Badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { formatDate } from "@/lib/utils";

export interface ProjectDetailLike {
  id?: string;
  project_code: string | null;
  project_name: string;
  customer_name: string;
  line_of_business: string | null;
  use_case: string | null;
  project_year: number;
  project_category: string;
  is_monetized: boolean;
  start_date: string | null;
  end_date: string | null;
  sme_id: string | null;
  delivery_manager_id: string | null;
  project_manager_id: string | null;
  dgo_id: string | null;
  metadata_officer_id: string | null;
  dq_officer_id: string | null;
  pic_data_compliance_id: string | null;
}

export interface UserOptionLike {
  id: string;
  full_name: string;
  email: string;
}

export interface OwnerRecordLike {
  role_type: string;
  full_name: string;
  email: string;
  position?: string | null;
}

/** Until when uploaded source files are kept (GET /projects/{id}/source-file-retention). */
export interface SourceFileRetentionLike {
  expiry_date: string | null;
  warning_date: string | null;
  basis: "default" | "ropa" | string;
  default_days: number;
  ropa_retention_period: string | null;
  ropa_process_name: string | null;
  unreadable_ropa_periods: string[];
}

export function retentionBasisText(r: SourceFileRetentionLike): string {
  return r.basis === "ropa"
    ? `End date + approved ROPA retention period "${r.ropa_retention_period}"${r.ropa_process_name ? ` (${r.ropa_process_name})` : ""}`
    : `End date + ${r.default_days} days (no approved ROPA yet)`;
}

function EmptyValue() {
  return <span className="text-slate-400 font-mono">-</span>;
}

function UserName({ id, users }: { id: string | null; users: UserOptionLike[] }) {
  if (!id) return <EmptyValue />;
  const user = users.find((u) => u.id === id);
  return user ? (
    <span className="flex flex-col">
      <span className="font-semibold text-xs text-slate-900">{user.full_name}</span>
      <span className="text-[11px] text-slate-400 font-mono">{user.email}</span>
    </span>
  ) : <EmptyValue />;
}

function OwnerName({ owner }: { owner?: OwnerRecordLike }) {
  return owner ? (
    <span className="flex flex-col">
      <span className="font-semibold text-xs text-slate-900">{owner.full_name}</span>
      {owner.position && <span className="text-[11px] text-slate-600">{owner.position}</span>}
      <span className="text-[11px] text-slate-400 font-mono">{owner.email}</span>
    </span>
  ) : <EmptyValue />;
}

function SourceFileRetentionField({ retention }: { retention: SourceFileRetentionLike }) {
  return (
    <div className="md:col-span-2">
      <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Uploaded Source Files Kept Until</p>
      {retention.expiry_date ? (
        <>
          <p className="text-xs text-slate-900 font-mono">{formatDate(retention.expiry_date)}</p>
          <p className="text-[11px] text-slate-500">{retentionBasisText(retention)}. Files are deleted on this date; metadata, DQ results and governance records stay.</p>
        </>
      ) : (
        <p className="text-[11px] text-slate-500">Set the project End Date to start the retention period (end date + {retention.default_days} days, or the approved ROPA retention period).</p>
      )}
      {retention.unreadable_ropa_periods.length > 0 && (
        <p className="text-[11px] text-amber-700 mt-0.5">
          Approved ROPA retention period{retention.unreadable_ropa_periods.length > 1 ? "s" : ""} not readable as a duration: {retention.unreadable_ropa_periods.map(p => `"${p}"`).join(", ")}. Use e.g. &quot;5 Years&quot;.
        </p>
      )}
    </div>
  );
}

export function ProjectBasicInformationContent({ project, retention }: { project: ProjectDetailLike; retention?: SourceFileRetentionLike }) {
  return (
    <>
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project ID</p>
        {project.project_code
          ? <p className="font-mono font-medium text-slate-900">{project.project_code}</p>
          : <EmptyValue />}
      </div>
      <div />
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project Name</p><p className="font-medium text-xs text-slate-900">{project.project_name}</p></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Customer / Client</p><p className="font-medium text-xs text-slate-900">{project.customer_name}</p></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Line of Business</p><p className="text-xs text-slate-900">{project.line_of_business ?? <EmptyValue />}</p></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project Category</p><Badge variant="default" className="text-[10px] font-mono">{project.project_category}</Badge></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Project Year</p><p className="text-xs text-slate-900 font-mono">{project.project_year}</p></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Monetized</p><Badge variant={project.is_monetized ? "success" : "default"} className="text-[10px] font-mono">{project.is_monetized ? "Yes" : "No"}</Badge></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Start Date</p><p className="text-xs text-slate-900 font-mono">{project.start_date ? formatDate(project.start_date) : <EmptyValue />}</p></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">End Date</p><p className="text-xs text-slate-900 font-mono">{project.end_date ? formatDate(project.end_date) : <EmptyValue />}</p></div>
      {retention && <SourceFileRetentionField retention={retention} />}
      {project.use_case && (
        <div className="md:col-span-2"><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-0.5">Use Case / Description</p><p className="text-xs text-slate-800 leading-relaxed">{project.use_case}</p></div>
      )}
    </>
  );
}

export function ProjectTeamContent({ project, users }: { project: ProjectDetailLike; users: UserOptionLike[] }) {
  return (
    <>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Subject Matter Expert (SME)</p><UserName id={project.sme_id} users={users} /></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Delivery Manager</p><UserName id={project.delivery_manager_id} users={users} /></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Project Manager</p><UserName id={project.project_manager_id} users={users} /></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Data Governance Officer</p><UserName id={project.dgo_id} users={users} /></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Metadata Officer</p><UserName id={project.metadata_officer_id} users={users} /></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">DQ Officer</p><UserName id={project.dq_officer_id} users={users} /></div>
      <div><p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">PIC Data Compliance</p><UserName id={project.pic_data_compliance_id} users={users} /></div>
    </>
  );
}

export function ProjectOwnerStewardContent({ owners }: { owners: OwnerRecordLike[] }) {
  const dataSteward = owners.find((o) => o.role_type === "lead_business_steward") ?? owners.find((o) => o.role_type === "business_steward");
  const dataOwner = owners.find((o) => o.role_type === "data_owner");

  return (
    <>
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Data Steward</p>
        <OwnerName owner={dataSteward} />
      </div>
      <div>
        <p className="text-[10px] font-semibold uppercase tracking-wider text-slate-400 font-mono mb-1">Data Owner</p>
        <OwnerName owner={dataOwner} />
      </div>
    </>
  );
}

export function ProjectDetailCards({
  project,
  users,
  owners,
}: {
  project: ProjectDetailLike;
  users: UserOptionLike[];
  owners: OwnerRecordLike[];
}) {
  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Basic Information</CardTitle>
        </CardHeader>
        <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
          <ProjectBasicInformationContent project={project} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Project Team</CardTitle>
        </CardHeader>
        <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-3.5">
          <ProjectTeamContent project={project} users={users} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-3 border-b border-slate-100">
          <CardTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">Data Steward &amp; Data Owner</CardTitle>
        </CardHeader>
        <CardContent className="pt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
          <ProjectOwnerStewardContent owners={owners} />
        </CardContent>
      </Card>
    </div>
  );
}
