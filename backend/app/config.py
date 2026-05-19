from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", case_sensitive=False, extra="ignore")

    # App
    app_name: str = "AI Governance Tools"
    app_version: str = "1.0.0"
    environment: str = "development"
    debug: bool = False

    # Security
    secret_key: str
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7
    bcrypt_rounds: int = 12
    allowed_origins: str = "http://localhost:3000"

    # Database
    database_url: str
    database_url_sync: str

    # Redis
    redis_url: str
    redis_denylist_db: int = 1
    redis_cache_db: int = 2

    # Celery
    celery_broker_url: str
    celery_result_backend: str

    # GCP
    gcp_project_id: str = ""
    gcp_dq_dataset: str = "dq_governance"
    gcp_bucket_dq_outputs: str = "dq-governance-outputs"
    gcp_bucket_exports: str = "governance-exports"
    gcp_bucket_bapd: str = "bapd-evidence"

    # Ollama
    ollama_host: str = "http://ollama:11434"
    ollama_model: str = "llama3:8b"
    ollama_fallback_model: str = "mistral:7b"
    ollama_timeout_seconds: int = 30

    # Email
    email_provider: str = "smtp"
    smtp_host: str = "localhost"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from_name: str = "AI Governance Tools"
    smtp_from_email: str = "noreply@ai-governance.local"
    sendgrid_api_key: str = ""

    # Rate limiting
    rate_limit_login_max: int = 5
    rate_limit_login_window_seconds: int = 600
    rate_limit_api_max: int = 100

    # File upload
    max_upload_size_mb: int = 20
    upload_temp_dir: str = "/tmp/ag_uploads"
    upload_retention_hours: int = 24

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]


@lru_cache
def get_settings() -> Settings:
    return Settings()
