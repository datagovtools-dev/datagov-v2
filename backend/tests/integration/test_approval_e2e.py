"""End-to-end integration tests for all Governance Approval workflows.
Covers DSR, AI Compliance Checklist, DPIA, BAPD Disposal, and DQ Runs.
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
    }
    return payload


def _complete_ai_assessment_payload() -> dict:
    item_ids = [
        "before_use_1", "before_use_2", "before_use_3",
        "input_1", "input_2", "input_3",
        "output_1", "output_2",
        "utilization_1", "utilization_2",
    ]
    return {
        "ai_assessment": {
            "items": {
                item_id: {
                    "status": "COMPLIED",
                    "notes": "Verified and audited model compliance",
                    "evidence_url": "https://compliance.internal/docs",
                }
                for item_id in item_ids
            },
            "sign_off": {
                "approved": "Yes",
                "prepared_by": "AI Governance Lead",
                "prepared_position": "Principal AI Architect",
                "acknowledged_by": "Ethics Officer",
                "acknowledged_position": "Chief Compliance Officer",
            },
        }
    }


# ── 1. DSR Full Approval Lifecycle E2E ────────────────────────────────────────

@pytest.mark.asyncio
async def test_dsr_full_approval_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """E2E Test: DSR Draft -> Submitted -> Step 1 -> Step 2 -> Step 3 -> Step 4 -> Approved."""
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
    assert len(dsr_data["approvals"]) == 4
    assert all(a["status"] == "pending" for a in dsr_data["approvals"])

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
    dsr_submitted = submit_resp.json()
    assert dsr_submitted["status"] == "submitted"
    step1 = next(a for a in dsr_submitted["approvals"] if a["step_order"] == 1)
    assert step1["status"] == "requested"

    # 4. Action Step 1 (PIC Compliance)
    s1_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "Step 1 Compliance Approved"},
    )
    assert s1_resp.status_code == 200, s1_resp.text
    d_s1 = s1_resp.json()
    assert d_s1["status"] == "under_review"
    s1_app = next(a for a in d_s1["approvals"] if a["step_order"] == 1)
    s2_app = next(a for a in d_s1["approvals"] if a["step_order"] == 2)
    assert s1_app["status"] == "approved"
    assert s1_app["comments"] == "Step 1 Compliance Approved"
    assert s2_app["status"] == "requested"

    # 5. Action Step 2 (DM / PM)
    s2_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/2",
        headers=auth_headers,
        json={"action": "approve", "comments": "Step 2 DM Approved"},
    )
    assert s2_resp.status_code == 200, s2_resp.text
    d_s2 = s2_resp.json()
    s3_app = next(a for a in d_s2["approvals"] if a["step_order"] == 3)
    assert s3_app["status"] == "requested"

    # 6. Action Step 3 (SME Sign-off)
    s3_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/3",
        headers=auth_headers,
        json={"action": "approve", "comments": "Step 3 SME Approved"},
    )
    assert s3_resp.status_code == 200, s3_resp.text
    d_s3 = s3_resp.json()
    s4_app = next(a for a in d_s3["approvals"] if a["step_order"] == 4)
    assert s4_app["status"] == "requested"

    # 7. Action Step 4 (Client / Data Owner Sign-off)
    s4_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/4",
        headers=auth_headers,
        json={"action": "approve", "comments": "Step 4 Client Final Sign-off"},
    )
    assert s4_resp.status_code == 200, s4_resp.text
    d_s4 = s4_resp.json()
    assert d_s4["status"] == "approved"
    s4_app = next(a for a in d_s4["approvals"] if a["step_order"] == 4)
    assert s4_app["status"] == "approved"
    assert all(a["status"] == "approved" for a in d_s4["approvals"])


# ── 2. DSR Rejection Flow E2E ─────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_dsr_rejection_flow_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """E2E Test: DSR Rejection halts pipeline and updates status to rejected."""
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

    await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_dsr_checklist_payload(is_ai=False)},
    )
    await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)

    # Reject Step 1
    reject_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/1",
        headers=auth_headers,
        json={"action": "reject", "comments": "Data transfer violates security policy"},
    )
    assert reject_resp.status_code == 200
    d_rej = reject_resp.json()
    assert d_rej["status"] == "rejected"
    s1 = next(a for a in d_rej["approvals"] if a["step_order"] == 1)
    assert s1["status"] == "rejected"
    assert s1["comments"] == "Data transfer violates security policy"


# ── 3. AI Compliance Checklist Approval Flow E2E ──────────────────────────────

@pytest.mark.asyncio
async def test_ai_checklist_approval_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """E2E Test: AI Checklist Submit -> Step 1 -> Step 2 -> Step 3 -> Approved."""
    # 1. Create DSR with is_ai_use=True
    start_d = date.today().isoformat()
    end_d = (date.today() + timedelta(days=60)).isoformat()
    create_resp = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Customer Service Chat Logs",
            "recipient": "GenAI Inference Cluster",
            "purpose": "LLM Fine-tuning and RAG",
            "is_ai_use": True,
            "duration_start": start_d,
            "duration_end": end_d,
        },
    )
    assert create_resp.status_code in (200, 201)
    dsr_id = create_resp.json()["id"]

    # 2. Populate AI assessment checklist
    save_resp = await client.put(
        f"/api/v1/dsr/{dsr_id}/checklist",
        headers=auth_headers,
        json={"checklist_json": _complete_ai_assessment_payload()},
    )
    assert save_resp.status_code == 200, save_resp.text

    # 3. Submit AI Checklist for approval
    submit_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/checklist/submit",
        headers=auth_headers,
    )
    assert submit_resp.status_code == 200, submit_resp.text
    dsr_ck_sub = submit_resp.json()
    ck_sub = dsr_ck_sub["ai_checklist"]
    assert ck_sub["status"] == "submitted"
    ai_s1 = next(a for a in ck_sub["approvals"] if a["step_order"] == 1)
    assert ai_s1["status"] == "requested"

    # 4. Action Step 1 (PIC Compliance)
    s1_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/checklist/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "AI Step 1 Approved"},
    )
    assert s1_resp.status_code == 200, s1_resp.text
    ck_s1 = s1_resp.json()["ai_checklist"]
    assert ck_s1["status"] == "under_review"

    # 5. Action Step 2 (DM)
    s2_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/checklist/approvals/2",
        headers=auth_headers,
        json={"action": "approve", "comments": "AI Step 2 Approved"},
    )
    assert s2_resp.status_code == 200, s2_resp.text
    ck_s2 = s2_resp.json()["ai_checklist"]
    ai_s3 = next(a for a in ck_s2["approvals"] if a["step_order"] == 3)
    assert ai_s3["status"] == "requested"

    # 6. Action Step 3 (SME Final Sign-off)
    s3_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/checklist/approvals/3",
        headers=auth_headers,
        json={"action": "approve", "comments": "AI Step 3 Final Sign-off"},
    )
    assert s3_resp.status_code == 200, s3_resp.text
    ck_s3 = s3_resp.json()["ai_checklist"]
    assert ck_s3["status"] == "approved"
    assert all(a["status"] == "approved" for a in ck_s3["approvals"])


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


# ── 5. BAPD Dual Approval and Disposal Execution E2E ──────────────────────────

@pytest.mark.asyncio
async def test_bapd_dual_approval_and_execution_lifecycle_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project, auth_user
):
    """E2E Test: BAPD Draft -> Submitted -> Step 1 -> Step 2 -> Approved -> Execute Disposal & POD."""
    # 1. Create BAPD
    exp_d = date.today().isoformat()
    create_resp = await client.post(
        "/api/v1/bapd",
        headers=auth_headers,
        json={
            "project_id": str(test_project.id),
            "dataset_name": "Expired Temporary Staging Data",
            "dataset_location": "gs://datagov-staging-temp/2025/q4",
            "expiry_date": exp_d,
            "reason": "Retention window of 90 days expired as per GDPR/UU PDP Article 27",
            "responsible_party_id": str(auth_user.id),
        },
    )
    assert create_resp.status_code in (200, 201), create_resp.text
    bapd_data = create_resp.json()
    bapd_id = bapd_data["id"]
    assert bapd_data["status"] == "draft"
    assert len(bapd_data["approvals"]) == 2

    # 2. Transition to submitted
    trans_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/transition",
        headers=auth_headers,
        json={"target_status": "submitted", "comments": "Submitting BAPD for data destruction review"},
    )
    assert trans_resp.status_code == 200, trans_resp.text
    b_sub = trans_resp.json()
    assert b_sub["status"] == "submitted"
    s1 = next(a for a in b_sub["approvals"] if a["step_order"] == 1)
    assert s1["status"] == "requested"

    # 3. Action Step 1 (Data Owner / DGO)
    s1_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "Data Owner confirms data is eligible for purge"},
    )
    assert s1_resp.status_code == 200, s1_resp.text
    b_s1 = s1_resp.json()
    assert b_s1["status"] == "under_review"
    s2 = next(a for a in b_s1["approvals"] if a["step_order"] == 2)
    assert s2["status"] == "requested"

    # 4. Action Step 2 (Compliance Officer)
    s2_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/approvals/2",
        headers=auth_headers,
        json={"action": "approve", "comments": "Compliance Officer verifies disposal mandate"},
    )
    assert s2_resp.status_code == 200, s2_resp.text
    b_s2 = s2_resp.json()
    assert b_s2["status"] == "approved"

    # 5. Execute Data Disposal
    exec_resp = await client.post(
        f"/api/v1/bapd/{bapd_id}/execute",
        headers=auth_headers,
    )
    assert exec_resp.status_code == 200, exec_resp.text
    b_exec = exec_resp.json()
    assert b_exec["status"] == "executed"
    assert b_exec["pod_file_path"] is not None
    assert b_exec["executed_at"] is not None

    # 6. Fetch Proof of Deletion (POD)
    pod_resp = await client.get(
        f"/api/v1/bapd/{bapd_id}/pod",
        headers=auth_headers,
    )
    assert pod_resp.status_code == 200, pod_resp.text
    assert len(pod_resp.content) > 0


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


# ── 7. Dashboard Action Items Queue E2E ───────────────────────────────────────

@pytest.mark.asyncio
async def test_dashboard_action_items_queue_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project
):
    """E2E Test: Dashboard reflects active approval items waiting in queue."""
    # Create DSR and submit it so it enters Step 1 "requested"
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

    # Query Dashboard
    dash_resp = await client.get("/api/v1/dashboard", headers=auth_headers)
    assert dash_resp.status_code == 200, dash_resp.text
    dash_data = dash_resp.json()
    action_items = dash_data.get("action_items", [])
    assert len(action_items) > 0
    # Check that our DSR is present in action items queue with active approval step
    dsr_items = [item for item in action_items if item["entity_id"] == dsr_id]
    assert len(dsr_items) >= 1
    assert "DSR" in dsr_items[0]["title"]


# ── 8. In-App Bell Notifications for Next Approver E2E ────────────────────────

@pytest.mark.asyncio
async def test_in_app_bell_notifications_next_approver_e2e(
    client: AsyncClient, auth_headers: dict[str, str], test_project, auth_user
):
    """E2E Test: Advancing an approval step immediately generates an in-app notification for the next approver's UI bell."""
    # 1. Create and submit a DSR
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
    # Submit -> triggers Step 1 notification for Step 1 approver
    submit_resp = await client.post(f"/api/v1/dsr/{dsr_id}/submit", headers=auth_headers)
    assert submit_resp.status_code == 200

    # 2. Check in-app notifications endpoint (which powers the header bell icon in frontend)
    notif_resp = await client.get("/api/v1/notifications", headers=auth_headers)
    assert notif_resp.status_code == 200, notif_resp.text
    notif_data = notif_resp.json()
    assert notif_data["unread_count"] > 0
    items = notif_data["items"]
    dsr_notifs = [n for n in items if n.get("entity_id") == dsr_id]
    assert len(dsr_notifs) >= 1
    assert "Approval Required" in dsr_notifs[0]["title"] or "DSR" in dsr_notifs[0]["title"]

    # 3. Action Step 1 -> Should generate next notification for Step 2
    s1_resp = await client.post(
        f"/api/v1/dsr/{dsr_id}/approvals/1",
        headers=auth_headers,
        json={"action": "approve", "comments": "Step 1 Compliance verified"},
    )
    assert s1_resp.status_code == 200

    # 4. Check that a new notification for Step 2 was added to notifications
    notif_resp2 = await client.get("/api/v1/notifications", headers=auth_headers)
    notif_data2 = notif_resp2.json()
    assert notif_data2["unread_count"] >= 2
    step2_notifs = [n for n in notif_data2["items"] if n.get("entity_id") == dsr_id and "Step 2" in (n.get("body") or "")]
    assert len(step2_notifs) >= 1

    # 5. Mark first notification as read
    first_notif_id = dsr_notifs[0]["id"]
    read_resp = await client.put(f"/api/v1/notifications/{first_notif_id}/read", headers=auth_headers)
    assert read_resp.status_code == 200
    assert read_resp.json()["is_read"] is True
