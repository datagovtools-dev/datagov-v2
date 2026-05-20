import os

import pytest

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")
os.environ.setdefault("DATABASE_NULL_POOL", "true")

from app.models.metadata import MetadataRecord
from app.services import ai_generation
from app.services.ai_generation import AICandidateConfig, AIGenerationError


class FakeResponse:
    def __init__(self, status_code: int, payload: dict | None = None, text: str = ""):
        self.status_code = status_code
        self._payload = payload or {}
        self.text = text
        self.reason_phrase = "error"

    def json(self):
        return self._payload


@pytest.mark.asyncio
async def test_generate_text_calls_ollama_cloud_with_bearer_token(monkeypatch):
    calls = {}

    class FakeClient:
        def __init__(self, timeout):
            calls["timeout"] = timeout

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            return None

        async def post(self, url, json, headers):
            calls.update({"url": url, "json": json, "headers": headers})
            return FakeResponse(200, {"response": "A generated definition."})

    monkeypatch.setattr(ai_generation.httpx, "AsyncClient", FakeClient)

    result = await ai_generation.generate_text(
        "prompt",
        AICandidateConfig(api_key="ollama-key", model_name="gpt-oss:120b", timeout_seconds=12),
    )

    assert result == "A generated definition."
    assert calls["url"] == "https://ollama.com/api/generate"
    assert calls["json"]["model"] == "gpt-oss:120b"
    assert calls["headers"] == {"Authorization": "Bearer ollama-key"}
    assert calls["timeout"] == 12.0


@pytest.mark.asyncio
async def test_generate_text_requires_cloud_api_key():
    with pytest.raises(AIGenerationError, match="API key"):
        await ai_generation.generate_text("prompt", AICandidateConfig(api_key=None))


@pytest.mark.asyncio
async def test_generate_text_maps_unauthorized_response(monkeypatch):
    class FakeClient:
        def __init__(self, timeout):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            return None

        async def post(self, url, json, headers):
            return FakeResponse(401, {"error": "bad key"})

    monkeypatch.setattr(ai_generation.httpx, "AsyncClient", FakeClient)

    with pytest.raises(AIGenerationError, match="rejected"):
        await ai_generation.generate_text("prompt", AICandidateConfig(api_key="bad-key"))


def test_build_metadata_definition_prompt_includes_governance_context():
    record = MetadataRecord(
        data_domain_table="orders",
        data_attribute="customer_id",
        business_term="Customer Identifier",
        data_type="STRING",
        sample_data="CUST-001",
    )

    prompt = ai_generation.build_metadata_definition_prompt(record)

    assert "data governance expert" in prompt
    assert "orders" in prompt
    assert "customer_id" in prompt
    assert "Customer Identifier" in prompt
