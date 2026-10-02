import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AIProviderConfig(Base):
    __tablename__ = "ai_provider_configs"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    provider: Mapped[str] = mapped_column(String(40), nullable=False, default="ollama")
    mode: Mapped[str] = mapped_column(String(40), nullable=False, default="cloud")
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    base_url: Mapped[str] = mapped_column(String(500), nullable=False, default="https://ollama.com/api")
    model_name: Mapped[str] = mapped_column(String(160), nullable=False, default="gemma4:31b-cloud")
    timeout_seconds: Mapped[int] = mapped_column(Integer, nullable=False, default=60)
    batch_size: Mapped[int] = mapped_column(Integer, nullable=False, default=5)
    parser_contract_version: Mapped[str | None] = mapped_column(String(40), nullable=True, default="legacy_v1")
    metadata_contract_version: Mapped[str | None] = mapped_column(String(40), nullable=True, default="metadata_v1")
    dq_policy: Mapped[str | None] = mapped_column(String(40), nullable=True, default="guarded_legacy")
    model_override_enabled: Mapped[bool | None] = mapped_column(Boolean, nullable=True, default=True)
    repair_enabled: Mapped[bool | None] = mapped_column(Boolean, nullable=True, default=True)
    minimum_score_delta: Mapped[float | None] = mapped_column(Float, nullable=True, default=0.0)
    metadata_validation: Mapped[str | None] = mapped_column(String(40), nullable=True, default="strict")
    fallback_enabled: Mapped[bool | None] = mapped_column(Boolean, nullable=True, default=True)
    encrypted_api_key: Mapped[str | None] = mapped_column(Text, nullable=True)
    api_key_last4: Mapped[str | None] = mapped_column(String(12), nullable=True)
    updated_by: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
