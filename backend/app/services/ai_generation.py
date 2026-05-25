from __future__ import annotations

import re
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


_METADATA_OPTIONS: dict[str, Any] = {
    "temperature": 0.20,
    "top_p": 0.85,
    "top_k": 30,
    "repeat_penalty": 1.15,
    "num_predict": 160,
}


def _clean_output(text: str) -> str:
    result = re.sub(r'\n+', ' ', text)
    result = re.sub(r';\s+([a-zA-Z])', lambda m: '. ' + m.group(1).upper(), result)
    result = re.sub(r'\s{2,}', ' ', result).strip()
    if result and not result.endswith('.'):
        result += '.'
    return result


def _clean_table_name(table: str) -> str:
    """Strip file extension and sheet suffix so the model gets clean domain context."""
    for ext in (".xlsx", ".xls", ".csv"):
        idx = table.lower().find(ext)
        if idx > 0:
            table = table[:idx]
            break
    # Remove trailing ' - Sheet1' style suffixes
    for sep in (" - ", " – ", "_"):
        parts = table.rsplit(sep, 1)
        if len(parts) == 2 and parts[1].lower().startswith("sheet"):
            table = parts[0]
    return table.strip(" -_")


def build_metadata_definition_prompt(record: MetadataRecord) -> str:
    table_context = _clean_table_name(record.data_domain_table or "")

    ctx_lines = [
        f"Source table: {table_context}",
        f"Business term: {record.business_term or record.data_attribute}",
        f"Data type: {record.data_type or 'text'}",
    ]
    if record.data_grouping:
        ctx_lines.append(f"Domain: {record.data_grouping}")
    if record.line_of_business:
        ctx_lines.append(f"Line of business: {record.line_of_business}")
    if record.distinct_values:
        ctx_lines.append(f"Possible values: {record.distinct_values}")
    else:
        if record.standard_format:
            ctx_lines.append(f"Value format / range: {record.standard_format}")
        if record.sample_data:
            ctx_lines.append(f"Example value: {record.sample_data}")
    if record.data_sensitivity:
        ctx_lines.append(f"Sensitivity: {record.data_sensitivity}")
    if record.is_primary_key is not None:
        ctx_lines.append(f"Primary key: {'Yes' if record.is_primary_key else 'No'}")
    if record.is_nullable is not None:
        ctx_lines.append(f"Nullable: {'Yes' if record.is_nullable else 'No'}")

    context = "\n".join(ctx_lines)

    is_categorical = bool(record.distinct_values) or (
        record.standard_format is not None and (
            record.standard_format.startswith("Category:") or
            record.standard_format.startswith("Boolean")
        )
    )
    n = "3" if is_categorical else "2"
    s3 = "\n   3. What each possible value means in practice — one clause per value" if is_categorical else ""

    conditional_rules: list[str] = []
    if record.data_sensitivity in ("Highly Confidential", "Restricted"):
        conditional_rules.append(
            "8. This data is personally identifiable — briefly note it is handled under data privacy policy."
        )
    if record.is_primary_key:
        conditional_rules.append(
            "9. Mention that this value uniquely identifies each record."
        )
    if record.is_nullable:
        conditional_rules.append(
            "10. Briefly note when or why this value may be absent."
        )
    conditional_block = (
        "\n" + "\n".join(conditional_rules)
        if conditional_rules else ""
    )

    return (
        "You are a senior data governance specialist writing a business data dictionary entry.\n\n"
        f"{context}\n\n"
        "CRITICAL: Every sentence must end with a period (.). "
        "Using a semicolon (;) anywhere in your response is forbidden — if you use one, your answer is wrong.\n\n"
        f"Write exactly {n} sentences as one continuous paragraph. Rules:\n"
        "1. Start with a verb — Captures / Records / Identifies / Measures / Tracks / Indicates / Reflects\n"
        "2. Never name the column or business term\n"
        f"3. Sentence 1: what real-world fact this records, anchored to the business area and domain\n"
        f"4. Sentence 2: how it is used in business decisions or reporting{s3}\n"
        "5. Do not mention the table name — draw context from the business area or domain only.\n"
        "6. Write in plain, everyday language — no jargon, no acronyms, no technical terms. "
        "Any reader regardless of background should understand what this data means.\n"
        "7. No line breaks between sentences. Output the definition only."
        f"{conditional_block}\n"
    )


async def generate_text(
    prompt: str,
    config: AICandidateConfig,
    options: dict[str, Any] | None = None,
) -> str:
    if config.provider != "ollama":
        raise AIGenerationError("Only Ollama is supported.", 400)
    if not config.enabled:
        raise AIGenerationError("AI generation is disabled.", 400)
    if _is_cloud_host(config.base_url) and not config.api_key:
        raise AIGenerationError("Ollama Cloud API key is not configured.", 400)

    headers = {"Authorization": f"Bearer {config.api_key}"} if config.api_key else {}
    payload: dict[str, Any] = {"model": config.model_name, "prompt": prompt, "stream": False}
    if options:
        payload["options"] = options

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
    prompt = build_metadata_definition_prompt(record)
    text = await generate_text(prompt, config, options=_METADATA_OPTIONS)
    return _clean_output(text)


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
