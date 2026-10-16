import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, ForeignKey, DateTime, Date, SmallInteger, Integer, JSON, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Uuid
from app.database import Base


class RetentionPolicy(Base):
    __tablename__ = "retention_policies"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    dataset_type: Mapped[str] = mapped_column(String(150), nullable=False, unique=True)
    retention_days: Mapped[int] = mapped_column(Integer, nullable=False)
    policy_reference: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class BAPDRecord(Base):
    __tablename__ = "bapd_records"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("projects.id"), nullable=False, index=True)
    dataset_name: Mapped[str] = mapped_column(String(300), nullable=False)
    dataset_location: Mapped[str] = mapped_column(Text, nullable=False)
    retention_policy_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("retention_policies.id"), nullable=True)
    expiry_date: Mapped[date] = mapped_column(Date, nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    responsible_party_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="draft", index=True)
    approval_method: Mapped[str | None] = mapped_column(String(30), nullable=True, default="form_sign_off")
    sign_off_json: Mapped[dict | None] = mapped_column(JSON, nullable=True, default=dict)
    pod_file_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    executed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    executed_by: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    version: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    created_by: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    approvals: Mapped[list["BAPDApproval"]] = relationship("BAPDApproval", back_populates="bapd", lazy="selectin")
    target_datasets: Mapped[list["BAPDTargetDataset"]] = relationship(
        "BAPDTargetDataset",
        back_populates="bapd",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="BAPDTargetDataset.display_order",
    )


class BAPDTargetDataset(Base):
    __tablename__ = "bapd_target_datasets"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    bapd_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("bapd_records.id", ondelete="CASCADE"), nullable=False, index=True)
    dataset_name: Mapped[str] = mapped_column(String(300), nullable=False)
    dataset_location: Mapped[str] = mapped_column(Text, nullable=False)
    source_type: Mapped[str | None] = mapped_column(String(60), nullable=True)
    display_order: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=0)

    bapd: Mapped["BAPDRecord"] = relationship("BAPDRecord", back_populates="target_datasets")


class BAPDApproval(Base):
    __tablename__ = "bapd_approvals"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    bapd_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("bapd_records.id", ondelete="CASCADE"), nullable=False, index=True)
    approver_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
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
