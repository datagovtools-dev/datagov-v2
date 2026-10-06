"""End-to-end API tests for privileged project-asset deletion."""
from datetime import date, timedelta
from pathlib import Path

import pytest
from sqlalchemy import func, select


@pytest.fixture(autouse=True)
def disable_redis_denylist(monkeypatch):
    async def _not_denied(_jti):
        return False
    monkeypatch.setattr("app.core.deps.is_token_denied", _not_denied)


@pytest.mark.asyncio
async def test_asset_deletion_is_superadmin_only(client, db, test_project, auth_user):
    from app.core.security import create_access_token, hash_password
    from app.models.user import Role, User, UserProjectRole

    role = Role(name="regular_user", description="Regular user", permissions=["project:read"])
    db.add(role)
    await db.flush()
    user = User(
        full_name="Regular Test User",
        email="regular-delete-test@example.test",
        password_hash=hash_password("not-used-in-test"),
        is_active=True,
    )
    db.add(user)
    await db.flush()
    db.add(UserProjectRole(user_id=user.id, role_id=role.id, assigned_by=auth_user.id))
    await db.commit()

    token = create_access_token(str(user.id), roles=["regular_user"])
    headers = {"Authorization": f"Bearer {token}"}
    preview = await client.get(f"/api/v1/projects/{test_project.id}/deletion-preview", headers=headers)
    deleted = await client.delete(
        f"/api/v1/projects/{test_project.id}?confirmation_code={test_project.project_code}",
        headers=headers,
    )

    assert preview.status_code == 403
    assert deleted.status_code == 403


@pytest.mark.asyncio
async def test_asset_deletion_requires_exact_confirmation(client, db, test_project, auth_headers):
    response = await client.delete(
        f"/api/v1/projects/{test_project.id}?confirmation_code=WRONG-CODE",
        headers=auth_headers,
    )
    assert response.status_code == 400
    assert "Confirmation code" in response.json()["detail"]
    assert (await db.get(type(test_project), test_project.id)) is not None


@pytest.mark.asyncio
async def test_asset_deletion_cascades_project_owned_records_and_retains_audit(
    client, db, test_project, auth_user, auth_headers, tmp_path: Path, monkeypatch
):
    from app.models.bapd import BAPDApproval, BAPDRecord
    from app.models.dpia import DPIAApproval, DPIARecord
    from app.models.dq import DQFinding, DQGCPArchive, DQResult, DQRun
    from app.models.dsr import DSRApproval, DataSharingRequest
    from app.models.metadata import DataOwnerSteward, MetadataRecord, ProjectSourceFile
    from app.models.notification import Notification
    from app.models.ropa import ROPARecord
    from app.models.user import AuditLog, Role, UserProjectRole

    import app.services.project_deletion as deletion_service

    uploads_root = tmp_path / "uploads"
    shared_root = tmp_path / "shared_uploads"
    stored = uploads_root / str(test_project.id) / "asset.xlsx"
    shared = shared_root / str(test_project.id) / "asset.xlsx"
    stored.parent.mkdir(parents=True)
    shared.parent.mkdir(parents=True)
    stored.write_bytes(b"test upload")
    shared.write_bytes(b"shared test upload")
    monkeypatch.setattr(deletion_service, "UPLOADS_ROOT", str(uploads_root))
    monkeypatch.setattr(deletion_service, "SHARED_ROOT", str(shared_root))

    source = ProjectSourceFile(
        project_id=test_project.id,
        source_type="excel",
        original_filename="asset.xlsx",
        stored_path=str(stored),
        file_size=12,
        uploaded_by=str(auth_user.id),
    )
    db.add(source)
    await db.flush()

    db.add(MetadataRecord(
        project_id=test_project.id, seq_no=1, business_users="Finance",
        data_domain_table="payments", project_name=test_project.project_name,
        project_year=test_project.project_year, data_attribute="amount",
        source_type="upload", remarks="-", data_sensitivity="Confidential",
    ))
    db.add(DataOwnerSteward(
        project_id=test_project.id, role_type="data_owner", full_name="Owner",
        email="owner@example.test",
    ))

    run = DQRun(
        project_id=test_project.id, source_file_id=source.id, run_name="Test DQ",
        dataset_name="payments", dataset_location="uploaded", status="completed",
        triggered_by=auth_user.id,
    )
    db.add(run)
    await db.flush()
    result = DQResult(
        run_id=run.id, check_name="Completeness", check_type="completeness",
        column_name="amount", status="fail", row_count=10, failed_count=2,
    )
    db.add(result)
    await db.flush()
    db.add(DQFinding(result_id=result.id, severity="warning", description="Missing values"))
    db.add(DQGCPArchive(run_id=run.id, archive_status="completed", gcs_report_path="gs://bucket/report"))

    dsr = DataSharingRequest(
        tracking_id="DSR-DELETE-001", project_id=test_project.id, requester_id=auth_user.id,
        dataset_name="payments", recipient="Internal Audit", purpose="Testing",
        duration_start=date.today(), duration_end=date.today() + timedelta(days=30),
    )
    db.add(dsr)
    await db.flush()
    db.add(DSRApproval(dsr_id=dsr.id, approver_id=auth_user.id, approver_role="dpo", step_order=1))

    dpia = DPIARecord(
        tracking_id="DPIA-DELETE-001", project_id=test_project.id, process_name="Testing",
        purpose="Testing", data_category="Business", risk_description="Low",
        assessment_date=date.today(), responsible_party_id=auth_user.id, created_by=auth_user.id,
    )
    db.add(dpia)
    await db.flush()
    db.add(DPIAApproval(dpia_id=dpia.id, approver_id=auth_user.id, approver_role="dpo", step_order=1))

    bapd = BAPDRecord(
        project_id=test_project.id, dataset_name="payments", dataset_location="uploaded",
        expiry_date=date.today() + timedelta(days=30), reason="Testing",
        responsible_party_id=auth_user.id, created_by=auth_user.id,
    )
    db.add(bapd)
    await db.flush()
    db.add(BAPDApproval(bapd_id=bapd.id, approver_id=auth_user.id, approver_role="dpo", step_order=1))

    db.add(ROPARecord(
        project_id=test_project.id, process_name="Testing", purpose="Testing",
        data_category="Business", data_subject="Customers", legal_basis="Contract",
        retention_period="30 days", created_by=auth_user.id,
    ))
    role = (await db.execute(select(Role).where(Role.name == "super_admin"))).scalar_one()
    db.add(UserProjectRole(user_id=auth_user.id, role_id=role.id, project_id=test_project.id, assigned_by=auth_user.id))
    db.add(Notification(
        user_id=auth_user.id, module="project", event="project.updated", title="Project changed",
        entity_type="project", entity_id=str(test_project.id),
    ))
    await db.commit()

    preview = await client.get(f"/api/v1/projects/{test_project.id}/deletion-preview", headers=auth_headers)
    assert preview.status_code == 200, preview.text
    preview_data = preview.json()
    assert preview_data["can_delete"] is True
    assert preview_data["related_counts"]["metadata_records"] == 1
    assert preview_data["related_counts"]["dq_runs"] == 1
    assert preview_data["related_counts"]["dsr_requests"] == 1
    assert preview_data["related_counts"]["dpia_records"] == 1
    assert preview_data["related_counts"]["bapd_records"] == 1
    assert preview_data["uploaded_file_count"] == 1

    response = await client.delete(
        f"/api/v1/projects/{test_project.id}?confirmation_code={test_project.project_code}",
        headers=auth_headers,
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["deleted_counts"]["metadata_records"] == 1
    assert body["files_deleted"] == 1
    assert not stored.exists()
    assert not shared.exists()

    for model in (
        ProjectSourceFile, MetadataRecord, DataOwnerSteward, DQRun, DQResult, DQFinding,
        DQGCPArchive, DataSharingRequest, DSRApproval, DPIARecord, DPIAApproval,
        BAPDRecord, BAPDApproval, ROPARecord, UserProjectRole, Notification,
    ):
        if model is UserProjectRole:
            statement = select(func.count()).select_from(model).where(model.project_id == test_project.id)
        else:
            statement = select(func.count()).select_from(model)
        assert (await db.execute(statement)).scalar_one() == 0, model.__name__

    from app.models.project import Project
    assert (await db.execute(select(func.count()).select_from(Project).where(Project.id == test_project.id))).scalar_one() == 0

    audit_rows = (
        await db.execute(
            select(AuditLog).where(AuditLog.entity_id == str(test_project.id), AuditLog.action == "delete")
        )
    ).scalars().all()
    assert len(audit_rows) == 1
    assert audit_rows[0].details["audit_retained"] is True


@pytest.mark.asyncio
async def test_asset_deletion_blocks_active_dq_run(client, db, test_project, auth_user, auth_headers):
    from app.models.dq import DQRun

    db.add(DQRun(
        project_id=test_project.id, run_name="Active DQ", dataset_name="payments",
        dataset_location="uploaded", status="running", triggered_by=auth_user.id,
    ))
    await db.commit()

    response = await client.delete(
        f"/api/v1/projects/{test_project.id}?confirmation_code={test_project.project_code}",
        headers=auth_headers,
    )
    assert response.status_code == 409
    assert "pending or running" in response.json()["detail"]
    assert await db.get(type(test_project), test_project.id) is not None
