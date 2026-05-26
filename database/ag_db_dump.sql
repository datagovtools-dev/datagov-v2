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
10c09d27-7f07-458c-b04e-aff4f6790be3	b6113743-ae21-4fda-8fd5-896d08d429ea	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	pending	\N	\N
0e1b4ce7-895c-446b-a4f1-7385c8176fcd	b6113743-ae21-4fda-8fd5-896d08d429ea	13c686f6-db44-4585-b9f1-6c6200aac025	dm	2	pending	\N	\N
fc0b12ea-4e2a-4f4b-9d66-e2a62f6a9675	b6113743-ae21-4fda-8fd5-896d08d429ea	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	pending	\N	\N
11fac752-3ae0-445d-a358-43d4fb9c96e1	ae5892cf-9769-4a96-8185-c2987d1809c7	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	pending	\N	\N
da7721a1-c861-4d57-ad6c-95629694937b	ae5892cf-9769-4a96-8185-c2987d1809c7	13c686f6-db44-4585-b9f1-6c6200aac025	dm	2	pending	\N	\N
47869237-72ef-481b-a8d0-49714f1f9efe	ae5892cf-9769-4a96-8185-c2987d1809c7	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	pending	\N	\N
b8b172fb-dc0d-437c-a5a0-8f07a8f358fb	6ae7c72b-400c-4d30-b87d-e35878cd8180	336b5420-9af0-49de-b844-e42ee6658cd4	pic_compliance	1	pending	\N	\N
d4d25e1e-7784-49a2-8672-401d220fc929	6ae7c72b-400c-4d30-b87d-e35878cd8180	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm	2	pending	\N	\N
63cbabe3-8f85-41eb-835d-a44bc0bce688	6ae7c72b-400c-4d30-b87d-e35878cd8180	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
90572a18-acf7-452b-a5e8-d325263f3f7e	1b751499-4ac7-434b-a48d-8cd0c88a7d66	f961edea-0a7a-4f6c-8738-098f640b6dc8	pic_compliance	1	pending	\N	\N
9027c6b6-8009-4a9a-b8b9-137c39b9a11a	1b751499-4ac7-434b-a48d-8cd0c88a7d66	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm	2	pending	\N	\N
dbeb98c9-0075-40b6-afed-906e31dc352b	1b751499-4ac7-434b-a48d-8cd0c88a7d66	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
\.


--
-- Data for Name: ai_compliance_checklists; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_compliance_checklists (id, dsr_id, validated_by, validated_at, checklist_json, status) FROM stdin;
b6113743-ae21-4fda-8fd5-896d08d429ea	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	\N	2026-01-27 14:00:00+00	{"B_i": {"answer": "Yes", "remarks": "Contains personal financial transaction data classified as sensitive under UU PDP."}, "B_v": {"answer": "Yes", "remarks": "Research consent included in digital banking app consent form signed by customers."}, "D_i": {"answer": "Yes", "remarks": "Generative AI models are used for customer financial insight generation. AI Checklist Assessment completed separately."}, "B_ii": {"answer": "Yes", "remarks": "PII fields are masked and tokenised before sharing; access restricted to authorised team members only."}, "B_iv": {"answer": "Yes", "remarks": "Customer consent obtained via Terms & Conditions agreement at account opening."}, "B_vi": {"answer": "Yes", "remarks": "Data is processed within the BU secured analytics environment with role-based access control enforced."}, "A_i_1": {"answer": "No", "remarks": "No revenue cannibalization risk; data is used solely for internal AI model development."}, "A_i_2": {"answer": "No", "remarks": "Data is anonymised prior to use; no direct customer relationship impact."}, "A_i_3": {"answer": "No", "remarks": "No other commercial interests identified."}, "B_iii": {"answer": "Yes", "remarks": "Transaction records contain customer identifiers and financial data constituting personal data."}, "C_i_1": {"answer": "No", "remarks": "Compliant with OJK regulations on data usage for financial analytics purposes."}, "C_i_2": {"answer": "No", "remarks": "Compliant with UU PDP (Personal Data Protection Law No. 27/2022)."}, "C_i_3": {"answer": "No", "remarks": "Compliant with internal Data Governance Policy v2.1 and AI Ethics Guidelines."}, "A_ii_1": {"answer": "No", "remarks": "No confidential partnership data is included in the transaction dataset."}, "A_ii_2": {"answer": "No", "remarks": "No patent information present in scope of data."}, "A_ii_3": {"answer": "No", "remarks": "No M&A-related information included."}, "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets identified in the dataset."}, "sign_off": {"remarks": "All compliance requirements have been reviewed and satisfied. Data sharing approved for AI model development purposes.", "approved": "Yes", "prepared_by": "Rendra Kusuma Wijaya", "prepared_date": "2026-01-25", "acknowledged_by": "Dewi Rahayu", "acknowledged_date": "2026-01-25", "prepared_position": "Head of Digital Innovation", "prepared_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAAClklEQVR4nO2cQXIDIQwE85Lc84b8/13OLeWyDSskoQG2u3Jy1pIYaJLTfj0AQMqXegCAu4OEAGKQEEAMEgKIQUIAMUgIIAYJAcQgIYAYJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxCAhgJjNJPz++X3+UY+zPS95EqyEnSTkuGTRco9sJeRIWLBzHJcgRvFODXbldeVLOGOFtzouuYzKdl6265+ZBAlnL69VvCzWZTevRfCv3LwjW5/kFtd3VMLZC+tXrvd/qc17Ieiepdqk2dxlR5t2Jpk0g4VZElZenDWtV9u5mjnj1SRJXrZYakNDEl5eM4nF+9USA+0flHV2ruxkR4pLkrRXzs3NXccvYaufcD3BNI2nWe5hgXjGpo4hIzV9c/qWZp8kvhc5EvbHilQereDLwpGjRMV69ywDGIeM1MyabfTro2OXSnjZLDGL4GzuKHMbBZHrdzlJ/1eOmvGpclfXfyDS1yOhpaVvrMQTdplOVoizxVhHP+NU9UmmJ2NcXVbTqITGxywj1kTZ+jzScZIka+r3TE2Sic/Hh5nRbljCoQkiaY4OZq88Kcrcsovr948wyZp8CjZiTELHHJavzI5ytn6XjeqLFFNzdfYfyGrdn2dGcb+Evm+9f7EsTWEj34W1hX5T6d+ex0Q0IGHi7d76fOv7rNXLsrojz1YKxxv4cEs42uZjauel+YLlxJx6sHI5OyWPhL5Ox99nLVqLvVsOQQ4Oqk7CR9dDd80tsPxPdXwIKRyZVfXrLe58+NAPPiJ4x8ydzx/6wTuaFz3d/AjefPnwwk5vWwM4EiQEEIOEAGKQEEAMEgKIQUIAMUgIIAYJAcQgIYAYJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxPwBr27y8ba2v8YAAAAASUVORK5CYII=", "acknowledged_position": "Senior Data Scientist", "acknowledged_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAACmklEQVR4nO3bS1JrMQxFUUaSPmNg/uMKPYoKN0aSJR052atoJteyrGM+L+/jDkDqQ10A8O4IISBGCAExQgiIEUJAjBACYoQQECOEgBghBMQIISBGCAExQgiIEUJAjBACYoQQECOEgNi4EN4+v35/qcuB1cPBcYJ2s0LIKR7nWfY4RLtBIdQeIUNjZwweLTWaEkLhETI3Rt6w0VKjESG8PKqe8xt1fw8c2c3vcm1dHdg6O30I1+0rba4x/NUnOucWMJbkra1uX6Pu0DBxCC1dq+js+sCE97dwkqqLaXjaoTlUhtDer9zOGo9KdX9fviBl3Vg9DRvPKnXxmpT6i8hC6G1TVlv31627v+vWjZVUsdyzFXfq/Pv2s3KoCWGsQZttDR9Mz/1tfKN90XBViUt4V7cX2X+B1nGEMGsnudMcfmNPhndm6NkTXGW7Ckt58mYNt+VPlf3nHqjfu0QwhOGdpHRk/0YM1X79qMunpQxQRf32LbRZ96po6tJnYKfmeAgDOyltRFHNxmfeUu/vuo1MS+CPovitn59bYTiQvt8Jd3bS0NbEagOr1w3QYtHNgrMKS9FQYWwJ1/kGRiLyh5nAToqau3hsz8C1xW+xYrjO9NpSVJdnb8Xm4drfHvzrqKum0uMPXDy5+ufbtdxB8eu0aEvFLJWE0PLoZ6/ZWdFeRvPMNc+3cZskcMF4faf3LTmE9/+O+bW/I8m5Ov/y3YiZcIPn/GN9811iLKN6uQkum0wCXeTtSvvEjDyBD2X0LDfBkM6fTtiu5I+tMQcSJPBo+Z8dZQ5UaPuhqj7AzShI0PYT6f9nPfDmCCEgRggBMUIIiBFCQIwQAmKEEBAjhIAYIQTECCEgRggBMUIIiBFCQIwQAmKEEBAjhIDYN8GW/N1n4h0IAAAAAElFTkSuQmCC"}, "ai_assessment": {"items": {"input_1": {"status": "Yes", "remarks": "Customer transaction data is fully anonymised and tokenised before being used as AI model input. No raw PII — names, account numbers, phone numbers — is included in any prompt or model input."}, "input_2": {"status": "Yes", "remarks": "All data inputs to the Gen AI pipeline are pseudonymised. Customer identifiers are replaced with internal tokens, and synthetic dummy data is used during model exploration and testing phases."}, "input_3": {"status": "Yes", "remarks": "All prompts are reviewed by the AI Engineer and Data Scientist before use. Prompt templates are documented in the project repository under /docs/prompt-log.txt and versioned accordingly."}, "output_1": {"status": "Yes", "remarks": "All AI-generated financial insights are reviewed and validated by the Subject Matter Expert (Dewi Rahayu) before being surfaced to end users. A validation checklist is applied to each output batch to check for hallucinations, bias, or inaccuracies."}, "output_2": {"status": "Yes", "remarks": "Any source code generated or assisted by Gen AI undergoes mandatory peer review by a senior developer, security static analysis scanning, and functional testing before integration into the customer analytics platform."}, "before_use_1": {"status": "Yes", "remarks": "The platform has been reviewed against OJK regulations, UU PDP No. 27/2022, and internal AI Ethics & Governance Policy. Legal and compliance sign-off obtained prior to project initiation."}, "before_use_2": {"status": "Yes", "remarks": "The generative AI platform used for financial insight generation is officially licensed and has received formal written approval from the Chief Technology Officer and Head of Digital Innovation."}, "before_use_3": {"status": "Yes", "remarks": "Platform settings have been configured to disable interaction history logging. The team has opted out of all model training data-sharing options provided by the Gen AI service provider."}, "utilization_1": {"status": "Yes", "remarks": "AI-generated insights and recommendations are only released after independent assessment and sign-off by the authorised SME. A review checklist is used to confirm outputs are ready for customer-facing use."}, "utilization_2": {"status": "Yes", "remarks": "A feedback and correction loop is in place. Inaccurate or inappropriate AI outputs are flagged, corrected, and logged in the incident register before any distribution to customers or stakeholders."}}, "sign_off": {"approved": "Yes", "prepared_by": "Ahmad Fauzi", "prepared_date": "2026-01-27", "acknowledged_by": "Dewi Rahayu", "acknowledged_date": "2026-01-27", "prepared_position": "Senior Delivery Manager", "prepared_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAACg0lEQVR4nO2bSW7DMBAE/RLf84b8/13KIRcjgcStZ3ooVSHHmNNqsmgDhl8HAFh5uQMAPB0kBDCDhABmkBDADBICmEFCADNICGAGCQHMICGAGSQEMIOEAGaQEMAMEgKYQUIAM7eS8P31/fnnjrM9f/qk2CDuIyHHRcKZeHQbR4iE+bvFcVmhX7zMYp+zj3oJK+zWc/ZvjmnTcrp92lYqJbR0dzbItX9lD43qLS50fyu8A/ek0q4vk9DSXYVr+2KWXUWVeJ0rB0WNGLeeShhAI+FZvtDiOheP3rygU54TLGKEMKd8liqYNoZAwtHu1ieOLpt2/pp3UI6KmXfBypSJkDmVnk0JKnZJws4oCQLEvapnnYs18z20mD86dOUoRz/g9LZOh5mXcHS2qrWVZ16pbKX3HDEs+o0GUJ3diIcVXiVDYSYlnBu5Xtl67yqFJA6PhjeuvxLj3fosJ5+lWm0xSeciMxKuPLbrtc2l/q+muudG51ZYMyJSUE7JspJg0086JqHxgTPPbui5qW+1imj9moOmX5ucZ0BCYdbRpeK28PqgxJ1s43WWSeYdMTErNF6GhGkRLT64Do3x/o4jM2FnM5aNPvuHSQkV2brsMioRNKg513t/34BmP9UKnJFQOH60LOHoizChU65H17m/d6f5AadOgf7fE56VUrCsULa7v+uzhYFHBQl/2aKsBDa6v3ehfoFVJDwCvszdFAyUU7zAQhIefOL6AP3klO2wloSH+ouQrcHAh1BOwqPwjWWBNm5PRQkBHgUSAphBQgAzSAhgBgkBzCAhgBkkBDCDhABmkBDADBICmEFCADNICGAGCQHMICGAGSQEMIOEAGaQEMAMEgKY+QEOqe37kV4VDgAAAABJRU5ErkJggg==", "acknowledged_position": "Senior Data Scientist", "acknowledged_signature": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAA4CAIAAADIL1IbAAACs0lEQVR4nO2cS27DMAwFe5Lse4be/1zpokAQJLFM8fdkdQbd1RGfSI3ibvp1BwApX+oAAP8dJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxCAhgBgkBBCDhABikBBADBICiEFCADEdEt6+f55/GirCmJeJMBQj731LaV25hEW5wcfHcTCUAYOOZbWuUMLS3Bdinb1XH6adsLiX1b0qCRvuj0uwyPYbTtIe2FuU2L0SCe25K6ofxSitZQkgOfSndTtTrel85HpK6V6+hONMPWNY4aZ/r9ucKniY2vKoVIy4d7rOVJJMCY1pqmcQb2t6AGO80gyn69flSTnruaSHiSySJmFw5EUZbsdfQSkVLRnsUVOCRZbtDKNSsbnzlg/mSJgy8vQMz2v2jDx4EwWzpSyV2KjTpfo9bKjoWD9Bwsiu6g5f8MmUGJH8KSt4txKdy1Qe1f1YJ/xsrZCEKRurmHd1Zsuy8RXc2xHuyJen2pBOAx0V/RKucO8mflCS357t45r9Z9eRPFIuvp1+/RzVnRI2NGv2+dkMvjs7njwlXlZ4X4zZtMFy7n1pDbRn8EjYduzsT6rmVD3jo0PZfLYG5SryrHw5+hiHmZOwevyni1cEcB+jthkL9RtkOApWVM6+uLBLU6kev5qQsGdjs5duXd3B4pIZyw/W+C6oiOQosaaBD5IlLEh4WKuts5ZC2hlrD1bzOAZF3Y/JSZOwINuo3Dojv8SYq1nhLeCl7lUM/IhHwro0RxX7O2v5Kr7QmNPRvgVsNpfV/8fMCi9+e0x6D/Yz8L6+hPdV/wqShIE/NhvKBSSUs82wd2KnoSChlQ2GvR97DAUJAcQgIYAYJAQQg4QAYpAQQAwSAohBQgAxSAggBgkBxCAhgBgkBBCDhABikBBADBICiEFCADFICCAGCQHEICGAmF9ogHlmP+PZFwAAAABJRU5ErkJggg=="}}}	draft
ae5892cf-9769-4a96-8185-c2987d1809c7	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	{"B_i": {"answer": "Yes", "remarks": "Dataset includes customer financial behaviour and transaction history, classified as sensitive personal financial data under UU PDP."}, "B_v": {"answer": "Yes", "remarks": "Customer consent for AI/ML model development is covered under the digital banking service agreement signed at account opening."}, "D_i": {"answer": "Yes", "remarks": "The credit risk scoring model utilises gradient boosting machine learning algorithms to predict default probability based on customer transaction patterns and financial behaviour data."}, "B_ii": {"answer": "Yes", "remarks": "Data is pseudonymized and aggregated prior to sharing. PII fields are masked and access is restricted to the authorized analytics team only."}, "B_iv": {"answer": "Yes", "remarks": "Written consent has been obtained through customer onboarding agreements and terms of service covering data use in credit risk assessment."}, "B_vi": {"answer": "Yes", "remarks": "All data processing is conducted within PT Finansial Nusantara's secured analytics environment with role-based access controls and audit logging."}, "A_i_1": {"answer": "No", "remarks": "Credit risk data is used for internal analytics only; no revenue cannibalization risk identified."}, "A_i_2": {"answer": "No", "remarks": "Data is pseudonymized before sharing; customer identity is protected throughout the process."}, "A_i_3": {"answer": "No", "remarks": "No other commercial interest risks have been identified for this data sharing request."}, "B_iii": {"answer": "Yes", "remarks": "Transaction records and credit history contain personal financial data subject to the Personal Data Protection Law (UU PDP No. 27/2022)."}, "C_i_1": {"answer": "No", "remarks": "OJK regulations on credit scoring and data sharing have been reviewed; this request complies with applicable banking sector regulations."}, "C_i_2": {"answer": "No", "remarks": "Data sharing is compliant with UU PDP No. 27 of 2022; appropriate technical and organisational safeguards are in place."}, "C_i_3": {"answer": "No", "remarks": "Internal data governance policy and data sharing SOP have been reviewed; this request is fully compliant with internal regulations."}, "A_ii_1": {"answer": "No", "remarks": "No highly confidential partnership information is included in the requested dataset."}, "A_ii_2": {"answer": "No", "remarks": "Dataset contains transactional and behavioural data only; no patent-related information involved."}, "A_ii_3": {"answer": "No", "remarks": "No merger or acquisition information is included in the scope of this data sharing."}, "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets identified within the requested credit data dataset."}, "sign_off": {"remarks": "All data governance requirements have been reviewed and verified. This data sharing is approved for credit risk model development purposes only.", "approved": "Yes", "prepared_by": "Dian Pratiwi", "prepared_date": "", "acknowledged_by": "Dewi Rahayu", "acknowledged_date": "", "prepared_position": "Head of Analytics", "prepared_signature": "", "acknowledged_position": "Senior Data Scientist", "acknowledged_signature": ""}}	draft
1b751499-4ac7-434b-a48d-8cd0c88a7d66	724230d4-37c0-4791-a898-2cdda92c1f8a	\N	\N	{}	draft
6ae7c72b-400c-4d30-b87d-e35878cd8180	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	{"B_i": {"answer": "Yes", "remarks": "Dataset may contain customer and operational information classified as sensitive."}, "B_v": {"answer": "Yes", "remarks": "Consent for analytics and AI/ML use is obtained through service agreements and internal approvals."}, "D_i": {"answer": "Yes", "remarks": "Data may be used for AI/ML-based analytics such as forecasting, prediction, and operational optimization."}, "B_ii": {"answer": "Yes", "remarks": "Data is pseudonymized/masked and access is restricted to authorized personnel only."}, "B_iv": {"answer": "Yes", "remarks": "Written consent is covered under customer agreements and privacy notices."}, "B_vi": {"answer": "Yes", "remarks": "All data processing is conducted within secured environments with limited, role-based access and audit logging."}, "A_i_1": {"answer": "No", "remarks": "No revenue cannibalization risk; data is used for internal integration and reporting purposes only."}, "A_i_2": {"answer": "No", "remarks": "Customer data is handled under internal data protection policies; customer relationship risk is mitigated."}, "A_i_3": {"answer": "No", "remarks": "No other commercial interest risks have been identified for this data sharing request."}, "B_iii": {"answer": "Yes", "remarks": "Dataset contains personal data elements under UU PDP No. 27 Tahun 2022."}, "C_i_1": {"answer": "No", "remarks": "No violations of automotive industry regulations or compliance requirements identified."}, "C_i_2": {"answer": "No", "remarks": "Compliant with UU PDP No. 27 Tahun 2022 and applicable data protection regulations."}, "C_i_3": {"answer": "No", "remarks": "Compliant with internal data governance policies, SOPs, and enterprise security standards."}, "A_ii_1": {"answer": "No", "remarks": "The dataset does not contain confidential partnership or strategic collaboration information."}, "A_ii_2": {"answer": "No", "remarks": "No patent, intellectual property, or proprietary technical information is included."}, "A_ii_3": {"answer": "No", "remarks": "No merger, acquisition, or corporate restructuring information is included."}, "A_ii_4": {"answer": "No", "remarks": "No other commercial secrets have been identified within the requested dataset."}, "sign_off": {"remarks": "Data sharing for PRJ-2026-018 (Enterprise Data Integration Platform Implementation) is intended to support enterprise reporting, operational monitoring, and analytics across authorized Astra business units. The shared datasets include operational and transactional data from after sales, service, inventory, billing, and related systems. All sensitive and personal data are protected through pseudonymization, access control, and encryption. The activity complies with applicable laws and internal governance policies, and any AI/ML usage is limited to internal analytics and business improvement purposes.", "approved": "Yes", "prepared_by": "Bambang Budi Santoso", "acknowledged_by": "Adi Kurniawan", "prepared_position": "Head of IT Dept Head", "acknowledged_position": "Data Analyst"}, "ai_assessment": {"items": {"input_1": {"status": "No", "remarks": "Dataset contains personal and sensitive operational data; mitigated using pseudonymization"}, "input_2": {"status": "Yes", "remarks": "Sensitive data is pseudonymized before being processed by AI models"}, "input_3": {"status": "Yes", "remarks": "Prompts are standardized, documented, and reviewed for compliance"}, "output_1": {"status": "Yes", "remarks": "Outputs are validated by BI team using reporting systems and trusted datasets"}, "output_2": {"status": "Yes", "remarks": "All generated scripts are reviewed and tested before deployment"}, "before_use_1": {"status": "Yes", "remarks": "Fully compliant with applicable regulations; AI usage limited to internal analytics purposes"}, "before_use_2": {"status": "Yes", "remarks": "AI tools are enterprise-approved and comply with IT security standards"}, "before_use_3": {"status": "Yes", "remarks": "All configurations set to prevent data retention and training usage"}, "utilization_1": {"status": "Yes", "remarks": "Outputs require BI team validation and data owner approval before use"}, "utilization_2": {"status": "Yes", "remarks": "Outputs are corrected and revalidated before distribution"}}, "sign_off": {"approved": "Yes", "prepared_by": "Agus Setiawan", "acknowledged_by": "Adi Kurniawan", "prepared_position": "Senior Data Engineer", "acknowledged_position": "Data Analyst"}}}	draft
\.


--
-- Data for Name: ai_provider_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_provider_configs (id, provider, mode, enabled, base_url, model_name, timeout_seconds, batch_size, encrypted_api_key, api_key_last4, updated_by, created_at, updated_at) FROM stdin;
a7748f4b-2022-49f1-b7c4-fd647d0d726f	ollama	local	t	http://ollama:11434	llama3.2:3b	120	5	\N	\N	\N	2026-05-21 09:47:41.161635+00	2026-05-22 08:53:29.177606+00
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
344	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-13 06:07:05.136783+00
33	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:54:55.569057+00
35	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:56:44.828735+00
43	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:22:58.608093+00
45	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:25:22.813823+00
51	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:32:42.324923+00
34	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:54:55.570676+00
37	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:01:56.687765+00
39	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:09:45.951067+00
44	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:22:58.712549+00
47	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:26:24.096308+00
49	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:30:41.622372+00
54	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:33:12.68875+00
36	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 07:56:45.019262+00
38	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:01:56.68509+00
46	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:25:22.817797+00
40	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:09:45.974054+00
41	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:11:51.941636+00
48	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:26:24.090313+00
52	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:32:42.475033+00
42	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:11:51.944022+00
50	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:30:41.617225+00
53	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 08:33:12.678234+00
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
97	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	login	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:22:32.542309+00
85	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:06.910074+00
91	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 01:37:11.702241+00
96	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:13:36.578266+00
86	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:06.910383+00
89	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:35:41.316203+00
94	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:02:36.76805+00
95	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:13:36.559403+00
87	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:07.184515+00
88	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:33:07.475399+00
90	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-06 09:35:41.31902+00
93	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 02:02:36.764815+00
92	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 01:37:23.349883+00
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
1008	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"stamped": 93}	\N	\N	2026-05-19 08:20:22.786981+00
129	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:36:48.66704+00
131	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:43:52.237075+00
132	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	login	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:49:03.843777+00
130	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 03:43:52.238219+00
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
157	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:36.709725+00
156	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 04:47:36.711233+00
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
172	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:05.954895+00
175	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:06.453515+00
171	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:05.921253+00
173	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:06.065923+00
174	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 05:12:06.444818+00
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
209	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:04.449244+00
211	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:16.223124+00
215	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:14:49.408793+00
206	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:02.276246+00
207	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:02.283611+00
210	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:04.453945+00
216	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:14:49.414404+00
208	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:04.448107+00
213	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:16.232989+00
212	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:13:16.226922+00
214	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:14:49.412943+00
219	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:11.619816+00
221	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:13.034092+00
217	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:11.619778+00
220	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:13.03347+00
218	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 06:58:11.617817+00
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
258	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:19.171659+00
259	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:49.41757+00
264	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:27:46.78248+00
265	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:29:22.096513+00
269	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:34:13.289563+00
254	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:17:03.098789+00
257	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:19.174449+00
261	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:25:23.076962+00
266	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:29:22.100358+00
255	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:17:03.114029+00
268	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:30:50.068129+00
272	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:41:56.485831+00
256	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:17:03.106606+00
260	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:19:49.422896+00
262	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:25:23.121232+00
263	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:27:46.754564+00
267	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:30:50.046803+00
270	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:34:13.304083+00
271	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-07 08:41:56.454408+00
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
287	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:46:05.483386+00
286	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 01:46:05.483527+00
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
304	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:51:43.218962+00
301	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:10:13.803884+00
302	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:10:13.803842+00
303	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-08 03:51:43.220795+00
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
1139	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-19 12:21:20.277543+00
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
342	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:06:50.866591+00
343	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-13 06:07:01.089861+00
365	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:44:12.787089+00
366	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:44:21.813023+00
368	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.121375+00
372	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:23:03.630949+00
375	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:27:49.097426+00
377	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.58513+00
382	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:52.977032+00
339	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:02:02.649749+00
340	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:06:50.840986+00
346	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:09:13.405763+00
348	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-13 06:10:42.310928+00
349	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:13:39.20903+00
352	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:20:02.879555+00
354	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:20:02.918118+00
356	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:26:12.695206+00
362	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:43:21.185333+00
363	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:43:55.923322+00
376	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:27:49.106169+00
341	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:06:50.87571+00
345	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:09:13.398604+00
351	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:13:39.242935+00
353	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:20:02.903482+00
355	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:26:12.692174+00
357	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:19.468722+00
359	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:21.960759+00
361	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:43:21.142331+00
367	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.112371+00
347	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:09:13.409971+00
350	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:13:39.205555+00
358	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:19.472413+00
360	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 06:33:21.960736+00
364	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	5f8cf746-6035-447a-9cfa-3694bd423aaa	\N	\N	\N	2026-05-13 06:44:10.400166+00
369	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.152136+00
371	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:23:03.576532+00
373	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:25:18.437363+00
378	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.585664+00
380	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.586318+00
381	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:52.95603+00
370	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:17:35.173552+00
374	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:25:18.439456+00
379	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 07:44:42.585706+00
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
425	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:24:32.344651+00
432	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:11.384058+00
436	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:41:32.151013+00
438	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:41:32.322303+00
439	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:44:49.471481+00
444	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:46:52.214408+00
447	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:56.221216+00
448	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:57.225357+00
451	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:40:19.511129+00
454	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.832485+00
457	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:58:04.810225+00
459	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:00:20.485411+00
464	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:04:16.566148+00
465	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:19.933054+00
468	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:30.379231+00
471	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:45.508507+00
413	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:06:00.411685+00
417	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:08:23.563959+00
424	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:24:32.276353+00
427	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:08.14864+00
430	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:11.353962+00
434	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:36:32.201513+00
437	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:41:32.280039+00
452	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:40:19.500405+00
461	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:00:20.508652+00
462	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:04:16.535209+00
414	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:06:00.467259+00
422	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:23.006292+00
431	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:11.353804+00
440	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:44:49.453362+00
443	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:46:52.214563+00
449	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:57.272401+00
467	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:19.951992+00
415	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:08:23.52308+00
418	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:01.859547+00
423	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:23.020017+00
428	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:08.148414+00
433	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:36:32.200125+00
442	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:46:40.913086+00
445	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:33.18207+00
460	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:00:20.502589+00
463	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:04:16.537485+00
473	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:45.510127+00
416	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:08:23.546435+00
426	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:24:32.368943+00
429	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:35:08.213956+00
435	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:36:32.205598+00
441	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:44:49.46176+00
458	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:58:04.835631+00
472	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:45.506875+00
419	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:01.934284+00
455	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.80224+00
470	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:30.387076+00
420	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:01.935447+00
446	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:32:33.358089+00
450	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:40:19.443935+00
421	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-13 09:15:22.975435+00
453	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.803624+00
456	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 01:57:36.981651+00
466	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:19.941414+00
469	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:07:30.380909+00
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
518	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:31.485181+00
503	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:50:13.638295+00
506	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:30.080578+00
538	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:58.763332+00
569	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:09.285891+00
571	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:23.195606+00
766	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:42:16.868301+00
767	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:42:43.065955+00
768	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:42:49.549368+00
772	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:59:16.772523+00
783	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:45:43.131821+00
789	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:47:49.083413+00
830	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:00:25.60976+00
831	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:04:27.349873+00
898	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.205454+00
900	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:35:31.697489+00
903	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:51:57.679385+00
911	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:08:11.68316+00
921	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:25:08.070386+00
923	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	\N	\N	\N	2026-05-19 03:30:44.856822+00
924	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	\N	\N	\N	2026-05-19 03:30:46.679624+00
926	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-19 03:31:52.565343+00
927	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:31:56.031625+00
930	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:47:26.62426+00
933	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:44.916799+00
978	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:40:01.899121+00
992	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:09.813218+00
1003	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:00:39.511411+00
1087	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 24, "table": "customer_data.xlsx - Sheet1", "grouping": "Customer"}	\N	\N	2026-05-19 09:21:16.860472+00
1185	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:41:54.54392+00
1193	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:03.738791+00
1195	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	ad670b81-df3b-4fc0-898c-b64b3098a186	\N	\N	\N	2026-05-20 08:03:34.372831+00
504	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:29.953656+00
507	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:43.022861+00
511	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:55:01.831015+00
513	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:17.849856+00
517	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:31.46202+00
519	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:05:10.818537+00
523	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:10:40.237173+00
536	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:52.172612+00
572	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:34:35.260847+00
573	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:34:35.314647+00
574	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:34:35.338334+00
578	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:49:36.544966+00
590	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:09.981217+00
593	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:12.208649+00
627	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:53:47.771539+00
648	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:16:11.567969+00
656	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:40:18.025381+00
659	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:50:52.564905+00
662	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:59:02.732009+00
703	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:37.975145+00
704	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:56.845656+00
706	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:59.806278+00
769	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:42:49.555099+00
770	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:43:25.526332+00
773	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:59:16.772543+00
774	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:18:57.222321+00
776	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:19:00.02677+00
778	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 05:19:12.420486+00
779	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:10.355095+00
781	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:11.51908+00
785	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:08:38.733215+00
788	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:09:09.464884+00
508	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:43.036725+00
524	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:10:40.258693+00
575	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:40:10.898853+00
576	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:40:10.948722+00
600	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.665728+00
601	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:07.79386+00
602	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:07.831995+00
603	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:07.906691+00
618	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:33:23.69481+00
642	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:11:10.720119+00
646	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:16:11.569869+00
705	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:56.884161+00
707	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:07:59.814863+00
771	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:43:25.685305+00
775	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:18:57.285307+00
777	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:19:00.033636+00
791	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:48:26.301579+00
799	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:18:12.809236+00
832	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:04:27.427048+00
833	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:08:39.754505+00
906	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.799693+00
917	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	submit	dsr	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	{"tracking_id": "DSR-2026-0003"}	\N	\N	2026-05-19 03:22:02.684664+00
983	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:48:50.559384+00
986	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:20.50992+00
987	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:25.456894+00
991	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:09.771009+00
994	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:10.442923+00
996	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:29.418758+00
1001	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:00:39.470091+00
1088	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:53.99545+00
1092	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:48.633909+00
1186	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:41:54.610705+00
1188	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	ad670b81-df3b-4fc0-898c-b64b3098a186	\N	\N	\N	2026-05-20 07:44:50.377858+00
509	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:43.031985+00
527	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:13:57.897347+00
577	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:40:10.960829+00
586	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:57:47.997924+00
588	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:09.975705+00
592	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:12.206622+00
597	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.418165+00
608	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:20:06.061213+00
617	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:33:23.761178+00
640	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:10:21.783223+00
649	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:20.924172+00
658	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:50:51.681527+00
660	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:59:02.556699+00
708	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:20.561258+00
709	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:20.604531+00
710	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:25.305017+00
713	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:27.336544+00
715	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:39.084918+00
717	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:15:12.317844+00
723	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:25:13.311776+00
724	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:28:26.70531+00
780	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:10.418263+00
782	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:37:11.545156+00
790	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:47:49.185382+00
792	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:48:26.417041+00
793	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:54:01.413522+00
795	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:00:56.655539+00
796	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:00:56.696414+00
797	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:02:51.119591+00
835	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:14:04.857565+00
941	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:35:41.587812+00
944	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:09.911162+00
510	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:55:01.830073+00
526	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:13:57.830226+00
530	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:14:13.810882+00
531	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:29:18.82616+00
537	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:58.765076+00
579	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:49:36.54311+00
583	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:51:15.885761+00
589	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:09.977572+00
598	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.416712+00
605	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:15:47.739519+00
607	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:20:06.013683+00
609	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:20:06.093251+00
613	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:25:58.11072+00
615	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:27:10.372334+00
626	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:53:47.757547+00
628	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:54:15.619312+00
633	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:59:46.801803+00
636	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:05:53.445869+00
647	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:16:11.571993+00
651	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:23.04758+00
711	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:25.309881+00
712	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:27.336159+00
714	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:14:39.085435+00
716	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:15:12.315825+00
718	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:20:27.045766+00
719	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:20:27.069739+00
720	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:22:59.421894+00
721	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:22:59.438542+00
722	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:25:13.307605+00
784	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 05:45:43.28659+00
794	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:54:01.413618+00
803	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:47:52.448604+00
514	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:17.850904+00
516	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:31.452778+00
520	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:05:10.807408+00
522	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:10:40.234461+00
525	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:13:57.827552+00
528	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:14:13.663097+00
533	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:33:11.932906+00
535	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:45:52.156883+00
580	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:49:36.546519+00
595	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:10:09.538822+00
596	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.361396+00
614	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:26:32.401263+00
623	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:49:46.703431+00
629	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:54:15.614013+00
632	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:59:46.745628+00
641	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:11:10.71591+00
644	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:12:02.922613+00
725	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:28:26.708255+00
786	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:08:38.765563+00
787	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 06:09:09.452262+00
798	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:02:51.132866+00
800	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:41:17.190087+00
836	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:14:04.986654+00
942	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:35:41.475689+00
945	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:09.91195+00
949	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.664118+00
1004	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:14:13.737245+00
1089	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:54.03256+00
1187	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	create	project	ad670b81-df3b-4fc0-898c-b64b3098a186	{"project_name": "Customer 360 Analytics and Personalization Platform", "customer_name": "Astra International – Digital Transformation Division"}	\N	\N	2026-05-20 07:44:22.733017+00
1189	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	create	dsr	724230d4-37c0-4791-a898-2cdda92c1f8a	{"tracking_id": "DSR-2026-0004"}	\N	\N	2026-05-20 07:45:26.039319+00
1191	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:03.734261+00
521	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:05:10.828653+00
534	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:33:11.974242+00
582	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:51:15.861467+00
587	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 06:57:56.240809+00
591	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:58:12.201132+00
604	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:15:47.7349+00
610	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:20:45.390059+00
616	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:27:27.527062+00
620	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:48:30.847914+00
622	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:49:46.685206+00
624	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 07:51:05.326561+00
625	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:53:47.726963+00
635	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:05:47.981446+00
638	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:05:53.447864+00
652	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:23.049819+00
654	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:40:17.904721+00
664	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:24:39.188878+00
726	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:35:43.566417+00
727	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:35:43.590693+00
801	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:41:17.025379+00
837	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:20:12.549702+00
943	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:35:41.712385+00
951	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:17.630101+00
1005	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:20:07.207546+00
1006	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:20:07.277591+00
1090	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:54.045418+00
1103	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.511647+00
1107	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.91358+00
1108	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:30.834685+00
1113	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.656274+00
1128	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	\N	\N	\N	2026-05-19 11:45:37.951671+00
1134	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:58.944002+00
1190	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:03.728152+00
539	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:58:09.33479+00
542	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	create	dpia	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	\N	\N	\N	2026-05-15 03:59:20.637026+00
581	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:51:15.853455+00
585	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:57:48.011084+00
594	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	\N	\N	\N	2026-05-15 06:58:23.421022+00
612	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:25:58.035623+00
621	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:49:46.655452+00
630	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:54:15.615177+00
631	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:59:46.555592+00
639	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:10:21.77112+00
645	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	submit	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:12:06.055609+00
650	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:18:20.932056+00
653	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:33:53.993766+00
655	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:40:18.055369+00
728	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:51:07.901824+00
802	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:47:52.437807+00
838	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:20:12.567611+00
840	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 09:20:37.555517+00
842	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:21:12.055067+00
844	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 09:21:45.966377+00
946	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:09.949929+00
1007	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:20:07.356589+00
1091	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:21:54.041573+00
1093	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:48.879408+00
1096	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.559174+00
1106	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.907634+00
1118	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:52.056364+00
1124	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:30:33.551775+00
1127	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:45:37.87583+00
1129	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-19 11:46:11.92494+00
1142	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.306733+00
1146	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.836257+00
1151	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.494639+00
1152	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 13:03:55.114798+00
1192	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:03.735468+00
540	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:58:23.335334+00
543	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:34:21.014774+00
584	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:57:47.954285+00
611	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:25:57.948563+00
619	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:33:23.825318+00
634	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dpia	update	dpia	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	\N	\N	\N	2026-05-15 08:00:25.268044+00
637	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:05:53.445814+00
657	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:50:51.683195+00
661	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:59:02.558878+00
663	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:24:39.191987+00
729	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:58:24.955863+00
736	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:08:21.810216+00
804	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:59:13.508162+00
805	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 07:59:13.506077+00
806	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:18.147595+00
809	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:30.31704+00
810	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:13:18.012522+00
811	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:13:18.019559+00
839	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:20:12.573273+00
843	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:21:12.057743+00
947	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.68052+00
952	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:17.663761+00
1094	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:49.003448+00
1115	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.991538+00
1121	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:22:08.73785+00
1122	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:30:33.54679+00
1135	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:58.944002+00
1147	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.843492+00
1194	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-20 07:58:03.983564+00
541	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:58:23.343157+00
599	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:14:03.393989+00
606	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 07:15:47.752167+00
643	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 08:11:10.730363+00
730	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 03:58:24.979468+00
732	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:02:41.737621+00
733	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:05:57.009828+00
735	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:08:21.829152+00
807	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:18.240085+00
808	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:08:30.310309+00
841	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:21:12.04189+00
948	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.665383+00
1009	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:23:53.357781+00
1012	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:28:06.239996+00
1015	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:31:05.138471+00
1021	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:38:19.026869+00
1022	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:38:19.08665+00
1024	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:50.669706+00
1025	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:50.75242+00
1030	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.939363+00
1032	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:17.580692+00
1036	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.209157+00
1038	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.2402+00
1041	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.437486+00
1043	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.474983+00
1044	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.364663+00
1045	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.504883+00
1047	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.589231+00
1048	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.568383+00
1052	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.612536+00
1056	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.632692+00
1057	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.679696+00
544	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:34:21.077873+00
665	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:27:44.988334+00
667	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:27:45.032615+00
668	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:34:12.150324+00
671	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 10:03:19.534983+00
731	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:02:41.676962+00
734	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:05:57.019659+00
812	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:15:49.226019+00
845	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:36:34.480149+00
846	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:36:34.47969+00
849	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:39:50.128919+00
950	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:14.810693+00
1010	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:23:53.360382+00
1013	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:28:06.242025+00
1016	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:31:05.152605+00
1017	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:31:05.19177+00
1019	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:35:29.664432+00
1062	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.143066+00
1066	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.039157+00
1082	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.673015+00
1095	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:27:49.766761+00
1098	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.62976+00
1119	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:52.0598+00
1133	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:09:18.083568+00
1137	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:59.003307+00
1141	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.571852+00
1145	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.820055+00
546	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:03.587277+00
545	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:03.587459+00
547	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:11.142018+00
548	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 04:49:11.151965+00
549	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:16.699502+00
551	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:25.14148+00
666	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:27:45.00531+00
670	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 10:03:19.522151+00
737	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:11:57.609944+00
740	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:12:01.358052+00
741	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:15:39.426555+00
813	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:15:49.239643+00
847	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:36:34.493564+00
848	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:39:50.12196+00
953	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:01:17.646733+00
1011	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:23:53.361318+00
1014	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:28:06.254556+00
1034	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:17.542781+00
1050	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.693996+00
1053	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.656564+00
1054	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.710115+00
1063	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.184173+00
1075	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.730914+00
1097	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.558788+00
1123	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:30:33.646916+00
1143	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.350894+00
1144	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:33.750918+00
1155	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 13:03:55.132416+00
550	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:16.82137+00
552	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:28:25.144728+00
669	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 09:34:12.17896+00
738	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:11:57.613313+00
739	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:12:01.35502+00
814	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:29:29.394456+00
815	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:29:59.225216+00
850	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:39:50.134002+00
954	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:16:27.874099+00
955	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:23:04.049715+00
958	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:32.372154+00
961	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:59.483434+00
963	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:02.97237+00
969	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:08.639177+00
972	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:12:45.921958+00
1018	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:35:29.661861+00
1023	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:38:19.097763+00
1026	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:50.773322+00
1029	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.913836+00
1031	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.955064+00
1037	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.208217+00
1039	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:47:43.261543+00
1040	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.404599+00
1042	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:50:38.457559+00
1046	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:53:48.545812+00
1049	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.568306+00
1058	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.692+00
1061	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.205637+00
1065	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.028912+00
1070	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.406955+00
1073	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.720288+00
1078	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.234238+00
553	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:43:21.264449+00
554	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:43:21.288402+00
555	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:54:13.912388+00
742	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:17:04.631693+00
744	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:17:27.794763+00
747	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:22:50.82588+00
816	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:30:00.20255+00
817	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:36:00.683362+00
818	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:36:00.753179+00
819	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:36:00.781783+00
851	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:54:51.539818+00
852	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:05:10.816637+00
855	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:06:27.784081+00
859	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:07:04.836931+00
860	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:07:04.855977+00
868	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:27:13.325714+00
883	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:35.004625+00
887	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:47.818782+00
888	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:05:11.940201+00
892	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:20:12.817219+00
895	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.033387+00
909	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.842511+00
929	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:31:56.046671+00
931	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:02:31.863298+00
956	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:23:04.019007+00
957	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:32.37202+00
968	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:05.360677+00
1020	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:35:29.910804+00
1027	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:41:51.084256+00
1028	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:42:04.913805+00
1033	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:17.580618+00
1055	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:00:39.657583+00
1067	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.060018+00
556	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 05:54:13.928403+00
743	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:17:04.655769+00
745	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:22:28.166016+00
749	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:00.881818+00
750	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:09.128943+00
755	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:26:10.57155+00
820	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:45:25.45977+00
821	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:45:26.545037+00
825	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:51:41.237237+00
853	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:05:10.84471+00
857	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:06:27.840903+00
866	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:55.381027+00
867	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:27:13.325699+00
901	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:35:31.732925+00
904	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:51:57.678748+00
908	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.84056+00
914	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	create	dsr	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	{"tracking_id": "DSR-2026-0003"}	\N	\N	2026-05-19 03:18:36.664868+00
916	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update	dsr	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:21:58.359501+00
935	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:45.22849+00
959	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:32.514628+00
960	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:59.464459+00
964	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:02.972048+00
966	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:05.350182+00
971	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:12:45.9234+00
1035	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:45:19.333431+00
1051	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:57:18.714654+00
1099	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:39:52.588839+00
1100	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.377302+00
1101	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.494846+00
1105	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.912603+00
1110	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:30.831989+00
1114	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.672115+00
1120	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"stamped": 27}	\N	\N	2026-05-19 11:11:45.422894+00
557	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:07:11.453643+00
559	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:12:04.69156+00
563	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:18:30.237512+00
567	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:09.074313+00
746	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:22:28.234047+00
748	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:00.882522+00
752	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:24:34.736996+00
754	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:24:47.056132+00
822	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:45:26.599225+00
854	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:05:10.900455+00
856	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:06:27.783675+00
858	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:07:04.825004+00
861	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:05.384038+00
870	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	login	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:37:10.091099+00
871	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:38:11.042438+00
873	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:03.125874+00
877	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:16.155243+00
880	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:17.968946+00
882	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:35.004031+00
890	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:05:11.95678+00
896	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.001543+00
907	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.839364+00
920	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:24:56.755902+00
925	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-19 03:31:38.840988+00
934	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:44.903496+00
938	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.7207+00
962	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:31:59.567785+00
973	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:12:45.94491+00
1059	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:04:33.69768+00
1060	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:19.154982+00
1064	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:06:56.027252+00
1068	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.328234+00
1069	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.387838+00
558	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:07:11.485309+00
562	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:18:30.23884+00
568	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:09.074937+00
570	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:23.19153+00
751	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:23:09.159255+00
753	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:24:34.742595+00
756	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:26:10.582323+00
823	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:50:57.380239+00
824	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:50:57.43936+00
862	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:05.363956+00
864	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:55.359405+00
869	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:27:13.328725+00
875	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:03.551861+00
878	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:16.156332+00
881	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:17.970121+00
884	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:35.040837+00
885	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:47.777392+00
889	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:05:11.941021+00
897	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.008814+00
905	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:57:06.799622+00
912	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:08:11.684484+00
919	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:22:11.974023+00
922	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:25:08.701169+00
928	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:31:56.030194+00
939	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.726603+00
940	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.926+00
965	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:02.969963+00
967	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:05.434053+00
970	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 06:57:08.638837+00
1071	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:10:10.416402+00
1072	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.724297+00
1079	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.234272+00
560	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:12:04.696259+00
565	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:02.611202+00
757	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-18 04:27:37.753923+00
758	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:43.651462+00
760	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:45.808545+00
763	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:20.816382+00
764	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:47.652068+00
826	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:51:41.247757+00
863	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:05.397289+00
865	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:09:55.370492+00
874	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:03.54692+00
876	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:16.146944+00
879	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:46:17.969788+00
886	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 01:51:47.782244+00
893	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:20:12.816806+00
910	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:08:11.68122+00
915	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	dsr	update_checklist	ai_checklist	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	\N	\N	\N	2026-05-19 03:21:58.323651+00
932	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:17:44.892083+00
936	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.704635+00
974	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:38:26.291943+00
980	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"rows": 9, "table": "PRJ018_AI_Analytics.xlsx - AI", "grouping": "Service Prediction"}	\N	\N	2026-05-19 07:42:13.37155+00
982	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:48:50.511962+00
988	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:25.458732+00
990	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:09.724062+00
993	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:56:10.442896+00
995	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:29.413207+00
998	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:30.212999+00
1002	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 08:00:39.486536+00
1074	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:14:22.729437+00
1076	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.178855+00
1077	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:17:02.220973+00
1085	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 23, "table": "car_sales_data.xlsx - Sheet1", "grouping": "Sales"}	\N	\N	2026-05-19 09:20:48.174016+00
1086	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 24, "table": "car_demand_data.xlsx - Sheet1", "grouping": "Demand"}	\N	\N	2026-05-19 09:21:03.495599+00
561	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:18:30.122676+00
564	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:02.601927+00
759	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:43.722422+00
761	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:27:45.810237+00
765	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:47.69117+00
827	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:56:23.945431+00
872	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 10:38:11.096113+00
891	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:06:52.047276+00
975	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:38:26.768493+00
979	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:40:01.936922+00
981	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:48:50.520254+00
984	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:20.440027+00
985	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:20.493753+00
989	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:52:25.458396+00
1080	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.640598+00
1084	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"rows": 22, "table": "car_stock_data.xlsx - Sheet1", "grouping": "Stock"}	\N	\N	2026-05-19 09:20:35.850039+00
1102	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:23.510778+00
1104	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:50:29.905651+00
1109	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:30.830977+00
1111	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:31.204281+00
1112	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 10:58:34.637584+00
1116	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:51.894223+00
1117	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:06:52.037728+00
1125	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-19 11:32:02.437138+00
1126	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	update	project	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-19 11:33:10.528474+00
1130	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:54:14.287379+00
1132	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	\N	\N	\N	2026-05-19 11:54:34.72532+00
1136	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:18:58.915402+00
1138	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	{"stamped": 33}	\N	\N	2026-05-19 12:20:56.823321+00
1149	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.449082+00
1153	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 13:03:55.131059+00
566	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 06:30:02.565727+00
762	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.4	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 04:28:20.780581+00
828	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 08:56:23.945092+00
829	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:00:25.606518+00
834	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-18 09:08:39.618181+00
894	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:22:57.001715+00
899	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:35:31.694654+00
902	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 02:51:57.675229+00
913	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	project	create	project	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	{"project_name": "Enterprise Data Integration Platform Implementation", "customer_name": "Astra UD Trucks"}	\N	\N	2026-05-19 03:17:28.948382+00
918	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 03:22:11.973526+00
937	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	auth	token_refresh	user	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 04:18:42.707715+00
976	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:38:28.380807+00
977	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:40:01.870709+00
997	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:29.37963+00
999	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:30.220923+00
1000	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 07:59:30.24182+00
1081	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.645701+00
1083	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 09:20:17.69166+00
1131	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 11:54:14.289608+00
1140	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:41:29.169794+00
1148	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.418506+00
1150	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 12:47:45.489503+00
1154	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.3	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-19 13:03:55.138544+00
502	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:50:13.574809+00
505	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:54:30.019779+00
512	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:55:01.833677+00
515	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 02:57:17.853754+00
529	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:14:13.665277+00
532	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.18.0.9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	2026-05-15 03:33:11.961463+00
1196	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 06:04:28.340714+00
1197	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 06:11:26.341325+00
1198	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 06:11:26.342084+00
1199	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:04:43.422187+00
1200	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:04:44.177386+00
1201	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:04:45.04622+00
1202	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:04:45.050222+00
1203	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:13:49.986564+00
1204	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:13:50.037759+00
1205	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:13:50.059232+00
1206	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:13:50.056142+00
1208	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:16:13.962798+00
1210	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:35:44.156951+00
1211	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:35:44.205128+00
1207	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:16:13.951402+00
1209	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:31:35.223143+00
1214	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:45:53.723122+00
1216	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:48:35.711955+00
1212	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:41:20.497492+00
1213	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:41:20.573494+00
1215	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:45:53.733168+00
1217	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:48:35.712883+00
1218	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:48:38.716216+00
1219	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:48:38.706505+00
1221	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:48:41.308989+00
1220	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:48:41.283066+00
1222	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:21.482217+00
1223	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:21.529266+00
1224	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:22.428491+00
1225	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:22.430022+00
1226	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:25.121045+00
1227	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:25.123483+00
1228	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:32.586691+00
1229	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 07:54:32.604003+00
1230	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:00:34.505156+00
1231	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:00:34.514595+00
1232	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:00:34.594102+00
1233	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:05:59.670557+00
1234	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:05:59.670405+00
1235	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:05:59.74509+00
1236	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:06:02.071506+00
1237	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:06:02.074126+00
1238	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:06:02.109758+00
1239	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:10:55.64066+00
1240	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:10:55.649168+00
1241	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:10:55.712926+00
1242	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:14:07.734318+00
1243	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:14:07.754344+00
1244	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:14:07.770541+00
1245	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:14:14.593971+00
1246	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:14:14.594192+00
1247	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:14:14.600492+00
1248	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:16:43.32628+00
1249	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:16:43.305713+00
1250	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:16:43.387013+00
1251	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:20:57.394077+00
1252	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:20:57.41025+00
1253	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:20:57.433068+00
1261	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:22:23.0646+00
1264	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:28:36.390493+00
1271	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:34:36.467474+00
1254	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:20:59.691057+00
1257	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:21:02.343162+00
1265	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:28:36.395883+00
1270	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:34:36.440916+00
1256	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:20:59.696257+00
1258	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:21:02.346577+00
1314	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:05.179031+00
1318	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:28.778261+00
1348	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:10:45.609407+00
1367	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:56:34.085654+00
1379	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 04:07:27.528643+00
1383	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:10.91981+00
1406	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:10:35.923222+00
1417	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:33:23.947266+00
1428	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:44:14.303059+00
1431	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:48:30.914976+00
1436	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:04:00.49835+00
1452	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:48:23.068115+00
1464	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:06:51.08829+00
1690	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:50:20.381905+00
1697	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:52:26.461748+00
1702	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:53:26.830641+00
1741	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:06:23.220198+00
1746	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:07:25.454669+00
1758	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:10:18.214057+00
1775	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:24:46.795803+00
1786	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:34:25.054963+00
1848	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:20:25.273695+00
1850	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:20:26.988039+00
1852	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:23:18.183396+00
1854	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:24:36.541862+00
1861	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:40:29.611334+00
1262	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:22:23.097352+00
1266	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:30:31.975284+00
1268	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:30:32.012693+00
1273	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:39:41.377215+00
1315	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:05.183797+00
1327	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:48:09.531931+00
1330	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:53:42.770791+00
1369	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:56:34.097966+00
1372	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 03:15:37.635887+00
1375	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 04:07:27.535384+00
1381	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:10.916694+00
1434	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:48:30.922828+00
1439	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:04:00.574362+00
1443	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:13:49.709556+00
1451	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:48:23.00958+00
1465	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:06:51.090147+00
1692	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:50:20.38879+00
1699	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:53:26.831651+00
1705	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:55:40.236397+00
1742	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:06:23.221311+00
1745	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:07:25.419663+00
1748	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:07:25.467413+00
1756	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:10:18.205449+00
1776	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:24:46.795809+00
1780	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:29:16.754154+00
1784	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:29:16.78094+00
1859	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:29:32.179944+00
1274	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:39:41.383689+00
1275	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:42:50.881601+00
1316	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:05.241307+00
1317	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	python-httpx/0.27.0	2026-05-21 09:46:11.225744+00
1319	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:28.78144+00
1321	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:28.839302+00
1326	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:48:09.528444+00
1329	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:53:42.746737+00
1334	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:50:21.870757+00
1338	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:52:29.64414+00
1341	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:52:29.797635+00
1345	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:08:14.611163+00
1373	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 03:15:37.620931+00
1384	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:10.925575+00
1388	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:32.119458+00
1397	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:19:11.87897+00
1404	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:29:11.998904+00
1418	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:33:23.921501+00
1435	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:04:00.533655+00
1466	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:14:07.420311+00
1506	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:05:13.040307+00
1509	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:06:59.570244+00
1532	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:12.601084+00
1537	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:20.238235+00
1541	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:27:51.953043+00
1545	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:53.458387+00
1552	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:19.633902+00
1576	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:48:55.847858+00
1584	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:21:05.007646+00
1585	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:21:23.2447+00
1606	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-25 07:47:48.23231+00
1608	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 07:49:37.185937+00
1691	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:50:20.38392+00
1277	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:45:51.281163+00
1278	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:45:51.281188+00
1279	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:53:56.475384+00
1281	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:59:09.075161+00
1322	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:29.025196+00
1332	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:53:43.078963+00
1392	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:02:20.394317+00
1391	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:02:20.378465+00
1398	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:19:11.799751+00
1399	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:19:11.805436+00
1410	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:15:15.971268+00
1412	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:15:16.011915+00
1467	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:14:07.47713+00
1507	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:05:13.037572+00
1514	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:09:59.19935+00
1519	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:49.358265+00
1523	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:52.547776+00
1551	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:57.618905+00
1564	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:36:10.30708+00
1565	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:40:40.876681+00
1579	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:08:33.126937+00
1580	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:08:34.187681+00
1583	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:21:05.008088+00
1607	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 07:48:27.860127+00
1610	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 07:49:37.170093+00
1693	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:50:20.388612+00
1743	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:06:23.226853+00
1749	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:07:25.480548+00
1751	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:09:27.475681+00
1757	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:10:18.198477+00
1777	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:24:46.797504+00
1781	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:29:16.762876+00
1280	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:53:56.472481+00
1283	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:59:09.075119+00
1324	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:48:09.517472+00
1390	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:02:20.386786+00
1403	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:29:12.004706+00
1408	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:10:35.948514+00
1416	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:33:23.82329+00
1468	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:14:07.476356+00
1508	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:06:59.534365+00
1512	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:09:59.159268+00
1536	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:20.22699+00
1556	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:19.640725+00
1563	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:36:10.301495+00
1570	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:56:02.025013+00
1582	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:08:34.188104+00
1609	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 07:49:37.177578+00
1694	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:52:26.418673+00
1706	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:55:40.234874+00
1744	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:06:23.227147+00
1747	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:07:25.46497+00
1755	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:10:18.18103+00
1778	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:24:46.797495+00
1788	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:34:25.058951+00
1282	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:59:09.074292+00
1325	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:48:09.516307+00
1401	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:29:11.748388+00
1407	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:10:35.946271+00
1469	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:14:07.493009+00
1510	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:06:59.540466+00
1513	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:09:59.163161+00
1516	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:49.328274+00
1526	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:17:20.52855+00
1533	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:12.60652+00
1539	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:27:51.925729+00
1542	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:27:51.963768+00
1548	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:53.477356+00
1550	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:57.618917+00
1561	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:36:10.295888+00
1568	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:40:40.893052+00
1571	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:11:27.885427+00
1574	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:48:55.842158+00
1611	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 07:49:37.239004+00
1613	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-25 07:54:27.804633+00
1696	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:52:26.424691+00
1707	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:55:40.242935+00
1750	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:09:27.414045+00
1754	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:09:27.492352+00
1779	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:24:46.802258+00
1782	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:29:16.769048+00
1785	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:34:25.039653+00
1284	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:02:28.222574+00
1331	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:53:42.75222+00
1336	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:50:22.548849+00
1422	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:42:01.301926+00
1425	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:44:14.292743+00
1432	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:48:30.913394+00
1453	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:48:23.072049+00
1470	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:14:07.518339+00
1511	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:09:59.157621+00
1517	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:49.335774+00
1524	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:17:20.499287+00
1530	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:12.595016+00
1538	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:20.239255+00
1543	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:27:51.975495+00
1567	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:40:40.887157+00
1578	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:08:33.043922+00
1586	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:21:23.245609+00
1612	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 07:49:37.399671+00
1614	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"stamped": 93}	\N	\N	2026-05-25 07:55:15.929144+00
1698	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:52:26.456433+00
1752	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:09:27.477762+00
1783	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:29:16.768973+00
1789	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:34:25.063222+00
1285	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:02:28.222392+00
1286	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:06:43.623529+00
1339	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:52:29.766958+00
1423	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:42:01.320902+00
1441	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:13:49.700739+00
1450	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:35:01.638502+00
1471	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:41.004674+00
1477	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:52.446076+00
1486	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:23:16.961062+00
1490	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:26:52.281132+00
1495	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:27:08.432972+00
1500	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:47:18.252448+00
1505	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-23 08:34:23.070635+00
1515	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 03:09:59.207779+00
1518	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:49.33771+00
1522	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:50.294366+00
1527	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:17:20.574697+00
1529	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:12.599967+00
1544	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:53.452107+00
1554	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:19.638024+00
1558	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:20.242752+00
1562	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:36:10.296095+00
1572	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:24:41.925932+00
1575	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:48:55.84137+00
1577	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:08:33.042858+00
1581	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:08:34.187701+00
1615	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	\N	\N	\N	2026-05-25 07:56:16.918685+00
1620	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	\N	\N	\N	2026-05-25 07:59:22.365183+00
1621	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:01:51.911392+00
1636	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:04:35.575349+00
1642	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:12:55.599032+00
1649	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:22:55.996313+00
1654	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:24:38.254145+00
1287	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:06:43.632485+00
1289	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:12:02.158416+00
1290	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:14:44.279592+00
1293	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:14:58.792274+00
1296	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:16:56.658051+00
1342	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:52:30.160254+00
1344	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:08:14.612545+00
1346	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:10:45.558429+00
1424	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:42:01.260676+00
1426	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:44:14.247893+00
1430	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:48:30.914824+00
1449	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:19:56.216976+00
1455	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:48:23.058677+00
1472	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:41.078474+00
1476	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:52.446076+00
1481	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:20:17.85625+00
1488	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:23:17.004491+00
1520	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:49.417446+00
1521	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:12:50.265736+00
1525	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:17:20.528796+00
1531	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:12.6028+00
1535	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:20.236481+00
1546	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:53.465914+00
1555	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:19.645319+00
1566	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:40:40.885198+00
1616	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_stamp	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"stamped": 93}	\N	\N	2026-05-25 07:56:27.157877+00
1617	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	\N	\N	\N	2026-05-25 07:57:17.966409+00
1619	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	ad670b81-df3b-4fc0-898c-b64b3098a186	\N	\N	\N	2026-05-25 07:58:46.208977+00
1627	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:03:26.07953+00
1638	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:12:55.592905+00
1651	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:22:56.012484+00
1655	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:24:38.247961+00
1661	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:32:31.469866+00
1288	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:12:02.152548+00
1292	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:14:44.292526+00
1294	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:14:58.792719+00
1295	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:16:56.632827+00
1349	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:25:51.315587+00
1350	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:26:01.07137+00
1427	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:44:14.326333+00
1437	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:04:00.511793+00
1440	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:13:49.622052+00
1473	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:41.086923+00
1484	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:23:16.845325+00
1491	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:26:52.298285+00
1496	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:27:08.430285+00
1501	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:47:18.280467+00
1504	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-23 08:34:08.036839+00
1528	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:17:20.680529+00
1534	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:26:20.232959+00
1540	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:27:51.961322+00
1547	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:53.463404+00
1549	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:31:57.612615+00
1553	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:19.636754+00
1557	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:20.232082+00
1559	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:32:22.693522+00
1560	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:36:10.296016+00
1569	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 04:40:40.89436+00
1573	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 05:24:41.951674+00
1618	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	proceed	metadata	85eaf07b-2298-4658-baaa-a5e267c74812	\N	\N	\N	2026-05-25 07:57:59.869421+00
1637	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:04:35.591431+00
1643	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:13:10.285443+00
1656	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:24:38.266742+00
1675	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:42:12.205036+00
1700	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:53:26.831152+00
1291	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:14:44.28061+00
1351	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:26:01.107217+00
1355	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:27:52.248241+00
1429	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:44:14.328991+00
1447	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:19:56.215945+00
1454	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:48:23.058702+00
1474	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:41.097507+00
1478	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:52.44472+00
1483	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:20:17.869198+00
1487	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:23:16.946484+00
1492	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:26:52.317329+00
1587	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:34:03.46493+00
1588	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:34:03.467048+00
1589	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:34:30.980936+00
1591	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:34:32.573628+00
1594	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:35:00.732588+00
1595	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:36:07.529113+00
1599	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:41:07.118528+00
1601	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:49:34.636867+00
1605	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:49:34.727813+00
1622	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:01:51.917227+00
1633	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:04:24.444771+00
1640	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:12:55.597516+00
1650	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:22:56.005454+00
1673	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:40:50.134988+00
1685	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:49:05.071371+00
1701	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:53:26.833602+00
1760	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:18:20.660389+00
1761	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:18:20.743336+00
1768	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:19:29.288204+00
1787	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:34:25.0606+00
1297	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:16:56.680006+00
1352	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:26:01.284497+00
1356	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:27:52.261164+00
1438	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:04:00.551582+00
1475	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:41.097632+00
1482	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:20:17.857008+00
1502	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:47:18.249986+00
1590	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:34:30.966995+00
1592	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:34:32.577409+00
1593	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:35:00.729366+00
1597	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:36:07.53446+00
1623	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:01:51.915108+00
1626	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:03:26.075804+00
1652	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:22:56.024264+00
1657	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:24:38.259883+00
1659	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:32:31.410031+00
1663	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:38:31.663766+00
1665	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:38:31.799889+00
1676	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:42:12.207275+00
1679	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:45:45.978487+00
1681	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:45:46.042404+00
1688	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:49:05.105169+00
1708	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:55:40.259143+00
1762	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:18:20.740559+00
1770	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:20:07.672884+00
1790	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:43:50.035165+00
1817	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 01:45:04.873641+00
1819	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 01:59:09.661925+00
1298	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:18:15.649831+00
1301	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:21:47.539873+00
1302	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:21:47.556057+00
1303	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:21:47.570784+00
1353	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:26:01.322357+00
1357	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:27:52.267046+00
1456	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:53:13.295362+00
1479	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:52.491458+00
1489	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:26:52.290904+00
1494	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:27:08.429379+00
1499	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:47:18.206993+00
1596	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:36:07.529396+00
1598	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:41:07.121202+00
1602	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:49:34.679174+00
1624	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:01:51.919544+00
1631	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:03:34.263104+00
1634	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:04:24.458963+00
1646	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:13:10.30529+00
1648	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:22:55.971953+00
1653	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:24:38.2034+00
1658	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:32:31.2996+00
1660	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:32:31.437599+00
1666	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:38:31.827058+00
1672	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:40:50.127701+00
1680	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:45:46.030687+00
1687	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:49:05.09956+00
1709	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:57:48.501899+00
1710	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:57:48.563774+00
1722	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:01:15.807254+00
1729	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	batch_save	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"saved": 1, "errors": 0}	\N	\N	2026-05-25 09:02:50.663924+00
1734	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:57.079243+00
1737	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:05:38.034425+00
1299	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:18:15.706448+00
1307	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	ad670b81-df3b-4fc0-898c-b64b3098a186	{"rows": 10, "table": "PRJ004_Transactions.xlsx - Sheet1", "grouping": "Transaction"}	\N	\N	2026-05-21 09:25:24.202219+00
1354	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:26:01.321014+00
1358	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:27:52.270897+00
1457	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:53:13.296705+00
1480	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:19:52.526111+00
1493	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:26:52.275856+00
1498	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:27:08.44497+00
1503	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:47:18.299261+00
1600	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:41:07.122782+00
1604	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:49:34.684928+00
1625	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:01:51.922563+00
1630	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:03:34.259331+00
1632	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:04:24.444937+00
1647	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:13:10.316895+00
1678	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:42:12.206146+00
1711	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:57:48.69374+00
1717	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:58:54.613438+00
1727	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:14.128387+00
1730	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:57.065495+00
1736	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:05:38.038371+00
1763	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:18:20.742984+00
1765	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:19:29.285356+00
1769	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:19:29.310279+00
1771	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:20:07.668598+00
1791	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:43:50.038983+00
1796	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:46:06.835304+00
1801	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:47:17.354461+00
1807	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:52:45.671281+00
1815	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:28.944939+00
1818	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 01:45:04.862003+00
1300	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:18:15.712178+00
1305	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	ad670b81-df3b-4fc0-898c-b64b3098a186	{"rows": 10, "table": "PRJ004_Customer_Master.xlsx - Sheet1", "grouping": "Master Customer"}	\N	\N	2026-05-21 09:24:58.897002+00
1306	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	ad670b81-df3b-4fc0-898c-b64b3098a186	{"rows": 10, "table": "PRJ004_Digital_Behavior.xlsx - Sheet1", "grouping": "Digital Behaviour"}	\N	\N	2026-05-21 09:25:15.336323+00
1359	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:27:52.315471+00
1459	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:53:13.292013+00
1485	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:23:16.868186+00
1497	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:27:08.433071+00
1603	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 06:49:34.678997+00
1628	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:03:26.087457+00
1629	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:03:34.262282+00
1635	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:04:35.551027+00
1639	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:12:55.594712+00
1645	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:13:10.289832+00
1662	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:32:31.470308+00
1669	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:40:50.126375+00
1677	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:42:12.201184+00
1683	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:45:46.052448+00
1684	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:49:05.018494+00
1712	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:57:48.696097+00
1715	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:58:54.598469+00
1728	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:14.131716+00
1732	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:57.067877+00
1735	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:05:37.985709+00
1764	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:18:20.742279+00
1766	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:19:29.288362+00
1792	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:43:50.039741+00
1800	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:47:17.347093+00
1808	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:52:45.673741+00
1809	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:15.462106+00
1816	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:28.944541+00
1820	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 01:59:09.666775+00
1304	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	bulk_grouping	metadata	ad670b81-df3b-4fc0-898c-b64b3098a186	{"rows": 10, "table": "PRJ004_AI_Scoring.xlsx - Sheet1", "grouping": "Model Scoring"}	\N	\N	2026-05-21 09:24:46.903642+00
1360	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:46:03.211617+00
1374	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 03:15:37.778956+00
1376	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 04:07:27.532841+00
1389	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:32.23132+00
1460	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:53:13.299872+00
1641	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:12:55.597737+00
1644	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:13:10.288143+00
1713	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:57:48.69767+00
1714	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:58:54.597848+00
1723	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:01:15.812187+00
1725	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:14.10588+00
1767	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:19:29.282032+00
1793	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:43:50.04477+00
1797	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:46:06.846269+00
1802	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:47:17.353733+00
1806	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:51:55.880972+00
1810	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:15.483025+00
1812	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:23.016463+00
1814	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:25.22129+00
1821	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:05:16.22796+00
1822	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:05:52.208237+00
1824	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:06:24.573774+00
1826	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:06:43.752555+00
1827	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:07:54.844669+00
1829	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:09:14.036192+00
1834	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:11:39.187331+00
1841	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:17.489991+00
1843	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:18.235283+00
1847	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:17:26.913556+00
1849	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:20:25.275602+00
1855	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:24:36.542281+00
1858	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:29:16.360722+00
1308	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:27:54.434189+00
1361	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:46:03.211645+00
1368	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:56:34.09289+00
1382	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:10.920204+00
1385	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:32.115825+00
1409	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:10:36.022768+00
1421	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:42:01.304727+00
1448	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:19:56.226389+00
1458	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:53:13.297946+00
1664	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:38:31.766393+00
1667	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:38:31.857498+00
1670	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:40:50.124611+00
1682	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:45:46.049777+00
1716	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:58:54.601153+00
1721	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:01:15.794305+00
1733	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:57.071441+00
1739	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:05:38.06664+00
1773	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:20:07.67797+00
1794	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:43:50.058164+00
1795	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:46:06.823913+00
1799	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:46:06.856489+00
1803	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:47:17.355905+00
1805	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:51:55.877854+00
1811	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:23.011938+00
1813	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 10:02:25.219285+00
1823	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:06:07.393622+00
1825	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:06:36.255738+00
1832	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:09:14.781428+00
1833	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:09:22.820634+00
1835	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:11:39.194091+00
1836	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:11:43.927827+00
1837	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:14:56.469501+00
1844	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:19.566744+00
1309	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:27:54.455275+00
1362	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:46:03.211604+00
1366	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:56:34.086902+00
1387	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:32.117542+00
1413	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:15:16.002986+00
1415	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:33:23.823541+00
1420	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:42:01.322211+00
1442	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:13:49.699548+00
1445	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:19:56.207638+00
1461	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:06:51.019254+00
1668	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	metadata	batch_save	metadata	5288642d-13e8-45b3-8f77-bcbff82a42c5	{"saved": 23, "errors": 0}	\N	\N	2026-05-25 08:39:06.821957+00
1686	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:49:05.087744+00
1718	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:58:54.654176+00
1720	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:01:15.803873+00
1726	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:14.106331+00
1731	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:57.066126+00
1738	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:05:38.045738+00
1772	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:20:07.67549+00
1798	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:46:06.844602+00
1804	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:47:17.360344+00
1828	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:07:54.850086+00
1830	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:09:14.09765+00
1831	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:09:14.779114+00
1838	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:14:56.472617+00
1839	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:03.765711+00
1840	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:17.483105+00
1842	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:18.225736+00
1845	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:15:19.571487+00
1851	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:20:26.993947+00
1853	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:23:18.183279+00
1856	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:24:36.544224+00
1857	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:29:16.360707+00
1310	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:27:54.522355+00
1363	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:46:03.212742+00
1365	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:56:34.075935+00
1370	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 03:15:37.651187+00
1378	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 04:07:27.539259+00
1393	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:02:20.946551+00
1396	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:19:11.805142+00
1402	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:29:12.003057+00
1414	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:15:16.009976+00
1444	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:13:49.69988+00
1446	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 08:19:56.209756+00
1462	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:06:51.075093+00
1671	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:40:50.125384+00
1674	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:42:12.195349+00
1719	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:01:15.794346+00
1724	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:02:14.10598+00
1774	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:20:07.713206+00
1846	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	login	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	127.0.0.1	curl/8.14.1	2026-05-26 02:16:02.068068+00
1860	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-26 02:40:29.607304+00
1311	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:43:32.598407+00
1312	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:05.146443+00
1313	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:05.176593+00
1320	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:46:28.7985+00
1323	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:48:09.517625+00
1328	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 09:53:42.555023+00
1333	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:50:21.735832+00
1335	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:50:21.979585+00
1337	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:50:22.695131+00
1340	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 01:52:29.696115+00
1343	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:08:14.593722+00
1347	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:10:45.573292+00
1364	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 02:46:03.213959+00
1371	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 03:15:37.633681+00
1377	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 04:07:27.543027+00
1380	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:10.92454+00
1386	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 05:44:32.117703+00
1394	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:02:20.948145+00
1395	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:19:11.806412+00
1400	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 06:29:11.791725+00
1405	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:10:35.923753+00
1411	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:15:16.003065+00
1419	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:33:24.866823+00
1433	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 07:48:30.914963+00
1463	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-22 09:06:51.071559+00
1689	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:50:20.33944+00
1695	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:52:26.426606+00
1703	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:53:26.838983+00
1704	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 08:55:40.190641+00
1740	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:06:23.199694+00
1753	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:09:27.49508+00
1759	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-25 09:10:18.217085+00
1255	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:20:59.691049+00
1259	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:21:02.34527+00
1260	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:22:23.050704+00
1263	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:28:36.388776+00
1267	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:30:31.99871+00
1269	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:34:36.443117+00
1272	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:39:41.352958+00
1276	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	auth	token_refresh	user	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	\N	172.19.0.8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36	2026-05-21 08:42:50.883931+00
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
ec4b6e73-ab39-4513-8e91-432afaee3ad2	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	lead_business_steward	Ethan Walker	ethan.walker92@example.com	2026-05-19 11:32:02.713296+00
b2080696-803e-4e43-93e7-6f88e3a4cb87	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	data_owner	Sophia Bennett	sophia.bennett17@example.com	2026-05-19 11:32:02.900517+00
44e3fffb-26e0-4011-b340-c1868051212a	5288642d-13e8-45b3-8f77-bcbff82a42c5	lead_business_steward	Daniel Carter	daniel.carter84@example.com	2026-05-19 11:33:10.562223+00
e3006601-f6ba-430d-a929-cb201e3140b6	5288642d-13e8-45b3-8f77-bcbff82a42c5	data_owner	Olivia Hayes	olivia.hayes31@example.com	2026-05-19 11:33:10.666727+00
941c54fc-c2dd-4095-bffd-41585bf41c1f	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	lead_business_steward	Michael Turner	michael.turner56@example.com	2026-05-19 11:45:38.055045+00
5fa1f196-190b-4c8d-bbe7-0a975ecbba44	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	data_owner	Chloe Mitchell	chloe.mitchell88@example.com	2026-05-19 11:45:38.096383+00
0103817a-b73f-4e1a-b76f-97a1ea7e9d43	85eaf07b-2298-4658-baaa-a5e267c74812	lead_business_steward	Ryan Foster	ryan.foster23@example.com	2026-05-19 11:46:11.958668+00
7b55f63b-efd5-4594-9c65-baf82d713c71	85eaf07b-2298-4658-baaa-a5e267c74812	data_owner	Amelia Brooks	amelia.brooks74@example.com	2026-05-19 11:46:11.990144+00
b74e4a3d-34ef-4e56-8c50-4110c4b2b05e	ad670b81-df3b-4fc0-898c-b64b3098a186	lead_business_steward	Andika Pratama Wijaya	andika.wijaya@astra-group.co.id	2026-05-20 07:44:50.410937+00
06992bda-d9a5-41d7-af03-cec2a71d4a23	ad670b81-df3b-4fc0-898c-b64b3098a186	data_owner	Rina Maharani Putri	rina.putri@astra-group.co.id	2026-05-20 07:44:50.439154+00
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
4a6f596c-dcef-437c-bfa1-c777e0db5e6c	DSR-2026-0001	5288642d-13e8-45b3-8f77-bcbff82a42c5	9af488f8-db30-4b90-a672-c1ec50f45c85	Customer Transaction Dataset Q1-2026	PT Maju Bersama Digital	To train and validate AI-powered analytics models using customer transaction data for personalised financial insight generation, customer behaviour segmentation, and predictive modelling in support of the AI-Powered Customer Analytics Platform initiative.	t	2026-02-01	2026-12-31	\N	approved	2026-01-10 09:00:00+00	2026-01-25 11:45:00+00
5f8cf746-6035-447a-9cfa-3694bd423aaa	DSR-2026-0002	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	Customer Credit Data	PT Finansial Nusantara	To develop and train a credit risk scoring model leveraging customer transaction history, financial behaviour patterns, and credit bureau data, aimed at improving loan approval accuracy and reducing default rates for PT Finansial Nusantara's retail banking portfolio under the Smart Credit Risk Analytics Platform initiative.	t	2026-03-01	2026-12-31	\N	under_review	2026-05-07 03:02:08.540473+00	2026-05-07 03:02:08.540473+00
062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	DSR-2026-0003	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	DMS After Sales & Service Integration Dataset	Astra UD Trucks	Data sharing is required to support enterprise reporting, operational monitoring, and centralized analytics initiatives across after sales and service operations. The dataset will be used for integration into the corporate analytics platform to improve service performance visibility, billing reconciliation, inventory monitoring, and customer service reporting consistency across dealer networks.	t	2026-03-03	2026-10-28	\N	submitted	2026-05-19 03:18:36.664868+00	2026-05-19 03:22:02.684664+00
724230d4-37c0-4791-a898-2cdda92c1f8a	DSR-2026-0004	ad670b81-df3b-4fc0-898c-b64b3098a186	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	Customer 360 Integrated Analytics Dataset	Astra International – Digital Transformation Division	Data sharing is required to support the development of a Customer 360 analytics platform that integrates customer data from multiple sources, including sales transactions, after-sales services, and digital interaction channels. The dataset will be used to enable AI/ML-driven use cases such as customer segmentation, behavior prediction, and personalized recommendations to enhance customer engagement and business decision-making. All data processing will be conducted within a secure environment with appropriate safeguards, including pseudonymization, access control, and compliance with applicable data protection regulations.	t	2026-02-15	2026-11-30	\N	draft	2026-05-20 07:45:26.039319+00	2026-05-20 07:45:26.039319+00
\.


--
-- Data for Name: dpia_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dpia_approvals (id, dpia_id, approver_id, approver_role, step_order, status, comments, actioned_at) FROM stdin;
973587a9-afce-4a07-8f4c-4166ef1fe7e2	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	pending	\N	\N
df534081-26b6-410f-8e94-0abd96e60841	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	pending	\N	\N
9850336c-7db8-402e-8694-fc2ec42c3d04	82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	pending	\N	\N
7571909a-35ea-4733-a9c0-199e0cc7e794	c19f5d23-f981-46a8-9bb4-c4e9e75056e9	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	requested	\N	\N
541a33b9-3cfe-494c-b093-81eace455b95	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
722bd2f1-9158-44c5-a14d-a8b08130874b	01585cf6-32d7-47c8-aaa0-64f46c60d6b2	336b5420-9af0-49de-b844-e42ee6658cd4	pic_compliance	1	requested	\N	\N
b1ed1564-6744-4705-84e4-8fb1569e8088	2fba113d-74ec-49ea-a141-76478375037c	f961edea-0a7a-4f6c-8738-098f640b6dc8	pic_compliance	1	pending	\N	\N
c232429e-46db-45d4-9904-5478610e0736	2fba113d-74ec-49ea-a141-76478375037c	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
\.


--
-- Data for Name: dpia_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dpia_records (id, project_id, process_name, purpose, data_category, risk_description, mitigation_measures, residual_risk, likelihood_score, impact_score, risk_score, assessment_date, responsible_party_id, status, version, created_by, created_at, updated_at, tracking_id, governance_json) FROM stdin;
c19f5d23-f981-46a8-9bb4-c4e9e75056e9	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	Smart Credit Risk Analytics Platform		Full Name, Passport Number, Date of Birth, Gender, Email Address, Phone Number, Postal Code, Home / Residential Address, Employee ID, Job Title & Position, IP Address & Device ID	Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm.	Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable.	Low	\N	\N	\N	2026-05-15	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	submitted	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-15 05:32:44.458131+00	2026-05-15 08:12:06.055609+00	DPIA-2026-0002	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "no", "remarks": "Doesnt need data sharing request", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "yes", "remarks": "need to delete all the document related to project deliverable from the ADI environment", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "yes", "remarks": "Activity logs maintained in centralised audit trail system throughout the project lifecycle.", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "yes", "remarks": "RBAC policy document prepared and approved by DGO. Access limited to 4 authorised team members.", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "yes", "remarks": "PT Finansial Nusantara data governance team reviewed and approved all access documentation on 15 Mar 2026.", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "yes", "remarks": "Access credentials provisioned for approved team members only via secure VPN tunnel.", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "yes", "remarks": "Customer PII fields pseudonymised using SHA-256 hashing prior to transfer. Data encrypted at rest using AES-256.", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "yes", "remarks": "Metadata catalogue created covering 11 data attributes across identity, contact, employment, and digital behaviour categories.", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "yes", "remarks": "DQI measured at 94.2% completeness and 98.7% accuracy across the training dataset. Results reviewed by DQ Officer.", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "yes", "remarks": "PT Finansial Nusantara data team reviewed and approved all metadata definitions on 20 Mar 2026.", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "yes", "remarks": "DQ measurement methodology and index approved by PT Finansial Nusantara on 22 Mar 2026.", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "yes", "remarks": "Dedicated Supabase schema provisioned with row-level security enabled. Access restricted to whitelisted IP ranges only.", "responsible": "Client"}]}
82b993f4-ac05-4bf6-8519-2b2e5ee1eb5c	5288642d-13e8-45b3-8f77-bcbff82a42c5	AI-Powered Customer Analytics Platform		Full Name, Date of Birth, Gender, Email Address, Phone Number, Home / Residential Address, Postal Code, Employee ID, Job Title & Position, IP Address & Device ID	Unauthorised access to customer personal data during AI model training may result in identity theft or financial harm.	Data is pseudonymised before transfer. Access is limited to authorised team members via RBAC. All activity is logged and auditable.	Low	\N	\N	\N	2026-05-15	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	draft	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-15 03:59:20.637026+00	2026-05-15 06:58:23.421022+00	DPIA-2026-0001	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "", "remarks": "", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "", "remarks": "", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "", "remarks": "", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "", "remarks": "", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "", "remarks": "", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "", "remarks": "", "responsible": "Client"}]}
01585cf6-32d7-47c8-aaa0-64f46c60d6b2	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	Enterprise Data Integration Platform Implementation		Full Name, Email Address, Phone Number	Unauthorized access to customer personal data during AI processing or analytics may lead to data leakage, identity theft, or financial impact.	Data is pseudonymized before processing. Access is restricted through RBAC. All activities are logged and monitored. AI usage is limited to internal analytics within secured environments compliant with data protection regulations.	Low	\N	\N	\N	2026-05-19	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	submitted	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-19 03:18:36.664868+00	2026-05-19 03:30:46.679624+00	DPIA-2026-0003	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "yes", "remarks": "Data sharing request has been formally documented, including purpose, scope, and data classification", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "yes", "remarks": "Data retention and deletion policy defined; data will be deleted after project end date", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "yes", "remarks": "Data retention and deletion policy defined; data will be deleted after project end date", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "yes", "remarks": "All data processing activities are logged and auditable within secure environments", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "yes", "remarks": "RBAC model is implemented and documented; access restricted to authorized personnel only", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "yes", "remarks": "All documentation has been reviewed and approved by data governance and compliance team", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "yes", "remarks": "Personal data is pseudonymized and masked before usage in AI and analytics processes", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "yes", "remarks": "Metadata documentation has been created for dataset structure, fields, and data lineage", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "yes", "remarks": "Data quality metrics (completeness, consistency, accuracy) are defined and monitored", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "yes", "remarks": "Metadata reviewed and approved by data governance team", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "yes", "remarks": "Data quality framework validated and aligned with enterprise standards", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "yes", "remarks": "Data sharing is conducted within secure enterprise environment with encryption, access control, and monitoring", "responsible": "Client"}]}
2fba113d-74ec-49ea-a141-76478375037c	ad670b81-df3b-4fc0-898c-b64b3098a186	Customer 360 Analytics and Personalization Platform				\N	\N	\N	\N	\N	2026-05-20	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	draft	1	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-20 07:45:26.039319+00	2026-05-20 07:45:26.039319+00	DPIA-2026-0004	{"access": [{"id": "access_1", "item": "Data Sharing Request Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_2", "item": "Revoke / Extermination Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_3", "item": "Data Activity Records Documentation (during project)", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_4", "item": "Role-Based Access Control Document", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "access_5", "item": "Assess and Approve Documentation Above", "status": "", "remarks": "", "responsible": "Client"}, {"id": "access_6", "item": "Grant Access to Project Team Only (per RBAC document)", "status": "", "remarks": "", "responsible": "Client"}], "secure_data": [{"id": "secure_data_1", "item": "Prepare Mitigated Personal Data (e.g. encrypted, hashed, pseudonymised)", "status": "", "remarks": "", "responsible": "Client"}], "data_definition": [{"id": "data_def_1", "item": "Create Metadata Documentation", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_2", "item": "Measure Data Quality Index", "status": "", "remarks": "", "responsible": "Internal"}, {"id": "data_def_3", "item": "Assess and Approve Metadata Definition", "status": "", "remarks": "", "responsible": "Client"}, {"id": "data_def_4", "item": "Assess and Approve Data Quality Measurement Approach and Index", "status": "", "remarks": "", "responsible": "Client"}], "secure_sharing_environment": [{"id": "secure_env_1", "item": "Provide Secure Environment or Schema to Enable Data Sharing", "status": "", "remarks": "", "responsible": "Client"}]}
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
e3b2747b-0836-42b9-b6b7-1a4240202ec0	5f8cf746-6035-447a-9cfa-3694bd423aaa	c8cf883c-330c-46c0-b023-3629c2f99a69	client	4	pending	\N	\N
9476693c-346f-4d82-884b-9609a8fef043	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	approved	Reviewed and approved. Governance policies compliant.	2026-01-15 10:30:00+00
aa549bf0-c42d-4823-8bed-696468a7d3cb	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	approved	Reviewed and approved. Data usage aligns with project scope.	2026-01-18 14:15:00+00
d5d43037-fe5f-4530-ab2c-fc6aa4b1d180	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	approved	Approved. Data is relevant and fit for AI model training.	2026-01-22 09:00:00+00
2b803572-2f69-44bd-9740-a4ad3952070d	4a6f596c-dcef-437c-bfa1-c777e0db5e6c	c8cf883c-330c-46c0-b023-3629c2f99a69	client	4	approved	Approved. Compliance requirements satisfied.	2026-01-25 11:45:00+00
b0f7637c-d2aa-4643-ae44-5b39d52749bb	5f8cf746-6035-447a-9cfa-3694bd423aaa	1b6e6cdf-4700-4914-81cf-29f7e768c523	pic_compliance	1	approved	\N	2026-05-13 07:17:30.076257+00
28340666-50d1-4eb2-9565-f838e2d4523e	5f8cf746-6035-447a-9cfa-3694bd423aaa	13c686f6-db44-4585-b9f1-6c6200aac025	dm_pm	2	approved	\N	2026-05-13 07:17:30.076257+00
32320d50-06e9-4623-9863-443646e7031e	5f8cf746-6035-447a-9cfa-3694bd423aaa	4aa61e37-f659-44ae-810b-41d4ac793b26	sme	3	requested	\N	\N
aca8c71e-fb52-4d64-a53e-1180f64153f2	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
92413bd4-0d9c-4def-b62d-6a7b3e01f2ea	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
8dcf46b9-b3df-48b6-bee8-5656be212034	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	8216e50c-c627-469d-a696-1e91285f5aab	client	4	pending	\N	\N
ac34646e-f1f8-472d-8d0b-262f488853de	062b7358-ccfe-4b4e-bbc6-03c7f4a92c9f	336b5420-9af0-49de-b844-e42ee6658cd4	pic_compliance	1	requested	\N	\N
f2ecd93c-51ab-4a41-9165-99517f0c910e	724230d4-37c0-4791-a898-2cdda92c1f8a	f961edea-0a7a-4f6c-8738-098f640b6dc8	pic_compliance	1	pending	\N	\N
e70851cf-86ee-4b08-a435-2efb806644b2	724230d4-37c0-4791-a898-2cdda92c1f8a	89efb71c-c9f1-4224-8fa5-ae4b5e211402	dm_pm	2	pending	\N	\N
d7b991b4-37a8-4af6-bbed-3b55e3c4ad71	724230d4-37c0-4791-a898-2cdda92c1f8a	4a1a48b4-55b2-4ed4-84a8-ae84851e870d	sme	3	pending	\N	\N
0188d20d-fadc-4bac-8cc0-c46f4463f282	724230d4-37c0-4791-a898-2cdda92c1f8a	8216e50c-c627-469d-a696-1e91285f5aab	client	4	pending	\N	\N
\.


--
-- Data for Name: metadata_records; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.metadata_records (id, project_id, seq_no, business_users, data_domain_table, line_of_business, table_type, project_name, project_year, data_steward, data_owner, data_attribute, data_sensitivity, data_grouping, business_term, business_definition, definition_status, standard_format, is_primary_key, is_nullable, sample_data, data_type, data_level, updated_date, updated_by, remarks, source_type, created_at, source_row_count, data_year, distinct_values) FROM stdin;
504d2b2b-8edf-415c-bb0b-1af43d00ab54	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	1	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	ID	Confidential	\N	Identifier	Captures and records a unique, free-text identifier used to distinguish individual credit profiles within the financial services industry. This value is utilized in business decisions and reporting to track customer accounts, verify identity, and ensure accurate data matching across various systems.	ai_generated	Free text	t	t	PRJ002_0_0 | PRJ002_0_1 | PRJ002_0_2 | PRJ002_0_3 | PRJ002_0_4	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
13aa7e5f-fc07-4115-9145-f9b22459ae61	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	5	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Type	Confidential	\N	Loan Type	Captures information about the type of loan offered to customers in the Financial Services industry, which is crucial for understanding customer credit profiles and determining interest rates and repayment terms. It is used by financial analysts to create reports on loan performance and by risk managers to assess potential defaults. Category values indicate specific types of loans such as Auto loans are designed for purchasing vehicles, Mortgage loans are for buying or refinancing a home, Personal loans are for personal expenses.	ai_generated	Category: Auto, Mortgage, Personal	f	t	Personal | Mortgage | Auto	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Auto, Mortgage, Personal
dfd7208a-7a78-4a31-b386-f5fbb15941a0	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	7	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Status	Confidential	\N	Loan Status	Captures and records a critical status indicator in the financial services domain that signifies the current condition of an account's creditworthiness, which is used to inform loan approval decisions and reporting on credit risk. It indicates whether a loan application has been approved for funding, is still pending review or processing, or was rejected due to insufficient credit history or other factors. Approved loans are typically considered low-risk investments, while Rejected loans may require additional evaluation or alternative financing options. Pending status often requires further investigation or verification before making a final decision. This value may be absent when an account's credit profile is still being evaluated or updated, indicating that the current information is incomplete or not yet finalized. It also may be used to track changes in loan status over time, providing insights into trends and patterns in credit risk.	ai_generated	Category: Approved, Pending, Rejected	f	t	Rejected | Approved | Pending	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Approved, Pending, Rejected
5f4b94d8-cc8d-4c43-8e3a-de2b18a4424e	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	8	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Risk_Level	Confidential	\N	Risk Level	Captures and records a categorization of credit risk within the financial services industry, reflecting on the level of uncertainty associated with an individual's ability to repay debts. It is used in business decisions and reporting to determine eligibility for loans, credit lines, and other financial products, as well as to assess potential losses and risks. High indicates a high likelihood of default, Low signifies a low risk of non-payment, and Medium denotes a moderate level of uncertainty. These values are used to inform underwriting guidelines, loan approval processes, and portfolio management strategies. This value may be absent when an individual's credit profile is incomplete or when the assessment process has not been completed, but in practice, it provides a standardized way to communicate risk levels across different stakeholders and business functions.	ai_generated	Category: High, Low, Medium	f	t	Medium | Low | High	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	High, Low, Medium
c3baaa26-5ea6-46cb-bc6b-7943c96b5c5c	5288642d-13e8-45b3-8f77-bcbff82a42c5	2		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			inquiry_date	Confidential	Car Demand	Inquiry Date	Captures and records the date on which demand for a particular product or service is being inquired about within the Demand business area. It informs sales forecasting, inventory management, and pricing strategies by providing a specific point of reference for analyzing historical trends and seasonal fluctuations.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	f	2025-02-04T00:00:00 | 2026-01-04T00:00:00 | 2024-06-11T00:00:00 | 2024-06-25T00:00:00 | 2024-09-13T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
3686d812-df71-4923-8647-2d091ac98dce	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	4	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Income	Highly Confidential	\N	Income	Captures and records a unique identifier for an individual's financial transactions within the Financial Services domain, specifically tied to their credit profile. Used in business decisions and reporting to track customer income levels and assess eligibility for loans and other financial services, handled under our data privacy policy due to its personally identifiable nature.	ai_generated	Integer (whole number)	t	t	11226105 | 12613827 | 5435864 | 15952049 | 9421547	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
9d2a897b-ae8f-43e0-a884-cc465a68e4d0	85eaf07b-2298-4658-baaa-a5e267c74812	8	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Last_Updated	Confidential	\N	Last Updated	Captures and records the date and time a project was last updated, providing a critical timestamp for tracking changes within the banking industry domain. It is used to inform business decisions regarding project status, compliance with regulatory requirements, and reporting on project performance. This unique identifier ensures that each record can be distinguished from others, but this value may occasionally be absent if no updates have been made since its last recorded date.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01T00:00:00 | 2026-02-02T00:00:00 | 2026-02-03T00:00:00 | 2026-02-04T00:00:00 | 2026-02-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
3e13a250-37ae-4d80-87ca-38e42cdd3891	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	13	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Customer_ID	Confidential	\N	Customer Identifier	Captures and records a unique identifier for customers within the financial services domain, which is used to track individual customer accounts and transactions across various loan products. This value uniquely identifies each record in the system, allowing business stakeholders to make informed decisions about customer creditworthiness, account management, and risk assessment. However, this field may be absent if a customer has not yet been assigned an identifier or if the data is being used for internal reporting purposes.	ai_generated	ID / Code (e.g. CUST1000)	t	t	CUST1000 | CUST1002 | CUST1003 | CUST1004 | CUST1005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
651ddbc2-6e7f-4b82-859c-0d88945eec87	5288642d-13e8-45b3-8f77-bcbff82a42c5	19		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			follow_up_status	Confidential	Car Demand	Follow Up Status	Captures and records a specific follow-up status that indicates whether a car demand has been successfully resolved or is still pending in the sales process within the Demand domain, providing critical information for tracking progress and making informed decisions about future inventory management. Is used by business stakeholders to make timely adjustments to production schedules, allocate resources effectively, and evaluate the overall performance of their sales teams based on the status of each car demand.	ai_generated	Category: Contacted, Converted, Lost, Open	f	f	Lost | Open | Converted | Contacted	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	Contacted, Converted, Lost, Open
dbdb947e-ebc6-4209-ba20-eb8ba76293bd	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	15	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Income	Highly Confidential	\N	Income	Captures and records a unique identifier for an individual's financial transactions, specifically within the context of loan processing in the Financial Services domain. It is used to track and measure income earned by customers through various channels, including phone calls, influencing business decisions on account management and customer engagement. This value uniquely identifies each record, but may be absent when a transaction is not completed or recorded due to technical issues or data entry errors handled under our company's personal identifiable information policy.	ai_generated	Integer (whole number)	t	t	5554829 | 14272664 | 18506906 | 19897491 | 6118946	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
c87d9a34-1d71-4f79-8a00-cfa5b83a129d	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	16	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Type	Confidential	\N	Loan Type	Captures and records information about the type of loan that is being processed within the financial services domain, specifically in relation to the characteristics of a borrower's credit facility. It plays a crucial role in determining the terms and conditions of the loan, including interest rates and repayment schedules. This value is used by business stakeholders to make informed decisions about loan approvals, risk assessments, and portfolio management, as well as for reporting purposes such as loan originations and delinquencies. The possible values indicate specific types of loans, with Auto representing a short-term or personal loan, Mortgage indicating a long-term residential loan, and Personal signifying a consumer credit facility. These values are used to categorize and analyze loan data in order to identify trends and patterns.	ai_generated	Category: Auto, Mortgage, Personal	f	t	Auto | Personal | Mortgage	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Auto, Mortgage, Personal
bc3490b2-c7a6-4107-8f47-3f91e5975c03	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	19	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Risk_Level	Confidential	\N	Risk Level	Captures and records information about an individual's creditworthiness in relation to loan transactions, which is critical for financial services organizations to assess risk and make informed decisions. It informs business decisions regarding loan approvals, interest rates, and repayment terms, as well as provides insights into customer behavior and financial stability. The value indicates a high level of risk when the category is High, meaning the individual has a history of late payments or defaults on loans, a moderate level of risk when the category is Medium, suggesting some credit concerns but also potential for growth, and a low level of risk when the category is Low, signifying a strong credit profile with a stable payment history. This value may be absent in cases where no loan transactions have been recorded for an individual or entity, which could indicate a lack of financial.	ai_generated	Category: High, Low, Medium	f	t	High | Medium | Low	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	High, Low, Medium
946b4cf0-112d-472f-b923-eb67f768790c	85eaf07b-2298-4658-baaa-a5e267c74812	15	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Classification	Confidential	\N	Classification	Captures and records confidential information related to project classification within the banking domain, which is essential for maintaining sensitive customer data confidentiality. It plays a crucial role in business decisions by providing clear categorization of projects as internal, public, or confidential, allowing stakeholders to make informed choices about access and sharing. Each value represents a specific level of sensitivity, with Confidential indicating that information should not be shared outside the organization, Internal suggesting restricted access within the company, and Public signifying that data can be freely disseminated.	ai_generated	Category: Confidential, Internal, Public	f	t	Internal | Confidential | Public	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Confidential, Internal, Public
f7c0cf6d-c0d3-44c4-92c5-9c20aea1d08b	5288642d-13e8-45b3-8f77-bcbff82a42c5	35		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			color	Confidential	Sales	Color	Captures information about the color of vehicles sold within the sales domain and reflects a critical aspect of product offerings in the automotive industry. It is used to track color preferences among customers, influencing marketing strategies and inventory management decisions to meet demand for specific hues.	ai_generated	Category: Black, Blue, Gray, Red, Silver, White	f	f	Blue | White | Red | Gray | Black	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	Black, Blue, Gray, Red, Silver, White
ea6403b4-115a-42a1-b623-796c308ad3be	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	20	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Application_Date	Confidential	\N	Application Date	Captures and records the date on which a loan application is submitted, providing critical information for financial services organizations to track loan processing timelines within their domain. This datetime value plays a crucial role in business decisions by enabling the tracking of loan application status, facilitating reporting on loan processing efficiency, and ensuring compliance with regulatory requirements.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01T00:00:00 | 2026-01-02T00:00:00 | 2026-01-03T00:00:00 | 2026-01-04T00:00:00 | 2026-01-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
f7190501-11a9-4d24-a5e5-70f2a0d4a8d6	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	23	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	ID	Confidential	\N	Identifier	Captures and records a unique identifier for each risk scoring entry within the financial services domain, specifically in relation to project identification numbers. This value is used to track individual projects across various business decisions and reporting, uniquely identifying each record while also being sensitive due to its confidential nature. It may be absent when no specific project information is available or required.	ai_generated	Free text	t	t	PRJ002_2_0 | PRJ002_2_1 | PRJ002_2_2 | PRJ002_2_3 | PRJ002_2_4	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
98c9e809-e261-4afb-8cee-392e4d7144b8	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	27	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Type	Confidential	\N	Loan Type	Captures information about the type of loan offered to customers in the financial services industry, specifically distinguishing between auto loans, mortgage loans, and personal loans. This data is used by business analysts and risk managers to inform credit decisions and assess potential risks associated with each loan type. The values recorded for this field indicate that an Auto loan represents a car financing arrangement, a Mortgage loan signifies a home purchase or refinance transaction, and a Personal loan denotes a consumer credit agreement outside of the auto or mortgage categories. These values are used in business reporting to track loan performance by type, identify trends in customer behavior, and measure the effectiveness of risk mitigation strategies.	ai_generated	Category: Auto, Mortgage, Personal	f	t	Auto | Personal | Mortgage	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Auto, Mortgage, Personal
7716774e-8836-47b2-8ff8-ea1ac2cd5029	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	7		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Model_Confidence	Confidential	Service Prediction	Model Confidence	Captures a measure of how certain predictions are made with high accuracy within the service prediction domain. It indicates that when the model's confidence level is 0.84, it suggests that the predicted outcome has an 84% chance of being correct in real-world scenarios.	ai_generated	Decimal number	f	f	0.84 | 0.87 | 0.91 | 0.86 | 0.81	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
2284de94-a467-44ce-8341-fc5101a2052b	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	26	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Income	Highly Confidential	\N	Income	Captures a unique identifier for an individual's contact information within the Financial Services domain, specifically related to their phone number. This value is used in business decisions and reporting to assess risk exposure and make informed financial decisions about customers or clients.	ai_generated	Integer (whole number)	t	t	13608689 | 10454808 | 3039622 | 19690853 | 5928577	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
c6a8361f-ab0e-4592-88fc-4f6ae026e7ce	5288642d-13e8-45b3-8f77-bcbff82a42c5	10		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			fuel_preference	Confidential	Car Demand	Fuel Preference	Captures information about an individual's preferred fuel type for their vehicle within the demand area of the automotive industry. Is used to inform product development and marketing strategies, as well as track customer preferences in sales reports and loyalty programs.	ai_generated	Category: Diesel, Electric, Gasoline, Hybrid	f	f	Electric | Diesel | Gasoline | Hybrid	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	Diesel, Electric, Gasoline, Hybrid
114a700d-4755-42c3-bbc9-031ea5fb5937	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	28	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Amount	Confidential	\N	Loan Amount	Captures and records a specific financial amount associated with an individual loan, which is used to determine eligibility for credit and assess risk in the Financial Services industry. This value is utilized by business stakeholders to make informed decisions regarding loan approvals, interest rates, and repayment terms, while also being used to track and analyze historical data on loan amounts.	ai_generated	Integer (whole number)	t	t	62328040 | 147767679 | 142719967 | 16766034 | 84610024	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
5400260e-4b53-4787-a986-211590dfe439	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	23		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Quantity	Confidential	\N	Quantity	Captures and records the quantity of items sold or manufactured within a specific business area, such as retail or manufacturing, to support accurate inventory management and billing processes. It is used in business decisions and reporting to determine product availability, track sales trends, and calculate revenue, providing valuable insights into operational performance.	ai_generated	Integer (whole number)	f	f	3 | 2 | 9 | 8 | 7	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	1, 2, 3, 4, 5, 6, 7, 8, 9
cc3ef378-72af-46b3-92b3-b34336cb5c20	5288642d-13e8-45b3-8f77-bcbff82a42c5	7		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_model	Confidential	Car Demand	Preferred Model	Captures real-world demand patterns for specific vehicle models within the automotive industry's demand area and specifically within the domain of car sales, providing valuable insights into consumer preferences. This data is used by business stakeholders to inform product development decisions, pricing strategies, and marketing campaigns that cater to in-demand model variants such as the Xpander.	ai_generated	Category: 320i, CR-V, City, GLA, GLE, Ioniq, Outlander, X1, X3, Xpander, ...	f	f	Xpander | CR-V | Outlander | X3 | X1	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	320i, 520i, Air EV, Almaz, Alvez, Avanza, Baleno, Brio, C200, CR-V, City, Confero, Creta, E300, Ertiga, Fortuner, GLA, GLE, HR-V, Innova
4ae3ec21-147f-4ece-b1c1-7dcae386dd81	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	18	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Status	Confidential	\N	Loan Status	Captures and records real-world fact that a loan application is being reviewed for approval, rejection, or further processing within the financial services domain. It informs business decisions regarding loan approvals, rejections, and pending reviews to ensure compliance with regulatory requirements and internal policies. The approved status indicates that all necessary documentation has been verified and the applicant meets the required criteria, while rejected means the application is not eligible for funding due to insufficient creditworthiness or other reasons. Pending signifies that additional information or verification is needed before a final decision can be made. This value may be absent when an application has been approved or rejected in full.	ai_generated	Category: Approved, Pending, Rejected	f	t	Pending | Approved | Rejected	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Approved, Pending, Rejected
ebd53e42-f4a7-48ea-a9b0-25fea96afc8b	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	29	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Status	Confidential	\N	Loan Status	Captures and records real-world fact that a loan application has been evaluated for its risk level within the financial services domain, specifically in relation to its potential to default on repayment obligations. Is used by business stakeholders to make informed decisions about loan approvals, rejections, or continuance of processing, as well as to generate reports on loan status and performance metrics. The value indicates that a loan application has been rejected due to high risk, meaning the lender is unlikely to approve it for funding. An approved loan means the lender believes the borrower can repay the loan in full. A pending loan indicates that additional information or evaluation is required before making a final decision. The values of this data are as follows: Rejected means the lender has determined that the borrower's creditworthiness and financial situation do not meet their.	ai_generated	Category: Approved, Pending, Rejected	f	t	Rejected | Approved | Pending	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Approved, Pending, Rejected
360993d6-b44a-4256-bb2c-7e3aef412014	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	6	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Amount	Confidential	\N	Loan Amount	Captures and records a unique identifier for loan amounts within the Financial Services domain, specifically in relation to credit profiles. It is used by financial analysts to make informed decisions about lending and risk assessment, also serving as a key component in generating reports on outstanding loans. This value uniquely identifies each record, while its absence may be noted when a customer has no outstanding loan balance or when a new loan is being processed.	ai_generated	Integer (whole number)	t	t	60491266 | 126889095 | 97749799 | 53015536 | 17327951	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
fe3d72cb-60ba-4302-b83c-be2b69900326	5288642d-13e8-45b3-8f77-bcbff82a42c5	25		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sales_id	Confidential	Sales	Sales Identifier	Captures a unique identifier for individual sales transactions within the Sales domain, which is used to track and measure specific sales events across various locations and time periods. It serves as a critical component in business decision-making by providing a distinct reference point for analyzing sales performance, identifying trends, and making informed decisions about future sales strategies.	ai_generated	ID / Code (e.g. SALE000001)	t	f	SALE000001 | SALE000002 | SALE000003 | SALE000004 | SALE000005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
7228c5ab-0c85-4da3-856d-531451389f54	5288642d-13e8-45b3-8f77-bcbff82a42c5	46		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sales_channel	Confidential	Sales	Sales Channel	Captures and records information about how sales are made, specifically identifying whether they were conducted through a physical store location or an online platform. It is used to inform business decisions regarding marketing strategies, customer targeting, and overall revenue generation by distinguishing between in-store and online channels of sale.	ai_generated	Category: Exhibition, Online, Showroom	f	f	Online | Exhibition | Showroom	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	Exhibition, Online, Showroom
4849d880-8bcf-4030-94f7-5d75229ccea2	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	30	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Risk_Level	Confidential	\N	Risk Level	Captures and records risk levels in financial services, which are used to inform investment decisions and assess potential losses. High indicates a high level of risk, Low indicates a low level of risk, Medium indicates a moderate level of risk. The values reflect the severity of potential outcomes, with High indicating significant potential loss, Low indicating minimal potential loss, and Medium indicating some potential loss. This value is used to categorize risks in financial services, providing a standardized way to communicate risk levels across different teams and stakeholders. It helps to prioritize risk mitigation efforts and allocate resources effectively.	ai_generated	Category: High, Low, Medium	f	t	Medium | Low | High	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	High, Low, Medium
bd2f4cf4-3078-4d16-8819-1d027ce441a3	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	31	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Application_Date	Confidential	\N	Application Date	Captures and records the date a project's risk assessment is completed, providing critical information within the Financial Services domain. It serves as the primary identifier for each record, informing business decisions on project timelines and milestones, while also being used to track changes in project status over time. This value may be absent if a project has not yet been assessed or scored, but its presence uniquely identifies each record and is essential for accurate reporting and analysis.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01T00:00:00 | 2026-01-02T00:00:00 | 2026-01-03T00:00:00 | 2026-01-04T00:00:00 | 2026-01-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
bee18883-0f2c-48af-b64c-c731bd7b9229	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	33	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Score	Confidential	\N	Score	Captures a measure of risk associated with financial transactions in the Financial Services domain. It is used to inform business decisions regarding creditworthiness and investment opportunities, influencing the allocation of resources across various projects. This score may be absent for certain transactions that are not subject to risk scoring, such as those involving low-risk clients or internal transfers.	ai_generated	Decimal number	f	t	0.62 | 0.67 | 0.01 | 0.68 | 0.5	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
24c609e5-5712-4195-a08e-ce340c7e4883	ad670b81-df3b-4fc0-898c-b64b3098a186	5	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Score	Confidential	Model Scoring	Score	Captures a decimal number score that reflects an individual's performance in relation to their assigned model, used to evaluate and prioritize retail and automotive ecosystem customers. This score is utilized by business stakeholders to make informed decisions regarding customer engagement, loyalty programs, and sales incentives.	ai_generated	Decimal number	f	t	0.24 | 0.09 | 0.03 | 0.44 | 0.06	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
42dcfa00-b24b-4830-88ae-037f84b6adbf	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	10		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_ID	Confidential	\N	Customer Identifier	Captures a unique and confidential identifier for customers within the service area, which is used to track individual customer interactions and ensure accurate reporting on customer satisfaction levels. It serves as a critical component in making informed business decisions regarding customer relationships and loyalty programs.	ai_generated	ID / Code (e.g. CUST1000)	t	f	CUST1000 | CUST1001 | CUST1002 | CUST1003 | CUST1004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
85caa6a4-8c00-4ec5-884d-f922f77987ee	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	32	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Notes	Confidential	\N	Notes	Captures and records real-world information about a project's risk profile within the financial services domain, specifically indicating whether it falls under good conditions, high risk, incomplete documentation, or verification status. This data is used in business decisions to assess potential risks and guide investment strategies. It also informs reporting on project performance and progress. The value indicates that a "good profile" signifies low-risk projects, while "high risk" signals cautionary measures are needed, "incomplete docs" suggests further investigation is required, and "verified" confirms the accuracy of information. The possible values have practical meanings: a good profile means the project has minimal risks, high risk indicates significant concerns that need attention, incomplete docs suggest additional data or clarification is necessary, and verified signifies reliable information.	ai_generated	Free text	f	t	Good profile | Incomplete docs | Verified | High risk	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Good profile, High risk, Incomplete docs, Verified
31982c40-f640-4c58-99b1-b5d9c801b3e2	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	11	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Score	Confidential	\N	Score	Captures a critical creditworthiness indicator in the Financial Services domain that reflects an organization's ability to repay debts, measured as a decimal number. It is used by financial analysts and risk managers to inform lending decisions and assess credit risk, influencing the approval or denial of loans. This value may be absent for customers with no established credit history or when data on their credit profile is incomplete or unavailable.	ai_generated	Decimal number	f	t	0.76 | 0.4 | 0.93 | 0.2 | 0.01	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
c6fb84b5-1127-4995-a359-93bbe47069c8	85eaf07b-2298-4658-baaa-a5e267c74812	11	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Approval_Status	Confidential	\N	Approval Status	Captures and records a critical status indicator in the banking domain that signifies whether a project has been approved, is pending review, or has been rejected for various business purposes. It informs decision-making processes regarding resource allocation, risk management, and compliance reporting. The approval status indicates when a project is fully sanctioned (Approved), requires further evaluation before making a final decision (Pending), or has been deemed unacceptable (Rejected). This value may be absent in cases where the review process has not yet begun or was never initiated due to lack of necessary information or resources.	ai_generated	Category: Approved, Pending, Rejected	f	t	Approved | Rejected | Pending	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Approved, Pending, Rejected
26a9a7d7-d559-4863-8178-a7a44ffbf71c	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	3		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Usage_Pattern	Confidential	Service Prediction	Usage Pattern	Captures and records real-world usage patterns within the service prediction domain to inform business decisions regarding resource allocation and optimization strategies that reflect customer behavior and preferences. It is used in business decision-making processes to identify areas of high demand, optimize resource utilization, and measure the effectiveness of predictive models.	ai_generated	Category: High, Low, Medium	f	f	High | Medium | Low	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	High, Low, Medium
ffda456d-8d53-4b5b-97e3-e99bea1a132c	5288642d-13e8-45b3-8f77-bcbff82a42c5	29		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_id	Confidential	Sales	Customer Identifier	Captures a unique and confidential identifier for each customer involved in sales transactions within the automotive industry domain. Is used to track individual customers across multiple sales interactions, informing targeted marketing campaigns, loyalty programs, and personalized product recommendations.	ai_generated	ID / Code (e.g. CUST01188)	f	f	CUST01188 | CUST00912 | CUST00307 | CUST00197 | CUST00616	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
6321c22d-2f13-4add-872e-22ab534b94a0	5288642d-13e8-45b3-8f77-bcbff82a42c5	31		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			model	Confidential	Sales	Model	Captures information about a specific type of vehicle that is sold to customers within the sales domain and reflects its characteristics in relation to other vehicles. It informs business decisions by providing insight into customer preferences, market trends, and product offerings, helping organizations make informed choices about new models or discontinued lines.	ai_generated	Category: Almaz, Alvez, C200, CR-V, City, Ertiga, Fortuner, Jimny, Palisade, X3, ...	f	f	City | C200 | CR-V | X3 | Palisade	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	320i, 520i, Air EV, Almaz, Alvez, Avanza, Baleno, Brio, C200, CR-V, City, Confero, Creta, E300, Ertiga, Fortuner, GLA, GLE, HR-V, Innova
04447fd3-501d-4990-b7d7-b0d8b5a79e4c	5288642d-13e8-45b3-8f77-bcbff82a42c5	70		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_id	Confidential	Customer	Customer Identifier	Captures a unique and confidential identifier for every customer in the domain, ensuring that each record is distinguishable from others within the business area. Is used to track individual customers across various transactions, reports, and analyses, providing a consistent reference point for making informed decisions about customer relationships and loyalty programs.	ai_generated	ID / Code (e.g. CUST00001)	t	f	CUST00001 | CUST00002 | CUST00003 | CUST00004 | CUST00005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
2d44552d-babd-453f-9dbc-e5232b6cb72c	5288642d-13e8-45b3-8f77-bcbff82a42c5	79		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			tax_id	Highly Confidential	Customer	Tax Identifier	Captures and records a unique identifier for individual customers in Brazil, specifically within the customer domain, which is used to track and identify each customer's tax information, reflecting their personal details and ensuring confidentiality due to its highly sensitive nature. It serves as a primary key to uniquely identify each record and is not nullable, handling personally identifiable data under our organization's data privacy policy.	ai_generated	Phone number	t	f	40.011.270.4-788.502 | 60.271.985.7-806.532 | 69.143.075.8-318.823 | 10.273.477.5-567.277 | 36.871.579.9-076.844	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
f4eccce7-5b76-4b92-8394-d12c0eb4cda7	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	22	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Score	Confidential	\N	Score	Captures and records a financial score that indicates an organization's creditworthiness in relation to loan transactions, anchored within the Financial Services domain. It is used by business stakeholders to make informed decisions about lending and risk management, as well as to generate reports on credit performance. This value may be absent when a loan transaction has not been fully processed or evaluated, such as during the initial stages of application review.	ai_generated	Decimal number	f	t	0.99 | 0.94 | 0.38 | 0.48 | 0.67	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
05a42544-e96c-49b7-9e7e-aef24bb1b90e	85eaf07b-2298-4658-baaa-a5e267c74812	5	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	PII_Flag	Confidential	\N	Pii Flag	Captures and records a real-world fact that indicates whether sensitive personal information is present in customer accounts, anchored to the banking domain where it is used to inform decisions about data protection and security measures. It is used in business decisions and reporting to distinguish between customers who have opted-in or out of sharing their personally identifiable information with third parties. The value "Yes" typically means that the customer has given explicit consent for data sharing, while "No" indicates that they have not. This distinction is critical when complying with regulatory requirements. The possible values mean: Yes, the customer has explicitly agreed to share sensitive personal information with authorized third parties. No, the customer has opted-out of sharing their personally identifiable information.	ai_generated	Boolean (Yes / No)	f	t	Yes | No	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	No, Yes
afea0a01-afd9-4809-95ee-0af262b420a5	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	24	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Customer_ID	Confidential	\N	Customer Identifier	Captures and records a unique, free-text identifier for customers within the Financial Services domain, which is used to track individual customer relationships across various financial products and services. This value uniquely identifies each record in order to facilitate accurate reporting, decision-making, and compliance with regulatory requirements. This identifier may be absent when a new customer account is created or updated, as it requires manual input by business staff.	ai_generated	ID / Code (e.g. CUST1000)	t	t	CUST1000 | CUST1001 | CUST1003 | CUST1004 | CUST1005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
76fcbfc2-36cb-4322-b801-9033daee287c	85eaf07b-2298-4658-baaa-a5e267c74812	3	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Owner	Confidential	\N	Owner	Captures and records information about the owner of a project in the banking industry. It is used to track ownership responsibilities and ensure compliance with regulatory requirements, particularly in relation to business intelligence, IT operations, and internal processes, where BI indicates strategic decision-making, IT signifies technical expertise, and Ops denotes operational oversight. The value format ranges from Category: BI, indicating that this owner has a key role in driving business strategy. IT suggests involvement in technology implementation. And Ops implies responsibility for managing day-to-day operations. Each category provides distinct insights into the project's ownership structure. This data may be absent when there is no clear or designated owner of a project, which can occur in cases where multiple stakeholders are involved or when projects lack formal governance structures.	ai_generated	Category: BI, IT, Ops	f	t	BI | IT | Ops	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	BI, IT, Ops
a6080a2c-90fd-46f0-b07b-0c511ae537c6	85eaf07b-2298-4658-baaa-a5e267c74812	4	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Classification	Confidential	\N	Classification	Captures and records sensitive information related to project classification within the banking industry domain, which is crucial for maintaining confidentiality and adhering to regulatory requirements. It plays a vital role in business decisions by providing clear categorization of projects as confidential, internal, or public, allowing stakeholders to make informed choices about access and disclosure. The values recorded fall into three categories: Confidential indicates sensitive information that should not be shared with external parties, Internal signifies project data accessible only within the organization's walls, while Public denotes publicly available information. Each value carries distinct implications for handling and sharing project details. This classification may be absent when a project is deemed public or when specific organizational policies dictate otherwise, such as in cases where sensitive information needs to be shared with external partners or auditors.	ai_generated	Category: Confidential, Internal, Public	f	t	Internal | Confidential | Public	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Confidential, Internal, Public
e09f48c4-dcb3-4caa-88c0-5c6f16971b3a	85eaf07b-2298-4658-baaa-a5e267c74812	12	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Record_ID	Confidential	\N	Record Identifier	Captures a unique identifier for every project, which is used to track and manage projects across various departments within the banking industry. It serves as a crucial component in business decisions such as project allocation, resource assignment, and risk assessment, uniquely identifying each record while allowing flexibility in data entry. This value may be absent when a new project is initiated without an existing identifier or during data migration processes to maintain consistency throughout the system.	ai_generated	Free text	t	t	PRJ003_2_0 | PRJ003_2_2 | PRJ003_2_3 | PRJ003_2_4 | PRJ003_2_5	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
898e431c-a3ec-40fc-8f92-a886042ecfb5	85eaf07b-2298-4658-baaa-a5e267c74812	18	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Completeness	Confidential	\N	Completeness	Captures a measure of how accurately project-related financial information is recorded in accordance with established standards within the banking industry domain. It influences business decisions by indicating whether project costs and revenues are being tracked correctly, which can impact resource allocation and budgeting. This data value may be absent when there is no available project-related financial information or when the quality of that information cannot be assessed due to incomplete or inaccurate records.	ai_generated	Decimal number	f	t	0.68 | 0.84 | 0.95 | 0.78 | 0.8	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
0363f974-6583-47a6-a0fa-e316e1f42fff	ad670b81-df3b-4fc0-898c-b64b3098a186	13	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Email	Highly Confidential	Master Customer	Email	Captures and records a unique email address for every customer in the Retail & Automotive Ecosystem, which serves as their primary means of communication and is used to track interactions with customers across various touchpoints. It plays a crucial role in business decisions by enabling targeted marketing campaigns, personalized promotions, and efficient issue resolution. This sensitive data is handled under our company's data privacy policy and uniquely identifies each customer record, but may be absent for inactive or deleted records.	ai_generated	Email (name@domain.com)	t	t	cust0@mail.com | cust1@mail.com | cust2@mail.com | cust3@mail.com | cust6@mail.com	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
4b0db16f-10c8-4e4d-bcf5-d5927aee69d7	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	11		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_Name	Highly Confidential	\N	Customer Name	Captures and records highly confidential personal information about individual customers, specifically their full name as a unique identifier in our customer service operations. Used to make informed decisions regarding customer interactions, reporting, and account management, while being handled under our data privacy policy due to its personally identifiable nature.	ai_generated	Free text	t	f	Name_0 | Name_1 | Name_2 | Name_3 | Name_4	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
cb3787f7-2900-4cad-80fa-d75ae86f18a9	85eaf07b-2298-4658-baaa-a5e267c74812	10	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Notes	Confidential	\N	Issue Notes	Captures and records instances where a project has duplicate data, missing fields, is free from issues, or has been validated by relevant stakeholders in the banking industry domain. It informs business decisions related to risk management, compliance, and quality control by providing insights into the overall health of projects. Duplicate data indicates that there are multiple entries for the same item, which may require further investigation to ensure accuracy and consistency. No issue signifies that a project has been completed successfully without any major concerns or issues. Validated means that the data has been verified as accurate and reliable by relevant authorities or experts in the field. This value is absent when a project is still under review or evaluation, indicating that there may be incomplete information available yet.	ai_generated	Free text	f	t	Duplicate data | Missing fields | Validated | No issue	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Duplicate data, Missing fields, No issue, Validated
67fde6dc-e06a-49bc-93c7-18da4884376b	85eaf07b-2298-4658-baaa-a5e267c74812	9	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Flag	Confidential	\N	Issue Flag	Captures and records a real-world fact that indicates whether an issue has been resolved in the banking domain, specifically within project management. It is used to inform business decisions regarding resource allocation and risk assessment, as well as to track progress towards resolving outstanding issues. Yes means the issue has been fully addressed, while False signifies ongoing work or unresolved problems. The value of True/False indicates that an issue has been completely resolved (True) versus still requiring attention (False). This data is absent when no decision regarding project resolution has been made.	ai_generated	Boolean (Yes / No)	f	t	Yes | No	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	No, Yes
d60e1fdf-8537-4dfd-a75b-0a7c9688b65a	ad670b81-df3b-4fc0-898c-b64b3098a186	1	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Record_ID	Confidential	Model Scoring	Record Identifier	Captures a unique identifier for every scoring model, anchored to the retail and automotive ecosystem's domain of model scoring, which is used in business decisions such as tracking customer interactions with AI-powered models and reporting on the performance of individual models. It uniquely identifies each record and its absence may indicate that no specific model has been assigned or created.	ai_generated	ID / Code (e.g. AI4000)	t	t	AI4000 | AI4001 | AI4002 | AI4003 | AI4005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
5eb81097-f9e5-4cf8-9840-0f3b11da6170	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	12	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	ID	Confidential	\N	Identifier	Captures and records a unique, free-text identifier used to distinguish individual loan transactions within the financial services domain. This identifier is utilized in business decisions and reporting to track specific loan transactions, measure their status, and ensure accurate accounting for each record.	ai_generated	Free text	t	t	PRJ002_1_0 | PRJ002_1_1 | PRJ002_1_2 | PRJ002_1_3 | PRJ002_1_4	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
37ea8849-5e75-4598-b2b6-d467b888420d	85eaf07b-2298-4658-baaa-a5e267c74812	7	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Completeness	Confidential	\N	Completeness	Captures a measure of how well an account's financial information is accurate and up-to-date, reflecting the level of completeness in banking operations. It influences business decisions by indicating whether accounts are fully recorded, allowing for more informed risk management and compliance reporting. This value may be absent when an account has been closed or is no longer active, but its absence does not necessarily imply a lack of completeness.	ai_generated	Decimal number	f	t	0.86 | 0.59 | 0.76 | 0.55 | 0.58	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	0.51, 0.52, 0.54, 0.55, 0.58, 0.59, 0.6, 0.61, 0.63, 0.66, 0.67, 0.74, 0.76, 0.79, 0.82, 0.83, 0.84, 0.85, 0.86, 0.9
4c4445cf-0e87-4585-ae0e-6b22f63dd9fc	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	13		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Phone_Number	Highly Confidential	\N	Phone Number	Captures and records a unique identifier for customer contact information, which is used to ensure confidentiality in sensitive communications with customers across various business channels. It plays a crucial role in making informed decisions about customer interactions and reporting on service quality, while being handled under our data privacy policy due to its personally identifiable nature.	ai_generated	Phone number	t	f	08634895718 | 08299900595 | 08962061404 | 08887846414 | 08227521863	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
c0b8fca5-5729-4d6d-9d39-1eb5ce72fa7a	85eaf07b-2298-4658-baaa-a5e267c74812	14	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Owner	Confidential	\N	Owner	Captures information about who is responsible for a project in the banking industry. It helps identify key stakeholders and decision-makers, particularly those with ownership rights over specific business initiatives that impact various lines of business such as IT, BI, and operations. This data informs reporting and analysis to track progress, allocate resources, and measure success across different departments. Each category represents a distinct role or responsibility within the organization. The values recorded here indicate who is accountable for project outcomes, with "BI" signifying ownership by Business Intelligence teams, "IT" denoting IT department involvement, and "Ops" representing operational oversight. These categories are used to make informed decisions about resource allocation and strategic partnerships.	ai_generated	Category: BI, IT, Ops	f	t	BI | IT | Ops	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	BI, IT, Ops
190481c7-bab8-4fce-a85b-e1b930388b5f	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	8		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Analyst_Comments	Confidential	Service Prediction	Analyst Comments	Captures real-world feedback from service prediction processes within the domain of artificial intelligence analytics, providing valuable insights that reflect the quality and performance of these predictions. This recorded information is used by business stakeholders to inform decision-making and reporting on service reliability and customer satisfaction levels.	ai_generated	Category: Monitor closely, No action required, Normal usage, Potential issue detected	f	f	Monitor closely | Potential issue detected | No action required | Normal usage	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Monitor closely, No action required, Normal usage, Potential issue detected
68b545ae-3c03-4a69-8108-8486927f6d3b	85eaf07b-2298-4658-baaa-a5e267c74812	16	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	PII_Flag	Confidential	\N	Pii Flag	Captures and records a real-world fact that indicates whether sensitive customer information is being protected in accordance with banking regulations, anchored to the banking domain where confidentiality of customer data is paramount. It informs business decisions regarding risk management and compliance reporting by providing a clear indication of whether customer data has been compromised or not, which can have significant implications for reputational damage and regulatory penalties. The value "Yes" indicates that sensitive customer information has been flagged as being at high risk of exposure, while the value "No" means it is considered secure. In practice, this means that if a customer's data is marked as "Yes", it may require additional security measures to be put in place to mitigate the risk. This value may be absent when there is no sensitive customer information involved or when the level of sensitivity has.	ai_generated	Boolean (Yes / No)	f	t	Yes | No	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	No, Yes
b8feb8ff-0a44-4aa9-b7ca-49a9ca8c1d6d	85eaf07b-2298-4658-baaa-a5e267c74812	19	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Last_Updated	Confidential	\N	Last Updated	Captures and records the date and time a project's quality status was last updated, providing a critical timestamp within the banking domain to ensure data integrity and compliance with regulatory requirements. It is used in business decisions by tracking changes over time to identify trends, detect anomalies, and measure the effectiveness of quality control processes.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01T00:00:00 | 2026-02-02T00:00:00 | 2026-02-04T00:00:00 | 2026-02-06T00:00:00 | 2026-02-07T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
640d30a2-df39-4669-9488-8b6a5cec9b34	85eaf07b-2298-4658-baaa-a5e267c74812	17	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Quality_Score	Confidential	\N	Quality Score	Captures a measure of project quality that reflects the bank's overall performance in meeting customer expectations and delivering high-quality financial services within the banking domain. It is used to inform business decisions regarding resource allocation, risk management, and process improvements by providing a standardized way to evaluate project outcomes. This value may be absent when no data is available or if the project has not yet been completed, indicating that there is insufficient information to make an informed assessment of its quality.	ai_generated	Decimal number	f	t	0.64 | 0.96 | 0.61 | 0.82 | 0.92	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	0.61, 0.64, 0.65, 0.66, 0.67, 0.68, 0.69, 0.7, 0.72, 0.74, 0.75, 0.76, 0.78, 0.79, 0.8, 0.82, 0.84, 0.85, 0.87, 0.91
ae95fd6b-39ea-4db0-bbbe-183715a5a41a	85eaf07b-2298-4658-baaa-a5e267c74812	21	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Notes	Confidential	\N	Issue Notes	Captures and records instances where a project's quality is compromised due to duplicate data, missing fields, or no issue with its validity. It informs business decisions regarding resource allocation and risk management in the banking line of business by providing insight into potential problems that could impact customer satisfaction. The value indicates specific categories such as Duplicate data meaning that identical information has been recorded for a single project, Missing fields signifying gaps in required details, No issue showing that all necessary information is present and accurate, Validated denoting that the quality check confirms the data's correctness. This field may be absent when no issues are found with a project's data quality or if duplicate records have not occurred. Its absence does not imply any problem with the data itself but rather indicates that it meets the required standards.	ai_generated	Free text	f	t	Duplicate data | Missing fields | No issue | Validated	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Duplicate data, Missing fields, No issue, Validated
53bc5062-f31a-483a-b756-b9cd20ccaa23	5288642d-13e8-45b3-8f77-bcbff82a42c5	82		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			province	Confidential	Customer	Province	Captures real-world geographical information about a customer's location within the Customer domain. This piece of data is used to identify specific regions or areas where customers reside, which can inform targeted marketing efforts and regional product offerings.	ai_generated	Category: Kalimantan Timur	f	f	Kalimantan Timur	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	Kalimantan Timur
4b9d666a-eb04-4687-a511-d37c6d9e67d4	85eaf07b-2298-4658-baaa-a5e267c74812	22	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Approval_Status	Confidential	\N	Approval Status	Captures and records real-world facts about project status within the banking domain, specifically indicating whether a project has been approved, is pending further review, or has been rejected due to non-compliance with business requirements. It informs business decisions by providing critical information on project viability and progress, enabling stakeholders to make informed choices regarding resource allocation and risk management. The value of "Approved" signifies that the project meets all necessary criteria and can proceed as planned, while "Pending" indicates a need for further review or clarification before making a final decision, and "Rejected" signals that the project does not meet business requirements and should be terminated. Each value has significant implications for stakeholders, including project managers, investors, and regulatory bodies. This data may be absent when a project is in its initial stages and no status information.	ai_generated	Category: Approved, Pending, Rejected	f	t	Pending | Rejected | Approved	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Approved, Pending, Rejected
349dd538-81d0-483a-ab66-cf01ca8c6887	85eaf07b-2298-4658-baaa-a5e267c74812	23	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Record_ID	Confidential	\N	Record Identifier	Captures and records a unique, free-text identifier for every project in the banking domain, which is used to track and identify individual projects across various business functions and reporting periods. It uniquely identifies each record within the metadata catalog, allowing for accurate tracking and retrieval of specific project information, but may be absent when a new or deleted project lacks an established identifier.	ai_generated	Free text	t	t	PRJ003_1_0 | PRJ003_1_2 | PRJ003_1_3 | PRJ003_1_4 | PRJ003_1_5	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
b9f44d06-7848-4b92-839f-5c5d28b6c692	85eaf07b-2298-4658-baaa-a5e267c74812	28	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Quality_Score	Confidential	\N	Quality Score	Captures a measure of an entity's creditworthiness in the banking industry, reflecting its ability to meet financial obligations. It is used by business stakeholders to evaluate risk and make informed decisions about lending and investment opportunities, influencing reporting on loan performance and portfolio health. This value may be absent when an entity has no outstanding loans or credit lines, as this would indicate a lack of exposure to potential losses.	ai_generated	Decimal (2 decimal places)	f	t	0.89 | 0.77 | 0.81 | 0.78 | 0.94	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	0.61, 0.62, 0.63, 0.67, 0.68, 0.69, 0.75, 0.76, 0.77, 0.78, 0.81, 0.82, 0.83, 0.85, 0.87, 0.88, 0.89, 0.92, 0.94, 0.96
4521df6b-bc7f-4581-8764-e21811127a34	85eaf07b-2298-4658-baaa-a5e267c74812	25	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Owner	Confidential	\N	Owner	Captures information about who is responsible for a project in the banking industry domain. It informs business decisions and reporting by identifying the owner of a specific project, which can impact resource allocation, risk management, and compliance with regulatory requirements. The values recorded are categorized as either Business Intelligence (BI), Information Technology (IT), or Operations (Ops). BI indicates strategic planning, IT signifies technical implementation, and Ops denotes operational oversight. These categories help in making informed decisions about project prioritization, budgeting, and resource allocation. This value may be absent when a project is not owned by an individual but rather by the organization as a whole, such as in cases of joint ventures or partnerships.	ai_generated	Category: BI, IT, Ops	f	t	Ops | BI | IT	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	BI, IT, Ops
4113a833-fe0c-4945-81f2-48d7cf2fabc4	5288642d-13e8-45b3-8f77-bcbff82a42c5	3		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_name	Highly Confidential	Car Demand	Customer Name	Captures and records highly confidential personal information about individual customers, specifically their names, which are used to identify them uniquely across all demand-related transactions. This sensitive data is utilized in business decisions and reporting to personalize customer interactions, track sales performance, and analyze market trends.	ai_generated	Free text	t	f	Tgk. Kezia Hutasoit | Cahya Aryani | Wulan Permata | Justin Ortiz | Dt. Kunthara Waskita, S.Psi	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
4f13efdc-51dc-4b5d-931c-2002a4dfd263	85eaf07b-2298-4658-baaa-a5e267c74812	24	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Dataset_Name	Highly Confidential	\N	Dataset Name	Captures and records real-world facts about dataset names in the banking domain, specifically identifying categories such as customer, inventory, and sales. Used to inform business decisions and reporting related to product offerings and market analysis, where each category represents a distinct type of data. Values are Sales for specific products, Customer for personal accounts, Inventory for stock levels, indicating that these datasets hold critical information about financial transactions.	ai_generated	Free text	f	t	Sales | Inventory | Customer	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Customer, Inventory, Sales
9fb9c791-b8f6-4bf7-97dc-39701a9f6bc6	85eaf07b-2298-4658-baaa-a5e267c74812	26	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Classification	Confidential	\N	Classification	Captures and records sensitive information related to project classification within the banking domain, which is crucial for maintaining confidentiality and adhering to regulatory requirements. Is used in business decisions and reporting to categorize projects as confidential, internal, or public, allowing stakeholders to make informed choices about access and disclosure. Each possible value represents a distinct level of sensitivity: Confidential indicates sensitive information that requires utmost protection. Internal signifies project data accessible only within the organization. Public denotes publicly available project information.	ai_generated	Category: Confidential, Internal, Public	f	t	Internal | Public | Confidential	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Confidential, Internal, Public
60b1d343-f4b3-47ed-b93f-aa35635362e5	85eaf07b-2298-4658-baaa-a5e267c74812	30	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Last_Updated	Confidential	\N	Last Updated	Captures and records the date and time a project's metadata was last updated, providing a critical timestamp for tracking changes within the banking industry domain. It is used to inform business decisions regarding project status updates, compliance reporting, and regulatory requirements. This unique identifier ensures that each record can be distinguished from others, while its absence may indicate that no update has occurred since the data was initially recorded or retrieved from an external source.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01T00:00:00 | 2026-02-02T00:00:00 | 2026-02-03T00:00:00 | 2026-02-04T00:00:00 | 2026-02-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
0f03f992-bede-4818-b0d1-478227e065cc	ad670b81-df3b-4fc0-898c-b64b3098a186	11	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Customer_ID	Confidential	Master Customer	Customer Identifier	Captures and records a unique, free-text identifier for individual customers within the retail and automotive ecosystem domain, which is used to identify and distinguish one customer from another in all business transactions and interactions. This value uniquely identifies each record and plays a critical role in making informed business decisions, such as personalizing offers, tracking loyalty programs, and analyzing sales data. It may be absent for new customers who have not yet been assigned an identifier.	ai_generated	ID / Code (e.g. CUST1000)	t	t	CUST1000 | CUST1001 | CUST1002 | CUST1003 | CUST1004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
08374f28-323d-4a15-bfba-d52116915eae	ad670b81-df3b-4fc0-898c-b64b3098a186	22	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Customer_ID	Confidential	Digital Behaviour	Customer Identifier	Captures and records a unique identifier for individual customers in the retail and automotive ecosystem, specifically within the digital behavior domain. It is used to track customer interactions across various channels and inform business decisions related to loyalty programs, marketing campaigns, and sales analytics. This value may be absent when a new customer joins the system or if their identifier changes due to data migration or updates.	ai_generated	ID / Code (e.g. CUST1059)	f	t	CUST1059 | CUST1015 | CUST1042 | CUST1046 | CUST1017	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
2c50e2cd-5d31-4b63-8869-62c30c3c871e	85eaf07b-2298-4658-baaa-a5e267c74812	32	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Notes	Confidential	\N	Issue Notes	Captures and records instances where a project has duplicate data, missing fields, is free from issues, or has been validated by relevant stakeholders in the banking industry domain. It informs business decisions regarding risk assessment, compliance monitoring, and quality control processes. Duplicate data indicates that there are multiple entries for the same item, which may require further investigation to resolve discrepancies. No issue signifies that a project's metadata is accurate and complete, while Validated means that the information has been verified by authorized personnel. Missing fields could represent incomplete or outdated records, while Confidential sensitivity requires special handling due to sensitive nature of this data, and it may be absent when no such issues are present in the project metadata.	ai_generated	Free text	f	t	Duplicate data | Missing fields | No issue | Validated	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Duplicate data, Missing fields, No issue, Validated
f603f7bc-ffa9-4f26-a00c-2d41c33c9d9d	5288642d-13e8-45b3-8f77-bcbff82a42c5	58		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			transmission	Confidential	Stock	Transmission	Captures information about a vehicle's transmission type, which is an important aspect of its stock and falls under the domain of automotive inventory management. This data is used by business stakeholders to make informed decisions regarding new or existing vehicles, as well as to track sales trends and customer preferences.	ai_generated	Category: Automatic, Manual	f	f	Manual | Automatic	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Automatic, Manual
edc8f6ae-12c0-47e1-a661-063248dc3ad1	85eaf07b-2298-4658-baaa-a5e267c74812	33	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Approval_Status	Confidential	\N	Approval Status	Captures and records a critical status indicator in the banking domain that signifies whether a project has been approved, is pending review, or has been rejected for various business reasons. It informs business decisions regarding resource allocation, risk management, and regulatory compliance by providing insight into the current state of project viability. The value indicates that an approval was given to proceed with a project (Approved), but further investigation or review is needed before making a final decision (Pending). If an approval has been rejected due to unforeseen issues or non-compliance, it signifies that the project should not be pursued at this time. This sensitive information may be absent when a project is in the early stages of development and no formal approval process has yet begun. However, its absence does not necessarily imply that the project will move forward without scrutiny.	ai_generated	Category: Approved, Pending, Rejected	f	t	Rejected | Approved | Pending	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Approved, Pending, Rejected
7c031d39-445d-4296-8655-fa89c2d9d6f5	ad670b81-df3b-4fc0-898c-b64b3098a186	37	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Transaction_Date	Confidential	Transaction	Transaction Date	Captures and records a specific date and time within the retail and automotive ecosystem, which is used to track sales transactions and identify patterns in customer behavior. It uniquely identifies each transaction record and informs business decisions regarding inventory management, pricing strategies, and customer loyalty programs. This value may be absent for historical or archived data that has not been updated with the current timestamp.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2025-01-01T00:00:00 | 2025-01-02T00:00:00 | 2025-01-03T00:00:00 | 2025-01-04T00:00:00 | 2025-01-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
1acebd05-39b9-4a93-8097-454958de20dd	ad670b81-df3b-4fc0-898c-b64b3098a186	32	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Customer_ID	Confidential	Transaction	Customer Identifier	Captures and records a unique identifier for customers within the retail and automotive ecosystem, specifically in transactions related to their purchases and interactions with our business. It is used by sales teams to track customer loyalty programs, by marketing departments to personalize promotions and offers, and by management to analyze sales trends and identify areas of growth. This value may be absent when a new customer makes an initial purchase or interacts with our business for the first time, as their identifier has not yet been established.	ai_generated	ID / Code (e.g. CUST1023)	f	t	CUST1023 | CUST1041 | CUST1032 | CUST1012 | CUST1031	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
d4734a33-f968-4f37-9141-3a69fa8d52cd	85eaf07b-2298-4658-baaa-a5e267c74812	27	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	PII_Flag	Confidential	\N	Pii Flag	Captures information about whether a customer's personal identifiable information is protected by a specific flag, which is used in banking to ensure compliance with regulations and industry standards. It informs business decisions related to data sharing and access controls, as well as reporting on the effectiveness of these measures. The value "Yes" indicates that Pii Flag is set to protect sensitive customer data, while "No" means it is not protected, which can have significant implications for customer privacy and security. In practice, a "True" or "1" value would also be considered as indicating protection, whereas a "False" or "0" value would indicate no protection. This value may be absent when the data is being used to report on overall compliance levels, but it can provide important context for specific customer records that have been.	ai_generated	Boolean (Yes / No)	f	t	No | Yes	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	No, Yes
97a33c5c-1822-4919-80b5-14735dd5f403	5288642d-13e8-45b3-8f77-bcbff82a42c5	30		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			brand	Confidential	Sales	Brand	Captures information about a specific automobile manufacturer that is relevant to sales performance within the automotive industry domain. It provides valuable insights into customer loyalty and market trends, which are essential for making informed decisions on product development, marketing strategies, and resource allocation in the sales function.	ai_generated	Category: BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling	f	f	Honda | Mercedes-Benz | BMW | Hyundai | Wuling	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling
50e82314-30d9-465c-b24d-e907d382d3dd	ad670b81-df3b-4fc0-898c-b64b3098a186	6	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Model_Version	Confidential	Model Scoring	Model Version	Captures and records a specific version number associated with model scoring in the retail and automotive ecosystem, which is used to track changes made to models over time. It informs business decisions regarding model updates and ensures compliance with regulatory requirements by indicating the current version of the model being used. The value v1 typically represents an initial or baseline version of the model, while v2 signifies a revised or updated version. In practice, each possible value indicates that the corresponding model has undergone significant changes to its scoring logic or parameters. This data may be absent when no model is currently active or when the system is initializing, as it relies on the presence of an active model to accurately capture and record its version number.	ai_generated	Category: v1, v2	f	t	v1 | v2	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	v1, v2
dbbc52f0-079b-4852-84c6-d171fd69acb6	85eaf07b-2298-4658-baaa-a5e267c74812	31	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Flag	Confidential	\N	Issue Flag	Captures a critical indicator in project management that signifies whether an issue has been resolved, Records the status of an outstanding problem, Indicates the presence or absence of a significant concern within a banking operation. Is used by business stakeholders to make informed decisions about resource allocation and risk mitigation, Is reported on in regular progress updates and performance reviews to track project health and identify areas for improvement. Represents two possible states: "Yes" or "No", indicating whether an issue has been fully addressed or still requires attention, "True" or "False" signifying the existence or non-existence of a critical problem, with absence typically denoting that no such issue exists.	ai_generated	Boolean (Yes / No)	f	t	No | Yes	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	No, Yes
6a525841-6c56-4c81-bde8-406ee65f7dc6	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	3	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Age	Confidential	\N	Age	Captures information about an individual's age within the Financial Services domain, reflecting a real-world fact that is relevant to assessing creditworthiness and determining loan eligibility. It is used in business decisions and reporting to identify customers who are likely to repay loans on time. This value may be absent for individuals whose birthdate is not available or has been reported as unknown, which can occur due to incomplete or inaccurate customer data.	ai_generated	Integer (whole number)	f	t	58 | 33 | 29 | 32 | 26	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	21, 22, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 38, 39, 41, 43, 44, 45, 46
bf17210d-9027-4d64-8ac3-576c532c6691	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	14	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Age	Confidential	\N	Age	Captures and records the age of customers in a financial services context, which is used to determine eligibility for loans and credit products. It also helps track customer loyalty and retention rates over time, influencing business decisions on loan approvals and interest rate adjustments. This value may be absent if a customer has never applied for or been approved for a loan, but its absence does not necessarily imply an error in data entry.	ai_generated	Integer (whole number)	f	t	53 | 54 | 28 | 35 | 34	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	21, 22, 27, 28, 33, 34, 35, 36, 37, 39, 40, 42, 46, 47, 49, 51, 53, 54, 56, 57
4a673b13-094f-4131-8f0f-7cf950337af2	ad670b81-df3b-4fc0-898c-b64b3098a186	7	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Prediction_Date	Confidential	Model Scoring	Prediction Date	Captures and records a specific date and time when a prediction is made in the retail and automotive ecosystem, which falls within the model scoring domain. This value indicates the point at which a prediction was made and uniquely identifies each record, allowing for accurate tracking of predictions over time.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-02-01T00:00:00 | 2026-02-03T00:00:00 | 2026-02-04T00:00:00 | 2026-02-06T00:00:00 | 2026-02-07T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
b00b822d-aaaf-4619-a977-5c3c37edbc5a	ad670b81-df3b-4fc0-898c-b64b3098a186	9	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Comments	Confidential	Model Scoring	Comments	Captures and records real-world feedback from customers regarding their AI scoring results within the retail and automotive ecosystem, specifically in relation to model performance monitoring. It is used by business stakeholders to inform decisions on product development and customer service improvements, as well as for reporting purposes to track progress towards meeting quality standards. The value indicates that a review or validation of the AI scoring result has been completed, which means it needs further attention from the team. This value signifies that the model's performance is being closely monitored by the business stakeholders, who are responsible for ensuring its accuracy and reliability. This value may be absent when no feedback has been received from customers regarding their AI scoring results, or if a review of the result has not yet been completed.	ai_generated	Category: Monitor, Review Needed, Valid	f	t	Monitor | Valid | Review Needed	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Monitor, Review Needed, Valid
ce08a9ba-a4c8-44ff-93e4-cfeeaba8c20e	5288642d-13e8-45b3-8f77-bcbff82a42c5	17		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			test_drive_requested	Confidential	Car Demand	Test Drive Requested	Captures information about a customer's interest in taking their vehicle for a test drive as part of demand planning within the automotive industry domain. It informs sales forecasts and inventory management decisions by indicating whether potential customers have expressed a desire to experience the vehicle firsthand, thereby influencing supply chain optimization.	ai_generated	Boolean (Yes / No)	f	f	No | Yes	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	No, Yes
d65a3d38-547a-4cae-83f5-84d4c31766ce	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	25	PT Finansial Nusantara	PRJ002_Risk_Scoring.xlsx - RiSco	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Age	Confidential	\N	Age	Captures information about an individual's age within the Financial Services domain, which is a real-world fact that reflects their chronological age in whole numbers to support risk assessment and compliance requirements. It is used by business stakeholders to make informed decisions regarding loan eligibility, creditworthiness, and regulatory reporting. This value may be absent for individuals who have not provided their date of birth or are unidentified within the system.	ai_generated	Integer (whole number)	f	t	39 | 46 | 38 | 58 | 41	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	21, 22, 24, 25, 30, 33, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 48, 51, 53
e1fb7ef2-bfba-44fb-8143-08bf09f9aa69	5288642d-13e8-45b3-8f77-bcbff82a42c5	42		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			bank_financing	Confidential	Sales	Bank Financing	Captures information about a customer's financing arrangement with a bank in relation to car sales, indicating whether they have secured financing through a financial institution. This data is used by business stakeholders to analyze trends and make informed decisions regarding credit offerings and sales strategies.	ai_generated	Category: ACC, BCA Finance, Mandiri Tunas	f	t	ACC | None | BCA Finance | Mandiri Tunas	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	ACC, BCA Finance, Mandiri Tunas, None
26d15cb4-2dd1-4455-b61e-a626e9882762	5288642d-13e8-45b3-8f77-bcbff82a42c5	18		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			test_drive_date	Confidential	Car Demand	Test Drive Date	Captures and records a specific date in the calendar that indicates a customer's interest in taking a car for a test drive within the demand area, which is typically used to track sales trends and forecast future demand. It is also utilized by business analysts to analyze seasonal fluctuations and make informed decisions about inventory management.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	t	2025-02-13T00:00:00 | 2026-01-08T00:00:00 | 2024-06-16T00:00:00 | 2024-06-26T00:00:00 | 2024-09-17T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
760bc168-b02a-4879-803a-265504678c9d	ad670b81-df3b-4fc0-898c-b64b3098a186	10	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Flag	Confidential	Model Scoring	Flag	Captures and records a real-world fact that indicates whether a project has been flagged for review in the retail and automotive ecosystem, specifically within the model scoring domain. It is used to inform business decisions regarding project prioritization and resource allocation, as well as to track progress towards key performance indicators. The value of this data point can be interpreted as follows: "Yes" means that the project requires further evaluation or attention from stakeholders, while "No" indicates that the project is proceeding with standard procedures. In practice, a flagging decision may be based on factors such as project risk, customer feedback, or market trends. This value may be absent when no review or evaluation is required for a particular project, but it is considered sensitive information and should not be shared publicly.	ai_generated	Boolean (Yes / No)	f	t	Yes | No	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	No, Yes
e97ebc6c-3739-4dff-96c7-e76a1a44a88f	5288642d-13e8-45b3-8f77-bcbff82a42c5	9		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			budget_range	Confidential	Car Demand	Budget Range	Captures and records a specific budget range within the demand area that indicates the expected financial expenditure for a particular product or service over a certain period of time, anchored to industry standards and market trends. It is used by business stakeholders to make informed decisions about resource allocation and to track spending variances against established budgets in order to optimize profitability and achieve strategic objectives.	ai_generated	Category: 100M-200M, 200M-400M, 400M-600M, 600M+	f	f	100M-200M | 600M+ | 200M-400M | 400M-600M	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	100M-200M, 200M-400M, 400M-600M, 600M+
59bb8125-6aa2-41af-9306-b625e0f10d9a	5288642d-13e8-45b3-8f77-bcbff82a42c5	26		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sales_date	Confidential	Sales	Sales Date	Captures and records a specific date range for sales transactions within the automotive industry domain, which is essential to track sales performance over time in accordance with company policies and regulatory requirements. It serves as a critical component in generating monthly or quarterly sales reports that inform strategic business decisions regarding inventory management, pricing strategies, and marketing campaigns.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	f	2025-06-04T00:00:00 | 2026-01-09T00:00:00 | 2025-06-01T00:00:00 | 2025-08-12T00:00:00 | 2025-03-07T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
c44565ea-64aa-490b-a33f-dcf37116f858	ad670b81-df3b-4fc0-898c-b64b3098a186	12	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Full_Name	Highly Confidential	Master Customer	Full Name	Captures and records a unique, free-text identifier for individual customers within the Retail & Automotive Ecosystem domain, which uniquely identifies each customer record and is handled in accordance with our data privacy policy. It indicates an individual's full name, used to make informed business decisions and reporting across various retail and automotive operations.	ai_generated	Free text	t	t	Customer_0 | Customer_2 | Customer_3 | Customer_4 | Customer_5	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
ab7f5b7c-8213-447b-999a-1421e6db7c17	5288642d-13e8-45b3-8f77-bcbff82a42c5	24		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_notes	Confidential	Car Demand	Customer Notes	Captures customer concerns and issues related to their purchases, providing valuable insights into demand patterns in the automotive industry. This sensitive information is used by business analysts to inform product development decisions, track market trends, and measure customer satisfaction levels, making it a critical component of data-driven decision-making.	ai_generated	Free text (long description)	t	t	Quibusdam eveniet veniam molestias consectetur placeat animi repudiandae. | Magazine require those store dog program care owner. | Must would letter whole campaign kid whom two green feeling. | Enjoy only out friend work reach sell choice computer house meeting note or. | Voluptatum aperiam minima temporibus exercitationem suscipit.	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
ee3d993b-24a3-4caf-a303-38e1fa1225b3	5288642d-13e8-45b3-8f77-bcbff82a42c5	27		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			dealer_name	Highly Confidential	Sales	Dealer Name	Captures and records highly confidential information about individual dealerships in the sales domain, specifically their names. Used to identify specific businesses when tracking sales performance, reporting revenue, or analyzing market trends, while being handled in accordance with our personal identifiable information data privacy policy.	ai_generated	Free text	f	f	Mega Auto | Auto Prima | Borneo Cars | Nusantara Motor	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	Auto Prima, Borneo Cars, Mega Auto, Nusantara Motor
b7ccd29c-d628-42c7-a982-1cc556f06a12	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	21	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Notes	Confidential	\N	Notes	Captures information about loan transactions that indicate a level of risk associated with incomplete documentation, which is crucial for financial services to make informed decisions and ensure regulatory compliance. It provides valuable insights into the status of loan applications and helps identify potential issues early on. The notes field records three distinct categories: Good profile, High risk, and Incomplete docs, each conveying specific information about the transaction's risk level or documentation completeness. This value may be absent when a loan is fully documented and compliant with all regulatory requirements.	ai_generated	Free text	f	t	Incomplete docs | High risk | Good profile | Verified	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Good profile, High risk, Incomplete docs, Verified
6f175f90-bb06-4d49-bcf1-53c4154c42e5	ad670b81-df3b-4fc0-898c-b64b3098a186	14	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Phone	Highly Confidential	Master Customer	Phone	Captures and records a unique, phone number identifier for customers in the Retail & Automotive Ecosystem domain, which uniquely identifies each customer record and is handled under our data privacy policy to protect personally identifiable information. It is used by business stakeholders to make decisions about customer communication, sales, and service, as well as to track customer interactions across different channels.	ai_generated	Phone number	t	t	08191571465 | 08309427581 | 08189128932 | 08674014784 | 08928992881	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
042ac17b-9394-4e66-a208-5f0b1d987592	5288642d-13e8-45b3-8f77-bcbff82a42c5	92		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			loyalty_points	Confidential	Customer	Loyalty Points	Captures a unique identifier for customers who have earned loyalty points within our customer base. This value is used to track individual customer progress and inform rewards programs, helping us make informed decisions about future promotions and incentives.	ai_generated	Integer (whole number)	t	f	29439 | 24807 | 43920 | 42954 | 39086	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
12f4b0ac-0586-4de7-9595-e3d6bbaa6444	ad670b81-df3b-4fc0-898c-b64b3098a186	15	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Gender	Highly Confidential	Master Customer	Gender	Captures and records a critical aspect of customer identity within the Retail & Automotive Ecosystem, specifically in relation to Master Customer domain. It informs business decisions regarding customer segmentation, targeting, and overall sales strategy by providing insight into gender demographics. Female represents a female individual, Male represents a male individual. It is used to categorize customers for marketing purposes, such as product recommendations or promotional offers tailored to specific genders. Female indicates the customer is eligible for products typically associated with females, while Male indicates eligibility for products typically associated with males. The value Female signifies that the customer identifies as female in practical terms, and Male signifies that the customer identifies as male. This data may be absent when a customer's gender is unknown or not specified. It is handled under our data privacy policy to ensure sensitive information.	ai_generated	Category: Female, Male	f	t	Female | Male	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Female, Male
9e012055-d8ab-4cde-908f-1efad5e229d0	5288642d-13e8-45b3-8f77-bcbff82a42c5	28		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			salesperson_name	Highly Confidential	Sales	Salesperson Name	Captures and records a unique identifier for individual sales professionals within the Sales domain, reflecting their professional identity in the context of car sales transactions. This sensitive information is used to track sales performance, measure individual contributions to overall revenue, and inform business decisions regarding personnel management and compensation. This personally identifiable data is handled under our organization's data privacy policy and must be treated with high confidentiality due to its sensitivity, uniquely identifying each record in the dataset.	ai_generated	Free text	t	f	Qori Simbolon | David Hudson | Balijan Sirait | Okto Puspasari | Mark Brown	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
00ddc30b-4e0b-40dc-b215-5c31801fd571	5288642d-13e8-45b3-8f77-bcbff82a42c5	68		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			battery_health	Highly Confidential	Stock	Battery Health	Captures real-world fact that a vehicle's battery health status, which reflects its overall condition and performance within the stock domain. Indicates whether the vehicle can be safely used for transportation, influencing business decisions related to fleet management, maintenance schedules, and customer satisfaction. This data is handled under our personal identifiable information (PII) policy, as it pertains to sensitive individual-level characteristics, and may be absent if a vehicle has not been in use or has unknown battery health status.	ai_generated	Integer (whole number)	f	t	99 | 93 | 86 | 97 | 71	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
ce8d1134-3ecf-4c3c-b399-833351ada673	ad670b81-df3b-4fc0-898c-b64b3098a186	8	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Confidence	Confidential	Model Scoring	Confidence	Captures a measure of how certain in its predictions that an AI scoring model is, reflecting confidence levels within the retail and automotive ecosystem's model scoring domain. It influences business decisions by informing whether to approve or reject a transaction based on the predicted outcome. This value may be absent when no prediction has been made for a particular record.	ai_generated	Decimal number	f	t	0.76 | 0.91 | 0.78 | 0.96 | 0.95	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
eee68041-afea-4fbb-a3d9-33257a40b30f	5288642d-13e8-45b3-8f77-bcbff82a42c5	21		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			lead_score	Confidential	Car Demand	Lead Score	Captures a measure of demand that reflects an organization's ability to convert potential customers into actual sales, anchored in the automotive industry and within the realm of demand. It is used by business stakeholders to inform pricing strategies, resource allocation decisions, and forecasting models. This value may be absent when there are no recorded interactions with potential customers or during periods of low market activity.	ai_generated	Integer (whole number)	f	t	94 | 22 | 77 | 59 | 9	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
c845479f-4a7f-4e7b-9afb-8bcb51a410a2	5288642d-13e8-45b3-8f77-bcbff82a42c5	32		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vehicle_year	Confidential	Sales	Vehicle Year	Captures and records the year in which a vehicle was sold within the sales domain for that specific type of vehicle. It is used to track historical trends, inform pricing strategies, and support regulatory compliance reporting by providing a clear understanding of when vehicles were introduced or discontinued.	ai_generated	Integer (whole number)	f	f	2025 | 2020 | 2026 | 2023 | 2024	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	2020, 2021, 2022, 2023, 2024, 2025, 2026
2e33d05f-09a0-4dc2-bc36-42c8f866c343	85eaf07b-2298-4658-baaa-a5e267c74812	6	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Quality_Score	Confidential	\N	Quality Score	Captures a measure of an account's creditworthiness in the banking industry, reflecting its ability to repay loans and other financial obligations. It is used by business stakeholders to make informed decisions about lending and risk management, as well as to generate reports on customer credit performance. This value may be absent when an account has no outstanding loans or credit history.	ai_generated	Decimal number	f	t	0.72 | 0.79 | 0.9 | 1 | 0.81	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	0.63, 0.68, 0.69, 0.72, 0.74, 0.75, 0.76, 0.77, 0.79, 0.8, 0.81, 0.82, 0.84, 0.89, 0.9, 0.96, 0.98, 0.99, 1
8234cf2e-776b-4187-8f9b-877abc0fcf6a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	20		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_ID	Confidential	\N	Customer Identifier	Captures a unique identifier for customers within the billing and inventory management process, which is used to track individual customer accounts and ensure accurate billing and payment processing in order to inform business decisions regarding customer relationships and financial transactions.	ai_generated	ID / Code (e.g. CUST1039)	f	f	CUST1039 | CUST1000 | CUST1010 | CUST1027 | CUST1056	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
33a7138a-d08c-47f3-a31d-edcd13b82763	85eaf07b-2298-4658-baaa-a5e267c74812	1	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Record_ID	Confidential	\N	Record Identifier	Captures and records a unique, free-text identifier for every project in the banking domain, anchored to specific business processes and regulatory requirements. This value is used by business stakeholders to make informed decisions about project tracking, reporting, and compliance, uniquely identifying each record and enabling efficient management of sensitive financial information.	ai_generated	Free text	t	t	PRJ003_0_0 | PRJ003_0_1 | PRJ003_0_2 | PRJ003_0_3 | PRJ003_0_4	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	\N
6b9b8c8f-4980-4ec2-8539-9a02b105fe79	5288642d-13e8-45b3-8f77-bcbff82a42c5	12		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			financing_interest	Confidential	Car Demand	Financing Interest	Captures information about whether a customer has been offered financing options for their vehicle purchase and reflects the financial implications of such an offer on demand. It is used by sales teams to tailor product presentations and pricing strategies to individual customers' needs, influencing overall revenue projections and customer satisfaction metrics.	ai_generated	Boolean (Yes / No)	f	f	No | Yes	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	No, Yes
55a2479a-d23b-43d7-9f43-c275809f9ed8	5288642d-13e8-45b3-8f77-bcbff82a42c5	5		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			email	Highly Confidential	Car Demand	Email	Captures real-world contact information for individuals who have expressed interest in purchasing a vehicle, specifically within the demand area of the automotive industry. Indicates how customer email addresses are used to personalize marketing efforts and track sales leads, while also being handled under our data privacy policy due to its personally identifiable nature.	ai_generated	Email (name@domain.com)	t	f	christinewilliams@yahoo.com | nicolas45@gmail.com | hastutiwakiman@cv.ponpes.id | farahpradipta@perum.gov | taswirlaksita@yahoo.com	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
9f42b443-b12d-4e82-b9c3-a4067c3a4486	5288642d-13e8-45b3-8f77-bcbff82a42c5	6		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_brand	Confidential	Car Demand	Preferred Brand	Captures information about a customer's preferred car brand within the demand area. It is used to inform product offerings and pricing strategies in order to meet specific market needs.	ai_generated	Category: BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling	f	f	Mitsubishi | Honda | BMW | Hyundai | Mercedes-Benz	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling
8ecacb11-b171-4f0f-933f-af9a95ef7614	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	21		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Item_Code	Confidential	\N	Item Code	Captures and records a unique identifier for inventory items within the billing process, which is used to track specific products across various orders and transactions in the supply chain domain. This value plays a crucial role in generating invoices and processing payments by providing a distinct code that corresponds to each item being billed or sold.	ai_generated	Category: ITM01, ITM02, ITM03, ITM04	f	f	ITM02 | ITM03 | ITM04 | ITM01	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	ITM01, ITM02, ITM03, ITM04
f7cf0f8f-18a9-43ea-97f2-e6eb2479f835	5288642d-13e8-45b3-8f77-bcbff82a42c5	8		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_color	Confidential	Car Demand	Preferred Color	Captures information about a customer's preferred color within the demand area, specifically related to car sales and marketing strategies that focus on appealing to individual tastes and preferences in the automotive industry domain. This value is used by business analysts and marketers to segment customers based on their color preferences when creating targeted advertising campaigns or analyzing consumer behavior patterns.	ai_generated	Category: Black, Blue, Gray, Red, Silver, White	f	f	Black | Gray | Red | Silver | White	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	Black, Blue, Gray, Red, Silver, White
2d2b7e25-8132-4416-b606-4408eb9b6942	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	24		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Price	Confidential	\N	Price	Captures a unique monetary charge applied to an item's sale or purchase in the inventory billing process, which is essential for calculating total costs and determining profit margins within the organization's retail operations. Is used by financial analysts and management to make informed decisions about pricing strategies, cost control measures, and revenue projections, as this value uniquely identifies each record and provides a critical component of the overall sales data.	ai_generated	Integer (whole number)	t	f	266139 | 117215 | 381186 | 194356 | 253861	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
c1f9edca-f72a-4fdd-9752-0855f499b6e2	5288642d-13e8-45b3-8f77-bcbff82a42c5	4		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			phone_number	Highly Confidential	Car Demand	Phone Number	Captures and records a unique identifier for individual customers within the demand area, specifically related to their contact information in Brazil. Indicates a critical component used by sales teams to track customer interactions and make informed decisions about product offerings and pricing strategies, while also being handled under our data privacy policy due to its personally identifiable nature.	ai_generated	Phone number	t	f	284.999.6454x9229 | (953)698-3320x600 | +62 (0143) 288-9861 | +62-331-020-2581 | +62 (013) 806 5130	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
8724efae-1738-4354-8563-08f1b200ce6a	ad670b81-df3b-4fc0-898c-b64b3098a186	16	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Birth_Date	Highly Confidential	Master Customer	Birth Date	Captures and records a customer's birth date, which is an important fact in the Retail & Automotive Ecosystem domain of Master Customer, providing valuable information about individual customers' life events. It is used by business stakeholders to make informed decisions about customer loyalty programs, promotions, and product offerings. This data value uniquely identifies each record, but may be absent for deceased or unknown individuals, handled under our organization's data privacy policy.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	1985-01-01T00:00:00 | 1985-01-02T00:00:00 | 1985-01-03T00:00:00 | 1985-01-04T00:00:00 | 1985-01-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
d443c530-c5b0-4eac-836c-d76d1d1b15b0	5288642d-13e8-45b3-8f77-bcbff82a42c5	11		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			transmission_preference	Confidential	Car Demand	Transmission Preference	Captures real-world preferences for automatic versus manual transmission types within the demand area of the automotive industry domain, which reflects customer attitudes and driving habits that influence sales trends and market analysis. This information is used by business stakeholders to inform product development decisions, pricing strategies, and marketing campaigns targeting specific segments of customers with preferred transmission types.	ai_generated	Category: Automatic, Manual	f	f	Automatic | Manual	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	Automatic, Manual
be6f5a38-a03a-44dc-b4b5-d8ca8645d14b	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	27		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Transaction_Date	Confidential	\N	Transaction Date	Captures and records a specific date range within an inventory billing cycle that is critical to determining payment schedules, refunds, and other financial obligations in the manufacturing sector. It serves as a key component in identifying trends, forecasting demand, and making informed decisions about production planning and resource allocation.	ai_generated	Date (YYYY-MM-DD)	t	f	2026-02-01 | 2026-02-02 | 2026-02-03 | 2026-02-04 | 2026-02-05	DATE	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
c327ec04-e6a7-4da9-a9fb-bdf0ebef980c	5288642d-13e8-45b3-8f77-bcbff82a42c5	14		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			source_channel	Confidential	Car Demand	Source Channel	Captures information about how customers are exposed to products or services that meet their demand needs in various channels. This data is used by business stakeholders to analyze customer behavior, track marketing campaigns' effectiveness, and make informed decisions about product placement and promotion strategies.	ai_generated	Category: Instagram, Referral, Walk-in, Website	f	f	Referral | Instagram | Walk-in | Website	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	Instagram, Referral, Walk-in, Website
5f7dfb6a-cf27-4ecb-90ec-4f5ebaa45321	5288642d-13e8-45b3-8f77-bcbff82a42c5	16		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			urgency_level	Confidential	Car Demand	Urgency Level	Captures and records a measure of how quickly demand for cars is changing within the automotive industry's supply chain domain. It indicates whether customers are likely to make an immediate purchase decision based on their current needs, influencing sales forecasts and inventory management strategies.	ai_generated	Category: High, Low, Medium	f	f	Low | Medium | High	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	High, Low, Medium
31489074-4b56-409a-9300-cc030d342cdb	5288642d-13e8-45b3-8f77-bcbff82a42c5	13		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			trade_in_interest	Confidential	Car Demand	Trade In Interest	Captures information about whether a customer is trading in their vehicle when purchasing a new car, which reflects their willingness to give up their current vehicle as part of the deal. This value is used by sales teams and financial analysts to understand customer preferences and make informed decisions about pricing and incentives.	ai_generated	Boolean (Yes / No)	f	f	No | Yes	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	No, Yes
eba5ab3e-ddcc-4a87-a86f-233c42c2acb6	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	9	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Application_Date	Confidential	\N	Application Date	Captures and records the date on which a customer's credit profile was last updated, providing critical information for financial services operations within the organization. It is used to inform business decisions regarding loan approvals, interest rates, and account management, as well as in reporting to track changes in customer creditworthiness over time.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01T00:00:00 | 2026-01-02T00:00:00 | 2026-01-03T00:00:00 | 2026-01-04T00:00:00 | 2026-01-06T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
65564a4d-db19-4c60-bc0c-5f74d6ab100f	ad670b81-df3b-4fc0-898c-b64b3098a186	17	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	City	Confidential	Master Customer	City	Captures information about a customer's location within the Retail & Automotive Ecosystem domain, specifically in relation to Master Customer records. It is used to identify and track customers for targeted marketing campaigns, sales promotions, and loyalty programs across various retail and automotive channels. The city value indicates that this customer resides in Bandung, Jakarta, Medan, or Surabaya, with each location associated with distinct characteristics and preferences. A city of Bandung signifies a customer from the western region, while a city of Jakarta implies an urban dweller. This data may be absent for customers who do not reside within these specified cities or regions, which could occur due to various factors such as business partnerships in other locations or changes in customer addresses over time.	ai_generated	Category: Bandung, Jakarta, Medan, Surabaya	f	t	Jakarta | Surabaya | Bandung | Medan	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Bandung, Jakarta, Medan, Surabaya
729a5cc2-9289-4490-99cf-19f68a0c3427	5288642d-13e8-45b3-8f77-bcbff82a42c5	15		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			dealer_location	Confidential	Car Demand	Dealer Location	Captures real-world information about specific locations where cars are sold, providing a critical detail within the demand domain that helps organizations understand market trends and customer behavior. This business term is used to inform sales strategies, track regional performance, and support data-driven decision-making across various departments.	ai_generated	Category: Balikpapan, Bandung, Bontang, Jakarta, Samarinda, Surabaya	f	f	Bontang | Balikpapan | Bandung | Surabaya | Jakarta	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	Balikpapan, Bandung, Bontang, Jakarta, Samarinda, Surabaya
dc05d4bf-b87f-4ed2-b395-d5a626e8121c	5288642d-13e8-45b3-8f77-bcbff82a42c5	20		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			assigned_salesperson	Confidential	Car Demand	Assigned Salesperson	Captures information about the salesperson responsible for a specific car sale in the demand area. This assigned salesperson is used to track and report on individual sales performance, providing insights into who is driving sales growth or struggling with certain products within the business.	ai_generated	Free text	t	f	Cinthia Wijaya | Victoria Reynolds | Edi Pudjiastuti | Zaenab Mahendra | Tgk. Titin Januar, S.Farm	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
8d119665-f5fd-4842-b1f3-ed64bc82bf5e	5288642d-13e8-45b3-8f77-bcbff82a42c5	22		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			competitor_brand	Confidential	Car Demand	Competitor Brand	Captures information about a specific brand that competes in the demand for vehicles, providing insight into market share and consumer preferences within the automotive industry. This data is used to inform product development strategies, marketing campaigns, and sales forecasting, helping businesses make more accurate decisions about which brands to invest in or target.	ai_generated	Category: BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling	f	t	Toyota | Mitsubishi | Wuling | BMW | Honda	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling
f241de9b-93b9-4f30-82bb-9fad83d04ab4	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	19		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Transaction_ID	Confidential	\N	Transaction Identifier	Captures a unique identifier for every transaction in the inventory billing domain, which is used to track and measure individual transactions across various business processes and reporting periods. This value is crucially used by management and analysts to identify specific transactions when reviewing financial performance, making adjustments, or generating reports on sales trends.	ai_generated	ID / Code (e.g. TRX2000)	t	f	TRX2000 | TRX2001 | TRX2002 | TRX2003 | TRX2004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
053cab9f-1f0c-405e-8eb3-0b0427b68618	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	2	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Customer_ID	Confidential	\N	Customer Identifier	Captures and records a unique, free-text identifier for customers within the financial services domain, which is used to track individual customer accounts and ensure accurate billing and credit reporting. It uniquely identifies each record in the system, allowing business stakeholders to make informed decisions about customer relationships and creditworthiness. This value may be absent when a new customer account is created or updated, as the identifier is typically populated by the financial services team during onboarding or after initial data entry.	ai_generated	ID / Code (e.g. CUST1000)	t	t	CUST1000 | CUST1001 | CUST1002 | CUST1003 | CUST1004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
56271c8a-74f9-4188-b482-0d76282741ac	ad670b81-df3b-4fc0-898c-b64b3098a186	31	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Transaction_ID	Confidential	Transaction	Transaction Identifier	Captures and records a unique, free-text identifier for every transaction within the retail and automotive ecosystem domain, which is used to track individual transactions across various business processes. It uniquely identifies each record in the system, allowing for accurate tracking and analysis of sales data, inventory movements, and customer interactions. This value may be absent when a transaction has not been completed or recorded, but its absence does not imply that no such transaction exists.	ai_generated	ID / Code (e.g. TRX2000)	t	t	TRX2000 | TRX2001 | TRX2002 | TRX2003 | TRX2004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
93fb942b-38d0-4454-9ae8-daf2821868ec	5288642d-13e8-45b3-8f77-bcbff82a42c5	33		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vin_number	Confidential	Sales	Vin Number	Captures and records a unique identifier for every vehicle sold within the sales domain, specifically in the automotive industry, which is used to track individual vehicles across all transactions and ensures accurate reporting of sales data by providing a distinct reference point for each record. This value is utilized in business decisions and financial analysis to verify ownership, facilitate warranty claims, and enable targeted marketing efforts by uniquely identifying each vehicle sold.	ai_generated	Free text	t	f	PsF03308986396 | RZA47671045896 | wSy27991932593 | IuF49252172795 | tNm98813794655	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
6bfc1c54-c5bc-4687-972a-b0aced401f85	5288642d-13e8-45b3-8f77-bcbff82a42c5	23		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			estimated_purchase_date	Confidential	Car Demand	Estimated Purchase Date	Captures the estimated date on which a customer is expected to make a purchase within the demand area, reflecting real-world fact that a sale is imminent. It informs business decisions by providing critical insights into seasonal fluctuations and helping forecasters predict future sales trends.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	f	2025-04-15T00:00:00 | 2026-02-08T00:00:00 | 2024-09-05T00:00:00 | 2024-07-19T00:00:00 | 2024-12-09T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
ef45a823-82f5-4104-929e-2314fedf6d9a	5288642d-13e8-45b3-8f77-bcbff82a42c5	34		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			engine_number	Confidential	Sales	Engine Number	Captures a unique identifier for every vehicle sold within the sales domain, anchored to the engine specifications and ensuring confidentiality in sensitive business information. This value is used by sales teams to track individual vehicles across multiple transactions, enabling accurate reporting on sales performance and customer loyalty.	ai_generated	ID / Code (e.g. ENG34262)	t	f	ENG34262 | ENG75037 | ENG86353 | ENG47276 | ENG08548	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
3c58bb52-10a1-4c05-801c-3d01c0a3f0d8	ad670b81-df3b-4fc0-898c-b64b3098a186	2	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Customer_ID	Confidential	Model Scoring	Customer Identifier	Captures and records a unique identifier for customers within the retail and automotive ecosystem's model scoring domain, which is used to track individual customer interactions and preferences across various products and services. It indicates a specific customer segment in business decisions and reporting, such as personalized marketing campaigns or loyalty program rewards. This value may be absent when a new customer is onboarded or during data cleansing processes to ensure accurate identification of existing customers.	ai_generated	ID / Code (e.g. CUST1068)	f	t	CUST1068 | CUST1005 | CUST1065 | CUST1066 | CUST1003	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
e8d45d77-4a35-45e0-b30a-7a61a08baaf5	85eaf07b-2298-4658-baaa-a5e267c74812	20	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Issue_Flag	Confidential	\N	Issue Flag	Captures and records a real-world fact that indicates whether an issue has been resolved in a banking project, providing clarity on the status of quality issues within the domain. Is used to inform business decisions regarding project prioritization, resource allocation, and risk management, as well as to generate reports on the overall quality of projects across the organization. The value "Yes" or "True" indicates that an issue has been resolved, while "No" or "False" signifies that it remains outstanding. In practice, a "Yes" means the issue is closed, a "No" means it's still open. The possible values are as follows: A "Yes" value means the issue has been successfully addressed and does not impact project progress.	ai_generated	Boolean (Yes / No)	f	t	No | Yes	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	No, Yes
2aecf80d-453f-48ba-ac8d-029d60e982fb	85eaf07b-2298-4658-baaa-a5e267c74812	13	PT ABC Tbk	PRJ003_Data_Quality.xlsx - Data Quality	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Dataset_Name	Highly Confidential	\N	Dataset Name	Captures information about the type of dataset being managed in the banking industry, specifically indicating whether it pertains to customer, inventory, or sales data. This recorded fact informs business decisions and reporting by enabling stakeholders to categorize and analyze datasets accordingly. The values captured reflect specific categories: Customer indicates a dataset related to individual customers' accounts, Inventory signifies a dataset tracking product stock levels, while Sales denotes a dataset containing transactional records of financial transactions. These meanings are essential for operational efficiency and strategic planning. This data is personally identifiable information handled under our data privacy policy, and it may be absent when datasets are not categorized or when the categorization process has not been completed yet.	ai_generated	Free text	f	t	Inventory | Sales | Customer	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Customer, Inventory, Sales
e07a0945-eebb-4031-8490-bd16a760afac	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	17	PT Finansial Nusantara	PRJ002_Loan_Transactions.xlsx - LoTrans	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Loan_Amount	Confidential	\N	Loan Amount	Captures and records a specific financial transaction amount within the Financial Services domain, which is used to determine loan eligibility and calculate interest payments. It uniquely identifies each record in the system, allowing for accurate tracking of individual loans and facilitating business decisions regarding loan approvals and repayments. This value may be absent if there has been no outstanding balance on an account or if a payment was made without specifying an amount.	ai_generated	Integer (whole number)	t	t	86156168 | 52706419 | 23493895 | 126251696 | 104782359	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	\N
2e8af8e4-795c-4bdf-a1c8-db39c3f9d6b4	5288642d-13e8-45b3-8f77-bcbff82a42c5	61		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			selling_price	Confidential	Stock	Selling Price	Captures and records a unique selling price for every stock item in the inventory, which is used to determine profit margins and revenue calculations within the retail sector. This confidential data is crucial in making informed business decisions regarding pricing strategies, inventory management, and supply chain logistics.	ai_generated	Integer (whole number)	t	f	870073230 | 317745641 | 431462611 | 190833451 | 757081805	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
ea04cd0c-7c9a-457d-b56a-39937fb44d18	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	10	PT Finansial Nusantara	PRJ002_Credit_Profile.xlsx - CreProf	Financial Services	Source	Smart Credit Risk Analytics Platform	2026		Chloe Mitchell <chloe.mitchell88@example.com>	Notes	Confidential	\N	Notes	Captures information about a customer's credit profile in relation to their financial health and stability within our Financial Services domain, which is critical for making informed lending decisions. It provides valuable insights into an individual's risk level and helps guide business outcomes such as loan approvals or denials. The value of this field is used to categorize customers based on their creditworthiness, with each category indicating a specific level of risk or profile type that affects our financial performance and regulatory compliance. This data is categorized into three distinct values: Good profile indicates a low-risk customer, High risk signifies an individual who may struggle with repayment, and Incomplete docs suggests a lack of necessary information to assess creditworthiness. Verified denotes a confirmed identity and accurate credit history, which provides assurance in the lending process.	ai_generated	Free text	f	t	Good profile | Incomplete docs | High risk | Verified	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 11:54:37.043282+00	40	2026	Good profile, High risk, Incomplete docs, Verified
73e25b4d-ab74-4dbc-8443-1deb2f6cc60f	5288642d-13e8-45b3-8f77-bcbff82a42c5	36		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			fuel_type	Confidential	Sales	Fuel Type	Captures information about the type of fuel used to power vehicles sold within the sales domain and specifically in the automotive industry, which is a critical aspect of understanding customer preferences and market trends related to vehicle ownership and maintenance costs. Is used by business stakeholders to make informed decisions regarding product offerings, pricing strategies, and marketing campaigns that cater to different types of fuel, thereby influencing overall revenue and profitability.	ai_generated	Category: Diesel, Electric, Gasoline, Hybrid	f	f	Diesel | Electric | Gasoline | Hybrid	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	Diesel, Electric, Gasoline, Hybrid
d5c6a10c-1c58-4960-80ef-95c3c2548210	5288642d-13e8-45b3-8f77-bcbff82a42c5	59		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			stock_status	Confidential	Stock	Stock Status	Captures and records information about a vehicle's current status within the stock domain, providing insight into its location and movement within the supply chain. It is used to inform inventory management decisions, track shipments, and ensure accurate reporting of stock levels and movements in real-time.	ai_generated	Category: Available, In Transit, Reserved	f	f	In Transit | Available | Reserved	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Available, In Transit, Reserved
b1470002-1e68-4ebf-83b3-b8de8ff8d7d8	85eaf07b-2298-4658-baaa-a5e267c74812	2	PT ABC Tbk	PRJ003_Data_Governance.xlsx - Data Gov	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Dataset_Name	Highly Confidential	\N	Dataset Name	Captures and records a real-world fact that identifies a customer as belonging to one of three categories: Customer, Inventory, or Sales in the banking business area. Used in business decisions and reporting to track customer type for account management and risk assessment purposes. The values are categorized into distinct meanings - a value of "Customer" indicates an individual customer, while "Inventory" signifies a product or asset, and "Sales" denotes a transactional event. These categories provide context for understanding the nature of interactions within the banking domain. This data is personally identifiable and handled in accordance with our data privacy policy, and may be absent when no category can be determined due to incomplete or missing information.	ai_generated	Free text	f	t	Customer | Inventory | Sales	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	Customer, Inventory, Sales
50f9c960-0872-4fe8-835a-66ea5c7db2eb	85eaf07b-2298-4658-baaa-a5e267c74812	29	PT ABC Tbk	PRJ003_Metadata_Catalog.xlsx - Meta Log	Banking	Source	Enterprise Data Governance Implementation	2026		Amelia Brooks <amelia.brooks74@example.com>	Completeness	Confidential	\N	Completeness	Captures a measure of how complete a project is in relation to its overall goals and objectives within the banking industry, reflecting the level of progress made towards achieving those goals. It influences business decisions by indicating whether a project has reached a high degree of completion, allowing stakeholders to assess the likelihood of meeting deadlines or exceeding expectations.	ai_generated	Decimal number	f	t	0.99 | 0.62 | 0.91 | 0.67 | 0.61	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 12:21:20.78585+00	40	2026	0.51, 0.53, 0.55, 0.58, 0.59, 0.61, 0.62, 0.63, 0.67, 0.71, 0.74, 0.76, 0.8, 0.82, 0.83, 0.85, 0.87, 0.89, 0.91, 0.92
b2640f9c-1e6f-46e5-b498-b76899198fd8	ad670b81-df3b-4fc0-898c-b64b3098a186	3	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Churn_Risk	Confidential	Model Scoring	Churn Risk	Captures and records a categorical assessment of customer risk in relation to leaving a retail or automotive purchase, anchored within the context of model scoring for the retail & automotive ecosystem. It informs business decisions regarding creditworthiness and loyalty programs by providing insight into the likelihood of customers switching to competitors. The value indicates that a medium level of churn risk is present when the category is Medium, suggesting a moderate probability of customer defection, while High and Low categories signify higher or lower risks respectively, with each representing distinct levels of potential loss. In practice, a high risk would necessitate more stringent credit terms, whereas low risk might warrant less scrutiny. This value may be absent for customers who have not yet demonstrated any signs of churn behavior, such as making payments on time and maintaining account activity over an extended period.	ai_generated	Category: High, Low, Medium	f	t	Medium | High | Low	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	High, Low, Medium
21c692f3-c206-454b-8366-7121fa6ad84d	5288642d-13e8-45b3-8f77-bcbff82a42c5	38		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			sale_price	Confidential	Sales	Sale Price	Captures and records the total amount paid by a customer for a vehicle sale in the sales domain, providing critical financial information to support business decisions related to revenue tracking and profitability analysis. This data is used to make informed decisions about pricing strategies, inventory management, and customer loyalty programs, uniquely identifying each record with its corresponding sale price value.	ai_generated	Integer (whole number)	t	f	369788155 | 887501242 | 336541403 | 556257861 | 274547116	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
d0caadc8-9ded-440d-9df8-af134562a219	5288642d-13e8-45b3-8f77-bcbff82a42c5	39		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			discount_amount	Confidential	Sales	Discount Amount	Captures the real-world fact that a specific amount is deducted from the total sale price of an automobile, reflecting the discount applied to individual transactions within the sales domain. Indicates the percentage reduction in revenue for each car sold, influencing business decisions and financial reporting by providing insight into pricing strategies and customer loyalty.	ai_generated	Integer (whole number)	t	t	21008061 | 30096419 | 35211073 | 39092495 | 317550	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
ca502f7e-0e94-457f-8e15-ac87f926fc39	5288642d-13e8-45b3-8f77-bcbff82a42c5	37		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			transmission	Confidential	Sales	Transmission	Captures information about the type of transmission used in vehicle sales within the automotive industry, specifically identifying whether it is an Automatic or Manual transmission type that reflects customer preferences and purchasing decisions. This data is utilized by sales teams to analyze market trends, track customer behavior, and make informed recommendations for new vehicle models and inventory management.	ai_generated	Category: Automatic, Manual	f	f	Automatic | Manual	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	Automatic, Manual
12052e4b-5096-4a82-8294-a80c223c37d6	ad670b81-df3b-4fc0-898c-b64b3098a186	30	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Duration_Minutes	Confidential	Digital Behaviour	Duration Minutes	Captures a measure of time spent by customers in digital environments within the Retail and Automotive Ecosystem, specifically related to their behavior in online platforms. This duration is used to inform business decisions on customer engagement strategies, track sales performance, and analyze overall retail experience. The absence of this value may occur when a customer has not interacted with any digital channels or platforms during a specific time period.	ai_generated	Integer (whole number)	f	t	34 | 48 | 86 | 4 | 56	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
4190d8cd-564b-40cb-9fe5-1ba12b0a07da	ad670b81-df3b-4fc0-898c-b64b3098a186	33	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Product_Code	Confidential	Transaction	Product Code	Captures and records a category classification for products within the retail and automotive ecosystem domain, which is used to categorize transactions into specific product groups that are relevant to business decisions and reporting. Category PRD1 represents standard parts, PRD2 signifies accessories, PRD3 denotes replacement parts, and PRD4 indicates specialty items. Each of these categories has a distinct meaning in practice, with PRD1 products being non-discretionary, PRD2 products offering additional functionality or convenience, PRD3 products providing alternative solutions to existing ones, and PRD4 products catering to specific customer needs that differ from standard offerings.	ai_generated	Category: PRD1, PRD2, PRD3, PRD4	f	t	PRD4 | PRD1 | PRD2 | PRD3	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	PRD1, PRD2, PRD3, PRD4
83c3ee15-5488-4e1a-be09-9276a209290c	5288642d-13e8-45b3-8f77-bcbff82a42c5	1		car_demand_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			demand_id	Confidential	Car Demand	Demand Identifier	Captures and records a unique identifier for demand in the automotive industry, anchored to the vehicle type and purchase history within the Demand domain. It is used by sales teams to track customer preferences and inform inventory management decisions, ensuring accurate reporting on sales performance and supply chain optimization.	ai_generated	ID / Code (e.g. DEM00001)	t	f	DEM00001 | DEM00002 | DEM00003 | DEM00004 | DEM00005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1300	\N	\N
b9afffc4-6ce9-4d5c-a225-db8fc37d1586	ad670b81-df3b-4fc0-898c-b64b3098a186	4	Astra International – Digital Transformation Division	PRJ004_AI_Scoring.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Next_Best_Action	Confidential	Model Scoring	Next Best Action	Captures real-world customer interactions in a retail and automotive ecosystem, specifically within model scoring to inform next steps for customers who have not taken action. It is used by business stakeholders to make decisions about follow-up actions, such as calling the customer or offering discounts, which can impact sales and revenue. Its possible values indicate different levels of engagement, including call customer indicating a need for immediate attention, no action suggesting a lack of urgency, and offer discount signifying an opportunity to incentivize purchase.	ai_generated	Category: Call Customer, No Action, Offer Discount	f	t	No Action | Offer Discount | Call Customer	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Call Customer, No Action, Offer Discount
68903994-501a-4d0b-b2ad-1490d95376f9	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	1		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Record_ID	Confidential	Service Prediction	Record Identifier	Captures a unique identifier for every project related to artificial intelligence analytics in the service prediction domain, which is used to distinguish one project from another and ensure accurate tracking of individual records throughout their lifecycle. This value is crucial in business decisions as it enables organizations to make informed choices about resource allocation, project prioritization, and data analysis, ultimately driving better outcomes for customers and stakeholders.	ai_generated	ID / Code (e.g. REC3000)	t	f	REC3000 | REC3001 | REC3002 | REC3003 | REC3004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
95ae17be-e6d4-485c-bf01-e8df0a3ed17a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	4		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Last_Service_Days	Confidential	Service Prediction	Last Service Days	Captures the number of days remaining before a service is predicted to end within its respective domain, specifically in the context of service prediction for projects. It informs business stakeholders about the time frame during which services are expected to be available or unavailable, influencing decisions related to resource allocation and customer expectations.	ai_generated	Integer (whole number)	f	f	312 | 19 | 321 | 295 | 251	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
adad8af6-fbae-4c0f-a2aa-24a01db357d7	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	5		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Prediction_Service_Need	Confidential	Service Prediction	Prediction Service Need	Captures real-world fact that a service is required to make predictions based on specific criteria within the Service Prediction domain. Indicates its sensitivity level as confidential and ensures it cannot be null or primary key, reflecting its importance in business decision-making processes.	ai_generated	Category: Immediate, Not Soon, Soon	f	f	Soon | Not Soon | Immediate	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Immediate, Not Soon, Soon
57d0bacb-44c9-4b01-ad27-ce511d8cea23	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	12		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Email	Highly Confidential	\N	Email	Captures and records a customer's unique email address, which serves as a distinguishing identifier for individual customers in our service operations domain. This sensitive information is used to make personalized business decisions and inform reporting on customer interactions, handled under our data privacy policy to protect personally identifiable information.	ai_generated	Email (name@domain.com)	t	f	customer0@mail.com | customer1@mail.com | customer2@mail.com | customer3@mail.com | customer4@mail.com	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
cbac7647-25a3-4e87-a3b8-9659f0f3f7bc	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	17		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Dealer_Code	Confidential	\N	Dealer Code	Captures a unique identifier for dealerships within the automotive industry, which is used to track and manage customer service interactions across various locations. It plays a crucial role in informing sales strategies, inventory allocation, and customer loyalty programs by providing a standardized way of distinguishing between different dealership entities.	ai_generated	Category: DLR01, DLR02, DLR03	f	f	DLR03 | DLR01 | DLR02	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	DLR01, DLR02, DLR03
39fd7a24-ac5c-46da-aa70-df5749561169	5288642d-13e8-45b3-8f77-bcbff82a42c5	40		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			down_payment	Confidential	Sales	Down Payment	Captures a critical aspect of sales transactions in the automotive industry, specifically within the domain of Sales, where it represents the amount paid upfront by customers at the time of purchase. This value is used to inform business decisions regarding financing options, pricing strategies, and customer loyalty programs, as well as to track key performance indicators such as revenue growth and customer retention.	ai_generated	Integer (whole number)	t	f	136697057 | 232538000 | 82008415 | 248158794 | 121488048	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
0dd14761-d82f-4289-bb08-6d326bd62e90	5288642d-13e8-45b3-8f77-bcbff82a42c5	41		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			loan_tenure_months	Confidential	Sales	Loan Tenure Months	Captures the number of months a customer has an outstanding loan balance within the sales process. It is used to calculate interest charges and determine payment schedules for customers with extended loan periods, influencing overall revenue recognition and financial performance.	ai_generated	Integer (whole number)	f	f	48 | 12 | 24 | 60 | 36	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	12, 24, 36, 48, 60
b5bf773c-b45f-415b-aa3f-977057b0d367	5288642d-13e8-45b3-8f77-bcbff82a42c5	43		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			insurance_provider	Confidential	Sales	Insurance Provider	Captures information about the insurance provider responsible for a vehicle sale in the sales domain. It is used to identify and track customer loyalty, policy renewals, and claims history in order to inform business decisions on premium pricing, discounts, and targeted marketing campaigns. This data may be absent if a vehicle sale does not involve an insurance contract or if the insurance information is not available due to incomplete or outdated records.	ai_generated	Category: ACA, Allianz, Sinarmas	f	t	Sinarmas | Allianz | ACA	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	ACA, Allianz, Sinarmas
5fa75550-a1b2-4f5a-9fda-138487eca286	5288642d-13e8-45b3-8f77-bcbff82a42c5	44		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			trade_in	Confidential	Sales	Trade In	Captures information about whether a customer is trading in an existing vehicle when making a purchase, which helps to accurately record sales and revenue in the Sales domain. This value is used by business stakeholders to make informed decisions about pricing, inventory management, and customer satisfaction, as well as to generate accurate financial reports.	ai_generated	Boolean (Yes / No)	f	f	Yes | No	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	No, Yes
718467c4-e19f-4545-9b4a-84eb9e0909c8	5288642d-13e8-45b3-8f77-bcbff82a42c5	45		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			delivery_date	Confidential	Sales	Delivery Date	Captures the date on which a vehicle was delivered to a customer within the sales process, specifically in the context of tracking inventory movements and managing supply chain logistics. It is used by business stakeholders to analyze sales trends, identify seasonal fluctuations, and inform strategic decisions regarding new product releases or promotions. This value may be absent if there has been no delivery made for an individual vehicle sale, which can occur when a customer cancels their order or the vehicle is not yet available in stock.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	t	2025-05-10T00:00:00 | 2025-07-20T00:00:00 | 2025-06-08T00:00:00 | 2026-03-20T00:00:00 | 2026-01-21T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	\N
ca5972cd-71e1-41fd-ad2f-0d1a27cdae9a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	14		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Service_Type	Confidential	\N	Service Type	Captures information about the type of service provided to customers, which is a critical aspect of customer service in the repair industry. It helps organizations make informed decisions about resource allocation and service level agreements by providing insight into the specific services being offered.	ai_generated	Category: Inspection, Maintenance, Repair, Warranty	f	f	Repair | Maintenance | Inspection | Warranty	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Inspection, Maintenance, Repair, Warranty
cd00e679-cf93-456c-a942-4dbbbe98d1da	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	26		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Billing_Notes	Confidential	\N	Billing Notes	Captures and records sensitive information regarding payment status or any other relevant details that may impact an invoice's overall value in a specific business area. It is used to inform business decisions, such as credit limits, discounts, or future billing cycles, by providing context on why certain invoices have been paid or not.	ai_generated	Free text	f	f	Paid on time | Delayed payment | Invoice under review | Discount applied	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Delayed payment, Discount applied, Invoice under review, Paid on time
9fd9c285-48c1-42c1-8cec-addfec5fee17	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	18		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Payment_Method	Confidential	\N	Payment Method	Captures information about how a customer pays for goods or services, specifically identifying the method used to complete the transaction in our customer service area. It is used by business analysts and financial managers to track payment trends and make informed decisions about pricing strategies and revenue recognition policies.	ai_generated	Category: Cash, Credit, Transfer	f	f	Transfer | Credit | Cash	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Cash, Credit, Transfer
b6edd389-0b24-4062-a04a-da18495e97b8	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	15		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Service_Notes	Confidential	\N	Service Notes	Captures and records instances where a customer requires additional support or clarification regarding their service experience, providing valuable insights into areas for improvement within our business operations. This information is utilized by internal teams to inform strategic decisions and reporting, enabling data-driven actions that enhance overall customer satisfaction and loyalty.	ai_generated	Free text	f	f	Follow-up required | Customer reported issue | Urgent repair needed | Routine check	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Customer reported issue, Follow-up required, Routine check, Urgent repair needed
ba0b8148-8dba-41e5-9d6e-af83975892c6	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	25		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Billing_Status	Confidential	\N	Billing Status	Captures information about the current status of an invoice's processing within the accounts payable department, which indicates whether it has been received, processed, or is still pending payment review. This value is used to inform decision-making regarding follow-up actions and reporting on outstanding invoices in order to ensure timely payments are made.	ai_generated	Category: Paid, Pending, Unpaid	f	f	Pending | Paid | Unpaid	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Paid, Pending, Unpaid
016a2dba-2f59-4fe8-8bf5-fe93a0b64187	5288642d-13e8-45b3-8f77-bcbff82a42c5	48		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			stock_id	Confidential	Stock	Stock Identifier	Captures a unique and confidential identifier for every stock item in the inventory, which is used to track its movement within the organization's supply chain and ensure accurate reporting on stock levels and availability. This value is crucial in making informed business decisions regarding stock replenishment, ordering, and distribution, as it uniquely identifies each record and allows for efficient tracking of stock movements across different locations.	ai_generated	ID / Code (e.g. STK00001)	t	f	STK00001 | STK00002 | STK00003 | STK00004 | STK00005	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
d7e7cb6f-7497-4977-9064-adda39aaedd9	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	22		PRJ018_Inventory_Billing.xlsx - Sheet1	\N	Source	Enterprise Data Integration Platform Implementation	2026			Item_Description	Confidential	\N	Item Description	Captures and records a critical piece of information about an item's characteristics that is essential to understanding its value in our inventory management process, particularly within the context of billing and pricing for goods sold by our company. Is used as a key component in determining product costs, identifying specific items on invoices, and providing valuable insights into customer purchasing behavior when analyzing sales data.	ai_generated	Free text	f	f	Oil Filter | Brake Pad | Engine Oil | Battery	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Battery, Brake Pad, Engine Oil, Oil Filter
56297f56-318f-4fca-ae85-c277cac142cf	5288642d-13e8-45b3-8f77-bcbff82a42c5	47		car_sales_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			payment_status	Confidential	Sales	Payment Status	Captures and records real-world facts about a customer's payment status within the sales domain to ensure accurate tracking of outstanding payments. It informs business decisions regarding follow-up actions, credit approvals, or other financial matters that impact revenue growth and customer relationships.	ai_generated	Category: Installment, Paid, Pending	f	f	Pending | Paid | Installment	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1800	\N	Installment, Paid, Pending
551c28f7-588d-49e9-9207-f204ddac864f	5288642d-13e8-45b3-8f77-bcbff82a42c5	50		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			warehouse_location	Confidential	Stock	Warehouse Location	Captures information about specific locations within warehouses where stock is stored, providing a critical detail for inventory management and tracking in the Stock domain. This data is used by business stakeholders to make informed decisions about storage capacity allocation, shipping routes, and product availability across various warehouse locations.	ai_generated	Category: Balikpapan, Bandung, Bontang, Jakarta, Samarinda, Surabaya	f	f	Jakarta | Surabaya | Balikpapan | Samarinda | Bandung	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Balikpapan, Bandung, Bontang, Jakarta, Samarinda, Surabaya
e7d3ebbe-cdff-44c1-b2d0-e3786868d2f9	5288642d-13e8-45b3-8f77-bcbff82a42c5	49		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			dealer_name	Highly Confidential	Stock	Dealer Name	Captures and records real-world information about a specific business entity within the stock domain, providing valuable insights into the identity of the dealer responsible for managing inventory levels. This sensitive data informs strategic decisions related to supplier partnerships, customer relationships, and overall market performance, while also being handled in accordance with our organization's personal identifiable information policy.	ai_generated	Free text	f	f	Borneo Cars | Nusantara Motor | Mega Auto | Auto Prima	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Auto Prima, Borneo Cars, Mega Auto, Nusantara Motor
0c9fa8f5-f3df-42a6-90d2-3331c88166ee	ad670b81-df3b-4fc0-898c-b64b3098a186	18	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Customer_Segment	Confidential	Master Customer	Customer Segment	Captures information about a customer's loyalty status within the retail and automotive ecosystem. It is used to inform business decisions regarding marketing campaigns, promotions, and rewards programs, as well as to track customer behavior across different segments. It indicates that customers are categorized into three distinct groups: Occasional, Premium, and Regular, with each category signifying a specific level of loyalty and purchasing frequency. The value Occasional signifies customers who make occasional purchases, the value Premium signifies frequent buyers, and the value Regular signifies consistent shoppers. This data may be absent for new or inactive customers, as their loyalty status is unknown at the time of entry into the system. However, it is not a requirement to have this information present in order to conduct business operations.	ai_generated	Category: Occasional, Premium, Regular	f	t	Regular | Occasional | Premium	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Occasional, Premium, Regular
03142113-df49-406b-bb04-1a9f86ad450b	ad670b81-df3b-4fc0-898c-b64b3098a186	19	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Join_Date	Confidential	Master Customer	Join Date	Captures and records the date a customer joined the retail and automotive ecosystem, which is a critical milestone in understanding their purchasing history and loyalty to the business. It is used by analysts to identify trends in new customer acquisition and inform strategies for retaining existing customers. This value uniquely identifies each record, but may be absent if a customer has never made a purchase or engaged with the business, indicating they are not yet part of the ecosystem.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2023-01-01T00:00:00 | 2023-01-02T00:00:00 | 2023-01-03T00:00:00 | 2023-01-04T00:00:00 | 2023-01-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
27bc2c97-4faf-40d7-a9fc-d72b93f9f151	ad670b81-df3b-4fc0-898c-b64b3098a186	20	Astra International – Digital Transformation Division	PRJ004_Customer_Master.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Status	Confidential	Master Customer	Status	Captures a customer's status in relation to their active participation in retail and automotive ecosystem activities, which can impact sales, marketing, and loyalty programs. It is used by business stakeholders to make informed decisions about customer engagement and retention, as well as to generate reports on customer activity levels. The value indicates that the customer is actively engaged with our services, meaning they have made a purchase or are registered for rewards, but may be inactive if they haven't interacted in some time. It also signifies that the customer has been marked as inactive, which can affect their eligibility for certain promotions and offers. This status reflects whether the customer's account is active or inactive, with "Active" meaning they have a valid relationship with our company and are eligible for rewards and benefits, while "Inactive" means they no.	ai_generated	Category: Active, Inactive	f	t	Active | Inactive	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Active, Inactive
fe4f5513-631c-4321-b6c5-a694cfc3f44d	ad670b81-df3b-4fc0-898c-b64b3098a186	23	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Device_Type	Confidential	Digital Behaviour	Device Type	Captures and records information about a customer's device type in relation to their digital behavior within the Retail & Automotive Ecosystem, specifically within the Digital Behaviour domain. It is used by business stakeholders to inform product recommendations, marketing campaigns, and sales strategies. The Device Type field indicates that a customer uses a Desktop for work purposes, a Mobile for personal use, or a Tablet for entertainment activities. These categories help retailers and automotive companies tailor their services to individual customers' needs. This value may be absent when a customer's device type is unknown or unrecorded, which can occur if they do not have an active account with the company or if their device information has not been updated recently.	ai_generated	Category: Desktop, Mobile, Tablet	f	t	Tablet | Desktop | Mobile	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Desktop, Mobile, Tablet
bb207d02-7ad9-4913-8dd7-11809e513b09	ad670b81-df3b-4fc0-898c-b64b3098a186	21	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Session_ID	Confidential	Digital Behaviour	Session Identifier	Captures and records a unique identifier for individual digital behavior sessions within the Retail & Automotive Ecosystem, specifically in the Digital Behaviour domain. This value is used to track customer interactions across multiple touchpoints, informing business decisions on loyalty programs, targeted marketing campaigns, and sales performance analysis.	ai_generated	ID / Code (e.g. SES3000)	t	t	SES3000 | SES3001 | SES3002 | SES3003 | SES3004	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
bdf44476-032f-4593-93a7-33b44903c1f1	ad670b81-df3b-4fc0-898c-b64b3098a186	24	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Browser	Confidential	Digital Behaviour	Browser	Captures and records digital behavior in relation to how users interact with websites within the Retail & Automotive Ecosystem, specifically focusing on browser usage patterns that fall under the Digital Behaviour domain. This data is used by business stakeholders to inform decisions regarding marketing strategies, customer engagement initiatives, and product development based on user preferences and browsing habits. The values recorded for this digital behavior are: Chrome represents users who primarily use Google's Chrome web browser, Edge signifies users who predominantly utilize Microsoft's Edge browser, while Safari denotes users who mainly surf the internet using Apple's Safari browser. This data may be absent when a user does not have a supported browser installed on their device or when browsing is not enabled.	ai_generated	Category: Chrome, Edge, Safari	f	t	Chrome | Edge | Safari	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Chrome, Edge, Safari
13011644-8fdc-417f-90b1-4b0491fe0400	ad670b81-df3b-4fc0-898c-b64b3098a186	25	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Page_Views	Confidential	Digital Behaviour	Page Views	Captures and records instances where a customer interacts with digital content on behalf of an organization in the retail and automotive ecosystem, specifically within the realm of digital behavior. This data is used by business stakeholders to inform decisions related to marketing campaigns, product optimization, and customer engagement strategies. The absence of this value may occur when a customer does not interact with digital content at all, such as during periods of technical maintenance or when an account has been inactive for an extended period.	ai_generated	Integer (whole number)	f	t	2 | 30 | 12 | 1 | 25	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
4a20f2c5-9019-4e11-a267-e9a2abd6e87d	ad670b81-df3b-4fc0-898c-b64b3098a186	26	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Click_Count	Confidential	Digital Behaviour	Click Count	Captures and records a count of individual interactions with digital content within the Retail & Automotive Ecosystem, specifically in relation to customer behavior and preferences. It informs business decisions regarding marketing strategies, product placement, and customer engagement initiatives by providing insights into user activity levels. This data is typically not present for historical or archived interactions where no further analysis can be conducted.	ai_generated	Integer (whole number)	f	t	59 | 42 | 49 | 77 | 58	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
efaae415-3e99-4902-b308-3b159236d666	ad670b81-df3b-4fc0-898c-b64b3098a186	27	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Session_Date	Confidential	Digital Behaviour	Session Date	Captures and records a specific date and time at which digital behavior occurs within the retail and automotive ecosystem, providing a unique identifier for each instance of customer interaction with our services. It is used to inform business decisions regarding customer loyalty programs, marketing campaigns, and sales performance analysis.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	t	2026-01-01T00:00:00 | 2026-01-02T00:00:00 | 2026-01-03T00:00:00 | 2026-01-04T00:00:00 | 2026-01-05T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
cec266c3-c7da-4f93-aee0-31d8f3b5e76b	ad670b81-df3b-4fc0-898c-b64b3098a186	28	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Location	Confidential	Digital Behaviour	Location	Captures and records geographical locations relevant to digital behavior in the retail and automotive ecosystem, specifically within the domain of digital behavior. It is used by business stakeholders to inform location-based decisions and reporting, such as identifying customer demographics or analyzing sales trends across different regions. The values recorded include Bandung, Jakarta, Surabaya, each representing a distinct city with its own characteristics and market conditions - for instance, Bandung is known for its outdoor activities and shopping centers, while Jakarta is the country's capital and largest city. Surabaya is a major port city and industrial hub. This value may be absent when no location information is available or relevant to the specific business context.	ai_generated	Category: Bandung, Jakarta, Surabaya	f	t	Surabaya | Jakarta | Bandung	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Bandung, Jakarta, Surabaya
acbccdb5-81b7-474a-bd90-d5067e06f3c8	ad670b81-df3b-4fc0-898c-b64b3098a186	29	Astra International – Digital Transformation Division	PRJ004_Digital_Behavior.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Referral	Confidential	Digital Behaviour	Referral	Captures and records instances where a customer is directed to another website or platform for further information about a product, anchored in the Retail & Automotive Ecosystem within the Digital Behaviour domain. This data informs business decisions related to marketing campaigns and customer engagement strategies, as well as reporting on customer behavior across different channels. The value indicates that the referral came from social media ads, organic search engine results, or another online platform, meaning the customer was exposed to a product through these channels before being directed elsewhere. Ads refer to referrals generated from paid advertisements, Organic refers to referrals resulting from natural search engine results without any advertising involvement, and Social refers to referrals originating from social media platforms.	ai_generated	Category: Ads, Organic, Social	f	t	Social | Ads | Organic	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Ads, Organic, Social
6234ae04-e651-4bb5-b004-d5fc6188d655	ad670b81-df3b-4fc0-898c-b64b3098a186	34	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Category	Confidential	Transaction	Category	Captures and records a fact about transaction types within the retail and automotive ecosystem domain, specifically distinguishing between service-related transactions, spare part sales, and vehicle purchases. It is used in business decisions to categorize transactions for inventory management, pricing strategies, and customer segmentation purposes. The category value indicates that a transaction is related to a service provided by a retailer or dealership, such as maintenance work or repairs, or the sale of spare parts like tires or batteries. It also signifies the purchase of a vehicle from a seller in this ecosystem. This field may be absent for transactions classified under other categories, such as returns or exchanges, where the primary focus is on resolving customer issues rather than categorizing transaction types.	ai_generated	Category: Service, Sparepart, Vehicle	f	t	Service | Vehicle | Sparepart	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Service, Sparepart, Vehicle
9bfe3183-97fd-4725-b7b0-e42f52252055	ad670b81-df3b-4fc0-898c-b64b3098a186	36	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Payment_Method	Confidential	Transaction	Payment Method	Captures information about how a transaction was settled in cash, credit, or another method. It is used to inform business decisions and reporting related to retail sales and customer payment preferences, including categorizing transactions as secure, convenient, or costly. The values of this field indicate whether the transaction involved Cash (a one-time payment), Credit (an installment plan), or Transfer (electronic funds transfer). When a Payment Method value is absent, it may be because the transaction was not completed due to technical issues or customer declined the offer;.	ai_generated	Category: Cash, Credit, Transfer	f	t	Transfer | Credit | Cash	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Cash, Credit, Transfer
495f2380-0a0e-4f90-aaf3-93d5f153aefe	ad670b81-df3b-4fc0-898c-b64b3098a186	38	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Dealer_Code	Confidential	Transaction	Dealer Code	Captures information about a dealer's classification within the retail and automotive ecosystem, specifically in relation to transactional activities that fall under category DLR01, DLR02, or DLR03. It is used by business stakeholders to make informed decisions regarding customer relationships and sales performance, as well as for reporting purposes to track overall industry trends and market share. Each possible value - such as DLR01, indicating a specific type of dealer classification - signifies a particular category that influences how customers are treated or what products they can purchase. Similarly, values like DLR02 signify another distinct category, while DLR03 represents yet another classification type. This field may be absent when no transactional activity falls under the specified categories, which could occur if a customer does not engage in any retail or automotive-related transactions.	ai_generated	Category: DLR01, DLR02, DLR03	f	t	DLR01 | DLR03 | DLR02	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	DLR01, DLR02, DLR03
b81ced8f-cd9d-4b3c-93ce-b226d918fcb9	ad670b81-df3b-4fc0-898c-b64b3098a186	39	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Channel	Confidential	Transaction	Channel	Captures information about the channel through which a transaction was conducted in the retail and automotive ecosystem, specifically within the domain of transactions. It is used to inform business decisions regarding customer behavior and sales strategies, as well as for reporting purposes such as tracking online versus offline sales channels. The value indicates that an online sale occurred when the category is set to Online, meaning the purchase took place on a website or through other digital means. In contrast, when the category is Offline, it signifies that the transaction happened in-store or through another physical channel. This data may be absent for transactions where no channel information was recorded or reported.	ai_generated	Category: Offline, Online	f	t	Online | Offline	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Offline, Online
e7ad35d8-3535-4b0c-b738-c431cbd95aaf	ad670b81-df3b-4fc0-898c-b64b3098a186	35	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Amount	Confidential	Transaction	Amount	Captures and records a unique, confidential identifier for individual transactions within the retail and automotive ecosystem domain, specifically in the transaction category. It is used to track and measure financial amounts associated with these transactions in business decisions and reporting, uniquely identifying each record and serving as a primary key. This value may be absent when a transaction has not been completed or recorded, but its presence ensures that every transaction can be accurately accounted for and analyzed within the retail and automotive ecosystem domain.	ai_generated	Integer (whole number)	t	t	4251741 | 9080672 | 3512140 | 1069723 | 8257989	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	\N
f66413bb-7a68-402d-845e-e4d36565837b	ad670b81-df3b-4fc0-898c-b64b3098a186	40	Astra International – Digital Transformation Division	PRJ004_Transactions.xlsx - Sheet1	Retail & Automotive Ecosystem	Source	Customer 360 Analytics and Personalization Platform	2026		Rina Maharani Putri <rina.putri@astra-group.co.id>	Notes	Confidential	Transaction	Notes	Captures information about transactional notes that reflect a specific category within the retail and automotive ecosystem, specifically indicating whether a discount is applied, normal pricing applies, a promotional offer is in effect, or an urgent matter requires attention. This data informs business decisions by providing context for customer interactions and sales reporting, allowing retailers to track the effectiveness of promotions and identify areas for improvement. The values recorded here correspond to distinct scenarios: when a discount is given, it signifies that a reduction has been applied to the transaction price. Normal pricing means no adjustments have been made. Promotional offers are used to incentivize purchases during specific periods or events. Urgent matters require immediate attention due to time-sensitive issues such as product recalls. This data may be absent in cases where transactions do not involve notes, which could occur when sales are.	ai_generated	Free text	f	t	Promo | Urgent | Discount | Normal	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-20 08:03:34.671409+00	70	2026	Discount, Normal, Promo, Urgent
83738de8-5fdb-4843-8849-98e32316032c	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	6		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Risk_Score	Confidential	Service Prediction	Risk Score	Captures a measure of uncertainty associated with service prediction outcomes within the AI analytics domain. Used to inform business decisions regarding risk tolerance and resource allocation in various operational contexts, such as project planning and execution.	ai_generated	Decimal number	f	f	0.4 | 0.7 | 0.18 | 0.41 | 0.87	FLOAT	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
43a56de0-b5ff-4494-b528-d90782daa8b4	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	9		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Recommendation	Confidential	Service Prediction	Recommendation	Captures real-world customer interactions within the Service Prediction domain that indicate a need for personalized recommendations to enhance customer experience and satisfaction. Is used by business analysts and decision-makers to inform product development, marketing strategies, and customer engagement initiatives.	ai_generated	Category: Contact customer, Inspect vehicle, No action, Schedule maintenance	f	f	Contact customer | Inspect vehicle | Schedule maintenance | No action	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	Contact customer, Inspect vehicle, No action, Schedule maintenance
319e299b-3248-4493-9ea1-f170ab51fdde	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	16		PRJ018_Customer_Service.xlsx - CS	\N	Source	Enterprise Data Integration Platform Implementation	2026			Service_Date	Confidential	\N	Service Date	Captures and records a specific date when services are provided to customers in the customer service domain. It is used by business stakeholders to track customer interactions over time, informing decisions on service level agreements and performance metrics.	ai_generated	Date (YYYY-MM-DD)	t	f	2026-01-01 | 2026-01-02 | 2026-01-03 | 2026-01-04 | 2026-01-05	DATE	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
7ceb248d-4d3e-49e6-b6b1-10a4f6049130	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	2		PRJ018_AI_Analytics.xlsx - AI	\N	Source	Enterprise Data Integration Platform Implementation	2026			Customer_ID	Confidential	Service Prediction	Customer Identifier	Captures a unique and confidential identifier for individual customers within the Service Prediction domain, which is used to track customer interactions and predict future service needs in order to inform business decisions and reporting on customer behavior and preferences. This identifier is critical in ensuring data accuracy and consistency across various business processes, including sales forecasting, marketing campaigns, and customer segmentation analysis.	ai_generated	ID / Code (e.g. CUST1057)	f	f	CUST1057 | CUST1043 | CUST1016 | CUST1037 | CUST1006	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-19 03:31:42.216868+00	60	\N	\N
3798c116-65c6-43c0-9e89-10408734927e	5288642d-13e8-45b3-8f77-bcbff82a42c5	52		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			model	Confidential	Stock	Model	Captures real-world information about a specific type of vehicle that is part of the stock inventory in the automotive domain. It provides critical details for tracking and managing the supply of vehicles to meet customer demand, informing business decisions related to production planning, inventory management, and sales forecasting.	ai_generated	Category: Baleno, Brio, C200, CR-V, Creta, Ertiga, Fortuner, Innova, Jimny, X3, ...	f	f	Fortuner | Jimny | Creta | Baleno | Ertiga	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	320i, 520i, Air EV, Almaz, Alvez, Avanza, Baleno, Brio, C200, CR-V, City, Confero, Creta, E300, Ertiga, Fortuner, GLA, GLE, HR-V, Innova
1757cbe8-5f34-4eab-b4a1-f2463e07cc05	5288642d-13e8-45b3-8f77-bcbff82a42c5	55		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			engine_number	Confidential	Stock	Engine Number	Captures a unique identifier for vehicles within the stock domain, specifically related to engine specifications and confidential in nature. This value is used by business stakeholders to track inventory levels, manage supply chains, and make informed decisions about vehicle maintenance and replacement, ensuring accurate reporting and compliance with regulatory requirements.	ai_generated	ID / Code (e.g. ENG80549)	t	f	ENG80549 | ENG70269 | ENG66342 | ENG49947 | ENG70957	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
8a8059a2-defa-4ca3-ba7d-a2c098338c37	5288642d-13e8-45b3-8f77-bcbff82a42c5	53		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vehicle_year	Confidential	Stock	Vehicle Year	Captures and records the year a vehicle was manufactured or acquired within the stock domain to support inventory management decisions related to ordering, stocking, and disposal of vehicles in various business operations and financial reporting periods. Indicates the age and model year of vehicles for pricing, warranty, and insurance purposes, as well as for regulatory compliance and fleet maintenance planning.	ai_generated	Integer (whole number)	f	f	2026 | 2025 | 2021 | 2024 | 2020	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	2020, 2021, 2022, 2023, 2024, 2025, 2026
68f70010-85ca-4389-961d-2d5cada2e819	5288642d-13e8-45b3-8f77-bcbff82a42c5	51		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			brand	Confidential	Stock	Brand	Captures real-world information about a specific automobile manufacturer that is relevant to stock management within the automotive industry domain. Indicates its importance in business decisions by providing valuable insights into brand loyalty, market share, and product offerings when used to analyze sales data and customer preferences.	ai_generated	Category: BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling	f	f	Toyota | Suzuki | Hyundai | Honda | Mercedes-Benz	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling
de406088-07c7-45ec-b32c-e557210a7d8e	5288642d-13e8-45b3-8f77-bcbff82a42c5	54		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			vin_number	Confidential	Stock	Vin Number	Captures and records a unique identifier for every vehicle in stock within the automotive domain, specifically within the context of inventory management for dealerships and retailers. It is used to track ownership history, verify authenticity, and ensure compliance with regulatory requirements such as emissions testing and safety standards.	ai_generated	Free text	t	f	Giu34348697388 | JNh85839683294 | ndz22156073655 | kFz92807482846 | NVS88510737848	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
1b68473d-bf2c-4a36-8e80-67cf6c17685f	5288642d-13e8-45b3-8f77-bcbff82a42c5	56		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			color	Confidential	Stock	Color	Captures real-world facts about a vehicle's visual appearance within the stock domain and specifically in relation to its color, which is an important aspect for identifying and tracking inventory levels across various product lines. This information is used by business stakeholders to make informed decisions regarding product pricing, marketing strategies, and supply chain management, ultimately influencing overall revenue and profitability.	ai_generated	Category: Black, Blue, Gray, Red, Silver, White	f	f	Silver | Blue | White | Gray | Black	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Black, Blue, Gray, Red, Silver, White
2f7bdf3d-689c-4332-a3ef-c7004f200aaf	5288642d-13e8-45b3-8f77-bcbff82a42c5	57		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			fuel_type	Confidential	Stock	Fuel Type	Captures information about the type of fuel used to power vehicles within the stock domain. It is used by business stakeholders to make informed decisions regarding inventory management, supply chain logistics, and customer preferences in order to optimize operations and ensure compliance with regulatory requirements.	ai_generated	Category: Diesel, Electric, Gasoline, Hybrid	f	f	Diesel | Gasoline | Hybrid | Electric	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Diesel, Electric, Gasoline, Hybrid
f3ab3f4f-0293-4cf7-b724-b62ed9459e2d	5288642d-13e8-45b3-8f77-bcbff82a42c5	62		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			days_in_stock	Confidential	Stock	Days In Stock	Captures the number of days that a product has been available for sale without being sold or removed from stock in the retail industry within the Stock domain. Indicates the level of inventory turnover and helps retailers manage their supply chain, informing decisions on ordering quantities and restocking schedules.	ai_generated	Integer (whole number)	f	f	47 | 195 | 286 | 30 | 168	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
e1adaac0-6454-495b-bace-c74b95533b49	5288642d-13e8-45b3-8f77-bcbff82a42c5	63		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			stock_age_category	Confidential	Stock	Stock Age Category	Captures real-world fact that indicates a product's age and movement within the inventory, anchored to the retail store domain and stock area. Reflects on business decisions by categorizing slow-moving products as such, influencing restocking strategies and supply chain optimization efforts.	ai_generated	Category: Fast Moving, Normal, Slow Moving	f	f	Slow Moving | Fast Moving | Normal	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Fast Moving, Normal, Slow Moving
f2b21e2b-dc08-4d44-9f83-053903711725	5288642d-13e8-45b3-8f77-bcbff82a42c5	64		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			inspection_status	Confidential	Stock	Inspection Status	Captures and records a real-world fact that indicates whether a vehicle is currently being held in stock pending inspection or repair, anchored to the automotive industry and its focus on maintaining safe and reliable vehicles for public use. It informs business decisions regarding inventory management, allocation of resources, and customer communication about the status of their vehicles.	ai_generated	Category: Passed, Pending	f	f	Pending | Passed	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Passed, Pending
c61f955f-76e7-45ba-9f2b-fe243a8205a8	5288642d-13e8-45b3-8f77-bcbff82a42c5	65		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			parking_zone	Confidential	Stock	Parking Zone	Captures real-world information about designated areas within a parking facility where vehicles are allowed to park, anchored in the stock domain and related to inventory management. This data is used by business stakeholders to make informed decisions regarding vehicle allocation, track occupancy rates, and measure the effectiveness of parking zone configurations.	ai_generated	Category: Zone-1, Zone-10, Zone-2, Zone-3, Zone-4, Zone-5, Zone-6, Zone-7, Zone-8, Zone-9	f	f	Zone-2 | Zone-4 | Zone-3 | Zone-1 | Zone-5	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	Zone-1, Zone-10, Zone-2, Zone-3, Zone-4, Zone-5, Zone-6, Zone-7, Zone-8, Zone-9
87b1c3fd-2dc1-4b24-8e6d-ea756332b57c	5288642d-13e8-45b3-8f77-bcbff82a42c5	66		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			last_maintenance_date	Confidential	Stock	Last Maintenance Date	Captures the date of the most recent maintenance performed on vehicles in stock, which is a critical aspect of ensuring their safety and reliability within the automotive industry. This data informs business decisions related to vehicle inventory management, pricing strategies, and customer service standards, helping organizations maintain high levels of quality control and customer satisfaction.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	t	2024-05-28T00:00:00 | 2024-08-08T00:00:00 | 2024-12-12T00:00:00 | 2025-11-05T00:00:00 | 2025-12-04T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
a0631a04-4426-4b34-9f1b-c781de4c0fea	5288642d-13e8-45b3-8f77-bcbff82a42c5	67		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			assigned_salesperson	Confidential	Stock	Assigned Salesperson	Captures information about the assigned salesperson in the stock domain, providing a unique identifier for each record and reflecting their role in managing inventory levels. It is used to inform business decisions regarding sales performance, customer satisfaction, and overall revenue growth. This sensitive data may be absent when an employee has been temporarily reassigned or no longer works with the company, but its presence uniquely identifies each record and supports accurate reporting and analysis across various departments.	ai_generated	Free text	t	t	Chelsea Pratama | drg. Jagapati Puspasari, S.E. | Pangeran Maheswara | Jarwa Hassanah, S.IP | dr. Agus Irawan, S.Pt	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
1c6d3a2c-56e3-4f21-bcce-297897d8c644	5288642d-13e8-45b3-8f77-bcbff82a42c5	89		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			customer_segment	Confidential	Customer	Customer Segment	Captures and records a specific classification used to categorize customers based on their loyalty and purchasing behavior within the customer domain. It is utilized by business stakeholders to inform targeted marketing campaigns, rewards programs, and sales strategies that cater to each segment's unique characteristics and preferences.	ai_generated	Category: Corporate, Retail, VIP	f	f	VIP | Retail | Corporate	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	Corporate, Retail, VIP
99baf50f-fb2b-4fce-9eb0-34773292467f	5288642d-13e8-45b3-8f77-bcbff82a42c5	60		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			purchase_cost	Confidential	Stock	Purchase Cost	Captures and records the actual cost at which a vehicle is purchased by an organization within the stock domain, providing a critical piece of information for financial analysis and inventory management. It serves as a key component in determining profit margins, calculating depreciation costs, and making informed decisions about purchasing new or used vehicles.	ai_generated	Integer (whole number)	t	f	598922243 | 463936459 | 445282155 | 645086023 | 384306993	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
da91a17a-1a61-430f-85f8-96420e6b92f5	5288642d-13e8-45b3-8f77-bcbff82a42c5	69		car_stock_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			gps_tracking_id	Confidential	Stock	Gps Tracking Identifier	Captures a unique identifier for tracking and managing stock levels across various locations within the inventory management process, anchored to the domain of stock operations. This value is used in business decisions by providing a distinct reference point for tracking and reporting on stock movements, enabling organizations to monitor and optimize their inventory more effectively.	ai_generated	Free text	t	f	fda7cfe5-9997-4ff1-88a6-a5ba994b31c2 | 5eea73b5-8a33-45d7-a215-d89b4bd67d9e | 4918fb86-246d-4735-b16b-23326c918b84 | 8b081985-65ac-48bc-95f5-752fa19cdc53 | 906cc7f8-c757-492f-9495-b5d75593d585	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1200	\N	\N
e59bdaba-c0a8-4fe7-9972-4a779650b1ce	5288642d-13e8-45b3-8f77-bcbff82a42c5	71		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			first_name	Highly Confidential	Customer	First Name	Captures and records a customer's personal name as part of their overall profile, which is highly confidential due to its sensitive nature. This information is used in business decisions such as account management and customer engagement, while also being subject to our organization's data privacy policy.	ai_generated	Free text	f	f	Amanda | Salimah | Gaiman | Christopher | Wira	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
391802a3-64c2-4d01-902c-0efaec399b29	5288642d-13e8-45b3-8f77-bcbff82a42c5	72		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			last_name	Highly Confidential	Customer	Last Name	Captures highly confidential personal information that identifies a customer's family lineage within our organization. It plays a crucial role in shaping business decisions and reporting, as it provides a unique identifier for each individual customer, enabling us to tailor services and offers accordingly while ensuring compliance with our data privacy policy.	ai_generated	Free text	f	f	Cruz | Powell | Kuswandari | Lane | Irawan	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
44edf039-bb55-44ef-945c-18ce365c490a	5288642d-13e8-45b3-8f77-bcbff82a42c5	73		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			full_name	Highly Confidential	Customer	Full Name	Captures and records a unique, full name of every customer in the domain, which is essential for identifying individuals within the organization. Indicates their identity as part of business processes and reporting, while being handled with utmost care due to its highly confidential nature and being personally identifiable information that falls under our data privacy policy.	ai_generated	Free text	t	f	Amanda Cruz | Salimah Powell | Gaiman Kuswandari | Christopher Lane | Wira Irawan	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
3b4b913c-f123-49c0-acc1-cfd98ff84dba	5288642d-13e8-45b3-8f77-bcbff82a42c5	74		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			gender	Highly Confidential	Customer	Gender	Captures and records a fact about an individual's biological characteristics that are relevant to their identity within the customer domain, specifically related to gender. It influences business decisions regarding product offerings, marketing strategies, and compliance with regulatory requirements, while also being subject to strict handling under our organization's data privacy policy due to its sensitive nature.	ai_generated	Category: Female, Male	f	f	Female | Male	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	Female, Male
863af9c7-f035-4edc-984c-33a8129042be	5288642d-13e8-45b3-8f77-bcbff82a42c5	75		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			date_of_birth	Confidential	Customer	Date Of Birth	Captures a customer's age and life stage information at birth, providing context to their demographic characteristics within the Customer domain. It is used in business decisions and reporting to determine eligibility for certain services or products, as well as to calculate age-related benefits and privileges.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	t	f	1970-12-18T00:00:00 | 1985-10-04T00:00:00 | 1986-06-08T00:00:00 | 1991-04-07T00:00:00 | 2001-03-22T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
0d1e7656-46a5-40e8-aaa0-81c250b23b3c	5288642d-13e8-45b3-8f77-bcbff82a42c5	77		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			email	Highly Confidential	Customer	Email	Captures and records a unique identifier for individual customers within the customer domain, specifically an email address used to communicate with them. Indicates how it is utilized in business decisions and reporting by providing a primary means of contact and facilitating targeted marketing efforts while being handled under our data privacy policy.	ai_generated	Email (name@domain.com)	t	t	sanchezlisa@gmail.com | lurhur45@pd.my.id | elon50@hotmail.com | emily03@hotmail.com | jperry@baldwin-perez.com	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
23621014-ce87-49b7-8c42-2e976861c26b	5288642d-13e8-45b3-8f77-bcbff82a42c5	78		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			national_id	Confidential	Customer	National Identifier	Captures a unique and confidential identifier for individual customers within the customer domain, which is used to track and identify each customer's identity across all interactions with the organization. This sensitive information is crucial in making informed business decisions, such as offering targeted marketing campaigns or providing personalized services.	ai_generated	Integer (whole number)	t	f	3104054678340300 | 8560225016963805 | 2650688233701707 | 3875353611832923 | 4088648816480203	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
bfdc069d-81b3-4c1d-a748-7c89ae882f18	5288642d-13e8-45b3-8f77-bcbff82a42c5	76		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			phone_number	Highly Confidential	Customer	Phone Number	Captures and records a unique identifier for individual customers within the customer domain, specifically tied to their personal contact information. Used in business decisions such as account management, marketing campaigns, and customer service interactions to track and identify specific individuals, with highly confidential data handled under our data privacy policy.	ai_generated	Phone number	t	t	798.035.1886x82894 | +62 (043) 748-1535 | 697.293.1083x720 | +62 (141) 095 5631 | (858)808-4666	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
64cec6b4-ea7b-478f-bb6e-f73ea20251d3	5288642d-13e8-45b3-8f77-bcbff82a42c5	80		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			address	Highly Confidential	Customer	Address	Captures and records highly confidential information about a customer's physical location, which is used to facilitate secure delivery of goods or services and inform targeted marketing efforts. It plays a critical role in business decisions by enabling organizations to tailor their offerings and interactions with customers based on their specific addresses. This data is handled under our company's personal identifiable information policy and uniquely identifies each record due to its unique combination of characters, making it an essential component of customer profiles.	ai_generated	Free text (long description)	t	f	Jalan Dipenogoro No. 83, Cimahi, Sulawesi Tenggara 04087 | Gang Veteran No. 538, Salatiga, NB 14822 | 6081 Shane Extensions Suite 687, Caseystad, CA 87261 | Gg. KH Amin Jasuta No. 29, Lubuklinggau, Jawa Tengah 92959 | Gang M.H Thamrin No. 946, Palembang, SU 50425	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
6d4c4bd5-3516-4860-9459-ae12cfd7261a	5288642d-13e8-45b3-8f77-bcbff82a42c5	81		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			city	Confidential	Customer	City	Captures information about a customer's location within the Customer domain. It is used to identify specific cities where customers reside and inform targeted marketing efforts or regional sales strategies.	ai_generated	Category: Balikpapan, Bandung, Bontang, Jakarta, Samarinda, Surabaya	f	f	Jakarta | Surabaya | Balikpapan | Samarinda | Bandung	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	Balikpapan, Bandung, Bontang, Jakarta, Samarinda, Surabaya
de52632f-68f2-4b27-b77f-b8f97432bf34	5288642d-13e8-45b3-8f77-bcbff82a42c5	83		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			postal_code	Confidential	Customer	Postal Code	Captures a unique geographic identifier used to identify specific locations within a customer's address, which is essential for ensuring accurate and efficient mail delivery services in our business area. It plays a critical role in informing business decisions related to customer segmentation, marketing campaigns, and data analytics reporting.	ai_generated	Integer (whole number)	t	f	44048 | 63787 | 29188 | 66690 | 43999	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
ed57c81f-ff48-42e1-bdda-ae06fc2512c7	5288642d-13e8-45b3-8f77-bcbff82a42c5	84		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			occupation	Confidential	Customer	Occupation	Captures information about a customer's profession within the Customer domain, providing insight into their role and responsibilities in building control and surveying. This occupation data is used to inform business decisions related to customer segmentation, marketing strategies, and compliance with regulatory requirements.	ai_generated	Free text	f	f	Surveyor, building control | Producer, television/film/video | Chemist, analytical | Agricultural consultant | Engineer, broadcasting (operations)	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
ee096d5e-969a-4ca2-ba92-ecc75480019b	5288642d-13e8-45b3-8f77-bcbff82a42c5	85		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			company_name	Highly Confidential	Customer	Company Name	Captures and records a unique identifier for individual customers within the customer domain, which is essential to distinguish between different individuals in the business area. It plays a crucial role in making informed decisions regarding customer relationships, loyalty programs, marketing campaigns, and sales tracking. This sensitive information is handled under our data privacy policy due to its personally identifiable nature, and it uniquely identifies each record, while being absent when customers are deleted or have not yet been registered.	ai_generated	Free text	t	t	Sampson Ltd | Sullivan-Khan | PD Fujiati | PT Wasita Nugroho (Persero) Tbk | UD Handayani	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
fb869d37-e5bc-476a-903e-4ced1ced2540	5288642d-13e8-45b3-8f77-bcbff82a42c5	87		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			marital_status	Confidential	Customer	Marital Status	Captures and records real-world facts about a customer's personal life within the context of their relationship status with others in the domain of Customer Data. Indicates how this information is used to inform business decisions regarding customer segmentation, marketing campaigns, and compliance with regulatory requirements.	ai_generated	Category: Married, Single	f	f	Single | Married	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	Married, Single
f9a8ac94-3d30-41d6-9003-01a23c742ba7	5288642d-13e8-45b3-8f77-bcbff82a42c5	88		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			preferred_brand	Confidential	Customer	Preferred Brand	Captures information about a customer's preferred brand, which is an important aspect of their loyalty and purchasing behavior within the automotive industry domain. It influences how customers interact with dealerships and service providers, ultimately affecting sales performance and customer satisfaction metrics.	ai_generated	Category: BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling	f	f	Mitsubishi | Hyundai | Suzuki | Honda | Mercedes-Benz	STRING	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	BMW, Honda, Hyundai, Mercedes-Benz, Mitsubishi, Suzuki, Toyota, Wuling
854abd13-d3a9-4b8b-a59e-b18c439ce73e	5288642d-13e8-45b3-8f77-bcbff82a42c5	86		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			monthly_income	Highly Confidential	Customer	Monthly Income	Captures a customer's monthly income, which represents their total earnings over the past month within our organization and is used to determine eligibility for certain benefits and rewards. It plays a crucial role in business decisions regarding customer loyalty programs and financial incentives. This data is handled under our company's data privacy policy due to its personally identifiable nature, may be absent if a customer has not received their monthly payment or if the record is incomplete, uniquely identifies each customer record, and is classified as highly confidential.	ai_generated	Integer (whole number)	t	t	20613608 | 29090698 | 47660060 | 11100827 | 5217789	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
72f3ac35-a233-4b64-aaf7-7d53bba3a216	5288642d-13e8-45b3-8f77-bcbff82a42c5	90		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			registration_date	Confidential	Customer	Registration Date	Captures the date on which a customer's registration is finalized and recorded as part of their overall account information within the customer domain. It informs business decisions related to customer onboarding, loyalty programs, and compliance with regulatory requirements by providing a specific point in time for tracking customer activity.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	f	2025-11-16T00:00:00 | 2025-02-08T00:00:00 | 2024-08-13T00:00:00 | 2026-03-13T00:00:00 | 2025-06-12T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
1e78fbcd-9c13-4163-90e6-c8f6988957b6	5288642d-13e8-45b3-8f77-bcbff82a42c5	91		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			last_purchase_date	Confidential	Customer	Last Purchase Date	Captures the date of a customer's most recent purchase in order to track their purchasing history and identify trends within our business area, specifically related to customer loyalty and sales patterns. This data is used by sales teams to measure customer engagement and inform targeted marketing campaigns, while also being reported on by management to analyze overall revenue growth and customer retention rates. It may be absent if a customer has never made a purchase or if their most recent purchase date is unknown.	ai_generated	Datetime (YYYY-MM-DD HH:MM:SS)	f	t	2025-01-08T00:00:00 | 2026-02-02T00:00:00 | 2025-03-25T00:00:00 | 2025-01-18T00:00:00 | 2024-11-30T00:00:00	DATETIME	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
d1e41187-357b-414a-9eef-05741dfd5086	5288642d-13e8-45b3-8f77-bcbff82a42c5	93		customer_data.xlsx - Sheet1	\N	Source	AI-Powered Customer Analytics Platform	2026			credit_score	Confidential	Customer	Credit Score	Captures and records a customer's creditworthiness within the financial services domain. Indicates an individual's likelihood of meeting their debt obligations in order to inform lending decisions, risk assessments, and other business operations that rely on this critical assessment.	ai_generated	Integer (whole number)	f	f	801 | 540 | 636 | 755 | 532	INTEGER	Raw	2026-05-25	Super Administrator <admin@governance.local>	-	excel	2026-05-18 09:20:40.027151+00	1500	\N	\N
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
dec34d1d-5903-473d-922f-45344de78831	5288642d-13e8-45b3-8f77-bcbff82a42c5	excel	car_demand_data.xlsx	/app/uploads/5288642d-13e8-45b3-8f77-bcbff82a42c5/b51a4b8172734b3abe116c93cc094229_car_demand_data.xlsx	256308	2026-05-25 07:56:17.132458+00	Super Administrator <admin@governance.local>
d6596fab-dd43-4452-a4b5-0c48a1c61e43	5288642d-13e8-45b3-8f77-bcbff82a42c5	excel	car_sales_data.xlsx	/app/uploads/5288642d-13e8-45b3-8f77-bcbff82a42c5/69fde5cbc68840908d8bff66de3b9e86_car_sales_data.xlsx	307247	2026-05-25 07:56:17.13305+00	Super Administrator <admin@governance.local>
8c4016ce-ef1b-4b1f-8478-825252b0e33e	5288642d-13e8-45b3-8f77-bcbff82a42c5	excel	car_stock_data.xlsx	/app/uploads/5288642d-13e8-45b3-8f77-bcbff82a42c5/66f4b3c54df44ef99f8f8c4130e567e2_car_stock_data.xlsx	220734	2026-05-25 07:56:17.133912+00	Super Administrator <admin@governance.local>
5b9d1e65-e74f-440f-a2a2-6473959ed2b5	5288642d-13e8-45b3-8f77-bcbff82a42c5	excel	customer_data.xlsx	/app/uploads/5288642d-13e8-45b3-8f77-bcbff82a42c5/c0f956e4694647b78fddf59b3ed880f7_customer_data.xlsx	370813	2026-05-25 07:56:17.134833+00	Super Administrator <admin@governance.local>
06e90a8d-33ca-4b11-aaf4-586330f33f29	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	excel	PRJ002_Credit_Profile.xlsx	/app/uploads/40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19/61e5a346a9614ebf9914cadff9c2eb4d_PRJ002_Credit_Profile.xlsx	12603	2026-05-25 07:57:18.056073+00	Super Administrator <admin@governance.local>
c13efa46-9401-4b5b-85e9-a592b7cdd5ac	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	excel	PRJ002_Loan_Transactions.xlsx	/app/uploads/40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19/437a7963c39a46bd9784721802c6900c_PRJ002_Loan_Transactions.xlsx	12562	2026-05-25 07:57:18.056331+00	Super Administrator <admin@governance.local>
2e169655-a55b-4ea1-ace9-928f752808c4	40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	excel	PRJ002_Risk_Scoring.xlsx	/app/uploads/40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19/d4888a390de842f6812698ea3fa8c5e4_PRJ002_Risk_Scoring.xlsx	12563	2026-05-25 07:57:18.05685+00	Super Administrator <admin@governance.local>
e9f5528b-5876-431d-aead-1e1c0b671b6f	85eaf07b-2298-4658-baaa-a5e267c74812	excel	PRJ003_Data_Governance.xlsx	/app/uploads/85eaf07b-2298-4658-baaa-a5e267c74812/10365909a0e84ec28b28ac185d8352b0_PRJ003_Data_Governance.xlsx	12017	2026-05-25 07:57:59.958552+00	Super Administrator <admin@governance.local>
3595e144-ea94-42a5-980d-c2cf0a0d3fdd	85eaf07b-2298-4658-baaa-a5e267c74812	excel	PRJ003_Data_Quality.xlsx	/app/uploads/85eaf07b-2298-4658-baaa-a5e267c74812/51bfc1f05530423e8ad4c2a822533be8_PRJ003_Data_Quality.xlsx	11987	2026-05-25 07:57:59.958863+00	Super Administrator <admin@governance.local>
73833c8d-eacb-47b7-9653-5ab8c264979f	85eaf07b-2298-4658-baaa-a5e267c74812	excel	PRJ003_Metadata_Catalog.xlsx	/app/uploads/85eaf07b-2298-4658-baaa-a5e267c74812/ce7a37e941e9478b9cc54426c4d509eb_PRJ003_Metadata_Catalog.xlsx	12001	2026-05-25 07:57:59.959055+00	Super Administrator <admin@governance.local>
3913e55d-5414-476a-ae6b-b803f78d21b8	ad670b81-df3b-4fc0-898c-b64b3098a186	excel	PRJ004_AI_Scoring.xlsx	/app/uploads/ad670b81-df3b-4fc0-898c-b64b3098a186/03a8670f6cff4e9ea045a44dd9db9cb7_PRJ004_AI_Scoring.xlsx	12987	2026-05-25 07:58:46.300928+00	Super Administrator <admin@governance.local>
e07b383e-1cf4-4da7-822a-42ccd8495e7b	ad670b81-df3b-4fc0-898c-b64b3098a186	excel	PRJ004_Customer_Master.xlsx	/app/uploads/ad670b81-df3b-4fc0-898c-b64b3098a186/b065147c5f014fd58af01acd9a4e2b9d_PRJ004_Customer_Master.xlsx	13666	2026-05-25 07:58:46.301277+00	Super Administrator <admin@governance.local>
97fe1528-009d-4949-bcdd-0c5ecec32ec0	ad670b81-df3b-4fc0-898c-b64b3098a186	excel	PRJ004_Digital_Behavior.xlsx	/app/uploads/ad670b81-df3b-4fc0-898c-b64b3098a186/f7a2cb1cff4c4e07b08489d9793fe8e7_PRJ004_Digital_Behavior.xlsx	13084	2026-05-25 07:58:46.301504+00	Super Administrator <admin@governance.local>
692046f5-d8c8-4d09-87e0-2d954e3d2685	ad670b81-df3b-4fc0-898c-b64b3098a186	excel	PRJ004_Transactions.xlsx	/app/uploads/ad670b81-df3b-4fc0-898c-b64b3098a186/6a160598ffc44eb8ad0995c3aefaf763_PRJ004_Transactions.xlsx	13146	2026-05-25 07:58:46.303359+00	Super Administrator <admin@governance.local>
31670fd9-b58f-457f-9f1f-be7068e2805a	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	excel	PRJ018_AI_Analytics.xlsx	/app/uploads/0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7/3d88f012ed6c42b49fbe97a30da52ac1_PRJ018_AI_Analytics.xlsx	13011	2026-05-25 07:59:22.448449+00	Super Administrator <admin@governance.local>
6e36b54c-ed12-4994-b393-72f0ac224df9	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	excel	PRJ018_Customer_Service.xlsx	/app/uploads/0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7/a5ca0df01a284cc287520ce99ef6f71c_PRJ018_Customer_Service.xlsx	13435	2026-05-25 07:59:22.448619+00	Super Administrator <admin@governance.local>
babf427f-d86f-40c7-8294-421515a290ec	0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	excel	PRJ018_Inventory_Billing.xlsx	/app/uploads/0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7/5a51943089014e5cbd0483f83a156553_PRJ018_Inventory_Billing.xlsx	13134	2026-05-25 07:59:22.448716+00	Super Administrator <admin@governance.local>
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.projects (id, project_name, created_by, created_at, updated_at, customer_name, line_of_business, use_case, project_year, project_category, is_monetized, delivery_manager_id, project_manager_id, dgo_id, metadata_officer_id, dq_officer_id, pic_data_compliance_id, start_date, end_date, project_code, sme_id) FROM stdin;
5288642d-13e8-45b3-8f77-bcbff82a42c5	AI-Powered Customer Analytics Platform	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-01-05 09:00:00+00	2026-05-05 08:48:11.221111+00	PT Maju Bersama Digital	Digital Banking	Leverage generative AI to analyze customer transaction patterns and generate personalized financial insights.	2026	AI / Machine Learning	t	13c686f6-db44-4585-b9f1-6c6200aac025	9af488f8-db30-4b90-a672-c1ec50f45c85	c8cf883c-330c-46c0-b023-3629c2f99a69	c8cf883c-330c-46c0-b023-3629c2f99a69	c8cf883c-330c-46c0-b023-3629c2f99a69	1b6e6cdf-4700-4914-81cf-29f7e768c523	2026-01-15	2026-12-31	PRJ-2026-001	4aa61e37-f659-44ae-810b-41d4ac793b26
40eaa9f8-8584-426e-b9ab-fc5fc2c9cd19	Smart Credit Risk Analytics Platform	13c686f6-db44-4585-b9f1-6c6200aac025	2026-03-01 01:00:00+00	2026-03-01 01:00:00+00	PT Finansial Nusantara	Financial Services	Develop an AI-powered credit risk scoring model leveraging customer financial behaviour, transaction history, and external credit bureau data to improve loan approval accuracy and reduce default rates across retail banking portfolios.	2026	AI / Machine Learning	t	13c686f6-db44-4585-b9f1-6c6200aac025	9af488f8-db30-4b90-a672-c1ec50f45c85	c8cf883c-330c-46c0-b023-3629c2f99a69	facd7d45-6237-46a9-8015-507fe266c7ff	19d275fc-8c44-4411-a412-92a85834759b	1b6e6cdf-4700-4914-81cf-29f7e768c523	2026-03-01	2026-12-31	PRJ-2026-002	4aa61e37-f659-44ae-810b-41d4ac793b26
85eaf07b-2298-4658-baaa-a5e267c74812	Enterprise Data Governance Implementation	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-13 02:54:35.239403+00	2026-05-13 06:10:42.310928+00	PT ABC Tbk	Banking	Implementation of an enterprise data governance framework to improve data consistency, ownership, metadata management, and regulatory compliance across business domains. The project includes data cataloging, business glossary standardization, data quality monitoring, and governance workflow enablement to support reliable and trusted enterprise data usage.	2026	Data Governance	t	13c686f6-db44-4585-b9f1-6c6200aac025	c8cf883c-330c-46c0-b023-3629c2f99a69	9af488f8-db30-4b90-a672-c1ec50f45c85	1b6e6cdf-4700-4914-81cf-29f7e768c523	facd7d45-6237-46a9-8015-507fe266c7ff	19d275fc-8c44-4411-a412-92a85834759b	2026-05-01	2026-10-31	PRJ-2026-003	3991d4dd-deb4-432c-9a8a-edee818513b0
0f5c16e1-aa7d-430a-97ff-34d9bb57b5b7	Enterprise Data Integration Platform Implementation	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-19 03:17:28.948382+00	2026-05-19 03:17:28.948382+00	Astra UD Trucks	Automotive Distribution & After Sales	Implementation of enterprise data integration solution to consolidate operational data from Dealer Management System (DMS), after sales, inventory, billing, and customer service applications into centralized reporting and analytics platforms. The project includes ETL pipeline development, API integration, data mapping standardization, and automated data synchronization processes.	2026	Integration	t	89efb71c-c9f1-4224-8fa5-ae4b5e211402	13c686f6-db44-4585-b9f1-6c6200aac025	8216e50c-c627-469d-a696-1e91285f5aab	4908c50c-2a1d-4ab5-8a1c-68965e49ba47	4908c50c-2a1d-4ab5-8a1c-68965e49ba47	336b5420-9af0-49de-b844-e42ee6658cd4	2026-03-03	2026-10-28	PRJ-2026-018	4a1a48b4-55b2-4ed4-84a8-ae84851e870d
ad670b81-df3b-4fc0-898c-b64b3098a186	Customer 360 Analytics and Personalization Platform	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-20 07:44:22.733017+00	2026-05-20 07:44:22.733017+00	Astra International – Digital Transformation Division	Retail & Automotive Ecosystem	Develop a Customer 360 platform that integrates data from multiple sources, including sales, after-sales, and customer interaction systems, into a unified analytics environment. The solution leverages AI/ML models to generate insights such as customer segmentation, behavior prediction, and personalized recommendations to support business decision-making. All data processing is conducted within a secure and governed environment, with appropriate controls such as pseudonymization, access restriction, and compliance with applicable data protection regulations.	2026	AI / ML	t	89efb71c-c9f1-4224-8fa5-ae4b5e211402	13c686f6-db44-4585-b9f1-6c6200aac025	8216e50c-c627-469d-a696-1e91285f5aab	8216e50c-c627-469d-a696-1e91285f5aab	8216e50c-c627-469d-a696-1e91285f5aab	f961edea-0a7a-4f6c-8738-098f640b6dc8	2026-02-15	2026-11-30	PRJ-2026-004	4a1a48b4-55b2-4ed4-84a8-ae84851e870d
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
6696a78a-0441-47e3-8b36-80f37cfbeb00	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	1	\N	3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	2026-05-05 08:46:10.075526+00	\N
fb8d3c79-165a-417d-8eea-fa7219b5be5e	13c686f6-db44-4585-b9f1-6c6200aac025	11	\N	13c686f6-db44-4585-b9f1-6c6200aac025	2026-05-05 08:48:08.476676+00	\N
7b139f60-6d5d-42ac-a3fb-3a70e220becd	9af488f8-db30-4b90-a672-c1ec50f45c85	11	\N	9af488f8-db30-4b90-a672-c1ec50f45c85	2026-05-05 08:48:08.476676+00	\N
1bc73912-ab3e-4424-881b-1159ef9df508	c8cf883c-330c-46c0-b023-3629c2f99a69	11	\N	c8cf883c-330c-46c0-b023-3629c2f99a69	2026-05-05 08:48:08.476676+00	\N
fc301f14-da6c-45f4-b3da-417ae495853f	1b6e6cdf-4700-4914-81cf-29f7e768c523	11	\N	1b6e6cdf-4700-4914-81cf-29f7e768c523	2026-05-05 08:48:08.476676+00	\N
f3a72615-1b95-4644-815f-9194b8d4b6e6	4aa61e37-f659-44ae-810b-41d4ac793b26	11	\N	4aa61e37-f659-44ae-810b-41d4ac793b26	2026-05-05 08:48:08.476676+00	\N
a891a6c5-94f0-46aa-94b6-24be7b9558ca	facd7d45-6237-46a9-8015-507fe266c7ff	11	\N	facd7d45-6237-46a9-8015-507fe266c7ff	2026-05-05 08:48:08.476676+00	\N
31f0bfa2-bfb2-4125-9b65-4017f784f0a5	19d275fc-8c44-4411-a412-92a85834759b	11	\N	19d275fc-8c44-4411-a412-92a85834759b	2026-05-05 08:48:08.476676+00	\N
1d0fda9a-8f09-45bf-8a5f-61b2d5a45a4f	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	8	\N	bf6b981a-dccb-4e6c-a4a8-6f6f14810158	2026-05-06 09:22:09.012469+00	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, full_name, email, password_hash, is_active, last_login_at, created_at, updated_at, "position") FROM stdin;
13c686f6-db44-4585-b9f1-6c6200aac025	Ahmad Fauzi	ahmad.fauzi@company.com	$2b$12$PdcEha/.RuB64oqkiZBS1uIKQ/w4Bhb8IWaGslBrMMMsufp1n.Wuq	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Senior Delivery Manager
9af488f8-db30-4b90-a672-c1ec50f45c85	Bagas Adi Nugraha	bagas.nugraha@company.com	$2b$12$CJb1TMsBSY5ygQ7uJoiV/ukipMkzzDBFcF0cSr19mIQZMAM1n1lLy	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Project Manager
c8cf883c-330c-46c0-b023-3629c2f99a69	Anisa Putri	anisa.putri@company.com	$2b$12$mEo0QE8VEJBoGYUJrXsrBuc/eidOUFM4yNBgVkiw9nQiooGxH4pwu	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Data Governance Officer
1b6e6cdf-4700-4914-81cf-29f7e768c523	Budi Santoso	budi.santoso@company.com	$2b$12$Mp5Uj/hQhZgDkii6xtAP1ec/sg5yZgN3XIEnPJDzVCeFfz8Gd5lxy	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Data Compliance Officer
4aa61e37-f659-44ae-810b-41d4ac793b26	Dewi Rahayu	dewi.rahayu@company.com	$2b$12$MCE2.iFFgufAqpNq6IwXY.s.8VDFTli3Kvkmg3nqn4hCsOgy5y19a	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Senior Data Scientist
facd7d45-6237-46a9-8015-507fe266c7ff	Eko Prasetyo	eko.prasetyo@company.com	$2b$12$bqyJCHgopUbi1uL1Ta9bQO5KqIXq2OBt2FrYibT47roV3kGDOPZIS	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	Data Analyst
19d275fc-8c44-4411-a412-92a85834759b	Fitri Handayani	fitri.handayani@company.com	$2b$12$7G4YNjOnyBCZRAtNGfOW9eo8mC/Z09uyrSrt8aPoclZfSbdduKA4i	t	\N	2026-05-05 08:48:08.476676+00	2026-05-06 06:18:57.679988+00	AI Engineer
bf6b981a-dccb-4e6c-a4a8-6f6f14810158	Read-Only Viewer	viewer@governance.local	$2b$12$uaP.CIaweJlps8IY2ORu9uniu3nDwT.nh1H8NMytALDPPnTbXkbvS	t	2026-05-18 10:37:10.540445+00	2026-05-06 09:22:08.697769+00	2026-05-18 10:37:10.091099+00	\N
4a1a48b4-55b2-4ed4-84a8-ae84851e870d	Adi Kurniawan	adi.kurniawan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
89efb71c-c9f1-4224-8fa5-ae4b5e211402	Agus Setiawan	agus.setiawan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
10f026d1-d2cf-42ec-9633-fb4318091d4e	Andi Firmansyah	andi.firmansyah@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Business Analyst
336b5420-9af0-49de-b844-e42ee6658cd4	Anton Hidayat	anton.hidayat@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
f6e6e704-35cf-4871-8660-76e1c7e72db0	Arief Wibowo	arief.wibowo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	DevOps Engineer
042635a8-8fac-4563-bb78-075923bfa77d	Arif Nugroho	arif.nugroho@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
a63329f0-c28e-42a9-9b13-12d65a57e833	Bambang Susanto	bambang.susanto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Manager
13b88b78-edb8-4b1d-8372-5dc6b7a15b11	Benny Hartono	benny.hartono@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Solutions Architect
e2346f61-50ac-4e1c-9fa3-e16f04a5e02d	Cahyo Prabowo	cahyo.prabowo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Backend Developer
cb8ec3d2-13ba-41bc-9c06-bac73ad0d7b8	Dani Wahyudi	dani.wahyudi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
463b5372-d8c6-46e4-aa3b-914cba184690	David Santoso	david.santoso@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Analyst
2cacb21f-e706-4e2e-a3f5-bdf6bf1ded6b	Dedi Prasetyo	dedi.prasetyo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	System Analyst
2e80132d-2b00-4104-9749-4934f53fba60	Denny Saputra	denny.saputra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Cloud Engineer
2859d82c-7977-41c0-b7e5-2da886af7909	Dimas Ramadhan	dimas.ramadhan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
48196223-c5dc-4c82-977b-c6abc08d53c4	Fajar Maulana	fajar.maulana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
37a43514-01da-4df3-9f44-7d692b20d339	Fandi Kurnia	fandi.kurnia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
441c3beb-b472-4e37-9edf-d651da770a6e	Febri Andriyanto	febri.andriyanto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Full Stack Developer
d76096ca-cf59-431b-9076-b9fc3ce95c95	Galih Permana	galih.permana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Database Administrator
3fe0f76c-826f-4238-8160-cfee350895fc	Gunawan Hidayatullah	gunawan.hidayatullah@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Software Engineer
5ec9e918-23e6-4eb7-b0e3-3e453622b856	Hadi Subagyo	hadi.subagyo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
9c094644-5cc9-4952-aac1-80be16d2cc46	Hendra Wijaya	hendra.wijaya@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
562c949a-f7e3-4fbb-8d50-7b10f386d74e	Herman Sanjaya	herman.sanjaya@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
7607b230-55dd-48fa-bd0d-03960a5e7250	Ibnu Hakim	ibnu.hakim@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
301e9dc9-73ef-4e50-b6d0-8fca770fef76	Imam Wahyono	imam.wahyono@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Scrum Master
925384f7-bb76-4dd9-93c1-823ef148e838	Iwan Setiadi	iwan.setiadi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Business Analyst
f94e2983-99d5-4879-a520-ad62faa82198	Joko Widiantoro	joko.widiantoro@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
f3c9750c-47aa-4bed-ad70-326737a3afc9	Kevin Prasetya	kevin.prasetya@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Frontend Developer
5f05b270-9b96-457c-bd23-414fed422291	Luthfi Hamdani	luthfi.hamdani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Scientist
d34ad4b6-337b-4cdf-8ce6-ad68b7533fe5	Mahendra Kusuma	mahendra.kusuma@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
6b59690f-a62c-4058-9a66-6beec35bce54	Muhammad Rizky	muhammad.rizky@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
4872c2fd-8bc9-4c2d-b9c4-5992034e2a51	Nanang Supriyadi	nanang.supriyadi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
9d6fc91a-9eca-43af-9cb3-9eb19a8f94b9	Pandu Wiradinata	pandu.wiradinata@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Project Manager
609734f6-e61b-49b5-ba0a-762ffc74e888	Panji Adiputra	panji.adiputra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Cloud Engineer
9609a999-7ed1-4da9-9645-f5b06ee75da9	Rahmat Hidayat	rahmat.hidayat@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
89070005-c639-454e-af9a-363b4202c4a4	Raka Pratama	raka.pratama@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
bab14ece-9415-4478-a4bb-c325608383c8	Randi Firmanto	randi.firmanto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Backend Developer
c99a9b0f-d1b5-4503-9267-f1017162dc9e	Rangga Satria	rangga.satria@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	DevOps Engineer
417e9063-d72e-453f-bc85-27edd13f61e5	Rendi Cahyono	rendi.cahyono@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	System Analyst
6512895c-8f98-4d86-951e-6554ecaa0e85	Reza Fauzan	reza.fauzan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
1f6142dc-92fa-4cb0-9ac6-72a5409ef7d6	Rifki Maulana	rifki.maulana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
8fabecc4-b214-498f-86d3-5b926900e20f	Rio Harianto	rio.harianto@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
ac008bf5-98c0-4741-9b81-7353925746a8	Ryan Budiman	ryan.budiman@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Full Stack Developer
c6b7640c-349d-4fbe-b93b-26521c1c42b3	Satria Nugroho	satria.nugroho@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Solutions Architect
d53a7b87-eaa2-41f0-a5c7-a5a9d92755b9	Sigit Prayogo	sigit.prayogo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Business Analyst
4931a6d0-7393-4d3d-acd4-ae2b18df4864	Sugeng Raharjo	sugeng.raharjo@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Database Administrator
d1048068-41d7-4213-b13b-35f0a0323ca7	Surya Kusuma	surya.kusuma@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Manager
5495b01c-6a7a-4619-914b-303a9f2ff697	Teguh Santoso	teguh.santoso@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
2b1cd54f-a428-4928-9915-2c1e86a86231	Tommy Wirabuana	tommy.wirabuana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
f05ac9a6-dc01-4d18-86a6-0f9ecefe3941	Umar Hakim	umar.hakim@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
f6c56d4a-1ef2-4b97-a4db-b16259714474	Wahyu Setiawan	wahyu.setiawan@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
18eb3622-e93f-422c-8155-f02c0a214967	Wisnu Wardhana	wisnu.wardhana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Software Engineer
02bdf23f-e01f-4d69-a5e6-2963dd89df0a	Yogi Pratama	yogi.pratama@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
0eda815a-c10e-4fa5-b75a-768352e18064	Yudi Santosa	yudi.santosa@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Scrum Master
a0f414a7-f936-43b0-8d2d-8b14cf8b6071	Yusuf Rachman	yusuf.rachman@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Frontend Developer
8216e50c-c627-469d-a696-1e91285f5aab	Aini Rahmawati	aini.rahmawati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
f961edea-0a7a-4f6c-8738-098f640b6dc8	Amalia Putri	amalia.putri@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Business Analyst
4908c50c-2a1d-4ab5-8a1c-68965e49ba47	Anastasia Dewi	anastasia.dewi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Analyst
279d171e-6fc9-47d3-9b5d-ff3dede08449	Aulia Rahma	aulia.rahma@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
f1f87ebb-9e9f-4929-b265-098512c610a0	Ayu Lestari	ayu.lestari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
e461c5b1-3f56-4153-88a1-fc07305f5b87	Bunga Pertiwi	bunga.pertiwi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
3991d4dd-deb4-432c-9a8a-edee818513b0	Citra Nirmala	citra.nirmala@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
8919db87-2434-4b6a-aca1-fbf32224213b	Desi Wulandari	desi.wulandari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
4c6b0862-80a3-471a-b21f-57091048947f	Diah Ayu Ningrum	diah.ayu@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
0e3fac0f-ae09-4689-be27-2dbededaf7b6	Diana Puspita	diana.puspita@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Business Analyst
8b0f7afb-3d25-4958-828d-484d926556f2	Dina Marliana	dina.marliana@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
0eca99fb-0477-4935-8df1-9ac77a65d563	Endah Sulistyowati	endah.sulistyowati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
5f80c115-cd37-422d-b663-5bfcd357d412	Eva Kristina	eva.kristina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
84c8a7ed-63bd-415b-9c61-7c7686ae40dc	Fani Oktavia	fani.oktavia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
7cd86197-3a72-435a-b2ac-e65713f706ed	Fatimah Zahra	fatimah.zahra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
e31ff406-bc4e-40b6-9250-92bcf756f221	Febby Anggraini	febby.anggraini@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
017b69ab-0eee-4554-8c7a-1d697acdb108	Hani Setyaningsih	hani.setyaningsih@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
612f3887-fdb0-4ead-ab7a-a3763e819805	Indah Permatasari	indah.permatasari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Business Analyst
ce2fd09d-7bda-454b-a641-7afda6c5b26e	Intan Novitasari	intan.novitasari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
0c043732-ea2e-47ff-90bd-c62142dbfa4c	Ira Sukmawati	ira.sukmawati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Scientist
6f1b0aaf-14dc-4926-93b8-34c840d8d771	Kartika Sari	kartika.sari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Project Manager
344ec3c7-ca7f-4ee8-bd31-a232ef8e6067	Laila Nurhayati	laila.nurhayati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	System Analyst
77ab4b32-e99f-4c1e-8eac-6780b78dd8ee	Lestari Handayani	lestari.handayani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
4e462c43-67d8-40ed-8bf2-6567c91e41e8	Lina Marlina	lina.marlina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Frontend Developer
d071e644-bb72-4c8e-b865-f9d3f242baa6	Maya Sofianti	maya.sofianti@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Software Engineer
ea97fc15-3df1-40f1-8fdc-9f988258f758	Mega Wulandari	mega.wulandari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Scrum Master
cabba18e-0fb7-4e08-896b-4276de5adda5	Mila Agustina	mila.agustina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Analyst
996ed30f-fddd-43c1-96b0-7c8268f8f2a7	Nabila Azzahra	nabila.azzahra@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
07b98940-163b-49ea-9a24-1a69e3402753	Nadia Rahmatika	nadia.rahmatika@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Manager
335e6de9-d833-473d-83b3-58a215696a04	Novi Andriani	novi.andriani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Backend Developer
64293f5d-016d-407c-97e4-cee7a48ba6bf	Nurul Hidayah	nurul.hidayah@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
8ed54171-e2d6-4d71-9fbe-d868635d64ea	Putri Rahayu	putri.rahayu@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Cloud Engineer
f0650df1-497c-4d94-88d6-ae9706ce896d	Ratna Dewi	ratna.dewi@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Solutions Architect
159c4b87-5a6f-44c0-9c7c-8159afd5108f	Reni Oktaviani	reni.oktaviani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Full Stack Developer
e3c51290-ec9d-45c7-aefe-b2178b37a06d	Rina Puspitasari	rina.puspitasari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Risk Analyst
bf8ba960-3066-4a05-846a-004110358d88	Risma Nurul Aini	risma.nurul@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	QA Engineer
f7edfb0a-8745-4ab2-8843-5292b3052d1c	Sari Wahyuningsih	sari.wahyuningsih@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Database Administrator
e47b0cdc-40fd-4ad5-a3fe-af7bc9dbf13d	Sella Oktaviani	sella.oktaviani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	IT Consultant
9d2e8330-3aa8-47e9-bdec-c2d7037774a1	Shinta Kusumawati	shinta.kusumawati@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Project Manager
cdf78a74-fa36-4103-a8dc-d37c320ff257	Sri Wahyuni	sri.wahyuni@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Engineer
bc64cc07-876f-4574-b7db-5438d6d00af1	Suci Ramadhani	suci.ramadhani@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Analyst
724b68d0-b9c5-4352-88d8-dc7ba1fb084b	Syifa Aulia	syifa.aulia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Compliance Officer
2b3ca039-bf92-4473-a428-8bfc9fa4fbdd	Tania Putri	tania.putri@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Product Manager
3eec2e56-98b6-4cfa-b6df-7c73465d5f50	Umi Kalsum	umi.kalsum@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Quality Analyst
2c22201a-4024-49e2-a0fc-c3bd60e4b1da	Vina Oktavia	vina.oktavia@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	DevOps Engineer
76c1633d-8d0a-4666-a2fc-e03ace0502c1	Winda Sari	winda.sari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Scientist
21a48c56-639e-4b51-9fe3-3d5693d8b35b	Wulan Dari	wulan.dari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Software Engineer
f2f4641f-92eb-485c-8a49-15a3e5dbcf99	Yeni Marlina	yeni.marlina@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Metadata Analyst
28d57e28-6bff-4e73-88e0-4eaa77a3ce30	Yuli Astuti	yuli.astuti@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Senior Data Engineer
ef85e3ab-8c81-467a-82e4-091420d6223e	Yunita Sari	yunita.sari@company.com	$2b$12$G63eWZaFuQHhJNmA5VutW.heWhO6/NTii.wajqafDDloK6B1Vabve	t	\N	2026-05-13 06:06:13.243969+00	2026-05-13 06:06:13.243969+00	Data Governance Analyst
3b33c2dc-c2a4-4528-ac81-f6e9ad8531ef	Super Administrator	admin@governance.local	$2b$12$Cg5PXcgBW1DIO9sjiikoB.dLnM6dVs/kk9a4HOXkxVFxmx2ZyHIlW	t	2026-05-26 02:29:32.426834+00	2026-05-05 08:46:09.725028+00	2026-05-26 02:29:32.179944+00	\N
\.


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1861, true);


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

