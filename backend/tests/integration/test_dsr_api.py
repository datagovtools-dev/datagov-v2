"""Integration tests for DSR, DPIA, ROPA, BAPD, DQ API endpoints."""
import uuid
import pytest
from httpx import AsyncClient


MODULE_ENDPOINTS = [
    ("GET",  "/api/v1/dsr"),
    ("GET",  "/api/v1/dpia"),
    ("GET",  "/api/v1/ropa"),
    ("GET",  "/api/v1/bapd"),
    ("GET",  "/api/v1/dq"),
    ("GET",  "/api/v1/dashboard"),
    ("GET",  "/api/v1/audit-logs"),
    ("GET",  "/api/v1/notifications"),
    ("GET",  "/api/v1/notifications/preferences"),
]


@pytest.mark.asyncio
@pytest.mark.parametrize("method,url", MODULE_ENDPOINTS)
async def test_all_protected_endpoints_require_auth(client: AsyncClient, method: str, url: str):
    if method == "GET":
        resp = await client.get(url)
    else:
        resp = await client.post(url, json={})
    assert resp.status_code == 401, f"{method} {url} should return 401 without auth"


@pytest.mark.asyncio
async def test_dsr_submit_requires_valid_payload_and_auth(client: AsyncClient):
    resp = await client.post("/api/v1/dsr", json={})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_bapd_eligible_datasets_requires_auth(client: AsyncClient):
    resp = await client.get("/api/v1/bapd/eligible-datasets")
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_dq_validate_gcp_requires_auth(client: AsyncClient):
    resp = await client.post("/api/v1/dq/validate-gcp", json={
        "gcp_project": "test-proj",
        "bq_dataset": "test_ds",
        "bq_table": "test_table",
    })
    assert resp.status_code == 401
