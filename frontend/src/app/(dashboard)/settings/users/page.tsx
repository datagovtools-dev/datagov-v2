"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  UserPlus,
  X,
  Search,
  ShieldCheck,
  LayoutDashboard,
  FolderOpen,
  Database,
  Share2,
  Bot,
  BarChart2,
  ClipboardList,
  History,
  Sparkles,
  Settings,
  CheckCircle2,
  XCircle,
  Users,
  Layers,
  UserCheck,
  Eye,
  Trash2,
  Calendar,
} from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Input } from "@/components/ui/Input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/Select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Modal, ModalContent, ModalHeader, ModalTitle, ModalBody, ModalFooter } from "@/components/ui/Modal";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/Card";
import { TableSkeleton } from "@/components/ui/LoadingState";
import { toast } from "@/components/ui/Toast";
import { formatDateTime } from "@/lib/utils";

interface MenuAccessItem {
  id: string;
  label: string;
  href: string;
  group: string;
  icon: string;
  description: string;
  is_accessible: boolean;
}

interface ActivityItem {
  id: string;
  name: string;
  group: string;
  category: string;
  description: string;
  required_permission: string | null;
  is_permitted: boolean;
}

interface RoleOption {
  id: number;
  name: string;
  description: string | null;
  accessible_menu_count?: number;
  permitted_activity_count?: number;
  menus?: MenuAccessItem[];
  activities?: ActivityItem[];
}

interface RoleAssignment {
  id: string;
  role_id: number;
  role_name: string;
  project_id: string | null;
  assigned_at: string;
}

interface UserSummary {
  id: string;
  full_name: string;
  email: string;
  position: string | null;
  is_active: boolean;
  roles: RoleAssignment[];
  accessible_menu_count: number;
  permitted_activity_count: number;
  accessible_menus: MenuAccessItem[];
  permitted_activities: ActivityItem[];
}

const ICON_MAP: Record<string, React.ComponentType<{ className?: string }>> = {
  LayoutDashboard,
  FolderOpen,
  Database,
  Share2,
  Bot,
  ShieldCheck,
  ClipboardList,
  BarChart2,
  Trash2,
  History,
  Sparkles,
  Settings,
};

export default function UsersPage() {
  const qc = useQueryClient();
  const [search, setSearch] = React.useState("");
  const [assignOpen, setAssignOpen] = React.useState(false);
  const [accessProfileOpen, setAccessProfileOpen] = React.useState(false);
  const [accessSubTab, setAccessSubTab] = React.useState<"menus" | "activities" | "roles">("menus");
  const [selectedUser, setSelectedUser] = React.useState<UserSummary | null>(null);
  const [roleId, setRoleId] = React.useState("");
  const [assignError, setAssignError] = React.useState("");

  const { data: users = [], isLoading: usersLoading } = useQuery<UserSummary[]>({
    queryKey: ["users", search],
    queryFn: () => api.get<UserSummary[]>(`/rbac/users?search=${encodeURIComponent(search)}`),
  });

  const { data: roles = [] } = useQuery<RoleOption[]>({
    queryKey: ["roles"],
    queryFn: () => api.get<RoleOption[]>("/rbac/roles"),
  });

  const assign = useMutation({
    mutationFn: () =>
      api.post(`/rbac/users/${selectedUser!.id}/roles`, {
        user_id: selectedUser!.id,
        role_id: parseInt(roleId),
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["users"] });
      qc.invalidateQueries({ queryKey: ["roles"] });
      toast.success("Role berhasil ditugaskan ke pengguna");
      setAssignOpen(false);
      // Update selectedUser if opened in profile view
      if (selectedUser) {
        qc.refetchQueries({ queryKey: ["users"] });
      }
    },
    onError: (e: any) => {
      setAssignError(e.message);
      toast.error(e.message || "Gagal menugaskan role");
    },
  });

  const revoke = useMutation({
    mutationFn: ({ userId, assignmentId }: { userId: string; assignmentId: string }) =>
      api.delete(`/rbac/users/${userId}/roles/${assignmentId}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["users"] });
      qc.invalidateQueries({ queryKey: ["roles"] });
      toast.success("Penugasan role berhasil dicabut");
    },
    onError: (e: any) => {
      toast.error(e.message || "Gagal mencabut role");
    },
  });

  // Find selected role details for live capability preview during assignment
  const selectedRoleOption = roles.find((r) => String(r.id) === roleId);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/80 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">Manajemen Pengguna & Izin Akses</h1>
            <Badge variant="info">Directory</Badge>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Kelola penugasan role pengguna dan pantau izin akses menu serta aktivitas operasional mereka
          </p>
        </div>
      </div>

      {/* Metrics Bar */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        <Card>
          <CardContent className="p-3.5 flex items-center gap-3">
            <div className="h-8 w-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-800 shrink-0">
              <Users className="h-4 w-4" />
            </div>
            <div>
              <div className="text-[10px] uppercase font-mono tracking-wider text-slate-400 font-semibold">Total User Accounts</div>
              <div className="text-base font-bold font-mono text-slate-900 tabular-nums">{users.length} Users</div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-3.5 flex items-center gap-3">
            <div className="h-8 w-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-800 shrink-0">
              <UserCheck className="h-4 w-4" />
            </div>
            <div>
              <div className="text-[10px] uppercase font-mono tracking-wider text-slate-400 font-semibold">Active Users</div>
              <div className="text-base font-bold font-mono text-slate-900 tabular-nums">
                {users.filter((u) => u.is_active).length} Users
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-3.5 flex items-center gap-3">
            <div className="h-8 w-8 rounded-md bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-800 shrink-0">
              <ShieldCheck className="h-4 w-4" />
            </div>
            <div>
              <div className="text-[10px] uppercase font-mono tracking-wider text-slate-400 font-semibold">Role-Assigned Users</div>
              <div className="text-base font-bold font-mono text-slate-900 tabular-nums">
                {users.filter((u) => u.roles && u.roles.length > 0).length} Users
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search & Filter Bar */}
      <div className="flex items-center justify-between gap-3">
        <div className="w-full max-w-sm">
          <Input
            placeholder="Search by name, email, or position…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="h-8 text-xs font-mono"
          />
        </div>
        <div className="text-xs text-slate-500 font-mono">
          Showing {users.length} registered users
        </div>
      </div>

      {/* Users Table */}
      <Card>
        <CardContent className="p-0 overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User Identity</TableHead>
                <TableHead>Email &amp; Position</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Assigned Roles</TableHead>
                <TableHead>Access Scope</TableHead>
                <TableHead className="w-36 text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {usersLoading ? (
                <TableRow>
                  <TableCell colSpan={6} className="p-0">
                    <TableSkeleton rows={5} cols={6} />
                  </TableCell>
                </TableRow>
              ) : users.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-10 text-slate-400 text-xs font-mono">
                    No users found matching search query.
                  </TableCell>
                </TableRow>
              ) : (
                users.map((user) => {
                  const isSuper = user.roles.some((r) => r.role_name === "super_admin");
                  const accessibleCount = isSuper ? 12 : user.accessible_menu_count;
                  const activityCount = isSuper ? 22 : user.permitted_activity_count;

                  return (
                    <TableRow key={user.id} className="hover:bg-slate-50/70 transition-colors">
                      <TableCell>
                        <div className="flex items-center gap-2.5">
                          <div className="h-7 w-7 rounded-md bg-slate-900 text-white flex items-center justify-center text-[10px] font-bold shrink-0 font-mono">
                            {user.full_name
                              .split(" ")
                              .map((n) => n[0])
                              .slice(0, 2)
                              .join("")}
                          </div>
                          <div className="flex flex-col min-w-0">
                            <span className="font-semibold text-slate-900 text-xs truncate">
                              {user.full_name}
                            </span>
                            {user.position && (
                              <span className="text-[10px] text-slate-400 truncate font-mono">
                                {user.position}
                              </span>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className="text-xs text-slate-600 font-mono">{user.email}</span>
                      </TableCell>
                      <TableCell>
                        <Badge variant={user.is_active ? "success" : "danger"} className="text-[10px]">
                          {user.is_active ? "Active" : "Inactive"}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1 max-w-xs">
                          {user.roles.length === 0 ? (
                            <span className="text-slate-400 text-xs font-mono italic">No roles</span>
                          ) : (
                            user.roles.map((r) => (
                              <span
                                key={r.id}
                                className={`inline-flex items-center gap-1 rounded-md px-1.5 py-0.5 text-[10px] font-mono border ${
                                  r.role_name === "super_admin"
                                    ? "bg-slate-900 text-white border-slate-900 font-semibold"
                                    : "bg-slate-100 text-slate-800 border-slate-200 font-medium"
                                }`}
                              >
                                {r.role_name}
                                <button
                                  type="button"
                                  title="Revoke Role"
                                  onClick={() => revoke.mutate({ userId: user.id, assignmentId: r.id })}
                                  className="text-slate-400 hover:text-rose-600 ml-0.5 rounded p-0.5 transition-colors"
                                >
                                  <X className="h-2.5 w-2.5" />
                                </button>
                              </span>
                            ))
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1.5">
                          {isSuper ? (
                            <span className="rounded-md bg-emerald-50 text-emerald-800 border border-emerald-200 px-1.5 py-0.5 text-[10px] font-mono font-semibold">
                              Full Access (12 Modules • 22 Actions)
                            </span>
                          ) : user.roles.length === 0 ? (
                            <span className="text-slate-400 text-[10px] font-mono">Dashboard Only</span>
                          ) : (
                            <div className="flex items-center gap-1 text-[10px] font-mono text-slate-700">
                              <span className="bg-slate-100 text-slate-800 px-1.5 py-0.5 rounded-md border border-slate-200 font-medium">
                                {accessibleCount} Modules
                              </span>
                              <span className="text-slate-300">•</span>
                              <span className="bg-slate-100 text-slate-700 px-1.5 py-0.5 rounded-md border border-slate-200">
                                {activityCount} Actions
                              </span>
                            </div>
                          )}
                        </div>
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex items-center justify-end gap-1">
                          <Button
                            size="sm"
                            variant="outline"
                            title="Inspect access profile and modules"
                            onClick={() => {
                              setSelectedUser(user);
                              setAccessSubTab("menus");
                              setAccessProfileOpen(true);
                            }}
                            className="h-7 px-2 text-xs font-medium text-slate-700"
                          >
                            <Eye className="h-3 w-3 mr-1 text-slate-500" />
                            Profile
                          </Button>
                          <Button
                            size="sm"
                            onClick={() => {
                              setSelectedUser(user);
                              setRoleId("");
                              setAssignError("");
                              setAssignOpen(true);
                            }}
                            className="h-7 px-2 text-xs font-medium"
                          >
                            <UserPlus className="h-3 w-3 mr-1" />
                            Assign
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  );
                })
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* User Access Profile Modal */}
      <Modal open={accessProfileOpen} onOpenChange={setAccessProfileOpen}>
        <ModalContent size="lg">
          <ModalHeader className="border-b border-slate-100 pb-3">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="h-8 w-8 rounded-md bg-slate-900 text-white flex items-center justify-center text-xs font-bold shrink-0 font-mono">
                  {selectedUser?.full_name
                    .split(" ")
                    .map((n) => n[0])
                    .slice(0, 2)
                    .join("")}
                </div>
                <div>
                  <ModalTitle className="text-sm font-semibold font-mono flex items-center gap-2">
                    Access Profile: {selectedUser?.full_name}
                  </ModalTitle>
                  <p className="text-xs text-slate-500 font-mono">{selectedUser?.email}</p>
                </div>
              </div>
              <div className="flex items-center gap-1">
                {selectedUser?.roles.map((r) => (
                  <span
                    key={r.id}
                    className="rounded-md bg-slate-100 text-slate-800 border border-slate-200 px-2 py-0.5 text-[10px] font-mono font-medium"
                  >
                    {r.role_name}
                  </span>
                ))}
              </div>
            </div>
          </ModalHeader>
          <ModalBody className="space-y-3 pt-3">
            {/* Sub-tabs */}
            <div className="flex border-b border-slate-200 text-xs font-mono font-semibold">
              <button
                onClick={() => setAccessSubTab("menus")}
                className={`pb-2 px-3 border-b-2 transition-colors ${
                  accessSubTab === "menus"
                    ? "border-slate-900 text-slate-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Accessible Modules (
                {selectedUser?.roles.some((r) => r.role_name === "super_admin")
                  ? "12"
                  : selectedUser?.accessible_menus.filter((m) => m.is_accessible).length}
                )
              </button>
              <button
                onClick={() => setAccessSubTab("activities")}
                className={`pb-2 px-3 border-b-2 transition-colors ${
                  accessSubTab === "activities"
                    ? "border-slate-900 text-slate-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Permitted Actions (
                {selectedUser?.roles.some((r) => r.role_name === "super_admin")
                  ? "22"
                  : selectedUser?.permitted_activities.filter((a) => a.is_permitted).length}
                )
              </button>
              <button
                onClick={() => setAccessSubTab("roles")}
                className={`pb-2 px-3 border-b-2 transition-colors ${
                  accessSubTab === "roles"
                    ? "border-slate-900 text-slate-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Role History ({selectedUser?.roles.length || 0})
              </button>
            </div>

            {/* Menus List */}
            {accessSubTab === "menus" && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-[380px] overflow-y-auto pr-1">
                {selectedUser?.accessible_menus.map((menu) => {
                  const isSuper = selectedUser.roles.some((r) => r.role_name === "super_admin");
                  const hasAccess = isSuper || menu.is_accessible;
                  const IconComp = ICON_MAP[menu.icon] || FolderOpen;

                  return (
                    <div
                      key={menu.id}
                      className={`p-2.5 rounded-md border transition-colors flex items-start gap-2.5 ${
                        hasAccess
                          ? "bg-white border-slate-200 shadow-2xs"
                          : "bg-slate-50/50 border-slate-100 opacity-40"
                      }`}
                    >
                      <div
                        className={`p-1.5 rounded-md shrink-0 ${
                          hasAccess
                            ? "bg-slate-100 text-slate-800 border border-slate-200"
                            : "bg-slate-200 text-slate-400"
                        }`}
                      >
                        <IconComp className="h-3.5 w-3.5" />
                      </div>
                      <div className="flex flex-col min-w-0 flex-1">
                        <div className="flex items-center justify-between gap-1">
                          <span className="font-semibold text-xs text-slate-900 truncate font-mono">
                            {menu.label}
                          </span>
                          {hasAccess ? (
                            <CheckCircle2 className="h-3 w-3 text-emerald-600 shrink-0" />
                          ) : (
                            <XCircle className="h-3 w-3 text-slate-300 shrink-0" />
                          )}
                        </div>
                        <span className="text-[10px] text-slate-400 font-mono mt-0.5">
                          {menu.href}
                        </span>
                        <p className="text-[11px] text-slate-500 mt-0.5 leading-snug">
                          {menu.description}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {/* Activities List */}
            {accessSubTab === "activities" && (
              <div className="space-y-1.5 max-h-[380px] overflow-y-auto pr-1">
                {selectedUser?.permitted_activities.map((act) => {
                  const isSuper = selectedUser.roles.some((r) => r.role_name === "super_admin");
                  const isPermitted = isSuper || act.is_permitted;

                  return (
                    <div
                      key={act.id}
                      className={`p-2.5 rounded-md border transition-colors flex items-center justify-between gap-2.5 ${
                        isPermitted
                          ? "bg-white border-slate-200 shadow-2xs"
                          : "bg-slate-50/50 border-slate-100 opacity-40"
                      }`}
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        <div
                          className={`flex h-6 w-6 items-center justify-center rounded-md text-[10px] font-bold font-mono shrink-0 ${
                            isPermitted
                              ? "bg-slate-100 text-slate-800 border border-slate-200"
                              : "bg-slate-100 text-slate-400"
                          }`}
                        >
                          {act.category[0].toUpperCase()}
                        </div>
                        <div className="flex flex-col min-w-0">
                          <span className="font-semibold text-xs text-slate-900 truncate font-mono">
                            {act.name}
                          </span>
                          <span className="text-[10px] text-slate-500 line-clamp-1">
                            {act.description}
                          </span>
                        </div>
                      </div>
                      <div className="shrink-0 flex items-center gap-2">
                        <span className="text-[10px] bg-slate-100 text-slate-600 px-1.5 py-0.5 rounded-md font-mono border border-slate-200">
                          {act.group}
                        </span>
                        {isPermitted ? (
                          <span className="rounded-md bg-emerald-50 text-emerald-800 border border-emerald-200 px-1.5 py-0.5 text-[10px] font-mono font-semibold flex items-center gap-1">
                            <CheckCircle2 className="h-3 w-3 text-emerald-600" />
                            Permitted
                          </span>
                        ) : (
                          <span className="rounded-md bg-slate-100 text-slate-400 border border-slate-200 px-1.5 py-0.5 text-[10px] font-mono flex items-center gap-1">
                            <XCircle className="h-3 w-3" />
                            Restricted
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {/* Role Assignments List */}
            {accessSubTab === "roles" && (
              <div className="space-y-2 max-h-[380px] overflow-y-auto pr-1">
                {selectedUser?.roles.length === 0 ? (
                  <div className="text-center py-6 text-xs text-slate-400 font-mono">
                    This user currently has no roles assigned. Click "Assign Role" to grant access.
                  </div>
                ) : (
                  selectedUser?.roles.map((r) => (
                    <div
                      key={r.id}
                      className="p-2.5 rounded-md border border-slate-200 bg-white flex items-center justify-between shadow-2xs"
                    >
                      <div className="flex items-center gap-2.5">
                        <div className="h-7 w-7 rounded-md bg-slate-100 text-slate-800 border border-slate-200 flex items-center justify-center font-bold text-xs">
                          <ShieldCheck className="h-3.5 w-3.5" />
                        </div>
                        <div className="flex flex-col">
                          <span className="font-semibold text-xs font-mono text-slate-900">{r.role_name}</span>
                          <span className="text-[10px] text-slate-400 flex items-center gap-1 mt-0.5 font-mono">
                            <Calendar className="h-3 w-3" /> Assigned {formatDateTime(r.assigned_at)}
                          </span>
                        </div>
                      </div>
                      <Button
                        size="sm"
                        variant="outline"
                        className="h-6.5 px-2 text-[10px] font-mono text-rose-700 hover:text-rose-800 hover:bg-rose-50 border-rose-200"
                        onClick={() => {
                          revoke.mutate({ userId: selectedUser.id, assignmentId: r.id });
                          setAccessProfileOpen(false);
                        }}
                      >
                        <Trash2 className="h-3 w-3 mr-1" /> Revoke
                      </Button>
                    </div>
                  ))
                )}
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" size="sm" className="h-8 text-xs font-mono" onClick={() => setAccessProfileOpen(false)}>
              Close
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Role Assignment Modal with Live Preview */}
      <Modal open={assignOpen} onOpenChange={setAssignOpen}>
        <ModalContent size="md">
          <ModalHeader className="border-b border-slate-100 pb-3">
            <ModalTitle className="text-sm font-semibold font-mono uppercase tracking-wider text-slate-800">
              Assign Role — {selectedUser?.full_name}
            </ModalTitle>
          </ModalHeader>
          <ModalBody className="space-y-3 pt-3">
            <div>
              <label className="text-xs font-semibold text-slate-700 mb-1 block">
                Select Platform Role:
              </label>
              <Select value={roleId} onValueChange={setRoleId}>
                <SelectTrigger className="h-8 text-xs font-mono" error={!!assignError}>
                  <SelectValue placeholder="Select platform role..." />
                </SelectTrigger>
                <SelectContent>
                  {roles.map((r) => (
                    <SelectItem key={r.id} value={String(r.id)}>
                      {r.name} {r.description ? `— ${r.description}` : ""}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {assignError && <p className="text-xs text-rose-600 font-mono mt-1">{assignError}</p>}
            </div>

            {/* Live capability preview */}
            {selectedRoleOption && (
              <div className="rounded-md border border-slate-200 bg-slate-50/70 p-3 space-y-1.5 text-xs font-mono">
                <div className="font-semibold text-slate-900 flex items-center gap-1.5">
                  <ShieldCheck className="h-3.5 w-3.5 text-slate-800" />
                  Access Preview: {selectedRoleOption.name}
                </div>
                <p className="text-slate-600 text-[11px] leading-relaxed font-sans">
                  {selectedRoleOption.description ||
                    "User will be granted permissions to navigation modules and operational capabilities configured in this role."}
                </p>
                <div className="pt-1 flex items-center gap-1.5">
                  <span className="rounded-md bg-slate-100 text-slate-800 border border-slate-200 px-1.5 py-0.5 text-[10px] font-medium">
                    {selectedRoleOption.name === "super_admin"
                      ? "12 Modules Granted"
                      : `${selectedRoleOption.accessible_menu_count || "Configured"} Modules Granted`}
                  </span>
                  <span className="rounded-md bg-slate-100 text-slate-800 border border-slate-200 px-1.5 py-0.5 text-[10px] font-medium">
                    {selectedRoleOption.name === "super_admin"
                      ? "Full Access (Wildcard *)"
                      : `${selectedRoleOption.permitted_activity_count || "Configured"} Actions Permitted`}
                  </span>
                </div>
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" size="sm" className="h-8 text-xs font-mono" onClick={() => setAssignOpen(false)}>
              Cancel
            </Button>
            <Button size="sm" className="h-8 text-xs font-medium" disabled={!roleId} loading={assign.isPending} onClick={() => assign.mutate()}>
              Confirm &amp; Assign Role
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </div>
  );
}

