"use client";

import * as React from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Plus,
  Pencil,
  Trash2,
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
  SlidersHorizontal,
  Lock,
  Save,
  RotateCcw,
  CheckSquare,
  Square,
  AlertTriangle,
  KeyRound,
} from "lucide-react";
import { api } from "@/lib/api";
import { Button } from "@/components/ui/Button";
import { Badge } from "@/components/ui/Badge";
import { Input } from "@/components/ui/Input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/Table";
import { Modal, ModalContent, ModalHeader, ModalTitle, ModalBody, ModalFooter } from "@/components/ui/Modal";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/Card";
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

interface Role {
  id: number;
  name: string;
  description: string | null;
  created_at: string;
  user_count: number;
  accessible_menu_count: number;
  permitted_activity_count: number;
  menus: MenuAccessItem[];
  activities: ActivityItem[];
}

interface RoleMatrixEntry {
  role_id: number;
  role_name: string;
  role_description: string | null;
  user_count: number;
  accessible_menus: string[];
  permitted_activities: string[];
}

interface AccessMatrixData {
  menus: {
    id: string;
    label: string;
    href: string;
    group: string;
    icon: string;
    description: string;
  }[];
  activities: {
    id: string;
    name: string;
    group: string;
    category: string;
    description: string;
    required_permission: string | null;
  }[];
  roles: RoleMatrixEntry[];
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

export default function RolesPage() {
  const qc = useQueryClient();
  const [activeTab, setActiveTab] = React.useState<"roles" | "matrix">("roles");
  const [modalOpen, setModalOpen] = React.useState(false);
  const [inspectOpen, setInspectOpen] = React.useState(false);
  const [inspectSubTab, setInspectSubTab] = React.useState<"menus" | "activities">("menus");
  const [editing, setEditing] = React.useState<Role | null>(null);
  const [viewing, setViewing] = React.useState<Role | null>(null);
  const [name, setName] = React.useState("");
  const [desc, setDesc] = React.useState("");
  const [error, setError] = React.useState("");
  const [searchFilter, setSearchFilter] = React.useState("");

  // Dedicated Role Permission Editor Modal state
  const [permModalOpen, setPermModalOpen] = React.useState(false);
  const [editingPermRole, setEditingPermRole] = React.useState<Role | null>(null);
  const [permSubTab, setPermSubTab] = React.useState<"menus" | "activities">("menus");
  const [selectedMenus, setSelectedMenus] = React.useState<string[]>([]);
  const [selectedActivities, setSelectedActivities] = React.useState<string[]>([]);

  // Interactive Matrix Mode State
  const [isMatrixEditMode, setIsMatrixEditMode] = React.useState(false);
  const [matrixDraft, setMatrixDraft] = React.useState<
    Record<number, { accessible_menus: string[]; permitted_activities: string[] }>
  >({});

  const { data: roles = [], isLoading: rolesLoading } = useQuery<Role[]>({
    queryKey: ["roles"],
    queryFn: () => api.get<Role[]>("/rbac/roles"),
  });

  const { data: matrixData, isLoading: matrixLoading } = useQuery<AccessMatrixData>({
    queryKey: ["access-matrix"],
    queryFn: () => api.get<AccessMatrixData>("/rbac/access-matrix"),
  });

  // Sync draft state whenever matrixData is loaded or refetched
  React.useEffect(() => {
    if (matrixData?.roles) {
      const initialDraft: Record<
        number,
        { accessible_menus: string[]; permitted_activities: string[] }
      > = {};
      matrixData.roles.forEach((r) => {
        initialDraft[r.role_id] = {
          accessible_menus: [...r.accessible_menus],
          permitted_activities: [...r.permitted_activities],
        };
      });
      setMatrixDraft(initialDraft);
    }
  }, [matrixData]);

  // Mutations
  const saveRoleMutation = useMutation({
    mutationFn: () =>
      editing
        ? api.put(`/rbac/roles/${editing.id}`, { name, description: desc })
        : api.post("/rbac/roles", { name, description: desc }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["roles"] });
      qc.invalidateQueries({ queryKey: ["access-matrix"] });
      toast.success(editing ? "Role berhasil diperbarui" : "Role baru berhasil dibuat");
      closeModal();
    },
    onError: (e: any) => {
      setError(e.message);
      toast.error(e.message || "Gagal menyimpan role");
    },
  });

  const saveSingleRolePerms = useMutation({
    mutationFn: (roleId: number) =>
      api.put(`/rbac/roles/${roleId}/permissions`, {
        accessible_menus: selectedMenus,
        permitted_activities: selectedActivities,
      }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["roles"] });
      qc.invalidateQueries({ queryKey: ["access-matrix"] });
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success(`Hak akses untuk ${editingPermRole?.name} berhasil disimpan`);
      setPermModalOpen(false);
    },
    onError: (e: any) => {
      toast.error(e.message || "Gagal menyimpan izin role");
    },
  });

  const resetRoleDefaults = useMutation({
    mutationFn: (roleId: number) => api.post(`/rbac/roles/${roleId}/reset-defaults`, {}),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["roles"] });
      qc.invalidateQueries({ queryKey: ["access-matrix"] });
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success("Izin role berhasil direset ke standar pabrik");
      setPermModalOpen(false);
    },
    onError: (e: any) => {
      toast.error(e.message || "Gagal mereset izin role");
    },
  });

  const saveMatrixMutation = useMutation({
    mutationFn: () => {
      const payload = Object.entries(matrixDraft).map(([roleIdStr, data]) => ({
        role_id: parseInt(roleIdStr),
        accessible_menus: data.accessible_menus,
        permitted_activities: data.permitted_activities,
      }));
      return api.put("/rbac/access-matrix", { roles: payload });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["access-matrix"] });
      qc.invalidateQueries({ queryKey: ["roles"] });
      qc.invalidateQueries({ queryKey: ["users"] });
      toast.success("Seluruh perubahan Matriks Hak Akses berhasil disimpan!");
      setIsMatrixEditMode(false);
    },
    onError: (e: any) => {
      toast.error(e.message || "Gagal menyimpan matriks akses");
    },
  });

  const del = useMutation({
    mutationFn: (id: number) => api.delete(`/rbac/roles/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["roles"] });
      qc.invalidateQueries({ queryKey: ["access-matrix"] });
      toast.success("Role berhasil dihapus");
    },
    onError: (e: any) => {
      toast.error(e.message || "Gagal menghapus role");
    },
  });

  function openNew() {
    setEditing(null);
    setName("");
    setDesc("");
    setError("");
    setModalOpen(true);
  }
  function openEdit(r: Role) {
    setEditing(r);
    setName(r.name);
    setDesc(r.description ?? "");
    setError("");
    setModalOpen(true);
  }
  function closeModal() {
    setModalOpen(false);
    setEditing(null);
  }

  function openPermEditor(role: Role) {
    setEditingPermRole(role);
    setSelectedMenus(role.menus.filter((m) => m.is_accessible).map((m) => m.id));
    setSelectedActivities(role.activities.filter((a) => a.is_permitted).map((a) => a.id));
    setPermSubTab("menus");
    setPermModalOpen(true);
  }

  // Interactive Matrix Handlers
  const toggleMatrixMenu = (roleId: number, menuId: string) => {
    setMatrixDraft((prev) => {
      const current = prev[roleId]?.accessible_menus || [];
      const updated = current.includes(menuId)
        ? current.filter((id) => id !== menuId)
        : [...current, menuId];
      return {
        ...prev,
        [roleId]: {
          ...(prev[roleId] || { permitted_activities: [] }),
          accessible_menus: updated,
        },
      };
    });
  };

  const toggleMatrixActivity = (roleId: number, actId: string) => {
    setMatrixDraft((prev) => {
      const current = prev[roleId]?.permitted_activities || [];
      const updated = current.includes(actId)
        ? current.filter((id) => id !== actId)
        : [...current, actId];
      return {
        ...prev,
        [roleId]: {
          ...(prev[roleId] || { accessible_menus: [] }),
          permitted_activities: updated,
        },
      };
    });
  };

  const selectAllForRole = (roleId: number) => {
    if (!matrixData) return;
    setMatrixDraft((prev) => ({
      ...prev,
      [roleId]: {
        accessible_menus: matrixData.menus.map((m) => m.id),
        permitted_activities: matrixData.activities.map((a) => a.id),
      },
    }));
  };

  const clearAllForRole = (roleId: number) => {
    setMatrixDraft((prev) => ({
      ...prev,
      [roleId]: {
        accessible_menus: ["dashboard"], // keep dashboard minimum
        permitted_activities: [],
      },
    }));
  };

  const resetMatrixDraft = () => {
    if (matrixData?.roles) {
      const initialDraft: Record<
        number,
        { accessible_menus: string[]; permitted_activities: string[] }
      > = {};
      matrixData.roles.forEach((r) => {
        initialDraft[r.role_id] = {
          accessible_menus: [...r.accessible_menus],
          permitted_activities: [...r.permitted_activities],
        };
      });
      setMatrixDraft(initialDraft);
    }
  };

  // Count changed cells in matrix
  const changedCount = React.useMemo(() => {
    if (!matrixData?.roles) return 0;
    let changes = 0;
    matrixData.roles.forEach((r) => {
      const draft = matrixDraft[r.role_id];
      if (!draft) return;
      // Compare menus
      const originalMenus = new Set(r.accessible_menus);
      const draftMenus = new Set(draft.accessible_menus);
      draft.accessible_menus.forEach((m) => {
        if (!originalMenus.has(m)) changes++;
      });
      r.accessible_menus.forEach((m) => {
        if (!draftMenus.has(m)) changes++;
      });
      // Compare activities
      const originalActs = new Set(r.permitted_activities);
      const draftActs = new Set(draft.permitted_activities);
      draft.permitted_activities.forEach((a) => {
        if (!originalActs.has(a)) changes++;
      });
      r.permitted_activities.forEach((a) => {
        if (!draftActs.has(a)) changes++;
      });
    });
    return changes;
  }, [matrixData, matrixDraft]);

  const isSeedRole = (roleName: string) =>
    [
      "super_admin",
      "compliance_officer",
      "dpo",
      "data_governance_officer",
      "project_manager",
      "data_steward",
      "data_owner",
      "requester",
      "auditor",
      "viewer",
    ].includes(roleName);

  const filteredRoles = roles.filter(
    (r) =>
      r.name.toLowerCase().includes(searchFilter.toLowerCase()) ||
      (r.description && r.description.toLowerCase().includes(searchFilter.toLowerCase()))
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/80 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">Role & Hak Akses (RBAC)</h1>
            <Badge variant="info">Interactive Control Plane</Badge>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Konfigurasi definisi role, pemetaan menu navigasi yang dapat diakses, dan rincian aktivitas bisnis sistem
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center bg-slate-100/80 p-1 rounded-xl border border-slate-200/70 text-xs font-semibold">
            <button
              onClick={() => setActiveTab("roles")}
              className={`px-3 py-1.5 rounded-lg transition-all ${
                activeTab === "roles"
                  ? "bg-white text-slate-900 shadow-2xs"
                  : "text-slate-500 hover:text-slate-800"
              }`}
            >
              Daftar Role ({roles.length})
            </button>
            <button
              onClick={() => setActiveTab("matrix")}
              className={`px-3 py-1.5 rounded-lg transition-all flex items-center gap-1.5 ${
                activeTab === "matrix"
                  ? "bg-white text-slate-900 shadow-2xs"
                  : "text-slate-500 hover:text-slate-800"
              }`}
            >
              <SlidersHorizontal className="h-3.5 w-3.5" />
              Matriks Akses Global
            </button>
          </div>
          <Button onClick={openNew}>
            <Plus className="h-4 w-4 mr-1.5" /> Tambah Role
          </Button>
        </div>
      </div>

      {activeTab === "roles" && (
        <div className="space-y-4">
          {/* Quick Metrics Bar */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Card>
              <CardContent className="p-4 flex items-center gap-3.5">
                <div className="h-10 w-10 rounded-xl bg-amber-50 border border-amber-200/70 flex items-center justify-center text-amber-600">
                  <ShieldCheck className="h-5 w-5" />
                </div>
                <div>
                  <div className="text-xs text-slate-500 font-medium">Total Role Terdaftar</div>
                  <div className="text-lg font-bold text-slate-900">{roles.length} Role</div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 flex items-center gap-3.5">
                <div className="h-10 w-10 rounded-xl bg-blue-50 border border-blue-200/70 flex items-center justify-center text-blue-600">
                  <Users className="h-5 w-5" />
                </div>
                <div>
                  <div className="text-xs text-slate-500 font-medium">Total Pengguna Terpetakan</div>
                  <div className="text-lg font-bold text-slate-900">
                    {roles.reduce((acc, r) => acc + (r.user_count || 0), 0)} Penugasan
                  </div>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4 flex items-center gap-3.5">
                <div className="h-10 w-10 rounded-xl bg-emerald-50 border border-emerald-200/70 flex items-center justify-center text-emerald-600">
                  <Layers className="h-5 w-5" />
                </div>
                <div>
                  <div className="text-xs text-slate-500 font-medium">Cakupan Menu & Modul</div>
                  <div className="text-lg font-bold text-slate-900">12 Menu • 22 Aktivitas</div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Search bar */}
          <div className="flex items-center justify-between gap-4">
            <div className="w-full max-w-sm">
              <Input
                placeholder="Cari role atau deskripsi…"
                value={searchFilter}
                onChange={(e) => setSearchFilter(e.target.value)}
              />
            </div>
            <div className="text-xs text-slate-500 font-medium">
              Menampilkan {filteredRoles.length} dari {roles.length} role
            </div>
          </div>

          {/* Roles Table */}
          <Card>
            <CardContent className="p-0 overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Role & Tipe</TableHead>
                    <TableHead>Deskripsi</TableHead>
                    <TableHead className="text-center">Pengguna</TableHead>
                    <TableHead>Akses Menu</TableHead>
                    <TableHead>Aktivitas Bisnis</TableHead>
                    <TableHead className="w-48 text-right">Aksi</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rolesLoading ? (
                    <TableRow>
                      <TableCell colSpan={6} className="p-0">
                        <TableSkeleton rows={4} cols={6} />
                      </TableCell>
                    </TableRow>
                  ) : filteredRoles.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center py-12 text-slate-400 text-xs">
                        Tidak ada role yang sesuai dengan filter pencarian.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredRoles.map((role) => {
                      const accessibleMenus = role.menus.filter((m) => m.is_accessible);
                      const permittedActs = role.activities.filter((a) => a.is_permitted);

                      return (
                        <TableRow key={role.id} className="hover:bg-slate-50/70 transition-colors">
                          <TableCell>
                            <div className="flex flex-col gap-1">
                              <div className="flex items-center gap-2">
                                <span className="font-bold text-slate-900 text-xs tracking-tight">
                                  {role.name}
                                </span>
                                {isSeedRole(role.name) ? (
                                  <span className="rounded-md bg-slate-100 text-slate-700 border border-slate-200 px-1.5 py-0.2 text-[10px] font-mono font-medium">
                                    system
                                  </span>
                                ) : (
                                  <span className="rounded-md bg-slate-100 text-slate-700 border border-slate-200 px-1.5 py-0.2 text-[10px] font-mono font-medium">
                                    custom
                                  </span>
                                )}
                              </div>
                              <span className="text-[10px] text-slate-400 font-mono">
                                Dibuat {formatDateTime(role.created_at)}
                              </span>
                            </div>
                          </TableCell>
                          <TableCell>
                            <span className="text-xs text-slate-600 max-w-xs line-clamp-2 leading-relaxed">
                              {role.description ?? "—"}
                            </span>
                          </TableCell>
                          <TableCell className="text-center">
                            <span className="inline-flex items-center gap-1 rounded-md bg-slate-100 px-2 py-0.5 text-xs font-mono font-semibold text-slate-700 border border-slate-200">
                              <Users className="h-3 w-3 text-slate-500" />
                              {role.user_count || 0}
                            </span>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1.5 flex-wrap max-w-xs">
                              {role.name === "super_admin" ? (
                                <span className="rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 text-[11px] font-semibold">
                                  Semua Menu (12/12)
                                </span>
                              ) : (
                                <>
                                  <span className="rounded-md bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 text-[11px] font-semibold">
                                    {accessibleMenus.length} Menu Terbuka
                                  </span>
                                  <div className="flex gap-1">
                                    {accessibleMenus.slice(0, 3).map((m) => (
                                      <span
                                        key={m.id}
                                        className="text-[10px] bg-slate-100 text-slate-700 px-1.5 py-0.5 rounded-md border border-slate-200 truncate max-w-[90px] font-mono"
                                        title={m.label}
                                      >
                                        {m.label.split("(")[0]}
                                      </span>
                                    ))}
                                    {accessibleMenus.length > 3 && (
                                      <span className="text-[10px] text-slate-400 font-semibold font-mono">
                                        +{accessibleMenus.length - 3} lagi
                                      </span>
                                    )}
                                  </div>
                                </>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center gap-1.5">
                              {role.name === "super_admin" ? (
                                <span className="rounded-md bg-purple-50 text-purple-700 border border-purple-200 px-2 py-0.5 text-[11px] font-bold">
                                  Akses Penuh (Wildcard *)
                                </span>
                              ) : (
                                <span className="rounded-md bg-slate-100 text-slate-700 border border-slate-200 px-2 py-0.5 text-[11px] font-semibold">
                                  {permittedActs.length} dari {role.activities.length} Aktivitas
                                </span>
                              )}
                            </div>
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex items-center justify-end gap-1">
                              {/* Edit Permissions Button */}
                              {role.name !== "super_admin" && (
                                <Button
                                  size="sm"
                                  variant="outline"
                                  title="Edit Izin Menu & Aktivitas Role Ini"
                                  onClick={() => openPermEditor(role)}
                                  className="h-7 px-2 text-xs font-semibold text-amber-700 border-amber-200 hover:bg-amber-50"
                                >
                                  <KeyRound className="h-3.5 w-3.5 mr-1" />
                                  Edit Izin
                                </Button>
                              )}
                              <Button
                                size="sm"
                                variant="ghost"
                                title="Periksa Menu & Aktivitas Lengkap"
                                onClick={() => {
                                  setViewing(role);
                                  setInspectSubTab("menus");
                                  setInspectOpen(true);
                                }}
                                className="h-7 px-2 text-xs text-slate-600"
                              >
                                <ShieldCheck className="h-3.5 w-3.5 mr-1 text-slate-500" />
                                Rincian
                              </Button>
                              <Button
                                size="icon"
                                variant="ghost"
                                onClick={() => openEdit(role)}
                                className="h-7 w-7 text-slate-500 hover:text-slate-900"
                              >
                                <Pencil className="h-3.5 w-3.5" />
                              </Button>
                              {!isSeedRole(role.name) && (
                                <Button
                                  size="icon"
                                  variant="ghost"
                                  className="h-7 w-7 text-rose-500 hover:text-rose-700 hover:bg-rose-50"
                                  onClick={() => del.mutate(role.id)}
                                >
                                  <Trash2 className="h-3.5 w-3.5" />
                                </Button>
                              )}
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
        </div>
      )}

      {/* Global Interactive Access Control Matrix View */}
      {activeTab === "matrix" && (
        <div className="space-y-4">
          <Card className="border-slate-200">
            <CardHeader className="border-b border-slate-100 bg-slate-50/50 pb-4">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div>
                  <div className="flex items-center gap-2">
                    <CardTitle className="text-base flex items-center gap-2">
                      <SlidersHorizontal className="h-4 w-4 text-amber-600" />
                      Matriks Interaktif Akses Role vs Menu & Aktivitas
                    </CardTitle>
                    {isMatrixEditMode && (
                      <span className="rounded-full bg-amber-500 text-white px-2.5 py-0.5 text-[10px] font-bold animate-pulse">
                        Mode Edit Aktif
                      </span>
                    )}
                  </div>
                  <CardDescription className="text-xs mt-1">
                    {isMatrixEditMode
                      ? "Klik pada ikon cell untuk mencentang (memberikan akses) atau mematikan (membatasi) izin role secara interaktif."
                      : "Tabel visual komparatif hak akses seluruh role. Klik 'Mode Edit Matriks' untuk mengubah hak akses."}
                  </CardDescription>
                </div>

                {/* Edit Mode Toggle & Action Bar */}
                <div className="flex items-center gap-2.5 shrink-0">
                  {!isMatrixEditMode ? (
                    <Button
                      onClick={() => setIsMatrixEditMode(true)}
                      className="bg-amber-600 hover:bg-amber-700 text-white shadow-sm"
                    >
                      <Pencil className="h-3.5 w-3.5 mr-1.5" />
                      Mode Edit Matriks
                    </Button>
                  ) : (
                    <div className="flex items-center gap-2">
                      <Button
                        variant="secondary"
                        size="sm"
                        onClick={() => {
                          resetMatrixDraft();
                          setIsMatrixEditMode(false);
                        }}
                      >
                        Batal
                      </Button>
                      <Button
                        size="sm"
                        loading={saveMatrixMutation.isPending}
                        onClick={() => saveMatrixMutation.mutate()}
                        className="bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm font-bold"
                      >
                        <Save className="h-3.5 w-3.5 mr-1.5" />
                        Simpan Matriks {changedCount > 0 && `(${changedCount} Perubahan)`}
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            </CardHeader>

            <CardContent className="p-0 overflow-x-auto">
              {matrixLoading || !matrixData ? (
                <div className="p-6">
                  <TableSkeleton rows={8} cols={7} />
                </div>
              ) : (
                <div className="min-w-[960px]">
                  {/* Sticky Banner when in edit mode with changes */}
                  {isMatrixEditMode && changedCount > 0 && (
                    <div className="sticky top-0 z-10 bg-amber-500 text-white px-4 py-2 text-xs font-bold flex items-center justify-between shadow-md">
                      <span className="flex items-center gap-2">
                        <AlertTriangle className="h-4 w-4" />
                        Terdapat {changedCount} perubahan izin yang belum disimpan.
                      </span>
                      <div className="flex items-center gap-2">
                        <button
                          onClick={resetMatrixDraft}
                          className="px-2.5 py-1 rounded bg-amber-600 hover:bg-amber-700 text-white text-[11px] font-semibold flex items-center gap-1"
                        >
                          <RotateCcw className="h-3 w-3" /> Reset
                        </button>
                        <button
                          onClick={() => saveMatrixMutation.mutate()}
                          disabled={saveMatrixMutation.isPending}
                          className="px-3 py-1 rounded bg-white text-amber-900 hover:bg-amber-50 text-[11px] font-bold flex items-center gap-1 shadow-2xs"
                        >
                          <Save className="h-3 w-3" /> Simpan Sekarang
                        </button>
                      </div>
                    </div>
                  )}

                  {/* 1. Menu Access Section */}
                  <div className="bg-slate-100/90 px-4 py-2.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider border-y border-slate-200 flex items-center justify-between">
                    <span>1. Hak Akses Menu Navigasi (Navigation Access)</span>
                    {isMatrixEditMode && (
                      <span className="text-[10px] text-amber-700 normal-case font-semibold">
                        💡 Klik ikon pada kolom role untuk mengubah akses menu
                      </span>
                    )}
                  </div>
                  <table className="w-full text-xs text-left border-collapse">
                    <thead>
                      <tr className="border-b border-slate-200 bg-slate-50/80">
                        <th className="p-3 font-bold text-slate-800 w-64">Nama Menu & Rute</th>
                        {matrixData.roles.map((r) => {
                          const isSuper = r.role_name === "super_admin";
                          return (
                            <th
                              key={r.role_id}
                              className="p-3 text-center font-bold text-slate-800 min-w-[100px]"
                            >
                              <div className="flex flex-col items-center gap-1">
                                <span
                                  className="truncate max-w-[100px] text-xs font-bold"
                                  title={r.role_name}
                                >
                                  {r.role_name}
                                </span>
                                {isSuper ? (
                                  <span className="text-[9px] bg-purple-100 text-purple-800 px-1.5 py-0.5 rounded font-mono font-bold flex items-center gap-0.5">
                                    <Lock className="h-2.5 w-2.5" /> Wildcard
                                  </span>
                                ) : isMatrixEditMode ? (
                                  <div className="flex items-center gap-1 mt-0.5">
                                    <button
                                      type="button"
                                      title="Pilih Semua Menu"
                                      onClick={() => selectAllForRole(r.role_id)}
                                      className="p-0.5 rounded hover:bg-slate-200 text-slate-600 text-[10px]"
                                    >
                                      All
                                    </button>
                                    <span className="text-slate-300">|</span>
                                    <button
                                      type="button"
                                      title="Hapus Semua Menu"
                                      onClick={() => clearAllForRole(r.role_id)}
                                      className="p-0.5 rounded hover:bg-slate-200 text-slate-600 text-[10px]"
                                    >
                                      None
                                    </button>
                                  </div>
                                ) : null}
                              </div>
                            </th>
                          );
                        })}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {matrixData.menus.map((menu) => {
                        const IconComp = ICON_MAP[menu.icon] || FolderOpen;
                        return (
                          <tr key={menu.id} className="hover:bg-slate-50/60 transition-colors">
                            <td className="p-3">
                              <div className="flex items-center gap-2.5">
                                <div className="p-1 rounded bg-slate-100 text-slate-600 shrink-0">
                                  <IconComp className="h-3.5 w-3.5" />
                                </div>
                                <div className="flex flex-col min-w-0">
                                  <span className="font-semibold text-slate-900 truncate">
                                    {menu.label}
                                  </span>
                                  <span className="text-[10px] text-slate-400 font-mono">
                                    {menu.href}
                                  </span>
                                </div>
                              </div>
                            </td>
                            {matrixData.roles.map((r) => {
                              const isSuper = r.role_name === "super_admin";
                              const currentSelected =
                                matrixDraft[r.role_id]?.accessible_menus || r.accessible_menus;
                              const hasAccess = isSuper || currentSelected.includes(menu.id);

                              return (
                                <td key={r.role_id} className="p-2.5 text-center">
                                  {isSuper ? (
                                    <span
                                      className="inline-flex items-center justify-center h-6 w-6 rounded-md bg-slate-100 text-slate-700 border border-slate-200"
                                      title="Super Admin memiliki akses mutlak"
                                    >
                                      <CheckCircle2 className="h-3.5 w-3.5" />
                                    </span>
                                  ) : isMatrixEditMode ? (
                                    <button
                                      type="button"
                                      onClick={() => toggleMatrixMenu(r.role_id, menu.id)}
                                      className={`inline-flex items-center justify-center h-6.5 w-6.5 rounded-md border transition-colors cursor-pointer ${
                                        hasAccess
                                          ? "bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100"
                                          : "bg-slate-50 text-slate-300 border-slate-200 hover:bg-slate-100 hover:text-slate-500"
                                      }`}
                                      title={`Klik untuk ${hasAccess ? "mencabut" : "memberikan"} akses`}
                                    >
                                      {hasAccess ? (
                                        <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
                                      ) : (
                                        <XCircle className="h-3.5 w-3.5 text-slate-300" />
                                      )}
                                    </button>
                                  ) : hasAccess ? (
                                    <span className="inline-flex items-center justify-center h-5.5 w-5.5 rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200">
                                      <CheckCircle2 className="h-3 w-3" />
                                    </span>
                                  ) : (
                                    <span className="inline-flex items-center justify-center h-5.5 w-5.5 rounded-md bg-slate-50 text-slate-300">
                                      <XCircle className="h-3 w-3" />
                                    </span>
                                  )}
                                </td>
                              );
                            })}
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>

                  {/* 2. Business Activity Section */}
                  <div className="bg-slate-100/90 px-4 py-2.5 text-[11px] font-bold text-slate-700 uppercase tracking-wider border-y border-slate-200 mt-4 flex items-center justify-between font-mono">
                    <span>2. Izin Aktivitas Bisnis & Governance (Operational Capabilities)</span>
                    {isMatrixEditMode && (
                      <span className="text-[10px] text-slate-500 normal-case font-mono">
                        Klik ikon untuk mengaktifkan/menonaktifkan kemampuan bisnis
                      </span>
                    )}
                  </div>
                  <table className="w-full text-xs text-left border-collapse">
                    <thead>
                      <tr className="border-b border-slate-200 bg-slate-50/80">
                        <th className="p-3 font-bold text-slate-800 w-64">Nama Aktivitas</th>
                        {matrixData.roles.map((r) => (
                          <th key={r.role_id} className="p-3 text-center font-bold text-slate-800">
                            <span className="truncate max-w-[100px] text-xs font-mono" title={r.role_name}>
                              {r.role_name}
                            </span>
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {matrixData.activities.map((act) => (
                        <tr key={act.id} className="hover:bg-slate-50/60 transition-colors">
                          <td className="p-3">
                            <div className="flex flex-col">
                              <span className="font-medium text-slate-900">{act.name}</span>
                              <span className="text-[10px] text-slate-500 line-clamp-1">
                                {act.description}
                              </span>
                            </div>
                          </td>
                          {matrixData.roles.map((r) => {
                            const isSuper = r.role_name === "super_admin";
                            const currentSelected =
                              matrixDraft[r.role_id]?.permitted_activities ||
                              r.permitted_activities;
                            const isPermitted = isSuper || currentSelected.includes(act.id);

                            return (
                              <td key={r.role_id} className="p-2.5 text-center">
                                {isSuper ? (
                                  <span
                                    className="inline-flex items-center justify-center h-6 w-6 rounded-md bg-slate-100 text-slate-700 border border-slate-200"
                                    title="Super Admin memiliki izin mutlak"
                                  >
                                    <CheckCircle2 className="h-3.5 w-3.5" />
                                  </span>
                                ) : isMatrixEditMode ? (
                                  <button
                                    type="button"
                                    onClick={() => toggleMatrixActivity(r.role_id, act.id)}
                                    className={`inline-flex items-center justify-center h-6.5 w-6.5 rounded-md border transition-colors cursor-pointer ${
                                      isPermitted
                                        ? "bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100"
                                        : "bg-slate-50 text-slate-300 border-slate-200 hover:bg-slate-100 hover:text-slate-500"
                                    }`}
                                    title={`Klik untuk ${isPermitted ? "mencabut" : "memberikan"} izin`}
                                  >
                                    {isPermitted ? (
                                      <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
                                    ) : (
                                      <XCircle className="h-3.5 w-3.5 text-slate-300" />
                                    )}
                                  </button>
                                ) : isPermitted ? (
                                  <span className="inline-flex items-center justify-center h-5.5 w-5.5 rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200">
                                    <CheckCircle2 className="h-3 w-3" />
                                  </span>
                                ) : (
                                  <span className="inline-flex items-center justify-center h-5.5 w-5.5 rounded-md bg-slate-50 text-slate-300">
                                    <XCircle className="h-3 w-3" />
                                  </span>
                                )}
                              </td>
                            );
                          })}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}

      {/* Dedicated Role Permission Editor Modal */}
      <Modal open={permModalOpen} onOpenChange={setPermModalOpen}>
        <ModalContent size="lg">
          <ModalHeader className="border-b border-slate-100 pb-3">
            <div className="flex items-center justify-between">
              <div>
                <ModalTitle className="text-base flex items-center gap-2">
                  <KeyRound className="h-4 w-4 text-amber-600" />
                  Konfigurasi Izin & Hak Akses: {editingPermRole?.name}
                </ModalTitle>
                <p className="text-xs text-slate-500 mt-0.5">
                  Pilih menu navigasi dan aktivitas operasional yang diizinkan untuk role ini
                </p>
              </div>
              <Button
                size="sm"
                variant="outline"
                onClick={() => editingPermRole && resetRoleDefaults.mutate(editingPermRole.id)}
                loading={resetRoleDefaults.isPending}
                className="text-xs text-slate-600"
              >
                <RotateCcw className="h-3 w-3 mr-1" /> Reset Default
              </Button>
            </div>
          </ModalHeader>

          <ModalBody className="space-y-4 pt-4">
            {/* Sub-tabs */}
            <div className="flex border-b border-slate-200 text-xs font-semibold">
              <button
                onClick={() => setPermSubTab("menus")}
                className={`pb-2 px-3 border-b-2 transition-all ${
                  permSubTab === "menus"
                    ? "border-amber-600 text-amber-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Menu Navigasi ({selectedMenus.length}/12 Terpilih)
              </button>
              <button
                onClick={() => setPermSubTab("activities")}
                className={`pb-2 px-3 border-b-2 transition-all ${
                  permSubTab === "activities"
                    ? "border-amber-600 text-amber-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Aktivitas Bisnis ({selectedActivities.length}/22 Terpilih)
              </button>
            </div>

            {/* Menus Checkbox Grid */}
            {permSubTab === "menus" && (
              <div className="space-y-3 max-h-[380px] overflow-y-auto pr-1">
                <div className="flex items-center justify-between pb-1">
                  <span className="text-xs text-slate-500 font-medium">
                    Pilih menu yang dapat dilihat oleh pengguna dengan role ini
                  </span>
                  <div className="flex items-center gap-2 text-xs">
                    <button
                      type="button"
                      onClick={() =>
                        setSelectedMenus(matrixData?.menus.map((m) => m.id) || [])
                      }
                      className="text-amber-700 hover:underline font-semibold"
                    >
                      Pilih Semua
                    </button>
                    <span className="text-slate-300">|</span>
                    <button
                      type="button"
                      onClick={() => setSelectedMenus(["dashboard"])}
                      className="text-slate-500 hover:underline"
                    >
                      Kosongkan
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5">
                  {matrixData?.menus.map((menu) => {
                    const isChecked = selectedMenus.includes(menu.id);
                    const IconComp = ICON_MAP[menu.icon] || FolderOpen;

                    return (
                      <label
                        key={menu.id}
                        onClick={() => {
                          setSelectedMenus((prev) =>
                            prev.includes(menu.id)
                              ? prev.filter((id) => id !== menu.id)
                              : [...prev, menu.id]
                          );
                        }}
                        className={`p-3 rounded-xl border transition-all flex items-start gap-3 cursor-pointer select-none ${
                          isChecked
                            ? "bg-amber-50/50 border-amber-300/80 shadow-2xs"
                            : "bg-white border-slate-200 hover:border-slate-300 opacity-60"
                        }`}
                      >
                        <div className="pt-0.5">
                          {isChecked ? (
                            <CheckSquare className="h-4 w-4 text-amber-600" />
                          ) : (
                            <Square className="h-4 w-4 text-slate-400" />
                          )}
                        </div>
                        <div className="flex flex-col min-w-0 flex-1">
                          <div className="flex items-center gap-1.5">
                            <IconComp className="h-3.5 w-3.5 text-slate-600" />
                            <span className="font-bold text-xs text-slate-900 truncate">
                              {menu.label}
                            </span>
                          </div>
                          <span className="text-[10px] text-slate-400 font-mono mt-0.5">
                            {menu.href}
                          </span>
                          <p className="text-[11px] text-slate-500 mt-1 leading-snug">
                            {menu.description}
                          </p>
                        </div>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}

            {/* Activities Checkbox List */}
            {permSubTab === "activities" && (
              <div className="space-y-3 max-h-[380px] overflow-y-auto pr-1">
                <div className="flex items-center justify-between pb-1">
                  <span className="text-xs text-slate-500 font-medium">
                    Pilih izin aktivitas bisnis yang dapat dijalankan role ini
                  </span>
                  <div className="flex items-center gap-2 text-xs">
                    <button
                      type="button"
                      onClick={() =>
                        setSelectedActivities(matrixData?.activities.map((a) => a.id) || [])
                      }
                      className="text-amber-700 hover:underline font-semibold"
                    >
                      Pilih Semua
                    </button>
                    <span className="text-slate-300">|</span>
                    <button
                      type="button"
                      onClick={() => setSelectedActivities([])}
                      className="text-slate-500 hover:underline"
                    >
                      Kosongkan
                    </button>
                  </div>
                </div>

                <div className="space-y-2">
                  {matrixData?.activities.map((act) => {
                    const isChecked = selectedActivities.includes(act.id);

                    return (
                      <label
                        key={act.id}
                        onClick={() => {
                          setSelectedActivities((prev) =>
                            prev.includes(act.id)
                              ? prev.filter((id) => id !== act.id)
                              : [...prev, act.id]
                          );
                        }}
                        className={`p-3 rounded-xl border transition-all flex items-center justify-between gap-3 cursor-pointer select-none ${
                          isChecked
                            ? "bg-emerald-50/40 border-emerald-300 shadow-2xs"
                            : "bg-white border-slate-200 hover:border-slate-300 opacity-60"
                        }`}
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <div>
                            {isChecked ? (
                              <CheckSquare className="h-4 w-4 text-emerald-600" />
                            ) : (
                              <Square className="h-4 w-4 text-slate-400" />
                            )}
                          </div>
                          <div className="flex flex-col min-w-0">
                            <span className="font-bold text-xs text-slate-900 truncate">
                              {act.name}
                            </span>
                            <span className="text-[11px] text-slate-500 line-clamp-1">
                              {act.description}
                            </span>
                          </div>
                        </div>
                        <span className="text-[10px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded font-mono border border-slate-200 shrink-0">
                          {act.group}
                        </span>
                      </label>
                    );
                  })}
                </div>
              </div>
            )}
          </ModalBody>

          <ModalFooter>
            <Button variant="secondary" onClick={() => setPermModalOpen(false)}>
              Batal
            </Button>
            <Button
              loading={saveSingleRolePerms.isPending}
              onClick={() => editingPermRole && saveSingleRolePerms.mutate(editingPermRole.id)}
            >
              Simpan Izin Role
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Create / Edit Role Modal */}
      <Modal open={modalOpen} onOpenChange={setModalOpen}>
        <ModalContent>
          <ModalHeader>
            <ModalTitle>{editing ? "Edit Role" : "Buat Role Baru"}</ModalTitle>
          </ModalHeader>
          <ModalBody className="flex flex-col gap-4">
            <Input
              label="Nama Role"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. data_analyst"
              required
              error={error}
            />
            <Input
              label="Deskripsi Hak Akses"
              value={desc}
              onChange={(e) => setDesc(e.target.value)}
              placeholder="Jelaskan peran dan tanggung jawab role ini..."
            />
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" onClick={closeModal}>
              Batal
            </Button>
            <Button loading={saveRoleMutation.isPending} onClick={() => saveRoleMutation.mutate()}>
              Simpan Role
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>

      {/* Role Inspector Modal */}
      <Modal open={inspectOpen} onOpenChange={setInspectOpen}>
        <ModalContent size="lg">
          <ModalHeader className="border-b border-slate-100 pb-3">
            <div className="flex items-center justify-between">
              <div>
                <ModalTitle className="text-base flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-amber-600" />
                  Rincian Kemampuan Akses: {viewing?.name}
                </ModalTitle>
                <p className="text-xs text-slate-500 mt-0.5">{viewing?.description ?? "—"}</p>
              </div>
              <span className="rounded-full bg-amber-50 text-amber-800 border border-amber-200 px-3 py-1 text-xs font-bold">
                {viewing?.user_count || 0} Pengguna Aktif
              </span>
            </div>
          </ModalHeader>
          <ModalBody className="space-y-4 pt-4">
            {/* Sub-tabs */}
            <div className="flex border-b border-slate-200 text-xs font-semibold">
              <button
                onClick={() => setInspectSubTab("menus")}
                className={`pb-2 px-3 border-b-2 transition-all ${
                  inspectSubTab === "menus"
                    ? "border-amber-600 text-amber-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Menu yang Dapat Diakses (
                {viewing?.name === "super_admin"
                  ? "12"
                  : viewing?.menus.filter((m) => m.is_accessible).length}
                )
              </button>
              <button
                onClick={() => setInspectSubTab("activities")}
                className={`pb-2 px-3 border-b-2 transition-all ${
                  inspectSubTab === "activities"
                    ? "border-amber-600 text-amber-900 font-bold"
                    : "border-transparent text-slate-500 hover:text-slate-800"
                }`}
              >
                Aktivitas yang Diizinkan (
                {viewing?.name === "super_admin"
                  ? "22"
                  : viewing?.activities.filter((a) => a.is_permitted).length}
                )
              </button>
            </div>

            {inspectSubTab === "menus" && (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5 max-h-[380px] overflow-y-auto pr-1">
                {viewing?.menus.map((menu) => {
                  const hasAccess = viewing.name === "super_admin" || menu.is_accessible;
                  const IconComp = ICON_MAP[menu.icon] || FolderOpen;

                  return (
                    <div
                      key={menu.id}
                      className={`p-3 rounded-xl border transition-all flex items-start gap-3 ${
                        hasAccess
                          ? "bg-white border-slate-200/90 shadow-2xs"
                          : "bg-slate-50/50 border-slate-100 opacity-40"
                      }`}
                    >
                      <div
                        className={`p-2 rounded-lg shrink-0 ${
                          hasAccess
                            ? "bg-amber-50 text-amber-700 border border-amber-200/60"
                            : "bg-slate-200/70 text-slate-400"
                        }`}
                      >
                        <IconComp className="h-4 w-4" />
                      </div>
                      <div className="flex flex-col min-w-0 flex-1">
                        <div className="flex items-center justify-between gap-1">
                          <span className="font-bold text-xs text-slate-900 truncate">
                            {menu.label}
                          </span>
                          {hasAccess ? (
                            <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600 shrink-0" />
                          ) : (
                            <XCircle className="h-3.5 w-3.5 text-slate-300 shrink-0" />
                          )}
                        </div>
                        <span className="text-[10px] text-slate-400 font-mono mt-0.5">
                          {menu.href}
                        </span>
                        <p className="text-[11px] text-slate-500 mt-1 leading-snug">
                          {menu.description}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}

            {inspectSubTab === "activities" && (
              <div className="space-y-2 max-h-[380px] overflow-y-auto pr-1">
                {viewing?.activities.map((act) => {
                  const isPermitted = viewing.name === "super_admin" || act.is_permitted;

                  return (
                    <div
                      key={act.id}
                      className={`p-3 rounded-xl border transition-all flex items-center justify-between gap-3 ${
                        isPermitted
                          ? "bg-white border-slate-200/90 shadow-2xs"
                          : "bg-slate-50/50 border-slate-100 opacity-40"
                      }`}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div
                          className={`flex h-7 w-7 items-center justify-center rounded-lg text-xs font-bold shrink-0 ${
                            isPermitted
                              ? "bg-emerald-50 text-emerald-700 border border-emerald-200/70"
                              : "bg-slate-100 text-slate-400"
                          }`}
                        >
                          {act.category[0].toUpperCase()}
                        </div>
                        <div className="flex flex-col min-w-0">
                          <span className="font-bold text-xs text-slate-900 truncate">
                            {act.name}
                          </span>
                          <span className="text-[11px] text-slate-500 line-clamp-1">
                            {act.description}
                          </span>
                        </div>
                      </div>
                      <div className="shrink-0 flex items-center gap-2">
                        <span className="text-[10px] bg-slate-100 text-slate-600 px-2 py-0.5 rounded font-mono border border-slate-200">
                          {act.group}
                        </span>
                        {isPermitted ? (
                          <span className="rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 text-[10px] font-bold flex items-center gap-1">
                            <CheckCircle2 className="h-3 w-3 text-emerald-600" />
                            Diizinkan
                          </span>
                        ) : (
                          <span className="rounded-full bg-slate-100 text-slate-400 border border-slate-200 px-2 py-0.5 text-[10px] font-medium flex items-center gap-1">
                            <XCircle className="h-3 w-3" />
                            Dibatasi
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </ModalBody>
          <ModalFooter>
            <Button variant="secondary" onClick={() => setInspectOpen(false)}>
              Tutup
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </div>
  );
}


