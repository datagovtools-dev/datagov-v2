"""Project DQ report: latest run with results per table."""
from datetime import datetime, timedelta, timezone

import pytest
from httpx import AsyncClient


async def _run(db, project, user, dataset: str, status: str, minutes_ago: int, scores: dict[str, float]):
    from app.models.dq import DQResult, DQRun

    run = DQRun(project_id=project.id, run_name=f"DQ Run — {dataset}", dataset_name=dataset,
                dataset_location="project_file", status=status, triggered_by=user.id,
                created_at=datetime.now(timezone.utc) - timedelta(minutes=minutes_ago))
    db.add(run)
    await db.flush()
    for column, score in scores.items():
        db.add(DQResult(run_id=run.id, check_name=f"{column}__completeness", check_type="completeness",
                        column_name=column, status="pass" if score >= 95 else "fail", actual_value=str(score)))
    await db.commit()
    return run


@pytest.mark.asyncio
async def test_report_uses_latest_run_with_results_per_table(client: AsyncClient, auth_headers, db, test_project, auth_user):
    await _run(db, test_project, auth_user, "sales.xlsx", "completed", 30, {"a": 50.0})
    newest_sales = await _run(db, test_project, auth_user, "sales.xlsx", "completed", 10, {"a": 100.0, "b": 90.0})
    stock_ok = await _run(db, test_project, auth_user, "stock.xlsx", "completed", 20, {"id": 100.0})
    await _run(db, test_project, auth_user, "stock.xlsx", "failed", 5, {})  # newer run failed
    await _run(db, test_project, auth_user, "gone.xlsx", "failed", 5, {})   # never produced results

    resp = await client.get(f"/api/v1/dq/project/{test_project.id}/report", headers=auth_headers)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    tables = {t["dataset_name"]: t for t in body["tables"]}
    assert set(tables) == {"sales.xlsx", "stock.xlsx"}
    assert tables["sales.xlsx"]["run"]["id"] == str(newest_sales.id)
    assert len(tables["sales.xlsx"]["run"]["results"]) == 2
    assert tables["sales.xlsx"]["newer_run_status"] is None
    assert tables["stock.xlsx"]["run"]["id"] == str(stock_ok.id)
    assert tables["stock.xlsx"]["newer_run_status"] == "failed"
    assert body["tables_without_results"] == ["gone.xlsx"]


@pytest.mark.asyncio
async def test_report_for_project_without_runs_is_empty(client: AsyncClient, auth_headers, test_project):
    body = (await client.get(f"/api/v1/dq/project/{test_project.id}/report", headers=auth_headers)).json()
    assert body["tables"] == [] and body["tables_without_results"] == []
