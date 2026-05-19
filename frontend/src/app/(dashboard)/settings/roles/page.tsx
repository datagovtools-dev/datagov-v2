"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Pencil, Trash2, ShieldCheck } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Input } from "@/components/ui/Input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Modal, ModalContent, ModalHeader, ModalTitle, ModalBody, ModalFooter } from "@/components/ui/Modal";
import { formatDateTime } from "@/lib/utils";

interface Role { id: number; name: string; description: string | null; created_at: string }

const PERMISSION_MAP: Record<string, string[]> = {
  super_admin:              ["All permissions (wildcard)"],
  data_governance_officer:  ["dsr:read/approve/reject", "dpia:*", "ropa:*", "bapd:*", "metadata:read/update", "dq:read/run", "audit:read"],
  project_manager:          ["project:read/create/update", "dsr:read/create", "dpia:read", "ropa:read", "user:read"],
  data_steward:             ["metadata:*", "ropa:read/create/update", "dq:read/run/create"],
  data_owner:               ["dsr:read/approve/reject", "metadata:read"],
  requester:                ["dsr:read/create/update"],
  auditor:                  ["audit:read", "all modules: read-only"],
  viewer:                   ["all modules: read-only"],
};

export default function RolesPage() {
  const qc = useQueryClient();
  const [modalOpen, setModalOpen] = React.useState(false);
  const [permOpen, setPermOpen] = React.useState(false);
  const [editing, setEditing] = React.useState<Role | null>(null);
  const [viewing, setViewing] = React.useState<Role | null>(null);
  const [name, setName] = React.useState("");
  const [desc, setDesc] = React.useState("");
  const [error, setError] = React.useState("");

  const { data: roles = [], isLoading } = useQuery<Role[]>({
    queryKey: ["roles"],
    queryFn: () => api.get<Role[]>("/rbac/roles"),
  });

  const save = useMutation({
    mutationFn: () =>
      editing
        ? api.put(`/rbac/roles/${editing.id}`, { name, description: desc })
        : api.post("/rbac/roles", { name, description: desc }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["roles"] }); closeModal(); },
    onError: (e: any) => setError(e.message),
  });

  const del = useMutation({
    mutationFn: (id: number) => api.delete(`/rbac/roles/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["roles"] }),
  });

  function openNew() { setEditing(null); setName(""); setDesc(""); setError(""); setModalOpen(true); }
  function openEdit(r: Role) { setEditing(r); setName(r.name); setDesc(r.description ?? ""); setError(""); setModalOpen(true); }
  function closeModal() { setModalOpen(false); setEditing(null); }

  const isSeedRole = (name: string) => Object.keys(PERMISSION_MAP).includes(name);

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Role Management</h1>
          <p className="text-sm text-surface-500 mt-0.5">Manage system roles and their permission sets</p>
        </div>
        <Button onClick={openNew}><Plus className="h-4 w-4" /> New Role</Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Role Name</TableHead>
            <TableHead>Description</TableHead>
            <TableHead>Created</TableHead>
            <TableHead className="w-32">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={4} className="text-center text-surface-400 py-8">Loading…</TableCell></TableRow>
          ) : roles.map((role) => (
            <TableRow key={role.id}>
              <TableCell>
                <div className="flex items-center gap-2">
                  <span className="font-medium">{role.name}</span>
                  {isSeedRole(role.name) && <Badge variant="info">System</Badge>}
                </div>
              </TableCell>
              <TableCell className="text-surface-500">{role.description ?? "—"}</TableCell>
              <TableCell>{formatDateTime(role.created_at)}</TableCell>
              <TableCell>
                <div className="flex gap-1">
                  <Button size="icon" variant="ghost" title="View permissions"
                    onClick={() => { setViewing(role); setPermOpen(true); }}>
                    <ShieldCheck className="h-4 w-4" />
                  </Button>
                  <Button size="icon" variant="ghost" onClick={() => openEdit(role)}>
                    <Pencil className="h-4 w-4" />
                  </Button>
                  {!isSeedRole(role.name) && (
                    <Button size="icon" variant="ghost" className="text-red-500 hover:text-red-700"
                      onClick={() => del.mutate(role.id)}>
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  )}
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {/* Create / Edit modal */}
      <Modal open={modalOpen} onOpenChange={setModalOpen}>
        <ModalContent>
          <ModalHeader>
            <ModalTitle>{editing ? "Edit Role" : "New Role"}</ModalTitle>
          </ModalHeader>
          <ModalBody className="flex flex-col gap-4">
            <Input label="Role Name" value={name} onChange={e => setName(e.target.value)} required error={error} />
            <Input label="Description" value={desc} onChange={e => setDesc(e.target.value)} />
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" onClick={closeModal}>Cancel</Button>
            <Button loading={save.isPending} onClick={() => save.mutate()}>Save</Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Permissions modal */}
      <Modal open={permOpen} onOpenChange={setPermOpen}>
        <ModalContent>
          <ModalHeader>
            <ModalTitle>Permissions — {viewing?.name}</ModalTitle>
          </ModalHeader>
          <ModalBody>
            <ul className="space-y-2">
              {(PERMISSION_MAP[viewing?.name ?? ""] ?? ["Custom role — permissions managed in code"]).map((p) => (
                <li key={p} className="flex items-center gap-2 text-sm text-surface-700">
                  <ShieldCheck className="h-3.5 w-3.5 text-primary-500 shrink-0" />{p}
                </li>
              ))}
            </ul>
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" onClick={() => setPermOpen(false)}>Close</Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </div>
  );
}
