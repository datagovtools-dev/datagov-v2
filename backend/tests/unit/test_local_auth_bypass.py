from starlette.requests import Request

from app.core import deps


def _request(host: str) -> Request:
    hostname = host.split(":", 1)[0]
    return Request(
        {
            "type": "http",
            "method": "GET",
            "path": "/api/v1/auth/me",
            "headers": [(b"host", host.encode())],
            "scheme": "http",
            "server": (hostname, 80),
            "client": ("127.0.0.1", 12345),
        }
    )


def test_local_auth_bypass_is_local_host_only(monkeypatch):
    monkeypatch.setattr(deps.settings, "local_auth_bypass_enabled", True)
    monkeypatch.setattr(deps.settings, "environment", "development")
    monkeypatch.setattr(deps.settings, "local_auth_bypass_hosts", "localhost,127.0.0.1,::1")

    assert deps.is_local_auth_bypass_request(_request("localhost"))
    assert deps.is_local_auth_bypass_request(_request("127.0.0.1:80"))
    assert not deps.is_local_auth_bypass_request(_request("kde-exam-plate-destinations.trycloudflare.com"))


def test_local_auth_bypass_is_disabled_in_production(monkeypatch):
    monkeypatch.setattr(deps.settings, "local_auth_bypass_enabled", True)
    monkeypatch.setattr(deps.settings, "environment", "production")

    assert not deps.is_local_auth_bypass_request(_request("localhost"))
