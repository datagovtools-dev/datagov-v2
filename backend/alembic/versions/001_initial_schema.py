"""initial schema

Revision ID: 001
Revises:
Create Date: 2025-01-01 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # --- roles ---
    op.create_table(
        "roles",
        sa.Column("id", sa.SmallInteger(), autoincrement=True, nullable=False),
        sa.Column("name", sa.String(80), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_roles"),
        sa.UniqueConstraint("name", name="uq_roles_name"),
    )

    # --- users ---
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("full_name", sa.String(200), nullable=False),
        sa.Column("email", sa.String(200), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_users"),
        sa.UniqueConstraint("email", name="uq_users_email"),
    )

    # --- projects ---
    op.create_table(
        "projects",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_name", sa.String(300), nullable=False),
        sa.Column("project_code", sa.String(50), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="active"),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("delivery_manager", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("project_manager", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("data_governance_officer", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("metadata_officer", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("dq_officer", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("pic_data_compliance", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["delivery_manager"], ["users.id"], name="fk_projects_delivery_manager"),
        sa.ForeignKeyConstraint(["project_manager"], ["users.id"], name="fk_projects_project_manager"),
        sa.ForeignKeyConstraint(["data_governance_officer"], ["users.id"], name="fk_projects_dgo"),
        sa.ForeignKeyConstraint(["metadata_officer"], ["users.id"], name="fk_projects_metadata_officer"),
        sa.ForeignKeyConstraint(["dq_officer"], ["users.id"], name="fk_projects_dq_officer"),
        sa.ForeignKeyConstraint(["pic_data_compliance"], ["users.id"], name="fk_projects_pic_data_compliance"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], name="fk_projects_created_by"),
        sa.PrimaryKeyConstraint("id", name="pk_projects"),
        sa.UniqueConstraint("project_code", name="uq_projects_project_code"),
    )
    op.create_index("ix_projects_status", "projects", ["status"])

    # --- user_project_roles ---
    op.create_table(
        "user_project_roles",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("role_id", sa.SmallInteger(), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("assigned_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("assigned_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_upr_user_id"),
        sa.ForeignKeyConstraint(["role_id"], ["roles.id"], name="fk_upr_role_id"),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_upr_project_id"),
        sa.ForeignKeyConstraint(["assigned_by"], ["users.id"], name="fk_upr_assigned_by"),
        sa.PrimaryKeyConstraint("id", name="pk_user_project_roles"),
    )
    op.create_index("ix_upr_user_id", "user_project_roles", ["user_id"])
    op.create_index("ix_upr_project_id", "user_project_roles", ["project_id"])

    # --- audit_logs (append-only; protected by DDL trigger in init.sql) ---
    op.create_table(
        "audit_logs",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("module", sa.String(50), nullable=False),
        sa.Column("action", sa.String(50), nullable=False),
        sa.Column("entity_type", sa.String(100), nullable=True),
        sa.Column("entity_id", sa.Text(), nullable=True),
        sa.Column("details", postgresql.JSONB(), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], name="fk_audit_logs_user_id", ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id", name="pk_audit_logs"),
    )
    op.create_index("ix_audit_logs_user_id", "audit_logs", ["user_id"])
    op.create_index("ix_audit_logs_module", "audit_logs", ["module"])
    op.create_index("ix_audit_logs_created_at", "audit_logs", ["created_at"])

    # --- data_sharing_agreements ---
    op.create_table(
        "data_sharing_agreements",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("file_path", sa.Text(), nullable=True),
        sa.Column("validity_start", sa.Date(), nullable=False),
        sa.Column("validity_end", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_data_sharing_agreements"),
    )

    # --- data_sharing_requests ---
    op.create_table(
        "data_sharing_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("tracking_id", sa.String(30), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("requester_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("dataset_name", sa.String(300), nullable=False),
        sa.Column("recipient", sa.Text(), nullable=False),
        sa.Column("purpose", sa.Text(), nullable=False),
        sa.Column("is_ai_use", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("duration_start", sa.Date(), nullable=False),
        sa.Column("duration_end", sa.Date(), nullable=False),
        sa.Column("dsa_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="draft"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_dsr_project_id"),
        sa.ForeignKeyConstraint(["requester_id"], ["users.id"], name="fk_dsr_requester_id"),
        sa.ForeignKeyConstraint(["dsa_id"], ["data_sharing_agreements.id"], name="fk_dsr_dsa_id"),
        sa.PrimaryKeyConstraint("id", name="pk_data_sharing_requests"),
        sa.UniqueConstraint("tracking_id", name="uq_dsr_tracking_id"),
    )
    op.create_index("ix_dsr_project_id", "data_sharing_requests", ["project_id"])
    op.create_index("ix_dsr_status", "data_sharing_requests", ["status"])
    op.create_index("ix_dsr_tracking_id", "data_sharing_requests", ["tracking_id"])

    # --- dsr_approvals ---
    op.create_table(
        "dsr_approvals",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("dsr_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("approver_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("approver_role", sa.String(80), nullable=False),
        sa.Column("step_order", sa.SmallInteger(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("comments", sa.Text(), nullable=True),
        sa.Column("actioned_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["dsr_id"], ["data_sharing_requests.id"], name="fk_dsr_approvals_dsr_id"),
        sa.ForeignKeyConstraint(["approver_id"], ["users.id"], name="fk_dsr_approvals_approver_id"),
        sa.PrimaryKeyConstraint("id", name="pk_dsr_approvals"),
    )
    op.create_index("ix_dsr_approvals_dsr_id", "dsr_approvals", ["dsr_id"])

    # --- ai_compliance_checklists ---
    op.create_table(
        "ai_compliance_checklists",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("dsr_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("purpose_desc", sa.Text(), nullable=False),
        sa.Column("fairness_ok", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("minimization_ok", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("explainability_ok", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("validated_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("validated_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["dsr_id"], ["data_sharing_requests.id"], name="fk_ai_checklist_dsr_id"),
        sa.ForeignKeyConstraint(["validated_by"], ["users.id"], name="fk_ai_checklist_validated_by"),
        sa.PrimaryKeyConstraint("id", name="pk_ai_compliance_checklists"),
        sa.UniqueConstraint("dsr_id", name="uq_ai_checklist_dsr_id"),
    )

    # --- dpia_records ---
    op.create_table(
        "dpia_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("process_name", sa.String(300), nullable=False),
        sa.Column("purpose", sa.Text(), nullable=False),
        sa.Column("data_category", sa.Text(), nullable=False),
        sa.Column("risk_description", sa.Text(), nullable=False),
        sa.Column("mitigation_measures", sa.Text(), nullable=True),
        sa.Column("residual_risk", sa.String(20), nullable=True),
        sa.Column("likelihood_score", sa.SmallInteger(), nullable=True),
        sa.Column("impact_score", sa.SmallInteger(), nullable=True),
        sa.Column("risk_score", sa.SmallInteger(), nullable=True),
        sa.Column("assessment_date", sa.Date(), nullable=False),
        sa.Column("responsible_party_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(30), nullable=False, server_default="draft"),
        sa.Column("version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("likelihood_score BETWEEN 1 AND 5", name="ck_dpia_likelihood"),
        sa.CheckConstraint("impact_score BETWEEN 1 AND 5", name="ck_dpia_impact"),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_dpia_project_id"),
        sa.ForeignKeyConstraint(["responsible_party_id"], ["users.id"], name="fk_dpia_responsible_party"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], name="fk_dpia_created_by"),
        sa.PrimaryKeyConstraint("id", name="pk_dpia_records"),
    )
    op.create_index("ix_dpia_project_id", "dpia_records", ["project_id"])
    op.create_index("ix_dpia_status", "dpia_records", ["status"])

    # --- ropa_records ---
    op.create_table(
        "ropa_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("process_name", sa.String(300), nullable=False),
        sa.Column("purpose", sa.Text(), nullable=False),
        sa.Column("data_category", sa.Text(), nullable=False),
        sa.Column("data_subject", sa.Text(), nullable=False),
        sa.Column("legal_basis", sa.Text(), nullable=False),
        sa.Column("retention_period", sa.String(100), nullable=False),
        sa.Column("recipient", sa.Text(), nullable=True),
        sa.Column("linked_asset_ids", postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="draft"),
        sa.Column("version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_ropa_project_id"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], name="fk_ropa_created_by"),
        sa.PrimaryKeyConstraint("id", name="pk_ropa_records"),
    )
    op.create_index("ix_ropa_project_id", "ropa_records", ["project_id"])
    op.create_index("ix_ropa_status", "ropa_records", ["status"])

    # --- retention_policies ---
    op.create_table(
        "retention_policies",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("dataset_type", sa.String(150), nullable=False),
        sa.Column("retention_days", sa.Integer(), nullable=False),
        sa.Column("policy_reference", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_retention_policies"),
        sa.UniqueConstraint("dataset_type", name="uq_retention_policies_dataset_type"),
    )

    # --- bapd_records ---
    op.create_table(
        "bapd_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("dataset_name", sa.String(300), nullable=False),
        sa.Column("dataset_location", sa.Text(), nullable=False),
        sa.Column("retention_policy_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("expiry_date", sa.Date(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("responsible_party_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(30), nullable=False, server_default="draft"),
        sa.Column("pod_file_path", sa.Text(), nullable=True),
        sa.Column("executed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("executed_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("version", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column("created_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_bapd_project_id"),
        sa.ForeignKeyConstraint(["retention_policy_id"], ["retention_policies.id"], name="fk_bapd_retention_policy"),
        sa.ForeignKeyConstraint(["responsible_party_id"], ["users.id"], name="fk_bapd_responsible_party"),
        sa.ForeignKeyConstraint(["executed_by"], ["users.id"], name="fk_bapd_executed_by"),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], name="fk_bapd_created_by"),
        sa.PrimaryKeyConstraint("id", name="pk_bapd_records"),
    )
    op.create_index("ix_bapd_project_id", "bapd_records", ["project_id"])
    op.create_index("ix_bapd_status", "bapd_records", ["status"])

    # --- metadata_records ---
    op.create_table(
        "metadata_records",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("seq_no", sa.Integer(), nullable=False),
        sa.Column("business_users", sa.String(200), nullable=False),
        sa.Column("data_domain_table", sa.String(300), nullable=False),
        sa.Column("line_of_business", sa.String(200), nullable=True),
        sa.Column("table_type", sa.String(50), nullable=False, server_default="Source"),
        sa.Column("project_name", sa.String(300), nullable=False),
        sa.Column("project_year", sa.SmallInteger(), nullable=False),
        sa.Column("data_steward", sa.Text(), nullable=True),
        sa.Column("data_owner", sa.Text(), nullable=True),
        sa.Column("data_attribute", sa.String(300), nullable=False),
        sa.Column("data_sensitivity", sa.String(30), nullable=False, server_default="Confidential"),
        sa.Column("data_grouping", sa.Text(), nullable=True),
        sa.Column("business_term", sa.Text(), nullable=True),
        sa.Column("business_definition", sa.Text(), nullable=True),
        sa.Column("definition_status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("standard_format", sa.Text(), nullable=True),
        sa.Column("is_primary_key", sa.Boolean(), nullable=True),
        sa.Column("is_nullable", sa.Boolean(), nullable=True),
        sa.Column("sample_data", sa.Text(), nullable=True),
        sa.Column("data_type", sa.String(30), nullable=True),
        sa.Column("data_level", sa.String(30), nullable=False, server_default="Raw"),
        sa.Column("updated_date", sa.Date(), nullable=True),
        sa.Column("updated_by", sa.Text(), nullable=True),
        sa.Column("remarks", sa.Text(), nullable=False, server_default="-"),
        sa.Column("source_type", sa.String(20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_metadata_project_id"),
        sa.PrimaryKeyConstraint("id", name="pk_metadata_records"),
    )
    op.create_index("ix_metadata_project_id", "metadata_records", ["project_id"])
    op.create_index("ix_metadata_data_domain_table", "metadata_records", ["data_domain_table"])
    op.create_index("ix_metadata_data_attribute", "metadata_records", ["data_attribute"])

    # --- data_owner_stewards ---
    op.create_table(
        "data_owner_stewards",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("role_type", sa.String(50), nullable=False),
        sa.Column("full_name", sa.String(200), nullable=False),
        sa.Column("email", sa.String(200), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_dos_project_id"),
        sa.PrimaryKeyConstraint("id", name="pk_data_owner_stewards"),
    )
    op.create_index("ix_dos_project_id", "data_owner_stewards", ["project_id"])

    # --- dq_runs ---
    op.create_table(
        "dq_runs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("project_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("run_name", sa.String(300), nullable=False),
        sa.Column("dataset_name", sa.String(300), nullable=False),
        sa.Column("dataset_location", sa.Text(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False, server_default="pending"),
        sa.Column("total_checks", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("passed_checks", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("failed_checks", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("overall_score", sa.Numeric(5, 2), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("triggered_by", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("celery_task_id", sa.String(200), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["project_id"], ["projects.id"], name="fk_dq_runs_project_id"),
        sa.ForeignKeyConstraint(["triggered_by"], ["users.id"], name="fk_dq_runs_triggered_by"),
        sa.PrimaryKeyConstraint("id", name="pk_dq_runs"),
    )
    op.create_index("ix_dq_runs_project_id", "dq_runs", ["project_id"])
    op.create_index("ix_dq_runs_status", "dq_runs", ["status"])

    # --- dq_results ---
    op.create_table(
        "dq_results",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("run_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("check_name", sa.String(200), nullable=False),
        sa.Column("check_type", sa.String(50), nullable=False),
        sa.Column("column_name", sa.String(200), nullable=True),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("expected_value", sa.Text(), nullable=True),
        sa.Column("actual_value", sa.Text(), nullable=True),
        sa.Column("row_count", sa.Integer(), nullable=True),
        sa.Column("failed_count", sa.Integer(), nullable=True),
        sa.Column("details", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["run_id"], ["dq_runs.id"], name="fk_dq_results_run_id"),
        sa.PrimaryKeyConstraint("id", name="pk_dq_results"),
    )
    op.create_index("ix_dq_results_run_id", "dq_results", ["run_id"])

    # --- dq_findings ---
    op.create_table(
        "dq_findings",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("result_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("severity", sa.String(20), nullable=False, server_default="warning"),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("recommendation", sa.Text(), nullable=True),
        sa.Column("status", sa.String(30), nullable=False, server_default="open"),
        sa.Column("resolved_by", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["result_id"], ["dq_results.id"], name="fk_dq_findings_result_id"),
        sa.ForeignKeyConstraint(["resolved_by"], ["users.id"], name="fk_dq_findings_resolved_by"),
        sa.PrimaryKeyConstraint("id", name="pk_dq_findings"),
    )
    op.create_index("ix_dq_findings_result_id", "dq_findings", ["result_id"])
    op.create_index("ix_dq_findings_status", "dq_findings", ["status"])

    # --- dq_gcp_archives ---
    op.create_table(
        "dq_gcp_archives",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("run_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("gcs_report_path", sa.Text(), nullable=True),
        sa.Column("bq_dataset", sa.String(200), nullable=True),
        sa.Column("bq_table", sa.String(200), nullable=True),
        sa.Column("archived_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("archive_status", sa.String(30), nullable=False, server_default="pending"),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["run_id"], ["dq_runs.id"], name="fk_dq_gcp_archives_run_id"),
        sa.PrimaryKeyConstraint("id", name="pk_dq_gcp_archives"),
        sa.UniqueConstraint("run_id", name="uq_dq_gcp_archives_run_id"),
    )

    # Apply RLS policies and immutable audit_log trigger via raw SQL
    op.execute(open("alembic/init.sql").read())


def downgrade() -> None:
    op.drop_table("dq_gcp_archives")
    op.drop_table("dq_findings")
    op.drop_table("dq_results")
    op.drop_table("dq_runs")
    op.drop_table("data_owner_stewards")
    op.drop_table("metadata_records")
    op.drop_table("bapd_records")
    op.drop_table("retention_policies")
    op.drop_table("ropa_records")
    op.drop_table("dpia_records")
    op.drop_table("ai_compliance_checklists")
    op.drop_table("dsr_approvals")
    op.drop_table("data_sharing_requests")
    op.drop_table("data_sharing_agreements")
    op.drop_table("audit_logs")
    op.drop_table("user_project_roles")
    op.drop_table("projects")
    op.drop_table("users")
    op.drop_table("roles")
