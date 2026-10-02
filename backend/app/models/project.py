import re
import uuid
from datetime import datetime, date
from sqlalchemy import String, Boolean, SmallInteger, Text, ForeignKey, DateTime, Date, func
from sqlalchemy.orm import Mapped, mapped_column, validates
from sqlalchemy import Uuid
from app.database import Base

# Project ID format: PRJ-<4-digit project year>-<3-digit sequence>, e.g. PRJ-2026-001
PROJECT_CODE_PATTERN = re.compile(r"^PRJ-(\d{4})-(\d{3})$")


class Project(Base):
    __tablename__ = "projects"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    project_code: Mapped[str | None] = mapped_column(String(50), nullable=True, unique=True, index=True)
    customer_name: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    line_of_business: Mapped[str | None] = mapped_column(String(200), nullable=True)
    project_name: Mapped[str] = mapped_column(String(300), nullable=False)
    use_case: Mapped[str | None] = mapped_column(Text, nullable=True)
    project_year: Mapped[int] = mapped_column(SmallInteger, nullable=False, index=True)
    project_category: Mapped[str] = mapped_column(String(50), nullable=False)
    is_monetized: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    sme_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    delivery_manager_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    project_manager_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    dgo_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    metadata_officer_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    dq_officer_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    pic_data_compliance_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    created_by: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    @validates("project_code")
    def _validate_project_code(self, _key: str, code: str | None) -> str | None:
        if code is None or not PROJECT_CODE_PATTERN.match(code) or code.endswith("-000"):
            raise ValueError(f"Invalid Project ID {code!r}: expected PRJ-YYYY-NNN from 001, e.g. PRJ-2026-001")
        return code
