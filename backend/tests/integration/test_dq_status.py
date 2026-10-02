"""Generate step: progress, queue position, time estimate and failure explanation from /dq/{id}/status."""
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient


async def _run(db, project, user, status: str, **fields):
    from app.models.dq import DQRun

    run = DQRun(project_id=project.id, run_name=f"run {status}", dataset_name="d.xlsx",
                dataset_location="project_file", status=status, triggered_by=user.id, **fields)
    db.add(run)
    await db.commit()
    return run


@pytest.mark.asyncio
async def test_running_run_reports_column_progress_and_eta(client: AsyncClient, auth_headers, db, test_project, auth_user):
    started = datetime.now(timezone.utc) - timedelta(seconds=120)
    run = await _run(db, test_project, auth_user, "running", columns_total=10, columns_done=4, started_at=started)
    body = (await client.get(f"/api/v1/dq/{run.id}/status", headers=auth_headers)).json()
    assert body["progress_pct"] == 40
    assert body["message"] == "Running — 4 of 10 columns done"
    # speed so far (120 s / 4 columns) blended with the usual 65 s/column: ~42 s/column, 10 columns - 120 s elapsed
    assert 280 <= body["eta_seconds"] <= 310


@pytest.mark.asyncio
async def test_slow_first_column_does_not_swing_the_estimate(client: AsyncClient, auth_headers, db, test_project, auth_user):
    # live case 2026-09-27: first column took 255 s (model loading + busy CPU)
    started = datetime.now(timezone.utc) - timedelta(seconds=255)
    run = await _run(db, test_project, auth_user, "running", columns_total=11, columns_done=1, started_at=started)
    body = (await client.get(f"/api/v1/dq/{run.id}/status", headers=auth_headers)).json()
    assert body["eta_seconds"] < 1300  # was 2550 s with the plain average


@pytest.mark.asyncio
async def test_pending_run_waits_for_runs_ahead(client: AsyncClient, auth_headers, db, test_project, auth_user):
    now = datetime.now(timezone.utc)
    await _run(db, test_project, auth_user, "running", columns_total=5, columns_done=0,
               started_at=now, created_at=now - timedelta(minutes=2))
    queued = await _run(db, test_project, auth_user, "pending", columns_total=5, created_at=now - timedelta(minutes=1))
    body = (await client.get(f"/api/v1/dq/{queued.id}/status", headers=auth_headers)).json()
    assert body["queue_position"] == 1
    assert body["message"] == "Queued — 1 file ahead"
    assert body["eta_seconds"] > 5 * 65  # its own 5 columns plus the run ahead


@pytest.mark.asyncio
async def test_failed_run_explains_why(client: AsyncClient, auth_headers, db, test_project, auth_user):
    run = await _run(db, test_project, auth_user, "failed", error_category="ai_model_missing",
                     error_message="Model 'llama3.2:3b' was not found on the Ollama server.")
    body = (await client.get(f"/api/v1/dq/{run.id}/status", headers=auth_headers)).json()
    assert body["error_title"] == "AI model not installed"
    assert "Settings > AI Setup" in body["error_action"]
    assert body["error_detail"].startswith("Model 'llama3.2:3b'")
    assert body["will_retry"] is False


@pytest.mark.asyncio
async def test_older_failed_run_with_missing_file_is_explained(client: AsyncClient, auth_headers, db, test_project, auth_user, tmp_path):
    from app.models.metadata import ProjectSourceFile

    source = ProjectSourceFile(project_id=test_project.id, source_type="excel", original_filename="gone.xlsx",
                               stored_path=str(tmp_path / "gone.xlsx"))
    db.add(source)
    await db.commit()
    run = await _run(db, test_project, auth_user, "failed", source_file_id=source.id)
    body = (await client.get(f"/api/v1/dq/{run.id}/status", headers=auth_headers)).json()
    assert body["error_category"] == "source_file_missing"
    assert body["error_detail"] == "Missing file: gone.xlsx"


@pytest.mark.asyncio
async def test_new_run_on_missing_file_is_refused(client: AsyncClient, auth_headers, db, test_project, tmp_path):
    from app.models.metadata import ProjectSourceFile

    source = ProjectSourceFile(project_id=test_project.id, source_type="excel", original_filename="gone.xlsx",
                               stored_path=str(tmp_path / "gone.xlsx"))
    db.add(source)
    await db.commit()
    resp = await client.post("/api/v1/dq", headers=auth_headers, json={
        "project_id": str(test_project.id), "run_name": "x", "source_type": "project_file",
        "dataset_name": "gone.xlsx", "dataset_location": "project_file", "source_file_id": str(source.id),
    })
    assert resp.status_code == 400
    assert "re-upload it in Metadata" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_sources_flag_files_missing_on_disk(client: AsyncClient, auth_headers, db, test_project, tmp_path):
    from app.models.metadata import ProjectSourceFile

    present = tmp_path / "here.xlsx"
    present.write_bytes(b"x")
    db.add_all([
        ProjectSourceFile(project_id=test_project.id, source_type="excel", original_filename="here.xlsx", stored_path=str(present)),
        ProjectSourceFile(project_id=test_project.id, source_type="excel", original_filename="gone.xlsx", stored_path=str(tmp_path / "gone.xlsx")),
    ])
    await db.commit()
    files = (await client.get(f"/api/v1/dq/project/{test_project.id}/sources", headers=auth_headers)).json()
    assert {f["original_filename"]: f["file_available"] for f in files} == {"here.xlsx": True, "gone.xlsx": False}
