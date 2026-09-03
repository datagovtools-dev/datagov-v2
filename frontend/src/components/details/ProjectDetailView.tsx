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
      <span className="text-[11px] text-slate-400 font-mono">{owner.email}</span>
    </span>
  ) : <EmptyValue />;
}

export function ProjectBasicInformationContent({ project }: { project: ProjectDetailLike }) {
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
