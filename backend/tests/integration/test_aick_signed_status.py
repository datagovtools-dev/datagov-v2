"""AICK "signed" status: only after both sign-off signatures or the final approval, never just on save/submit."""
from datetime import date, timedelta

import pytest
from httpx import AsyncClient

ITEMS = ["before_use_1", "before_use_2", "before_use_3", "input_1", "input_2", "input_3",
         "output_1", "output_2", "utilization_1", "utilization_2"]


def _assessment(signatures: bool = False) -> dict:
    sign_off = {"approved": "Yes", "prepared_by": "Ahmad Fauzi", "prepared_position": "Delivery Manager",
                "acknowledged_by": "Dewi Rahayu", "acknowledged_position": "Head of Business Analytics"}
    if signatures:
        sign_off.update({"prepared_signature": "data:image/png;base64,AAA", "acknowledged_signature": "data:image/png;base64,BBB"})
    return {"ai_assessment": {"items": {i: {"status": "Yes", "remarks": "ok"} for i in ITEMS}, "sign_off": sign_off}}


async def _ai_dsr(client: AsyncClient, headers, project) -> str:
    resp = await client.post("/api/v1/dsr", headers=headers, json={
        "project_id": str(project.id), "dataset_name": "Churn Features", "recipient": "Vendor",
        "purpose": "Model training", "is_ai_use": True,
        "duration_start": date.today().isoformat(), "duration_end": (date.today() + timedelta(days=90)).isoformat(),
    })
    assert resp.status_code in (200, 201), resp.text
    return resp.json()["id"]


async def _is_signed(client: AsyncClient, headers, dsr_id: str) -> bool:
    items = (await client.get("/api/v1/dsr?page_size=100", headers=headers)).json()["items"]
    return next(i for i in items if i["id"] == dsr_id)["is_signed"]


@pytest.mark.asyncio
async def test_saved_and_submitted_aick_is_not_signed(client: AsyncClient, auth_headers, test_project):
    dsr_id = await _ai_dsr(client, auth_headers, test_project)
    await client.put(f"/api/v1/dsr/{dsr_id}/checklist", headers=auth_headers, json={"checklist_json": _assessment()})
    assert await _is_signed(client, auth_headers, dsr_id) is False  # "Approved? = Yes" alone does not sign

    await client.post(f"/api/v1/dsr/{dsr_id}/checklist/submit", headers=auth_headers)
    assert await _is_signed(client, auth_headers, dsr_id) is False

    for step in (1, 2):
        await client.post(f"/api/v1/dsr/{dsr_id}/checklist/approvals/{step}", headers=auth_headers,
                          json={"action": "approve", "comments": "ok"})
        assert await _is_signed(client, auth_headers, dsr_id) is False
    resp = await client.post(f"/api/v1/dsr/{dsr_id}/checklist/approvals/3", headers=auth_headers,
                             json={"action": "approve", "comments": "final"})
    assert resp.json()["ai_checklist"]["status"] == "approved"
    assert await _is_signed(client, auth_headers, dsr_id) is True  # final approval signs it


async def _ids_for(client: AsyncClient, headers, checklist_status: str) -> set[str]:
    resp = await client.get(f"/api/v1/dsr?page_size=100&is_ai_use=true&checklist_status={checklist_status}", headers=headers)
    return {i["id"] for i in resp.json()["items"]}


@pytest.mark.asyncio
async def test_aick_stays_submitted_until_pic_data_compliance_approves(client: AsyncClient, auth_headers, test_project):
    dsr_id = await _ai_dsr(client, auth_headers, test_project)
    await client.put(f"/api/v1/dsr/{dsr_id}/checklist", headers=auth_headers, json={"checklist_json": _assessment()})
    assert dsr_id in await _ids_for(client, auth_headers, "in_progress")

    await client.post(f"/api/v1/dsr/{dsr_id}/checklist/submit", headers=auth_headers)
    assert dsr_id in await _ids_for(client, auth_headers, "submitted")  # waiting for PIC Data Compliance
    assert dsr_id not in await _ids_for(client, auth_headers, "under_review")

    await client.post(f"/api/v1/dsr/{dsr_id}/checklist/approvals/1", headers=auth_headers,
                      json={"action": "approve", "comments": "PIC Data Compliance ok"})
    assert dsr_id in await _ids_for(client, auth_headers, "under_review")  # next approvers: DM, SME
    assert dsr_id not in await _ids_for(client, auth_headers, "submitted")


@pytest.mark.asyncio
async def test_both_signatures_sign_the_aick(client: AsyncClient, auth_headers, test_project):
    dsr_id = await _ai_dsr(client, auth_headers, test_project)
    await client.put(f"/api/v1/dsr/{dsr_id}/checklist", headers=auth_headers,
                     json={"checklist_json": _assessment(signatures=True)})
    assert await _is_signed(client, auth_headers, dsr_id) is True
