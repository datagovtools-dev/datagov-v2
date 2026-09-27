import uuid
from datetime import datetime, date
from sqlalchemy import String, Boolean, Text, ForeignKey, DateTime, Date, SmallInteger, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import JSON, Uuid
from app.database import Base
from app.models.project import Project
from app.models.user import User


class DataSharingRequest(Base):
    __tablename__ = "data_sharing_requests"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    tracking_id: Mapped[str] = mapped_column(String(30), unique=True, nullable=False, index=True)
    project_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("projects.id"), nullable=False, index=True)
    requester_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    dataset_name: Mapped[str] = mapped_column(String(300), nullable=False)
    recipient: Mapped[str] = mapped_column(Text, nullable=False)
    purpose: Mapped[str] = mapped_column(Text, nullable=False)
    is_ai_use: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    duration_start: Mapped[date] = mapped_column(Date, nullable=False)
    duration_end: Mapped[date] = mapped_column(Date, nullable=False)
    dsa_id: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("data_sharing_agreements.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="draft", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    approvals: Mapped[list["DSRApproval"]] = relationship(back_populates="dsr", cascade="all, delete-orphan", order_by="DSRApproval.step_order")
    ai_checklist: Mapped["AIComplianceChecklist | None"] = relationship(back_populates="dsr", uselist=False)
    dsa: Mapped["DataSharingAgreement | None"] = relationship()
    project: Mapped["Project"] = relationship(foreign_keys=[project_id])

    @property
    def project_name(self) -> str:
        return self.project.project_name if self.project else ""

    @property
    def project_code(self) -> str | None:
        return self.project.project_code if self.project else None

    @property
    def project_end_date(self):
        return self.project.end_date if self.project else None


class DSRApproval(Base):
    __tablename__ = "dsr_approvals"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    dsr_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("data_sharing_requests.id"), nullable=False, index=True)
    approver_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    approver_role: Mapped[str] = mapped_column(String(80), nullable=False)
    step_order: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="requested")
    comments: Mapped[str | None] = mapped_column(Text, nullable=True)
    actioned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    dsr: Mapped["DataSharingRequest"] = relationship(back_populates="approvals")
    approver: Mapped["User"] = relationship(foreign_keys=[approver_id])

    @property
    def approver_name(self) -> str:
        return self.approver.full_name if self.approver else ""


class DataSharingAgreement(Base):
    __tablename__ = "data_sharing_agreements"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    file_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    validity_start: Mapped[date] = mapped_column(Date, nullable=False)
    validity_end: Mapped[date | None] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class AIComplianceChecklist(Base):
    __tablename__ = "ai_compliance_checklists"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    dsr_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("data_sharing_requests.id"), unique=True, nullable=False)
    checklist_json: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="draft")
    validated_by: Mapped[uuid.UUID | None] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=True)
    validated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    dsr: Mapped["DataSharingRequest"] = relationship(back_populates="ai_checklist")
    approvals: Mapped[list["AIChecklistApproval"]] = relationship(
        back_populates="checklist", cascade="all, delete-orphan", order_by="AIChecklistApproval.step_order"
    )


class AIChecklistApproval(Base):
    __tablename__ = "ai_checklist_approvals"

    id: Mapped[uuid.UUID] = mapped_column(Uuid(), primary_key=True, default=uuid.uuid4)
    checklist_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("ai_compliance_checklists.id", ondelete="CASCADE"), nullable=False, index=True)
    approver_id: Mapped[uuid.UUID] = mapped_column(Uuid(), ForeignKey("users.id"), nullable=False)
    approver_role: Mapped[str] = mapped_column(String(80), nullable=False)
    step_order: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    comments: Mapped[str | None] = mapped_column(Text, nullable=True)
    actioned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    checklist: Mapped["AIComplianceChecklist"] = relationship(back_populates="approvals")
    approver: Mapped["User"] = relationship(foreign_keys=[approver_id])

    @property
    def approver_name(self) -> str:
        return self.approver.full_name if self.approver else ""
