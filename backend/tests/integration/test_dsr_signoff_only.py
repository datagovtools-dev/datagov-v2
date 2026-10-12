"""DSR approval is completed by the form sign-off, not a workflow chain."""
from datetime import date, timedelta
import uuid

import pytest
from httpx import AsyncClient


ITEMS = [
    "A_i_1", "A_i_2", "A_i_3",
    "A_ii_1", "A_ii_2", "A_ii_3", "A_ii_4",
    "B_i", "B_ii", "B_iii", "B_iv", "B_v", "B_vi",
    "C_i_1", "C_i_2", "C_i_3",
]


def _complete_checklist(signatures: bool = False) -> dict:
    sign_off = {
        "approved": "Yes",
        "prepared_by": "Test Lead",
        "prepared_position": "Senior Data Architect",
        "acknowledged_by": "Test SME",
        "acknowledged_position": "Head of Business Analytics",
    }
    if signatures:
        sign_off.update({
            "prepared_signature": "data:image/png;base64,AAA",
            "acknowledged_signature": "data:image/png;base64,BBB",
        })
    return {
        **{item: {"answer": "Yes", "remarks": "Verified"} for item in ITEMS},
        "sign_off": sign_off,
    }


@pytest.mark.asyncio
async def test_dsr_signoff_is_the_only_approval_step(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Data",
            "recipient": "Analytics Partner",
            "purpose": "Approved data sharing use case",
            "is_ai_use": False,
            "duration_start": date.today().isoformat(),
            "duration_end": (date.today() + timedelta(days=30)).isoformat(),
        },
    )
    assert create_resp.status_code == 201, create_resp.text
    dsr = create_resp.json()
    dsr_id = dsr["id"]
    assert dsr["approvals"] == []

    update_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_checklist(signatures=True)},
    )
    assert update_resp.status_code == 200, update_resp.text

    list_resp = await client.get("/api/v1/dsr?page_size=100", headers=auth_headers)
    assert list_resp.status_code == 200, list_resp.text
    listed = next(item for item in list_resp.json()["items"] if item["id"] == dsr_id)
    assert listed["is_final_signed"] is True

    submit_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/submit",
        headers=auth_headers,
    )
    assert submit_resp.status_code == 200, submit_resp.text
    submitted = submit_resp.json()
    assert submitted["status"] == "approved"
    assert submitted["approvals"] == []
    assert submitted["ai_checklist"]["status"] == "approved"
    assert submitted["ai_checklist"]["validated_at"] is not None

    legacy_approval_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "No separate workflow"},
    )
    assert legacy_approval_resp.status_code == 404


@pytest.mark.asyncio
async def test_dsr_requires_positive_form_approval(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Data",
            "recipient": "Analytics Partner",
            "purpose": "Rejected form approval case",
            "is_ai_use": False,
            "duration_start": date.today().isoformat(),
            "duration_end": (date.today() + timedelta(days=30)).isoformat(),
        },
    )
    assert create_resp.status_code == 201, create_resp.text
    dsr_id = create_resp.json()["id"]

    checklist = _complete_checklist(signatures=True)
    checklist["sign_off"]["approved"] = "No"
    update_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": checklist},
    )
    assert update_resp.status_code == 200, update_resp.text

    submit_resp = await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)
    assert submit_resp.status_code == 400
    assert "both Sign Off signatures" in submit_resp.json()["detail"]


@pytest.mark.asyncio
async def test_dsr_submit_requires_project_sme(
    client: AsyncClient, auth_headers: dict[str, str], test_project, db
):
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Data",
            "recipient": "Analytics Partner",
            "purpose": "SME authorization case",
            "is_ai_use": False,
            "duration_start": date.today().isoformat(),
            "duration_end": (date.today() + timedelta(days=30)).isoformat(),
        },
    )
    assert create_resp.status_code == 201, create_resp.text
    dsr_id = create_resp.json()["id"]

    update_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_checklist(signatures=True)},
    )
    assert update_resp.status_code == 200, update_resp.text

    test_project.sme_id = uuid.uuid4()
    db.add(test_project)
    await db.commit()

    submit_resp = await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)
    assert submit_resp.status_code == 403
    assert "Project SME" in submit_resp.json()["detail"]


@pytest.mark.asyncio
async def test_non_project_sme_cannot_save_acknowledged_signature(
    client: AsyncClient, auth_headers: dict[str, str], test_project, db
):
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Data",
            "recipient": "Analytics Partner",
            "purpose": "SME signature authorization case",
            "is_ai_use": False,
            "duration_start": date.today().isoformat(),
            "duration_end": (date.today() + timedelta(days=30)).isoformat(),
        },
    )
    assert create_resp.status_code == 201, create_resp.text
    dsr_id = create_resp.json()["id"]

    test_project.sme_id = uuid.uuid4()
    db.add(test_project)
    await db.commit()

    update_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_checklist(signatures=True)},
    )
    assert update_resp.status_code == 403
    assert "Project SME" in update_resp.json()["detail"]


@pytest.mark.asyncio
async def test_approved_dsr_checklist_is_immutable(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Data",
            "recipient": "Analytics Partner",
            "purpose": "Immutable approval case",
            "is_ai_use": False,
            "duration_start": date.today().isoformat(),
            "duration_end": (date.today() + timedelta(days=30)).isoformat(),
        },
    )
    assert create_resp.status_code == 201, create_resp.text
    dsr_id = create_resp.json()["id"]

    checklist = _complete_checklist(signatures=True)
    update_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": checklist},
    )
    assert update_resp.status_code == 200, update_resp.text
    submit_resp = await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)
    assert submit_resp.status_code == 200, submit_resp.text

    checklist["A_i_1"]["remarks"] = "tampered after approval"
    blocked_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": checklist},
    )
    assert blocked_resp.status_code == 400
    assert "immutable" in blocked_resp.json()["detail"].lower()
