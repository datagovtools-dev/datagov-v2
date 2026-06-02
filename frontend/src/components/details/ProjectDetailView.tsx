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
  return <span className="text-surface-400">-</span>;
}

function UserName({ id, users }: { id: string | null; users: UserOptionLike[] }) {
  if (!id) return <EmptyValue />;
  const user = users.find((u) => u.id === id);
  return user ? (
    <span className="flex flex-col">
      <span className="font-medium text-surface-900">{user.full_name}</span>
      <span className="text-xs text-surface-400">{user.email}</span>
    </span>
  ) : <EmptyValue />;
}

function OwnerName({ owner }: { owner?: OwnerRecordLike }) {
  return owner ? (
    <span className="flex flex-col">
      <span className="font-medium text-surface-900">{owner.full_name}</span>
      <span className="text-xs text-surface-400">{owner.email}</span>
    </span>
  ) : <EmptyValue />;
}

export function ProjectBasicInformationContent({ project }: { project: ProjectDetailLike }) {
  return (
    <>
      <div>
        <p className="text-xs text-surface-400 mb-0.5">Project ID</p>
        {project.project_code
          ? <p className="font-mono font-medium text-primary-700">{project.project_code}</p>
          : <EmptyValue />}
      </div>
      <div />
      <div><p className="text-xs text-surface-400 mb-0.5">Project Name</p><p className="font-medium">{project.project_name}</p></div>
      <div><p className="text-xs text-surface-400 mb-0.5">Customer / Client</p><p className="font-medium">{project.customer_name}</p></div>
      <div><p className="text-xs text-surface-400 mb-0.5">Line of Business</p><p>{project.line_of_business ?? <EmptyValue />}</p></div>
      <div><p className="text-xs text-surface-400 mb-0.5">Project Category</p><Badge variant="default">{project.project_category}</Badge></div>
      <div><p className="text-xs text-surface-400 mb-0.5">Project Year</p><p>{project.project_year}</p></div>
      <div><p className="text-xs text-surface-400 mb-0.5">Monetized</p><Badge variant={project.is_monetized ? "approved" : "default"}>{project.is_monetized ? "Yes" : "No"}</Badge></div>
      <div><p className="text-xs text-surface-400 mb-0.5">Start Date</p><p>{project.start_date ? formatDate(project.start_date) : <EmptyValue />}</p></div>
      <div><p className="text-xs text-surface-400 mb-0.5">End Date</p><p>{project.end_date ? formatDate(project.end_date) : <EmptyValue />}</p></div>
      {project.use_case && (
        <div className="md:col-span-2"><p className="text-xs text-surface-400 mb-0.5">Use Case / Description</p><p className="text-sm">{project.use_case}</p></div>
      )}
    </>
  );
}

export function ProjectTeamContent({ project, users }: { project: ProjectDetailLike; users: UserOptionLike[] }) {
  return (
    <>
      <div><p className="text-xs text-surface-400 mb-1">Subject Matter Expert (SME)</p><UserName id={project.sme_id} users={users} /></div>
      <div><p className="text-xs text-surface-400 mb-1">Delivery Manager</p><UserName id={project.delivery_manager_id} users={users} /></div>
      <div><p className="text-xs text-surface-400 mb-1">Project Manager</p><UserName id={project.project_manager_id} users={users} /></div>
      <div><p className="text-xs text-surface-400 mb-1">Data Governance Officer</p><UserName id={project.dgo_id} users={users} /></div>
      <div><p className="text-xs text-surface-400 mb-1">Metadata Officer</p><UserName id={project.metadata_officer_id} users={users} /></div>
      <div><p className="text-xs text-surface-400 mb-1">DQ Officer</p><UserName id={project.dq_officer_id} users={users} /></div>
      <div><p className="text-xs text-surface-400 mb-1">PIC Data Compliance</p><UserName id={project.pic_data_compliance_id} users={users} /></div>
    </>
  );
}

export function ProjectOwnerStewardContent({ owners }: { owners: OwnerRecordLike[] }) {
  const dataSteward = owners.find((o) => o.role_type === "lead_business_steward") ?? owners.find((o) => o.role_type === "business_steward");
  const dataOwner = owners.find((o) => o.role_type === "data_owner");

  return (
    <>
      <div>
        <p className="text-xs text-surface-400 mb-1">Data Steward</p>
        <OwnerName owner={dataSteward} />
      </div>
      <div>
        <p className="text-xs text-surface-400 mb-1">Data Owner</p>
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
    <div className="space-y-5">
      <Card>
        <CardHeader><CardTitle>Basic Information</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <ProjectBasicInformationContent project={project} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Project Team</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <ProjectTeamContent project={project} users={users} />
        </CardContent>
      </Card>

      <Card>
        <CardHeader><CardTitle>Data Steward &amp; Data Owner</CardTitle></CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <ProjectOwnerStewardContent owners={owners} />
        </CardContent>
      </Card>
    </div>
  );
}
