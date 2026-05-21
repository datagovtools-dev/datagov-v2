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
| **Projects** | Central project registry — create and manage data governance projects with team assignments (DGO, DM, SME, PIC); assign Data Steward and Data Owner with free-text name/email |
| **Data Sharing Request (DSR)** | End-to-end data sharing request lifecycle with serial 4-step approval workflow and client sign-off |
| **AI/ML Compliance Checklist (AICK)** | GEN AI usage assessment checklist linked to each DSR — 3-step serial approval with sign-off |
| **Data Protection Impact Assessment (DPIA)** | Auto-created from DSR; tracks residual risk, data categories, and 2-step governance approval |
| **Record of Processing Activities (ROPA)** | Document and track all data processing activities |
| **Data Extermination / BAPD** | Manage data disposal/extermination requests with evidence upload and approval |
| **Data Quality (DQ)** | Connect to GCP BigQuery, PostgreSQL, or Supabase and run automated data quality checks |
| **Metadata Management** | Auto-populate data dictionaries from GCP BigQuery, PostgreSQL, or Excel/CSV files; enrich with AI-generated business definitions via local Ollama LLM; responsive project info strip (Data Steward/Owner, Business Users, Line of Business); auto-assess Standard Format from data values; export to Excel (25-col) or styled PDF (A3 landscape with sensitivity pills, PK/NULL colour coding, AI badges) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Next.js 14 (App Router) + Tailwind CSS |
| **Backend** | FastAPI (Python) + SQLAlchemy + Alembic |
| **Database** | PostgreSQL |
| **Cache / Queue** | Redis + Celery |
| **AI / LLM** | Ollama (`phi3:mini`) — local, no external API needed |
| **Infrastructure** | Docker Compose + Nginx (reverse proxy) |
| **Cloud Integrations** | GCP BigQuery, GCS, PostgreSQL/Supabase |
| **CI/CD** | GitHub Actions |

---

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Nginx     │────▶│  Frontend   │     │   Ollama    │
│  (Port 80)  │     │  Next.js    │     │  phi3:mini  │
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
docker exec ag_ollama ollama pull phi3:mini
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
- **Sign-off with e-signature** — draw, drag-and-drop, or upload signature images; decision locked once signed
- **AI-generated metadata definitions** — bulk-generate business definitions for all data attributes using local Ollama LLM (`phi3:mini`); single queued endpoint avoids connection pool exhaustion
- **Standard Format auto-assessment** — on every metadata import the worker classifies each column's value format (date, categorical, phone, email, integer, decimal, ID/code, free text) and stores it automatically
- **Multi-source metadata ingestion** — GCP BigQuery, PostgreSQL/Supabase, Excel/CSV (multi-file, multi-sheet); original filenames preserved throughout
- **Metadata attributes grid** — 19-column inline-editable grid with project info strip (Data Steward, Data Owner, Business Users, Line of Business); bulk Save All stamp; bulk grouping per table
- **Styled PDF & Excel export** — Metadata PDF (A3 landscape) renders sensitivity pills, PK/NULL colour coding, AI badges, and monospace column names matching the UI; Excel export inserts 7 project-level columns
- **Data Steward & Data Owner** — assignable per project via free-text name + email; surfaced in the Metadata Attributes info strip and all exports
- **RBAC** — role-based access control enforced on both frontend and backend
- **PDF export** — export any DSR, AI Checklist, DPIA, or Metadata report to a formatted PDF; all document PDFs share a standardised header/subtitle format with colour-coded status and flag badges
- **Advanced overview filters** — DSR, DPIA, AI Checklist, and Projects overview pages have module-specific status filters and dynamic year filters; Projects additionally filters by Client, Category, and Monetized flag
- **Audit trail** — all changes logged with user, timestamp, and action
- **Notification system** — in-app notifications for approval actions and status changes
- **Data Quality checks** — automated DQ profiling against BigQuery, PostgreSQL, or Supabase

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
