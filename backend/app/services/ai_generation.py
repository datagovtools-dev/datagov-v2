from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Any
from urllib.parse import urlparse

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.secrets import decrypt_secret
from app.models.ai_config import AIProviderConfig
from app.models.metadata import MetadataRecord
from app.models.user import User
from app.schemas.settings import DEFAULT_AI_BASE_URL, DEFAULT_AI_MODEL


class AIGenerationError(RuntimeError):
    def __init__(self, message: str, http_status: int = 502):
        super().__init__(message)
        self.http_status = http_status


@dataclass(frozen=True)
class AICandidateConfig:
    provider: str = "ollama"
    mode: str = "cloud"
    enabled: bool = True
    base_url: str = DEFAULT_AI_BASE_URL
    model_name: str = DEFAULT_AI_MODEL
    timeout_seconds: int = 60
    batch_size: int = 5
    api_key: str | None = None


def _endpoint(base_url: str, name: str) -> str:
    base = base_url.rstrip("/")
    suffix = name.lstrip("/")
    if base.endswith("/api"):
        return f"{base}/{suffix}"
    return f"{base}/api/{suffix}"


def _is_cloud_host(base_url: str) -> bool:
    host = urlparse(base_url).netloc.lower()
    return "ollama.com" in host


def _safe_provider_error(response: httpx.Response) -> str:
    try:
        payload: Any = response.json()
    except ValueError:
        payload = {}

    detail = payload.get("error") if isinstance(payload, dict) else None
    if not detail:
        detail = response.text[:180] if response.text else response.reason_phrase
    return str(detail)[:180]


def _raise_for_provider_error(response: httpx.Response) -> None:
    if response.status_code < 400:
        return
    provider_detail = _safe_provider_error(response)
    if response.status_code in {401, 403}:
        raise AIGenerationError("Ollama rejected the API key.", 400)
    if response.status_code == 404:
        raise AIGenerationError(f"Ollama model or endpoint was not found: {provider_detail}", 400)
    if response.status_code == 429:
        raise AIGenerationError("Ollama rate limit reached. Try again later.", 429)
    raise AIGenerationError(f"Ollama request failed: {provider_detail}", 502)


async def get_ai_config(db: AsyncSession) -> AIProviderConfig | None:
    result = await db.execute(
        select(AIProviderConfig)
        .where(AIProviderConfig.provider == "ollama")
        .order_by(AIProviderConfig.updated_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


def decrypt_config_api_key(config: AIProviderConfig | None) -> str | None:
    if not config:
        return None
    return decrypt_secret(config.encrypted_api_key)


def config_is_ready(config: AIProviderConfig | None) -> bool:
    if not config or not config.enabled:
        return False
    if _is_cloud_host(config.base_url):
        return bool(config.encrypted_api_key)
    return True


def build_candidate_from_config(config: AIProviderConfig | None, api_key: str | None = None) -> AICandidateConfig:
    if not config:
        return AICandidateConfig(api_key=api_key)
    return AICandidateConfig(
        provider=config.provider,
        mode=config.mode,
        enabled=config.enabled,
        base_url=config.base_url,
        model_name=config.model_name,
        timeout_seconds=config.timeout_seconds,
        batch_size=config.batch_size,
        api_key=api_key if api_key is not None else decrypt_config_api_key(config),
    )


def build_metadata_definition_prompt(record: MetadataRecord) -> str:
    return (
        "You are a data governance expert. Write a clear, concise business definition "
        "for a database column.\n"
        f"Table: {record.data_domain_table}\n"
        f"Column: {record.data_attribute}\n"
        f"Business Term: {record.business_term or record.data_attribute}\n"
        f"Data Type: {record.data_type or 'unknown'}\n"
        f"Sample Value: {record.sample_data or 'not available'}\n\n"
        "Write only the definition in 1-2 sentences. Do not include headers or column names in your answer."
    )


async def generate_text(prompt: str, config: AICandidateConfig) -> str:
    if config.provider != "ollama":
        raise AIGenerationError("Only Ollama is supported.", 400)
    if not config.enabled:
        raise AIGenerationError("AI generation is disabled.", 400)
    if _is_cloud_host(config.base_url) and not config.api_key:
        raise AIGenerationError("Ollama Cloud API key is not configured.", 400)

    headers = {"Authorization": f"Bearer {config.api_key}"} if config.api_key else {}
    payload = {"model": config.model_name, "prompt": prompt, "stream": False}

    try:
        async with httpx.AsyncClient(timeout=float(config.timeout_seconds)) as client:
            response = await client.post(_endpoint(config.base_url, "generate"), json=payload, headers=headers)
    except httpx.TimeoutException as exc:
        raise AIGenerationError("Ollama request timed out.", 504) from exc
    except httpx.HTTPError as exc:
        raise AIGenerationError("Could not connect to Ollama.", 502) from exc

    _raise_for_provider_error(response)
    data = response.json()
    text = str(data.get("response", "")).strip()
    if not text:
        raise AIGenerationError("Ollama returned an empty response.", 502)
    return text


async def generate_metadata_definition(record: MetadataRecord, config: AICandidateConfig) -> str:
    return await generate_text(build_metadata_definition_prompt(record), config)


def apply_generated_definition(record: MetadataRecord, definition: str, current_user: User) -> None:
    record.business_definition = definition
    record.definition_status = "ai_generated"
    record.updated_date = date.today()
    record.updated_by = f"{current_user.full_name} <{current_user.email}>"


async def test_ollama_connection(config: AICandidateConfig) -> str:
    return await generate_text("Reply with exactly one word: ok", config)


async def list_ollama_models(config: AICandidateConfig) -> list[str]:
    headers = {"Authorization": f"Bearer {config.api_key}"} if config.api_key else {}
    try:
        async with httpx.AsyncClient(timeout=float(config.timeout_seconds)) as client:
            response = await client.get(_endpoint(config.base_url, "tags"), headers=headers)
    except httpx.TimeoutException as exc:
        raise AIGenerationError("Ollama model listing timed out.", 504) from exc
    except httpx.HTTPError as exc:
        raise AIGenerationError("Could not connect to Ollama.", 502) from exc

    _raise_for_provider_error(response)
    data = response.json()
    models = data.get("models", []) if isinstance(data, dict) else []
    names = [m.get("name") for m in models if isinstance(m, dict) and m.get("name")]
    return sorted(names)
