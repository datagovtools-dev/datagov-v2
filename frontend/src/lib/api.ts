import { useAuthStore } from "@/store/authStore";

const BASE = "/api/v1";

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = useAuthStore.getState().accessToken;
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(init.headers as Record<string, string> ?? {}),
  };

  const res = await fetch(`${BASE}${path}`, { ...init, headers, credentials: "include" });

  // Try token refresh on 401
  if (res.status === 401) {
    const refreshRes = await fetch(`${BASE}/auth/refresh`, { method: "POST", credentials: "include" });
    if (refreshRes.ok) {
      const { access_token } = await refreshRes.json();
      useAuthStore.getState().setToken(access_token);
      const retry = await fetch(`${BASE}${path}`, {
        ...init,
        headers: { ...headers, Authorization: `Bearer ${access_token}` },
        credentials: "include",
      });
      if (!retry.ok) throw new ApiError(retry.status, await retry.json().catch(() => ({})));
      return retry.json() as Promise<T>;
    }
    useAuthStore.getState().logout();
    throw new ApiError(401, { detail: "Session expired" });
  }

  if (!res.ok) throw new ApiError(res.status, await res.json().catch(() => ({})));
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export class ApiError extends Error {
  constructor(public status: number, public body: Record<string, unknown>) {
    super((body?.detail as string) ?? `HTTP ${status}`);
  }
}

export const api = {
  get:    <T>(path: string)                     => request<T>(path),
  post:   <T>(path: string, body: unknown)       => request<T>(path, { method: "POST",   body: JSON.stringify(body) }),
  put:    <T>(path: string, body: unknown)       => request<T>(path, { method: "PUT",    body: JSON.stringify(body) }),
  delete: <T>(path: string)                     => request<T>(path, { method: "DELETE" }),
};
