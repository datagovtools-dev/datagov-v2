"""DQ run Version: 1 for the first run of a dataset in a project, +1 for each re-check."""
import pytest
from httpx import AsyncClient


async def _add_run(db, project, user, dataset: str, version: int | None, source_file_id=None):
    from app.models.dq import DQRun

    run = DQRun(
        project_id=project.id, run_name=f"DQ Run — {dataset}", dataset_name=dataset,
        dataset_location="project_file", version=version, status="completed",
        triggered_by=user.id, source_file_id=source_file_id,
    )
    db.add(run)
    await db.commit()
    return run


@pytest.mark.asyncio
async def test_next_version_is_per_project_and_dataset(db, test_project, auth_user):
    from app.routers.dq import _next_run_version

    assert await _next_run_version(db, test_project.id, "sales.xlsx") == 1
    await _add_run(db, test_project, auth_user, "sales.xlsx", 1)
    await _add_run(db, test_project, auth_user, "sales.xlsx", 2)
    await _add_run(db, test_project, auth_user, "stock.xlsx", 1)
    assert await _next_run_version(db, test_project.id, "sales.xlsx") == 3
    assert await _next_run_version(db, test_project.id, "stock.xlsx") == 2
    assert await _next_run_version(db, test_project.id, "new.xlsx") == 1


@pytest.mark.asyncio
async def test_rerun_creates_next_version(client: AsyncClient, auth_headers, db, test_project, auth_user, monkeypatch, tmp_path):
    from app.models.metadata import ProjectSourceFile
    from app.worker.tasks import dq as dq_tasks

    dispatched = {}
    monkeypatch.setattr(dq_tasks.run_dq_generation, "delay",
                        lambda **kw: dispatched.update(kw) or type("T", (), {"id": "task-1"})())

    stored = tmp_path / "orders.xlsx"
    stored.write_bytes(b"x")
    source = ProjectSourceFile(
        project_id=test_project.id, source_type="excel", original_filename="orders.xlsx",
        stored_path=str(stored),
    )
    db.add(source)
    await db.commit()
    first = await _add_run(db, test_project, auth_user, "orders.xlsx", 1, source_file_id=source.id)

    resp = await client.post(f"/api/v1/dq/{first.id}/rerun", headers=auth_headers)
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["version"] == 2
    assert body["run_name"].endswith(" v2")
    assert body["source_file_id"] == str(source.id)
    assert dispatched["stored_path"] == str(stored)  # the re-run is actually queued


@pytest.mark.asyncio
async def test_rerun_without_source_file_is_rejected(client: AsyncClient, auth_headers, db, test_project, auth_user):
    run = await _add_run(db, test_project, auth_user, "legacy.xlsx", 1)
    resp = await client.post(f"/api/v1/dq/{run.id}/rerun", headers=auth_headers)
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_rerun_with_file_missing_on_disk_is_rejected(client: AsyncClient, auth_headers, db, test_project, auth_user, tmp_path):
    from app.models.metadata import ProjectSourceFile

    source = ProjectSourceFile(
        project_id=test_project.id, source_type="excel", original_filename="gone.xlsx",
        stored_path=str(tmp_path / "gone.xlsx"),
    )
    db.add(source)
    await db.commit()
    run = await _add_run(db, test_project, auth_user, "gone.xlsx", 1, source_file_id=source.id)
    resp = await client.post(f"/api/v1/dq/{run.id}/rerun", headers=auth_headers)
    assert resp.status_code == 400
    assert "re-upload it in Metadata" in resp.json()["detail"]
