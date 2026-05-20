"""Integration tests for Metadata API endpoints."""
import uuid
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_metadata_tables_requires_auth(client: AsyncClient):
    project_id = str(uuid.uuid4())
    resp = await client.get(f"/api/v1/metadata/tables/{project_id}")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_metadata_grid_requires_auth(client: AsyncClient):
    project_id = str(uuid.uuid4())
    resp = await client.get(f"/api/v1/metadata/{project_id}")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_metadata_proceed_requires_auth(client: AsyncClient):
    resp = await client.post("/api/v1/metadata/proceed", json={
        "project_id": str(uuid.uuid4()),
        "source_type": "gcp",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_metadata_save_requires_auth(client: AsyncClient):
    resp = await client.post("/api/v1/metadata/save", json={
        "project_id": str(uuid.uuid4()),
        "records": [],
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_audit_log_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/audit-logs")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_notifications_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/notifications")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_ai_settings_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/settings/ai")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_ai_status_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/settings/ai/status")
    assert resp.status_code == 401
