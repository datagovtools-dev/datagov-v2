import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.rbac import require_permission
from app.core.secrets import encrypt_secret
from app.models.ai_config import AIProviderConfig
from app.models.user import AuditLog, User
from app.schemas.settings import (
    AIModelsResponse,
    AISettingsOut,
    AISettingsStatus,
    AISettingsTestRequest,
    AISettingsTestResult,
    AISettingsUpdate,
    DEFAULT_AI_BASE_URL,
    DEFAULT_AI_MODEL,
)
from app.services.ai_generation import (
    AICandidateConfig,
    AIGenerationError,
    build_candidate_from_config,
    config_is_ready,
    decrypt_config_api_key,
    get_ai_config,
    list_provider_models,
    test_provider_connection,
)

router = APIRouter(prefix="/settings", tags=["settings"])
DB = Annotated[AsyncSession, Depends(get_db)]


def _to_out(config: AIProviderConfig | None) -> AISettingsOut:
    if not config:
        return AISettingsOut()
    return AISettingsOut(
        id=config.id,
        provider=config.provider,
        mode=config.mode,
        enabled=config.enabled,
        base_url=config.base_url,
        model_name=config.model_name,
        timeout_seconds=config.timeout_seconds,
        batch_size=config.batch_size,
        parser_contract_version=config.parser_contract_version or "legacy_v1",
        metadata_contract_version=config.metadata_contract_version or "metadata_v1",
        dq_policy=config.dq_policy or "guarded_legacy",
        model_override_enabled=config.model_override_enabled if config.model_override_enabled is not None else True,
        repair_enabled=config.repair_enabled if config.repair_enabled is not None else True,
        minimum_score_delta=float(config.minimum_score_delta or 0.0),
        metadata_validation=config.metadata_validation or "strict",
        fallback_enabled=config.fallback_enabled if config.fallback_enabled is not None else True,
        api_key_configured=bool(config.encrypted_api_key),
        api_key_last4=config.api_key_last4,
        updated_at=config.updated_at,
        updated_by=config.updated_by,
    )


def _to_status(config: AIProviderConfig | None) -> AISettingsStatus:
    out = _to_out(config)
    return AISettingsStatus(
        enabled=out.enabled,
        configured=config_is_ready(config),
        provider=out.provider,
        mode=out.mode,
        base_url=out.base_url,
        model_name=out.model_name,
        timeout_seconds=out.timeout_seconds,
        batch_size=out.batch_size,
        parser_contract_version=out.parser_contract_version,
        metadata_contract_version=out.metadata_contract_version,
        dq_policy=out.dq_policy,
        model_override_enabled=out.model_override_enabled,
        repair_enabled=out.repair_enabled,
        minimum_score_delta=out.minimum_score_delta,
        metadata_validation=out.metadata_validation,
        fallback_enabled=out.fallback_enabled,
        api_key_configured=out.api_key_configured,
    )


@router.get("/ai/status", response_model=AISettingsStatus)
async def get_ai_status(
    db: DB,
    _: Annotated[User, Depends(require_permission("metadata:read"))],
) -> AISettingsStatus:
    return _to_status(await get_ai_config(db))


@router.get("/ai", response_model=AISettingsOut)
async def get_ai_settings(
    db: DB,
    _: Annotated[User, Depends(require_permission("settings:manage"))],
) -> AISettingsOut:
    return _to_out(await get_ai_config(db))


@router.put("/ai", response_model=AISettingsOut)
async def update_ai_settings(
    body: AISettingsUpdate,
    db: DB,
    current_user: Annotated[User, Depends(require_permission("settings:manage"))],
) -> AISettingsOut:
    config = await get_ai_config(db)
    if not config:
        config = AIProviderConfig(id=uuid.uuid4())
        db.add(config)

    config.provider = body.provider
    config.mode = body.mode
    config.enabled = body.enabled
    config.base_url = body.base_url
    config.model_name = body.model_name
    config.timeout_seconds = body.timeout_seconds
    config.batch_size = body.batch_size
    config.parser_contract_version = body.parser_contract_version
    config.metadata_contract_version = body.metadata_contract_version
    config.dq_policy = body.dq_policy
    config.model_override_enabled = body.model_override_enabled
    config.repair_enabled = body.repair_enabled
    config.minimum_score_delta = body.minimum_score_delta
    config.metadata_validation = body.metadata_validation
    config.fallback_enabled = body.fallback_enabled
    config.updated_by = current_user.id

    if body.clear_api_key:
        config.encrypted_api_key = None
        config.api_key_last4 = None
    elif body.api_key and body.api_key.strip():
        api_key = body.api_key.strip()
        config.encrypted_api_key = encrypt_secret(api_key)
        config.api_key_last4 = api_key[-4:]

    db.add(AuditLog(
        user_id=current_user.id,
        module="settings",
        action="update_ai_settings",
        entity_type="ai_provider_config",
        entity_id=str(config.id),
        details={
            "provider": config.provider,
            "mode": config.mode,
            "enabled": config.enabled,
            "base_url": config.base_url,
            "model_name": config.model_name,
            "parser_contract_version": config.parser_contract_version,
            "metadata_contract_version": config.metadata_contract_version,
            "dq_policy": config.dq_policy,
            "model_override_enabled": config.model_override_enabled,
            "repair_enabled": config.repair_enabled,
            "minimum_score_delta": config.minimum_score_delta,
            "metadata_validation": config.metadata_validation,
            "fallback_enabled": config.fallback_enabled,
            "api_key_configured": bool(config.encrypted_api_key),
        },
    ))
    try:
        await db.commit()
    except SQLAlchemyError as exc:
        await db.rollback()
        raise HTTPException(status_code=500, detail="Could not save AI settings.") from exc
    await db.refresh(config)
    return _to_out(config)


@router.post("/ai/test", response_model=AISettingsTestResult)
async def test_ai_settings(
    body: AISettingsTestRequest,
    db: DB,
    _: Annotated[User, Depends(require_permission("settings:manage"))],
) -> AISettingsTestResult:
    saved = await get_ai_config(db)
    saved_api_key = decrypt_config_api_key(saved)
    api_key = body.api_key.strip() if body.api_key and body.api_key.strip() else saved_api_key
    provider = body.provider or (saved.provider if saved else "ollama")
    mode = body.mode or (saved.mode if saved else "cloud")
    base_url = (body.base_url or (saved.base_url if saved else DEFAULT_AI_BASE_URL)).rstrip("/")
    model_name = body.model_name or (saved.model_name if saved else DEFAULT_AI_MODEL)
    timeout_seconds = body.timeout_seconds or (saved.timeout_seconds if saved else 60)
    batch_size = saved.batch_size if saved else 5
    candidate = AICandidateConfig(
        provider=provider,
        mode=mode,
        enabled=True,
        base_url=base_url,
        model_name=model_name,
        timeout_seconds=timeout_seconds,
        batch_size=batch_size,
        api_key=api_key,
    )
    try:
        await test_provider_connection(candidate)
        return AISettingsTestResult(
            ok=True,
            message="Connection successful.",
            provider=candidate.provider,
            model_name=candidate.model_name,
        )
    except AIGenerationError as exc:
        return AISettingsTestResult(
            ok=False,
            message=str(exc),
            provider=candidate.provider,
            model_name=candidate.model_name,
        )


@router.get("/ai/models", response_model=AIModelsResponse)
async def get_ai_models(
    db: DB,
    _: Annotated[User, Depends(require_permission("settings:manage"))],
) -> AIModelsResponse:
    config = await get_ai_config(db)
    if not config:
        raise HTTPException(status_code=400, detail="AI settings are not configured")
    candidate = build_candidate_from_config(config)
    try:
        return AIModelsResponse(models=await list_provider_models(candidate))
    except AIGenerationError as exc:
        raise HTTPException(status_code=exc.http_status, detail=str(exc)) from exc
