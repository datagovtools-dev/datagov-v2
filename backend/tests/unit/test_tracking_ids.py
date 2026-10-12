"""Regression tests for yearly governance tracking ID allocation."""
from datetime import date, datetime, timezone

import pytest
from sqlalchemy.ext.asyncio import AsyncSession

import app.worker.tasks.notifications  # noqa: F401 - make the patch target importable


@pytest.mark.asyncio
async def test_dsr_tracking_id_uses_highest_existing_sequence(
    db: AsyncSession, test_project, auth_user
):
    from app.models.dsr import DataSharingRequest
    from app.routers.dsr import _gen_tracking_id

    now = datetime.now(timezone.utc)
    for sequence in (1, 3):
        db.add(
            DataSharingRequest(
                tracking_id=f"DSR-{now.year}-{sequence:04d}",
                project_id=test_project.id,
                requester_id=auth_user.id,
                dataset_name=f"Dataset {sequence}",
                recipient="Internal Audit",
                purpose="Tracking ID regression test",
                duration_start=date.today(),
                duration_end=date.today(),
                created_at=now,
            )
        )
    await db.flush()

    assert await _gen_tracking_id(db) == f"DSR-{now.year}-0004"


@pytest.mark.asyncio
async def test_dpia_tracking_id_uses_highest_existing_sequence(
    db: AsyncSession, test_project, auth_user
):
    from app.models.dpia import DPIARecord
    from app.routers.dsr import _next_dpia_tracking_id

    now = datetime.now(timezone.utc)
    for sequence in (1, 3):
        db.add(
            DPIARecord(
                tracking_id=f"DPIA-{now.year}-{sequence:04d}",
                project_id=test_project.id,
                process_name=f"Process {sequence}",
                purpose="Tracking ID regression test",
                data_category="Business",
                risk_description="Low risk",
                assessment_date=date.today(),
                responsible_party_id=auth_user.id,
                created_by=auth_user.id,
                created_at=now,
            )
        )
    await db.flush()

    assert await _next_dpia_tracking_id(db) == f"DPIA-{now.year}-0004"


@pytest.mark.asyncio
async def test_create_dsr_skips_existing_tracking_id_gap(
    client, auth_headers, db: AsyncSession, test_project, auth_user, monkeypatch
):
    async def _not_denied(_jti: str) -> bool:
        return False

    monkeypatch.setattr("app.core.deps.is_token_denied", _not_denied)
    from app.models.dsr import DataSharingRequest

    now = datetime.now(timezone.utc)
    for sequence in (1, 3):
        db.add(
            DataSharingRequest(
                tracking_id=f"DSR-{now.year}-{sequence:04d}",
                project_id=test_project.id,
                requester_id=auth_user.id,
                dataset_name=f"Existing Dataset {sequence}",
                recipient="Internal Audit",
                purpose="Tracking ID regression test",
                duration_start=date.today(),
                duration_end=date.today(),
                created_at=now,
            )
        )
    await db.commit()

    response = await client.post(
        "/api/v1/dsr",
        headers=auth_headers,
        json={
            "dataset_name": "New Dataset",
            "recipient": "Internal Audit",
            "purpose": "Verify gap-safe tracking ID allocation",
            "is_ai_use": False,
            "duration_start": str(date.today()),
            "duration_end": str(date.today()),
            "project_id": str(test_project.id),
        },
    )

    assert response.status_code == 201
    assert response.json()["tracking_id"] == f"DSR-{now.year}-0004"
