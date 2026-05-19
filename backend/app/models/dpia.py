import uuid
from datetime import datetime, date
from sqlalchemy import String, Text, ForeignKey, DateTime, Date, SmallInteger, func, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.database import Base


class DPIARecord(Base):
    __tablename__ = "dpia_records"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tracking_id: Mapped[str | None] = mapped_column(String(30), unique=True, nullable=True, index=True)
    project_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("projects.id"), nullable=False, index=True)
    process_name: Mapped[str] = mapped_column(String(300), nullable=False)
    purpose: Mapped[str] = mapped_column(Text, nullable=False)
    data_category: Mapped[str] = mapped_column(Text, nullable=False)
    risk_description: Mapped[str] = mapped_column(Text, nullable=False)
    mitigation_measures: Mapped[str | None] = mapped_column(Text, nullable=True)
    residual_risk: Mapped[str | None] = mapped_column(String(20), nullable=True)
    likelihood_score: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    impact_score: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    risk_score: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    assessment_date: Mapped[date] = mapped_column(Date, nullable=False)
    responsible_party_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="draft", index=True)
    version: Mapped[int] = mapped_column(SmallInteger, nullable=False, default=1)
    governance_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_by: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    project: Mapped["Project"] = relationship("Project", foreign_keys=[project_id], lazy="selectin")
    approvals: Mapped[list["DPIAApproval"]] = relationship(
        back_populates="dpia", cascade="all, delete-orphan", order_by="DPIAApproval.step_order"
    )

    __table_args__ = (
        CheckConstraint("likelihood_score BETWEEN 1 AND 5", name="ck_dpia_likelihood"),
        CheckConstraint("impact_score BETWEEN 1 AND 5", name="ck_dpia_impact"),
    )

    @property
    def project_code(self) -> str | None:
        return self.project.project_code if self.project else None

    @property
    def project_name(self) -> str | None:
        return self.project.project_name if self.project else None

    @property
    def customer_name(self) -> str | None:
        return self.project.customer_name if self.project else None


class DPIAApproval(Base):
    __tablename__ = "dpia_approvals"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dpia_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("dpia_records.id", ondelete="CASCADE"), nullable=False, index=True)
    approver_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    approver_role: Mapped[str] = mapped_column(String(80), nullable=False)
    step_order: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    comments: Mapped[str | None] = mapped_column(Text, nullable=True)
    actioned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    dpia: Mapped["DPIARecord"] = relationship(back_populates="approvals")
    approver: Mapped["User"] = relationship(foreign_keys=[approver_id])

    @property
    def approver_name(self) -> str:
        return self.approver.full_name if self.approver else ""
