import { create } from "zustand";
import { persist } from "zustand/middleware";

interface AuthUser {
  id: string;
  email: string;
  full_name: string;
  is_active: boolean;
  is_super_admin: boolean;
}

interface AuthState {
  user: AuthUser | null;
  accessToken: string | null;
  setAuth: (user: AuthUser, token: string) => void;
  setToken: (token: string) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      setAuth: (user, accessToken) => set({ user, accessToken }),
      setToken: (accessToken) => set({ accessToken }),
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
