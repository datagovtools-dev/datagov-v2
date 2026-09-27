"""Data Owner / Steward position (job title) is stored, returned and updated."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_owner_position_is_saved_and_updated(client: AsyncClient, auth_headers, test_project):
    url = f"/api/v1/metadata/owners/{test_project.id}"
    body = {"role_type": "data_owner", "full_name": "Sri Handayani", "email": "sri@example.com",
            "position": "CRM Department Head"}
    resp = await client.post(url, json=body, headers=auth_headers)
    assert resp.status_code == 201, resp.text
    assert resp.json()["position"] == "CRM Department Head"

    # same owner saved again (edit project) updates the position
    await client.post(url, json={**body, "position": "Head of CRM & Loyalty"}, headers=auth_headers)
    owners = (await client.get(url, headers=auth_headers)).json()
    owner = next(o for o in owners if o["role_type"] == "data_owner")
    assert owner["position"] == "Head of CRM & Loyalty"
    assert len([o for o in owners if o["role_type"] == "data_owner"]) == 1


@pytest.mark.asyncio
async def test_owner_position_is_optional(client: AsyncClient, auth_headers, test_project):
    resp = await client.post(f"/api/v1/metadata/owners/{test_project.id}",
                             json={"role_type": "lead_business_steward", "full_name": "Rizky", "email": "rizky@example.com"},
                             headers=auth_headers)
    assert resp.status_code == 201, resp.text
    assert resp.json()["position"] is None
