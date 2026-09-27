"""DQ progress page, no double start, and the previous version staying visible during a re-run."""
from datetime import datetime, timedelta, timezone

import pytest
import pytest_asyncio
from httpx import AsyncClient


@pytest_asyncio.fixture(autouse=True)
async def _finish_active_runs(db):
    """The DQ queue is global: close this module's queued/running runs so other tests see an empty queue."""
    yield
    from sqlalchemy import update

    from app.models.dq import DQRun

    await db.execute(update(DQRun).where(DQRun.status.in_(("pending", "running"))).values(status="failed"))
    await db.commit()


async def _file(db, project, tmp_path, name="sales.xlsx"):
    from app.models.metadata import ProjectSourceFile

    path = tmp_path / name
    path.write_bytes(b"x")
    source = ProjectSourceFile(project_id=project.id, source_type="excel", original_filename=name, stored_path=str(path))
    db.add(source)
    await db.commit()
    return source


async def _run(db, project, user, source, status, version=1, minutes_ago=1, score=None):
    from app.models.dq import DQRun

    run = DQRun(project_id=project.id, source_file_id=source.id, run_name=f"DQ v{version}",
                dataset_name=source.original_filename, dataset_location=f"project_file://{source.id}",
                version=version, status=status, triggered_by=user.id, overall_score=score,
                created_at=datetime.now(timezone.utc) - timedelta(minutes=minutes_ago))
    db.add(run)
    await db.commit()
    return run


@pytest.mark.asyncio
async def test_second_start_of_a_queued_file_is_refused(client: AsyncClient, auth_headers, db, test_project, auth_user, tmp_path):
    source = await _file(db, test_project, tmp_path)
    await _run(db, test_project, auth_user, source, "pending")
    resp = await client.post("/api/v1/dq", headers=auth_headers, json={
        "project_id": str(test_project.id), "run_name": "again", "source_type": "project_file",
        "dataset_name": source.original_filename, "dataset_location": "project_file", "source_file_id": str(source.id),
    })
    assert resp.status_code == 409
    assert "already queued (version 1)" in resp.json()["detail"]

    files = (await client.get(f"/api/v1/dq/project/{test_project.id}/sources", headers=auth_headers)).json()
    assert files[0]["active_run_status"] == "pending"


@pytest.mark.asyncio
async def test_rerun_while_a_version_is_running_is_refused(client: AsyncClient, auth_headers, db, test_project, auth_user, tmp_path):
    source = await _file(db, test_project, tmp_path)
    done = await _run(db, test_project, auth_user, source, "completed", version=1, minutes_ago=30, score=91.5)
    await _run(db, test_project, auth_user, source, "running", version=2)
    resp = await client.post(f"/api/v1/dq/{done.id}/rerun", headers=auth_headers)
    assert resp.status_code == 409
    assert "already running (version 2)" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_table_summary_keeps_previous_version_while_rerun_runs(client: AsyncClient, auth_headers, db, test_project, auth_user, tmp_path):
    from app.models.metadata import MetadataRecord

    source = await _file(db, test_project, tmp_path)
    db.add(MetadataRecord(project_id=test_project.id, seq_no=1, data_domain_table="sales.xlsx - Sheet1",
                          data_attribute="amount", source_type="excel", business_users="Test Customer PT",
                          project_name=test_project.project_name, project_year=2026))
    await db.commit()
    done = await _run(db, test_project, auth_user, source, "completed", version=1, minutes_ago=30, score=91.5)
    rerun = await _run(db, test_project, auth_user, source, "running", version=2)

    row = (await client.get(f"/api/v1/dq/project/{test_project.id}/tables-summary", headers=auth_headers)).json()[0]
    assert row["latest_run_id"] == str(done.id) and row["latest_run_version"] == 1
    assert row["latest_run_score"].startswith("91.5")
    assert (row["newer_run_id"], row["newer_run_status"], row["newer_run_version"]) == (str(rerun.id), "running", 2)


@pytest.mark.asyncio
async def test_progress_lists_active_and_recent_runs(client: AsyncClient, auth_headers, db, test_project, auth_user, tmp_path):
    a = await _file(db, test_project, tmp_path, "a.xlsx")
    b = await _file(db, test_project, tmp_path, "b.xlsx")
    c = await _file(db, test_project, tmp_path, "c.xlsx")
    await _run(db, test_project, auth_user, a, "completed", minutes_ago=20, score=99.0)
    await _run(db, test_project, auth_user, b, "running", minutes_ago=10)
    await _run(db, test_project, auth_user, c, "pending", minutes_ago=9)
    await _run(db, test_project, auth_user, c, "completed", minutes_ago=60 * 24 * 3)  # old: not listed

    body = (await client.get(f"/api/v1/dq/project/{test_project.id}/progress", headers=auth_headers)).json()
    assert body["active_count"] == 2
    assert body["eta_seconds"] > 0
    assert [(r["dataset_name"], r["status"]) for r in body["runs"]] == [
        ("a.xlsx", "completed"), ("b.xlsx", "running"), ("c.xlsx", "pending")]
