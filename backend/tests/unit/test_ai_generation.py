import os

import pytest

os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("DATABASE_URL", "sqlite+aiosqlite:///:memory:")
os.environ.setdefault("DATABASE_URL_SYNC", "sqlite:///:memory:")

from app.models.metadata import MetadataRecord
from app.services import ai_generation
from app.services.ai_generation import AICandidateConfig, AIGenerationError, ollama_endpoint, openrouter_endpoint


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


def test_ollama_endpoint_supports_root_and_api_base_urls():
    assert ollama_endpoint("https://ollama.com", "generate") == "https://ollama.com/api/generate"
    assert ollama_endpoint("https://ollama.com/api", "generate") == "https://ollama.com/api/generate"
    assert ollama_endpoint("http://ollama:11434/", "tags") == "http://ollama:11434/api/tags"


@pytest.mark.asyncio
async def test_generate_text_calls_openrouter_chat_completions(monkeypatch):
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
            return FakeResponse(200, {"choices": [{"message": {"content": "OpenRouter result"}}]})

    monkeypatch.setattr(ai_generation.httpx, "AsyncClient", FakeClient)

    result = await ai_generation.generate_text(
        "prompt",
        AICandidateConfig(
            provider="openrouter",
            base_url="https://openrouter.ai/api/v1",
            api_key="or-key",
            model_name="openai/gpt-4o-mini",
            timeout_seconds=14,
        ),
        options={"temperature": 0.2, "num_predict": 120},
    )

    assert result == "OpenRouter result"
    assert calls["url"] == "https://openrouter.ai/api/v1/chat/completions"
    assert calls["json"]["model"] == "openai/gpt-4o-mini"
    assert calls["json"]["messages"] == [{"role": "user", "content": "prompt"}]
    assert calls["json"]["max_tokens"] == 120
    assert calls["headers"] == {
        "Authorization": "Bearer or-key",
        "Content-Type": "application/json",
    }
    assert calls["timeout"] == 14.0


def test_openrouter_endpoint_supports_root_and_v1_base_urls():
    assert openrouter_endpoint("https://openrouter.ai", "chat/completions") == "https://openrouter.ai/api/v1/chat/completions"
    assert openrouter_endpoint("https://openrouter.ai/api/v1", "models") == "https://openrouter.ai/api/v1/models"


@pytest.mark.asyncio
async def test_list_provider_models_reads_openrouter_model_ids(monkeypatch):
    calls = {}

    class FakeClient:
        def __init__(self, timeout):
            calls["timeout"] = timeout

        async def __aenter__(self):
            return self

        async def __aexit__(self, *_):
            return None

        async def get(self, url, headers):
            calls.update({"url": url, "headers": headers})
            return FakeResponse(200, {"data": [{"id": "z/model"}, {"id": "a/model"}]})

    monkeypatch.setattr(ai_generation.httpx, "AsyncClient", FakeClient)

    models = await ai_generation.list_provider_models(
        AICandidateConfig(
            provider="openrouter",
            base_url="https://openrouter.ai/api/v1",
            api_key="or-key",
            timeout_seconds=9,
        )
    )

    assert models == ["a/model", "z/model"]
    assert calls["url"] == "https://openrouter.ai/api/v1/models"
    assert calls["headers"] == {"Authorization": "Bearer or-key"}


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
