import { api, ApiError } from "@/lib/api";
import { useAuthStore } from "@/store/authStore";

function response(status: number, body?: unknown): Response {
  return {
    status,
    ok: status >= 200 && status < 300,
    text: async () => (body === undefined ? "" : JSON.stringify(body)),
    json: async () => body,
  } as Response;
}

describe("api refresh coordination", () => {
  beforeEach(() => {
    useAuthStore.setState({
      user: {
        id: "user-1",
        email: "user@example.test",
        full_name: "Test User",
        is_active: true,
        is_super_admin: false,
      },
      accessToken: "old-token",
    });
  });

  it("shares one refresh request across concurrent 401 responses", async () => {
    let resolveRefresh: ((value: Response) => void) | undefined;
    const refreshResponse = new Promise<Response>((resolve) => {
      resolveRefresh = resolve;
    });
    let resourceCalls = 0;
    const fetchMock: jest.MockedFunction<typeof fetch> = jest.fn(async (url: RequestInfo | URL) => {
      const calledUrl = String(url);
      if (calledUrl.endsWith("/auth/refresh")) return refreshResponse;
      if (calledUrl.endsWith("/resource")) {
        resourceCalls += 1;
        return resourceCalls <= 2 ? response(401, { detail: "expired" }) : response(200, { ok: true });
      }
      return response(404);
    });
    global.fetch = fetchMock;

    const first = api.get<{ ok: boolean }>("/resource");
    const second = api.get<{ ok: boolean }>("/resource");
    await Promise.resolve();
    resolveRefresh?.(response(200, { access_token: "new-token" }));

    await expect(Promise.all([first, second])).resolves.toEqual([{ ok: true }, { ok: true }]);
    expect(fetchMock.mock.calls.filter(([url]) => String(url).endsWith("/auth/refresh"))).toHaveLength(1);
    expect(useAuthStore.getState().accessToken).toBe("new-token");
  });

  it("does not logout when the retried request fails after refresh succeeds", async () => {
    const logout = jest.fn();
    useAuthStore.setState({ logout });
    let resourceCalls = 0;
    const fetchMock: jest.MockedFunction<typeof fetch> = jest.fn(async (url: RequestInfo | URL) => {
      const calledUrl = String(url);
      if (calledUrl.endsWith("/auth/refresh")) return response(200, { access_token: "new-token" });
      resourceCalls += 1;
      return resourceCalls === 1 ? response(401, { detail: "expired" }) : response(500, { detail: "server error" });
    });
    global.fetch = fetchMock;

    await expect(api.get("/resource")).rejects.toBeInstanceOf(ApiError);
    expect(logout).not.toHaveBeenCalled();
  });
});