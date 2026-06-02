# AI Governance Tools

A full-stack web platform for managing data governance, AI compliance, and regulatory workflows across projects and teams.

---

## Overview

AI Governance Tools is an internal compliance platform built to support organisations in managing their data-sharing obligations, AI/ML usage assessments, data protection impact assessments, and metadata governance — all in one place.

The platform was built across 7 development phases (85 Kanban cards) and is fully UAT-accepted for all core modules.

---

## Modules

| Module | Description |
|--------|-------------|
| **Projects** | Central project registry — create and manage data governance projects with team assignments (DGO, DM, SME, PIC); assign Data Steward and Data Owner with free-text name/email; filter by Client, Category, Year, and Monetized flag; export project summary to PDF |
| **Data Sharing Request (DSR)** | End-to-end data sharing request lifecycle with serial 4-step approval workflow and client sign-off; auto-creates an AICK and DPIA on submission; filter by DSR status and year; export to PDF |
| **AI/ML Compliance Checklist (AICK)** | GEN AI usage assessment checklist auto-created with each DSR — 3-step serial approval with sign-off; filter by checklist status (In Progress / Pending Sign-Off / Completed & Signed) and year; export to PDF |
| **Data Protection Impact Assessment (DPIA)** | Auto-created from DSR; tracks residual risk, data categories, regulatory references, and governance activities (4 sections A–D); 2-step approval workflow; filter by DPIA status and year; export to PDF |
| **Record of Processing Activities (ROPA)** | Document and track all data processing activities; filter by legal basis |
| **Data Extermination / BAPD** | Manage data disposal/extermination requests with evidence upload and approval; manage retention policies (8 built-in policy types); auto-discover datasets eligible for disposal based on retention expiry |
| **Data Quality (DQ)** | Connect to GCP BigQuery, PostgreSQL, or Supabase and run automated 4-dimension data quality checks — **Completeness** (% non-null), **Consistency** (AI-generated regex pattern + business rules via Ollama with rule-based fallback), **Uniqueness** (for fully-unique / ID-like columns), **Latency** (recency scoring for datetime columns); each column-level result stores business rules, regex pattern, AI model used, and regex version; DQ runs go through a review/approval workflow (pending → running → completed → under_review → approved/rejected); AI config loaded from Settings > AI Setup |
| **Metadata Management** | Auto-populate data dictionaries from GCP BigQuery, PostgreSQL, or Excel/CSV files; Source Tables section shows all documented tables for a project across all source types with **"Open All Tables →"** shortcut to the full attribute grid; enrich with AI-generated business definitions via configurable Ollama (local or cloud); batch-process definitions in chunks to avoid connection pool exhaustion; responsive project info strip (Data Steward/Owner, Business Users, Line of Business); auto-assess Standard Format from data values; bulk grouping assignment per table; export to Excel (25-col) or styled PDF (A3 landscape with sensitivity pills, PK/NULL colour coding, AI badges); uploaded Excel/CSV files persisted to `uploads_data` volume and tracked in `project_source_files`; 30-day post-project retention with 7-day advance warning and auto-deletion |
| **Settings** | Manage users, roles, notification preferences, and AI/LLM configuration (provider, mode, base URL, model name, API key, batch size, timeout); test connection from the settings page |
| **Audit Log** | Full audit trail of all actions across modules; filter by module, action, entity, actor, and date range |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Next.js 14 (App Router) + Tailwind CSS |
| **Backend** | FastAPI (Python) + SQLAlchemy + Alembic |
| **Database** | PostgreSQL |
| **Cache / Queue** | Redis + Celery |
| **AI / LLM** | Ollama — configurable provider (local or cloud), model name, base URL, API key, and batch size via Settings UI |
| **Infrastructure** | Docker Compose + Nginx (reverse proxy) |
| **Cloud Integrations** | GCP BigQuery, GCS, PostgreSQL/Supabase |
| **CI/CD** | GitHub Actions |

---

## Environment & Version Requirements

Current baseline: **AI Governance Tools v1.0.0**. This local environment was last validated against commit `1e2b441` on `2026-06-02`.

### Required Local Tools

| Tool | Required / Tested Version | Notes |
|------|---------------------------|-------|
| Docker Desktop | Recent version with Docker Compose v2 | Primary runtime for local development and production-style testing |
| Git | Any current Git client | Required for clone, pull, branch, commit, and push workflows |
| Browser | Chrome or Edge recommended | The UI is served through Nginx at `http://localhost` |
| Node.js | 20.x, only when running the frontend outside Docker | Docker uses `node:20-alpine`; host `node_modules` are not required for the Docker flow |
| Python | 3.11.x, only when running the backend outside Docker | Backend supports Python `>=3.11,<3.13`; Docker uses `python:3.11-slim` |
| Ollama | Local container or cloud endpoint | Local model baseline is `llama3.2:3b`; cloud mode is configured in Settings > AI Setup with base URL, API key, and model |

### Container Baseline

| Service | Version / Image |
|---------|-----------------|
| Nginx | `nginx:1.25-alpine` |
| Frontend | Next.js `14.2.4`, React `18.3.1`, Tailwind CSS `3.4.4`, running on `node:20-alpine` |
| Backend API | FastAPI `0.111.0`, SQLAlchemy `2.0.30`, Alembic `1.13.1`, Pydantic `2.7.1`, running on `python:3.11-slim` |
| Database | `postgres:15-alpine` |
| Cache / Queue | `redis:7-alpine` with Celery `5.4.0` |
| LLM | `ollama/ollama:latest`; recommended local model `llama3.2:3b` |

### Important Team Notes

- Use Docker Compose as the source-of-truth runtime unless a task specifically requires native frontend or backend execution.
- For frontend-only updates, rebuild and recreate the frontend and Nginx services:
  ```bash
  docker compose -f docker-compose.yml build frontend
  docker compose -f docker-compose.yml up -d --force-recreate frontend nginx
  ```
- For backend or schema updates, run Alembic migrations in the API container before seeding or testing:
  ```bash
  docker exec ag_api alembic upgrade head
  ```
- Do not commit `.env`, API keys, uploaded source files, coverage artifacts, Docker volumes, or generated local cache files.
- Backend tests that exercise models with PostgreSQL `JSONB` columns need a PostgreSQL-compatible test setup. SQLite-based test setup will fail on those columns.
- Production readiness and open follow-up work are tracked in `docs/open-items.md`.

---

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Nginx     │────▶│  Frontend   │     │   Ollama    │
│  (Port 80)  │     │  Next.js    │     │ (local/cloud│
└─────┬───────┘     └─────────────┘     └──────┬──────┘
      │                                         │
      ▼                                         ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Backend   │────▶│  PostgreSQL │     │   Celery    │
│   FastAPI   │     │  (Database) │     │   Worker    │
└─────┬───────┘     └─────────────┘     └─────────────┘
      │
      ▼
┌─────────────┐
│    Redis    │
│(Cache/Queue)│
└─────────────┘
```

---

## Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [Git](https://git-scm.com/)

### 1. Clone the repository

```bash
git clone https://github.com/datagovtools-dev/datagov-tools.git
cd datagov-tools
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `SECRET_KEY` — generate with `openssl rand -hex 32`
- `POSTGRES_PASSWORD` — choose a strong password
- `REDIS_PASSWORD` — choose a strong password
- `DATABASE_URL` / `DATABASE_URL_SYNC` — update with your password

### 3. Start the platform

```bash
docker compose up -d
```

This starts all services: `api`, `worker`, `frontend`, `db`, `redis`, `nginx`, `ollama`.

### 4. Pull the AI model

```bash
docker exec ag_ollama ollama pull llama3.2:3b
```

### 5. Run database migrations

```bash
docker exec ag_api alembic upgrade head
```

### 6. Seed the admin user

```bash
docker exec ag_api python -m scripts.seed_admin
```

### 7. Open the app

Navigate to **http://localhost** in your browser.

Default admin login:
- Email: `admin@governance.local`
- Password: `Admin1234!`

---

## User Roles

| Role | Access Level |
|------|-------------|
| `super_admin` | Unrestricted access — bypasses all user-identity and approval-step UI gates (DPIA approver check, DSR/AICK signature step locks, ROPA edit lock); all business rules still apply for other roles |
| `admin` | Full access including user management |
| `compliance_officer` | Full operational access (all modules: create, edit, approve) |
| `dpo` | Same as compliance_officer |
| `viewer` | Read-only across all modules; can create DSR drafts |

---

## Key Features

- **Serial approval workflows** — DSR (4 steps), AICK (3 steps), DPIA (2 steps), BAPD — each step activates only after the previous is approved
- **Automatic linked-record creation** — submitting a DSR auto-creates a paired AICK and DPIA for the same project
- **Sign-off with e-signature** — draw, drag-and-drop, or upload signature images; "Signed off" status requires both prepared and acknowledged physical signatures to be present; decision locked once signed
- **AI-generated metadata definitions** — bulk-generate business definitions for all data attributes using a configurable Ollama provider (local or cloud mode); validated llama3.2:3b Variant A prompt (verb-first, 7-rule, CRITICAL semicolon ban, categorical/PII/PK/nullable conditionals) with Variant A hyperparameters applied identically across the API endpoint and Celery worker; post-processing normalises output (newline collapse, semicolon-to-sentence conversion, trailing period); model and base URL are DB-driven (configured in Settings > AI Setup); "Generate All AI Definitions" button auto-disables when all records are already generated; batch-chunked endpoint avoids connection pool exhaustion; single-record regeneration also available
- **Standard Format auto-assessment** — on every metadata import the worker classifies each column's value format using multi-signal detection: boolean (specific label per data — Yes/No, True/False, 1/0 etc.), categorical (column-name hints + value-length + cardinality thresholds), phone (separator required to avoid false positives on numeric amounts; column-name override for digit-only phone columns), date, email, integer, decimal, ID/code, free text; all three pipelines (sync API, async Celery worker, `reapply_standard_format.py`) share identical logic; distinct values stored for all Category/Boolean columns and any column with ≤ 25 unique values as a reclassification hint
- **Multi-source metadata ingestion** — GCP BigQuery, PostgreSQL/Supabase, Excel/CSV (multi-file, multi-sheet); original filenames preserved; Source Tables section shows all documented tables across all source types with per-table "Open Grid →" and a header-level "Open All Tables →" button; uploaded Excel/CSV files are persisted to a dedicated Docker volume (`uploads_data`) and tracked in `project_source_files` for future re-runs
- **Source file retention policy** — uploaded source files (Excel/CSV) kept for 30 days after project `end_date`, then auto-deleted; 7-day advance warning notification sent to the full project team and super admins; GCP/PostgreSQL imports have no physical files — all derived metadata attributes remain permanent regardless of retention
- **Metadata attributes grid** — inline-editable grid with project info strip (Data Steward, Data Owner, Business Users, Line of Business); per-table or all-tables view via dropdown; bulk Save All stamp; bulk grouping assignment per table
- **Retention policies & eligibility detection** — BAPD manages 8 built-in retention policy types; eligible datasets (past expiry) are auto-discovered and surfaced as a warning panel
- **4-dimension AI-powered Data Quality** — Completeness (% non-null), Consistency (Ollama-generated regex + business rules per column, with rule-based fallback), Uniqueness (only for fully-unique / ID-like columns, index = 100), Latency (datetime recency scored 100/70/50/30/0 based on days since latest value); each `dq_results` row stores `business_rules`, `regex_pattern`, `ai_model`, `regex_version` — matching the DQ Template output format; AI model and URL loaded from `ai_provider_configs`; DQ runs progress through pending → running → completed → under_review → approved/rejected states
- **Styled PDF & Excel export** — Metadata PDF (A3 landscape) renders sensitivity pills, PK/NULL colour coding, AI badges, and monospace column names; Excel export inserts 7 project-level columns; all document PDFs (Project, DSR, AICK, DPIA) share a standardised header with colour-coded status and flag badges
- **Data Steward & Data Owner** — assignable per project via free-text name + email; surfaced in the Metadata Attributes info strip and all exports
- **RBAC** — role-based access control enforced on both frontend and backend; `super_admin` role bypasses all user-identity and approval-step UI gates (DPIA approver check, DSR/AICK signature step locks, ROPA edit lock) while business rules remain in effect for other roles
- **Advanced overview filters** — each module's overview has module-specific status filters and dynamic year filters; Projects additionally filters by Client, Category, and Monetized flag; ROPA filters by Legal Basis
- **Configurable AI settings** — provider, mode (local/cloud), base URL, model name, API key, batch size, and timeout configurable via the Settings UI with a live test-connection check
- **Audit trail** — all changes logged with user, timestamp, and action; filterable by module, action, entity, actor, and date range
- **Notification system** — in-app notifications for approval actions and status changes

---

## Recent Updates (2026-05-25) — Data Quality 4-Dimension Enhancement

### 4 DQ Dimensions
- Replaced the simple 3-dimension rule-based pipeline with a full **4-dimension AI-powered** pipeline matching the DQ Template output format:
  - **Completeness** — `(non_null / total) × 100`; business rule: "There should be no empty field for {col} in this table"
  - **Consistency** — Ollama generates a regex pattern + business rules per column using a structured prompt (same approach as the reference `dq_gen_ai_generator3.py`); regex is then applied to compute a match %; silently falls back to format-detection rules if Ollama is unreachable or times out
  - **Uniqueness** — only created for fully-unique columns (Total Rows == Total Unique); index = 100; business rule: "There should be no duplicated field for {col} in this table"
  - **Latency** — only for datetime columns; score: 100 (today or future), 70 (≤7 days ago), 50 (8–14 days), 30 (15–30 days), 0 (>30 days); business rule: "Latest date in {col} should not be more than 14 days ago"

### Schema Enhancement — `dq_results` (migration `e3f4a5b6c7d8`)
- Added: `business_rules` (TEXT), `regex_pattern` (TEXT), `ai_model` (VARCHAR 100), `regex_version` (VARCHAR 50), `column_category` (VARCHAR 50)
- `actual_value` stores the index score (0–100); `check_type` stores the dimension name; `details` JSONB stores `raw_text`, `total_unique`, matched count

### AI Config Integration
- DQ Celery task reads the active AI config from `ai_provider_configs` (enabled=true) to get `model_name`, `base_url`, and `timeout_seconds`; defaults to `llama3.2:3b` at `http://ollama:11434` if none found

### Frontend — Detail Page
- **Score tab**: dynamic 1–4 dimension bars per column (shows only dimensions present in the run); 2×2 or 4-column responsive grid
- **Rules tab**: dimension filter chips (All / Completeness / Consistency / Uniqueness / Latency); columns added — Business Rules, Regex Pattern, AI Model; expandable text for long values

---

## Recent Updates (2026-05-25) — Metadata Standard Format & UX

### Standard Format — Multi-Signal Categorical Detection
- **`_assess_standard_format(values, column_name)`** now accepts a column name and uses multiple signals to decide whether a column is categorical:
  - **Column-name hints**: columns containing words like `type`, `status`, `level`, `brand`, `channel`, `mode`, `priority` etc. get a relaxed threshold (n_unique ≤ 20, ratio < 12 %); columns containing `name`, `notes`, `description`, `address` etc. suppress categorical detection entirely
  - **Value-length guard**: columns where average value length > 35 chars are never classified as Category
  - **Tightened thresholds**: n_unique ≤ 15 (base) / 20 (hint), ratio < 10 % (base) / 12 % (hint), frequency ≥ 3.0 (up from 2.0) — prevents continuous numeric ranges (lead_score, Age, Quality_Score) from being misclassified
  - **Numeric guard**: columns where all unique values are numeric skip the categorical check entirely and fall through to Integer / Decimal
- Identical logic applied in all three pipelines: sync `metadata_population.py`, async `worker/tasks/metadata.py`, and `scripts/reapply_standard_format.py`
- `reapply_standard_format.py` re-parses ALL rows from persisted source files (no 100-row cap) and re-applies the latest logic; run it after any classification change to update all projects

### Standard Format — Boolean Specific Labels
- Boolean columns now return a format label matching their actual data: `Boolean (Yes / No)`, `Boolean (True / False)`, `Boolean (1 / 0)`, `Boolean (Y / N)`, `Boolean (T / F)` etc. instead of the generic `Boolean (Yes/No or True/False)`
- Positive values sorted first (Yes before No, True before False, 1 before 0)

### Standard Format — Phone Number Fix
- Phone regex now requires at least one separator character (` + - . () x`) so pure-integer price/amount columns (Sale Price, Discount Amount, Down Payment stored as large Rupiah integers) are no longer misclassified as Phone number
- Column-name override added: if `_assess_standard_format()` returns Integer / Free text / None AND the column name contains `phone`, `mobile`, `tel`, `hp`, `handphone`, `telepon`, `nohp`, or `no_hp`, the format is overridden to `Phone number` — handles phone columns that store digits without separators (Indonesian mobile: `081234567890`)

### Standard Format — Combobox UI
- **`StandardFormatCombobox`** replaces the plain textarea in the Metadata Attributes grid; groups options into: Boolean / Categorical / Date & Time / Contact / Numeric / Identifier / Text
- Clicking **Category: [type values…]** auto-fills the field with the actual `distinct_values` stored for that attribute — no manual typing needed
- Free-text entry still available for custom formats

### Table-Level Field Propagation
- Editing **Table Type**, **Data Year**, **Grouping**, or **Level** on any row in edit mode now propagates the same value to all other attributes in the same table (`data_domain_table`) simultaneously — reflects the fact that these fields describe the table, not individual columns
- Column headers show a tooltip: "Table-level — editing one row updates all columns in the same table"

### `distinct_values` — Expanded Coverage
- `_get_distinct_values()` now stores distinct values for **any column with ≤ 25 unique non-null values**, not only Category/Boolean columns — so if a user later reclassifies an Integer or Free text column to Category, the combobox can still auto-populate the values
- `distinct_values` is now included in `MetadataRecordOut` (was missing from the response schema — field was in DB but never returned to the frontend)
- **Save endpoint**: when `standard_format` is saved as `Category:…` the distinct_values is derived from the format string; when saved as `Boolean (…)` the values inside the parentheses are extracted and sorted; for all other formats the existing `distinct_values` is preserved (not cleared)

### PRJ-2026-004 Added
- Fifth project **Customer 360 Analytics and Personalization Platform** (PRJ-2026-004) added with 40 attributes across 4 tables (AI Scoring, Customer Master, Digital Behavior, Transactions)
- All 226 metadata attributes across all 5 projects have been re-processed with the latest classification logic

---

## Recent Updates (2026-05-25) — Core Platform

### Metadata — Open All Tables Shortcut
- **"Open All Tables →"** button added to the Source Tables section header; visible whenever at least one table is documented; navigates directly to the Metadata Attributes grid with all tables loaded (no table filter applied)
- Per-table **"Open Grid →"** links remain for navigating to a specific table directly

### Infrastructure — Nginx DNS Stability
- Added `resolver 127.0.0.11 valid=30s ipv6=off` to `nginx.conf`; Docker's internal DNS is now re-queried every 30 seconds so nginx automatically recovers when `api` or `worker` containers are recreated with new IPs — previously required a manual `restart nginx`

### Source File Persistence & Retention Policy
- **`project_source_files` table** (Alembic migration `d8e9f0a1b2c3`) tracks every Excel/CSV file imported per project: original filename, stored path, file size, `uploaded_at`, `uploaded_by`
- **`uploads_data` Docker named volume** mounted at `/app/uploads` on both `api` and `worker`; scoped to `/app/uploads/{project_id}/`; survives container restarts and redeployments
- **`proceed_metadata` endpoint** copies each temp file to the persistent volume after successful import and creates a `project_source_files` record; files are available for future re-runs without re-uploading
- **30-day post-project retention** — source files are automatically deleted 30 days after the project `end_date`; all system-created records (metadata attributes, definitions, DSR, DPIA, AICK, ROPA, BAPD) are **never auto-deleted**
- **7-day advance warning** — `source_file_expiry_check` Celery Beat task runs daily at 07:00 WIB; sends in-app notification and email to the full project team (DGO, DM, PM, SME, Metadata Officer, DQ Officer, PIC Data Compliance, project creator) and all super admins
- **Automatic deletion** — on expiry day: physical files removed from `uploads_data` volume, `project_source_files` records deleted, deletion-confirmed notification sent to the same recipients
- GCP BigQuery and PostgreSQL/Supabase imports have no physical files to clean up — their derived `metadata_records` stay permanently

### Metadata Import — Richer Data Capture
- **`_get_sample_data()`** now stores up to **5 distinct non-null values** pipe-separated (was 1); richer context for AI definition generation
- **`distinct_values`** now populated by the Celery `retrieve_metadata` task (was only set by the sync `metadata_population` path); categorical/boolean columns get their full unique value set stored
- **`backfill_standard_format.py`** updated to use stored `distinct_values` for categorical/boolean re-inference when available, falling back to type + single-sample regex

### AI Generation Pipeline — End-to-End Alignment
- **Celery worker `generate_ai_definition`** now reads model name and base URL from `ai_provider_configs` DB table (was hard-coded `OLLAMA_MODEL` env var defaulting to `llama3:8b`)
- **Identical pipeline** across API endpoint and Celery worker: same validated llama3.2:3b Variant A prompt, same Variant A hyperparameters (`temperature=0.20`, `top_p=0.85`, `top_k=30`, `repeat_penalty=1.15`, `num_predict=160`), same `_clean_output()` post-processing
- Worker now fetches all 12 context fields per record (was 5) to fully populate the prompt (domain, line of business, distinct values, standard format, sensitivity, PK, nullable)
- All 226 business definitions across 5 projects regenerated with the validated prompt

### Metadata Attributes — Generate All Button
- **"Generate All AI Definitions" button** auto-disables when every record in the project already has an `ai_generated` definition; re-enables automatically if any record is added without a definition or reverts to `pending`

### Super Admin — Full UI Access
- **Super admin role bypasses all user-identity and approval-step gates** across all document pages:
  - **DPIA**: `canAction` now allows super admin to approve/reject any step regardless of which user is the assigned approver
  - **DSR**: both signature pads (Client Sign Off step 4, SME Sign Off step 3) are unlocked at any approval step for super admin
  - **AI Checklist**: same signature pad unlock (DM Sign-off step 2, SME Sign-off step 3)
  - **ROPA**: `canEdit` bypasses the `approved`-status lock for super admin
- **Backend**: `is_super_admin` computed property added to `User` model; exposed via `UserOut` Pydantic schema and carried in the auth store so frontend gates can read it without additional API calls
- Super admin retains these capabilities while all step-sequencing and business rules continue to apply for other roles

### Approval Timeline — Visual Consistency
- **Active (requested) step** now renders with a **primary-blue dot** and blue badge across all timeline views; previously it was indistinguishable from not-yet-reached steps
- Fixed in four locations: DSR main timeline, DPIA → DSR sub-timeline, DPIA → AICK sub-timeline, AI Checklist → DSR modal timeline
- Not-yet-reached steps consistently show a lighter grey dot with "Not Yet" label; completed steps remain green (approved) or red (rejected)

### DSR Checklist Sign-Off — Correct Trigger
- **`validated_at`** (the "Signed off" badge on the Data & Insights Sharing Evaluation Checklist) is now set **only when both physical signatures are present** — `sign_off.prepared_signature` AND `sign_off.acknowledged_signature`
- Previously it was triggered by `ai_assessment.sign_off.approved === "Yes"`, which is an auto-set default field, causing the "Signed off" badge to appear before anyone had actually signed
- `validated_at` is also **cleared** if either signature is later removed, keeping the state accurate
- Existing records with prematurely-set `validated_at` (e.g. DSR-2026-0003) corrected directly in the database

---

## Recent Updates (2026-05-21)

### Filtering & Overview Pages
- **DSR overview** — Status filter renamed to "All DSR Statuses"; Year filter is now dynamic (sourced from distinct project years in the database)
- **AI Checklist overview** — Status filter uses checklist-specific values ("All AI Checklist Statuses"): In Progress, Pending Sign-Off, Completed & Signed; backend `checklist_status` query param maps to SQL conditions on `validated_at` and DSR status; dynamic Year filter
- **DPIA overview** — Full page rewrite matching DSR/AI Checklist style: paginated table, "All DPIA Statuses" filter, dynamic Year filter, chevron pagination
- **Projects overview** — Four new filter dropdowns: All Clients · All Categories · All Years · All Monetized; backend adds `client` and `is_monetized` query params; `ProjectFiltersResponse` extended with `clients` list

### Export PDF — DPIA Detail Page
- Export PDF button added to DPIA detail page (matching DSR and AI Checklist)
- Sections in UI order: Project Information → Data Categories → Approval Timeline → Regulatory References → Governance Activities (A–D) → Risk Assessment → Mitigation & Residual Risk
- Governance tables A–D use `table-layout:fixed` with uniform `colgroup` column widths (42 % Activity / 18 % Responsible / 12 % Status / 28 % Remarks)

### PDF Header Standardisation
- All document PDFs (DSR, DPIA, AI Checklist) now use a consistent subtitle format: `[Tracking ID] · [Project Name] · [Year] · [Status badge] · [flags] · v[version]`
- Document h1 is the document type name only (tracking ID moved to subtitle)
- DSR adds AI Use flag; DPIA adds Contains PII flag; status badges are colour-coded (approved/review/warning/danger/draft)
- New `pdfStatusBadge()` helper and badge types (`warning`, `review`, `danger`) added to `exportPdf.ts`

### Dashboard
- Quick Actions buttons — text is now left-aligned (was centred)

### Metadata Management — Source Logic Rework
- **Source Tables section** always shows **all documented tables for the project across all source types** (GCP, Excel, PostgreSQL together), driven by a dedicated query independent of the Source Configuration state
- **Source Configuration panel** remains dedicated to importing/uploading new data for the selected source type; uploading an Excel file temporarily shows fresh sheets in Source Tables until the upload is cleared
- Backend fallback for `/metadata/tables/{project_id}` now returns all documented tables for the project (grouped by `data_domain_table` + `source_type`) instead of filtering by the selected source type

---

## Recent Updates (2026-05-19)

### Metadata Attributes Page — UI Overhaul
- **Project info strip** above the grid: Project ID · Project Name · Project Year · Business Users · Line of Business · Data Steward · Data Owner (responsive 7-column layout)
- **Column order refined**: Table Type → Data Year → Grouping → Level → Attribute → Type → Sensitivity → Business Term → Business Definition → Standard Format → PK → Null → Sample
- **NULL display**: No = green (required field / good quality), Yes = red (nullable / quality risk)
- **Updated By auto-populated** on first import from the user who clicked Proceed; refreshed on Save All
- **Bulk Save All**: stamps `updated_date` and `updated_by` on all records in one click
- **Standard Format auto-assessed** during import by `_assess_standard_format()` in the Celery worker

### Export Improvements
- **Export dropdown** (hover): Excel (.xlsx) or PDF (A3 landscape)
- **Excel** exports 25 columns — inserts 7 project-level columns (Project ID → Data Owner) between `#` and Table
- **PDF** now matches the UI: sensitivity colour pills, blue PK badge, red/green Null, violet AI chip on definitions, monospace fonts for table/attribute/sample, system UI font stack, colgroup column widths

### Projects Page
- New **Data Steward & Data Owner card** below Project Team (free-text full name + email)
- Saved to `data_owner_stewards` table; values appear in Metadata Attributes info strip and PDF export

---

## Project Structure

```
datagov-tools/
├── backend/
│   ├── app/
│   │   ├── core/          # RBAC, security, deps
│   │   ├── models/        # SQLAlchemy ORM models
│   │   ├── routers/       # FastAPI route handlers
│   │   ├── schemas/       # Pydantic request/response schemas
│   │   ├── services/      # Business logic (metadata population, AI generation)
│   │   └── worker/        # Celery tasks (metadata, DQ, notifications, scheduled)
│   ├── alembic/           # Database migrations
│   ├── scripts/           # Seed and utility scripts (backfill, regenerate)
│   └── tests/             # Unit and integration tests
├── frontend/
│   └── src/
│       ├── app/           # Next.js App Router pages
│       ├── components/    # Shared UI components
│       ├── lib/           # API client, utilities, PDF export
│       └── store/         # Auth state (Zustand)
├── nginx/                 # Nginx reverse proxy config
├── docs/                  # UAT checklist and open items
├── docker-compose.yml     # Defines: api, worker, beat, frontend, db, redis, nginx, ollama
└── .env.example
```

### Docker volumes

| Volume | Mount path | Purpose |
|--------|-----------|---------|
| `postgres_data` | `/var/lib/postgresql/data` | Primary database — permanent |
| `redis_data` | `/data` | Redis persistence |
| `ollama_data` | `/root/.ollama` | Downloaded LLM model weights |
| `tmp_data` | `/tmp` | Shared temp dir for API ↔ worker file handoff |
| `uploads_data` | `/app/uploads` | Persistent Excel/CSV source files per project |
| `static_files` | `/var/www/static` | Static assets served by nginx |

---

## Development

### Restart after code changes

```bash
# Backend / task code changes — always clear pycache first
Get-ChildItem -Path backend -Recurse -Filter "__pycache__" -Directory | Remove-Item -Recurse -Force
docker compose restart worker api

# Beat schedule changes (celery_app.py)
docker compose restart beat

# Frontend changes
docker compose build frontend
docker compose up -d frontend

# After any container recreation (up -d) nginx must be restarted
# to pick up new container IPs (handled automatically after 30s via DNS resolver,
# but an explicit restart is instant)
docker compose restart nginx
```

> **Note:** Use `docker compose restart` for code-only changes (preserves container IPs).
> Use `docker compose up -d` only when adding new volume mounts or env vars — this recreates
> the container and briefly changes its IP. Nginx recovers automatically within 30 s.

### Celery Beat scheduled tasks

| Task | Schedule (WIB) | Purpose |
|------|---------------|---------|
| `retention_eligibility_scan` | Daily 02:00 | Flag BAPD records past their expiry date |
| `cleanup_temp_files` | Daily 03:00 | Delete temp export files older than 24 h from `/tmp` |
| `source_file_expiry_check` | Daily 07:00 | Warn project teams 7 days before source file deletion; auto-delete on expiry day |
| `dsr_expiry_check` | Daily 08:00 | Warn on DSRs expiring in 7 days; auto-archive past-due DSRs |
| `gcp_sa_key_purge` | Every 30 min | Purge in-memory GCP service account keys older than 30 min |

### Running tests

```bash
# Backend unit + integration tests
docker exec ag_api pytest backend/tests/ -v
```

---

## Environment Variables

See [`.env.example`](.env.example) for the full list of required variables. Never commit your `.env` file.

---

## License

Internal use only.
