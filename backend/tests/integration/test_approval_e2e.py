"""End-to-end integration tests for active Governance Approval workflows.
Covers DSR, DPIA, BAPD Disposal, and DQ Runs.
"""
import uuid
from datetime import date, timedelta, datetime, timezone
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


def _complete_dsr_checklist_payload(is_ai: bool = False) -> dict:
    items = [
        "A_i_1", "A_i_2", "A_i_3",
        "A_ii_1", "A_ii_2", "A_ii_3", "A_ii_4",
        "B_i", "B_ii", "B_iii", "B_iv", "B_v", "B_vi",
        "C_i_1", "C_i_2", "C_i_3",
    ]
    if is_ai:
        items.append("D_i")
    payload = {item: {"answer": "Yes", "remarks": "Compliant and verified with standards"} for item in items}
    payload["sign_off"] = {
        "approved": "Yes",
        "prepared_by": "Test Lead",
        "prepared_position": "Senior Data Architect",
        "acknowledged_by": "Test Head",
        "acknowledged_position": "Head of Data Governance",
        "prepared_signature": "data:image/png;base64,AAA",
        "acknowledged_signature": "data:image/png;base64,BBB",
    }
    return payload


# ── 1. DSR Form Sign-Off Approval E2E ──────────────────────────────────────────

@pytest.mark.asyncio
async def test_dsr_signoff_approval_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """E2E Test: DSR Draft -> form Sign Off -> Approved, without approval steps."""
    # 1. Create DSR
    start_d = date.today().isoformat()
    end_d = (date.today() + timedelta(days=90)).isoformat()
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Financial Transactions",
            "recipient": "Analytics Partner Corp",
            "purpose": "Risk scoring model validation",
            "is_ai_use": False,
            "duration_start": start_d,
            "duration_end": end_d,
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    dsr_data = create_resp.json()
    dsr_id = dsr_data["id"]
    assert dsr_data["status"] == "draft"
    assert dsr_data["approvals"] == []

    # 2. Populate Checklist
    checklist_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_dsr_checklist_payload(is_ai=False)},
    )
    assert checklist_resp.status_code == 200, checklist_resp.text

    # 3. Submit DSR
    submit_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/submit",
        headers=auth_headers,
    )
    assert submit_resp.status_code == 200, submit_resp.text
    dsr_approved = submit_resp.json()
    assert dsr_approved["status"] == "approved"
    assert dsr_approved["approvals"] == []
    assert dsr_approved["ai_checklist"]["status"] == "approved"

    legacy_approval_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "No separate workflow"},
    )
    assert legacy_approval_resp.status_code == 404


# ── 2. DSR Sign-Off Validation E2E ─────────────────────────────────────────────

@pytest.mark.asyncio
async def test_dsr_submission_requires_form_signatures(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """A DSR cannot be approved until both form Sign Off signatures exist."""
    start_d = date.today().isoformat()
    end_d = (date.today() + timedelta(days=30)).isoformat()
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Confidential HR Records",
            "recipient": "Third Party Recruiter",
            "purpose": "Hiring data mining",
            "is_ai_use": False,
            "duration_start": start_d,
            "duration_end": end_d,
        },
    )
    assert create_resp.status_code in (200, 201)
    dsr_id = create_resp.json()["id"]

    incomplete = _complete_dsr_checklist_payload(is_ai=False)
    incomplete["sign_off"].pop("prepared_signature")
    incomplete["sign_off"].pop("acknowledged_signature")
    await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": incomplete},
    )
    submit_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/submit",
        headers=auth_headers,
    )
    assert submit_resp.status_code == 400
    assert "both Sign Off signatures" in submit_resp.json()["detail"]

    detail_resp = await client.get(f"/api/v1/dsr/{dsr_id}", headers=auth_headers)
    assert detail_resp.status_code == 200
    assert detail_resp.json()["status"] == "draft"


# AI Checklist completion is covered by test_aick_signed_status.py.


# ── 4. DPIA Approval Lifecycle E2E ────────────────────────────────────────────

@pytest.mark.asyncio
async def test_dpia_approval_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """E2E Test: DPIA Draft -> Submit -> Step 1 -> Step 2 -> Approved."""
    # 1. Create DPIA
    create_resp = await client.post(
        "/api/v1/dpia",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "process_name": "Biometric Authentication Pilot",
            "data_category": "Special Category (Biometric)",
            "risk_description": "Unauthorized access to facial template embeddings",
            "mitigation_measures": "Hardware Security Module (HSM) encryption and zero retention raw images",
            "residual_risk": "Low",
            "likelihood_score": 2,
            "impact_score": 4,
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    dpia_data = create_resp.json()
    dpia_id = dpia_data["id"]
    assert dpia_data["status"] == "draft"

    # 2. Submit DPIA
    submit_resp = await client.post(
        f"/api/v1/dpia/{dpia_id}/submit",
        headers=auth_headers,
    )
    assert submit_resp.status_code == 200, submit_resp.text
    dpia_sub = submit_resp.json()
    assert dpia_sub["status"] == "submitted"
    s1 = next(a for a in dpia_sub["approvals"] if a["step_order"] == 1)
    assert s1["status"] == "requested"

    # 3. Action Step 1 (DM / PM)
    s1_resp = await client.post(
        f"/api/v1/dpia/{dpia_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "DM Privacy Risk Review Passed"},
    )
    assert s1_resp.status_code == 200, s1_resp.text
    dp_s1 = s1_resp.json()
    assert dp_s1["status"] == "under_review"
    s2 = next(a for a in dp_s1["approvals"] if a["step_order"] == 2)
    assert s2["status"] == "requested"

    # 4. Action Step 2 (Compliance Officer Sign-off)
    s2_resp = await client.post(
        f"/api/v1/dpia/{dpia_id}/approvals/2",
        headers=auth_headers,
        json={"action": "approve", "comments": "Compliance Officer Formally Approved"},
    )
    assert s2_resp.status_code == 200, s2_resp.text
    dp_s2 = s2_resp.json()
    assert dp_s2["status"] == "approved"
    assert all(a["status"] == "approved" for a in dp_s2["approvals"])


@pytest.mark.asyncio
async def test_bapd_prepared_signature_requires_configured_data_owner(
    client: AsyncClient, auth_headers: dict[str, str], test_project, auth_user
):
    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Unconfigured Data Owner Dataset",
            "dataset_location": "db://sqlite/no-data-owner",
            "expiry_date": date.today().isoformat(),
            "reason": "Testing fail-closed prepared signer authorization",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_id = create_resp.json()["id"]

    signoff_resp = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=auth_headers,
        json={"version": create_resp.json()["version"], "sign_off": {
            "prepared_signature": "data:image/png;base64,PREPARED",
            "prepared_date": date.today().isoformat(),
        }},
    )
    assert signoff_resp.status_code == 403
    assert "Data Owner" in signoff_resp.json()["detail"]


@pytest.mark.asyncio
async def test_bapd_null_workflow_marker_cannot_execute_without_signoff(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    from app.models.bapd import BAPDRecord

    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Null Workflow Marker Dataset",
            "dataset_location": "db://sqlite/null-workflow",
            "expiry_date": date.today().isoformat(),
            "reason": "Testing null approval method execution guard",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_id = create_resp.json()["id"]
    record = await db.get(BAPDRecord, uuid.UUID(bapd_id))
    record.approval_method = None
    record.status = "approved"
    await db.commit()

    execute_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/execute",
        headers=auth_headers,
        json={"confirmation_phrase": "DELETE PERMANENTLY"},
    )
    assert execute_resp.status_code == 400
    assert "sign off" in execute_resp.json()["detail"].lower()


# ── 5. BAPD Form Sign-Off and Disposal Execution E2E ───────────────────────────

@pytest.mark.asyncio
async def test_bapd_form_signoff_and_execution_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    """BAPD Draft -> Final Approval & Sign Off -> Approved -> Execute -> POD."""
    from app.models.metadata import DataOwnerSteward
    db.add(DataOwnerSteward(
        project_id=test_project.id,
        role_type="data_owner",
        full_name=auth_user.full_name,
        email=auth_user.email,
        position="Project Data Owner",
    ))
    await db.commit()
    exp_d = date.today().isoformat()
    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Expired Temporary Staging Data",
            "dataset_location": "gs://datagov-staging-temp/2025/q4",
            "expiry_date": exp_d,
            "reason": "Retention window expired as per the approved retention policy",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_data = create_resp.json()
    bapd_id = bapd_data["id"]
    assert bapd_data["status"] == "draft"
    assert bapd_data["approvals"] == []
    assert bapd_data["is_final_signed"] is False

    dashboard_resp = await client.get("/api/v1/dashboard", headers=auth_headers)
    assert dashboard_resp.status_code == 200, dashboard_resp.text
    dashboard_bapd = [
        item for item in dashboard_resp.json().get("action_items", [])
        if item["entity_id"] == bapd_id
    ]
    assert len(dashboard_bapd) == 1
    assert "Final Approval & Sign Off" in dashboard_bapd[0]["title"]

    incomplete_submit = await client.post(
        f"/api/v1/bapd/{bapd_id}/submit", headers=auth_headers
    )
    assert incomplete_submit.status_code == 400

    signoff = {
        "approved": "Yes",
        "prepared_by": "Project Data Owner",
        "prepared_position": "Data Owner",
        "prepared_signature": "data:image/png;base64,PREPARED",
        "prepared_date": date.today().isoformat(),
        "acknowledged_by": "free-form value must be normalized",
        "acknowledged_position": "free-form position must be normalized",
        "acknowledged_signature": "data:image/png;base64,ACKNOWLEDGED",
        "acknowledged_date": date.today().isoformat(),
    }
    signoff_resp = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=auth_headers,
        json={"version": bapd_data["version"], "sign_off": signoff},
    )
    assert signoff_resp.status_code == 200, signoff_resp.text
    saved = signoff_resp.json()
    assert saved["sign_off"]["acknowledged_by"] == auth_user.full_name
    assert saved["sign_off"]["acknowledged_signed_by"] == str(auth_user.id)
    assert saved["is_final_signed"] is True

    refetched = await client.get(f"/api/v1/bapd/{bapd_id}", headers=auth_headers)
    assert refetched.status_code == 200
    replay_save = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=auth_headers,
        json={"version": refetched.json()["version"], "sign_off": refetched.json()["sign_off"]},
    )
    assert replay_save.status_code == 200, replay_save.text

    legacy_transition = await client.post(
        f"/api/v1/bapd/{bapd_id}/transition",
        headers=auth_headers,
        json={"target_status": "submitted"},
    )
    assert legacy_transition.status_code == 400

    legacy_approval = await client.post(
        f"/api/v1/bapd/{bapd_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve"},
    )
    assert legacy_approval.status_code == 400

    submit_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/submit", headers=auth_headers
    )
    assert submit_resp.status_code == 200, submit_resp.text
    approved = submit_resp.json()
    assert approved["status"] == "approved"
    assert approved["approvals"] == []

    bypass_exec = await client.post(
        f"/api/v1/bapd/{bapd_id}/transition",
        headers=auth_headers,
        json={"target_status": "executed"},
    )
    assert bypass_exec.status_code == 400

    invalid_exec_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/execute",
        headers=auth_headers,
        json={"confirmation_phrase": "DELETE"},
    )
    assert invalid_exec_resp.status_code == 400

    exec_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/execute",
        headers=auth_headers,
        json={"confirmation_phrase": "DELETE PERMANENTLY"},
    )
    assert exec_resp.status_code == 200, exec_resp.text
    executed = exec_resp.json()
    assert executed["status"] == "executed"
    assert executed["pod_file_path"] is not None
    assert executed["executed_at"] is not None

    pod_resp = await client.get(
        f"/api/v1/bapd/{bapd_id}/pod", headers=auth_headers
    )
    assert pod_resp.status_code == 200, pod_resp.text
    assert len(pod_resp.content) > 0


@pytest.mark.asyncio
async def test_bapd_signoff_requires_both_signatures(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    from app.models.metadata import DataOwnerSteward
    db.add(DataOwnerSteward(
        project_id=test_project.id,
        role_type="data_owner",
        full_name=auth_user.full_name,
        email=auth_user.email,
        position="Project Data Owner",
    ))
    await db.commit()
    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Incomplete Sign-Off Dataset",
            "dataset_location": "db://sqlite/incomplete",
            "expiry_date": date.today().isoformat(),
            "reason": "Testing incomplete sign-off validation",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_id = create_resp.json()["id"]

    signoff_resp = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=auth_headers,
        json={
            "version": create_resp.json()["version"],
            "sign_off": {
                "approved": "Yes",
                "prepared_by": "Project Data Owner",
                "prepared_position": "Data Owner",
                "prepared_signature": "data:image/png;base64,PREPARED",
            }
        },
    )
    assert signoff_resp.status_code == 200, signoff_resp.text

    submit_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/submit", headers=auth_headers
    )
    assert submit_resp.status_code == 400
    assert "sign" in submit_resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_bapd_acknowledged_signature_requires_project_sme(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    from app.core.security import create_access_token, hash_password
    from app.models.user import Role, User, UserProjectRole
    from sqlalchemy import select

    other_user = User(
        id=uuid.uuid4(),
        full_name="Non SME Reviewer",
        email=f"reviewer_{uuid.uuid4().hex[:8]}@vibecode.id",
        password_hash=hash_password("test-only-password"),
        position="Reviewer",
        is_active=True,
    )
    db.add(other_user)
    await db.flush()
    super_admin_role = (await db.execute(
        select(Role).where(Role.name == "super_admin")
    )).scalar_one()
    db.add(UserProjectRole(
        user_id=other_user.id,
        role_id=super_admin_role.id,
        assigned_by=auth_user.id,
    ))
    await db.commit()

    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "SME Authorization Dataset",
            "dataset_location": "db://sqlite/sme-check",
            "expiry_date": date.today().isoformat(),
            "reason": "Testing Project SME authorization",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_id = create_resp.json()["id"]
    other_headers = {
        "Authorization": f"Bearer {create_access_token(str(other_user.id), roles=['super_admin'])}"
    }

    approval_change_resp = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=other_headers,
        json={"version": create_resp.json()["version"], "sign_off": {"approved": "Yes"}},
    )
    assert approval_change_resp.status_code == 403

    signoff_resp = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=other_headers,
        json={
            "version": create_resp.json()["version"],
            "sign_off": {
                "approved": "Yes",
                "acknowledged_signature": "data:image/png;base64,ACKNOWLEDGED",
            }
        },
    )
    assert signoff_resp.status_code == 403
    assert "Project SME" in signoff_resp.json()["detail"]


@pytest.mark.asyncio
async def test_bapd_signoff_signature_cannot_be_cleared_by_unauthorized_user(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    from app.core.security import create_access_token, hash_password
    from app.models.metadata import DataOwnerSteward
    from app.models.user import Role, User, UserProjectRole
    from sqlalchemy import select

    db.add(DataOwnerSteward(
        project_id=test_project.id,
        role_type="data_owner",
        full_name=auth_user.full_name,
        email=auth_user.email,
        position="Project Data Owner",
    ))
    other_user = User(
        id=uuid.uuid4(),
        full_name="Unauthorized Sign-Off Editor",
        email=f"editor_{uuid.uuid4().hex[:8]}@vibecode.id",
        password_hash=hash_password("test-only-password"),
        position="Reviewer",
        is_active=True,
    )
    db.add(other_user)
    await db.flush()
    super_admin_role = (await db.execute(select(Role).where(Role.name == "super_admin"))).scalar_one()
    db.add(UserProjectRole(user_id=other_user.id, role_id=super_admin_role.id, assigned_by=auth_user.id))
    await db.commit()

    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Protected Sign-Off Dataset",
            "dataset_location": "db://sqlite/protected-signoff",
            "expiry_date": date.today().isoformat(),
            "reason": "Testing signature immutability authorization",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_id = create_resp.json()["id"]

    initial = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=auth_headers,
        json={"version": create_resp.json()["version"], "sign_off": {
            "approved": "Yes",
            "prepared_signature": "data:image/png;base64,PREPARED",
            "prepared_date": date.today().isoformat(),
            "acknowledged_signature": "data:image/png;base64,ACKNOWLEDGED",
            "acknowledged_date": date.today().isoformat(),
        }},
    )
    assert initial.status_code == 200, initial.text

    other_headers = {
        "Authorization": f"Bearer {create_access_token(str(other_user.id), roles=['super_admin'])}"
    }
    replay_attempt = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=other_headers,
        json={"version": initial.json()["version"], "sign_off": {
            "acknowledged_signature": initial.json()["sign_off"]["acknowledged_signature"],
        }},
    )
    assert replay_attempt.status_code == 403

    prepared_replay_attempt = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=other_headers,
        json={"version": initial.json()["version"], "sign_off": {
            "prepared_signature": initial.json()["sign_off"]["prepared_signature"],
        }},
    )
    assert prepared_replay_attempt.status_code == 403

    clear_attempt = await client.put(
        f"/api/v1/bapd/{bapd_id}/sign-off",
        headers=other_headers,
        json={"version": initial.json()["version"], "sign_off": {
            "prepared_signature": "",
            "prepared_date": "",
            "acknowledged_signature": "",
            "acknowledged_date": "",
        }},
    )
    assert clear_attempt.status_code == 403


@pytest.mark.asyncio
async def test_legacy_bapd_cannot_skip_preceding_approval_step(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    from app.models.bapd import BAPDApproval, BAPDRecord

    record = BAPDRecord(
        project_id=test_project.id,
        dataset_name="Legacy Ordered Approval Dataset",
        dataset_location="db://sqlite/legacy-order",
        expiry_date=date.today(),
        reason="Testing legacy approval ordering",
        responsible_party_id=auth_user.id,
        status="under_review",
        approval_method="legacy_dual_approval",
        created_by=auth_user.id,
    )
    db.add(record)
    await db.flush()
    db.add_all([
        BAPDApproval(
            bapd_id=record.id,
            approver_id=auth_user.id,
            approver_role="data_owner",
            step_order=1,
            status="requested",
        ),
        BAPDApproval(
            bapd_id=record.id,
            approver_id=auth_user.id,
            approver_role="compliance_officer",
            step_order=2,
            status="requested",
        ),
    ])
    await db.commit()

    response = await client.post(
        f"/api/v1/bapd/{record.id}/approvals/2",
        headers=auth_headers,
        json={"action": "approve"},
    )
    assert response.status_code == 400
    assert "preceding" in response.json()["detail"].lower()

    transition = await client.post(
        f"/api/v1/bapd/{record.id}/transition",
        headers=auth_headers,
        json={"target_status": "approved"},
    )
    assert transition.status_code == 400

    record.status = "approved"
    await db.commit()
    execute = await client.post(
        f"/api/v1/bapd/{record.id}/execute",
        headers=auth_headers,
        json={"confirmation_phrase": "DELETE PERMANENTLY"},
    )
    assert execute.status_code == 400
    assert "legacy" in execute.json()["detail"].lower()

    invalid_action = await client.post(
        f"/api/v1/bapd/{record.id}/approvals/1",
        headers=auth_headers,
        json={"action": "skip"},
    )
    assert invalid_action.status_code == 422


# ── 6. Data Quality Run Review Flow E2E ───────────────────────────────────────

@pytest.mark.asyncio
async def test_dq_run_governance_review_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], db: AsyncSession, test_project, auth_user
):
    """E2E Test: DQ Run completed -> Request Revision -> Under Review -> Approve."""
    from app.models.dq import DQRun

    # 1. Seed DQ Run in completed state
    run_id = uuid.uuid4()
    dq_run = DQRun(
        id=run_id,
        project_id=test_project.id,
        run_name="Q4 Production Pipeline Verification",
        dataset_name="customer_events",
        dataset_location="gs://analytics-bucket/raw/events",
        status="completed",
        total_checks=20,
        passed_checks=18,
        failed_checks=2,
        overall_score=90.0,
        triggered_by=auth_user.id,
        created_at=datetime.now(timezone.utc),
    )
    db.add(dq_run)
    await db.commit()

    # 2. Request Revision
    rev_resp = await client.post(
        f"/api/v1/dq/{run_id}/review",
        headers=auth_headers,
        json={"action": "request_revision", "comments": "Please resolve 2 null email anomalies"},
    )
    assert rev_resp.status_code == 200, rev_resp.text
    dq_rev = rev_resp.json()
    assert dq_rev["status"] == "under_review"

    # 3. Final Approval
    app_resp = await client.post(
        f"/api/v1/dq/{run_id}/review",
        headers=auth_headers,
        json={"action": "approve", "comments": "Anomalies reconciled. Approved for production use."},
    )
    assert app_resp.status_code == 200, app_resp.text
    dq_app = app_resp.json()
    assert dq_app["status"] == "approved"


# ── 7. Dashboard Excludes DSR Approval Queue E2E ───────────────────────────────

@pytest.mark.asyncio
async def test_dashboard_action_items_queue_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """A signed DSR is approved immediately and creates no dashboard action item."""
    start_d = date.today().isoformat()
    end_d = (date.today() + timedelta(days=45)).isoformat()
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Marketing Campaign Attribution",
            "recipient": "Digital Agency",
            "purpose": "Lead conversion analysis",
            "is_ai_use": False,
            "duration_start": start_d,
            "duration_end": end_d,
        },
    )
    assert create_resp.status_code in (200, 201)
    dsr_id = create_resp.json()["id"]

    await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_dsr_checklist_payload(is_ai=False)},
    )
    submit_resp = await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)
    assert submit_resp.status_code == 200, submit_resp.text

    assert submit_resp.json()["status"] == "approved"

    # Query Dashboard
    dash_resp = await client.get("/api/v1/dashboard", headers=auth_headers)
    assert dash_resp.status_code == 200, dash_resp.text
    dash_data = dash_resp.json()
    action_items = dash_data.get("action_items", [])
    # The DSR must not be present in an approval queue.
    dsr_items = [item for item in action_items if item["entity_id"] == dsr_id]
    assert dsr_items == []


# ── 8. DSR Sign-Off Does Not Create Approval Notifications E2E ─────────────────

@pytest.mark.asyncio
async def test_dsr_signoff_does_not_create_approval_notifications(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """Form-based DSR approval has no next approver to notify."""
    start_d = date.today().isoformat()
    end_d = (date.today() + timedelta(days=60)).isoformat()
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer KYC Documents",
            "recipient": "Compliance Audit Bureau",
            "purpose": "Regulatory compliance audit",
            "is_ai_use": False,
            "duration_start": start_d,
            "duration_end": end_d,
        },
    )
    assert create_resp.status_code in (200, 201)
    dsr_id = create_resp.json()["id"]

    await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_dsr_checklist_payload(is_ai=False)},
    )
    # Submit completes the form-based approval.
    submit_resp = await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)
    assert submit_resp.status_code == 200, submit_resp.text
    assert submit_resp.json()["status"] == "approved"

    # There is no approval-chain notification for this DSR.
    notif_resp = await client.get("/api/v1/notifications", headers=auth_headers)
    assert notif_resp.status_code == 200, notif_resp.text
    dsr_notifs = [n for n in notif_resp.json()["items"] if n.get("entity_id") == dsr_id]
    assert dsr_notifs == []
