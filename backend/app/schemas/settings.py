import uuid
from datetime import datetime

from pydantic import BaseModel, Field, field_validator


DEFAULT_AI_BASE_URL = "https://ollama.com/api"
DEFAULT_AI_MODEL = "gemma4:31b-cloud"
DEFAULT_OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
DEFAULT_PARSER_CONTRACT_VERSION = "legacy_v1"
DEFAULT_METADATA_CONTRACT_VERSION = "metadata_v1"
DEFAULT_DQ_POLICY = "guarded_legacy"


class AISettingsOut(BaseModel):
    id: uuid.UUID | None = None
    provider: str = "ollama"
    mode: str = "cloud"
    enabled: bool = False
    base_url: str = DEFAULT_AI_BASE_URL
    model_name: str = DEFAULT_AI_MODEL
    timeout_seconds: int = 60
    batch_size: int = 5
    parser_contract_version: str = DEFAULT_PARSER_CONTRACT_VERSION
    metadata_contract_version: str = DEFAULT_METADATA_CONTRACT_VERSION
    dq_policy: str = DEFAULT_DQ_POLICY
    model_override_enabled: bool = True
    repair_enabled: bool = True
    minimum_score_delta: float = 0.0
    metadata_validation: str = "strict"
    fallback_enabled: bool = True
    api_key_configured: bool = False
    api_key_last4: str | None = None
    updated_at: datetime | None = None
    updated_by: uuid.UUID | None = None

    model_config = {"from_attributes": True, "protected_namespaces": ()}


class AISettingsStatus(BaseModel):
    enabled: bool
    configured: bool
    provider: str
    mode: str
    base_url: str
    model_name: str
    timeout_seconds: int
    batch_size: int
    parser_contract_version: str
    metadata_contract_version: str
    dq_policy: str
    model_override_enabled: bool
    repair_enabled: bool
    minimum_score_delta: float
    metadata_validation: str
    fallback_enabled: bool
    api_key_configured: bool

    model_config = {"protected_namespaces": ()}


class AISettingsUpdate(BaseModel):
    provider: str = Field(default="ollama", max_length=40)
    mode: str = Field(default="cloud", max_length=40)
    enabled: bool = False
    base_url: str = Field(default=DEFAULT_AI_BASE_URL, max_length=500)
    model_name: str = Field(default=DEFAULT_AI_MODEL, min_length=1, max_length=160)
    timeout_seconds: int = Field(default=60, ge=5, le=180)
    batch_size: int = Field(default=5, ge=1, le=25)
    parser_contract_version: str = Field(default=DEFAULT_PARSER_CONTRACT_VERSION, max_length=40)
    metadata_contract_version: str = Field(default=DEFAULT_METADATA_CONTRACT_VERSION, max_length=40)
    dq_policy: str = Field(default=DEFAULT_DQ_POLICY, max_length=40)
    model_override_enabled: bool = True
    repair_enabled: bool = True
    minimum_score_delta: float = Field(default=0.0, ge=0.0, le=100.0)
    metadata_validation: str = Field(default="strict", max_length=40)
    fallback_enabled: bool = True
    api_key: str | None = Field(default=None, max_length=5000)
    clear_api_key: bool = False

    model_config = {"protected_namespaces": ()}

    @field_validator("provider")
    @classmethod
    def validate_provider(cls, value: str) -> str:
        if value not in {"ollama", "openrouter"}:
            raise ValueError("provider must be ollama or openrouter")
        return value

    @field_validator("mode")
    @classmethod
    def validate_mode(cls, value: str) -> str:
        if value not in {"cloud", "local"}:
            raise ValueError("mode must be cloud or local")
        return value

    @field_validator("base_url")
    @classmethod
    def validate_base_url(cls, value: str) -> str:
        stripped = value.strip().rstrip("/")
        if not stripped.startswith(("http://", "https://")):
            raise ValueError("base_url must start with http:// or https://")
        return stripped

    @field_validator("model_name")
    @classmethod
    def validate_model_name(cls, value: str) -> str:
        return value.strip()

    @field_validator("parser_contract_version")
    @classmethod
    def validate_parser_contract_version(cls, value: str) -> str:
        if value not in {"legacy_v1"}:
            raise ValueError("Unsupported parser contract version")
        return value

    @field_validator("metadata_contract_version")
    @classmethod
    def validate_metadata_contract_version(cls, value: str) -> str:
        if value not in {"metadata_v1"}:
            raise ValueError("Unsupported metadata contract version")
        return value

    @field_validator("dq_policy")
    @classmethod
    def validate_dq_policy(cls, value: str) -> str:
        if value not in {"legacy_compatible", "guarded_legacy", "profile_canonical"}:
            raise ValueError("dq_policy must be legacy_compatible, guarded_legacy or profile_canonical")
        return value

    @field_validator("metadata_validation")
    @classmethod
    def validate_metadata_validation(cls, value: str) -> str:
        if value not in {"strict", "warn"}:
            raise ValueError("metadata_validation must be strict or warn")
        return value


class AISettingsTestRequest(BaseModel):
    provider: str | None = None
    mode: str | None = None
    base_url: str | None = None
    model_name: str | None = None
    timeout_seconds: int | None = Field(default=None, ge=5, le=180)
    api_key: str | None = Field(default=None, max_length=5000)

    model_config = {"protected_namespaces": ()}


class AISettingsTestResult(BaseModel):
    ok: bool
    message: str
    provider: str
    model_name: str

    model_config = {"protected_namespaces": ()}


class AIModelsResponse(BaseModel):
    models: list[str]
