import { useAuthStore } from "@/store/authStore";

const BASE = "/api/v1";

// Short explanation per HTTP status: what happened and what to do. Used when the response has
// no readable `detail` (e.g. nginx returns an HTML error page for 413/502/504).
export const HTTP_ERROR_HELP: Record<number, string> = {
  400: "HTTP 400 · Request not accepted: some input is missing or invalid. Check the form and try again.",
  401: "HTTP 401 · Not signed in: your session has expired. Sign in again.",
  403: "HTTP 403 · No permission: your role cannot do this action. Ask a Super Admin to grant the role.",
  404: "HTTP 404 · Not found: the item was deleted or the link is wrong. Refresh the page.",
  408: "HTTP 408 · Request timed out: the connection was too slow. Try again.",
  409: "HTTP 409 · Conflict: the item was changed or already exists. Refresh the page and try again.",
  413: "HTTP 413 · File too large: the maximum is 25 MB per file. Split the file or remove unused sheets.",
  422: "HTTP 422 · Invalid data: a field has the wrong format. Check the values and try again.",
  429: "HTTP 429 · Too many requests: too many actions in a short time. Wait a few seconds and try again.",
  500: "HTTP 500 · Server error: something failed on the server. Try again; if it repeats, send the time of the error to the administrator (api log).",
  502: "HTTP 502 · Server not reachable: the API is restarting or stopped. Wait a minute and try again; if it repeats, ask the administrator to check the api container.",
  503: "HTTP 503 · Service unavailable: the server is busy or in maintenance. Wait a minute and try again.",
  504: "HTTP 504 · Server took too long: the request ran past the time limit (e.g. AI generation on a slow CPU). Refresh to see what was already saved, then try again with fewer items.",
};

export function httpErrorHelp(status: number): string {
  return HTTP_ERROR_HELP[status] ?? `HTTP ${status} · Request failed. Try again; if it repeats, contact the administrator.`;
}

/** Readable error text for a failed response: the API's `detail`, or a short explanation of the HTTP status. */
export async function errorDetail(res: Response): Promise<string> {
  const text = await res.text().catch(() => "");
  try {
    const detail = (JSON.parse(text) as { detail?: unknown }).detail;
    if (typeof detail === "string" && detail) return detail;
    if (Array.isArray(detail) && detail.length) {
      return detail.map((d) => (d as { msg?: string })?.msg ?? String(d)).join("; ");
    }
  } catch {
    // not JSON (e.g. an nginx error page)
  }
  return httpErrorHelp(res.status);
}

let refreshPromise: Promise<string> | null = null;

async function refreshAccessToken(): Promise<string> {
  if (!refreshPromise) {
    refreshPromise = (async () => {
      const refreshRes = await fetch(`${BASE}/auth/refresh`, { method: "POST", credentials: "include" });
      if (!refreshRes.ok) throw new ApiError(refreshRes.status, { detail: await errorDetail(refreshRes) });
      const body = await refreshRes.json() as { access_token?: string };
      if (!body.access_token) throw new ApiError(502, { detail: "Refresh response did not include an access token" });
      useAuthStore.getState().setToken(body.access_token);
      return body.access_token;
    })().finally(() => {
      refreshPromise = null;
    });
  }
  return refreshPromise;
}

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
    let accessToken: string;
    try {
      accessToken = await refreshAccessToken();
    } catch (error) {
      useAuthStore.getState().logout();
      if (error instanceof ApiError && error.status === 401) throw error;
      throw new ApiError(401, { detail: "Session expired" });
    }

    const retry = await fetch(`${BASE}${path}`, {
      ...init,
      headers: { ...headers, Authorization: `Bearer ${accessToken}` },
      credentials: "include",
    });
    if (!retry.ok) throw new ApiError(retry.status, { detail: await errorDetail(retry) });
    if (retry.status === 204) return undefined as T;
    return retry.json() as Promise<T>;
  }

  if (!res.ok) throw new ApiError(res.status, { detail: await errorDetail(res) });
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export class ApiError extends Error {
  constructor(public status: number, public body: Record<string, unknown>) {
    super((body?.detail as string) || httpErrorHelp(status));
  }
}

export const api = {
  get:    <T>(path: string)                     => request<T>(path),
  post:   <T>(path: string, body: unknown)       => request<T>(path, { method: "POST",   body: JSON.stringify(body) }),
  put:    <T>(path: string, body: unknown)       => request<T>(path, { method: "PUT",    body: JSON.stringify(body) }),
  delete: <T>(path: string)                     => request<T>(path, { method: "DELETE" }),
};
