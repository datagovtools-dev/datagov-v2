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
| **Data Quality (DQ)** | Connect to GCP BigQuery, PostgreSQL, or Supabase and run automated data quality checks; DQ run results go through a review/approval workflow (pending → running → completed → under_review → approved/rejected) |
| **Metadata Management** | Auto-populate data dictionaries from GCP BigQuery, PostgreSQL, or Excel/CSV files; Source Tables section shows all documented tables for a project across all source types; enrich with AI-generated business definitions via configurable Ollama (local or cloud); batch-process definitions in chunks to avoid connection pool exhaustion; responsive project info strip (Data Steward/Owner, Business Users, Line of Business); auto-assess Standard Format from data values; bulk grouping assignment per table; export to Excel (25-col) or styled PDF (A3 landscape with sensitivity pills, PK/NULL colour coding, AI badges) |
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
| `admin` | Full access including user management |
| `compliance_officer` | Full operational access (all modules: create, edit, approve) |
| `dpo` | Same as compliance_officer |
| `viewer` | Read-only across all modules; can create DSR drafts |

---

## Key Features

- **Serial approval workflows** — DSR (4 steps), AICK (3 steps), DPIA (2 steps), BAPD — each step activates only after the previous is approved
- **Automatic linked-record creation** — submitting a DSR auto-creates a paired AICK and DPIA for the same project
- **Sign-off with e-signature** — draw, drag-and-drop, or upload signature images; decision locked once signed
- **AI-generated metadata definitions** — bulk-generate business definitions for all data attributes using a configurable Ollama provider (local or cloud mode); validated llama3.2:3b Variant A prompt (verb-first, 7-rule, CRITICAL semicolon ban, categorical/PII/PK/nullable conditionals) with Variant A hyperparameters applied identically across the API endpoint and Celery worker; post-processing normalises output (newline collapse, semicolon-to-sentence conversion, trailing period); model and base URL are DB-driven (configured in Settings > AI Setup); "Generate All AI Definitions" button auto-disables when all records are already generated; batch-chunked endpoint avoids connection pool exhaustion; single-record regeneration also available
- **Standard Format auto-assessment** — on every metadata import the worker classifies each column's value format (date, categorical, phone, email, integer, decimal, ID/code, free text) and stores it automatically
- **Multi-source metadata ingestion** — GCP BigQuery, PostgreSQL/Supabase, Excel/CSV (multi-file, multi-sheet); original filenames preserved; Source Tables section shows all documented tables across all source types
- **Metadata attributes grid** — 19-column inline-editable grid with project info strip (Data Steward, Data Owner, Business Users, Line of Business); bulk Save All stamp; bulk grouping assignment per table
- **Retention policies & eligibility detection** — BAPD manages 8 built-in retention policy types; eligible datasets (past expiry) are auto-discovered and surfaced as a warning panel
- **Data Quality review workflow** — DQ runs progress through pending → running → completed → under_review → approved/rejected states
- **Styled PDF & Excel export** — Metadata PDF (A3 landscape) renders sensitivity pills, PK/NULL colour coding, AI badges, and monospace column names; Excel export inserts 7 project-level columns; all document PDFs (Project, DSR, AICK, DPIA) share a standardised header with colour-coded status and flag badges
- **Data Steward & Data Owner** — assignable per project via free-text name + email; surfaced in the Metadata Attributes info strip and all exports
- **RBAC** — role-based access control enforced on both frontend and backend
- **Advanced overview filters** — each module's overview has module-specific status filters and dynamic year filters; Projects additionally filters by Client, Category, and Monetized flag; ROPA filters by Legal Basis
- **Configurable AI settings** — provider, mode (local/cloud), base URL, model name, API key, batch size, and timeout configurable via the Settings UI with a live test-connection check
- **Audit trail** — all changes logged with user, timestamp, and action; filterable by module, action, entity, actor, and date range
- **Notification system** — in-app notifications for approval actions and status changes

---

## Recent Updates (2026-05-25)

### AI Generation Pipeline — End-to-End Alignment
- **Celery worker `generate_ai_definition`** now reads model name and base URL from `ai_provider_configs` DB table (was hard-coded `OLLAMA_MODEL` env var defaulting to `llama3:8b`)
- **Identical pipeline** across API endpoint and Celery worker: same validated llama3.2:3b Variant A prompt, same Variant A hyperparameters (`temperature=0.20`, `top_p=0.85`, `top_k=30`, `repeat_penalty=1.15`, `num_predict=160`), same `_clean_output()` post-processing
- Worker now fetches all 12 context fields per record (was 5) to fully populate the prompt (domain, line of business, distinct values, standard format, sensitivity, PK, nullable)
- All 226 business definitions across 5 projects regenerated with the validated prompt

### Metadata Attributes — Generate All Button
- **"Generate All AI Definitions" button** auto-disables when every record in the project already has an `ai_generated` definition; re-enables automatically if any record is added without a definition or reverts to `pending`

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
│   │   └── worker/        # Celery tasks (metadata, DQ, notifications)
│   ├── alembic/           # Database migrations
│   ├── scripts/           # Seed and utility scripts
│   └── tests/             # Unit and integration tests
├── frontend/
│   └── src/
│       ├── app/           # Next.js App Router pages
│       ├── components/    # Shared UI components
│       ├── lib/           # API client, utilities
│       └── store/         # Auth state (Zustand)
├── nginx/                 # Nginx reverse proxy config
├── docs/                  # UAT checklist and open items
├── docker-compose.yml
└── .env.example
```

---

## Development

### Restart after code changes

```bash
# Backend / task code changes — always clear pycache first
Get-ChildItem -Path backend -Recurse -Filter "__pycache__" -Directory | Remove-Item -Recurse -Force
docker compose restart worker api nginx

# Frontend changes
docker compose build frontend
docker compose up -d frontend
docker compose restart nginx
```

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
