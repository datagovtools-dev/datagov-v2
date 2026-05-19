"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { UserPlus, X, Search } from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Input } from "@/components/ui/Input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Modal, ModalContent, ModalHeader, ModalTitle, ModalBody, ModalFooter } from "@/components/ui/Modal";

interface Role { id: number; name: string }
interface RoleAssignment { id: string; role_id: number; role_name: string; project_id: string | null; assigned_at: string }
interface UserSummary { id: string; full_name: string; email: string; is_active: boolean; roles: RoleAssignment[] }

export default function UsersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = React.useState("");
  const [assignOpen, setAssignOpen] = React.useState(false);
  const [selectedUser, setSelectedUser] = React.useState<UserSummary | null>(null);
  const [roleId, setRoleId] = React.useState("");
  const [assignError, setAssignError] = React.useState("");

  const { data: users = [], isLoading } = useQuery<UserSummary[]>({
    queryKey: ["users", search],
    queryFn: () => api.get<UserSummary[]>(`/rbac/users?search=${encodeURIComponent(search)}`),
  });

  const { data: roles = [] } = useQuery<Role[]>({
    queryKey: ["roles"],
    queryFn: () => api.get<Role[]>("/rbac/roles"),
  });

  const assign = useMutation({
    mutationFn: () => api.post(`/rbac/users/${selectedUser!.id}/roles`, { user_id: selectedUser!.id, role_id: parseInt(roleId) }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["users"] }); setAssignOpen(false); },
    onError: (e: any) => setAssignError(e.message),
  });

  const revoke = useMutation({
    mutationFn: ({ userId, assignmentId }: { userId: string; assignmentId: string }) =>
      api.delete(`/rbac/users/${userId}/roles/${assignmentId}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["users"] }),
  });

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>User Management</h1>
          <p className="text-sm text-surface-500 mt-0.5">Assign and revoke roles for all platform users</p>
        </div>
      </div>

      <div className="relative mb-4 max-w-xs">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-surface-400 pointer-events-none" />
        <input
          className="input-base pl-9"
          placeholder="Search users…"
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Assigned Roles</TableHead>
            <TableHead className="w-28">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {isLoading ? (
            <TableRow><TableCell colSpan={5} className="text-center py-8 text-surface-400">Loading…</TableCell></TableRow>
          ) : users.map((user) => (
            <TableRow key={user.id}>
              <TableCell className="font-medium">{user.full_name}</TableCell>
              <TableCell className="text-surface-500">{user.email}</TableCell>
              <TableCell>
                <Badge variant={user.is_active ? "approved" : "rejected"}>
                  {user.is_active ? "Active" : "Inactive"}
                </Badge>
              </TableCell>
              <TableCell>
                <div className="flex flex-wrap gap-1">
                  {user.roles.length === 0 ? (
                    <span className="text-surface-400 text-xs">No roles</span>
                  ) : user.roles.map((r) => (
                    <span key={r.id} className="inline-flex items-center gap-1 rounded-full bg-primary-50 px-2 py-0.5 text-xs font-medium text-primary-700 border border-primary-200">
                      {r.role_name}
                      <button onClick={() => revoke.mutate({ userId: user.id, assignmentId: r.id })}
                        className="text-primary-400 hover:text-red-500 ml-0.5">
                        <X className="h-3 w-3" />
                      </button>
                    </span>
                  ))}
                </div>
              </TableCell>
              <TableCell>
                <Button size="sm" variant="outline"
                  onClick={() => { setSelectedUser(user); setRoleId(""); setAssignError(""); setAssignOpen(true); }}>
                  <UserPlus className="h-3.5 w-3.5" /> Assign
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <Modal open={assignOpen} onOpenChange={setAssignOpen}>
        <ModalContent size="sm">
          <ModalHeader>
            <ModalTitle>Assign Role — {selectedUser?.full_name}</ModalTitle>
          </ModalHeader>
          <ModalBody>
            <Select value={roleId} onValueChange={setRoleId}>
              <SelectTrigger error={!!assignError}><SelectValue placeholder="Select a role…" /></SelectTrigger>
              <SelectContent>
                {roles.map(r => <SelectItem key={r.id} value={String(r.id)}>{r.name}</SelectItem>)}
              </SelectContent>
            </Select>
            {assignError && <p className="text-xs text-red-500 mt-2">{assignError}</p>}
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" onClick={() => setAssignOpen(false)}>Cancel</Button>
            <Button disabled={!roleId} loading={assign.isPending} onClick={() => assign.mutate()}>Assign</Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </div>
  );
}
