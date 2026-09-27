"""GET /projects/{id}/source-file-retention: 30 days until the project's ROPA is approved."""
from datetime import timedelta

import pytest
from httpx import AsyncClient


async def _retention(client: AsyncClient, headers, project) -> dict:
    resp = await client.get(f"/api/v1/projects/{project.id}/source-file-retention", headers=headers)
    assert resp.status_code == 200, resp.text
    return resp.json()


@pytest.mark.asyncio
async def test_retention_follows_ropa_only_once_approved(client: AsyncClient, auth_headers, test_project):
    default_expiry = (test_project.end_date + timedelta(days=30)).isoformat()
    r = await _retention(client, auth_headers, test_project)
    assert (r["basis"], r["expiry_date"]) == ("default", default_expiry)

    resp = await client.post("/api/v1/ropa", headers=auth_headers, json={
        "project_id": str(test_project.id), "process_name": "Churn Modelling", "purpose": "Model training",
        "data_category": "Customer profile", "data_subject": "Customers", "legal_basis": "Contract",
        "retention_period": "5 Years from Account Termination",
    })
    assert resp.status_code in (200, 201), resp.text
    ropa_id = resp.json()["id"]

    for status in ("submitted", "under_review"):
        await client.post(f"/api/v1/ropa/{ropa_id}/transition", headers=auth_headers,
                          json={"target_status": status, "comments": "ok"})
        r = await _retention(client, auth_headers, test_project)
        assert (r["basis"], r["expiry_date"]) == ("default", default_expiry)  # not approved yet

    resp = await client.post(f"/api/v1/ropa/{ropa_id}/transition", headers=auth_headers,
                             json={"target_status": "approved", "comments": "ok"})
    assert resp.json()["status"] == "approved"
    r = await _retention(client, auth_headers, test_project)
    assert r["basis"] == "ropa"
    assert r["expiry_date"] == test_project.end_date.replace(year=test_project.end_date.year + 5).isoformat()
    assert r["ropa_retention_period"] == "5 Years from Account Termination"
