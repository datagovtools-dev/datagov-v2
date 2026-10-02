"""Integration tests for Project CRUD endpoints."""
import pytest
from httpx import AsyncClient


async def _create_and_login(client: AsyncClient) -> str:
    """Create a test superadmin user and return access token."""
    from sqlalchemy.ext.asyncio import AsyncSession
    # Direct DB seed via the client fixture's override — skip if no test DB
    pytest.skip("Requires authenticated session — run with TEST_DATABASE_URL")


@pytest.mark.asyncio
async def test_projects_list_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/projects")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_projects_filters_years_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/projects/filters")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_create_project_requires_auth(client: AsyncClient):
    resp = await client.post("/api/v1/projects", json={
        "name": "Test Project",
        "year": 2024,
        "status": "active",
    })
    assert resp.status_code == 401


def _project_body(year: int = 2031, **extra) -> dict:
    return {
        "project_name": "Project ID Rule Test",
        "customer_name": "PT Test",
        "project_year": year,
        "project_category": "Internal",
        **extra,
    }


@pytest.mark.asyncio
async def test_project_id_is_assigned_sequentially_per_year(client: AsyncClient, auth_headers):
    first = await client.post("/api/v1/projects", json=_project_body(), headers=auth_headers)
    second = await client.post("/api/v1/projects", json=_project_body(), headers=auth_headers)
    other_year = await client.post("/api/v1/projects", json=_project_body(2032), headers=auth_headers)
    assert first.status_code == 201, first.text
    assert first.json()["project_code"] == "PRJ-2031-001"
    assert second.json()["project_code"] == "PRJ-2031-002"
    assert other_year.json()["project_code"] == "PRJ-2032-001"

    preview = await client.get("/api/v1/projects/next-code?year=2031", headers=auth_headers)
    assert preview.json() == {"project_year": 2031, "project_code": "PRJ-2031-003"}


@pytest.mark.asyncio
async def test_project_id_from_client_is_ignored(client: AsyncClient, auth_headers):
    resp = await client.post(
        "/api/v1/projects", json=_project_body(2033, project_code="PRJ-000x"), headers=auth_headers,
    )
    assert resp.status_code == 201, resp.text
    assert resp.json()["project_code"] == "PRJ-2033-001"

    updated = await client.put(
        f"/api/v1/projects/{resp.json()['id']}", json={"project_code": "anything"}, headers=auth_headers,
    )
    assert updated.json()["project_code"] == "PRJ-2033-001"


@pytest.mark.asyncio
async def test_project_year_change_assigns_new_id(client: AsyncClient, auth_headers):
    created = (await client.post("/api/v1/projects", json=_project_body(2034), headers=auth_headers)).json()
    updated = await client.put(
        f"/api/v1/projects/{created['id']}", json={"project_year": 2035}, headers=auth_headers,
    )
    assert updated.json()["project_code"] == "PRJ-2035-001"


@pytest.mark.asyncio
async def test_project_year_must_have_four_digits(client: AsyncClient, auth_headers):
    resp = await client.post("/api/v1/projects", json=_project_body(26), headers=auth_headers)
    assert resp.status_code == 422


@pytest.mark.parametrize("code", ["PRJ-000x", "PRJ-002026-Astra-Infra", "PRJ-2026-001-A", "PRJ-2026-01", "PRJ-2026-000", "prj-2026-001"])
def test_model_rejects_invalid_project_ids(code):
    from app.models.project import Project

    with pytest.raises(ValueError):
        Project(project_code=code)


def test_model_accepts_valid_project_id():
    from app.models.project import Project

    assert Project(project_code="PRJ-2026-019").project_code == "PRJ-2026-019"
