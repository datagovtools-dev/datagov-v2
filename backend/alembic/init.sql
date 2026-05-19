-- ============================================================
-- init.sql — applied at end of migration 001
-- ============================================================

-- 1. Immutable audit_logs: block UPDATE and DELETE
CREATE OR REPLACE FUNCTION fn_audit_logs_immutable()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs rows are immutable — updates and deletes are not permitted';
END;
$$;

CREATE TRIGGER tg_audit_logs_immutable
BEFORE UPDATE OR DELETE ON audit_logs
FOR EACH ROW EXECUTE FUNCTION fn_audit_logs_immutable();


-- 2. Row-Level Security on data_sharing_requests
-- Users see only records for projects they are assigned to (or their own requests).
ALTER TABLE data_sharing_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_dsr_project_member ON data_sharing_requests
    USING (
        project_id IN (
            SELECT project_id FROM user_project_roles
            WHERE user_id = current_setting('app.current_user_id', true)::uuid
              AND revoked_at IS NULL
        )
        OR requester_id = current_setting('app.current_user_id', true)::uuid
    );


-- 3. Row-Level Security on dpia_records
ALTER TABLE dpia_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_dpia_project_member ON dpia_records
    USING (
        project_id IN (
            SELECT project_id FROM user_project_roles
            WHERE user_id = current_setting('app.current_user_id', true)::uuid
              AND revoked_at IS NULL
        )
    );


-- 4. Row-Level Security on ropa_records
ALTER TABLE ropa_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_ropa_project_member ON ropa_records
    USING (
        project_id IN (
            SELECT project_id FROM user_project_roles
            WHERE user_id = current_setting('app.current_user_id', true)::uuid
              AND revoked_at IS NULL
        )
    );


-- 5. Row-Level Security on bapd_records
ALTER TABLE bapd_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_bapd_project_member ON bapd_records
    USING (
        project_id IN (
            SELECT project_id FROM user_project_roles
            WHERE user_id = current_setting('app.current_user_id', true)::uuid
              AND revoked_at IS NULL
        )
    );


-- 6. Row-Level Security on metadata_records
ALTER TABLE metadata_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_metadata_project_member ON metadata_records
    USING (
        project_id IN (
            SELECT project_id FROM user_project_roles
            WHERE user_id = current_setting('app.current_user_id', true)::uuid
              AND revoked_at IS NULL
        )
    );


-- 7. Row-Level Security on dq_runs
ALTER TABLE dq_runs ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_dq_runs_project_member ON dq_runs
    USING (
        project_id IN (
            SELECT project_id FROM user_project_roles
            WHERE user_id = current_setting('app.current_user_id', true)::uuid
              AND revoked_at IS NULL
        )
    );


-- 8. Seed default roles
INSERT INTO roles (name, description) VALUES
    ('super_admin',        'Full system access across all projects'),
    ('data_governance_officer', 'Manages governance frameworks, approves DSRs and DPIAs'),
    ('project_manager',    'Creates and manages projects, assigns team members'),
    ('data_steward',       'Manages metadata, data quality runs, and ROPA records'),
    ('data_owner',         'Approves data sharing requests for owned datasets'),
    ('requester',          'Submits data sharing requests'),
    ('auditor',            'Read-only access to audit logs and reports'),
    ('viewer',             'Read-only access to project artifacts')
ON CONFLICT (name) DO NOTHING;
