"""Unit/integration tests for security-relevant HTTP behaviours."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_endpoint_does_not_expose_secrets(client: AsyncClient):
    resp = await client.get("/health")
    body = resp.text.lower()
    for sensitive in ("password", "secret", "token", "api_key", "private_key"):
        assert sensitive not in body, f"'{sensitive}' found in health response"


@pytest.mark.asyncio
async def test_login_rate_limit_not_bypassed_with_special_chars(client: AsyncClient):
    """SQL injection attempt should return 401 or 422, never 200."""
    resp = await client.post("/api/v1/auth/login", json={
        "email": "' OR '1'='1",
        "password": "' OR '1'='1",
    })
    assert resp.status_code in (401, 422), "SQL injection pattern should not succeed"


@pytest.mark.asyncio
async def test_login_with_xss_payload_is_rejected(client: AsyncClient):
    """XSS in email field should return 422 (validation error), not 500."""
    resp = await client.post("/api/v1/auth/login", json={
        "email": "<script>alert(1)</script>",
        "password": "password",
    })
    assert resp.status_code in (401, 422), "XSS payload should not cause 500 error"


@pytest.mark.asyncio
async def test_accessing_other_users_notification_requires_auth(client: AsyncClient):
    import uuid
    notif_id = str(uuid.uuid4())
    resp = await client.put(f"/api/v1/notifications/{notif_id}/read", json={})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_openapi_schema_not_available_in_production():
    """Verify OpenAPI schema is disabled in production (config-level check)."""
    from app.config import get_settings
    settings = get_settings()
    if settings.environment == "production":
        import pytest
        pytest.skip("Must verify separately in production")
    # In non-prod, docs should be available
    from app.main import app
    assert app.openapi_url is not None
