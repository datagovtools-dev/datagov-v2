import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, ForeignKey, DateTime, Date, SmallInteger, Integer, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base


class RetentionPolicy(Base):
    __tablename__ = "retention_policies"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_type: Mapped[str] = mapped_column(String(150), nullable=False, unique=True)
    retention_days: Mapped[int] = mapped_column(Integer, nullable=False)
    policy_reference: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class BAPDRecord(Base):
    __tablename__ = "bapd_records"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    dataset_name: Mapped[str] = mapped_column(String(300), nullable=False)
    dataset_location: Mapped[str] = mapped_column(Text, nullable=False)
    retention_policy_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("retention_policies.id"), nullable=True)
    expiry_date: Mapped[date] = mapped_column(Date, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    responsible_party_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="draft", index=True)
    pod_file_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    executed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    executed_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    version: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    approvals: Mapped[list["BAPDApproval"]] = relationship("BAPDApproval", back_populates="bapd", lazy="selectin")


class BAPDApproval(Base):
    __tablename__ = "bapd_approvals"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    bapd_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("bapd_records.id", ondelete="CASCADE"), nullable=False, index=True)
    approver_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    approver_role: Mapped[str] = mapped_column(String(60), nullable=False)  # data_owner | compliance_officer
    step_order: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")  # pending|approved|rejected
    comments: Mapped[str | None] = mapped_column(Text, nullable=True)
    actioned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    bapd: Mapped["BAPDRecord"] = relationship("BAPDRecord", back_populates="approvals")
    approver: Mapped["User"] = relationship("User", foreign_keys=[approver_id], lazy="selectin")

    @property
    def approver_name(self) -> str:
        return self.approver.full_name if self.approver else ""
