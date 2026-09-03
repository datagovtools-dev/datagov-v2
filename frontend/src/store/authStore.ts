import { create } from "zustand";
import { persist } from "zustand/middleware";

export interface AuthUser {
  id: string;
  email: string;
  full_name: string;
  is_active: boolean;
  is_super_admin: boolean;
  roles?: string[];
  permissions?: string[];
  accessible_menus?: string[];
  permitted_activities?: string[];
}

interface AuthState {
  user: AuthUser | null;
  accessToken: string | null;
  setAuth: (user: AuthUser, token: string) => void;
  setToken: (token: string) => void;
  hasRole: (role: string) => boolean;
  hasPermission: (permission: string) => boolean;
  canAccessMenu: (menuId: string) => boolean;
  canPerformActivity: (activityId: string) => boolean;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      accessToken: null,
      setAuth: (user, accessToken) => set({ user, accessToken }),
      setToken: (accessToken) => set({ accessToken }),
      hasRole: (role: string) => {
        const u = get().user;
        if (!u) return false;
        if (u.is_super_admin || (u.roles && u.roles.includes("super_admin"))) return true;
        return (u.roles || []).includes(role);
      },
      hasPermission: (permission: string) => {
        const u = get().user;
        if (!u) return false;
        if (u.is_super_admin || (u.permissions && u.permissions.includes("*"))) return true;
        return (u.permissions || []).includes(permission);
      },
      canAccessMenu: (menuId: string) => {
        const u = get().user;
        if (!u) return false;
        if (u.is_super_admin || (u.permissions && u.permissions.includes("*"))) return true;
        return (u.accessible_menus || []).includes(menuId);
      },
      canPerformActivity: (activityId: string) => {
        const u = get().user;
        if (!u) return false;
        if (u.is_super_admin || (u.permissions && u.permissions.includes("*"))) return true;
        return (u.permitted_activities || []).includes(activityId);
      },
      logout: () => {
        set({ user: null, accessToken: null });
        fetch("/api/v1/auth/logout", { method: "POST", credentials: "include" }).catch(() => null);
        window.location.assign("/login");
      },
    }),
    {
      name: "auth",
      partialize: (state) => ({ user: state.user }),
    },
  ),
);
