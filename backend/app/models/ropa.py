import uuid
from datetime import datetime
from sqlalchemy import String, Text, ForeignKey, DateTime, SmallInteger, func, JSON
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import Uuid
from app.database import Base


class ROPARecord(Base):
    __tablename__ = "ropa_records"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("projects.id"), nullable=False, index=True)
    process_name: Mapped[str] = mapped_column(String(300), nullable=False)
    purpose: Mapped[str] = mapped_column(Text, nullable=False)
    data_category: Mapped[str] = mapped_column(Text, nullable=False)
    data_subject: Mapped[str] = mapped_column(Text, nullable=False)
    legal_basis: Mapped[str] = mapped_column(Text, nullable=False)
    retention_period: Mapped[str] = mapped_column(String(100), nullable=False)
    recipient: Mapped[str | None] = mapped_column(Text, nullable=True)
    linked_asset_ids: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="draft", index=True)
    version: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    created_by: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
