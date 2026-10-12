"""AICK completion uses the assessment and sign-off section, not approvals."""
from datetime import date, timedelta

import pytest
from httpx import AsyncClient

ITEMS = [
    "before_use_1", "before_use_2", "before_use_3",
    "input_1", "input_2", "input_3",
    "output_1", "output_2",
    "utilization_1", "utilization_2",
]


def _assessment(signatures: bool = False) -> dict:
    sign_off = {
        "approved": "Yes",
        "prepared_by": "Ahmad Fauzi",
        "prepared_position": "Delivery Manager",
        "acknowledged_by": "Dewi Rahayu",
        "acknowledged_position": "Head of Business Analytics",
    }
    if signatures:
        sign_off.update({
            "prepared_signature": "data:image/png;base64,AAA",
            "acknowledged_signature": "data:image/png;base64,BBB",
        })
    return {
        "ai_assessment": {
            "items": {i: {"status": "Yes", "remarks": "ok"} for i in ITEMS},
            "sign_off": sign_off,
        }
    }


async def _ai_dsr(client: AsyncClient, headers, project) -> str:
    resp = await client.post("/api/v1/dsr", headers=headers, json={
        "project_id": str(project.id),
        "dataset_name": "Churn Features",
        "recipient": "Vendor",
        "purpose": "Model training",
        "is_ai_use": True,
        "duration_start": date.today().isoformat(),
        "duration_end": (date.today() + timedelta(days=90)).isoformat(),
    })
    assert resp.status_code in (200, 201), resp.text
    return resp.json()["id"]


async def _is_signed(client: AsyncClient, headers, dsr_id: str) -> bool:
    items = (await client.get("/api/v1/dsr?page_size=100", headers=headers)).json()["items"]
    return next(i for i in items if i["id"] == dsr_id)["is_signed"]


@pytest.mark.asyncio
async def test_aick_signoff_controls_signed_status(client: AsyncClient, auth_headers, test_project):
    dsr_id = await _ai_dsr(client, auth_headers, test_project)

    await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _assessment()},
    )
    assert await _is_signed(client, auth_headers, dsr_id) is False

    signed_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _assessment(signatures=True)},
    )
    assert signed_resp.status_code == 200, signed_resp.text
    signed_item = next(
        item for item in (await client.get("/api/v1/dsr?page_size=100", headers=auth_headers)).json()["items"]
        if item["id"] == dsr_id
    )
    assert signed_item["is_signed"] is True
    assert signed_item["is_final_signed"] is False
    assert await _is_signed(client, auth_headers, dsr_id) is True


@pytest.mark.asyncio
async def test_aick_submit_completes_without_approval_workflow(
    client: AsyncClient, auth_headers, test_project
):
    dsr_id = await _ai_dsr(client, auth_headers, test_project)
    await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _assessment()},
    )

    submit_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/checklist/submit",
        headers=auth_headers,
    )
    assert submit_resp.status_code == 200, submit_resp.text
    checklist = submit_resp.json()["ai_checklist"]
    assert checklist["status"] == "approved"
    assert "approvals" not in checklist

    legacy_approval_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/checklist/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "should not be used"},
    )
    assert legacy_approval_resp.status_code == 404
