import uuid
from datetime import datetime, date
from sqlalchemy import BigInteger, String, Text, Boolean, Integer, SmallInteger, ForeignKey, DateTime, Date, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class MetadataRecord(Base):
    __tablename__ = "metadata_records"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    seq_no: Mapped[int] = mapped_column(Integer, nullable=False)
    business_users: Mapped[str] = mapped_column(String(200), nullable=False)
    data_domain_table: Mapped[str] = mapped_column(String(300), nullable=False, index=True)
    line_of_business: Mapped[str | None] = mapped_column(String(200), nullable=True)
    table_type: Mapped[str] = mapped_column(String(50), nullable=False, default="Source")
    project_name: Mapped[str] = mapped_column(String(300), nullable=False)
    project_year: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    data_steward: Mapped[str | None] = mapped_column(Text, nullable=True)
    data_owner: Mapped[str | None] = mapped_column(Text, nullable=True)
    data_attribute: Mapped[str] = mapped_column(String(300), nullable=False, index=True)
    data_year: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    data_sensitivity: Mapped[str] = mapped_column(String(30), nullable=False, default="Confidential")
    data_grouping: Mapped[str | None] = mapped_column(Text, nullable=True)
    business_term: Mapped[str | None] = mapped_column(Text, nullable=True)
    business_definition: Mapped[str | None] = mapped_column(Text, nullable=True)
    definition_status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    standard_format: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_primary_key: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    is_nullable: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    sample_data: Mapped[str | None] = mapped_column(Text, nullable=True)
    data_type: Mapped[str | None] = mapped_column(String(30), nullable=True)
    data_level: Mapped[str] = mapped_column(String(30), nullable=False, default="Raw")
    updated_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    updated_by: Mapped[str | None] = mapped_column(Text, nullable=True)
    remarks: Mapped[str] = mapped_column(Text, nullable=False, default="-")
    source_type: Mapped[str] = mapped_column(String(20), nullable=False)
    source_row_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
    distinct_values: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class DataOwnerSteward(Base):
    __tablename__ = "data_owner_stewards"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    role_type: Mapped[str] = mapped_column(String(50), nullable=False)
    full_name: Mapped[str] = mapped_column(String(200), nullable=False)
    email: Mapped[str] = mapped_column(String(200), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class ProjectSourceFile(Base):
    __tablename__ = "project_source_files"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False, index=True)
    source_type: Mapped[str] = mapped_column(String(32), nullable=False)
    original_filename: Mapped[str] = mapped_column(String(512), nullable=False)
    stored_path: Mapped[str] = mapped_column(String(1024), nullable=False)
    file_size: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    uploaded_by: Mapped[str | None] = mapped_column(String(256), nullable=True)
