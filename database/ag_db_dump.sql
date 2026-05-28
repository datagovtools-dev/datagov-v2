--
-- PostgreSQL database dump
--

\restrict b59ja8xBpFqakoyhg6bkeoIt0ameizBpAT7qsEpnqpxCVfGX2dcq9JsZpdINzZh

-- Dumped from database version 15.17
-- Dumped by pg_dump version 15.17

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_audit_logs_immutable(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_audit_logs_immutable() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'audit_logs rows are immutable — updates and deletes are not permitted';
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_checklist_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_checklist_approvals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    checklist_id uuid NOT NULL,
    approver_id uuid NOT NULL,
    approver_role character varying(80) NOT NULL,
    step_order smallint NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    comments text,
    actioned_at timestamp with time zone
);


--
-- Name: ai_compliance_checklists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_compliance_checklists (
    id uuid NOT NULL,
    dsr_id uuid NOT NULL,
    validated_by uuid,
    validated_at timestamp with time zone,
    checklist_json jsonb DEFAULT '{}'::jsonb NOT NULL,
    status character varying(30) DEFAULT 'draft'::character varying NOT NULL
);


--
-- Name: ai_provider_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_provider_configs (
    id uuid NOT NULL,
    provider character varying(40) NOT NULL,
    mode character varying(40) NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    base_url character varying(500) DEFAULT 'https://ollama.com'::character varying NOT NULL,
    model_name character varying(160) DEFAULT 'gpt-oss:120b'::character varying NOT NULL,
    timeout_seconds integer DEFAULT 60 NOT NULL,
    batch_size integer DEFAULT 5 NOT NULL,
    encrypted_api_key text,
    api_key_last4 character varying(12),
    updated_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    user_id uuid,
    module character varying(60) NOT NULL,
    action character varying(80) NOT NULL,
    entity_type character varying(80),
    entity_id text,
    details jsonb,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: bapd_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bapd_approvals (
    id uuid NOT NULL,
    bapd_id uuid NOT NULL,
    approver_id uuid NOT NULL,
    approver_role character varying(60) NOT NULL,
    step_order smallint NOT NULL,
    status character varying(20) NOT NULL,
    comments text,
    actioned_at timestamp with time zone
);


--
-- Name: bapd_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bapd_records (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    dataset_name character varying(300) NOT NULL,
    dataset_location text NOT NULL,
    retention_policy_id uuid,
    expiry_date date NOT NULL,
    reason text NOT NULL,
    responsible_party_id uuid NOT NULL,
    status character varying(30) NOT NULL,
    pod_file_path text,
    executed_at timestamp with time zone,
    executed_by uuid,
    version smallint NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: data_owner_stewards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_owner_stewards (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    role_type character varying(50) NOT NULL,
    full_name character varying(200) NOT NULL,
    email character varying(200) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: data_sharing_agreements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sharing_agreements (
    id uuid NOT NULL,
    title text NOT NULL,
    file_path text,
    validity_start date NOT NULL,
    validity_end date,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: data_sharing_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sharing_requests (
    id uuid NOT NULL,
    tracking_id character varying(30) NOT NULL,
    project_id uuid NOT NULL,
    requester_id uuid NOT NULL,
    dataset_name character varying(300) NOT NULL,
    recipient text NOT NULL,
    purpose text NOT NULL,
    is_ai_use boolean NOT NULL,
    duration_start date NOT NULL,
    duration_end date NOT NULL,
    dsa_id uuid,
    status character varying(30) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: dpia_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dpia_approvals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    dpia_id uuid NOT NULL,
    approver_id uuid NOT NULL,
    approver_role character varying(80) NOT NULL,
    step_order smallint NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    comments text,
    actioned_at timestamp with time zone
);


--
-- Name: dpia_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dpia_records (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    process_name character varying(300) NOT NULL,
    purpose text NOT NULL,
    data_category text NOT NULL,
    risk_description text NOT NULL,
    mitigation_measures text,
    residual_risk character varying(20),
    likelihood_score smallint,
    impact_score smallint,
    risk_score smallint,
    assessment_date date NOT NULL,
    responsible_party_id uuid NOT NULL,
    status character varying(30) NOT NULL,
    version smallint NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tracking_id character varying(30),
    governance_json jsonb DEFAULT '{}'::jsonb,
    CONSTRAINT ck_dpia_records_ck_dpia_impact CHECK (((impact_score >= 1) AND (impact_score <= 5))),
    CONSTRAINT ck_dpia_records_ck_dpia_likelihood CHECK (((likelihood_score >= 1) AND (likelihood_score <= 5)))
);


--
-- Name: dq_findings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dq_findings (
    id uuid NOT NULL,
    result_id uuid NOT NULL,
    severity character varying(20) NOT NULL,
    description text NOT NULL,
    recommendation text,
    status character varying(30) NOT NULL,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: dq_gcp_archives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dq_gcp_archives (
    id uuid NOT NULL,
    run_id uuid NOT NULL,
    gcs_report_path text,
    bq_dataset character varying(200),
    bq_table character varying(200),
    archived_at timestamp with time zone DEFAULT now() NOT NULL,
    archive_status character varying(30) NOT NULL,
    error_message text
);


--
-- Name: dq_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dq_results (
    id uuid NOT NULL,
    run_id uuid NOT NULL,
    check_name character varying(200) NOT NULL,
    check_type character varying(50) NOT NULL,
    column_name character varying(200),
    status character varying(20) NOT NULL,
    expected_value text,
    actual_value text,
    row_count integer,
    failed_count integer,
    details jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    business_rules text,
    regex_pattern text,
    ai_model character varying(100),
    regex_version character varying(50),
    column_category character varying(50)
);


--
-- Name: dq_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dq_runs (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    run_name character varying(300) NOT NULL,
    dataset_name character varying(300) NOT NULL,
    dataset_location text NOT NULL,
    status character varying(30) NOT NULL,
    total_checks integer NOT NULL,
    passed_checks integer NOT NULL,
    failed_checks integer NOT NULL,
    overall_score numeric(5,2),
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    triggered_by uuid NOT NULL,
    celery_task_id character varying(200),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    source_file_id uuid
);


--
-- Name: dsr_approvals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dsr_approvals (
    id uuid NOT NULL,
    dsr_id uuid NOT NULL,
    approver_id uuid NOT NULL,
    approver_role character varying(80) NOT NULL,
    step_order smallint NOT NULL,
    status character varying(20) NOT NULL,
    comments text,
    actioned_at timestamp with time zone
);


--
-- Name: metadata_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.metadata_records (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    seq_no integer NOT NULL,
    business_users character varying(200) NOT NULL,
    data_domain_table character varying(300) NOT NULL,
    line_of_business character varying(200),
    table_type character varying(50) NOT NULL,
    project_name character varying(300) NOT NULL,
    project_year smallint NOT NULL,
    data_steward text,
    data_owner text,
    data_attribute character varying(300) NOT NULL,
    data_sensitivity character varying(30) NOT NULL,
    data_grouping text,
    business_term text,
    business_definition text,
    definition_status character varying(20) NOT NULL,
    standard_format text,
    is_primary_key boolean,
    is_nullable boolean,
    sample_data text,
    data_type character varying(30),
    data_level character varying(30) NOT NULL,
    updated_date date,
    updated_by text,
    remarks text NOT NULL,
    source_type character varying(20) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    source_row_count integer,
    data_year smallint,
    distinct_values text
);


--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_preferences (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    module character varying(60) NOT NULL,
    in_app boolean NOT NULL,
    email boolean NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    module character varying(60) NOT NULL,
    event character varying(80) NOT NULL,
    title character varying(300) NOT NULL,
    body text,
    entity_type character varying(80),
    entity_id text,
    is_read boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: project_source_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_source_files (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    source_type character varying(32) NOT NULL,
    original_filename character varying(512) NOT NULL,
    stored_path character varying(1024) NOT NULL,
    file_size bigint,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL,
    uploaded_by character varying(256)
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid NOT NULL,
    project_name character varying(300) NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    customer_name character varying(200) NOT NULL,
    line_of_business character varying(200),
    use_case text,
    project_year smallint NOT NULL,
    project_category character varying(50) NOT NULL,
    is_monetized boolean NOT NULL,
    delivery_manager_id uuid,
    project_manager_id uuid,
    dgo_id uuid,
    metadata_officer_id uuid,
    dq_officer_id uuid,
    pic_data_compliance_id uuid,
    start_date date,
    end_date date,
    project_code character varying(50),
    sme_id uuid
);


--
-- Name: retention_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.retention_policies (
    id uuid NOT NULL,
    dataset_type character varying(150) NOT NULL,
    retention_days integer NOT NULL,
    policy_reference text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id smallint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: ropa_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ropa_records (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    process_name character varying(300) NOT NULL,
    purpose text NOT NULL,
    data_category text NOT NULL,
    data_subject text NOT NULL,
    legal_basis text NOT NULL,
    retention_period character varying(100) NOT NULL,
    recipient text,
    linked_asset_ids character varying[],
    status character varying(30) NOT NULL,
    version smallint NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_project_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_project_roles (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id smallint NOT NULL,
    project_id uuid,
    assigned_by uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    full_name character varying(200) NOT NULL,
    email character varying(200) NOT NULL,
    password_hash text NOT NULL,
    is_active boolean NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    "position" character varying(200)
);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Data for Name: ai_checklist_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_checklist_approvals (id, checklist_id, approver_id, approver_role, step_order, status, comments, actioned_at) FROM stdin;
0b6a763f-bbc1-4e5c-9629-eb48961e1dbf	d01c3abc-3cab-4fa8-8816-1c1aa3d6a3e3	3991d4dd-deb4-432c-9a8a-edee818513b0	sme	3	pending	\N	\N
0e1b4ce7-895c-446b-a4f1-7385c8176fcd	b6113743-ae21-4fda-8fd5-896d08d429ea	13c686f6-db44-4585-b9f1-6c6200aac025	dm	2	pending	\N	\N
10c09d27-7f07-458c-b04e-aff4f6790be3	b6113743-ae21-4fda-8fd5-896d08d429ea	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	pending	\N	\N
11fac752-3ae0-445d-a358-43d4fb9c96e1	ae5892cf-9769-4a96-8185-c2987d1809c7	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	pending	\N	\N
31b93617-baa1-4990-a3a2-a16b25ef1955	d01c3abc-3cab-4fa8-8816-1c1aa3d6a3e3	13c686f6-db44-4585-b9f1-6c6200aac025	dm	2	pending	\N	\N
33cdb393-4e8a-435c-8305-e37b7db2bd29	d79ab212-4127-4026-b58e-cb60da607cb0	f961edea-0a7a-4f6c-8738-098f640b6dc8	pic_compliance	1	pending	\N	\N
47869237-72ef-481b-a8d0-49714f1f9efe	ae5892cf-9769-4a96-8185-c2987d1809c7	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	pending	\N	\N
63cbabe3-8f85-41eb-835d-a44bc0bce688	6ae7c72b-400c-4d30-b87d-e35878cd8180	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
7bea5254-af98-4ccc-8276-abaedc937937	d01c3abc-3cab-4fa8-8816-1c1aa3d6a3e3	19d275fc-8c44-4411-a412-92a85834759b	pic_compliance	1	pending	\N	\N
b8b172fb-dc0d-437c-a5a0-8f07a8f358fb	6ae7c72b-400c-4d30-b87d-e35878cd8180	336b5420-9af0-49de-b844-e42ee6658cd4	pic_compliance	1	pending	\N	\N
c0485c6b-9447-4c89-8601-fc676977b74f	d79ab212-4127-4026-b58e-cb60da607cb0	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm	2	pending	\N	\N
d4d25e1e-7784-49a2-8672-401d220fc929	6ae7c72b-400c-4d30-b87d-e35878cd8180	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm	2	pending	\N	\N
da7721a1-c861-4d57-ad6c-95629694937b	ae5892cf-9769-4a96-8185-c2987d1809c7	13c686f6-db44-4585-b9f1-6c6200aac025	dm	2	pending	\N	\N
f53b9119-b43d-4569-9ab2-4bef392d7031	d79ab212-4127-4026-b58e-cb60da607cb0	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
fc0b12ea-4e2a-4f4b-9d66-e2a62f6a9675	b6113743-ae21-4fda-8fd5-896d08d429ea	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	pending	\N	\N
\.


--
-- Data for Name: ai_compliance_checklists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_compliance_checklists (id, dsr_id, validated_by, validated_at, checklist_json, status) FROM stdin;
6ae7c72b-400c-4d30-b87d-e35878cd8180	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-19 03:25:08.781208+00	{"B_i": {"answer": "Yes", "remarks": "Dataset may contain customer and operational information classified as sensitive."}, "B_v": {"answer": "Yes", "remarks": "Consent for analytics and AI/ML use is obtained through service agreements and internal approvals."}, "D_i": {"answer": "Yes", "remarks": "Data may be used for AI/ML-based analytics such as forecasting, prediction, and operational optimization."}, "B_ii": {"answer": "Yes", "remarks": "Data is pseudonymized/masked and access is restricted to authorized personnel only."}, "B_iv": {"answer": "Yes", "remarks": "Written consent is covered under customer agreements and privacy notices."}, "B_vi": {"answer": "Yes", "remarks": "All data processing is conducted within secured environments with limited, role-based access and audit logging."}, "A_i_1": {"answer": "No", "remarks": "No revenue cannibalization risk; data is used for internal integration and reporting purposes only."}, "A_i_2": {"answer": "No", "remarks": "Customer data is handled under internal data protection policies; customer relationship risk is mitigated."}, "A_i_3": {"answer": "No", "remarks": "No other commercial interest risks have been identified for this data sharing request."}, "B_iii": {"answer": "Yes", "remarks": "Dataset contains personal data elements under UU PDP No. 27 Tahun 2022."}, "C_i_1": {"answer": "No", "remarks": "No violations of automotive industry regulations or compliance requirements identified."}, "C_i_2": {"answer": "No", "remarks": "Compliant with UU PDP No. 27 Tahun 2022 and applicable data protection regulations."}, "C_i_3": {"answer": "No", "remarks": "Compliant with internal data governance policies, SOPs, and enterprise security standards."}, "A_ii_1": {"answer": "No", "remarks": "The dataset does not contain confidential partnership or strategic collaboration information."}, "A_ii_2": {"answer": "No", "remarks": "No patent, intellectual property, or proprietary technical information is included."}, "A_ii_3": {"answer": "No", "remarks": "No merger, acquisition, or corporate restructuring information is included."}, "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets have been identified within the requested dataset."}, "sign_off": {"remarks": "Data sharing for PRJ-2026-018 (Enterprise Data Integration Platform Implementation) is intended to support enterprise reporting, operational monitoring, and analytics across authorized Astra business units. The shared datasets include operational and transactional data from after sales, service, inventory, billing, and related systems. All sensitive and personal data are protected through pseudonymization, access control, and encryption. The activity complies with applicable laws and internal governance policies, and any AI/ML usage is limited to internal analytics and business improvement purposes.", "approved": "Yes", "prepared_by": "Bambang Budi Santoso", "acknowledged_by": "Adi Kurniawan", "prepared_position": "Head of IT Dept Head", "acknowledged_position": "Data Analyst"}, "ai_assessment": {"items": {"input_1": {"status": "No", "remarks": "Dataset contains personal and sensitive operational data; mitigated using pseudonymization"}, "input_2": {"status": "Yes", "remarks": "Sensitive data is pseudonymized before being processed by AI models"}, "input_3": {"status": "Yes", "remarks": "Prompts are standardized, documented, and reviewed for compliance"}, "output_1": {"status": "Yes", "remarks": "Outputs are validated by BI team using reporting systems and trusted datasets"}, "output_2": {"status": "Yes", "remarks": "All generated scripts are reviewed and tested before deployment"}, "before_use_1": {"status": "Yes", "remarks": "Fully compliant with applicable regulations; AI usage limited to internal analytics purposes"}, "before_use_2": {"status": "Yes", "remarks": "AI tools are enterprise-approved and comply with IT security standards"}, "before_use_3": {"status": "Yes", "remarks": "All configurations set to prevent data retention and training usage"}, "utilization_1": {"status": "Yes", "remarks": "Outputs require BI team validation and data owner approval before use"}, "utilization_2": {"status": "Yes", "remarks": "Outputs are corrected and revalidated before distribution"}}, "sign_off": {"approved": "Yes", "prepared_by": "Agus Setiawan", "acknowledged_by": "Adi Kurniawan", "prepared_position": "Senior Data Engineer", "acknowledged_position": "Data Analyst"}}}	draft
ae5892cf-9769-4a96-8185-c2987d1809c7	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	{"B_i": {"answer": "Yes", "remarks": "Dataset includes customer financial behaviour and transaction history, classified as sensitive personal financial data under UU PDP."}, "B_v": {"answer": "Yes", "remarks": "Customer consent for AI/ML model development is covered under the digital banking service agreement signed at account opening."}, "D_i": {"answer": "Yes", "remarks": "The credit risk scoring model utilises gradient boosting machine learning algorithms to predict default probability based on customer transaction patterns and financial behaviour data."}, "B_ii": {"answer": "Yes", "remarks": "Data is pseudonymized and aggregated prior to sharing. PII fields are masked and access is restricted to the authorized analytics team only."}, "B_iv": {"answer": "Yes", "remarks": "Written consent has been obtained through customer onboarding agreements and terms of service covering data use in credit risk assessment."}, "B_vi": {"answer": "Yes", "remarks": "All data processing is conducted within PT Finansial Nusantara's secured analytics environment with role-based access controls and audit logging."}, "A_i_1": {"answer": "No", "remarks": "Credit risk data is used for internal analytics only; no revenue cannibalization risk identified."}, "A_i_2": {"answer": "No", "remarks": "Data is pseudonymized before sharing; customer identity is protected throughout the process."}, "A_i_3": {"answer": "No", "remarks": "No other commercial interest risks have been identified for this data sharing request."}, "B_iii": {"answer": "Yes", "remarks": "Transaction records and credit history contain personal financial data subject to the Personal Data Protection Law (UU PDP No. 27/2022)."}, "C_i_1": {"answer": "No", "remarks": "OJK regulations on credit scoring and data sharing have been reviewed; this request complies with applicable banking sector regulations."}, "C_i_2": {"answer": "No", "remarks": "Data sharing is compliant with UU PDP No. 27 of 2022; appropriate technical and organisational safeguards are in place."}, "C_i_3": {"answer": "No", "remarks": "Internal data governance policy and data sharing SOP have been reviewed; this request is fully compliant with internal regulations."}, "A_ii_1": {"answer": "No", "remarks": "No highly confidential partnership information is included in the requested dataset."}, "A_ii_2": {"answer": "No", "remarks": "Dataset contains transactional and behavioural data only; no patent-related information involved."}, "A_ii_3": {"answer": "No", "remarks": "No merger or acquisition information is included in the scope of this data sharing."}, "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets identified within the requested credit data dataset."}, "sign_off": {"remarks": "All data governance requirements have been reviewed and verified. This data sharing is approved for credit risk model development purposes only.", "approved": "Yes", "prepared_by": "Dian Pratiwi", "prepared_date": "", "acknowledged_by": "Dewi Rahayu", "acknowledged_date": "", "prepared_position": "Head of Analytics", "prepared_signature": "", "acknowledged_position": "Senior Data Scientist", "acknowledged_signature": ""}}	draft
b6113743-ae21-4fda-8fd5-896d08d429ea	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	\N	2026-01-27 14:00:00+00	{"B_i": {"answer": "Yes", "remarks": "Contains personal financial transaction data classified as sensitive under UU PDP."}, "B_v": {"answer": "Yes", "remarks": "Research consent included in digital banking app consent form signed by customers."}, "D_i": {"answer": "Yes", "remarks": "Generative AI models are used for customer financial insight generation. AI Checklist Assessment completed separately."}, "B_ii": {"answer": "Yes", "remarks": "PII fields are masked and tokenised before sharing; access restricted to authorised team members only."}, "B_iv": {"answer": "Yes", "remarks": "Customer consent obtained via Terms & Conditions agreement at account opening."}, "B_vi": {"answer": "Yes", "remarks": "Data is processed within the BU secured analytics environment with role-based access control enforced."}, "A_i_1": {"answer": "No", "remarks": "No revenue cannibalization risk; data is used solely for internal AI model development."}, "A_i_2": {"answer": "No", "remarks": "Data is anonymised prior to use; no direct customer relationship impact."}, "A_i_3": {"answer": "No", "remarks": "No other commercial interests identified."}, "B_iii": {"answer": "Yes", "remarks": "Transaction records contain customer identifiers and financial data constituting personal data."}, "C_i_1": {"answer": "No", "remarks": "Compliant with OJK regulations on data usage for financial analytics purposes."}, "C_i_2": {"answer": "No", "remarks": "Compliant with UU PDP (Personal Data Protection Law No. 27/2022)."}, "C_i_3": {"answer": "No", "remarks": "Compliant with internal Data Governance Policy v2.1 and AI Ethics Guidelines."}, "A_ii_1": {"answer": "No", "remarks": "No confidential partnership data is included in the transaction dataset."}, "A_ii_2": {"answer": "No", "remarks": "No patent information present in scope of data."}, "A_ii_3": {"answer": "No", "remarks": "No M&A-related information included."}, "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets identified in the dataset."}, "sign_off": {"remarks": "All compliance requirements have been reviewed and satisfied. Data sharing approved for AI model development purposes.", "approved": "Yes", "prepared_by": "Rendra Kusuma Wijaya", "prepared_date": "2026-01-25", "acknowledged_by": "Dewi Rahayu", "acknowledged_date": "2026-01-25", "prepared_position": "Head of Digital Innovation", "prepared_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAAClklEQVR4nO2cQXIDIQwE85Lc84b8/13OLeWyDSskoQG2u3Jy1pIYaJLTfj0AQMqXegCAu4OEAGKQEEAMEgKIQUIAMUgIIAYJAcQgIYAYJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxCAhgJjNJPz++X3+UY+zPS95EqyEnSTkuGTRco9sJeRIWLBzHJcgRvFODXbldeVLOGOFtzouuYzKdl6265+ZBAlnL69VvCzWZTevRfCv3LwjW5/kFtd3VMLZC+tXrvd/qc17Ieiepdqk2dxlR5t2Jpk0g4VZElZenDWtV9u5mjnj1SRJXrZYakNDEl5eM4nF+9USA+0flHV2ruxkR4pLkrRXzs3NXccvYaufcD3BNI2nWe5hgXjGpo4hIzV9c/qWZp8kvhc5EvbHilQereDLwpGjRMV69ywDGIeM1MyabfTro2OXSnjZLDGL4GzuKHMbBZHrdzlJ/1eOmvGpclfXfyDS1yOhpaVvrMQTdplOVoizxVhHP+NU9UmmJ2NcXVbTqITGxywj1kTZ+jzScZIka+r3TE2Sic/Hh5nRbljCoQkiaY4OZq88Kcrcsovr948wyZp8CjZiTELHHJavzI5ytn6XjeqLFFNzdfYfyGrdn2dGcb+Evm+9f7EsTWEj34W1hX5T6d+ex0Q0IGHi7d76fOv7rNXLsrojz1YKxxv4cEs42uZjauel+YLlxJx6sHI5OyWPhL5Ox99nLVqLvVsOQQ4Oqk7CR9dDd80tsPxPdXwIKRyZVfXrLe58+NAPPiJ4x8ydzx/6wTuaFz3d/AjefPnwwk5vWwM4EiQEEIOEAGKQEEAMEgKIQUIAMUgIIAYJAcQgIYAYJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxPwBr27y8ba2v8YAAAAASUVORK5CYII=", "acknowledged_position": "Senior Data Scientist", "acknowledged_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAACmklEQVR4nO3bS1JrMQxFUUaSPmNg/uMKPYoKN0aSJR052atoJteyrGM+L+/jDkDqQ10A8O4IISBGCAExQgiIEUJAjBACYoQQECOEgBghBMQIISBGCAExQgiIEUJAjBACYoQQECOEgNi4EN4+v35/qcuB1cPBcYJ2s0LIKR7nWfY4RLtBIdQeIUNjZwweLTWaEkLhETI3Rt6w0VKjESG8PKqe8xt1fw8c2c3vcm1dHdg6O30I1+0rba4x/NUnOucWMJbkra1uX6Pu0DBxCC1dq+js+sCE97dwkqqLaXjaoTlUhtDer9zOGo9KdX9fviBl3Vg9DRvPKnXxmpT6i8hC6G1TVlv31627v+vWjZVUsdyzFXfq/Pv2s3KoCWGsQZttDR9Mz/1tfKN90XBViUt4V7cX2X+B1nGEMGsnudMcfmNPhndm6NkTXGW7Ckt58mYNt+VPlf3nHqjfu0QwhOGdpHRk/0YM1X79qMunpQxQRf32LbRZ96po6tJnYKfmeAgDOyltRFHNxmfeUu/vuo1MS+CPovitn59bYTiQvt8Jd3bS0NbEagOr1w3QYtHNgrMKS9FQYWwJ1/kGRiLyh5nAToqau3hsz8C1xW+xYrjO9NpSVJdnb8Xm4drfHvzrqKum0uMPXDy5+ufbtdxB8eu0aEvFLJWE0PLoZ6/ZWdFeRvPMNc+3cZskcMF4faf3LTmE9/+O+bW/I8m5Ov/y3YiZcIPn/GN9811iLKN6uQkum0wCXeTtSvvEjDyBD2X0LDfBkM6fTtiu5I+tMQcSJPBo+Z8dZQ5UaPuhqj7AzShI0PYT6f9nPfDmCCEgRggBMUIIiBFCQIwQAmKEEBAjhIAYIQTECCEgRggBMUIIiBFCQIwQAmKEEBAjhIDYN8GW/N1n4h0IAAAAAElFTkSuQmCC"}, "ai_assessment": {"items": {"input_1": {"status": "Yes", "remarks": "Customer transaction data is fully anonymised and tokenised before being used as AI model input. No raw PII — names, account numbers, phone numbers — is included in any prompt or model input."}, "input_2": {"status": "Yes", "remarks": "All data inputs to the Gen AI pipeline are pseudonymised. Customer identifiers are replaced with internal tokens, and synthetic dummy data is used during model exploration and testing phases."}, "input_3": {"status": "Yes", "remarks": "All prompts are reviewed by the AI Engineer and Data Scientist before use. Prompt templates are documented in the project repository under /docs/prompt-log.txt and versioned accordingly."}, "output_1": {"status": "Yes", "remarks": "All AI-generated financial insights are reviewed and validated by the Subject Matter Expert (Dewi Rahayu) before being surfaced to end users. A validation checklist is applied to each output batch to check for hallucinations, bias, or inaccuracies."}, "output_2": {"status": "Yes", "remarks": "Any source code generated or assisted by Gen AI undergoes mandatory peer review by a senior developer, security static analysis scanning, and functional testing before integration into the customer analytics platform."}, "before_use_1": {"status": "Yes", "remarks": "The platform has been reviewed against OJK regulations, UU PDP No. 27/2022, and internal AI Ethics & Governance Policy. Legal and compliance sign-off obtained prior to project initiation."}, "before_use_2": {"status": "Yes", "remarks": "The generative AI platform used for financial insight generation is officially licensed and has received formal written approval from the Chief Technology Officer and Head of Digital Innovation."}, "before_use_3": {"status": "Yes", "remarks": "Platform settings have been configured to disable interaction history logging. The team has opted out of all model training data-sharing options provided by the Gen AI service provider."}, "utilization_1": {"status": "Yes", "remarks": "AI-generated insights and recommendations are only released after independent assessment and sign-off by the authorised SME. A review checklist is used to confirm outputs are ready for customer-facing use."}, "utilization_2": {"status": "Yes", "remarks": "A feedback and correction loop is in place. Inaccurate or inappropriate AI outputs are flagged, corrected, and logged in the incident register before any distribution to customers or stakeholders."}}, "sign_off": {"approved": "Yes", "prepared_by": "Ahmad Fauzi", "prepared_date": "2026-01-27", "acknowledged_by": "Dewi Rahayu", "acknowledged_date": "2026-01-27", "prepared_position": "Senior Delivery Manager", "prepared_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAACg0lEQVR4nO2bSW7DMBAE/RLf84b8/13KIRcjgcStZ3ooVSHHmNNqsmgDhl8HAFh5uQMAPB0kBDCDhABmkBDADBICmEFCADNICGAGCQHMICGAGSQEMIOEAGaQEMAMEgKYQUIAM7eS8P31/fnnjrM9f/qk2CDuIyHHRcKZeHQbR4iE+bvFcVmhX7zMYp+zj3oJK+zWc/ZvjmnTcrp92lYqJbR0dzbItX9lD43qLS50fyu8A/ek0q4vk9DSXYVr+2KWXUWVeJ0rB0WNGLeeShhAI+FZvtDiOheP3rygU54TLGKEMKd8liqYNoZAwtHu1ieOLpt2/pp3UI6KmXfBypSJkDmVnk0JKnZJws4oCQLEvapnnYs18z20mD86dOUoRz/g9LZOh5mXcHS2qrWVZ16pbKX3HDEs+o0GUJ3diIcVXiVDYSYlnBu5Xtl67yqFJA6PhjeuvxLj3fosJ5+lWm0xSeciMxKuPLbrtc2l/q+muudG51ZYMyJSUE7JspJg0086JqHxgTPPbui5qW+1imj9moOmX5ucZ0BCYdbRpeK28PqgxJ1s43WWSeYdMTErNF6GhGkRLT64Do3x/o4jM2FnM5aNPvuHSQkV2brsMioRNKg513t/34BmP9UKnJFQOH60LOHoizChU65H17m/d6f5AadOgf7fE56VUrCsULa7v+uzhYFHBQl/2aKsBDa6v3ehfoFVJDwCvszdFAyUU7zAQhIefOL6AP3klO2wloSH+ouQrcHAh1BOwqPwjWWBNm5PRQkBHgUSAphBQgAzSAhgBgkBzCAhgBkkBDCDhABmkBDADBICmEFCADNICGAGCQHMICGAGSQEMIOEAGaQEMAMEgKY+QEOqe37kV4VDgAAAABJRU5ErkJggg==", "acknowledged_position": "Senior Data Scientist", "acknowledged_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAACs0lEQVR4nO2cS27DMAwFe5Lse4be/1zpokAQJLFM8fdkdQbd1RGfSI3ibvp1BwApX+oAAP8dJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxCAhgBgkBBCDhABikBBADBICiEFCADEdEt6+f55/GirCmJeJMBQj731LaV25hEW5wcfHcTCUAYOOZbWuUMLS3Bdinb1XH6adsLiX1b0qCRvuj0uwyPYbTtIe2FuU2L0SCe25K6ofxSitZQkgOfSndTtTrel85HpK6V6+hONMPWNY4aZ/r9ucKniY2vKoVIy4d7rOVJJMCY1pqmcQb2t6AGO80gyn69flSTnruaSHiSySJmFw5EUZbsdfQSkVLRnsUVOCRZbtDKNSsbnzlg/mSJgy8vQMz2v2jDx4EwWzpSyV2KjTpfo9bKjoWD9Bwsiu6g5f8MmUGJH8KSt4txKdy1Qe1f1YJ/xsrZCEKRurmHd1Zsuy8RXc2xHuyJen2pBOAx0V/RKucO8mflCS357t45r9Z9eRPFIuvp1+/RzVnRI2NGv2+dkMvjs7njwlXlZ4X4zZtMFy7n1pDbRn8EjYduzsT6rmVD3jo0PZfLYG5SryrHw5+hiHmZOwevyni1cEcB+jthkL9RtkOApWVM6+uLBLU6kev5qQsGdjs5duXd3B4pIZyw/W+C6oiOQosaaBD5IlLEh4WKuts5ZC2hlrD1bzOAZF3Y/JSZOwINuo3Dojv8SYq1nhLeCl7lUM/IhHwro0RxX7O2v5Kr7QmNPRvgVsNpfV/8fMCi9+e0x6D/Yz8L6+hPdV/wqShIE/NhvKBSSUs82wd2KnoSChlQ2GvR97DAUJAcQgIYAYJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxCAhgBgkBBCDhABikBBADBICiEFCADFICCAGCQHEICGAmF9ogHlmP+PZFwAAAABJRU5ErkJggg=="}}}	draft
d01c3abc-3cab-4fa8-8816-1c1aa3d6a3e3	1ecb4c17-aca7-4159-b8aa-66dc208bd415	\N	\N	{}	draft
d79ab212-4127-4026-b58e-cb60da607cb0	f0a3e2af-135d-4048-86e4-44ac5457a8ee	\N	\N	{}	draft
\.


--
-- Data for Name: ai_provider_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_provider_configs (id, provider, mode, enabled, base_url, model_name, timeout_seconds, batch_size, encrypted_api_key, api_key_last4, updated_by, created_at, updated_at) FROM stdin;
5c33fe93-c2df-4458-ba47-2d921f7a3d8a	ollama	cloud	t	https://ollama.com	gpt-oss:120b	60	5	gAAAAABqDXYiAolHDyvGHqBFbUlQfeX265euGlX6WqvcbyZXadCwmAOckwSlIytZ_O2KSuDnuSTPOwBnO9saXlgdhsKeTVNYtfqCJFjPG6ew-RKbvqyOJtVPtAnUJ7zTBNYHvEnIWuou9dZv0_mJeEeSjk3RaeP-xw==	kgj-	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-20 08:39:36.708303+00	2026-05-20 08:51:44.543312+00
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alembic_version (version_num) FROM stdin;
b6c7d8e9f0a1
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, user_id, module, action, entity_type, entity_id, details, ip_address, user_agent, created_at) FROM stdin;
1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8115	2026-05-06 06:50:52.812258+00
2	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8115	2026-05-06 07:00:49.886774+00
3	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8115	2026-05-06 07:00:59.194544+00
4	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:08:03.129989+00
5	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:14:50.336821+00
6	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:14:50.335464+00
7	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:21:22.976955+00
8	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:21:23.020084+00
9	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:23:12.076931+00
10	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:23:12.079803+00
11	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:28:30.023989+00
12	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:28:30.052932+00
13	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:33:38.722465+00
14	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:33:38.760161+00
15	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:34:57.970501+00
16	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:34:57.969933+00
17	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:35:44.811101+00
18	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:35:44.805722+00
19	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:39:44.333813+00
20	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:39:44.29715+00
21	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:44:28.629986+00
22	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:44:28.63192+00
23	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:44:31.414528+00
24	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:44:31.417547+00
25	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:46:03.884539+00
26	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:46:03.884523+00
27	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:46:03.94391+00
28	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:47:04.62165+00
29	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:47:04.757996+00
30	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:47:04.839645+00
31	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:53:59.794204+00
32	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:53:59.929122+00
33	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:54:55.569057+00
34	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:54:55.570676+00
35	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:56:44.828735+00
36	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:56:45.019262+00
37	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:01:56.687765+00
38	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:01:56.68509+00
39	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:09:45.951067+00
40	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:09:45.974054+00
41	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:11:51.941636+00
42	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:11:51.944022+00
43	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:22:58.608093+00
44	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:22:58.712549+00
45	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:25:22.813823+00
46	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:25:22.817797+00
47	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:26:24.096308+00
48	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:26:24.090313+00
49	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:30:41.622372+00
50	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:30:41.617225+00
51	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:32:42.324923+00
52	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:32:42.475033+00
53	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:33:12.678234+00
54	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:33:12.68875+00
55	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:33:43.327181+00
56	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:33:43.338649+00
57	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:36:21.397059+00
58	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:36:21.608248+00
59	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:41:25.872005+00
60	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:41:25.921204+00
61	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:51:16.397151+00
62	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:51:16.457714+00
63	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:57:07.836612+00
64	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:57:07.982108+00
65	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:58:35.037366+00
66	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:58:35.071533+00
67	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:04:31.446897+00
68	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:04:31.442176+00
69	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:06:23.219256+00
70	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:06:23.230777+00
71	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:07:25.589714+00
72	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:07:25.623876+00
73	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:07:59.782781+00
74	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:07:59.792667+00
75	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:08:56.552245+00
76	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:08:56.553644+00
77	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:09:31.3381+00
78	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:09:31.436042+00
79	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:10:48.513887+00
80	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:10:48.606594+00
81	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:17:06.788983+00
82	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:17:06.800856+00
83	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:17:43.094418+00
84	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:17:43.108763+00
85	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:06.910074+00
86	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:06.910383+00
87	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:07.184515+00
88	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:07.475399+00
89	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:35:41.316203+00
90	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:35:41.31902+00
91	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 01:37:11.702241+00
92	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 01:37:23.349883+00
93	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:02:36.764815+00
94	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:02:36.76805+00
95	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:13:36.559403+00
96	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:13:36.578266+00
97	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	login	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:22:32.542309+00
98	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:30:03.785862+00
99	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:30:03.791537+00
100	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:31:47.583549+00
101	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:31:47.627309+00
102	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:31:47.749179+00
103	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:32:08.330506+00
104	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:32:08.33185+00
105	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:35:00.819222+00
106	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:35:00.827183+00
107	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:55:23.094334+00
108	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:55:23.093149+00
109	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:55:23.9528+00
110	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:55:24.007823+00
111	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:59:26.984186+00
112	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:59:27.033897+00
113	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:01:48.28068+00
114	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:01:48.391159+00
115	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:01:56.043979+00
116	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:01:56.067882+00
117	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	dsr	create	dsr	5f8cf746-6035-447a-9cfa-3694bd423aaa	{"tracking_id": "DSR-2026-0002"}	\N	\N	2026-05-07 03:02:08.540473+00
118	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:16:58.067753+00
119	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:16:58.145255+00
120	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:20:27.323028+00
121	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:20:27.561567+00
122	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:21:02.355569+00
123	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:21:02.356101+00
124	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:22:58.643727+00
125	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:22:58.891413+00
126	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:31:11.49247+00
127	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:31:11.501933+00
128	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:36:48.475568+00
129	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:36:48.66704+00
130	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:43:52.238219+00
131	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:43:52.237075+00
132	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	login	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:49:03.843777+00
133	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:50:47.687962+00
134	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:50:47.692236+00
135	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:54:10.785622+00
136	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:54:11.182601+00
137	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:01:03.26059+00
138	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:01:03.269367+00
139	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:01:16.29907+00
140	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:01:16.319566+00
141	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:01:16.544956+00
142	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:05:01.668588+00
143	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:05:01.910169+00
144	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:08:31.24679+00
145	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:08:31.248414+00
146	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:08:41.013035+00
147	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:08:41.294091+00
148	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:12:29.123071+00
149	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:12:29.129021+00
150	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:16:48.613567+00
151	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:16:48.761376+00
152	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:18:26.812838+00
153	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:18:26.824228+00
154	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:30:42.312411+00
155	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:30:42.331624+00
156	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:36.711233+00
157	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:36.709725+00
158	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:36.702899+00
159	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:36.88462+00
160	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:54.864258+00
161	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:54.880648+00
162	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:50:59.985843+00
163	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:50:59.98788+00
164	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:50:59.999034+00
165	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:51:00.120913+00
166	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:56:17.383181+00
167	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:56:17.432093+00
168	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:59:47.653718+00
169	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:59:47.653681+00
170	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:05.955752+00
171	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:05.921253+00
172	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:05.954895+00
173	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:06.065923+00
174	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:06.444818+00
175	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:06.453515+00
176	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:15:39.585271+00
177	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:15:39.587983+00
178	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:15:39.588973+00
179	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:15:39.620474+00
180	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:18:28.745202+00
181	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:18:28.745132+00
182	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:19:36.407319+00
183	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:19:36.407178+00
184	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:20:06.050643+00
185	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:20:06.048656+00
186	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:35:15.772839+00
187	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:35:15.881005+00
188	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:35:59.034122+00
189	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:35:59.034139+00
190	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:47:22.431441+00
191	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:47:22.437227+00
192	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:47:22.431978+00
193	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:47:22.4305+00
194	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:58:03.37665+00
195	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:58:03.378133+00
196	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:58:05.638236+00
197	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:58:05.639693+00
198	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:03:40.437637+00
199	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:03:40.441671+00
200	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:04:51.825173+00
201	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:04:51.8311+00
202	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:10:18.91557+00
203	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:10:18.91465+00
204	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:10:18.937711+00
205	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:02.27628+00
206	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:02.276246+00
207	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:02.283611+00
208	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:04.448107+00
209	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:04.449244+00
210	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:04.453945+00
211	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:16.223124+00
212	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:16.226922+00
213	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:16.232989+00
214	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:14:49.412943+00
215	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:14:49.408793+00
216	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:14:49.414404+00
217	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:11.619778+00
218	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:11.617817+00
219	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:11.619816+00
220	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:13.03347+00
221	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:13.034092+00
222	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:13.027127+00
223	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:00:37.135053+00
224	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:00:37.143299+00
225	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:00:37.15143+00
226	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:05:24.133896+00
227	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:05:24.14242+00
228	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:05:24.145943+00
229	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:06:49.30706+00
230	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:06:49.320056+00
231	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:13:36.668665+00
232	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:13:36.667796+00
233	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:13:36.713498+00
234	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:19:29.479394+00
235	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:19:29.505554+00
236	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:21:50.199438+00
237	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:21:50.199018+00
238	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:21:50.220763+00
239	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:28:20.304479+00
240	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:28:20.304577+00
241	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:28:20.311066+00
242	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:30:42.238984+00
243	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:30:42.240149+00
244	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:30:58.923075+00
245	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:30:58.920266+00
246	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:42:41.630878+00
247	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:42:41.704641+00
248	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:43:37.146151+00
249	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:43:37.145228+00
250	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:56:19.768722+00
251	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 07:56:19.810385+00
252	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:07:21.883993+00
253	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:07:21.933278+00
254	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:17:03.098789+00
255	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:17:03.114029+00
256	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:17:03.106606+00
257	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:19.174449+00
258	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:19.171659+00
259	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:49.41757+00
260	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:49.422896+00
261	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:25:23.076962+00
262	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:25:23.121232+00
263	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:27:46.754564+00
264	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:27:46.78248+00
265	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:29:22.096513+00
266	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:29:22.100358+00
267	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:30:50.046803+00
268	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:30:50.068129+00
269	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:34:13.289563+00
270	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:34:13.304083+00
271	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:41:56.454408+00
272	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:41:56.485831+00
273	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:45:32.893516+00
274	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:45:32.937353+00
275	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:45:32.978011+00
276	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:52:25.920888+00
277	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:52:25.935222+00
278	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:59:15.933183+00
279	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:59:15.979113+00
280	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 09:00:41.393886+00
281	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 09:00:41.411442+00
282	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 09:00:41.425658+00
283	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 09:29:34.615218+00
284	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 09:29:34.613273+00
285	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:46:05.479074+00
286	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:46:05.483527+00
287	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:46:05.483386+00
288	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:49:34.558678+00
289	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:49:34.563608+00
290	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:49:34.573022+00
291	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:12:10.697952+00
292	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:12:10.696375+00
293	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:12:10.701402+00
294	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:29:34.617688+00
295	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:29:34.62596+00
296	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:29:35.857928+00
297	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:48:54.575768+00
298	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:48:54.570169+00
299	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 02:48:54.604479+00
300	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:10:13.803892+00
301	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:10:13.803884+00
302	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:10:13.803842+00
303	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:51:43.220795+00
304	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:51:43.218962+00
305	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:51:43.22358+00
306	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-12 03:16:35.605699+00
307	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:16:06.054785+00
308	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:35.5688+00
309	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:35.598442+00
310	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:48.043755+00
311	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:48.053622+00
312	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:48.066178+00
313	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:50.890159+00
314	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:50.896938+00
315	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:23:50.907945+00
316	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-13 02:24:46.098563+00
317	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:38:48.147345+00
318	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:38:48.201751+00
319	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:38:48.217194+00
320	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:39:08.63772+00
321	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:39:08.64653+00
322	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:39:08.739568+00
323	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:45:50.893318+00
324	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:45:50.894439+00
325	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:45:50.893318+00
326	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:51:05.859173+00
327	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:51:05.858343+00
328	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:51:05.977887+00
329	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:51:21.046962+00
330	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:51:21.041658+00
331	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 02:51:21.060059+00
332	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	create	project	85eaf07b-2298-4658-baaa-a5e267c74812	{"project_name": "Enterprise Data Governance Implementation", "customer_name": "ABC Bank"}	\N	\N	2026-05-13 02:54:35.239403+00
333	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 03:59:38.513805+00
334	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 03:59:38.519813+00
335	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 05:59:10.572631+00
336	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 05:59:10.571627+00
337	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:02:02.517838+00
338	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:02:02.554044+00
339	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:02:02.649749+00
340	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:06:50.840986+00
341	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:06:50.87571+00
342	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:06:50.866591+00
343	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-13 06:07:01.089861+00
344	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-13 06:07:05.136783+00
345	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:09:13.398604+00
346	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:09:13.405763+00
347	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:09:13.409971+00
348	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-13 06:10:42.310928+00
349	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:13:39.20903+00
350	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:13:39.205555+00
351	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:13:39.242935+00
352	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:20:02.879555+00
353	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:20:02.903482+00
354	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:20:02.918118+00
355	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:26:12.692174+00
356	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:26:12.695206+00
357	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:19.468722+00
358	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:19.472413+00
359	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:21.960759+00
360	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:21.960736+00
361	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:43:21.142331+00
362	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:43:21.185333+00
363	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:43:55.923322+00
364	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:44:10.400166+00
365	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:44:12.787089+00
366	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:44:21.813023+00
367	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.112371+00
368	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.121375+00
369	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.152136+00
370	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.173552+00
371	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:23:03.576532+00
372	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:23:03.630949+00
373	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:25:18.437363+00
374	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:25:18.439456+00
375	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:27:49.097426+00
376	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:27:49.106169+00
377	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.58513+00
378	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.585664+00
379	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.585706+00
380	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.586318+00
381	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:52.95603+00
382	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:52.977032+00
383	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:59:54.623544+00
384	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:08:11.562796+00
385	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:08:11.642187+00
386	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:17:01.544457+00
387	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:17:01.556002+00
388	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:17:01.579223+00
389	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:18:04.269972+00
390	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:18:04.304313+00
391	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:18:04.331979+00
392	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:20:34.374777+00
393	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:20:34.390558+00
394	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:20:34.384531+00
395	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:23:55.591894+00
396	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:23:55.643203+00
397	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:23:55.679501+00
398	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:29:33.794559+00
399	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:29:33.945179+00
400	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:29:33.955403+00
401	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:36:02.401226+00
402	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:36:02.40641+00
403	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:36:02.371069+00
404	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:45:51.4567+00
405	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:45:51.493157+00
406	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:45:51.499001+00
407	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:55:45.335531+00
408	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:55:45.371977+00
409	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 08:55:45.423286+00
410	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:02:20.315029+00
411	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:02:20.317236+00
412	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:02:20.315827+00
413	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:06:00.411685+00
414	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:06:00.467259+00
415	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:08:23.52308+00
416	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:08:23.546435+00
417	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:08:23.563959+00
418	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:01.859547+00
419	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:01.934284+00
420	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:01.935447+00
421	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:22.975435+00
422	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:23.006292+00
423	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:23.020017+00
424	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:24:32.276353+00
425	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:24:32.344651+00
426	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:24:32.368943+00
427	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:08.14864+00
428	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:08.148414+00
429	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:08.213956+00
430	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:11.353962+00
431	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:11.353804+00
432	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:11.384058+00
433	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:36:32.200125+00
434	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:36:32.201513+00
435	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:36:32.205598+00
436	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:41:32.151013+00
437	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:41:32.280039+00
438	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:41:32.322303+00
439	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:44:49.471481+00
440	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:44:49.453362+00
441	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:44:49.46176+00
442	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:46:40.913086+00
443	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:46:52.214563+00
444	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:46:52.214408+00
445	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:33.18207+00
446	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:33.358089+00
447	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:56.221216+00
448	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:57.225357+00
449	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:57.272401+00
450	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:40:19.443935+00
451	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:40:19.511129+00
452	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:40:19.500405+00
453	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.803624+00
454	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.832485+00
455	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.80224+00
456	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.981651+00
457	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:58:04.810225+00
458	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:58:04.835631+00
459	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:00:20.485411+00
460	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:00:20.502589+00
461	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:00:20.508652+00
462	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:04:16.535209+00
463	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:04:16.537485+00
464	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:04:16.566148+00
465	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:19.933054+00
466	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:19.941414+00
467	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:19.951992+00
468	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:30.379231+00
469	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:30.380909+00
470	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:30.387076+00
471	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:45.508507+00
472	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:45.506875+00
473	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:45.510127+00
474	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:20:45.675326+00
475	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:20:45.767195+00
476	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:20:45.777096+00
477	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:21:21.758586+00
478	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:21:21.760307+00
479	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:21:22.001308+00
480	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:25:51.220679+00
481	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:25:51.225814+00
482	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:25:51.207832+00
483	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:37:05.222845+00
484	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:37:05.270138+00
485	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:37:05.277373+00
486	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:37:42.851413+00
487	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:37:42.815535+00
488	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:37:42.831489+00
489	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:40:26.830955+00
490	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:40:26.831154+00
491	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:40:26.836595+00
492	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:47:37.72451+00
493	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:47:37.733837+00
494	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:47:37.731886+00
495	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:47:49.96116+00
496	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:47:49.967304+00
497	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:47:49.957236+00
498	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:48:10.365906+00
499	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:48:10.356489+00
500	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:48:10.360505+00
501	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:50:13.56927+00
502	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:50:13.574809+00
503	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:50:13.638295+00
504	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:29.953656+00
505	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:30.019779+00
506	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:30.080578+00
507	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:43.022861+00
508	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:43.036725+00
509	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:43.031985+00
510	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:55:01.830073+00
511	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:55:01.831015+00
512	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:55:01.833677+00
513	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:17.849856+00
514	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:17.850904+00
515	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:17.853754+00
516	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:31.452778+00
517	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:31.46202+00
518	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:31.485181+00
519	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:05:10.818537+00
520	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:05:10.807408+00
521	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:05:10.828653+00
522	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:10:40.234461+00
523	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:10:40.237173+00
524	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:10:40.258693+00
525	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:13:57.827552+00
526	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:13:57.830226+00
527	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:13:57.897347+00
528	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:14:13.663097+00
529	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:14:13.665277+00
530	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:14:13.810882+00
531	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:29:18.82616+00
532	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:33:11.961463+00
533	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:33:11.932906+00
534	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:33:11.974242+00
535	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:52.156883+00
536	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:52.172612+00
537	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:58.765076+00
538	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:58.763332+00
539	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:58:09.33479+00
540	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:58:23.335334+00
541	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:58:23.343157+00
542	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	create	dpia	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	\N	\N	\N	2026-05-15 03:59:20.637026+00
543	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:34:21.014774+00
544	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:34:21.077873+00
545	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:03.587459+00
546	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:03.587277+00
547	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:11.142018+00
548	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:11.151965+00
549	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:16.699502+00
550	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:16.82137+00
551	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:25.14148+00
552	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:25.144728+00
553	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:43:21.264449+00
554	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:43:21.288402+00
555	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:54:13.912388+00
556	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:54:13.928403+00
557	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:07:11.453643+00
558	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:07:11.485309+00
559	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:12:04.69156+00
560	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:12:04.696259+00
561	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:18:30.122676+00
562	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:18:30.23884+00
563	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:18:30.237512+00
564	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:02.601927+00
565	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:02.611202+00
566	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:02.565727+00
567	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:09.074313+00
568	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:09.074937+00
569	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:09.285891+00
570	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:23.19153+00
571	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:23.195606+00
572	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:34:35.260847+00
573	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:34:35.314647+00
574	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:34:35.338334+00
575	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:40:10.898853+00
576	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:40:10.948722+00
577	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:40:10.960829+00
578	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:49:36.544966+00
579	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:49:36.54311+00
580	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:49:36.546519+00
581	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:51:15.853455+00
582	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:51:15.861467+00
583	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:51:15.885761+00
584	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:57:47.954285+00
585	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:57:48.011084+00
586	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:57:47.997924+00
587	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 06:57:56.240809+00
588	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:09.975705+00
589	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:09.977572+00
590	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:09.981217+00
591	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:12.201132+00
592	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:12.206622+00
593	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:12.208649+00
594	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	\N	\N	\N	2026-05-15 06:58:23.421022+00
595	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:10:09.538822+00
596	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.361396+00
597	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.418165+00
598	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.416712+00
599	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.393989+00
600	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.665728+00
601	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:07.79386+00
602	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:07.831995+00
603	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:07.906691+00
604	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:15:47.7349+00
605	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:15:47.739519+00
606	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:15:47.752167+00
607	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:20:06.013683+00
608	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:20:06.061213+00
609	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:20:06.093251+00
610	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:20:45.390059+00
611	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:25:57.948563+00
612	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:25:58.035623+00
613	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:25:58.11072+00
614	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:26:32.401263+00
615	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:27:10.372334+00
616	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:27:27.527062+00
617	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:33:23.761178+00
618	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:33:23.69481+00
619	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:33:23.825318+00
620	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:48:30.847914+00
621	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:49:46.655452+00
622	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:49:46.685206+00
623	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:49:46.703431+00
624	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:51:05.326561+00
625	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:53:47.726963+00
626	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:53:47.757547+00
627	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:53:47.771539+00
628	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:54:15.619312+00
629	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:54:15.614013+00
630	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:54:15.615177+00
631	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:59:46.555592+00
632	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:59:46.745628+00
633	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:59:46.801803+00
634	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:00:25.268044+00
635	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:05:47.981446+00
636	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:05:53.445869+00
637	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:05:53.445814+00
638	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:05:53.447864+00
639	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:10:21.77112+00
640	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:10:21.783223+00
641	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:11:10.71591+00
642	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:11:10.720119+00
643	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:11:10.730363+00
644	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:12:02.922613+00
645	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:12:06.055609+00
646	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:16:11.569869+00
647	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:16:11.571993+00
648	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:16:11.567969+00
649	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:20.924172+00
650	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:20.932056+00
651	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:23.04758+00
652	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:23.049819+00
653	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:33:53.993766+00
654	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:40:17.904721+00
655	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:40:18.055369+00
656	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:40:18.025381+00
657	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:50:51.683195+00
658	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:50:51.681527+00
659	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:50:52.564905+00
660	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:59:02.556699+00
661	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:59:02.558878+00
662	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:59:02.732009+00
663	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:24:39.191987+00
664	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:24:39.188878+00
665	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:27:44.988334+00
666	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:27:45.00531+00
667	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:27:45.032615+00
668	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:34:12.150324+00
669	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:34:12.17896+00
670	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 10:03:19.522151+00
671	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 10:03:19.534983+00
703	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:37.975145+00
704	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:56.845656+00
705	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:56.884161+00
706	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:59.806278+00
707	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:59.814863+00
708	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:20.561258+00
709	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:20.604531+00
710	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:25.305017+00
711	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:25.309881+00
712	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:27.336159+00
713	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:27.336544+00
714	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:39.085435+00
715	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:39.084918+00
716	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:15:12.315825+00
717	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:15:12.317844+00
718	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:20:27.045766+00
719	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:20:27.069739+00
720	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:22:59.421894+00
721	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:22:59.438542+00
722	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:25:13.307605+00
723	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:25:13.311776+00
724	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:28:26.70531+00
725	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:28:26.708255+00
726	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:35:43.566417+00
727	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:35:43.590693+00
728	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:51:07.901824+00
729	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:58:24.955863+00
730	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:58:24.979468+00
731	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:02:41.676962+00
732	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:02:41.737621+00
733	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:05:57.009828+00
734	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:05:57.019659+00
735	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:08:21.829152+00
736	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:08:21.810216+00
737	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:11:57.609944+00
738	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:11:57.613313+00
739	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:12:01.35502+00
740	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:12:01.358052+00
741	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:15:39.426555+00
742	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:17:04.631693+00
743	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:17:04.655769+00
744	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:17:27.794763+00
745	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:22:28.166016+00
746	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:22:28.234047+00
747	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:22:50.82588+00
748	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:00.882522+00
749	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:00.881818+00
750	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:09.128943+00
751	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:09.159255+00
752	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:24:34.736996+00
753	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:24:34.742595+00
754	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:24:47.056132+00
755	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:26:10.57155+00
756	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:26:10.582323+00
757	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:27:37.753923+00
758	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:43.651462+00
759	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:43.722422+00
760	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:45.808545+00
761	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:45.810237+00
762	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:20.780581+00
763	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:20.816382+00
764	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:47.652068+00
765	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:47.69117+00
766	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:42:16.868301+00
767	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:42:43.065955+00
768	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:42:49.549368+00
769	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:42:49.555099+00
770	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:43:25.526332+00
771	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:43:25.685305+00
772	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:59:16.772523+00
773	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:59:16.772543+00
774	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:18:57.222321+00
775	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:18:57.285307+00
776	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:19:00.02677+00
777	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:19:00.033636+00
778	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 05:19:12.420486+00
779	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:10.355095+00
780	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:10.418263+00
781	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:11.51908+00
782	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:11.545156+00
783	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:45:43.131821+00
784	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:45:43.28659+00
785	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:08:38.733215+00
786	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:08:38.765563+00
787	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:09:09.452262+00
788	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:09:09.464884+00
789	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:47:49.083413+00
790	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:47:49.185382+00
791	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:48:26.301579+00
792	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:48:26.417041+00
793	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:54:01.413522+00
794	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:54:01.413618+00
795	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:00:56.655539+00
796	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:00:56.696414+00
797	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:02:51.119591+00
798	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:02:51.132866+00
799	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:18:12.809236+00
800	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:41:17.190087+00
801	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:41:17.025379+00
802	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:47:52.437807+00
803	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:47:52.448604+00
804	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:59:13.508162+00
805	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:59:13.506077+00
806	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:18.147595+00
807	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:18.240085+00
808	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:30.310309+00
809	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:30.31704+00
810	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:13:18.012522+00
811	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:13:18.019559+00
812	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:15:49.226019+00
813	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:15:49.239643+00
814	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:29:29.394456+00
815	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:29:59.225216+00
816	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:30:00.20255+00
817	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:36:00.683362+00
818	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:36:00.753179+00
819	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:36:00.781783+00
820	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:45:25.45977+00
821	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:45:26.545037+00
822	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:45:26.599225+00
823	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:50:57.380239+00
824	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:50:57.43936+00
825	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:51:41.237237+00
826	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:51:41.247757+00
827	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:56:23.945431+00
828	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:56:23.945092+00
829	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:00:25.606518+00
830	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:00:25.60976+00
831	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:04:27.349873+00
832	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:04:27.427048+00
833	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:08:39.754505+00
834	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:08:39.618181+00
835	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:14:04.857565+00
836	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:14:04.986654+00
837	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:20:12.549702+00
838	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:20:12.567611+00
839	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:20:12.573273+00
840	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 09:20:37.555517+00
841	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:21:12.04189+00
842	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:21:12.055067+00
843	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:21:12.057743+00
844	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 09:21:45.966377+00
845	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:36:34.480149+00
846	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:36:34.47969+00
847	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:36:34.493564+00
848	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:39:50.12196+00
849	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:39:50.128919+00
850	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:39:50.134002+00
851	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:54:51.539818+00
852	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:05:10.816637+00
853	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:05:10.84471+00
854	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:05:10.900455+00
855	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:06:27.784081+00
856	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:06:27.783675+00
857	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:06:27.840903+00
858	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:07:04.825004+00
859	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:07:04.836931+00
860	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:07:04.855977+00
861	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:05.384038+00
862	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:05.363956+00
863	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:05.397289+00
864	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:55.359405+00
865	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:55.370492+00
866	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:55.381027+00
867	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:27:13.325699+00
868	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:27:13.325714+00
869	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:27:13.328725+00
870	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	login	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:37:10.091099+00
871	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:38:11.042438+00
872	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:38:11.096113+00
873	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:03.125874+00
874	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:03.54692+00
875	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:03.551861+00
876	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:16.146944+00
877	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:16.155243+00
878	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:16.156332+00
879	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:17.969788+00
880	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:17.968946+00
881	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:17.970121+00
882	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:35.004031+00
883	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:35.004625+00
884	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:35.040837+00
885	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:47.777392+00
886	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:47.782244+00
887	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:47.818782+00
888	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:05:11.940201+00
889	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:05:11.941021+00
890	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:05:11.95678+00
891	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:06:52.047276+00
892	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:20:12.817219+00
893	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:20:12.816806+00
894	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.001715+00
895	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.033387+00
896	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.001543+00
897	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.008814+00
898	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.205454+00
899	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:35:31.694654+00
900	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:35:31.697489+00
901	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:35:31.732925+00
902	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:51:57.675229+00
903	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:51:57.679385+00
904	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:51:57.678748+00
905	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.799622+00
906	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.799693+00
907	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.839364+00
908	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.84056+00
909	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.842511+00
910	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:08:11.68122+00
911	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:08:11.68316+00
912	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:08:11.684484+00
913	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	create	project	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"project_name": "Enterprise Data Integration Platform Implementation", "customer_name": "Astra UD Trucks"}	\N	\N	2026-05-19 03:17:28.948382+00
914	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	create	dsr	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	{"tracking_id": "DSR-2026-0003"}	\N	\N	2026-05-19 03:18:36.664868+00
915	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:21:58.323651+00
916	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update	dsr	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:21:58.359501+00
917	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	submit	dsr	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	{"tracking_id": "DSR-2026-0003"}	\N	\N	2026-05-19 03:22:02.684664+00
918	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:22:11.973526+00
919	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:22:11.974023+00
920	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:24:56.755902+00
921	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:25:08.070386+00
922	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:25:08.701169+00
923	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	\N	\N	\N	2026-05-19 03:30:44.856822+00
924	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	\N	\N	\N	2026-05-19 03:30:46.679624+00
925	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-19 03:31:38.840988+00
926	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-19 03:31:52.565343+00
927	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:31:56.031625+00
928	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:31:56.030194+00
929	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:31:56.046671+00
930	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:47:26.62426+00
931	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:02:31.863298+00
932	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:44.892083+00
933	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:44.916799+00
934	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:44.903496+00
935	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:45.22849+00
936	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.704635+00
937	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.707715+00
938	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.7207+00
939	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.726603+00
940	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.926+00
941	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:35:41.587812+00
942	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:35:41.475689+00
943	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:35:41.712385+00
944	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:09.911162+00
945	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:09.91195+00
946	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:09.949929+00
947	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.68052+00
948	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.665383+00
949	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.664118+00
950	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.810693+00
951	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:17.630101+00
952	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:17.663761+00
953	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:17.646733+00
954	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:16:27.874099+00
955	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:23:04.049715+00
956	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:23:04.019007+00
957	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:32.37202+00
958	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:32.372154+00
959	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:32.514628+00
960	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:59.464459+00
961	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:59.483434+00
962	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:59.567785+00
963	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:02.97237+00
964	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:02.972048+00
965	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:02.969963+00
966	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:05.350182+00
967	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:05.434053+00
968	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:05.360677+00
969	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:08.639177+00
970	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:08.638837+00
971	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:12:45.9234+00
972	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:12:45.921958+00
973	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:12:45.94491+00
974	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:38:26.291943+00
975	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:38:26.768493+00
976	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:38:28.380807+00
977	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:40:01.870709+00
978	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:40:01.899121+00
979	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:40:01.936922+00
980	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"rows": 9, "table": "PRJ018_AI_Analytics.xlsx - AI", "grouping": "Service Prediction"}	\N	\N	2026-05-19 07:42:13.37155+00
981	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:48:50.520254+00
982	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:48:50.511962+00
983	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:48:50.559384+00
984	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:20.440027+00
985	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:20.493753+00
986	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:20.50992+00
987	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:25.456894+00
988	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:25.458732+00
989	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:25.458396+00
990	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:09.724062+00
991	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:09.771009+00
992	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:09.813218+00
993	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:10.442896+00
994	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:10.442923+00
995	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:29.413207+00
996	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:29.418758+00
997	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:29.37963+00
998	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:30.212999+00
999	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:30.220923+00
1000	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:30.24182+00
1001	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:00:39.470091+00
1002	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:00:39.486536+00
1003	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:00:39.511411+00
1004	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:14:13.737245+00
1005	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:20:07.207546+00
1006	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:20:07.277591+00
1007	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:20:07.356589+00
1008	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"stamped": 93}	\N	\N	2026-05-19 08:20:22.786981+00
1009	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:23:53.357781+00
1010	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:23:53.360382+00
1011	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:23:53.361318+00
1012	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:28:06.239996+00
1013	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:28:06.242025+00
1014	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:28:06.254556+00
1015	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:31:05.138471+00
1016	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:31:05.152605+00
1017	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:31:05.19177+00
1018	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:35:29.661861+00
1019	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:35:29.664432+00
1020	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:35:29.910804+00
1021	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:38:19.026869+00
1022	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:38:19.08665+00
1023	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:38:19.097763+00
1024	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:50.669706+00
1025	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:50.75242+00
1026	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:50.773322+00
1027	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:51.084256+00
1028	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.913805+00
1029	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.913836+00
1030	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.939363+00
1031	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.955064+00
1032	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:17.580692+00
1033	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:17.580618+00
1034	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:17.542781+00
1035	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:19.333431+00
1036	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.209157+00
1037	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.208217+00
1038	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.2402+00
1039	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.261543+00
1040	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.404599+00
1041	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.437486+00
1042	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.457559+00
1043	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.474983+00
1044	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.364663+00
1045	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.504883+00
1046	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.545812+00
1047	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.589231+00
1048	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.568383+00
1049	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.568306+00
1050	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.693996+00
1051	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.714654+00
1052	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.612536+00
1053	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.656564+00
1054	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.710115+00
1055	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.657583+00
1056	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.632692+00
1057	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.679696+00
1058	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.692+00
1059	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.69768+00
1060	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.154982+00
1061	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.205637+00
1062	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.143066+00
1063	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.184173+00
1064	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.027252+00
1065	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.028912+00
1066	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.039157+00
1067	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.060018+00
1068	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.328234+00
1069	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.387838+00
1070	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.406955+00
1071	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.416402+00
1072	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.724297+00
1073	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.720288+00
1074	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.729437+00
1075	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.730914+00
1076	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.178855+00
1077	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.220973+00
1078	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.234238+00
1079	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.234272+00
1080	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.640598+00
1081	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.645701+00
1082	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.673015+00
1083	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.69166+00
1084	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 22, "table": "car_stock_data.xlsx - Sheet1", "grouping": "Stock"}	\N	\N	2026-05-19 09:20:35.850039+00
1085	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 23, "table": "car_sales_data.xlsx - Sheet1", "grouping": "Sales"}	\N	\N	2026-05-19 09:20:48.174016+00
1086	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 24, "table": "car_demand_data.xlsx - Sheet1", "grouping": "Demand"}	\N	\N	2026-05-19 09:21:03.495599+00
1087	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 24, "table": "customer_data.xlsx - Sheet1", "grouping": "Customer"}	\N	\N	2026-05-19 09:21:16.860472+00
1088	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:53.99545+00
1089	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:54.03256+00
1090	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:54.045418+00
1091	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:54.041573+00
1092	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:48.633909+00
1093	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:48.879408+00
1094	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:49.003448+00
1095	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:49.766761+00
1096	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.559174+00
1097	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.558788+00
1098	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.62976+00
1099	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.588839+00
1100	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.377302+00
1101	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.494846+00
1102	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.510778+00
1103	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.511647+00
1104	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.905651+00
1105	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.912603+00
1106	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.907634+00
1107	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.91358+00
1108	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:30.834685+00
1109	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:30.830977+00
1110	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:30.831989+00
1111	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:31.204281+00
1112	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.637584+00
1113	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.656274+00
1114	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.672115+00
1115	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.991538+00
1116	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:51.894223+00
1117	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:52.037728+00
1118	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:52.056364+00
1119	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:52.0598+00
1120	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"stamped": 27}	\N	\N	2026-05-19 11:11:45.422894+00
1121	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:22:08.73785+00
1122	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:30:33.54679+00
1123	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:30:33.646916+00
1124	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:30:33.551775+00
1125	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-19 11:32:02.437138+00
1126	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-19 11:33:10.528474+00
1127	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:45:37.87583+00
1128	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	\N	\N	\N	2026-05-19 11:45:37.951671+00
1129	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-19 11:46:11.92494+00
1130	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:54:14.287379+00
1131	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:54:14.289608+00
1132	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	\N	\N	\N	2026-05-19 11:54:34.72532+00
1133	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:09:18.083568+00
1134	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:58.944002+00
1135	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:58.944002+00
1136	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:58.915402+00
1137	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:59.003307+00
1138	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	{"stamped": 33}	\N	\N	2026-05-19 12:20:56.823321+00
1139	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-19 12:21:20.277543+00
1140	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.169794+00
1141	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.571852+00
1142	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.306733+00
1143	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.350894+00
1144	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.750918+00
1145	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.820055+00
1146	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.836257+00
1147	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.843492+00
1148	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.418506+00
1149	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.449082+00
1150	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.489503+00
1151	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.494639+00
1152	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 05:14:48.983964+00
1153	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 05:15:33.71043+00
1154	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/148.0.0.0 Safari/537.36	2026-05-20 05:16:17.257747+00
1155	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/148.0.0.0 Safari/537.36	2026-05-20 05:16:51.328162+00
1156	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 06:22:57.608503+00
1157	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	batch_save	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"saved": 1, "errors": 0}	\N	\N	2026-05-20 06:27:28.637627+00
1158	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 06:27:51.092904+00
1159	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 06:27:51.119089+00
1160	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 06:27:51.184486+00
1161	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 06:27:51.212991+00
1162	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 06:53:20.711024+00
1163	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:24:00.620773+00
1164	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	create	project	347eb32e-4b25-4290-a1b6-f793b608c929	{"project_name": "Customer 360 Analytics and Personalization Platform", "customer_name": "Astra International – Digital Transformation Division"}	\N	\N	2026-05-20 07:29:07.49258+00
1165	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:29:24.104103+00
1166	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:29:24.225023+00
1167	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:29:26.402965+00
1168	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:29:27.544048+00
1169	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:30:57.125431+00
1170	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 07:32:10.391452+00
1171	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:32:28.669049+00
1172	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:32:28.773691+00
1173	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:32:28.803285+00
1174	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:32:28.81886+00
1175	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 07:33:01.231304+00
1176	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	create	dsr	f0a3e2af-135d-4048-86e4-44ac5457a8ee	{"tracking_id": "DSR-2026-0004"}	\N	\N	2026-05-20 07:36:58.876075+00
1177	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:50:08.166213+00
1178	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:50:08.220387+00
1179	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:50:09.760185+00
1180	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:53:37.635236+00
1181	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	62139d71-4a07-4644-8e49-0129838363c5	\N	\N	\N	2026-05-20 07:54:02.947798+00
1182	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:54:18.57772+00
1183	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:54:41.278949+00
1184	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	62139d71-4a07-4644-8e49-0129838363c5	\N	\N	\N	2026-05-20 07:55:00.617333+00
1185	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:55:07.838683+00
1186	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:55:24.986094+00
1187	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:55:29.575505+00
1188	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:55:33.322782+00
1189	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:55:46.172417+00
1190	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:56:09.648672+00
1191	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:56:32.708408+00
1192	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 07:56:57.101204+00
1193	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	62139d71-4a07-4644-8e49-0129838363c5	\N	\N	\N	2026-05-20 07:57:42.928396+00
1194	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:13.046657+00
1195	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:13.156714+00
1196	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:20.75885+00
1197	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:01:43.075383+00
1198	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:23.697885+00
1199	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:36.541865+00
1200	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:36.599441+00
1201	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 08:02:47.255545+00
1202	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:49.145281+00
1203	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:49.173449+00
1204	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:49.288498+00
1205	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:49.330363+00
1206	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:02:49.445581+00
1207	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:10.627581+00
1208	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:10.634648+00
1209	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:10.665981+00
1210	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:10.690335+00
1211	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:10.762022+00
1212	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:14.236564+00
1213	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:14.321369+00
1214	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:17.686457+00
1215	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:17.747419+00
1216	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:17.80854+00
1217	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:21.559379+00
1218	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:21.549206+00
1219	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.203	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:03:21.677485+00
1220	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:03:44.588305+00
1221	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:04:15.597478+00
1222	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 08:04:30.69005+00
1223	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:05:19.775584+00
1224	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:06:24.127874+00
1225	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:07:14.413094+00
1226	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:08:01.23903+00
1227	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:11:03.053693+00
1228	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:11:03.122161+00
1229	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 08:17:43.757106+00
1230	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:17:48.15918+00
1231	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:19:42.016683+00
1232	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:23:44.105411+00
1233	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:23:44.314558+00
1234	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 08:39:30.991458+00
1235	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": false, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": false}	\N	\N	2026-05-20 08:39:36.708303+00
1236	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8457	2026-05-20 08:44:03.467858+00
1237	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": false, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": false}	\N	\N	2026-05-20 08:44:15.036705+00
1238	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:44:45.600432+00
1239	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:44:45.98899+00
1240	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:45:31.235758+00
1241	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:45:46.444578+00
1242	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:45:47.536038+00
1243	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": false, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": false}	\N	\N	2026-05-20 08:45:57.615586+00
1244	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:46:36.672833+00
1245	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": false, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": false}	\N	\N	2026-05-20 08:46:54.193645+00
1246	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:47:36.432035+00
1247	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": false, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": false}	\N	\N	2026-05-20 08:47:53.813732+00
1248	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 08:48:52.430986+00
1249	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:50:16.222816+00
1250	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:50:16.266482+00
1251	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": false, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": true}	\N	\N	2026-05-20 08:51:02.044132+00
1252	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	settings	update_ai_settings	ai_provider_config	5c33fe93-c2df-4458-ba47-2d921f7a3d8a	{"mode": "cloud", "enabled": true, "base_url": "https://ollama.com", "provider": "ollama", "model_name": "gpt-oss:120b", "api_key_configured": true}	\N	\N	2026-05-20 08:51:44.543312+00
1253	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:53:34.370544+00
1254	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:53:34.56758+00
1255	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 08:53:34.680968+00
1256	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 08:54:11.285714+00
1257	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 08:55:51.196723+00
1258	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:31:19.76765+00
1259	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:31:33.352976+00
1260	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:31:33.432471+00
1261	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:31:33.469091+00
1262	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:32:20.518559+00
1263	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:32:31.890541+00
1264	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:32:31.979558+00
1265	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/147.0.7727.15 Safari/537.36	2026-05-20 09:32:38.079138+00
1266	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 09:32:54.381673+00
1267	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:22.607585+00
1268	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:22.6458+00
1269	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:22.790159+00
1270	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:22.806973+00
1271	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:31.744967+00
1272	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:32.815814+00
1273	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:35:33.989988+00
1274	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	\N	\N	\N	2026-05-20 09:40:41.557752+00
1275	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	regenerate_ai_definition	metadata_record	526511ec-7991-4314-8685-6c8bf13d098c	{"provider": "ollama", "model_name": "gpt-oss:120b"}	\N	\N	2026-05-20 09:41:40.294158+00
1276	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	regenerate_all_ai_definitions	project	347eb32e-4b25-4290-a1b6-f793b608c929	{"failed": 0, "provider": "ollama", "processed": 5, "model_name": "gpt-oss:120b"}	\N	\N	2026-05-20 09:44:56.854693+00
1277	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	regenerate_all_ai_definitions	project	347eb32e-4b25-4290-a1b6-f793b608c929	{"failed": 0, "provider": "ollama", "processed": 5, "model_name": "gpt-oss:120b"}	\N	\N	2026-05-20 09:45:27.167191+00
1278	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	{"stamped": 18}	\N	\N	2026-05-20 09:46:00.014267+00
1279	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	347eb32e-4b25-4290-a1b6-f793b608c929	{"stamped": 18}	\N	\N	2026-05-20 09:46:17.181094+00
1280	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	regenerate_all_ai_definitions	project	347eb32e-4b25-4290-a1b6-f793b608c929	{"failed": 0, "provider": "ollama", "processed": 5, "model_name": "gpt-oss:120b"}	\N	\N	2026-05-20 09:45:58.431449+00
1281	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	regenerate_all_ai_definitions	project	347eb32e-4b25-4290-a1b6-f793b608c929	{"failed": 0, "provider": "ollama", "processed": 2, "model_name": "gpt-oss:120b"}	\N	\N	2026-05-20 09:46:34.861632+00
1282	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:51:08.5935+00
1283	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 09:51:08.642684+00
1284	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:03:24.209027+00
1285	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:03:25.380495+00
1286	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:18:55.001709+00
1287	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:18:55.048579+00
1288	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:18:55.12369+00
1289	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:18:55.158662+00
1290	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:18:55.164286+00
1291	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:25:33.4336+00
1292	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 10:25:33.43097+00
1293	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-20 10:26:29.663765+00
1294	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 15:34:00.092417+00
1295	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 15:34:00.155657+00
1296	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-20 15:40:13.556543+00
1297	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-20 15:40:13.703716+00
1298	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-20 15:40:13.777114+00
1299	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-20 15:40:13.797722+00
1300	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:09.623297+00
1301	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:10.779774+00
1302	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:11.404513+00
1303	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:11.538593+00
1304	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:31.209917+00
1305	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:33.589491+00
1306	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.121.133.165	Mozilla/5.0 (iPhone; CPU iPhone OS 18_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.7.2 Mobile/15E148 Safari/604.1	2026-05-20 22:00:39.06647+00
1307	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 03:23:07.663019+00
1308	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 03:23:08.805088+00
1309	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 03:26:11.886153+00
1310	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 03:51:23.295075+00
1311	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 03:51:24.425565+00
1312	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 03:51:25.556876+00
1313	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 04:20:45.357026+00
1314	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 04:20:46.53603+00
1315	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	202.65.236.121	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0	2026-05-21 04:20:47.637846+00
1316	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:28:26.985659+00
1317	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:28:28.133911+00
1318	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	create	dsr	1ecb4c17-aca7-4159-b8aa-66dc208bd415	{"tracking_id": "DSR-2026-0005"}	\N	\N	2026-05-21 07:39:36.205195+00
1319	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:43:44.278579+00
1320	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	regenerate_ai_definition	metadata_record	526511ec-7991-4314-8685-6c8bf13d098c	{"provider": "ollama", "model_name": "gpt-oss:120b"}	\N	\N	2026-05-21 07:48:03.285125+00
1321	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:57:29.006842+00
1322	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:57:30.079903+00
1323	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:25:45.951344+00
1324	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:25:47.05829+00
1325	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:25:48.124929+00
1326	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:51:15.666239+00
1327	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:51:16.719436+00
1328	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:51:17.891953+00
1329	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:51:18.941585+00
1330	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:17:54.288228+00
1331	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:17:55.365281+00
1332	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:17:56.432235+00
1333	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.85.114	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:17:57.533287+00
1334	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 03:39:31.805314+00
1335	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 03:39:32.954739+00
1336	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 03:39:44.514242+00
1337	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 03:39:44.675334+00
1338	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	103.86.154.205	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 03:40:00.424365+00
1339	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	182.0.210.173	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 04:30:56.136893+00
1340	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	182.0.210.173	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 04:30:56.579701+00
1341	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	182.0.207.132	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 06:15:21.331898+00
1342	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	182.0.207.132	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 06:15:22.443195+00
1343	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	203.17.87.40	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-28 03:48:53.541619+00
\.


--
-- Data for Name: bapd_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bapd_approvals (id, bapd_id, approver_id, approver_role, step_order, status, comments, actioned_at) FROM stdin;

\.


--
-- Data for Name: bapd_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bapd_records (id, project_id, dataset_name, dataset_location, retention_policy_id, expiry_date, reason, responsible_party_id, status, pod_file_path, executed_at, executed_by, version, created_by, created_at, updated_at) FROM stdin;

\.


--
-- Data for Name: data_owner_stewards; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_owner_stewards (id, project_id, role_type, full_name, email, created_at) FROM stdin;
0103817a-b73f-4e1a-b76f-97a1ea7e9d43	85eaf07b-2298-4658-baaa-a5e267c74812	lead_business_steward	Ryan Foster	ryan.foster23@example.com	2026-05-19 11:46:11.958668+00
44e3fffb-26e0-4011-b340-c1868051212a	5288642d-13e8-45b3-8f77-bcbff82a42c5	lead_business_steward	Daniel Carter	daniel.carter84@example.com	2026-05-19 11:33:10.562223+00
5fa1f196-190b-4c8d-bbe7-0a975ecbba44	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	data_owner	Chloe Mitchell	chloe.mitchell88@example.com	2026-05-19 11:45:38.096383+00
7b55f63b-efd5-4594-9c65-baf82d713c71	85eaf07b-2298-4658-baaa-a5e267c74812	data_owner	Amelia Brooks	amelia.brooks74@example.com	2026-05-19 11:46:11.990144+00
941c54fc-c2dd-4095-bffd-41585bf41c1f	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	lead_business_steward	Michael Turner	michael.turner56@example.com	2026-05-19 11:45:38.055045+00
a4f55367-ead5-4af5-b562-d68656cc2d40	347eb32e-4b25-4290-a1b6-f793b608c929	data_owner	Rina Maharani Putri	rina.putri@astra-group.co.id	2026-05-20 07:33:20.014148+00
b2080696-803e-4e43-93e7-6f88e3a4cb87	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	data_owner	Sophia Bennett	sophia.bennett17@example.com	2026-05-19 11:32:02.900517+00
e3006601-f6ba-430d-a929-cb201e3140b6	5288642d-13e8-45b3-8f77-bcbff82a42c5	data_owner	Olivia Hayes	olivia.hayes31@example.com	2026-05-19 11:33:10.666727+00
ec4b6e73-ab39-4513-8e91-432afaee3ad2	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	lead_business_steward	Ethan Walker	ethan.walker92@example.com	2026-05-19 11:32:02.713296+00
ed8d6847-fa2c-4c2e-9d67-c793012f89c9	347eb32e-4b25-4290-a1b6-f793b608c929	lead_business_steward	Andika Pratama Wijaya	andika.wijaya@astra-group.co.id	2026-05-20 07:32:20.242562+00
\.


--
-- Data for Name: data_sharing_agreements; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_sharing_agreements (id, title, file_path, validity_start, validity_end, created_at) FROM stdin;

\.


--
-- Data for Name: data_sharing_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_sharing_requests (id, tracking_id, project_id, requester_id, dataset_name, recipient, purpose, is_ai_use, duration_start, duration_end, dsa_id, status, created_at, updated_at) FROM stdin;
062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	DSR-2026-0003	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	DMS After Sales & Service Integration Dataset	Astra UD Trucks	Data sharing is required to support enterprise reporting, operational monitoring, and centralized analytics initiatives across after sales and service operations. The dataset will be used for integration into the corporate analytics platform to improve service performance visibility, billing reconciliation, inventory monitoring, and customer service reporting consistency across dealer networks.	t	2026-03-03	2026-10-28	\N	submitted	2026-05-19 03:18:36.664868+00	2026-05-19 03:22:02.684664+00
1ecb4c17-aca7-4159-b8aa-66dc208bd415	DSR-2026-0005	85eaf07b-2298-4658-baaa-a5e267c74812	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	AI	PT ABC Tbk	Abcd	t	2026-05-01	2026-10-31	\N	draft	2026-05-21 07:39:36.205195+00	2026-05-21 07:39:36.205195+00
4a6f596c-dcef-437c-bfa1-c777e0db5e6c	DSR-2026-0001	5288642d-13e8-45b3-8f77-bcbff82a42c5	9af488f8-db30-4b90-a672-c1ec50f45c85	Customer Transaction Dataset Q1-2026	PT Maju Bersama Digital	To train and validate AI-powered analytics models using customer transaction data for personalised financial insight generation, customer behaviour segmentation, and predictive modelling in support of the AI-Powered Customer Analytics Platform initiative.	t	2026-02-01	2026-12-31	\N	approved	2026-01-10 09:00:00+00	2026-01-25 11:45:00+00
5f8cf746-6035-447a-9cfa-3694bd423aaa	DSR-2026-0002	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	Customer Credit Data	PT Finansial Nusantara	To develop and train a credit risk scoring model leveraging customer transaction history, financial behaviour patterns, and credit bureau data, aimed at improving loan approval accuracy and reducing default rates for PT Finansial Nusantara's retail banking portfolio under the Smart Credit Risk Analytics Platform initiative.	t	2026-03-01	2026-12-31	\N	under_review	2026-05-07 03:02:08.540473+00	2026-05-07 03:02:08.540473+00
f0a3e2af-135d-4048-86e4-44ac5457a8ee	DSR-2026-0004	347eb32e-4b25-4290-a1b6-f793b608c929	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	Customer 360 Integrated Analytics Dataset	Astra International – Digital Transformation Division	Data sharing is required to support the development of a Customer 360 analytics platform that integrates customer data from multiple sources, including sales transactions, after-sales services, and digital interaction channels. The dataset will be used to enable AI/ML-driven use cases such as customer segmentation, behavior prediction, and personalized recommendations to enhance customer engagement and business decision-making. All data processing will be conducted within a secure environment with appropriate safeguards, including pseudonymization, access control, and compliance with applicable data protection regulations.	t	2026-02-15	2026-11-30	\N	draft	2026-05-20 07:36:58.876075+00	2026-05-20 07:36:58.876075+00
\.


--
-- Data for Name: dpia_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dpia_approvals (id, dpia_id, approver_id, approver_role, step_order, status, comments, actioned_at) FROM stdin;
541a33b9-3cfe-494c-b093-81eace455b95	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
5ed159a8-f75b-4f40-9684-831d5cfd3357	29815390-7d93-4db3-a89d-b7722ffeacfd	19d275fc-8c44-4411-a412-92a85834759b	pic_compliance	1	pending	\N	\N
722bd2f1-9158-44c5-a14d-a8b08130874b	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	336b5420-9af0-49de-b844-e42ee6658cd4	pic_compliance	1	requested	\N	\N
7571909a-35ea-4733-a9c0-199e0cc7e794	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	requested	\N	\N
973587a9-afce-4a07-8f4c-4166ef1fe7e2	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	pending	\N	\N
9850336c-7db8-402e-8694-fc2ec42c3d04	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	pending	\N	\N
d527ee90-4f49-4d84-8fef-f6ef13f371b3	29815390-7d93-4db3-a89d-b7722ffeacfd	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	pending	\N	\N
df534081-26b6-410f-8e94-0abd96e60841	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	pending	\N	\N
eb5d7ad3-698d-4718-a4be-be7a1df56d2f	62139d71-4a07-4644-8e49-0129838363c5	f961edea-0a7a-4f6c-8738-098f640b6dc8	pic_compliance	1	requested	\N	\N
ee2863f3-324a-4160-a86d-1e4e7571f061	62139d71-4a07-4644-8e49-0129838363c5	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
\.


--
-- Data for Name: dpia_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dpia_records (id, project_id, process_name, purpose, data_category, risk_description, mitigation_measures, residual_risk, likelihood_score, impact_score, risk_score, assessment_date, responsible_party_id, status, version, created_by, created_at, updated_at, tracking_id, governance_json) FROM stdin;
01585cf6-32d7-47c8-aaa0-64f46c60d6b2	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	Enterprise Data Integration Platform Implementation		Full Name, Email Address, Phone Number	Unauthorized access to customer personal data during AI processing or analytics may lead to data leakage, identity theft, or financial impact.	Data is pseudonymized before processing. Access is restricted through RBAC. All activities are logged and monitored. AI usage is limited to internal analytics within secured environments compliant with data protection regulations.	Low	\N	\N	\N	2026-05-19	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	submitted	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-19 03:18:36.664868+00	2026-05-19 03:30:46.679624+00	DPIA-2026-0003	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "yes", "remarks": "Data sharing request has been formally documented, including purpose, scope, and data classification", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "yes", "remarks": "Data retention and deletion policy defined; data will be deleted after project end date", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "yes", "remarks": "Data retention and deletion policy defined; data will be deleted after project end date", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "yes", "remarks": "All data processing activities are logged and auditable within secure environments", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "yes", "remarks": "RBAC model is implemented and documented; access restricted to authorized personnel only", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "yes", "remarks": "All documentation has been reviewed and approved by data governance and compliance team", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "yes", "remarks": "Personal data is pseudonymized and masked before usage in AI and analytics processes", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "yes", "remarks": "Metadata documentation has been created for dataset structure, fields, and data lineage", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "yes", "remarks": "Data quality metrics (completeness, consistency, accuracy) are defined and monitored", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "yes", "remarks": "Metadata reviewed and approved by data governance team", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "yes", "remarks": "Data quality framework validated and aligned with enterprise standards", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "yes", "remarks": "Data sharing is conducted within secure enterprise environment with encryption, access control, and monitoring", "responsible": "Client"}]}
29815390-7d93-4db3-a89d-b7722ffeacfd	85eaf07b-2298-4658-baaa-a5e267c74812	Enterprise Data Governance Implementation				\N	\N	\N	\N	\N	2026-05-21	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	draft	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-21 07:39:36.205195+00	2026-05-21 07:39:36.205195+00	DPIA-2026-0005	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "", "remarks": "", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "", "remarks": "", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "", "remarks": "", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "", "remarks": "", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "", "remarks": "", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "", "remarks": "", "responsible": "Client"}]}
62139d71-4a07-4644-8e49-0129838363c5	347eb32e-4b25-4290-a1b6-f793b608c929	Customer 360 Analytics and Personalization Platform		Full Name, Date of Birth, Gender, Nationality, Email Address, Phone Number, Home / Residential Address, Transaction History, Credit Score / Rating, IP Address & Device ID, Browser & App Usage Logs, Online Purchase Behaviour, Click & Interaction Data, Customer Relationship (CRM), Marketing Preferences	Unauthorized access, misuse, or unintended exposure of customer personal data during data integration, processing, or AI/ML model development may lead to privacy breaches such as identity disclosure, profiling risks, or unauthorized targeting. In addition, inaccurate or biased AI model outputs may negatively affect customer experience and decision-making, potentially resulting in reputational impact to the organization.	Data is pseudonymized and masked prior to processing to reduce exposure of personal information. Access to data is strictly controlled through role-based access control (RBAC) and limited to authorized personnel only. All processing activities are conducted within a secure analytics environment equipped with encryption, monitoring, and audit logging. AI/ML models are subject to internal governance processes including validation, testing, and bias checking before deployment. Data usage is aligned with customer consent and applicable data protection regulations.	Low	\N	\N	\N	2026-05-20	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	submitted	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-20 07:36:58.876075+00	2026-05-20 07:57:42.928396+00	DPIA-2026-0004	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "yes", "remarks": "Document completed and approved, including data scope and purpose", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "yes", "remarks": "Data retention and deletion policy defined based on project timeline", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "yes", "remarks": "All activities are logged and auditable", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "yes", "remarks": "RBAC implemented and documented", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "yes", "remarks": "Reviewed and approved by governance/compliance", "responsible": "Internal"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "yes", "remarks": "Access restricted to authorized users only", "responsible": "Internal"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "yes", "remarks": "Data is pseudonymized and sensitive fields are protected using encryption", "responsible": "Internal"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "yes", "remarks": "Data dictionary and lineage documented", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "yes", "remarks": "Data quality metrics established and monitored", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "yes", "remarks": "Reviewed and approved by governance team", "responsible": "Internal"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "yes", "remarks": "Data quality framework validated", "responsible": "Internal"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "yes", "remarks": "Secure enterprise analytics platform with monitoring and access control", "responsible": "Internal"}]}
82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	5288642d-13e8-45b3-8f77-bcbff82a42c5	AI-Powered Customer Analytics Platform		Full Name, Date of Birth, Gender, Email Address, Phone Number, Home / Residential Address, Postal Code, Employee ID, Job Title & Position, IP Address & Device ID	Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm.	Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable.	Low	\N	\N	\N	2026-05-15	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	draft	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-15 03:59:20.637026+00	2026-05-15 06:58:23.421022+00	DPIA-2026-0001	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "", "remarks": "", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "", "remarks": "", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "", "remarks": "", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "", "remarks": "", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "", "remarks": "", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "", "remarks": "", "responsible": "Client"}]}
c19f5d23-f981-46a8-9bb4-c4e9e75056e9	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	Smart Credit Risk Analytics Platform		Full Name, Passport Number, Date of Birth, Gender, Email Address, Phone Number, Postal Code, Home / Residential Address, Employee ID, Job Title & Position, IP Address & Device ID	Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm.	Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable.	Low	\N	\N	\N	2026-05-15	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	submitted	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-15 05:32:44.458131+00	2026-05-15 08:12:06.055609+00	DPIA-2026-0002	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "no", "remarks": "Doesnt need data sharing request", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "yes", "remarks": "need to delete all the document related to project deliverable from the ADI environment", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "yes", "remarks": "Activity logs maintained in centralised audit trail system throughout the project lifecycle.", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "yes", "remarks": "RBAC policy document prepared and approved by DGO. Access limited to 4 authorised team members.", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "yes", "remarks": "PT Finansial Nusantara data governance team reviewed and approved all access documentation on 15 Mar 2026.", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "yes", "remarks": "Access credentials provisioned for approved team members only via secure VPN tunnel.", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "yes", "remarks": "Customer PII fields pseudonymised using SHA-256 hashing prior to transfer. Data encrypted at rest using AES-256.", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "yes", "remarks": "Metadata catalogue created covering 11 data attributes across identity, contact, employment, and digital behaviour categories.", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "yes", "remarks": "DQI measured at 94.2% completeness and 98.7% accuracy across the training dataset. Results reviewed by DQ Officer.", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "yes", "remarks": "PT Finansial Nusantara data team reviewed and approved all metadata definitions on 20 Mar 2026.", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "yes", "remarks": "DQ measurement methodology and index approved by PT Finansial Nusantara on 22 Mar 2026.", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "yes", "remarks": "Dedicated Supabase schema provisioned with row-level security enabled. Access restricted to whitelisted IP ranges only.", "responsible": "Client"}]}
\.


--
-- Data for Name: dq_findings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dq_findings (id, result_id, severity, description, recommendation, status, resolved_by, resolved_at, created_at) FROM stdin;

\.


--
-- Data for Name: dq_gcp_archives; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dq_gcp_archives (id, run_id, gcs_report_path, bq_dataset, bq_table, archived_at, archive_status, error_message) FROM stdin;

\.


--
-- Data for Name: dq_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dq_results (id, run_id, check_name, check_type, column_name, status, expected_value, actual_value, row_count, failed_count, details, created_at, business_rules, regex_pattern, ai_model, regex_version, column_category) FROM stdin;

\.


--
-- Data for Name: dq_runs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dq_runs (id, project_id, run_name, dataset_name, dataset_location, status, total_checks, passed_checks, failed_checks, overall_score, started_at, completed_at, triggered_by, celery_task_id, created_at, source_file_id) FROM stdin;

\.


--
-- Data for Name: dsr_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dsr_approvals (id, dsr_id, approver_id, approver_role, step_order, status, comments, actioned_at) FROM stdin;
124c84f8-e1c9-4ebc-b8fe-408b545df1ed	f0a3e2af-135d-4048-86e4-44ac5457a8ee	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
28340666-50d1-4eb2-9565-f838e2d4523e	5f8cf746-6035-447a-9cfa-3694bd423aaa	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	approved	\N	2026-05-13 07:17:30.076257+00
2b803572-2f69-44bd-9740-a4ad3952070d	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	c8cf883c-330c-46c0-b023-3629c2f99a69	client	4	approved	Approved. Compliance requirements satisfied.	2026-01-25 11:45:00+00
32320d50-06e9-4623-9863-443646e7031e	5f8cf746-6035-447a-9cfa-3694bd423aaa	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	requested	\N	\N
67e2337a-7d67-4cf1-8029-fc877e0ccd9d	1ecb4c17-aca7-4159-b8aa-66dc208bd415	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	pending	\N	\N
74c7b2da-ba23-40d0-b289-727360e6d60f	1ecb4c17-aca7-4159-b8aa-66dc208bd415	19d275fc-8c44-4411-a412-92a85834759b	pic_compliance	1	pending	\N	\N
7b044cd4-556e-4ff1-b032-584c67c66444	f0a3e2af-135d-4048-86e4-44ac5457a8ee	8216e50c-c627-469d-a696-1e91285f5aab	client	4	pending	\N	\N
7b43d4a3-bbf9-4c3b-a3cd-dd86b280fd5e	1ecb4c17-aca7-4159-b8aa-66dc208bd415	9af488f8-db30-4b90-a672-c1ec50f45c85	client	4	pending	\N	\N
8dcf46b9-b3df-48b6-bee8-5656be212034	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	8216e50c-c627-469d-a696-1e91285f5aab	client	4	pending	\N	\N
8e067aee-4fc0-407e-8788-a6c97fc65087	f0a3e2af-135d-4048-86e4-44ac5457a8ee	f961edea-0a7a-4f6c-8738-098f640b6dc8	pic_compliance	1	pending	\N	\N
92413bd4-0d9c-4def-b62d-6a7b3e01f2ea	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
9476693c-346f-4d82-884b-9609a8fef043	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	approved	Reviewed and approved. Governance policies compliant.	2026-01-15 10:30:00+00
aa549bf0-c42d-4823-8bed-696468a7d3cb	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	approved	Reviewed and approved. Data usage aligns with project scope.	2026-01-18 14:15:00+00
ac34646e-f1f8-472d-8d0b-262f488853de	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	336b5420-9af0-49de-b844-e42ee6658cd4	pic_compliance	1	requested	\N	\N
aca8c71e-fb52-4d64-a53e-1180f64153f2	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
b0f7637c-d2aa-4643-ae44-5b39d52749bb	5f8cf746-6035-447a-9cfa-3694bd423aaa	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	approved	\N	2026-05-13 07:17:30.076257+00
b6103583-962e-4446-9013-78eb0b81c65a	1ecb4c17-aca7-4159-b8aa-66dc208bd415	3991d4dd-deb4-432c-9a8a-edee818513b0	sme	3	pending	\N	\N
bd0c01e1-df0e-4221-8ba6-53e16ee214d1	f0a3e2af-135d-4048-86e4-44ac5457a8ee	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
d5d43037-fe5f-4530-ab2c-fc6aa4b1d180	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	approved	Approved. Data is relevant and fit for AI model training.	2026-01-22 09:00:00+00
e3b2747b-0836-42b9-b6b7-1a4240202ec0	5f8cf746-6035-447a-9cfa-3694bd423aaa	c8cf883c-330c-46c0-b023-3629c2f99a69	client	4	pending	\N	\N
\.


--
-- Data for Name: metadata_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.metadata_records (id, project_id, seq_no, business_users, data_domain_table, line_of_business, table_type, project_name, project_year, data_steward, data_owner, data_attribute, data_sensitivity, data_grouping, business_term, business_definition, definition_status, standard_format, is_primary_key, is_nullable, sample_data, data_type, data_level, updated_date, updated_by, remarks, source_type, created_at, source_row_count, data_year, distinct_values) FROM stdin;
00ddc30b-4e0b-40dc-b215-5c31801fd571	5288642d-13e8-45b3-8f77-bcbff82a42c5	68		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			battery_health	Highly Confidential	Stock	Battery Health	Battery health represents a numerical indication of a vehicle' extrinsic energy storage system condition, ranging from optimal (e.g., values near maximum potential) to degraded performance states within the database. In this specific context, it is stored as an integer in the car_stock_data table and reflects one aspect of each recorded automobile's overall readiness for use or maintenance needs.\n\n\nBusiness Definition: The "battery health" column quantifies a vehicle’s battery condition through integers where higher values indicate better performance, directly influencing the necessity for servicing in car dealership inventory management systems to ensure customer satisfaction and fleet efficiency optimization.	ai_generated	\N	f	t	99	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
016a2dba-2f59-4fe8-8bf5-fe93a0b64187	5288642d-13e8-45b3-8f77-bcbff82a42c5	48		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			stock_id	Confidential	Stock	Stock Identifier	The "Stock Identifier" is a VARCHAR data type attribute representing each unique vehicle's identification code within an automotthetic car stock database, serving as a primary key for quick and accurate inventory tracking and management processes. Example values consist of alphanumeric strings such as 'STK00001'.	ai_generated	\N	t	f	STK00001	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
042ac17b-9394-4e66-a208-5f0b1d987592	5288642d-13e8-45b3-8f77-bcbff82a42c5	92		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			loyalty_points	Confidential	Customer	Loyalty Points	Loyalty points represent a numerical value assigned to each customer, quantifying their loyalty status as an integer (INTEGER data type). For example, one might have accumulated 29439 loyalty points after frequent purchases and participation in store events. This metric is used by the business to reward customers for their ongoing patronage and engagement with promotions or exclusive offers based upon point thresholds reached within this customer_data table.	ai_generated	\N	t	f	29439	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
04447fd3-501d-4990-b7d7-b0d8b5a79e4c	5288642d-13e8-45b3-8f77-bcbff82a42c5	70		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_id	Confidential	Customer	Customer Identifier	The 'Customer Identifier' is a unique, non-editable field within customer records that serves as an alphanumeric string (e.g., CUST00001) to differentiate each individual customer for data management and analysis purposes. This identifier must conform to standardized formatting guidelines consistent with the enterprise’s branding and be stored securely, in compliance with relevant privacy regulations like GDPR or CCPA as applicable within their jurisdiction of operation.	ai_generated	\N	t	f	CUST00001	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
053cab9f-1f0c-405e-8eb3-0b0427b68618	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	2	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Customer_ID	Confidential	\N	Customer Identifier	The 'Customer Identifier' is a string data type that uniquely identifies each customer within an organization, serving as their primary key for record differentiation and retrieval purposes; typically formatted like "CUST1000".	ai_generated	Free text	t	t	CUST1000	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
05a42544-e96c-49b7-9e7e-aef24bb1b90e	85eaf07b-2298-4658-baaa-a5e267c74812	5	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	PII_Flag	Confidential	\N	Pii Flag	The "PII Flag" serves as an indicator within a data governance context to swiftly identify rows containing personally identifiable information, thereby requiring additional security measures and compliance with privacy regulations such as GDPR and CCPA; it is represented by a single character string where 'Yes' denotes the presence of PII.	ai_generated	Boolean (Yes/No or True/False)	f	t	Yes	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
0d1e7656-46a5-40e8-aaa0-81c250b23b3c	5288642d-13e8-45b3-8f77-bcbff82a42c5	77		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			email	Highly Confidential	Customer	Email	The 'Email' represents a unique identifier for each customer, which is stored as a string of characters and separated by an "@" symbol within this database table. Its purpose is to facilitate communication with the respective customers regarding their orders, feedback, and promotions via electronic mail correspondence.	ai_generated	\N	t	t	sanchezlisa@gmail.com	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
0dd14761-d82f-4289-bb08-6d326bd62e90	5288642d-13e8-45b3-8f77-bcbff82a42c5	41		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			loan_tenure_months	Confidential	Sales	Loan Tenure Months	A business term representing "Loan Tenure Months" is a numeric field indicating the number of months over which an auto loan has been extended, recorded as integer values with possible example value being 48 for a loan lasting four years (or 576 months). This data assists in determining customer payment schedules and interest calculations.	ai_generated	\N	f	f	48	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
114a700d-4755-42c3-bbc9-031ea5fb5937	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	28	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Amount	Confidential	\N	Loan Amount	The "Loan_Amount" represents a business term that denotes the total sum of money borrowed by an individual, which is captured as an integer data type reflecting currency figures without any decimal places within the PRJ002 Risk Scoring database file RiSco. A sample value recorded in this field might be 62328040 indicating a substantial loan for $6,232,804 borrowed by an applicant assessed for risk purposes as pertains to project identification PRJ002_Risk_Scoring on excel.	ai_generated	Phone number	t	t	62328040	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
13aa7e5f-fc07-4115-9145-f9b22459ae61	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	5	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Type	Confidential	\N	Loan Type	The "Loan_Type" represents a personalized character string that categorizes loans into distinct groups such as 'Personal', which indicates non-commercial, individual lending products typically provided to borrowers without collateralaim for repayment. It's crucial in the PRJ002 Credit Profile database for differentiating between loan types and tailoring risk assessments accordingly within a financial institution or credit agency context.	ai_generated	Category: Auto, Mortgage, Personal	f	t	Personal	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
153a3f2e-4e33-4f51-b3d2-04b2a5722da3	347eb32e-4b25-4290-a1b6-f793b608c929	9	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	vin_code	Confidential	\N	Vin Code	A unique identifier assigned to each vehicle within the system, formatted as a VIN code (e.g., VIN‑000001) that distinguishes one vehicle from all others.	ai_generated	Category: VIN-000001, VIN-000002, VIN-000003	t	f	VIN-000001	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
1757cbe8-5f34-4eab-b4a1-f2463e07cc05	5288642d-13e8-45b3-8f77-bcbff82a42c5	55		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			engine_number	Confidential	Stock	Engine Number	The 'Engine Number' field represents a unique identifier for each car engine within the company’semotor inventory, structured as text and formatted to maintain consistency across records. It allows distinct identification of engines despite potential variations in naming conventions used during data entry or acquisition from various sources.	ai_generated	\N	t	f	ENG80549	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
190481c7-bab8-4fce-a85b-e1b930388b5f	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	8		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Analyst_Comments	Confidential	Service Prediction	Analyst Comments	Analyst Comments is a string field within an AI analytics table that contains qualitative observations made by analysts during data processing, reviewed insights on model performance and recommendations for further analysis; e.g., "Monitor closely". It serves as a communication tool between the raw data processed through machine learning algorithms and human oversight personnel to ensure accurate interpretation and subsequent decision-making processes based on AI-driven results.	ai_generated	\N	f	f	Monitor closely	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
1b68473d-bf2c-4a36-8e80-67cf6c17685f	5288642d-13e8-45b3-8f77-bcbff82a42c5	56		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			color	Confidential	Stock	Color	The "Color" business term refers to a string value representing the physical appearance of a car, such as 'Silver'. It is used within the `car_stock_data` database on Sheet1 for categorizing and filtering cars based on their color attributes. This data type allows easy identification and reporting by vehicle manufacturers or dealerships when managing inventory stocks to meet customer preferences efficiently.	ai_generated	\N	f	f	Silver	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
1c6d3a2c-56e3-4f21-bcce-297897d8c644	5288642d-13e8-45b3-8f77-bcbff82a42c5	89		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_segment	Confidential	Customer	Customer Segment	The "Customer Segment" refers to a categorized grouping of customers within an organization, typically designated by unique labels (e.g., 'VIP'), which helps tailor marketing strategies and services according to the value each segment contributes. It is stored as text in this database table under consideration for data-driven decision-making processes focusing on personalized customer experiences.	ai_generated	\N	f	f	VIP	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
1e5a022d-a16e-4700-930a-b2b3c089f36a	347eb32e-4b25-4290-a1b6-f793b608c929	11	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	mpg	Confidential	\N	Mpg	Mpg represents the vehicle’s fuel efficiency, indicating the number of miles it can travel on one gallon of gasoline under standard test conditions, stored as an integer value.	ai_generated	Integer (whole number)	f	f	18	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
1e78fbcd-9c13-4163-90e6-c8f6988957b6	5288642d-13e8-45b3-8f77-bcbff82a42c5	91		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			last_purchase_date	Confidential	Customer	Last Purchase Date	The Last Purchase Date refers to a DATETIME field within customer_data that records when each individual made their most recent purchase, with values formatted as year-month-day and time (e.g., "2025-01-08 00:00:00"). This column is crucial for analyzing purchasing patterns and tailoring marketing strategies to customer behavior over time.	ai_generated	\N	f	t	2025-01-08 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
21c692f3-c206-454b-8366-7121fa6ad84d	5288642d-13e8-45b3-8f77-bcbff82a42c5	38		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sale_price	Confidential	Sales	Sale Price	The "Sale Price" business term represents a monetary value for each vehicle sold, stored as an INTEGER data type within the car_sales_data table to facilitate efficient processing and reporting on total sales figures across all transactions recorded. A sample entry in this column would be '369788155'.	ai_generated	\N	t	f	369788155	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
2284de94-a467-44ce-8341-fc5101a2052b	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	26	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Income	Highly Confidential	\N	Income	In the PRJ002_Risk_Scoring database table, specifically within the RiSco Column of Table 'PRJ002_Risk_Scoring.xlsx', Income is defined as an INTEGER data type representing annual household income in dollars where a sample value would be 13608689.	ai_generated	Phone number	t	t	13608689	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
23621014-ce87-49b7-8c42-2e976861c26b	5288642d-13e8-45b3-8f77-bcbff82a42c5	78		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			national_id	Confidential	Customer	National Identifier	The national_id field stores a unique identifier for each customer, represented as an integer that serves as their National Identifier within the system to ensure consistent and secure access management. This data type facilitts efficient database indexing and retrieval operations while preserving confidentiality by limiting exposure of sensitive information outside authorized systems or processes.	ai_generated	\N	t	f	3104054678340300	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
26a9a7d7-d559-4863-8178-a7a44ffbf71c	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	3		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Usage_Pattern	Confidential	Service Prediction	Usage Pattern	The "Usage Pattern" represents a qualitative description of how often and under what circumstances an AI analytics tool is used, stored as text within the system to track frequency descriptors such as 'Low', 'Medium', or 'High'. This helps stakeholdner understand at a glance if usage levels are typical for this type of application.	ai_generated	\N	f	f	High	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
26d15cb4-2dd1-4455-b61e-a626e9882762	5288642d-13e8-45b3-8f77-bcbff82a42c5	18		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			test_drive_date	Confidential	Demand	Test Drive Date	The "Test Drive Date" field represents a DATETIME value within the car_demand_data, capturing when potential customers participated in test drives for vehicles; this data is essential for analyzing market demand patterns over time and planning business strategies accordingly. A sample date entry might appear as '2025-02-13 00:0ner'.	ai_generated	\N	f	t	2025-02-13 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
2aecf80d-453f-48ba-ac8d-029d60e982fb	85eaf07b-2298-4658-baaa-a5e267c74812	13	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Dataset_Name	Highly Confidential	\N	Dataset Name	The "Dataset Name" refers to a unique identifier for each dataset within PRJ003_Data_Quality, which is represented as text (STRING) and provides an at-adependent sample value such as 'Inventory' that signifies the type of data being analyzed.	ai_generated	Category: Customer, Inventory, Sales	f	t	Inventory	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
2b62ea53-9353-4cea-ad68-608d9d488be6	347eb32e-4b25-4290-a1b6-f793b608c929	5	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	sale_amount	Confidential	\N	Sale Amount	The total monetary value of a completed sale, recorded as an integer representing the amount in the smallest currency unit (e.g., cents).	ai_generated	Category: 25000, 27500, 31000	t	f	25000	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
2c50e2cd-5d31-4b63-8869-62c30c3c871e	85eaf07b-2298-4658-baaa-a5e267c74812	32	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Notes	Confidential	\N	Issue Notes	The 'Issue Notes' within PRJ003_Metadata_Catalog is a field for recording textual observations about issues found during project execution, with each entry being limited to a string of characters that provides specific details on duplicated data entries or other relevant matters affecting the integrity and accuracy of the metadata catalog.	ai_generated	Category: Duplicate data, Missing fields, No issue, Validated	f	t	Duplicate data	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
2d2b7e25-8132-4416-b606-4408eb9b6942	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	24		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Price	Confidential	\N	Price	The "Price" represents a unique identifier for each inventory item billing, stored as an integer data type reflecting monetary value without currency symbols to maintain consistency across records within the PRJ018_Inventory_Billing table. The sample price entry of 266139 indicates that this column contains numerical values only and serves for arithmetic operations related to inventory costs or sales revenue calculations, but is not a direct representation in currency format.	ai_generated	\N	t	f	266139	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
2d44552d-babd-453f-9dbc-e5232b6cb72c	5288642d-13e8-45b3-8f77-bcbff82a42c5	79		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			tax_id	Highly Confidential	Customer	Tax Identifier	The "Tax Identifier" is a string field within the customer_data table that uniquely identifies an individual'eneric identifier for tax purposes, typically represented as a sequence of numbers and/or letters specific to federal income tax records (e.g., SSN or Tax ID number).	ai_generated	\N	t	f	40.011.270.4-788.502	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
2e33d05f-09a0-4dc2-bc36-42c8f866c343	85eaf07b-2298-4658-baaa-a5e267c74812	6	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Quality_Score	Confidential	\N	Quality Score	The "Quality Score" is a numeric representation of data accuracy and reliability, typically assigned on a scale from 0 to 1 with decimals representing minor discrepanries; for instance, a score of 0.72 indicates relatively high quality but with some room for improvement in precision or correctness aspects. This measurement uses the FLOAT data type allowing fractional values and is critical in assessing overall information integrity within PRJ003_Data_Governance contexts.	ai_generated	Decimal number	f	t	0.72	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
2e8af8e4-795c-4bdf-a1c8-db39c3f9d6b4	5288642d-13e8-45b3-8f77-bcbff82a42c5	61		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			selling_price	Confidential	Stock	Selling Price	The business term "Selling Price" represents the price at which a vehicle is sold, calculated as an integer value representing currency with no decimals to ensure consistency and ease of calculation during data processing activities. This field should reflect only whole numbers that represent monetary values in dollars without cents or fractions for simplicity within the given business context.	ai_generated	\N	t	f	870073230	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
2f7bdf3d-689c-4332-a3ef-c7004f200aaf	5288642d-13e8-45b3-8f77-bcbff82a42c5	57		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			fuel_type	Confidential	Stock	Fuel Type	Fuel type refers to a specific attribute related to vehicles, categorized as strings within car stock data that indicate whether an engine uses gasoline, diesel, electricity, hybrid power, etc., with common examples being "Diesel," "Petrol," or "Electric."	ai_generated	\N	f	f	Diesel	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
2ff85a8c-5c7e-41a5-958b-8a62e97b67b9	347eb32e-4b25-4290-a1b6-f793b608c929	14	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	horsepower	Confidential	\N	Horsepower	The horsepower value indicates the engine’s power output, measured in mechanical horsepower, which reflects the vehicle’s ability to perform work and accelerate.	ai_generated	Integer (whole number)	f	t	130	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
31489074-4b56-409a-9300-cc030d342cdb	5288642d-13e8-45b3-8f77-bcbff82a42c5	13		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			trade_in_interest	Confidential	Demand	Trade In Interest	Trade In Interest represents a business term for any string value indicating whether customers have interest (Yes/No) to trade their car when purchasing a new one, directly impacting dealership sales strategies and inventory management within the automot extranosaíl data governance framework.	ai_generated	\N	f	f	No	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
31982c40-f640-4c58-99b1-b5d9c801b3e2	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	11	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Score	Confidential	\N	Score	The "Score" represents a numerical credit rating as a floating-point value, reflecting an individual's likelihood to repay debt based on their financial history and current circumstances; it is stored as FLOAT data type with values such as 0.76 indicating the subject has been deemed fairly likely to meet future payment obligations.	ai_generated	Decimal number	f	t	0.76	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
319e299b-3248-4493-9ea1-f170ab51fdde	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	16		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Service_Date	Confidential	\N	Service Date	The "Service Date" is a critical field representing when each customer service interaction occurred, recorded as a DATE datatype with values formatted in YYYY-MM-DD style; for example, January 1, 2ty6.	ai_generated	\N	t	f	2026-01-01	DATE	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
32f01c16-3c79-4f2e-8113-5c71ca46eb5d	347eb32e-4b25-4290-a1b6-f793b608c929	18	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	origin	Confidential	\N	Origin	The country in which the automobile was manufactured or assembled, identified by its standard country code (e.g., “usa”).	ai_generated	Category: europe, japan, usa	f	f	usa	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
33a7138a-d08c-47f3-a31d-edcd13b82763	85eaf07b-2298-4658-baaa-a5e267c74812	1	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Record_ID	Confidential	\N	Record Identifier	The "Record Identifier" serves as a unique alphanumeric string assigned to each record within the Data Governance framework, facilitating identification and retrieval of specific data entries for auditing purposes without revealing any sensitive information contained therein. It ensures consistency and traceability throughout data handling processes while maintaining compliance with relevant regulations concerning personal identifiable information (PII).	ai_generated	Free text	t	t	PRJ003_0_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
349dd538-81d0-483a-ab66-cf01ca8c6887	85eaf07b-2298-4658-baaa-a5e267c74812	23	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Record_ID	Confidential	\N	Record Identifier	The "Record Identifier" serves as a unique string key for each record within the PRJ0 endpoint metadata catalog, allowing efficient retrieval and association of related information; it is formatted consistently across entries like 'PRJ003_1_0'. Each Record ID uniquely identifies an item in the database without revealing specific data contained within.	ai_generated	Free text	t	t	PRJ003_1_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
360993d6-b44a-4256-bb2c-7e3aef412014	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	6	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Amount	Confidential	\N	Loan Amount	The "Loan_Amount" represents a numeric value indicating the principal amount of money disbursed to borrowers as part of their credit profile, categorized under 'Loan Amount' within PRJ002_Credit_Profile table with an integer data type and can range up to six digits long. It is utilized in assessing a borrower’s repayment capacity based on the sum they receive from loans provided by financial institutions or credit agencies, typically recorded as exact figures without decimal points for standardization purposes within loan amount calculations and evaluations.	ai_generated	Phone number	t	t	60491266	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
3686d812-df71-4923-8647-2d091ac98dce	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	4	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Income	Highly Confidential	\N	Income	The "Income" business term represents an individual's annual earnings, stored as an INTEGER data type within the Credit Profile table to facilitate financial analysis and creditworthiness assessments. The value indicates a positive integer reflecting yearly income earned by an entity or person for whom this database records personalized credit information.	ai_generated	Phone number	t	t	11226105	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
36b44e96-8837-49f6-98d2-81d86cd0d4e4	347eb32e-4b25-4290-a1b6-f793b608c929	17	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	model_year	Confidential	\N	Model Year	The model year indicates the calendar year in which the automobile was originally manufactured, recorded as a numeric value (e.g., 1970).	ai_generated	Category: 70, 71, 72, 73	f	f	70	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
3798c116-65c6-43c0-9e89-10408734927e	5288642d-13e8-45b3-8f77-bcbff82a42c5	52		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			model	Confidential	Stock	Model	The business term "Model" refers to a distinct version of a vehicle manufactured by a particular car company, usually characterized by unique design features and specifications. It represents an identifier for each individual product offered within the automotin industry's diverse range of vehicles on sheet1 from table:car_stock_data.xlsx - Sheet1, with its data type set as STRING to accommodate various alphanumeric characters that denote different models such as "Fortuner".	ai_generated	\N	f	f	Fortuner	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
37ea8849-5e75-4598-b2b6-d467b888420d	85eaf07b-2298-4658-baaa-a5e267c74812	7	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Completeness	Confidential	\N	Completeness	Completeness represents a measure of how fully each record within a dataset has been populated, typically expressed as a float value between 0 and 1 where higher values indicate greater completeness; for example, Completeness might be recorded at 0.86 indicating that approximately 86% of the required data fields are filled in per row.	ai_generated	Decimal number	f	t	0.86	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
39144b1e-5308-4cf3-9d20-3e9cc1a83788	347eb32e-4b25-4290-a1b6-f793b608c929	13	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	displacement	Confidential	\N	Displacement	Displacement is the total volume swept by an automobile’s pistons, recorded as an integer that represents the engine’s size in cubic inches.	ai_generated	Integer (whole number)	f	f	307	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
391802a3-64c2-4d01-902c-0efaec399b29	5288642d-13e8-45b3-8f77-bcbff82a42c5	72		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			last_name	Highly Confidential	Customer	Last Name	The "Last Name" business term refers to a string value that represents a customer' endonym, used for identification and reference purposes within company records stored as textual data type entries. An example of this would be the surname 'Cruz'.	ai_generated	\N	f	f	Cruz	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
39fd7a24-ac5c-46da-aa70-df5749561169	5288642d-13e8-45b3-8f77-bcbff82a42c5	40		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			down_payment	Confidential	Sales	Down Payment	The "Down Payment" represents a financial commitment made by a buyer, recorded as an INTEGER value indicating its amount within car_sales_data'an Excel spreadsheet."	ai_generated	\N	t	f	136697057	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
3b4b913c-f123-49c0-acc1-cfd98ff84dba	5288642d-13e8-45b3-8f77-bcbff82a42c5	74		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			gender	Highly Confidential	Customer	Gender	The "Gender" business term within the customer_data refers to a string attribute that represents and categorizes an individual'self as either male, female, non-binary, transgender etc., based on their gender identity; for instance 'Female'. This column is used primarily in demographic analyses or personalized marketing efforts.	ai_generated	\N	f	f	Female	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
3e13a250-37ae-4d80-87ca-38e42cdd3891	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	13	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Customer_ID	Confidential	\N	Customer Identifier	The "Customer ID" serves as a unique identifier for each customer, coded as a string of characters that distinguishes them within loan transaction records; it is essential for tracking accountability and personalizing services without disclosing sensitive information directly from the record itself. An example value might be represented by an alphanumeric code like "CUST1000".	ai_generated	Free text	t	t	CUST1000	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
4113a833-fe0c-4945-81f2-48d7cf2fabc4	5288642d-13e8-45b3-8f77-bcbff82a42c5	3		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_name	Highly Confidential	Demand	Customer Name	The "Customer Name" represents a unique identifier for each customer, stored as text within the car demand data system to facilitate personalized service and account management; it is essential for tracking purchases and interactions with customers who are represented by this attribute through various string formats such as names or initials.	ai_generated	\N	t	f	Tgk. Kezia Hutasoit	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
42dcfa00-b24b-4830-88ae-037f84b6adbf	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	10		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_ID	Confidential	\N	Customer Identifier	The "Customer Identifier" serves as a unique, alphanumeric string assigned to each customer within the database that allows for their identification and individual record tracking without revealing personal information directly associated with them. This identifier'thy type is consistently formatted across records for uniformity and ease of reference while maintaining data privacy standards.	ai_generated	\N	t	f	CUST1000	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
43a56de0-b5ff-4494-b528-d90782daa8b4	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	9		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Recommendation	Confidential	Service Prediction	Recommendation	The "Recommendation" is a string field within the AI Analytics table that holds discrete, actionable suggestions provided by an artificial intelligence model to engage customers based on their behavior patterns and data analysis; for example, suggesting contacting them directly through email or phone call as recommended.	ai_generated	\N	f	f	Contact customer	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
44edf039-bb55-44ef-945c-18ce365c490a	5288642d-13e8-45b3-8f77-bcbff82a42c5	73		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			full_name	Highly Confidential	Customer	Full Name	Full name represents a concatenated string of given and family names, serving as an identifiable alias for customer records within 'customer_data'. It is composed solethyric characters derived from textual inputs such as "Amanda Cruz" without any numeric elements included. This column facilitates personalized communication by providing a recognizable form of address directly associated with the respective individual's unique identity in the database, ensuring consistency and accuracy during data retrieval processes while adhering to privacy guidelines related to personally identifiable information (PII).	ai_generated	\N	t	f	Amanda Cruz	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
4521df6b-bc7f-4581-8764-e21811127a34	85eaf07b-2298-4658-baaa-a5e267c74812	25	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Owner	Confidential	\N	Owner	The "Owner" field represents a unique identifier for an individual, organization, or entity responsible for managing and maintaining access to project metadata within PRJ003_Metadata_Catalog database table. As a STRING data type with the sample value 'Ops', it indicates that Operations is likely in charge of this responsibility.	ai_generated	Category: BI, IT, Ops	f	t	Ops	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
4849d880-8bcf-4030-94f7-5d75229ccea2	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	30	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Risk_Level	Confidential	\N	Risk Level	The "Risk Level" is a categorical string field representing the assessed risk of an entity within PRJ002_Risk_Scoring, with possible values such as Low, Medium, and High to help prioritize responses or actions based on each entry's potential impact.	ai_generated	Category: High, Low, Medium	f	t	Medium	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
4ae3ec21-147f-4ece-b1c1-7dcae386dd81	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	18	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Status	Confidential	\N	Loan Status	The "Loan Status" represents the current condition of a loan application within an organization, indicating whether it is still under review (Pending), approved for disbursement, denied due to insufficient credit history or unfavorable terms, etc., and this status information assists in managing communication with applicants throughout their borrowing process. As a string data type, the values typically include textual representations such as "Pending," "Approved," "Denied (Insufficient Credit History)," among others that succinctly communicate specific loan conditions to various stakeholders within and outside of the organization for efficient handling and record-keeping.	ai_generated	Category: Approved, Pending, Rejected	f	t	Pending	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
4b0db16f-10c8-4e4d-bcf5-d5927aee69d7	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	11		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_Name	Highly Confidential	\N	Customer Name	The "Customer Name" is a string data type field representing full legal names of customers, such as 'Johnathan Smith'. It serves to identify individual clients within customer service operations for project PRJ018_Customer_Service (CS). Example value: 'Smith' or any legally compliant name.	ai_generated	\N	t	f	Name_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
4b9d666a-eb04-4687-a511-d37c6d9e67d4	85eaf07b-2298-4658-baaa-a5e267c74812	22	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Approval_Status	Confidential	\N	Approval Status	The "Approval Status" indicates whether a record has been reviewed and authorized; it is stored as text, commonly represented by values such as 'Pending', indicating that approval actions are yet to be taken for the respective data entries.	ai_generated	Category: Approved, Pending, Rejected	f	t	Pending	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
4c4445cf-0e87-4585-ae0e-6b22f63dd9fc	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	13		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Phone_Number	Highly Confidential	\N	Phone Number	The business term "Phone Number" refers to a unique identifier associated with an individual'selfs personal contact information, typically formatted as digits representing geographic areas and specific individuals. In this case, the data type is INTEGER, suggesting that while primarily serving its role as identification, it can also potentially be used for operations such as sorting or indexing within database queries without implying actual telecommunications functionality inherent to phone numbers themselves in raw numeric form.\n\nSample value: The provided example of a Phone Number (08634895718) is an integer representing what could correspond to the country code, area code and local number sequence for personal contact purposes within data management systems but does not inherently contain telecommunication capability outside its utilization as identification in this context.	ai_generated	\N	t	f	08634895718	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
4f13efdc-51dc-4b5d-931c-2002a4dfd263	85eaf07b-2298-4658-baaa-a5e267c74812	24	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Dataset_Name	Highly Confidential	\N	Dataset Name	The "Dataset Name" represents a unique identifier for each dataset within an organization, serving as a human-readable reference that encapsulthinely describes the content and nature of the data without diving into its specifics. As defined by Microsoft Excel or similar spreadsheet software standards, it is expected to be stored in text format (STRING) accommodating alphanumeric characters only for flexibility in naming conventions across diverse datasets such as "Sales".	ai_generated	Category: Customer, Inventory, Sales	f	t	Sales	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
504d2b2b-8edf-415c-bb0b-1af43d00ab54	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	1	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	ID	Confidential	\N	Identifier	The "ID" serves as a unique identifier for each record within the Credit Profile table, functioning to reference and distinguish data entries distinctly without carrying any specific credit information; it is of string type with sample values like PRJ002_0_0 reflecting project-based identifiers.	ai_generated	Free text	t	t	PRJ002_0_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
50f9c960-0872-4fe8-835a-66ea5c7db2eb	85eaf07b-2298-4658-baaa-a5e267c74812	29	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Completeness	Confidential	\N	Completeness	The "Completeness" business term within the PRJ003_Metadata_Catalog represents a float data type measure of how fully an item's metadata is populated, with values ranging from 0 (completely empty) to 1 (fully complete). A sample value might be represented as 0.99 indicating near-complete metadata coverage for the associated cataloged resource.	ai_generated	Decimal number	f	t	0.99	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
526511ec-7991-4314-8685-6c8bf13d098c	347eb32e-4b25-4290-a1b6-f793b608c929	10	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	name	Highly Confidential	\N	Name	The name is the manufacturer‑assigned model identifier for the automobile, recorded as a text string (e.g., “chevrolet chevelle malibu”).	ai_generated	Free text	f	f	chevrolet chevelle malibu	STRING	Raw	2026-05-21	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
53bc5062-f31a-483a-b756-b9cd20ccaa23	5288642d-13e8-45b3-8f77-bcbff82a42c5	82		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			province	Confidential	Customer	Province	The 'province' data type represents a specific administrative region within Indonesia, typically consisting of two characters representing its name; for example, "Kal" refers to Kalimantan Timur. It is stored as text (STRING) due to the inclusion of province names that may not follow conventional naming rules and needing flexibility in case sensitivity or accents if present.	ai_generated	\N	f	f	Kalimantan Timur	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
5400260e-4b53-4787-a986-211590dfe439	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	23		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Quantity	Confidential	\N	Quantity	Quantity represents the number of units for a particular item on hand, stored as an integer value within the inventory and billing system to facilitate accurate stock management and financial transactions. The Quantity field is essential for maintaining optimal inventory levels, tracking sold items, and calculating revenue or any discrepanries that may require adjustments in accounting records.	ai_generated	\N	f	f	3	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
551c28f7-588d-49e9-9207-f204ddac864f	5288642d-13e8-45b3-8f77-bcbff82a42c5	50		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			warehouse_location	Confidential	Stock	Warehouse Location	The business term 'Warehouse Location' refers to a specific, identifiable place where vehicles are stored before distribution and is represented as a string that denotes this location within the car stock data database. An example value for warehouse_location might be "Jakarta". This column helps in managing inventory by providing information about where each vehicle is physically located at any given time, facilitating efficient logistics operations such as receiving and dispatching vehicles to meet customer demand promptly.	ai_generated	\N	f	f	Jakarta	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
55a2479a-d23b-43d7-9f43-c275809f9ed8	5288642d-13e8-45b3-8f77-bcbff82a42c5	5		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			email	Highly Confidential	Demand	Email	The "Email" business term refers to a unique string value representing an individual's electronic mail address, used for communication related to car demand data within this Excel file context and typically follows the format of alphanumeric characters combined with symbols like periods and plus signs (e.g., christinewilliams@yahoo.com).	ai_generated	\N	t	f	christinewilliams@yahoo.com	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
56297f56-318f-4fca-ae85-c277cac142cf	5288642d-13e8-45b3-8f77-bcbff82a42c5	47		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			payment_status	Confidential	Sales	Payment Status	The "Payment Status" represents a record of whether a customer's payment for their car sale has been completed, is still pending approval, or requires additional actions from either party. It serves as an essential indicator to both the seller and buyer regarding transaction progress in real-time within 'car_sales_data'.xlsx - Sheet1 database table.	ai_generated	\N	f	f	Pending	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
57d0bacb-44c9-4b01-ad27-ce511d8cea23	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	12		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Email	Highly Confidential	\N	Email	Email is a VARCHAR(255) field representing the electronic mail address of a customer, used for communication purposes within business operations related to Customer Service (CS). It supports text data up to 255 characters and serves as an essential identifier for personalized interactions between customers and service representatives.	ai_generated	\N	t	f	customer0@mail.com	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
59bb8125-6aa2-41af-9306-b625e0f10d9a	5288642d-13e8-45b3-8f77-bcbff82a42c5	26		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sales_date	Confidential	Sales	Sales Date	Sales date refers to a specific point in time when a car sale occurred, represented as a DATETIME data type without any timezone information and recorded for each transaction within the provided Excel sheet related to vehicle sales activities. The format adheres strictly to standardized conventions of year-month-day hour:minute:second notation with all components being mandatory in order to ensure precise tracking across temporal records facilitated by this essential data column within car_sales_data repository, such as 2curated 'Sales Date'. This information is critical for the analysis and reporting of sales performance over time.	ai_generated	\N	f	f	2025-06-04 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
5eb81097-f9e5-4cf8-9840-0f3b11da6170	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	12	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	ID	Confidential	\N	Identifier	The "Identifier" business term for a database column stores unique, string-based numeric codes as identifiers to uniquely distinguish individual loan transactions within the table PRJ0soft_Loan_Transactions.loTrans; example values appear similar to financial instruments or policy references (e.g., 'PRJ002_1_0').\n\n\nAs a data governance consultant, you are required to craft comprehensive definitions for database columns that adhere strictly to best practices in business terminology and comply with international standards such as ISO/IEC 5218: LoanApplication.xlsx - LAppID Column Business Terms Description Data Types Examples\nColumn Name ID Business term Identifier Unique reference number (UUID) for each loan application PRJ003_2_7 string-based Globally recognized identifier that conforms to ISO/IEC 5218 standards	ai_generated	Free text	t	t	PRJ002_1_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
5f4b94d8-cc8d-4c43-8e3a-de2b18a4424e	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	8	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Risk_Level	Confidential	\N	Risk Level	"Risk Level is a categorical data type that represents the perceived risk associated with an entity, as determined by analyzing various financial indicators and credit history, where 'Medium' indicates a balanced level of potential default likelihood."	ai_generated	Category: High, Low, Medium	f	t	Medium	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
5f7dfb6a-cf27-4ecb-90ec-4f5ebaa45321	5288642d-13e8-45b3-8f77-bcbff82a42c5	16		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			urgency_level	Confidential	Demand	Urgency Level	The 'Urgency Level' is a string data type field representing the immediacy with which car demand needs to be addressed, classified into categories such as "Low," "Medium," and "High." This classification helps prioritize actions and allocate resources effectively within organizations.	ai_generated	\N	f	f	Low	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
5fa75550-a1b2-4f5a-9fda-138487eca286	5288642d-13e8-45b3-8f77-bcbff82a42c5	44		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			trade_in	Confidential	Sales	Trade In	A "Trade In" is a string value representing whether a customer provided their own vehicle for sale during this transaction, typically entered as 'Yes' if applicable and omitted otherwise. This data assists the business by indicating potential additional income sources from trade-ins when calculating total sales revenue.	ai_generated	\N	f	f	Yes	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
60b1d343-f4b3-47ed-b93f-aa35635362e5	85eaf07b-2298-4658-baaa-a5e267c74812	30	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Last_Updated	Confidential	\N	Last Updated	The 'Last Updated' field represents a DATETIME data type that captures when metadata entries were most recently modified within PRJ003_Metadata_Catalog, reflecting changes made on February 1, 2term to track the currency and accuracy of project information stored in this database.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
6321c22d-2f13-4add-872e-22ab534b94a0	5288642d-13e8-45b3-8f77-bcbff82a42c5	31		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			model	Confidential	Sales	Model	The "Model" represents a category of vehicles identified by unique string identifiers, such as make and model name (e.g., 'Toyota Camry'), which allows for differentiation among similar brands within the automotive industry data set being analyzed to understand market preferences and sales trends on Sheet1 in car_sales_data.xlsx file under Business Term: Model column with STRING data type, where a sample value like 'City' signifies one of many possible entries for this specific vehicle category within the database context.	ai_generated	\N	f	f	City	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
640d30a2-df39-4669-9488-8b6a5cec9b34	85eaf07b-2298-4658-baaa-a5e267c74812	17	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Quality_Score	Confidential	\N	Quality Score	The "Quality Score" is a business term representing an assessment of data accuracy, completeness, and reliability within PRJ003_Data_Quality table on the Quality_Score float type that can range from 0 (completely invalid or poor quality) to 1 (highest possible score indicating pristine condition). For example, a sample value of `0.64` signifies substantial data integrity with some areas left for improvement and is not reflective of the highest potential accuracy achievable by any given dataset in this context.	ai_generated	Decimal number	f	t	0.64	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
64cec6b4-ea7b-478f-bb6e-f73ea20251d3	5288642d-13e8-45b3-8f77-bcbff82a42c5	80		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			address	Highly Confidential	Customer	Address	The business term "Address" refers to a textual representation of an individual's residential location within the customer_data Excel sheet, formatted as a string and containing details such as street name (e.g., Jalan Dipenogoro), city (Cimahi), province or state (Sulawesi Tenggara), and postal code/zipcode 04087 in the example provided.	ai_generated	\N	t	f	Jalan Dipenogoro No. 83, Cimahi, Sulawesi Tenggara 04087	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
651ddbc2-6e7f-4b82-859c-0d88945eec87	5288642d-13e8-45b3-8f77-bcbff82a42c5	19		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			follow_up_status	Confidential	Demand	Follow Up Status	The "Follow Up Status" is a VARCHAR data type field that tracks whether and when to follow up with customers regarding their car demand, using values like 'Lost', 'Confirmed Interest', 'Inquired About Price' among others as status indicators for customer engagement in the context of automotin market analysis.	ai_generated	\N	f	f	Lost	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
67fde6dc-e06a-49bc-93c7-18da4884376b	85eaf07b-2298-4658-baaa-a5e267c74812	9	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Flag	Confidential	\N	Issue Flag	The 'Issue Flag' is a string value within the PRJ003_Data_Governance table that indicates whether an issue has been identified ('Yes') related to data governance, with other potential values such as 'No', representing no issues found or unidentified. This column assists in tracking and managing compliance statuses for various aspects of the organization's data management practices.	ai_generated	Boolean (Yes/No or True/False)	f	t	Yes	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
68903994-501a-4d0b-b2ad-1490d95376f9	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	1		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Record_ID	Confidential	Service Prediction	Record Identifier	The "Record Identifier" serves as a unique alphanumeric string assigned to each record within AI analytics database entries, ensuring accurate tracking and retrieval of individual data points for analysis purposes such as PRJ018_AI_Analytics (e.g., REC3000).	ai_generated	\N	t	f	REC3000	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
68b545ae-3c03-4a69-8108-8486927f6d3b	85eaf07b-2298-4658-baaa-a5e267c74812	16	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	PII_Flag	Confidential	\N	Pii Flag	The "PII Flag" signifies whether personal identifiable information is present (Yes) within a data record to ensure proper handling and protection of sensitive information according to regulatory compliance requirements for the project's data quality assessment process, represented as a string value with potential values being 'Yes' or 'No'.	ai_generated	Boolean (Yes/No or True/False)	f	t	Yes	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
68f70010-85ca-4389-961d-2d5cada2e819	5288642d-13e8-45b3-8f77-bcbff82a42c5	51		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			brand	Confidential	Stock	Brand	A "Brand" represents a company name within the car stock data, specifically identifying automotin manufacturers such as 'Toyota'. It is of string data type and holds values like brand's official registered trade mark for identification purposes only; this term does not include dealer names or model variations.	ai_generated	\N	f	f	Toyota	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
6a525841-6c56-4c81-bde8-406ee65f7dc6	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	3	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Age	Confidential	\N	Age	Age represents the chronological age of an individual, expressed as a whole number that denotes years since birth (e.g., Age = 58). It serves to help evaluate creditworthiness and financial stability for project-related services within PRJ002_Credit_Profile dataset by analyzing demographic factors associated with repayment behavior patterns in INTEGER format.	ai_generated	Integer (whole number)	f	t	58	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
6b9b8c8f-4980-4ec2-8539-9a02b105fe79	5288642d-13e8-45b3-8f77-bcbff82a42c5	12		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			financing_interest	Confidential	Demand	Financing Interest	The "Financing Interest" represents a company's level of interest, either high ("Yes") or low/no ("No"), in financing options for acquiring vehicles based on their specific needs and financial considerations as recorded in the car_demand_data Excel file Sheet1.	ai_generated	\N	f	f	No	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
6bfc1c54-c5bc-4687-972a-b0aced401f85	5288642d-13e8-45b3-8f77-bcbff82a42c5	23		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			estimated_purchase_date	Confidential	Demand	Estimated Purchase Date	The "Estimated Purchase Date" represents a future datetime when it is anticipated that an individual will complete their car purchase, as recorded with precision down to hours and seconds for planning and analysis purposes within the customer demand study data set. The field follows a DATETIME format where sample values look like 'YYYY-MM-DD HH:MM:SS'.	ai_generated	\N	f	f	2025-04-15 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
6d4c4bd5-3516-4860-9459-ae12cfd7261a	5288642d-13e8-45b3-8f77-bcbff82a42c5	81		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			city	Confidential	Customer	City	A city is a categorical data type represented as a string, indicating the urban area where a customer resides; for example, "Jakarta". This information assists businesses to understand their geographic market distribution and tailor services accordingly. In this Excel file's 'customer_data' sheet, you can find records with city values like "Bandung", "Surabaya", etc., each serving as a unique identifier for the customer’in respective locale within Java Island of Indonesia or elsewhere globally.	ai_generated	\N	f	f	Jakarta	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
718467c4-e19f-4545-9b4a-84eb9e0909c8	5288642d-13e8-45b3-8f77-bcbff82a42c5	45		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			delivery_date	Confidential	Sales	Delivery Date	The Delivery Date is a DATETIME data type field representing when a vehicle was delivered, formatted as YYYY-MM-DD HH:MM:SS with an example value of May 10th, 2 end of year 2546 reflecting the future delivery timeframe.	ai_generated	\N	f	t	2025-05-10 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
7228c5ab-0c85-4da3-856d-531451389f54	5288642d-13e8-45b3-8f77-bcbff82a42c5	46		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sales_channel	Confidential	Sales	Sales Channel	The "Sales Channel" represents a specific method through which car sales are made, with data type string and exemplified by an online platform for transactions. This term encapsulries all mediums of sale as distinctly categorized within the database to ensure proper tracking and analysis related to their respective performance metrics in the automotive industry's marketing efforts.	ai_generated	\N	f	f	Online	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
729a5cc2-9289-4490-99cf-19f68a0c3427	5288642d-13e8-45b3-8f77-bcbff82a42c5	15		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			dealer_location	Confidential	Demand	Dealer Location	The 'Dealer Location' represents a specific geographical location where car dealerships are situated, and it is stored as a string type within the database to facilitate textual representation of these locations for easy reference by users accessing this data without implying any inherent ordering or sorting ability.	ai_generated	\N	f	f	Bontang	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
72f3ac35-a233-4b64-aaf7-7d53bba3a216	5288642d-13e8-45b3-8f77-bcbff82a42c5	90		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			registration_date	Confidential	Customer	Registration Date	The Registration Date is a DATETIME field representing the specific point in time when each customer has registered, with values recorded as date and time down to the second (e.g., YYYY-MM-DD HH:MM:SS). This column holds historical data that can be used for tracking registration trends over specified periods or analyzing peak times of registrations within a company's operation cycle in customer_data.xlsx - Sheet1 on the provided business context.	ai_generated	\N	f	f	2025-11-16 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
73e25b4d-ab74-4dbc-8443-1deb2f6cc60f	5288642d-13e8-45b3-8f77-bcbff82a42c5	36		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			fuel_type	Confidential	Sales	Fuel Type	The business term "Fuel Type" refers to a string data type used within car sales records to denote whether vehicles run on diesel, petrol (gasoline), electricity, hybrid, natural gas, or another form of fuel as specified by the user input. It categorizes each vehicle' endurance source in concise text format for consistent record-keeping and reporting purposes.	ai_generated	\N	f	f	Diesel	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
7610e766-4f80-47c2-9e1a-cf62e195d361	347eb32e-4b25-4290-a1b6-f793b608c929	6	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	status	Confidential	\N	Status	The status reflects the current business state of the record, indicating where it is in the processing lifecycle (e.g., Delivered, Pending, In‑Transit, etc.).	ai_generated	Category: Delivered, Pending	f	f	Delivered	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
76fcbfc2-36cb-4322-b801-9033daee287c	85eaf07b-2298-4658-baaa-a5e267c74812	3	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Owner	Confidential	\N	Owner	The "Owner" field denotes the individual(s) responsible for maintaining data governance standards within a project, with each value being represented as a string indicating their name or initials (e.g., BI). This identifier is crucial to ensure accountability and trace ownership of actions taken on this particular dataset.	ai_generated	Category: BI, IT, Ops	f	t	BI	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
7716774e-8836-47b2-8ff8-ea1ac2cd5029	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	7		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Model_Confidence	Confidential	Service Prediction	Model Confidence	Model confidence is a quantitative measure represented as a floating-point number indicating how confident an artificial intelligence model'th prediction made on 'PRJ018_AI_Analytics' dataset feels about its accuracy, with sample values ranging from 0 to 1 where 1 denotes full certainty.	ai_generated	\N	f	f	0.84	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
7ceb248d-4d3e-49e6-b6b1-10a4f6049130	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	2		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_ID	Confidential	Service Prediction	Customer Identifier	The "Customer ID" serves as a unique identifier for each customer within the AI Analytics database, employing string data type to accommodate alphanumeric codes such as 'CUST1057'. This key is essential for accurately associating records with individual customers and maintaining consistent referencing throughout analytics processes.	ai_generated	\N	f	f	CUST1057	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
8234cf2e-776b-4187-8f9b-877abc0fcf6a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	20		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_ID	Confidential	\N	Customer Identifier	The "Customer_ID" serves as a unique string identifier for each customer within PRJ018_Inventory_Billing, allowing for individual tracking of billing and inventory activities associated with specific customers without disclosing personal details. Example: CUST1039 represents such an identifiable marker linking to one or more transactions in the database records.	ai_generated	\N	f	f	CUST1039	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
83738de8-5fdb-4843-8849-98e32316032c	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	6		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Risk_Score	Confidential	Service Prediction	Risk Score	The business term "Risk Score" refers to a quantifiable measure used by an AI analytics system, stored as a floating-point number (FLOAT) within the PRJ018_AI_Analytics database table, where sample value might be something like 0.4; this score typically reflects potential risk levels associated with particular projects or decisions based on analyzed data patterns and predictive algorithms.	ai_generated	\N	f	f	0.4	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
83c3ee15-5488-4e1a-be09-9276a209290c	5288642d-13e8-45b3-8f77-bcbff82a42c5	1		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			demand_id	Confidential	Demand	Demand Identifier	The 'Demand Identifier' serves as a unique, alphanumeric string associated with each car demand record to facilitate easy tracking and reference throughout data governance processes within automotinous industry analyses. It ensures consistent identification across various systems interacting with the database for seamless integration of real-time market analysis insights into strategic decision making.	ai_generated	\N	t	f	DEM00001	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
854abd13-d3a9-4b8b-a59e-b18c439ce73e	5288642d-13e8-45b3-8f77-bcbff82a42c5	86		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			monthly_income	Highly Confidential	Customer	Monthly Income	A database record stores a numerical value representing an individual customer's earnings on a monthly basis, which is integral to understanding their financial status and purchasing power within the business context. This particular piece of data reflects the gross income accrued by customers from all sources before any deductions during one calendar month.	ai_generated	\N	t	t	20613608	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
85caa6a4-8c00-4ec5-884d-f922f77987ee	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	32	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Notes	Confidential	\N	Notes	The "Notes" business term within PRJ002_Risk_Scoring table serves as a textual area to capture additional context, observations, and qualitative information related to the risk scoring of profiles evaluated by users; it supports non-numeric descriptors that may influence decision-making processes. The data type for this column is string (TEXT) in SQL dialects like MySQL or VARCHAR2 with predetermined length restrictions such as 500 characters, ensuring storage efficiency while accommodating detailed user input within the Excel file Notes cell range A:A to contain these narrative descriptions and allowing direct reference of specific entries by their row index.	ai_generated	Category: Good profile, High risk, Incomplete docs, Verified	f	t	Good profile	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
863af9c7-f035-4edc-984c-33a8129042be	5288642d-13e8-45b3-8f77-bcbff82a42c5	75		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			date_of_birth	Confidential	Customer	Date Of Birth	The Date Of Birth represents a person's birth date and time recorded as DATETIME data type, with values formatted as YYYY-MM-DD HH:MM:SS (e.g., 1970-12-18). This information is crucial for age verification processes in customer data management within a business context where the accuracy and consistency of this personal attribute are essential to maintain compliance with data governance standards.	ai_generated	\N	t	f	1970-12-18 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
87b1c3fd-2dc1-4b24-8e6d-ea756332b57c	5288642d-13e8-45b3-8f77-bcbff82a42c5	66		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			last_maintenance_date	Confidential	Stock	Last Maintenance Date	The Last Maintenance Date represents the most recent date and time when a vehicle within the car dealership's stock received maintenance, recorded as DATETIME data type for precision tracking purposes. This information is crucial for ensuring that all vehicles are serviced regularly to maintain reliability before sales or leasing offers them out.	ai_generated	\N	f	t	2024-05-28 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
898e431c-a3ec-40fc-8f92-a886042ecfb5	85eaf07b-2298-4658-baaa-a5e267c74812	18	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Completeness	Confidential	\N	Completeness	Completeness is a measure of how fully recorded data points are represented within a dataset, with sample values typically expressed as floating point numbers between 0 and 1 to represent ratios, such as the proportion of non-null entries relative to total possible records for each entry in this context. A completeness value like 0.68 indicates that approximately 68% of data points have been fully recorded with valid values while reflecting on the potential impacts and implications within business operations regarding missing information.	ai_generated	Decimal number	f	t	0.68	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
8a8059a2-defa-4ca3-ba7d-a2c098338c37	5288642d-13e8-45b3-8f77-bcbff82a42c5	53		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vehicle_year	Confidential	Stock	Vehicle Year	The "Vehicle Year" represents a specific calendar year when a vehicle was manufactured, recorded as an integer data type for consistent categorization and analysis within car inventory management systems; example values range from current years down to historical production models anticipated into the future (e.g., up to 2026).	ai_generated	\N	f	f	2026	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
8ca2cf81-6d62-4e68-86ff-c04680b4d14b	347eb32e-4b25-4290-a1b6-f793b608c929	8	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	region	Confidential	\N	Region	Region refers to the specific city or geographic area associated with the record, for example, Jakarta.	ai_generated	Category: Bandung, Jakarta, Surabaya	t	f	Jakarta	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
8d119665-f5fd-4842-b1f3-ed64bc82bf5e	5288642d-13e8-45b3-8f77-bcbff82a42c5	22		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			competitor_brand	Confidential	Demand	Competitor Brand	The 'Competitor Brand' represents a company that produces vehicles competing with another manufacturer, stored as text data type for comparison purposes within car demand analytics. This information assists businesses and analysts to understand market position and consumer preferences related to different vehicle brands.	ai_generated	\N	f	t	Toyota	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
8ecacb11-b171-4f0f-933f-af9a95ef7614	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	21		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Item_Code	Confidential	\N	Item Code	The "Item Code" within PRJ018_Inventory_Billing is a string that uniquely identifies inventory items for billing purposes, such as ITM02 representing the code assigned to an item of stock. This unique identifier ensures accurate tracking and financial recording during sales transactions.	ai_generated	\N	f	f	ITM02	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
8fd0233c-61f9-4cd6-8d5f-3c5ef0ae0c94	347eb32e-4b25-4290-a1b6-f793b608c929	7	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	delivery_date	Confidential	\N	Delivery Date	The calendar date on which the ordered goods or services are scheduled to be delivered to the customer or end‑user.	ai_generated	Category: 2026-01-15, 2026-02-10, 2026-03-05	t	f	2026-01-15	DATE	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
93fb942b-38d0-4454-9ae8-daf2821868ec	5288642d-13e8-45b3-8f77-bcbff82a42c5	33		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vin_number	Confidential	Sales	Vin Number	The "Vin Number" is a unique, alphanumeric identifier for each vehicle within car sales data, essential for tracing ownership and transaction history; it serves as an industry standard reference crucial to enstyling the authenticity of motor vehicles. As defined by string type in Excel format on Sheet1: 'car_sales_data.xlsx', this column encapsulates vehicle identification numbers (VIN), which consist typically of 17 characters, including letters and numbers that provide a concise summary to distinguish each car's specific history and ownership details without the need for additional documentation or records search due to its distinctive nature as defined by industry norms.	ai_generated	\N	t	f	PsF03308986396	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
946b4cf0-112d-472f-b923-eb67f768790c	85eaf07b-2298-4658-baaa-a5e267c74812	15	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Classification	Confidential	\N	Classification	The "Classification" business term represents a categorical attribute denoting internal users of an organization's database, with string data type and typically stored as single entries like 'Internal', ensuring the identification of user roles related to sensitive information handling for enhanced data governance practices.	ai_generated	Category: Confidential, Internal, Public	f	t	Internal	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
95ae17be-e6d4-485c-bf01-e8df0a3ed17a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	4		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Last_Service_Days	Confidential	Service Prediction	Last Service Days	The "Last Service Days" represents the duration, measured in days as an integer value, since the last service was performed on a particular item within an AI analytics context; it helps track maintenance frequency to ensure optimal system performance and data integrity. For instance, with a sample value of 312, this indicates that over two months have passed without servicing which could signal potential issues needing attention.	ai_generated	\N	f	f	312	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
97a33c5c-1822-4919-80b5-14735dd5f403	5288642d-13e8-45b3-8f77-bcbff82a42c5	30		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			brand	Confidential	Sales	Brand	The "brand" represents a vehicle's manufacturer, typically recorded as text strings such as 'Honda', and it serves to identify which automobile company produced each car sold within an organization. This information is critical for tracking sales by source and understanding market preferences among different brands of vehicles the business operates in or intends to enter into.	ai_generated	\N	f	f	Honda	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
98c9e809-e261-4afb-8cee-392e4d7144b8	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	27	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Type	Confidential	\N	Loan Type	Loan Type is a VARCHAR data type field that categorizes different types of loans into distinct classifications such as auto, personal, and mortgage within the PRJ002_Risk_Scoring database to assess risk levels associated with lending activities accurately.	ai_generated	Category: Auto, Mortgage, Personal	f	t	Auto	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
99baf50f-fb2b-4fce-9eb0-34773292467f	5288642d-13e8-45b3-8f77-bcbff82a42c5	60		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			purchase_cost	Confidential	Stock	Purchase Cost	The business term "Purchase Cost" represents a financial figure associated with acquiring vehicles, quantified as an integer value within car_stock_data to facilitate data analysis and decision making regarding inventory investments. It directly impacts the company's gross margin calculations by accounting for significant capital expenditcur in asset management strategies.	ai_generated	\N	t	f	598922243	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
9d2a897b-ae8f-43e0-a884-cc465a68e4d0	85eaf07b-2298-4658-baaa-a5e267c74812	8	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Last_Updated	Confidential	\N	Last Updated	The "Last Updated" field represents a datetime value that records the most recent update time of data within the PRJ003_Data_Governance table, ensuring traceability and freshness for audit purposes. Its purpose is to track when exactly each record was last altered in compliance with organizational governance policies.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
9e012055-d8ab-4cde-908f-1efad5e229d0	5288642d-13e8-45b3-8f77-bcbff82a42c5	28		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			salesperson_name	Highly Confidential	Sales	Salesperson Name	The "Salesperson Name" represents a string field within the car sales data that identifies each individual responsible for selling vehicles, providing essential information about who achieved specific revenue figures during reporting periods and allows tracking of performance by name as well as facilitating accountability in customer interactions.	ai_generated	\N	t	f	Qori Simbolon	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
9f42b443-b12d-4e82-b9c3-a4067c3a4486	5288642d-13e8-45b3-8f77-bcbff82a42c5	6		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_brand	Confidential	Demand	Preferred Brand	The "Preferred Brand" business term refers to a car buyer's most favored automobile manufacturer, represented as text data within an Excel file used for tracking demand analysis. It captures consumer preference trends at the brand level and can vary from one individual or demographic group to another; thus it is critical in aligning market strategies with customer desires. The "Preferred Brand" column stores this information using string values, such as 'Mitsubishi', allowing for diverse brands representation without imposing a limit on the number of preferred options per respondent.	ai_generated	\N	f	f	Mitsubishi	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
9fb9c791-b8f6-4bf7-97dc-39701a9f6bc6	85eaf07b-2298-4658-baaa-a5e267c74812	26	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Classification	Confidential	\N	Classification	Classification refers to a textual data element representing the categorization of metadata within PRJ003_Metadata_Catalog, with possible values such as "Internal", indicating an internal classification system used for organizing project-related information based on its nature and confidentiality level. The business term 'Classification' is implemented as a string datatype to accommodate diverse categorization labels that facilitate data governance strategies like access control and compliance with organizational policies within the database context of PRJ0energys Metadata Catalog.	ai_generated	Category: Confidential, Internal, Public	f	t	Internal	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
9fd9c285-48c1-42c1-8cec-addfec5fee17	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	18		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Payment_Method	Confidential	\N	Payment Method	The "Payment_Method" represents how customers choose to settle their bills with a string value such as 'Transfer', indicating that they select this method for payments, typically involving the movement of funds from one account to another within an organization'in response to financial services and internal policies.	ai_generated	\N	f	f	Transfer	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
a0631a04-4426-4b34-9f1b-c781de4c0fea	5288642d-13e8-45b3-8f77-bcbff82a42c5	67		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			assigned_salesperson	Confidential	Stock	Assigned Salesperson	The "Assigned Salesperson" represents a unique string value that identifies an individual employee within the car dealership responsible for selling specific vehicles from stock, ensuring accountability and targeted customer service efforts. For example, assigning Chelsea Pratama as the salesperson for certain cars allows customers to know who will be assisting them personally with their purchase decisions based on that vehicle'selfs unique characteristics or availability within the dealership's inventory.	ai_generated	\N	t	t	Chelsea Pratama	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
a601aedb-7eb1-4e38-9fb8-9de3e7eb064e	347eb32e-4b25-4290-a1b6-f793b608c929	4	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	owner_email	Highly Confidential	\N	Owner Email	The email address of the individual or entity that is designated as the primary custodian of the record, used for identification, communication, and accountability purposes.	ai_generated	Category: owner1@example.com, owner2@example.com	t	t	owner1@example.com	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
a6080a2c-90fd-46f0-b07b-0c511ae537c6	85eaf07b-2298-4658-baaa-a5e267c74812	4	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Classification	Confidential	\N	Classification	The classification business term refers to an internal data label that designates and differentiates between various levels of sensitive information within a database, as designated by predefined categories such as 'Public', 'Confidential', 'Restricted'. This STRING field assists organizations in enforcing proper access controls based on the sensitivity level.	ai_generated	Category: Confidential, Internal, Public	f	t	Internal	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
ab7f5b7c-8213-447b-999a-1421e6db7c17	5288642d-13e8-45b3-8f77-bcbff82a42c5	24		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_notes	Confidential	Demand	Customer Notes	The Customer Notes field represents unstructured qualitative data collected directly from customers related to their feedback, comments, and experiences with car services; it holds textual information as individual strings without a fixed length format within the `car_demand_data` database table on Sheet1. These notes can provide valuable insights into customer satisfaction levels and areas for improvement in service delivery or product offerings.	ai_generated	\N	t	t	Quibusdam eveniet veniam molestias consectetur placeat animi repudiandae.	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
adad8af6-fbae-4c0f-a2aa-24a01db357d7	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	5		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Prediction_Service_Need	Confidential	Service Prediction	Prediction Service Need		ai_generated	\N	f	f	Soon	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
ae95fd6b-39ea-4db0-bbbe-183715a5a41a	85eaf07b-2298-4658-baaa-a5e267c74812	21	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Notes	Confidential	\N	Issue Notes	The "Issue Notes" are descriptive text entries documenting specific concerns regarding duplicate data instances, detailing their nature and impact on overall database integrity for PRJ003_Data_Quality within the Data Quality domain. These notes typically comprise a string of alphanumeric characters providing context or explanations needed to address quality issues in this column.	ai_generated	Category: Duplicate data, Missing fields, No issue, Validated	f	t	Duplicate data	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
afea0a01-afd9-4809-95ee-0af262b420a5	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	24	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Customer_ID	Confidential	\N	Customer Identifier	The Customer Identifier is a unique string value representing individual customers, used to identify and manage customer information within risk scoring systems for Project PRJ002_Risk_Scoring database file RiSco; it must be non-repeating across records with sample values in the format like 'CUST1000'.	ai_generated	Free text	t	t	CUST1000	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
b1470002-1e68-4ebf-83b3-b8de8ff8d7d8	85eaf07b-2298-4658-baaa-a5e267c74812	2	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Dataset_Name	Highly Confidential	\N	Dataset Name	The "Dataset Name" represents a string identifier for each dataset within an organization's data governance framework, serving as a unique reference to facilitate access and management of specific datasets relevant to business operations and analysis needs. It enables clear communication among stakeholders about the purpose or focus area associated with different sets of structured data related to customer information, financial records, sales analytics, etc.	ai_generated	Category: Customer, Inventory, Sales	f	t	Customer	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
b5bf773c-b45f-415b-aa3f-977057b0d367	5288642d-13e8-45b3-8f77-bcbff82a42c5	43		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			insurance_provider	Confidential	Sales	Insurance Provider	The "Insurance Provider" field represents the name of the company providing insurance for each vehicle sold, with data type string and example values such as Sinarmas. This information is critical to identify which insurer was involved in securing coverage for a particular car sale within an automotdependent economy where vehicles are essential goods due to their roles not only as modes of transportation but also as significant assets affecting national GDP through vehicle sales, production, and maintenance activities tied into the nation's economic health. The insurance provider column is especially important in this context because it directly impacts consumer confidence; a reliable insurer can increase trust in purchasing decisions within an economy heavily reliant on its automotive sector for both personal mobility and commercial transportation needs, which together drive GDP growth through the multiplier effect. This data type facilitates efficient processing of claims related to damages or accidents involving vehicles sold by dealerships that contribute significantly to local economies across different regions within a country with vast automotive markets like Germany, Japan's keiretsu-based businesses in car sales and maintenance provide the backbone for these nations' robust economic systems. Adequate insurance coverage is crucial not only from an individual consumer perspective but also as it affects overall market stability; ensuring that providers are accurately recorded helps maintain confidence levels which directly correlates with consistent spending habits across various automotive service sectors, thus sustaining the livelihood of millions who depend on these industries. In this context where insurance plays a critical role in economic and social well-being due to its direct impact on consumer behavior towards vehicle investments within nations like India experiencing rapid urbanization with increasing car ownership rates that fuel market demand for new sales, accurate tracking through database columns becomes essential; providers can be identified by unique strings which must align closely with official documentation such as the Insurance Regulatory and Development Authority of India's recognized databases to ensure consumer trust in data integrity. Accurate identification helps avoid fraud that could destabilize individual financial security, especially since vehicles are major assets for families within regions like South Asia where economic disparities exist; thus maintaining high accuracy standards through database columns ensures equitable treatment across socioeconomic strata and adherence to consumer protection laws.	ai_generated	\N	f	t	Sinarmas	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
b6edd389-0b24-4062-a04a-da18495e97b8	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	15		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Service_Notes	Confidential	\N	Service Notes	A database record captures textual comments on customer service interactions, which may indicate additional actions needed for follow-up purposes and other relevant details expressed by the service representative during a call with the client. This free-form entry assists the team to ensure continuity of care in servicing diverse client needs effectively.	ai_generated	\N	f	f	Follow-up required	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
b7ccd29c-d628-42c7-a982-1cc556f06a12	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	21	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Notes	Confidential	\N	Notes	The "Notes" business term within the PRJ002_Loan_Transactions table represents unstructured textual information provided by loan applicants, typically regarding their personal circumstances influencing financial decisions; stored as a VARCHAR data type to accommodate natural language entries such as incomplete documentation.	ai_generated	Category: Good profile, High risk, Incomplete docs, Verified	f	t	Incomplete docs	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
b8feb8ff-0a44-4aa9-b7ca-49a9ca8c1d6d	85eaf07b-2298-4658-baaa-a5e267c74812	19	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Last_Updated	Confidential	\N	Last Updated	The "Last Updated" field represents the most recent date and time that a record within PRJ003_Data_Quality database was modified, ensuring data accuracy through timestamps with a DATETIME type format such as 'YYYY-MM-DD HH:MM:SS'.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
b9f44d06-7848-4b92-839f-5c5d28b6c692	85eaf07b-2298-4658-baaa-a5e267c74812	28	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Quality_Score	Confidential	\N	Quality Score	The Quality Score is a numerical representation of data integrity, accuracy and reliability as reflected by its value within the range of [0 to 1], where 'FLOAT' denotes that it can handle decimal precision up to four places beyond the point for fractional values in SQL databases.	ai_generated	Decimal (2 decimal places)	f	t	0.89	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
ba0b8148-8dba-41e5-9d6e-af83975892c6	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	25		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Billing_Status	Confidential	\N	Billing Status	The "Billing Status" represents a record of an organization's transactions and is used to indicate whether bills have been paid, are overdue, on credit hold, etc., with each status being represented as text within the database for clarity and accessibility by users at various levels.	ai_generated	\N	f	f	Pending	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
bc3490b2-c7a6-4107-8f47-3f91e5975c03	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	19	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Risk_Level	Confidential	\N	Risk Level	"The 'Risk_Level' data type for PRJ002_Loan_Transactions represents a string value that categorizes each loan transaction based on its assessed risk, with possible values including 'Low', 'Medium', and 'High' to aid in the evaluation of creditworthiness."\n\nIn this definition: \n- "The data type for PRJ0носительные 'Risk_Level' represents a string value" ensures that Risk Level is understood as text.\n- "categorizes each loan transaction based on its assessed risk" indicates the purpose of the column, which relates to evaluating creditworthiness (a key aspect in lending).\n- The inclusion of possible values ('Low', 'Medium', and 'High') provides an idea about how Risk Level is quantified or described within this business context.	ai_generated	Category: High, Low, Medium	f	t	High	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
bd2f4cf4-3078-4d16-8819-1d027ce441a3	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	31	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Application_Date	Confidential	\N	Application Date	The "Application Date" represents the specific datetime when an application is submitted for risk assessment, with a data type of DATETIME and examples such as '2026-01-01 00:0CT'. It serves to chronologically organize submissions within PRJ002_Risk_Scoring.xlsx database records related to RiSco's risk scoring process, ensuring timely analysis and management of potential risks associated with each application date recorded in the system.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
be6f5a38-a03a-44dc-b4b5-d8ca8645d14b	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	27		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Transaction_Date	Confidential	\N	Transaction Date	The business term "Transaction Date" refers to the specific date when a billing transaction occurred for an item within inventory, represented as a DATE data type in database records like those found on Sheet1 of PRJ018_Inventory_Billing Excel file. For example, '2026-02-01' indicates that this was the date when goods were billed or debited from stock inventory during accounting processes.	ai_generated	\N	t	f	2026-02-01	DATE	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
bee18883-0f2c-48af-b64c-c731bd7b9229	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	33	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Score	Confidential	\N	Score	The "Score" represents a numerical risk assessment value for potential project risks, ranging from 0 to 1 (with higher values indicating greater risk). This data type is float as it can represent fractional probabilities and nuanced evaluations of risk severity or likelihood.	ai_generated	Decimal number	f	t	0.62	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
bf17210d-9027-4d64-8ac3-576c532c6691	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	14	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Age	Confidential	\N	Age	The business term "Age" refers to the age of an individual as represented by a numerical value, specifically recorded using integer data type for simplicity and ease of calculation within PRJ002_Loan_Transactions database table 'LoTrans'. The sample provided indicates that individuals involved in loan transactions are typically over 53 years old.	ai_generated	Integer (whole number)	f	t	53	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
bfdc069d-81b3-4c1d-a748-7c89ae882f18	5288642d-13e8-45b3-8f77-bcbff82a42c5	76		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			phone_number	Highly Confidential	Customer	Phone Number	Phone number is a string field representing a customer' end contact information, formatted as 'Country Code + Area Code + Local Number', and may optionally include an extension (e.g., "7980351886x82894"). It should validate for proper international format or local US number pattern with extensions if applicable.	ai_generated	\N	t	t	798.035.1886x82894	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c0b8fca5-5729-4d6d-9d39-1eb5ce72fa7a	85eaf07b-2298-4658-baaa-a5e267c74812	14	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Owner	Confidential	\N	Owner	The "Owner" is a string data field that identifies and specifies an individual, usually within an organization, who holds accountability for maintaining high quality of database entries as per the standards set forth in PRJ003_Data_Quality documentation. For instance: Owner = BI denotes that Business Intelligence team or member is responsible.	ai_generated	Category: BI, IT, Ops	f	t	BI	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
c1f9edca-f72a-4fdd-9752-0855f499b6e2	5288642d-13e8-45b3-8f77-bcbff82a42c5	4		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			phone_number	Highly Confidential	Demand	Phone Number	A phone number is a unique string value that represents an individual'self',s private, direct contact information used primarily for personal and professional communications within the car demand data context to track consumer needs based on geographic location via their mobile devices. The format typically follows regional dialing conventions with area codes included before local numbers but can also contain extensions when necessary, as evidenced by sample values like '284.999.6454x9229'.	ai_generated	\N	t	f	284.999.6454x9229	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c327ec04-e6a7-4da9-a9fb-bdf0ebef980c	5288642d-13e8-45b3-8f77-bcbff82a42c5	14		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			source_channel	Confidential	Demand	Source Channel	The 'source channel' within the car demand data represents how prospective customers first learn about new vehicle models, with a string value such as "Referral" indicating that potential buyers found out through word of mouth from existing owners or acquaintances. This column helps businesses understand and track customer acquisition trends over time to tailor marketing strategies effectively.	ai_generated	\N	f	f	Referral	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c3baaa26-5ea6-46cb-bc6b-7943c96b5c5c	5288642d-13e8-45b3-8f77-bcbff82a42c5	2		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			inquiry_date	Confidential	Demand	Inquiry Date	The Inquiry Date represents a specific point at which interest was expressed for vehicles within car demand data, recorded as datetime values to capture exact timestamps down to milliseconds since year 0 (e.g., "2025-02-04T00:00:00").	ai_generated	\N	f	f	2025-02-04 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c61f955f-76e7-45ba-9f2b-fe243a8205a8	5288642d-13e8-45b3-8f77-bcbff82a42c5	65		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			parking_zone	Confidential	Stock	Parking Zone	Parking zone refers to a designated area within a parking facility where vehicles are parked and managed, categorized as per their specific location for administrative purposes such as rent collection, attendance tracking, and maintenance scheduling; it is represented by a string value indicating the unique identification of each zone.	ai_generated	\N	f	f	Zone-2	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c6797462-593e-46d1-9ded-439c379db5a5	347eb32e-4b25-4290-a1b6-f793b608c929	2	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	brand	Confidential	\N	Brand	Brand identifies the official name of the vehicle manufacturer that markets the product (e.g., “Toyota”). It is a string value representing the brand under which the vehicle is sold.	ai_generated	Category: Honda, Hyundai, Toyota	t	f	Toyota	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
c6a8361f-ab0e-4592-88fc-4f6ae026e7ce	5288642d-13e8-45b3-8f77-bcbff82a42c5	10		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			fuel_preference	Confidential	Demand	Fuel Preference	Fuel preference represents a car owner's choice of fuel type for their vehicle, expressed as strings such as "Gasoline", "Diesel", "Electric". This data helps businesses understand consumer trends and tailor products to meet market demands. The acceptable string values are limited based on the current range of popular or available options in the automotdependent industry at a specific point in time, such as ["Gasoline", "Diesel", "Electric"] during an era when hybrid vehicles were less prevalent and considered niche products with no established consumer preference.\n\n \nFuel Preference: A column designed to catalog car owners' choices for the type of fuel their vehicle runs on, primarily as strings but potentially allowing alternative data types if industry changes make it necessary (e.g., numerical identifiers or codes corresponding to specific non-traditional fuels). It reflects consumer inclination towards different propulsion systems and can guide strategic decisions in product development, marketing efforts, and infrastructure investments based on prevalent trends within the automotive sector.\n\n \nFuel Preference: This data field captures consumers' choices of fuel for their vehicles as strings like "Petrol", "Diesel", or identifiers such as numerical codes representing specific alternative fuels (e.g., biofuels), reflecting the broader market demand and assisting in targeted business intelligence analyses to meet customer needs effectively, ensuring alignment with evolving industry standards including hybrids and electric vehicles within a given temporal context that records these trends accurately as they develop over time due to advancements or regulatory changes.\n\n \nFuel Preference: A string-based column in the automotive data repository captures individual preferences for vehicle fuel types, categorized into conventional options (e.g., Gasoline) and emerging technologies at a specific juncture of their market adoption; it serves as an essential metric by which businesses can track consumer behavior patterns towards sustainable transportation alternatives in light of environmental considerations driving industry innovations like electric or hydrogen-fueled vehicles.	ai_generated	\N	f	f	Electric	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c6fb84b5-1127-4995-a359-93bbe47069c8	85eaf07b-2298-4658-baaa-a5e267c74812	11	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Approval_Status	Confidential	\N	Approval Status	Approval status refers to a record indicating whether access permissions have been granted for specific data, where 'approved' means that appropriate authorities within an organization have given consent for such access. This is represented as textual information of varying length up to several hundred characters long and stores the finalized state after any required internal or external reviews.	ai_generated	Category: Approved, Pending, Rejected	f	t	Approved	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
c845479f-4a7f-4e7b-9afb-8bcb51a410a2	5288642d-13e8-45b3-8f77-bcbff82a42c5	32		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vehicle_year	Confidential	Sales	Vehicle Year	Vehicle Year represents a specific calendar year associated with car transactions, stored as an integer value indicating when production occurred; for instance, entry of "2025" signifies that cars produced and sold were manufactured during the said year. This data is essential for tracking sales trends over time within vehicle markets.	ai_generated	\N	f	f	2025	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
c87d9a34-1d71-4f79-8a00-cfa5b83a129d	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	16	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Type	Confidential	\N	Loan Type	The business term "Loan Type" refers to a categorical variable within PRJ002_Loan_Transactions that describes whether the loan is secured, unsecured, personal, commercial, student, etc., with each record holding this information as text data representing various types of loans.	ai_generated	Category: Auto, Mortgage, Personal	f	t	Auto	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
c99746c9-f08c-4b24-a833-19a8bbe8c90d	347eb32e-4b25-4290-a1b6-f793b608c929	1	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	vehicle_id	Confidential	\N	Vehicle Identifier	A unique alphanumeric code that identifies each vehicle within the organization, enabling consistent reference across all applications and reports. The identifier follows a standard format, for example, “CAR-001”.	ai_generated	Category: CAR-001, CAR-002, CAR-003	t	f	CAR-001	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
c9d4e85b-4856-4784-9df4-dfb4e35cf8dc	347eb32e-4b25-4290-a1b6-f793b608c929	16	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	acceleration	Confidential	\N	Acceleration	The time, expressed in seconds, required for the vehicle to accelerate from a standstill to 60 miles per hour.	ai_generated	Free text	f	f	12	STRING	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
ca502f7e-0e94-457f-8e15-ac87f926fc39	5288642d-13e8-45b3-8f77-bcbff82a42c5	37		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			transmission	Confidential	Sales	Transmission	The "transmission" represents a string data type that records whether a car has an automatic, manual, or other transmission system and serves as identifying information for vehicle specifics within sales transactions. It is expected to contain standardized terms like 'Automatic', with optional variations if applicable (e.g., semi-automatic).	ai_generated	\N	f	f	Automatic	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
ca5972cd-71e1-41fd-ad2f-0d1a27cdae9a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	14		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Service_Type	Confidential	\N	Service Type	The 'Service Type' business term refers to a categorical attribute within customer service data that designates whether an interaction was for repair services, general assistance, information query, or other specific types of support; this is represented as string values such as "Repair," with the purpose being classification and easy retrieval during analysis.	ai_generated	\N	f	f	Repair	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
cb3787f7-2900-4cad-80fa-d75ae86f18a9	85eaf07b-2298-4658-baaa-a5e267c74812	10	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Notes	Confidential	\N	Issue Notes	Issue notes represent textual descriptions of specific problems identified within a dataset, typically capturing details like errors, inconsistenries, and areas needing attention for data governance purposes. These are usually stored as strings to accommodate various types of qualitative information that may require nuanced expression beyond numerical codes or simple Boolean values.	ai_generated	Category: Duplicate data, Missing fields, No issue, Validated	f	t	Duplicate data	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
cbac7647-25a3-4e87-a3b8-9659f0f3f7bc	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	17		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Dealer_Code	Confidential	\N	Dealer Code	The "Dealer Code" within PRJ018_Customer Service data represents a unique alphanumeric identifier assigned to each dealer, signifying their specific entity for transactions and communications with customers (Sample Value: DLR03). It serves as the primary key linking customer service activities directly back to individual dealers.	ai_generated	\N	f	f	DLR03	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
cc3ef378-72af-46b3-92b3-b34336cb5c20	5288642d-13e8-45b3-8f77-bcbff82a42c5	7		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_model	Confidential	Demand	Preferred Model	The "Preferred Model" is a string data type representing car buyers' most desired vehicle model, with entries such as 'Xpander'. This information assists businesses to understand market demand and tailor production accordingly.	ai_generated	\N	f	f	Xpander	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
cd00e679-cf93-456c-a942-4dbbbe98d1da	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	26		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Billing_Notes	Confidential	\N	Billing Notes	Billing notes represent textual information describing details regarding each billing transaction, typically capturing status such as "Paid on time," and are stored as strings within a company's accounting system to provide context for financial activities associated with inventory management.	ai_generated	\N	f	f	Paid on time	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
ce08a9ba-a4c8-44ff-93e4-cfeeaba8c20e	5288642d-13e8-45b3-8f77-bcbff82a42c5	17		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			test_drive_requested	Confidential	Demand	Test Drive Requested	The "Test Drive Requested" field records whether a potential customer has requested to take a test drive of a vehicle, with data type as string and sample values such as 'Yes' for those who have requested and 'No' for others. It plays a crucial role in understanding the car demand at dealerships by providing direct insight into customers’ intentions towards trying out specific models before making a purchase decision.	ai_generated	\N	f	f	No	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
d0caadc8-9ded-440d-9df8-af134562a219	5288642d-13e8-45b3-8f77-bcbff82a42c5	39		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			discount_amount	Confidential	Sales	Discount Amount	The "Discount Amount" represents a monetary value, specifically an integer amount denoting dollars saved by customers during car sales transactions. For example, if a customer receives $50 off on the listed price of their chosen vehicle due to promotions or discounts applied at the point-of end sale process in Excel's 'car_sales_data.'xlsx - Sheet1 document file format.	ai_generated	\N	t	t	21008061	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
d1e41187-357b-414a-9eef-05741dfd5086	5288642d-13e8-45b3-8f77-bcbff82a42c5	93		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			credit_score	Confidential	Customer	Credit Score	A Credit Score is an integer representing a customer'ner creditworthiness, based on their financial history and behavior; it ranges from typically around 300 to 850 (though this can vary by scoring model) with higher values indicating better scores which reflect lower risk.	ai_generated	\N	f	f	801	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
d443c530-c5b0-4eac-836c-d76d1d1b15b0	5288642d-13e8-45b3-8f77-bcbff82a42c5	11		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			transmission_preference	Confidential	Demand	Transmission Preference	Transmission preference represents a vehicle user's chosen type of transmission, such as "Automatic," and is stored as a string data type within the car_demand_data database for tracking consumer preferences related to vehicular features affecting overall demand patterns. This column helps in understanding market trends and guiding product development strategies accordingly.	ai_generated	\N	f	f	Automatic	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
d4734a33-f968-4f37-9141-3a69fa8d52cd	85eaf07b-2298-4658-baaa-a5e267c74812	27	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	PII_Flag	Confidential	\N	Pii Flag	The PII Flag indicates whether a record contains personally identifiable information (PII) by using a string value, where "Yes" represents records with PII and "No" denotes their absence. This binary flag assists organizations in quickly assessing the privacy sensitivity of metadata entries within the PRJ003_Metadata_Catalog spreadsheet.\n\n\n**Revised Definition:** The business term 'PII Flag' for a database column is designed to identify if personally identifiable information (PII) such as names, addresses, or social security numbers are present in each record of an Excel file representing metadata within the PRJ0self_MetadataCatalog. This indicator uses two-character string values: "Yes" signifies that PII data exists and must be treated with enhanced privacy controls due to its sensitive nature; conversely, a value of "No" confirms no such personal information is found in the record, potentially qualifying for more lenient handling. This column assists compliance teams by applying different security protocols based on PII content presence and ensures adherence to data protection regulations like GDPR or HIPAA when processing metadata entries linked directly with individuals' identities within project-related documents managed through the spreadsheet system.	ai_generated	Boolean (Yes/No or True/False)	f	t	No	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
d5c6a10c-1c58-4960-80ef-95c3c2548210	5288642d-13e8-45b3-8f77-bcbff82a42c5	59		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			stock_status	Confidential	Stock	Stock Status	The "Stock Status" is a string field representing whether vehicles are currently available for sale (e.g., 'Available'), reserved but yet to be delivered ('Reserved, In Transit', etc.), or no longer active on the marketplace ("Out of Stock"). It helps businesses manage their inventory by indicating each vehicle's current availability state at any given time.	ai_generated	\N	f	f	In Transit	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
d65a3d38-547a-4cae-83f5-84d4c31766ce	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	25	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Age	Confidential	\N	Age	The "Age" business term represents an individual's age as a measure used for risk assessment, stored as an integer data type with values such as 39 representing years old individuals within the dataset. This numeric attribute plays a crucial role in evaluating project risks based on demographic factors of team members or stakeholdner age groups.	ai_generated	Integer (whole number)	f	t	39	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
d7e7cb6f-7497-4977-9064-adda39aaedd9	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	22		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Item_Description	Confidential	\N	Item Description	The business term "Item Description" refers to a specific textual representation of an item' end attributes within the inventory billing context, typically describing physical characteristics and function; it is stored as a string data type which can accommodate values such as 'Oil Filter'. This description serves both informational needs for internal tracking and fulfillment requests.	ai_generated	\N	f	f	Oil Filter	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
da33d0e6-35cc-435a-bd42-070fcb51599f	347eb32e-4b25-4290-a1b6-f793b608c929	12	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	cylinders	Confidential	\N	Cylinders	The total number of engine cylinders in a vehicle, representing the engine’s configuration and influencing its power and displacement.	ai_generated	Category: 3, 4, 6, 8	f	f	8	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
da91a17a-1a61-430f-85f8-96420e6b92f5	5288642d-13e8-45b3-8f77-bcbff82a42c5	69		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			gps_tracking_id	Confidential	Stock	Gps Tracking Identifier	The GPS Tracking Identifier is a VARCHAR data type used to uniquely identify individual vehicles within the car_stock_data database, ensuring precise tracking and management of vehicle locations for inventory purposes. For example, `fda7cfe5-9997-4ff1 endowment funds often rely on accurate financial reporting that aligns with regulatory requirements and investor transparency standards; write a clear definition in one sentence incorporating the following aspects:\n\nTable Name: fund_contributions.xlsx - Sheet2\nColumn Name: donor_id\nBusiness Term: Contributor Identifier (CID)\nData Type: INTEGER UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, referencing an external 'donors' table for validation and maintaining data integrity. The CID is assigned to each individual or entity making a contribution towards fundraising efforts endowment funds without disclosing personal information beyond the necessary identification scope;\nSample Value: 123456 (This value would dynamically generate on insertion but should be presented as an example.)	ai_generated	\N	t	f	fda7cfe5-9997-4ff1-88a6-a5ba994b31c2	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
dbbc52f0-079b-4852-84c6-d171fd69acb6	85eaf07b-2298-4658-baaa-a5e267c74812	31	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Flag	Confidential	\N	Issue Flag	The "Issue Flag" is a string field within PRJ003_Metadata_Catalog that indicates whether there's an issue with the associated record, where 'No' signifies no issues present and other values represent different statuses of identified problems or concerns related to data quality.	ai_generated	Boolean (Yes/No or True/False)	f	t	No	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
dbdb947e-ebc6-4209-ba20-eb8ba76293bd	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	15	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Income	Highly Confidential	\N	Income	Income represents a loan transaction's revenue as an integer, signifying money earned from interest or fees during one financial period; for example, Income may record transactions with values such as 5,482,900 where negative amounts would indicate loss instead of earnings.	ai_generated	Phone number	t	t	5554829	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
dc05d4bf-b87f-4ed2-b395-d5a626e8121c	5288642d-13e8-45b3-8f77-bcbff82a42c5	20		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			assigned_salesperson	Confidential	Demand	Assigned Salesperson	The "Assigned Salesperson" field records a unique identifier, typically an employee's name within the organization responsible for handling and selling cars as represented by the sample value 'Cinthia Wijaya'. The data type is string to accommodate textual information relevant to personnel identification.	ai_generated	\N	t	f	Cinthia Wijaya	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
de406088-07c7-45ec-b32c-e557210a7d8e	5288642d-13e8-45b3-8f77-bcbff82a42c5	54		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vin_number	Confidential	Stock	Vin Number	The Vin Number, as a string data type within car_stock_data table on Sheet1, serves as an alphanumeric identifier unique to each vehicle for inventory management and compliance tracking purposes. A typical sample value is 'Giu34348697388'.	ai_generated	\N	t	f	Giu34348697388	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
de47ca30-8bb4-45ea-81f8-e75188c9890d	347eb32e-4b25-4290-a1b6-f793b608c929	3	Astra International – Digital Transformation Division	Codex_Metadata_E2E_1779269536461	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	model_year	Confidential	\N	Model Year	The model year denotes the calendar year in which a vehicle model was first introduced or designated by the manufacturer.	ai_generated	Category: 2024, 2025, 2026	t	f	2024	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:32:54.381673+00	3	2026	\N
de52632f-68f2-4b27-b77f-b8f97432bf34	5288642d-13e8-45b3-8f77-bcbff82a42c5	83		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			postal_code	Confidential	Customer	Postal Code	The "Postal Code" field represents a unique geographical code assigned to an address by postal authorities, typically stored as an INTEGER within customer_data table on Sheet1 for efficient querying and indexing purposes; Sample values are numeric representations of these codes such as '44048'.	ai_generated	\N	t	f	44048	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
dfd7208a-7a78-4a31-b386-f5fbb15941a0	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	7	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Status	Confidential	\N	Loan Status	Loan status is a string attribute that indicates whether an individual'thelp application for financial assistance has been approved, denied, pending review, or withdraenknown; it serves as a critical indicator of the outcome and next steps within credit assessment processes. Sample values include "Approved," "Rejected," "Pending Review," among potentially others that signal different stages in loan approval workflows.	ai_generated	Category: Approved, Pending, Rejected	f	t	Rejected	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
e07a0945-eebb-4031-8490-bd16a760afac	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	17	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Amount	Confidential	\N	Loan Amount	The business term "Loan Amount" represents the integer value indicating the principal sum disbursed to a borrower under a loan agreement within PRJ002_Loan_Transactions table, with values like 86156168 representing the actual dollar amount owed.	ai_generated	Phone number	t	t	86156168	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
e09f48c4-dcb3-4caa-88c0-5c6f16971b3a	85eaf07b-2298-4658-baaa-a5e267c74812	12	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Record_ID	Confidential	\N	Record Identifier	The "Record Identifier" serves as a unique string identifier within the database, which functions to pinpoint and reference specific records for quality assessment purposes without revealing sensitive information; its value is formatted like 'PRJ003_2_0'. It ensures each entry can be individually examined while maintaining privacy.	ai_generated	Free text	t	t	PRJ003_2_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
e1adaac0-6454-495b-bace-c74b95533b49	5288642d-13e8-45b3-8f77-bcbff82a42c5	63		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			stock_age_category	Confidential	Stock	Stock Age Category	The "Stock Age Category" is a database attribute designed to classify vehicles based on how long they have been held by the dealership, with categories such as "New," "Fresh," and "Slow Moving." This categorization assists business operations like inventory management, sales strategy development, and stock rotation planning.	ai_generated	\N	f	f	Slow Moving	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
e1fb7ef2-bfba-44fb-8143-08bf09f9aa69	5288642d-13e8-45b3-8f77-bcbff82a42c5	42		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			bank_financing	Confidential	Sales	Bank Financing	Bank financing refers to a string attribute representing financial assistance provided by banks for car purchases, exemplified by values such as "ACC". It is crucial for tracking and analyzing the extent of bank involvement in vehicle sales within an automotthetic organization's database.	ai_generated	\N	f	t	ACC	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
e59bdaba-c0a8-4fe7-9972-4a779650b1ce	5288642d-13e8-45b3-8f77-bcbff82a42c5	71		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			first_name	Highly Confidential	Customer	First Name	The "First Name" is a VARCHAR data type that holds an individual's given name and can consist of characters such as letters, hyphens, and apostrophes; for instance, the first entry 'Amanda'. This field serves to uniquely identify customers within our database while providing personalized interaction points.	ai_generated	\N	f	f	Amanda	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
e7d3ebbe-cdff-44c1-b2d0-e3786868d2f9	5288642d-13e8-45b3-8f77-bcbff82a42c5	49		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			dealer_name	Highly Confidential	Stock	Dealer Name	The "Dealer Name" is a string data type field representing the name of the car dealer, such as "Borneo Cars", found within the 'car_stock_data' Excel sheet under Sheet1. This entity identifies businesses or individuals who sell cars in various markets and allows for tracking their inventory levels.	ai_generated	\N	f	f	Borneo Cars	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
e8d45d77-4a35-45e0-b30a-7a61a08baaf5	85eaf07b-2298-4658-baaa-a5e267c74812	20	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Flag	Confidential	\N	Issue Flag	The "Issue Flag" is a string data type field that indicates whether there's an identified issue with data quality within its corresponding record, where 'No' suggests no issues are present.	ai_generated	Boolean (Yes/No or True/False)	f	t	No	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
e97ebc6c-3739-4dff-96c7-e76a1a44a88f	5288642d-13e8-45b3-8f77-bcbff82a42c5	9		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			budget_range	Confidential	Demand	Budget Range	The "Budget Range" is a business term within the car_demand_data representing potential spending limits for acquiring new vehicles, expressed as string values such as '100M-20 end user's ability to afford different budgets when purchasing cars. It provides an understanding of market segments that can be targeted based on financial capability and aids in customizing sales strategies accordingly.	ai_generated	\N	f	f	100M-200M	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
ea04cd0c-7c9a-457d-b56a-39937fb44d18	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	10	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Notes	Confidential	\N	Notes	The "Notes" business term within Table 'CreProf' is a VARCHAR field that stores textual descriptions and observations about an individual’ endorsed by credit reporting agencies, with the sample value being indicative of positive remarks on one's financial reliability or profile.	ai_generated	Category: Good profile, High risk, Incomplete docs, Verified	f	t	Good profile	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
ea6403b4-115a-42a1-b623-796c308ad3be	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	20	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Application_Date	Confidential	\N	Application Date	The application date refers to the specific point in time when a loan application was submitted, recorded as a datetime value without any associated header or table name; for example, "2026-01-01T00:0 end of business day." This column enables tracking and analyzing temporal patterns related to financial services.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
eba5ab3e-ddcc-4a87-a86f-233c42c2acb6	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	9	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Application_Date	Confidential	\N	Application Date	The business term "Application Date" refers to the specific date on which an individual's credit application was submitted for review and assessment within a database designed to track their financial history, with its data type being DATETIME representing any valid point-independent calendar dates along with time components. A sample value provided is 2026-01-01T00:0носити 00:00:00Z, illustrating the expected format for entries without specifying exact hours or timezone information due to their standardized nature within this contextual framework.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01 00:00:00	DATETIME	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
ebd53e42-f4a7-48ea-a9b0-25fea96afc8b	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	29	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Status	Confidential	\N	Loan Status	A loan status indicates whether a particular financial application for credit approval has been accepted, rejected, approved pending additional information (such as income verification), denied due to insufficient collateral size, declined because of high risk factors involved, and remains on hold awaiting further review or documentation. The data type is string with sample values including "Rejected," representing a financial application that was not successful in obtaining approval for the loan based on its initial assessment within PRJ002_Risk_Scoring database table RiSco.	ai_generated	Category: Approved, Pending, Rejected	f	t	Rejected	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
ed57c81f-ff48-42e1-bdda-ae06fc2512c7	5288642d-13e8-45b3-8f77-bcbff82a42c5	84		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			occupation	Confidential	Customer	Occupation	An "Occupation" is a textual field within customer data that categorizes individuals based on their profession; it uses alphanumeric characters and often includes commas for readability, such as Surveyor, building control, to aid business analysis concerning workforce demographics or market segmentation.	ai_generated	\N	f	f	Surveyor, building control	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
edc8f6ae-12c0-47e1-a661-063248dc3ad1	85eaf07b-2298-4658-baaa-a5e267c74812	33	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Approval_Status	Confidential	\N	Approval Status	The "Approval Status" is a string field that captures whether project metadata has been approved, pending approval, or rejected within an organization's review system for managing and tracking the progress of projects through various stages of validation and consent processes before finalization into records in their repository.	ai_generated	Category: Approved, Pending, Rejected	f	t	Rejected	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
ee096d5e-969a-4ca2-ba92-ecc75480019b	5288642d-13e8-45b3-8f77-bcbff82a42c5	85		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			company_name	Highly Confidential	Customer	Company Name	The "company name" represents the official registered business name of a customer and serves as an identifier for organizational affiliation within our records, accommodating up to 50 characters with values such as "Sampson Ltd." It is crucial for maintaining accurate corporate relationships in dealings.	ai_generated	\N	t	t	Sampson Ltd	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
ee3d993b-24a3-4caf-a303-38e1fa1225b3	5288642d-13e8-45b3-8f77-bcbff82a42c5	27		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			dealer_name	Highly Confidential	Sales	Dealer Name	Dealer name refers to a textual identifier for an automotdependent entity that deals with car sales, represented as strings within our database's 'car_sales_data' table under the business term "dealer name." The data type is string and can include example values such as Mega Auto.	ai_generated	\N	f	f	Mega Auto	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
eee68041-afea-4fbb-a3d9-33257a40b30f	5288642d-13e8-45b3-8f77-bcbff82a42c5	21		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			lead_score	Confidential	Demand	Lead Score	The "Lead Score" represents a numerical evaluation assigned to potential customers, indicating their likelihood of converting into paying clients based on various factors like demographic information and interactions with marketing efforts. This score is an integer value that helps prioritize leads for sales follow-inquiries within the car dealership database context.	ai_generated	\N	f	t	94	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
ef45a823-82f5-4104-929e-2314fedf6d9a	5288642d-13e8-45b3-8f77-bcbff82a42c5	34		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			engine_number	Confidential	Sales	Engine Number	The 'Engine Number' represents a unique identifier for an engine within car sales data, stored as a string to accommodate alphanumeric values and standardized formats, such as ENG34262. This information is used for tracking specific engines throughout the database lifecycle but does not directly relate to performance metrics or characteristics of the vehicle itself.	ai_generated	\N	t	f	ENG34262	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
f241de9b-93b9-4f30-82bb-9fad83d04ab4	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	19		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Transaction_ID	Confidential	\N	Transaction Identifier	Transaction Identifier is a unique string within PRJ018_Inventory_Billing that serves as an identifier for each billing entry, ensding traceability and referencing capabilities; example values range from 'TRX2000' to 'TRXXXXX'. The data type of this column must be VARCHAR or CHAR(n), where n is the maximum length expected based on business requirements.	ai_generated	\N	t	f	TRX2000	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
f2b21e2b-dc08-4d44-9f83-053903711725	5288642d-13e8-45b3-8f77-bcbff82a42c5	64		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			inspection_status	Confidential	Stock	Inspection Status	The "Inspection Status" is a string data field within the car stock dataset that indicates whether each vehicle has been inspected, with potential values including 'Pending', 'Completed', and 'Cancelled'. It plays a crucial role in tracking maintenance status for inventory management purposes.	ai_generated	\N	f	f	Pending	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
f3ab3f4f-0293-4cf7-b724-b62ed9459e2d	5288642d-13e8-45b3-8f77-bcbff82a42c5	62		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			days_in_stock	Confidential	Stock	Days In Stock	The "Days In Stock" represents a count of days that individual car units have been available for sale, recorded as an integer value representing each day from when they were added to inventory until sold or removed without selling; this metric helps track and manage the age distribution within stocked vehicles.	ai_generated	\N	f	f	47	INTEGER	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
f4eccce7-5b76-4b92-8394-d12c0eb4cda7	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	22	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Score	Confidential	\N	Score	The "Score" represents a floating-point numerical value assigned to each loan transaction, reflecting an evaluation metric such as creditworthiness, with values ranging up to but typically below one. This data type allows for decimal precision necessary for nuanced assessments within the financial context of these transactions.	ai_generated	Decimal number	f	t	0.99	FLOAT	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
f603f7bc-ffa9-4f26-a00c-2d41c33c9d9d	5288642d-13e8-45b3-8f77-bcbff82a42c5	58		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			transmission	Confidential	Stock	Transmission	A manual transmission is a type of vehicle drivetrain where the driver manually shifts gears using a clutch pedal, as opposed to an automatic transmission which performs this task automatically without driver intervention. This data attribute represents whether each car listed has a manual or automated drive system and helps in categorizing them for inventory purposes, impacting potential customer preferences towards specific drivetrain types during sales strategies and market analysis within the organization's scope of business operations centered on vehicle stock management and sale optimization.	ai_generated	\N	f	f	Manual	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
f7190501-11a9-4d24-a5e5-70f2a0d4a8d6	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	23	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	ID	Confidential	\N	Identifier	The "RiSco" database stores project risk scores using a unique identifier, represented as a string data type for each record, ensuring distinct and traceable reference within the context of PRJ002_Risk_Scoring table. For example, an entry might be assigned the value 'PRJ002_2_0' to represent its specific risk score uniquely in this systematic approach.	ai_generated	Free text	t	t	PRJ002_2_0	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
f7c0cf6d-c0d3-44c4-92c5-9c20aea1d08b	5288642d-13e8-45b3-8f77-bcbff82a42c5	35		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			color	Confidential	Sales	Color	The business term "Color" represents a categorical attribute describing the exterior paint of vehicles sold, with sample values such as 'Blue'. This data is stored as text strings within the car_sales_data Excel spreadsheet to accommodate different color options available for sale.	ai_generated	\N	f	f	Blue	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
f7cf0f8f-18a9-43ea-97f2-e6eb2479f835	5288642d-13e8-45b3-8f77-bcbff82a42c5	8		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_color	Confidential	Demand	Preferred Color	The 'Preferred Color' represents a customer attribute indicating their most preferred color for cars, with string values such as "Black" denoting individual preferences within the car demand data set. This information can be used by dealerships to tailor marketing efforts and inventory towards popular colors sought after in vehicle purchases.	ai_generated	\N	f	f	Black	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
f9a8ac94-3d30-41d6-9003-01a23c742ba7	5288642d-13e8-45b3-8f77-bcbff82a42c5	88		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_brand	Confidential	Customer	Preferred Brand	The "Preferred Brand" is a string attribute within the customer_data table that captures customers' preferred vehicle brands, with sample entries including specific brand preferences such as Mitsubishi for certain individuals. This data helps businesses tailor their marketing and sales strategies towards target demographics based on their most favored auto manufacturers.	ai_generated	\N	f	f	Mitsubishi	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
fa0e915b-e41f-43ce-ad62-2c081228ffe6	347eb32e-4b25-4290-a1b6-f793b608c929	15	Astra International – Digital Transformation Division	Automobile	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026	Andika Pratama Wijaya <andika.wijaya@astra-group.co.id>	Rina Maharani Putri <rina.putri@astra-group.co.id>	weight	Confidential	\N	Weight	The total weight of the automobile, measured in pounds, indicating the vehicle’s overall mass.	ai_generated	Integer (whole number)	f	f	3504	INTEGER	Raw	2026-05-20	Super Administrator <admin@governance.local>	-	excel	2026-05-20 09:40:41.557752+00	398	2026	\N
fb869d37-e5bc-476a-903e-4ced1ced2540	5288642d-13e8-45b3-8f77-bcbff82a42c5	87		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			marital_status	Confidential	Customer	Marital Status	Marital status refers to a single character field that indicates an individual' end state of marriage, with possible values such as 'Single', representing individuals who are unmarried; this data is used for demographic analysis and personalized marketing strategies within the customer_data database. The business term "Marital Status" aligns closely with societal constructs related to partnerships and can impact purchasing behavior, thus providing valuable insights into consumer segmentation based on life stage or commitment statuses.	ai_generated	\N	f	f	Single	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
fe3d72cb-60ba-4302-b83c-be2b69900326	5288642d-13e8-45b3-8f77-bcbff82a42c5	25		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sales_id	Confidential	Sales	Sales Identifier	A "Sales Identifier" serves as a unique string identifier within the car sales data, used to track and reference each individual sale transaction without revealing sensitive information about customers or products involved in the sale. The format adheres strictly to alphanumeric strings starting with 'SALE' followed by a sequence of numbers reflecting the chronological order of transactions; for example, SALE000001 indicates the first recorded car sales event within this dataset.	ai_generated	\N	t	f	SALE000001	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
ffda456d-8d53-4b5b-97e3-e99bea1a132c	5288642d-13e8-45b3-8f77-bcbff82a42c5	29		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_id	Confidential	Sales	Customer Identifier	A "Customer Identifier" is a unique string field within the car sales database that serves as an identifier for each customer, ensidered to be confidential and essential for tracking purchase history and preferences. Its data type must accommodate various alphanumeric formats while maintaining consistent length across all records for effective data governance practices.	ai_generated	\N	f	f	CUST01188	STRING	Raw	2026-05-19	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	100	\N	\N
\.


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification_preferences (id, user_id, module, in_app, email) FROM stdin;

\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, user_id, module, event, title, body, entity_type, entity_id, is_read, created_at) FROM stdin;

\.


--
-- Data for Name: project_source_files; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.project_source_files (id, project_id, source_type, original_filename, stored_path, file_size, uploaded_at, uploaded_by) FROM stdin;

\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.projects (id, project_name, created_by, created_at, updated_at, customer_name, line_of_business, use_case, project_year, project_category, is_monetized, delivery_manager_id, project_manager_id, dgo_id, metadata_officer_id, dq_officer_id, pic_data_compliance_id, start_date, end_date, project_code, sme_id) FROM stdin;
0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	Enterprise Data Integration Platform Implementation	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-19 03:17:28.948382+00	2026-05-19 03:17:28.948382+00	Astra UD Trucks	Automotive Distribution & After Sales	Implementation of enterprise data integration solution to consolidate operational data from Dealer Management System (DMS), after sales, inventory, billing, and customer service applications into centralized reporting and analytics platforms. The project includes ETL pipeline development, API integration, data mapping standardization, and automated data synchronization processes.	2026	Integration	t	89efb71c-c9f1-4224-8fa5-ae4b5e211402	13c686f6-db44-4585-b9f1-6c6200aac025	8216e50c-c627-469d-a696-1e91285f5aab	4908c50c-2a1d-4ab5-8a1c-68965e49ba47	4908c50c-2a1d-4ab5-8a1c-68965e49ba47	336b5420-9af0-49de-b844-e42ee6658cd4	2026-03-03	2026-10-28	PRJ-2026-018	4a1a48b4-55b2-4ed4-84a8-ae84851e870d
347eb32e-4b25-4290-a1b6-f793b608c929	Customer 360 Analytics and Personalization Platform	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-20 07:29:07.49258+00	2026-05-20 07:29:07.49258+00	Astra International – Digital Transformation Division	Retail & Automotive Ecosystem	Develop a Customer 360 platform that integrates data from multiple sources, including sales, after-sales, and customer interaction systems, into a unified analytics environment. The solution leverages AI/ML models to generate insights such as customer segmentation, behavior prediction, and personalized recommendations to support business decision-making. All data processing is conducted within a secure and governed environment, with appropriate controls such as pseudonymization, access restriction, and compliance with applicable data protection regulations.	2026	AI / ML	t	89efb71c-c9f1-4224-8fa5-ae4b5e211402	13c686f6-db44-4585-b9f1-6c6200aac025	8216e50c-c627-469d-a696-1e91285f5aab	8216e50c-c627-469d-a696-1e91285f5aab	8216e50c-c627-469d-a696-1e91285f5aab	f961edea-0a7a-4f6c-8738-098f640b6dc8	2026-02-15	2026-11-30	PRJ-2026-004	4a1a48b4-55b2-4ed4-84a8-ae84851e870d
40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	Smart Credit Risk Analytics Platform	13c686f6-db44-4585-b9f1-6c6200aac025	2026-03-01 01:00:00+00	2026-03-01 01:00:00+00	PT Finansial Nusantara	Financial Services	Develop an AI-powered credit risk scoring model leveraging customer financial behaviour, transaction history, and external credit bureau data to improve loan approval accuracy and reduce default rates across retail banking portfolios.	2026	AI / Machine Learning	t	13c686f6-db44-4585-b9f1-6c6200aac025	9af488f8-db30-4b90-a672-c1ec50f45c85	c8cf883c-330c-46c0-b023-3629c2f99a69	facd7d45-6237-46a9-8015-507fe266c7ff	19d275fc-8c44-4411-a412-92a85834759b	1b6e6cdf-4700-4914-81cf-29f7e768c523	2026-03-01	2026-12-31	PRJ-2026-002	4aa61e37-f659-44ae-810b-41d4ac793b26
5288642d-13e8-45b3-8f77-bcbff82a42c5	AI-Powered Customer Analytics Platform	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-01-05 09:00:00+00	2026-05-05 08:48:11.221111+00	PT Maju Bersama Digital	Digital Banking	Leverage generative AI to analyze customer transaction patterns and generate personalized financial insights.	2026	AI / Machine Learning	t	13c686f6-db44-4585-b9f1-6c6200aac025	9af488f8-db30-4b90-a672-c1ec50f45c85	c8cf883c-330c-46c0-b023-3629c2f99a69	c8cf883c-330c-46c0-b023-3629c2f99a69	c8cf883c-330c-46c0-b023-3629c2f99a69	1b6e6cdf-4700-4914-81cf-29f7e768c523	2026-01-15	2026-12-31	PRJ-2026-001	4aa61e37-f659-44ae-810b-41d4ac793b26
85eaf07b-2298-4658-baaa-a5e267c74812	Enterprise Data Governance Implementation	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-13 02:54:35.239403+00	2026-05-13 06:10:42.310928+00	PT ABC Tbk	Banking	Implementation of an enterprise data governance framework to improve data consistency, ownership, metadata management, and regulatory compliance across business domains. The project includes data cataloging, business glossary standardization, data quality monitoring, and governance workflow enablement to support reliable and trusted enterprise data usage.	2026	Data Governance	t	13c686f6-db44-4585-b9f1-6c6200aac025	c8cf883c-330c-46c0-b023-3629c2f99a69	9af488f8-db30-4b90-a672-c1ec50f45c85	1b6e6cdf-4700-4914-81cf-29f7e768c523	facd7d45-6237-46a9-8015-507fe266c7ff	19d275fc-8c44-4411-a412-92a85834759b	2026-05-01	2026-10-31	PRJ-2026-003	3991d4dd-deb4-432c-9a8a-edee818513b0
\.


--
-- Data for Name: retention_policies; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.retention_policies (id, dataset_type, retention_days, policy_reference, created_at, updated_at) FROM stdin;

\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, name, description, created_at) FROM stdin;
1	super_admin	Full system access across all projects	2026-05-05 08:43:07.051963+00
2	data_governance_officer	Manages governance frameworks, approves DSRs and DPIAs	2026-05-05 08:43:07.051963+00
3	project_manager	Creates and manages projects, assigns team members	2026-05-05 08:43:07.051963+00
4	data_steward	Manages metadata, data quality runs, and ROPA records	2026-05-05 08:43:07.051963+00
5	data_owner	Approves data sharing requests for owned datasets	2026-05-05 08:43:07.051963+00
6	requester	Submits data sharing requests	2026-05-05 08:43:07.051963+00
7	auditor	Read-only access to audit logs and reports	2026-05-05 08:43:07.051963+00
8	viewer	Read-only access to project artifacts	2026-05-05 08:43:07.051963+00
9	compliance_officer	Reviews and approves compliance-related items	2026-05-05 08:46:09.6989+00
10	dpo	Data Protection Officer — reviews DPIAs	2026-05-05 08:46:09.6989+00
11	regular_user	Basic access for project members	2026-05-05 08:46:09.6989+00
\.


--
-- Data for Name: ropa_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ropa_records (id, project_id, process_name, purpose, data_category, data_subject, legal_basis, retention_period, recipient, linked_asset_ids, status, version, created_by, created_at, updated_at) FROM stdin;

\.


--
-- Data for Name: user_project_roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_project_roles (id, user_id, role_id, project_id, assigned_by, assigned_at, revoked_at) FROM stdin;
1bc73912-ab3e-4424-881b-1159ef9df508	c8cf883c-330c-46c0-b023-3629c2f99a69	11	\N	c8cf883c-330c-46c0-b023-3629c2f99a69	2026-05-05 08:48:08.476676+00	\N
1d0fda9a-8f09-45bf-8a5f-61b2d5a45a4f	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	8	\N	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	2026-05-06 09:22:09.012469+00	\N
31f0bfa2-bfb2-4125-9b65-4017f784f0a5	19d275fc-8c44-4411-a412-92a85834759b	11	\N	19d275fc-8c44-4411-a412-92a85834759b	2026-05-05 08:48:08.476676+00	\N
6696a78a-0441-47e3-8b36-80f37cfbeb00	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	1	\N	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-05 08:46:10.075526+00	\N
7b139f60-6d5d-42ac-a3fb-3a70e220becd	9af488f8-db30-4b90-a672-c1ec50f45c85	11	\N	9af488f8-db30-4b90-a672-c1ec50f45c85	2026-05-05 08:48:08.476676+00	\N
a891a6c5-94f0-46aa-94b6-24be7b9558ca	facd7d45-6237-46a9-8015-507fe266c7ff	11	\N	facd7d45-6237-46a9-8015-507fe266c7ff	2026-05-05 08:48:08.476676+00	\N
f3a72615-1b95-4644-815f-9194b8d4b6e6	4aa61e37-f659-44ae-810b-41d4ac793b26	11	\N	4aa61e37-f659-44ae-810b-41d4ac793b26	2026-05-05 08:48:08.476676+00	\N
fb8d3c79-165a-417d-8eea-fa7219b5be5e	13c686f6-db44-4585-b9f1-6c6200aac025	11	\N	13c686f6-db44-4585-b9f1-6c6200aac025	2026-05-05 08:48:08.476676+00	\N
fc301f14-da6c-45f4-b3da-417ae495853f	1b6e6cdf-4700-4914-81cf-29f7e768c523	11	\N	1b6e6cdf-4700-4914-81cf-29f7e768c523	2026-05-05 08:48:08.476676+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, full_name, email, password_hash, is_active, last_login_at, created_at, updated_at, "position") FROM stdin;
017b69ab-0eee-4554-8c7a-1d697acdb108	Hani Setyaningsih	hani.setyaningsih@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
02bdf23f-e01f-4d69-a5e6-2963dd89df0a	Yogi Pratama	yogi.pratama@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
042635a8-8fac-4563-bb78-075923bfa77d	Arif Nugroho	arif.nugroho@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
07b98940-163b-49ea-9a24-1a69e3402753	Nadia Rahmatika	nadia.rahmatika@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Manager
0c043732-ea2e-47ff-90bd-c62142dbfa4c	Ira Sukmawati	ira.sukmawati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Scientist
0e3fac0f-ae09-4689-be27-2dbededaf7b6	Diana Puspita	diana.puspita@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Business Analyst
0eca99fb-0477-4935-8df1-9ac77a65d563	Endah Sulistyowati	endah.sulistyowati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
0eda815a-c10e-4fa5-b75a-768352e18064	Yudi Santosa	yudi.santosa@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Scrum Master
10f026d1-d2cf-42ec-9633-fb4318091d4e	Andi Firmansyah	andi.firmansyah@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Business Analyst
13b88b78-edb8-4b1d-8372-5dc6b7a15b11	Benny Hartono	benny.hartono@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Solutions Architect
13c686f6-db44-4585-b9f1-6c6200aac025	Ahmad Fauzi	ahmad.fauzi@company.com	$2b$12$PdcEha/.RuB64oqkiZBS1uIKQ/w4Bhb8IWaGslBrMMMsufp1n.Wuq	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Senior Delivery Manager
159c4b87-5a6f-44c0-9c7c-8159afd5108f	Reni Oktaviani	reni.oktaviani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Full Stack Developer
18eb3622-e93f-422c-8155-f02c0a214967	Wisnu Wardhana	wisnu.wardhana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Software Engineer
19d275fc-8c44-4411-a412-92a85834759b	Fitri Handayani	fitri.handayani@company.com	$2b$12$7G4YNjOnyBCZRAtNGfOW9eo8mC/Z09uyrSrt8aPoclZfSbdduKA4i	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	AI Engineer
1b6e6cdf-4700-4914-81cf-29f7e768c523	Budi Santoso	budi.santoso@company.com	$2b$12$Mp5Uj/hQhZgDkii6xtAP1ec/sg5yZgN3XIEnPJDzVCeFfz8Gd5lxy	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Data Compliance Officer
1f6142dc-92fa-4cb0-9ac6-72a5409ef7d6	Rifki Maulana	rifki.maulana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
21a48c56-639e-4b51-9fe3-3d5693d8b35b	Wulan Dari	wulan.dari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
279d171e-6fc9-47d3-9b5d-ff3dede08449	Aulia Rahma	aulia.rahma@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
2859d82c-7977-41c0-b7e5-2da886af7909	Dimas Ramadhan	dimas.ramadhan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
28d57e28-6bff-4e73-88e0-4eaa77a3ce30	Yuli Astuti	yuli.astuti@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
2b1cd54f-a428-4928-9915-2c1e86a86231	Tommy Wirabuana	tommy.wirabuana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
2b3ca039-bf92-4473-a428-8bfc9fa4fbdd	Tania Putri	tania.putri@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
2c22201a-4024-49e2-a0fc-c3bd60e4b1da	Vina Oktavia	vina.oktavia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	DevOps Engineer
2cacb21f-e706-4e2e-a3f5-bdf6bf1ded6b	Dedi Prasetyo	dedi.prasetyo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	System Analyst
2e80132d-2b00-4104-9749-4934f53fba60	Denny Saputra	denny.saputra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Cloud Engineer
301e9dc9-73ef-4e50-b6d0-8fca770fef76	Imam Wahyono	imam.wahyono@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Scrum Master
335e6de9-d833-473d-83b3-58a215696a04	Novi Andriani	novi.andriani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Backend Developer
336b5420-9af0-49de-b844-e42ee6658cd4	Anton Hidayat	anton.hidayat@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
344ec3c7-ca7f-4ee8-bd31-a232ef8e6067	Laila Nurhayati	laila.nurhayati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	System Analyst
37a43514-01da-4df3-9f44-7d692b20d339	Fandi Kurnia	fandi.kurnia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
3991d4dd-deb4-432c-9a8a-edee818513b0	Citra Nirmala	citra.nirmala@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	Super Administrator	admin@governance.local	$2b$12$Cg5PXcgBW1DIO9sjiikoB.dLnM6dVs/kk9a4HOXkxVFxmx2ZyHIlW	t	2026-05-28 03:48:54.86261+00	2026-05-05 08:46:09.725028+00	2026-05-28 03:48:53.541619+00	\N
3eec2e56-98b6-4cfa-b6df-7c73465d5f50	Umi Kalsum	umi.kalsum@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
3fe0f76c-826f-4238-8160-cfee350895fc	Gunawan Hidayatullah	gunawan.hidayatullah@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Software Engineer
417e9063-d72e-453f-bc85-27edd13f61e5	Rendi Cahyono	rendi.cahyono@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	System Analyst
441c3beb-b472-4e37-9edf-d651da770a6e	Febri Andriyanto	febri.andriyanto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Full Stack Developer
463b5372-d8c6-46e4-aa3b-914cba184690	David Santoso	david.santoso@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Analyst
48196223-c5dc-4c82-977b-c6abc08d53c4	Fajar Maulana	fajar.maulana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
4872c2fd-8bc9-4c2d-b9c4-5992034e2a51	Nanang Supriyadi	nanang.supriyadi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
4908c50c-2a1d-4ab5-8a1c-68965e49ba47	Anastasia Dewi	anastasia.dewi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Analyst
4931a6d0-7393-4d3d-acd4-ae2b18df4864	Sugeng Raharjo	sugeng.raharjo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Database Administrator
4a1a48b4-55b2-4ed4-84a8-ae84851e870d	Adi Kurniawan	adi.kurniawan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
4aa61e37-f659-44ae-810b-41d4ac793b26	Dewi Rahayu	dewi.rahayu@company.com	$2b$12$MCE2.iFFgufAqpNq6IwXY.s.8VDFTli3Kvkmg3nqn4hCsOgy5y19a	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Senior Data Scientist
4c6b0862-80a3-471a-b21f-57091048947f	Diah Ayu Ningrum	diah.ayu@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
4e462c43-67d8-40ed-8bf2-6567c91e41e8	Lina Marlina	lina.marlina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Frontend Developer
5495b01c-6a7a-4619-914b-303a9f2ff697	Teguh Santoso	teguh.santoso@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
562c949a-f7e3-4fbb-8d50-7b10f386d74e	Herman Sanjaya	herman.sanjaya@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
5ec9e918-23e6-4eb7-b0e3-3e453622b856	Hadi Subagyo	hadi.subagyo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
5f05b270-9b96-457c-bd23-414fed422291	Luthfi Hamdani	luthfi.hamdani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Scientist
5f80c115-cd37-422d-b663-5bfcd357d412	Eva Kristina	eva.kristina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
609734f6-e61b-49b5-ba0a-762ffc74e888	Panji Adiputra	panji.adiputra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Cloud Engineer
612f3887-fdb0-4ead-ab7a-a3763e819805	Indah Permatasari	indah.permatasari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Business Analyst
64293f5d-016d-407c-97e4-cee7a48ba6bf	Nurul Hidayah	nurul.hidayah@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
6512895c-8f98-4d86-951e-6554ecaa0e85	Reza Fauzan	reza.fauzan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
6b59690f-a62c-4058-9a66-6beec35bce54	Muhammad Rizky	muhammad.rizky@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
6f1b0aaf-14dc-4926-93b8-34c840d8d771	Kartika Sari	kartika.sari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Project Manager
724b68d0-b9c5-4352-88d8-dc7ba1fb084b	Syifa Aulia	syifa.aulia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
7607b230-55dd-48fa-bd0d-03960a5e7250	Ibnu Hakim	ibnu.hakim@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
76c1633d-8d0a-4666-a2fc-e03ace0502c1	Winda Sari	winda.sari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
77ab4b32-e99f-4c1e-8eac-6780b78dd8ee	Lestari Handayani	lestari.handayani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
7cd86197-3a72-435a-b2ac-e65713f706ed	Fatimah Zahra	fatimah.zahra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
8216e50c-c627-469d-a696-1e91285f5aab	Aini Rahmawati	aini.rahmawati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
84c8a7ed-63bd-415b-9c61-7c7686ae40dc	Fani Oktavia	fani.oktavia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
89070005-c639-454e-af9a-363b4202c4a4	Raka Pratama	raka.pratama@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
8919db87-2434-4b6a-aca1-fbf32224213b	Desi Wulandari	desi.wulandari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
89efb71c-c9f1-4224-8fa5-ae4b5e211402	Agus Setiawan	agus.setiawan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
8b0f7afb-3d25-4958-828d-484d926556f2	Dina Marliana	dina.marliana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
8ed54171-e2d6-4d71-9fbe-d868635d64ea	Putri Rahayu	putri.rahayu@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Cloud Engineer
8fabecc4-b214-498f-86d3-5b926900e20f	Rio Harianto	rio.harianto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
925384f7-bb76-4dd9-93c1-823ef148e838	Iwan Setiadi	iwan.setiadi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Business Analyst
9609a999-7ed1-4da9-9645-f5b06ee75da9	Rahmat Hidayat	rahmat.hidayat@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
996ed30f-fddd-43c1-96b0-7c8268f8f2a7	Nabila Azzahra	nabila.azzahra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
9af488f8-db30-4b90-a672-c1ec50f45c85	Bagas Adi Nugraha	bagas.nugraha@company.com	$2b$12$CJb1TMsBSY5ygQ7uJoiV/ukipMkzzDBFcF0cSr19mIQZMAM1n1lLy	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Project Manager
9c094644-5cc9-4952-aac1-80be16d2cc46	Hendra Wijaya	hendra.wijaya@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
9d2e8330-3aa8-47e9-bdec-c2d7037774a1	Shinta Kusumawati	shinta.kusumawati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Project Manager
9d6fc91a-9eca-43af-9cb3-9eb19a8f94b9	Pandu Wiradinata	pandu.wiradinata@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Project Manager
a0f414a7-f936-43b0-8d2d-8b14cf8b6071	Yusuf Rachman	yusuf.rachman@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Frontend Developer
a63329f0-c28e-42a9-9b13-12d65a57e833	Bambang Susanto	bambang.susanto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Manager
ac008bf5-98c0-4741-9b81-7353925746a8	Ryan Budiman	ryan.budiman@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Full Stack Developer
bab14ece-9415-4478-a4bb-c325608383c8	Randi Firmanto	randi.firmanto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Backend Developer
bc64cc07-876f-4574-b7db-5438d6d00af1	Suci Ramadhani	suci.ramadhani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Analyst
bf6b981a-dccb-4e6c-a4a8-6f6f14810158	Read-Only Viewer	viewer@governance.local	$2b$12$uaP.CIaweJlps8IY2ORu9uniu3nDwT.nh1H8NMytALDPPnTbXkbvS	t	2026-05-18 10:37:10.540445+00	2026-05-06 09:22:08.697769+00	2026-05-18 10:37:10.091099+00	\N
bf8ba960-3066-4a05-846a-004110358d88	Risma Nurul Aini	risma.nurul@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
c6b7640c-349d-4fbe-b93b-26521c1c42b3	Satria Nugroho	satria.nugroho@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Solutions Architect
c8cf883c-330c-46c0-b023-3629c2f99a69	Anisa Putri	anisa.putri@company.com	$2b$12$mEo0QE8VEJBoGYUJrXsrBuc/eidOUFM4yNBgVkiw9nQiooGxH4pwu	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Data Governance Officer
c99a9b0f-d1b5-4503-9267-f1017162dc9e	Rangga Satria	rangga.satria@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	DevOps Engineer
cabba18e-0fb7-4e08-896b-4276de5adda5	Mila Agustina	mila.agustina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
cb8ec3d2-13ba-41bc-9c06-bac73ad0d7b8	Dani Wahyudi	dani.wahyudi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
cdf78a74-fa36-4103-a8dc-d37c320ff257	Sri Wahyuni	sri.wahyuni@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
ce2fd09d-7bda-454b-a641-7afda6c5b26e	Intan Novitasari	intan.novitasari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
d071e644-bb72-4c8e-b865-f9d3f242baa6	Maya Sofianti	maya.sofianti@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Software Engineer
d1048068-41d7-4213-b13b-35f0a0323ca7	Surya Kusuma	surya.kusuma@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Manager
d34ad4b6-337b-4cdf-8ce6-ad68b7533fe5	Mahendra Kusuma	mahendra.kusuma@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
d53a7b87-eaa2-41f0-a5c7-a5a9d92755b9	Sigit Prayogo	sigit.prayogo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Business Analyst
d76096ca-cf59-431b-9076-b9fc3ce95c95	Galih Permana	galih.permana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Database Administrator
e2346f61-50ac-4e1c-9fa3-e16f04a5e02d	Cahyo Prabowo	cahyo.prabowo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Backend Developer
e31ff406-bc4e-40b6-9250-92bcf756f221	Febby Anggraini	febby.anggraini@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
e3c51290-ec9d-45c7-aefe-b2178b37a06d	Rina Puspitasari	rina.puspitasari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
e461c5b1-3f56-4153-88a1-fc07305f5b87	Bunga Pertiwi	bunga.pertiwi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
e47b0cdc-40fd-4ad5-a3fe-af7bc9dbf13d	Sella Oktaviani	sella.oktaviani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
ea97fc15-3df1-40f1-8fdc-9f988258f758	Mega Wulandari	mega.wulandari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Scrum Master
ef85e3ab-8c81-467a-82e4-091420d6223e	Yunita Sari	yunita.sari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
f05ac9a6-dc01-4d18-86a6-0f9ecefe3941	Umar Hakim	umar.hakim@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
f0650df1-497c-4d94-88d6-ae9706ce896d	Ratna Dewi	ratna.dewi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Solutions Architect
f1f87ebb-9e9f-4929-b265-098512c610a0	Ayu Lestari	ayu.lestari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
f2f4641f-92eb-485c-8a49-15a3e5dbcf99	Yeni Marlina	yeni.marlina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
f3c9750c-47aa-4bed-ad70-326737a3afc9	Kevin Prasetya	kevin.prasetya@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Frontend Developer
f6c56d4a-1ef2-4b97-a4db-b16259714474	Wahyu Setiawan	wahyu.setiawan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
f6e6e704-35cf-4871-8660-76e1c7e72db0	Arief Wibowo	arief.wibowo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	DevOps Engineer
f7edfb0a-8745-4ab2-8843-5292b3052d1c	Sari Wahyuningsih	sari.wahyuningsih@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Database Administrator
f94e2983-99d5-4879-a520-ad62faa82198	Joko Widiantoro	joko.widiantoro@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
f961edea-0a7a-4f6c-8738-098f640b6dc8	Amalia Putri	amalia.putri@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Business Analyst
facd7d45-6237-46a9-8015-507fe266c7ff	Eko Prasetyo	eko.prasetyo@company.com	$2b$12$bqyJCHgopUbi1uL1Ta9bQO5KqIXq2OBt2FrYibT47roV3kGDOPZIS	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Data Analyst
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1343, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_seq', 11, true);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: ai_checklist_approvals pk_ai_checklist_approvals; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_checklist_approvals
    ADD CONSTRAINT pk_ai_checklist_approvals PRIMARY KEY (id);


--
-- Name: ai_compliance_checklists pk_ai_compliance_checklists; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_compliance_checklists
    ADD CONSTRAINT pk_ai_compliance_checklists PRIMARY KEY (id);


--
-- Name: ai_provider_configs pk_ai_provider_configs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_provider_configs
    ADD CONSTRAINT pk_ai_provider_configs PRIMARY KEY (id);


--
-- Name: audit_logs pk_audit_logs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT pk_audit_logs PRIMARY KEY (id);


--
-- Name: bapd_approvals pk_bapd_approvals; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_approvals
    ADD CONSTRAINT pk_bapd_approvals PRIMARY KEY (id);


--
-- Name: bapd_records pk_bapd_records; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_records
    ADD CONSTRAINT pk_bapd_records PRIMARY KEY (id);


--
-- Name: data_owner_stewards pk_data_owner_stewards; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_owner_stewards
    ADD CONSTRAINT pk_data_owner_stewards PRIMARY KEY (id);


--
-- Name: data_sharing_agreements pk_data_sharing_agreements; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sharing_agreements
    ADD CONSTRAINT pk_data_sharing_agreements PRIMARY KEY (id);


--
-- Name: data_sharing_requests pk_data_sharing_requests; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sharing_requests
    ADD CONSTRAINT pk_data_sharing_requests PRIMARY KEY (id);


--
-- Name: dpia_approvals pk_dpia_approvals; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_approvals
    ADD CONSTRAINT pk_dpia_approvals PRIMARY KEY (id);


--
-- Name: dpia_records pk_dpia_records; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_records
    ADD CONSTRAINT pk_dpia_records PRIMARY KEY (id);


--
-- Name: dq_findings pk_dq_findings; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_findings
    ADD CONSTRAINT pk_dq_findings PRIMARY KEY (id);


--
-- Name: dq_gcp_archives pk_dq_gcp_archives; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_gcp_archives
    ADD CONSTRAINT pk_dq_gcp_archives PRIMARY KEY (id);


--
-- Name: dq_results pk_dq_results; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_results
    ADD CONSTRAINT pk_dq_results PRIMARY KEY (id);


--
-- Name: dq_runs pk_dq_runs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_runs
    ADD CONSTRAINT pk_dq_runs PRIMARY KEY (id);


--
-- Name: dsr_approvals pk_dsr_approvals; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsr_approvals
    ADD CONSTRAINT pk_dsr_approvals PRIMARY KEY (id);


--
-- Name: metadata_records pk_metadata_records; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_records
    ADD CONSTRAINT pk_metadata_records PRIMARY KEY (id);


--
-- Name: notification_preferences pk_notification_preferences; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT pk_notification_preferences PRIMARY KEY (id);


--
-- Name: notifications pk_notifications; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT pk_notifications PRIMARY KEY (id);


--
-- Name: project_source_files pk_project_source_files; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_source_files
    ADD CONSTRAINT pk_project_source_files PRIMARY KEY (id);


--
-- Name: projects pk_projects; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT pk_projects PRIMARY KEY (id);


--
-- Name: retention_policies pk_retention_policies; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retention_policies
    ADD CONSTRAINT pk_retention_policies PRIMARY KEY (id);


--
-- Name: roles pk_roles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT pk_roles PRIMARY KEY (id);


--
-- Name: ropa_records pk_ropa_records; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ropa_records
    ADD CONSTRAINT pk_ropa_records PRIMARY KEY (id);


--
-- Name: user_project_roles pk_user_project_roles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_project_roles
    ADD CONSTRAINT pk_user_project_roles PRIMARY KEY (id);


--
-- Name: users pk_users; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT pk_users PRIMARY KEY (id);


--
-- Name: ai_compliance_checklists uq_ai_compliance_checklists_dsr_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_compliance_checklists
    ADD CONSTRAINT uq_ai_compliance_checklists_dsr_id UNIQUE (dsr_id);


--
-- Name: dq_gcp_archives uq_dq_gcp_archives_run_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_gcp_archives
    ADD CONSTRAINT uq_dq_gcp_archives_run_id UNIQUE (run_id);


--
-- Name: retention_policies uq_retention_policies_dataset_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.retention_policies
    ADD CONSTRAINT uq_retention_policies_dataset_type UNIQUE (dataset_type);


--
-- Name: roles uq_roles_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT uq_roles_name UNIQUE (name);


--
-- Name: ix_ai_checklist_approvals_checklist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ai_checklist_approvals_checklist_id ON public.ai_checklist_approvals USING btree (checklist_id);


--
-- Name: ix_ai_provider_configs_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ai_provider_configs_provider ON public.ai_provider_configs USING btree (provider);


--
-- Name: ix_audit_logs_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: ix_audit_logs_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_entity_id ON public.audit_logs USING btree (entity_id);


--
-- Name: ix_audit_logs_module; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_audit_logs_module ON public.audit_logs USING btree (module);


--
-- Name: ix_bapd_approvals_bapd_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bapd_approvals_bapd_id ON public.bapd_approvals USING btree (bapd_id);


--
-- Name: ix_bapd_records_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bapd_records_project_id ON public.bapd_records USING btree (project_id);


--
-- Name: ix_bapd_records_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_bapd_records_status ON public.bapd_records USING btree (status);


--
-- Name: ix_data_owner_stewards_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_data_owner_stewards_project_id ON public.data_owner_stewards USING btree (project_id);


--
-- Name: ix_data_sharing_requests_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_data_sharing_requests_project_id ON public.data_sharing_requests USING btree (project_id);


--
-- Name: ix_data_sharing_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_data_sharing_requests_status ON public.data_sharing_requests USING btree (status);


--
-- Name: ix_data_sharing_requests_tracking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_data_sharing_requests_tracking_id ON public.data_sharing_requests USING btree (tracking_id);


--
-- Name: ix_dpia_approvals_dpia_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dpia_approvals_dpia_id ON public.dpia_approvals USING btree (dpia_id);


--
-- Name: ix_dpia_records_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dpia_records_project_id ON public.dpia_records USING btree (project_id);


--
-- Name: ix_dpia_records_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dpia_records_status ON public.dpia_records USING btree (status);


--
-- Name: ix_dpia_records_tracking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_dpia_records_tracking_id ON public.dpia_records USING btree (tracking_id);


--
-- Name: ix_dq_findings_result_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dq_findings_result_id ON public.dq_findings USING btree (result_id);


--
-- Name: ix_dq_findings_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dq_findings_status ON public.dq_findings USING btree (status);


--
-- Name: ix_dq_results_run_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dq_results_run_id ON public.dq_results USING btree (run_id);


--
-- Name: ix_dq_runs_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dq_runs_project_id ON public.dq_runs USING btree (project_id);


--
-- Name: ix_dq_runs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dq_runs_status ON public.dq_runs USING btree (status);


--
-- Name: ix_dsr_approvals_dsr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dsr_approvals_dsr_id ON public.dsr_approvals USING btree (dsr_id);


--
-- Name: ix_metadata_records_data_attribute; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_metadata_records_data_attribute ON public.metadata_records USING btree (data_attribute);


--
-- Name: ix_metadata_records_data_domain_table; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_metadata_records_data_domain_table ON public.metadata_records USING btree (data_domain_table);


--
-- Name: ix_metadata_records_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_metadata_records_project_id ON public.metadata_records USING btree (project_id);


--
-- Name: ix_notification_preferences_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notification_preferences_user_id ON public.notification_preferences USING btree (user_id);


--
-- Name: ix_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_created_at ON public.notifications USING btree (created_at);


--
-- Name: ix_notifications_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_is_read ON public.notifications USING btree (is_read);


--
-- Name: ix_notifications_module; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_module ON public.notifications USING btree (module);


--
-- Name: ix_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: ix_project_source_files_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_project_source_files_project_id ON public.project_source_files USING btree (project_id);


--
-- Name: ix_projects_customer_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_projects_customer_name ON public.projects USING btree (customer_name);


--
-- Name: ix_projects_project_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_projects_project_code ON public.projects USING btree (project_code);


--
-- Name: ix_projects_project_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_projects_project_year ON public.projects USING btree (project_year);


--
-- Name: ix_ropa_records_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ropa_records_project_id ON public.ropa_records USING btree (project_id);


--
-- Name: ix_ropa_records_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_ropa_records_status ON public.ropa_records USING btree (status);


--
-- Name: ix_user_project_roles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_user_project_roles_user_id ON public.user_project_roles USING btree (user_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: audit_logs tg_audit_logs_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_audit_logs_immutable BEFORE DELETE OR UPDATE ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION public.fn_audit_logs_immutable();


--
-- Name: ai_checklist_approvals fk_ai_checklist_approvals_approver_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_checklist_approvals
    ADD CONSTRAINT fk_ai_checklist_approvals_approver_id_users FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: ai_checklist_approvals fk_ai_checklist_approvals_checklist_id_ai_compliance_checklists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_checklist_approvals
    ADD CONSTRAINT fk_ai_checklist_approvals_checklist_id_ai_compliance_checklists FOREIGN KEY (checklist_id) REFERENCES public.ai_compliance_checklists(id) ON DELETE CASCADE;


--
-- Name: ai_compliance_checklists fk_ai_checklist_dsr_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_compliance_checklists
    ADD CONSTRAINT fk_ai_checklist_dsr_id FOREIGN KEY (dsr_id) REFERENCES public.data_sharing_requests(id);


--
-- Name: ai_compliance_checklists fk_ai_checklist_validated_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_compliance_checklists
    ADD CONSTRAINT fk_ai_checklist_validated_by FOREIGN KEY (validated_by) REFERENCES public.users(id);


--
-- Name: ai_provider_configs fk_ai_provider_configs_updated_by_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_provider_configs
    ADD CONSTRAINT fk_ai_provider_configs_updated_by_users FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: audit_logs fk_audit_logs_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT fk_audit_logs_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: bapd_approvals fk_bapd_approvals_approver_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_approvals
    ADD CONSTRAINT fk_bapd_approvals_approver_id_users FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: bapd_approvals fk_bapd_approvals_bapd_id_bapd_records; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_approvals
    ADD CONSTRAINT fk_bapd_approvals_bapd_id_bapd_records FOREIGN KEY (bapd_id) REFERENCES public.bapd_records(id) ON DELETE CASCADE;


--
-- Name: bapd_records fk_bapd_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_records
    ADD CONSTRAINT fk_bapd_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: bapd_records fk_bapd_executed_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_records
    ADD CONSTRAINT fk_bapd_executed_by FOREIGN KEY (executed_by) REFERENCES public.users(id);


--
-- Name: bapd_records fk_bapd_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_records
    ADD CONSTRAINT fk_bapd_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: bapd_records fk_bapd_responsible_party; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_records
    ADD CONSTRAINT fk_bapd_responsible_party FOREIGN KEY (responsible_party_id) REFERENCES public.users(id);


--
-- Name: bapd_records fk_bapd_retention_policy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bapd_records
    ADD CONSTRAINT fk_bapd_retention_policy FOREIGN KEY (retention_policy_id) REFERENCES public.retention_policies(id);


--
-- Name: data_owner_stewards fk_dos_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_owner_stewards
    ADD CONSTRAINT fk_dos_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: dpia_approvals fk_dpia_approvals_approver_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_approvals
    ADD CONSTRAINT fk_dpia_approvals_approver_id_users FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: dpia_approvals fk_dpia_approvals_dpia_id_dpia_records; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_approvals
    ADD CONSTRAINT fk_dpia_approvals_dpia_id_dpia_records FOREIGN KEY (dpia_id) REFERENCES public.dpia_records(id) ON DELETE CASCADE;


--
-- Name: dpia_records fk_dpia_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_records
    ADD CONSTRAINT fk_dpia_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: dpia_records fk_dpia_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_records
    ADD CONSTRAINT fk_dpia_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: dpia_records fk_dpia_responsible_party; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dpia_records
    ADD CONSTRAINT fk_dpia_responsible_party FOREIGN KEY (responsible_party_id) REFERENCES public.users(id);


--
-- Name: dq_findings fk_dq_findings_resolved_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_findings
    ADD CONSTRAINT fk_dq_findings_resolved_by FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: dq_findings fk_dq_findings_result_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_findings
    ADD CONSTRAINT fk_dq_findings_result_id FOREIGN KEY (result_id) REFERENCES public.dq_results(id);


--
-- Name: dq_gcp_archives fk_dq_gcp_archives_run_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_gcp_archives
    ADD CONSTRAINT fk_dq_gcp_archives_run_id FOREIGN KEY (run_id) REFERENCES public.dq_runs(id);


--
-- Name: dq_results fk_dq_results_run_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_results
    ADD CONSTRAINT fk_dq_results_run_id FOREIGN KEY (run_id) REFERENCES public.dq_runs(id);


--
-- Name: dq_runs fk_dq_runs_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_runs
    ADD CONSTRAINT fk_dq_runs_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: dq_runs fk_dq_runs_source_file_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_runs
    ADD CONSTRAINT fk_dq_runs_source_file_id FOREIGN KEY (source_file_id) REFERENCES public.project_source_files(id) ON DELETE SET NULL;


--
-- Name: dq_runs fk_dq_runs_triggered_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dq_runs
    ADD CONSTRAINT fk_dq_runs_triggered_by FOREIGN KEY (triggered_by) REFERENCES public.users(id);


--
-- Name: dsr_approvals fk_dsr_approvals_approver_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsr_approvals
    ADD CONSTRAINT fk_dsr_approvals_approver_id FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: dsr_approvals fk_dsr_approvals_dsr_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dsr_approvals
    ADD CONSTRAINT fk_dsr_approvals_dsr_id FOREIGN KEY (dsr_id) REFERENCES public.data_sharing_requests(id);


--
-- Name: data_sharing_requests fk_dsr_dsa_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sharing_requests
    ADD CONSTRAINT fk_dsr_dsa_id FOREIGN KEY (dsa_id) REFERENCES public.data_sharing_agreements(id);


--
-- Name: data_sharing_requests fk_dsr_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sharing_requests
    ADD CONSTRAINT fk_dsr_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: data_sharing_requests fk_dsr_requester_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sharing_requests
    ADD CONSTRAINT fk_dsr_requester_id FOREIGN KEY (requester_id) REFERENCES public.users(id);


--
-- Name: metadata_records fk_metadata_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.metadata_records
    ADD CONSTRAINT fk_metadata_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: notification_preferences fk_notification_preferences_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT fk_notification_preferences_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notifications fk_notifications_user_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT fk_notifications_user_id_users FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: project_source_files fk_project_source_files_project_id_projects; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_source_files
    ADD CONSTRAINT fk_project_source_files_project_id_projects FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: projects fk_projects_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: projects fk_projects_delivery_manager_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_delivery_manager_id_users FOREIGN KEY (delivery_manager_id) REFERENCES public.users(id);


--
-- Name: projects fk_projects_dgo_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_dgo_id_users FOREIGN KEY (dgo_id) REFERENCES public.users(id);


--
-- Name: projects fk_projects_dq_officer_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_dq_officer_id_users FOREIGN KEY (dq_officer_id) REFERENCES public.users(id);


--
-- Name: projects fk_projects_metadata_officer_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_metadata_officer_id_users FOREIGN KEY (metadata_officer_id) REFERENCES public.users(id);


--
-- Name: projects fk_projects_pic_data_compliance_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_pic_data_compliance_id_users FOREIGN KEY (pic_data_compliance_id) REFERENCES public.users(id);


--
-- Name: projects fk_projects_project_manager_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_project_manager_id_users FOREIGN KEY (project_manager_id) REFERENCES public.users(id);


--
-- Name: projects fk_projects_sme_id_users; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT fk_projects_sme_id_users FOREIGN KEY (sme_id) REFERENCES public.users(id);


--
-- Name: ropa_records fk_ropa_created_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ropa_records
    ADD CONSTRAINT fk_ropa_created_by FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: ropa_records fk_ropa_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ropa_records
    ADD CONSTRAINT fk_ropa_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: user_project_roles fk_upr_assigned_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_project_roles
    ADD CONSTRAINT fk_upr_assigned_by FOREIGN KEY (assigned_by) REFERENCES public.users(id);


--
-- Name: user_project_roles fk_upr_project_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_project_roles
    ADD CONSTRAINT fk_upr_project_id FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: user_project_roles fk_upr_role_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_project_roles
    ADD CONSTRAINT fk_upr_role_id FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: user_project_roles fk_upr_user_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_project_roles
    ADD CONSTRAINT fk_upr_user_id FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: ai_provider_configs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ai_provider_configs ENABLE ROW LEVEL SECURITY;

--
-- Name: bapd_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bapd_records ENABLE ROW LEVEL SECURITY;

--
-- Name: data_sharing_requests; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.data_sharing_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: dpia_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dpia_records ENABLE ROW LEVEL SECURITY;

--
-- Name: dq_runs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.dq_runs ENABLE ROW LEVEL SECURITY;

--
-- Name: metadata_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.metadata_records ENABLE ROW LEVEL SECURITY;

--
-- Name: ai_provider_configs rls_ai_provider_configs_backend_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_ai_provider_configs_backend_insert ON public.ai_provider_configs FOR INSERT WITH CHECK (true);


--
-- Name: ai_provider_configs rls_ai_provider_configs_backend_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_ai_provider_configs_backend_select ON public.ai_provider_configs FOR SELECT USING (true);


--
-- Name: ai_provider_configs rls_ai_provider_configs_backend_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_ai_provider_configs_backend_update ON public.ai_provider_configs FOR UPDATE USING (true) WITH CHECK (true);


--
-- Name: bapd_records rls_bapd_project_member; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_bapd_project_member ON public.bapd_records USING ((project_id IN ( SELECT user_project_roles.project_id
   FROM public.user_project_roles
  WHERE ((user_project_roles.user_id = (current_setting('app.current_user_id'::text, true))::uuid) AND (user_project_roles.revoked_at IS NULL)))));


--
-- Name: dpia_records rls_dpia_project_member; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_dpia_project_member ON public.dpia_records USING ((project_id IN ( SELECT user_project_roles.project_id
   FROM public.user_project_roles
  WHERE ((user_project_roles.user_id = (current_setting('app.current_user_id'::text, true))::uuid) AND (user_project_roles.revoked_at IS NULL)))));


--
-- Name: dq_runs rls_dq_runs_project_member; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_dq_runs_project_member ON public.dq_runs USING ((project_id IN ( SELECT user_project_roles.project_id
   FROM public.user_project_roles
  WHERE ((user_project_roles.user_id = (current_setting('app.current_user_id'::text, true))::uuid) AND (user_project_roles.revoked_at IS NULL)))));


--
-- Name: data_sharing_requests rls_dsr_project_member; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_dsr_project_member ON public.data_sharing_requests USING (((project_id IN ( SELECT user_project_roles.project_id
   FROM public.user_project_roles
  WHERE ((user_project_roles.user_id = (current_setting('app.current_user_id'::text, true))::uuid) AND (user_project_roles.revoked_at IS NULL)))) OR (requester_id = (current_setting('app.current_user_id'::text, true))::uuid)));


--
-- Name: metadata_records rls_metadata_project_member; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_metadata_project_member ON public.metadata_records USING ((project_id IN ( SELECT user_project_roles.project_id
   FROM public.user_project_roles
  WHERE ((user_project_roles.user_id = (current_setting('app.current_user_id'::text, true))::uuid) AND (user_project_roles.revoked_at IS NULL)))));


--
-- Name: ropa_records rls_ropa_project_member; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY rls_ropa_project_member ON public.ropa_records USING ((project_id IN ( SELECT user_project_roles.project_id
   FROM public.user_project_roles
  WHERE ((user_project_roles.user_id = (current_setting('app.current_user_id'::text, true))::uuid) AND (user_project_roles.revoked_at IS NULL)))));


--
-- Name: ropa_records; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ropa_records ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict b59ja8xBpFqakoyhg6bkeoIt0ameizBpAT7qsEpnqpxCVfGX2dcq9JsZpdINzZh

