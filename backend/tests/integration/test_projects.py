"""Integration tests for Project CRUD endpoints."""
import pytest
from httpx import AsyncClient


async def _create_and_login(client: AsyncClient) -> str:
    """Create a test superadmin user and return access token."""
    from sqlalchemy.ext.asyncio import AsyncSession
    # Direct DB seed via the client fixture's override — skip if no test DB
    # In CI this should run against a real PG instance with TEST_DATABASE_URL set
    pytest.skip("Requires authenticated session — run with TEST_DATABASE_URL")


@pytest.mark.asyncio
async def test_projects_list_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/projects")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_projects_filters_years_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/projects/filters/years")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_create_project_requires_auth(client: AsyncClient):
    resp = await client.post("/api/v1/projects", json={
        "name": "Test Project",
        "year": 2024,
        "status": "active",
    })
    assert resp.status_code == 401
