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
| **Projects** | Central project registry — create and manage data governance projects with team assignments (DGO, DM, SME, PIC); system-assigned Project ID `PRJ-<Project Year>-<3-digit number>` (e.g. `PRJ-2026-001`), not editable by users; assign Data Steward and Data Owner with free-text name/email; filter by Client, Category, Year, and Monetized flag; export project summary to PDF |
| **Data Sharing Request (DSR)** | End-to-end data sharing request lifecycle with serial 4-step approval workflow and client sign-off; auto-creates an AICK and DPIA on submission; filter by DSR status and year; export to PDF |
| **AI/ML Compliance Checklist (AICK)** | GEN AI usage assessment checklist auto-created with each DSR — 3-step serial approval with sign-off; filter by checklist status (In Progress / Pending Sign-Off / Completed & Signed) and year; export to PDF |
| **Data Protection Impact Assessment (DPIA)** | Auto-created from DSR; tracks residual risk, data categories, regulatory references, and governance activities (4 sections A–D); 2-step approval workflow; filter by DPIA status and year; export to PDF |
| **Record of Processing Activities (ROPA)** | Document and track all data processing activities; filter by legal basis |
| **Data Extermination / BAPD** | Manage data disposal/extermination requests with evidence upload and approval; manage retention policies (8 built-in policy types); auto-discover datasets eligible for disposal based on retention expiry |
| **Data Quality (DQ)** | Project-based DQ workflow using source files already imported or connected through Metadata; the New DQ Run wizard starts with project selection, auto-selects all available project files, then lets the user run one or all files without re-uploading; integrates the provided Existing Data Quality reference method for **Completeness**, **Consistency** (AI-generated regex pattern + business rules), **Uniqueness**, and **Latency**; each file creates an independent DQ run and each column-level result stores data type, business rules, regex pattern, version, regex version, complexity, reasoning, and automated remarks |
| **Metadata Management** | Auto-populate data dictionaries from GCP BigQuery or Excel/CSV files (export data from other databases to Excel/CSV first); Source Tables section shows all documented tables for a project across all source types with **"Open All Tables →"** shortcut to the full attribute grid; enrich with AI-generated business definitions via configurable Ollama (local or cloud); batch-process definitions in chunks to avoid connection pool exhaustion; responsive project info strip (Data Steward/Owner, Business Users, Line of Business); auto-assess Standard Format from data values; bulk grouping assignment per table; export to Excel (25-col) or styled PDF (A3 landscape with sensitivity pills, PK/NULL colour coding, AI badges); uploaded Excel/CSV files persisted to `uploads_data` volume and tracked in `project_source_files`; post-project retention (end date + 30 days, or + the approved ROPA retention period) with 7-day advance warning and auto-deletion |
| **Settings** | Manage users, roles, notification preferences, and AI/LLM configuration (provider, mode, base URL, model name, API key, batch size, timeout); test connection from the settings page |
| **Audit Log** | Full audit trail of all actions across modules; filter by module, action, entity, actor, and date range |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Next.js 14 (App Router) + Tailwind CSS |
| **Backend** | FastAPI (Python) + SQLAlchemy |
| **Database** | SQLite (single file, WAL mode) |
| **Cache / Queue** | Redis + Celery |
| **AI / LLM** | Ollama - metadata definitions use DB-configured Settings > AI Setup; DQ reference method uses the same model (`llama3.2:3b`) with a data-profile regex + repair pass, unless overridden by DQ env vars |
| **Infrastructure** | Docker Compose + Nginx (reverse proxy) |
| **Cloud Integrations** | GCP BigQuery, GCS |
| **CI/CD** | GitHub Actions |

---

## Environment & Version Requirements

Current baseline: **AI Governance Tools v1.0.0**. This local environment was last validated on `2026-09-25` (SQLite runtime, on top of commit `d6ed1e2`).

Developer configuration reference: see `development.config.yml` for AI model parameters, prompt contracts, database dump rules, shared UI contracts, and validation notes. For the new project-based Data Quality flow and reference method handoff, see `docs/data-quality-reference-method.md`.

### Required Local Tools

| Tool | Required / Tested Version | Notes |
|------|---------------------------|-------|
| Docker Desktop | Recent version with Docker Compose v2 | Primary runtime for local development and production-style testing |
| Git | Any current Git client | Required for clone, pull, branch, commit, and push workflows |
| Browser | Chrome or Edge recommended | The UI is served through Nginx at `http://localhost` |
| Node.js | 20.x, only when running the frontend outside Docker | Docker uses `node:20-alpine`; host `node_modules` are not required for the Docker flow |
| Python | 3.11.x, only when running the backend outside Docker | Backend supports Python `>=3.11,<3.13`; Docker uses `python:3.11-slim` |
| Ollama | Local container or cloud endpoint | Local model baseline is `llama3.2:3b`; cloud mode is configured in Settings > AI Setup with base URL, API key, and model |

### DQ Reference Method Model Requirements

The Data Quality module uses the provided Existing Data Quality reference method. Since 2026-09-27 it runs on the same local model as Metadata (`llama3.2:3b`) instead of the template's `qwen2.5-coder:32b` + `llama3.1:70b`, which are too heavy for local CPU computation:

| Purpose | Default model | Override env var |
|---------|---------------|------------------|
| Primary rule/regex generation | Settings > AI Setup model (`llama3.2:3b`) | `DQ_PRIMARY_MODEL` |
| Repair pass for consistency scores below 70 | same as primary | `DQ_SECONDARY_MODEL` |
| Ollama endpoint | Settings > AI Setup base URL, then `http://ollama:11434` | `DQ_OLLAMA_BASE_URL` |
| Request timeout | Settings > AI Setup timeout (minimum 300 s for DQ) | `DQ_OLLAMA_TIMEOUT_SECONDS` |
| API key fallback | Settings > AI Setup encrypted key | `DQ_OLLAMA_API_KEY` |

To keep the result quality of the qwen rules index with a 3B model, the regex is first derived from the data itself (data-profile regex, built from the value shapes of at least 95% of rows); the model writes the business rules from plain-language facts measured on the data (structure, distinct values, range, length, characters), plus complexity and reasoning, may correct the regex (the better-scoring regex is kept), and a repair pass with the failing values runs when the index is below 70. Details and benchmark: `docs/data-quality-reference-method.md`.

Local model install commands:

```bash
docker compose -f docker-compose.yml up -d ollama
docker compose -f docker-compose.yml exec -T ollama ollama pull llama3.2:3b
docker compose -f docker-compose.yml exec -T ollama ollama list
```

Benchmark (18 test columns, 2026-09-27): mean consistency index 99.9 with 100% of wrong values rejected, versus 88.9 for the qwen rules index on the same HSO columns. On CPU a DQ run takes about 35-150 s per column (average about 65 s). If the model is missing, DQ generation reaches the Generate step but each file run can fail with an Ollama `/api/generate` 404.

### Container Baseline

| Service | Version / Image |
|---------|-----------------|
| Nginx | `nginx:1.25-alpine` |
| Frontend | Next.js `14.2.4`, React `18.3.1`, Tailwind CSS `3.4.4`, running on `node:20-alpine` |
| Backend API | FastAPI `0.111.0`, SQLAlchemy `2.0.30`, aiosqlite `0.20.0`, Pydantic `2.7.1`, running on `python:3.11-slim` |
| Database | SQLite file `/data/datagov.db` in the `sqlite_data` volume |
| Cache / Queue | `redis:7-alpine` with Celery `5.4.0` |
| LLM | `ollama/ollama:latest`; metadata recommended local model `llama3.2:3b`; DQ reference models are listed above |

### Important Team Notes

- Use Docker Compose as the source-of-truth runtime unless a task specifically requires native frontend or backend execution.
- For frontend-only updates, rebuild and recreate the frontend (nginx does not need a restart; it finds the new container by name):
  ```bash
  docker compose -f docker-compose.yml build frontend
  docker compose -f docker-compose.yml up -d frontend
  ```
- After changing `nginx/nginx.conf`: `docker exec ag_nginx nginx -t` then `docker exec ag_nginx nginx -s reload`.
- Schema changes: there are no migration files. On startup the API creates missing tables and adds any model column that is missing from an existing table (`sync_schema()` in `app/database.py`). New columns are added as nullable; renaming, dropping or changing the type of a column needs a one-off script against the SQLite file.
- Do not commit `.env`, API keys, uploaded source files, coverage artifacts, Docker volumes, or generated local cache files.
- Backend tests run on in-memory SQLite (`backend/tests/conftest.py`); no database service is needed.
- Production readiness and open follow-up work are tracked in `docs/open-items.md`.

> **Team notice (2026-09-25): the project runs 100% on SQLite during the development stage.** PostgreSQL was removed from the app, the Celery worker, CI and the deploy script: there is no `db` container, no Alembic, and no `database/ag_db_dump.sql`. The Metadata "Postgres" source connector and the DQ PostgreSQL source were removed as well: export data from external databases to Excel/CSV and upload it instead. The bundled data lives in `backend/datagov.db`. After pulling, run `docker compose build` and `docker compose up -d --remove-orphans`. PostgreSQL is planned for production; see [Environments](#environments).

---

## Environments

The project has two target environments. Only the first one exists today.

| | 1. Development (current) | 2. Production (future, planned) |
|---|---|---|
| **Status** | In use | Not implemented yet |
| **Database** | SQLite, one file (`/data/datagov.db`) | PostgreSQL 15 (Google Cloud SQL recommended) |
| **Users** | Small team; one write at a time | Many concurrent users |
| **Compose file** | `docker-compose.yml` | `docker-compose.prod.yml` (to be created) |
| **Schema changes** | Automatic on startup (`sync_schema()`) | Alembic migrations |
| **Backups** | `export-sqlite.ps1` snapshot | Managed backups with point-in-time restore |

### 1. Development (current): SQLite

Everything in this README describes this environment unless it says otherwise.

- **Runtime:** `docker compose up -d` starts `api`, `worker`, `beat`, `frontend`, `redis`, `nginx` and `ollama`. No database service is needed.
- **Database:** SQLite in WAL mode with a 30-second busy timeout, stored in the `sqlite_data` volume and seeded from `backend/datagov.db` on first start. `export-sqlite.ps1` copies the live database back into the repo.
- **Accepted limits for this stage:**
  - One write at a time: parallel saves wait for each other, and heavy multi-user use is not supported.
  - The API runs a single Uvicorn process, and the API and worker must run on the same machine.
  - Only new columns are added automatically; renaming, dropping or changing a column needs a one-off script.
  - Data access is controlled by the app's RBAC only (no database-level per-project rules).
  - Backups are manual snapshots, not point-in-time.
- **External data:** BigQuery can be read directly; data from any other database is exported to Excel/CSV and uploaded.
- **Tests and CI:** backend tests run on in-memory SQLite; GitHub Actions needs only a Redis service. Run them with `docker exec -e DATABASE_URL=sqlite+aiosqlite:///:memory: -e DATABASE_URL_SYNC=sqlite:///:memory: ag_api pytest tests/ --no-cov` (the in-memory URLs keep tests away from the live database). Known issue: 3 tests in `tests/unit/test_ai_generation.py` fail (they also fail on commit `d6ed1e2`), so the CI test step fails until they are fixed; see `docs/open-items.md`.
- **Operational notes:** the app resets the 8 built-in trial accounts to their default passwords on every start. Nginx finds the `api` and `frontend` containers again by name after they are restarted or recreated (Docker DNS, re-checked every 10 s), so no nginx restart is needed; right after a restart the API answers 502 for the few seconds it needs to start, and the page shows "The server is not reachable … try again". Nginx rate-limits rapid API calls (HTTP 429) and accepts uploads up to 25 MB per file (HTTP 413 above that).

### 2. Production (future): PostgreSQL

**Status: planned, not implemented.** Move to this environment before go-live, or earlier if the development limits above start to block work (for example, several teams saving at the same time, or the need to run more than one API server).

**Target setup:** SQLite stays for local development; production uses PostgreSQL with the same application code. The models already use database-neutral types (`Uuid`, `JSON`), and worker tasks and scripts use one shared SQLAlchemy session (`get_sync_session()`), so no application logic has to be rewritten.

**Changes needed when the switch happens:**

| Area | Change |
|------|--------|
| Dependencies | Add `asyncpg` and `psycopg2-binary` back to `backend/requirements.txt` and `pyproject.toml`; add `libpq-dev` back to `backend/Dockerfile` if needed |
| `app/database.py` | Keep the SQLite settings for SQLite URLs; use connection pooling (`pool_pre_ping`, pool size) for PostgreSQL URLs |
| Schema management | Re-introduce Alembic with **one new baseline migration generated from the current models** (the old PostgreSQL migrations are not restored). Use batch mode so the same migrations also run on SQLite. Keep `sync_schema()` as a development safety net |
| Audit log protection | Create the `audit_logs` no-update/no-delete trigger for PostgreSQL in the baseline migration (SQLite already has it) |
| Per-project row-level security | Optional. The old PostgreSQL RLS policies were never effective, because the app never set `app.current_user_id` on its connections. Add only if required, together with that per-request setting |
| `docker-compose.prod.yml` | Create it (`scripts/deploy-production.sh` already refers to it): no `sqlite_data` volume, `DATABASE_URL` from `.env.production`, API with 4 workers |
| `.env.example` | Add a production PostgreSQL section (`DATABASE_URL=postgresql+asyncpg://...`, `DATABASE_URL_SYNC=postgresql://...`) |
| `scripts/deploy-production.sh` | Run `alembic upgrade head` before starting the services |
| GitHub Actions | Keep the SQLite test job; add a job that runs the migrations and tests against a PostgreSQL service. Fix the staging and production deploy steps, which run plain `docker compose up` and would start the SQLite development stack on the server |
| First production data | Either load the merged dataset once (a SQLite-to-PostgreSQL copy script was used for this before and can be added to `scripts/`), or start with users and roles only |
| Backups | Use Cloud SQL automated backups with point-in-time recovery (see `docs/open-items.md`) |
| AI model for Metadata and DQ | Development uses `llama3.2:3b` on CPU (about 1 minute per DQ column). For production volumes, run Ollama on a GPU server or an Ollama-compatible cloud endpoint (Settings > AI Setup); a larger DQ model can be set with `DQ_PRIMARY_MODEL` / `DQ_SECONDARY_MODEL` without code changes |
| Uploaded files | Keep the `uploads_data` volume on persistent, backed-up storage: DQ runs and re-runs read the uploaded Excel files from it (the database stores only their path). `backend/shared_uploads/` is for fictitious test files in development only; do not use it for production data |
| Documentation | Update this section, `database/README.md` and `development.config.yml` to describe the live production setup |

**Decisions to make before starting:**
1. Where PostgreSQL runs: Google Cloud SQL (recommended) or a container on the application server.
2. First production data: the merged dataset or a clean start.
3. Whether database-level per-project security is required, or the app's RBAC is enough.

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
│   Backend   │────▶│   SQLite    │◀────│   Celery    │
│   FastAPI   │     │  (Database) │     │   Worker    │
└─────┬───────┘     └─────────────┘     └──────▲──────┘
      │                                         │
      ▼                                         │
┌─────────────┐                                 │
│    Redis    │─────────────────────────────────┘
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
git clone https://github.com/datagovtools-dev/datagov-v2.git
cd datagov-v2
```

> **Native Run (No Docker)**: You can also run natively using PowerShell `.\start-native.ps1` (reads `.env.local`). It uses `backend/datagov.db` directly. Background jobs (DQ runs, scheduled tasks) need Redis + a Celery worker, so use Docker for the full feature set.

### 2. Set up environment variables

```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `SECRET_KEY` and `AI_CONFIG_ENCRYPTION_KEY`: generate each with `openssl rand -hex 32`
- `REDIS_PASSWORD`: choose a strong password, and use it in `REDIS_URL`, `CELERY_BROKER_URL` and `CELERY_RESULT_BACKEND`

Docker Compose sets the database URLs itself (`/data/datagov.db`); the `DATABASE_URL*` values in `.env` only apply to a native run.

### 3. Start the platform

```bash
docker compose up -d
```

This starts `api`, `worker`, `beat`, `frontend`, `redis`, `nginx` and `ollama`. On the first start the SQLite database is copied from `backend/datagov.db` into the `sqlite_data` volume. The app creates any missing tables and the default users on startup, so no migration or seeding step is needed.

### 4. Pull the Metadata AI model

```bash
docker exec ag_ollama ollama pull llama3.2:3b
```

This model supports the Metadata definition flow. For the Data Quality reference method, also install or provide the DQ models listed in "DQ Reference Method Model Requirements".

**Slow or unstable network:** `ollama pull` downloads the ~2 GB weights in 16 parallel parts. On a slow connection (tested at ~8 Mbps Wi-Fi) each part stalls and restarts from zero, so the pull never finishes, even though the ~1 GB already on disk makes it look half done. Use the single-connection script instead. It resumes after drops, verifies the sha256, and then runs `ollama pull` to finish the small layers:

```bash
docker cp scripts/fetch-ollama-model.sh ag_ollama:/tmp/fetch-ollama-model.sh
docker exec ag_ollama sh /tmp/fetch-ollama-model.sh llama3.2 3b
```

At ~1 MB/s the model takes about 30 minutes. Check it with `docker exec ag_ollama ollama list`. The AI runs on the CPU on a laptop without a GPU: expect about a minute for the first answer (model loading) and 15–20 seconds per metadata definition afterwards. Settings > AI Setup > Test connection confirms the app can reach the model.

### 5. Open the app

Navigate to **http://localhost** in your browser.

Default admin login:
- Email: `admin@governance.local`
- Password: `Admin1234!`

On every startup the app resets the eight built-in trial accounts (`admin@governance.local` and the `@company.com` trial users) to their default passwords (`Admin1234!` / `User1234!`). Other users keep their own passwords.

### Working with the SQLite database

- The live database is `/data/datagov.db` in the `sqlite_data` Docker volume, not the file in the repo. It is kept on the Docker (Linux) filesystem so the API and the Celery worker can share it with reliable file locking, in WAL mode with a 30-second busy timeout.
- `.\export-sqlite.ps1` copies a consistent snapshot of the live database back to `backend/datagov.db`, `database/datagov.db` and `database/datagov_sqlite_dump.sql`. Run it before committing data changes.
- To start again from the repo file: stop the stack, then `docker volume rm datagov-v2_sqlite_data`.
- The API runs a single Uvicorn process because SQLite allows one writer at a time.
- `audit_logs` rows are protected by SQLite triggers (created on startup): updates and deletes are rejected.
- Data from external databases: export the tables to Excel/CSV and upload them on the Metadata page (Excel / CSV source). Uploaded files are kept as project source files and reused by Data Quality runs. BigQuery can still be read directly.

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
- **Multi-source metadata ingestion** — GCP BigQuery and Excel/CSV (multi-file, multi-sheet); original filenames preserved; Source Tables section shows all documented tables across all source types with per-table "Open Grid →" and a header-level "Open All Tables →" button; uploaded Excel/CSV files are persisted to a dedicated Docker volume (`uploads_data`) and tracked in `project_source_files` for future re-runs
- **Source file retention policy** — uploaded source files (Excel/CSV) kept until 30 days after project `end_date`, or until `end_date` + the Retention Period of the project's approved ROPA, then auto-deleted; 7-day advance warning notification sent to the full project team and super admins; BigQuery imports have no physical files — all derived metadata attributes remain permanent regardless of retention
- **Metadata attributes grid** — inline-editable grid with project info strip (Data Steward, Data Owner, Business Users, Line of Business); per-table or all-tables view via dropdown; bulk Save All stamp; bulk grouping assignment per table
- **Retention policies & eligibility detection** — BAPD manages 8 built-in retention policy types; eligible datasets (past expiry) are auto-discovered and surfaced as a warning panel
- **Project-based reference Data Quality** — DQ uses project source files already imported through Metadata, so users do not need to upload the same Excel files again; New DQ Run auto-selects all files for the chosen project and creates one independent run per file; the backend executes the provided Existing Data Quality method for Completeness, Consistency, Uniqueness, and Latency; `dq_results` stores `data_type`, `business_rules`, `regex_pattern`, `regex_version`, `remarks`, and `details` JSON containing complexity and reasoning (`dq_runs.version` holds the DQ update number); DQ runs progress through pending → running → completed → under_review → approved/rejected states
- **Styled PDF & Excel export** — Metadata PDF (A3 landscape) renders sensitivity pills, PK/NULL colour coding, AI badges, and monospace column names; Excel export inserts 7 project-level columns; all document PDFs (Project, DSR, AICK, DPIA) share a standardised header with colour-coded status and flag badges
- **Data Steward & Data Owner** — assignable per project via free-text name + email; surfaced in the Metadata Attributes info strip and all exports
- **RBAC** — role-based access control enforced on both frontend and backend; `super_admin` role bypasses all user-identity and approval-step UI gates (DPIA approver check, DSR/AICK signature step locks, ROPA edit lock) while business rules remain in effect for other roles
- **Advanced overview filters** — each module's overview has module-specific status filters and dynamic year filters; Projects additionally filters by Client, Category, and Monetized flag; ROPA filters by Legal Basis
- **Configurable AI settings** — provider, mode (local/cloud), base URL, model name, API key, batch size, and timeout configurable via the Settings UI with a live test-connection check
- **Audit trail** — all changes logged with user, timestamp, and action; filterable by module, action, entity, actor, and date range
- **Notification system** — in-app notifications for approval actions and status changes

---

## Recent Updates (2026-09-27) — DQ on llama3.2:3b, DQ progress, file retention, sharing test data

Summary for teammates pulling this version: DQ runs on `llama3.2:3b` (no qwen/llama3.1:70b needed); DQ has a progress page and blocks double starts; uploaded files are kept until project end + 30 days or the approved ROPA retention period; test-project files are shared through `backend/shared_uploads/` (load the new database with `docker volume rm datagov-v2_sqlite_data`); nginx follows restarted containers by itself; error messages explain the HTTP code; business terms keep abbreviations in UPPERCASE; Metadata AI generation shows time left. Details below.

### Model switch
- DQ rule generation now uses the Settings > AI Setup model (`llama3.2:3b`, the same model as Metadata) instead of `qwen2.5-coder:32b` + `llama3.1:70b`, which are too heavy for local CPU computation. `DQ_PRIMARY_MODEL` / `DQ_SECONDARY_MODEL` still override it (for example a larger model on a GPU server).
- About 1 minute per column on CPU (35-150 s), plus about 60 s while the model loads.

### How result quality is kept at the qwen level (`backend/app/services/reference_dq.py`)
- **Data-profile regex:** the regex is derived from the value shapes of at least 95% of rows (`profile_regex()`), in the style of the qwen rules index (`^BPS_\d{3}$`, `^(KAB\.|KOTA) [A-Z]+( [A-Z]+)*$`, `^[135]$`, `^(-|AVG|MAX|Other|SUM)$`, `^-?\d+(\.\d+)?$`). Rare shapes are flagged, not absorbed.
- **Data facts:** the prompt gives the model plain facts measured on the column (structure, distinct values, number range, decimals, capitalisation, length, characters used); the business rules are written from these facts, because a 3B model misreads regex syntax.
- The model may correct the regex; the better-scoring regex is kept and Remarks record the decision. A repair pass with the failing values runs when the index is below 70.
- Results: synthetic benchmark (18 columns) mean index 99.9 vs 88.9 for the qwen rules index, 100% of wrong values rejected; real HSO sample data (1,685 columns) and a full llama3.2 run on 20 real HSO columns: see `docs/data-quality-reference-method.md`.

### Fixes
- Rules tab **Failed** for Consistency now shows the rows that do not match the regex (was a 0/1 flag), and the Completeness regex no longer shows a stray leading quote.
- Score tab: every attribute shows the same 4 metric slots (Completeness, Consistency, Uniqueness, Latency). A metric that was not run for the attribute shows a blank dashed bar marked **N/A** (with the reason on hover) instead of 0%, so 0% always means a real score of 0.
- KPI cards on the DQ run page, each with a short explanation. Row 1 counts **metric checks** (one per metric per attribute: up to 4 per column), except the last card: Total Metric Checks (= passed + warning + failed + checks on blank attributes), Passed Checks (score ≥ 95%), Warning Checks (70% to below 95%), Failed Checks (checks on real values scoring < 70%, listed in Findings; a 0% here means a wrong format or stale dates, not missing data) and **Blank Attributes** (columns in the file with no values at all, shown as "blank / all columns"; the explanation names them and says how many checks they account for). Row 2: Overall Score (average of all checks) and one card per metric (Completeness, Consistency, Uniqueness, Latency Score) with the average score over the attributes that have that metric; a metric not run stays as a card showing **N/A** with the reason. Pass/warning/fail thresholds are unchanged from the reference method.
- Blank attribute detection (Blank Attributes card): the worker marks an attribute as empty when every value is null/NaN/NaT, blank or whitespace, or a placeholder text (`null`, `none`, `nan`, `nat`, `n/a`, `na`, `#n/a`, `-`, `--`, `(blank)`, `undefined`, any case) — `reference_dq.is_empty_value()` / `empty_attributes()`. The names are stored in `dq_runs.empty_attributes`; every check on such an attribute gets the status **`no_data`** instead of pass/warning/fail (`reference_dq.mark_blank_attributes()`), its Completeness rule gets the Remark "All N values are empty …" and one finding "has no values" replaces the per-check findings. Scores are unchanged and still count in the Overall Score. Completeness alone would miss text placeholders (a column of 'NULL' texts scores 70–100% Completeness), so the data itself is inspected. Older runs fall back to Completeness = 0%. The Rules tab, Score tab ("No data" bars) and export show these checks as "no data".
- **DPIA auto-creation (clarified):** creating a project's first DSR also creates a DPIA draft for that project (empty risk content, status Draft, one DPIA per project); fill it in from the DPIA page and submit it. In the DPIA overview, "DSR Status" and "DPIA Status" are separate columns (e.g. DSR Submitted while the DPIA is still Draft).
- **Approval status rule (DSR and AICK, all projects):** after submit, a DSR or AICK stays **Submitted** until PIC Data Compliance approves step 1; only then it becomes **Under Review** (next approvers), then Approved and finally Signed. The AI Checklist overview now shows the checklist's own status (In Progress → Submitted → Under Review → Approved (Ready for Sign-Off) → Completed & Signed, or Rejected) instead of "Pending Approval" right after submit, and no longer takes the DSR's status for an AICK that was not submitted. Its status filter has the same options (`checklist_status=submitted|under_review|pending_signoff|signed|rejected|in_progress`).
- **Fix: AICK shown as signed too early.** Saving the AI checklist set it to "signed" (`ai_compliance_checklists.validated_at`) as soon as the pre-set sign-off answer "Approved? = Yes" was stored, so a just-submitted DSR/AICK showed "Signed & Locked" / "Completed & Signed" with no approval done. Now it counts as signed only when both AI sign-off signatures (DM and SME) are present or the last AICK approval step is approved; a rejection clears it. Existing data was corrected (only DSR-2026-0007 was affected).
- **DSR sign-off filled from the project:** when the DSR checklist is edited, **Prepared By** is filled from the project's Data Owner (name + the Data Owner's Position on the project) and **Acknowledged By** from the project SME (name + the SME's company position from the user account, not the project role). Both are read-only; if the Data Owner has no position yet, that field stays editable with a hint. Built-in trial accounts now carry company job titles instead of project-role labels (`backend/app/services/init_db.py`, re-applied on startup): Dewi Rahayu "Head of Business Analytics", Anisa Putri "Data Governance Manager", Budi Santoso "Data Compliance Manager", Eko Prasetyo "Data Analyst"; the viewer account gets "Internal Auditor" (`backend/scripts/seed_viewer.py`). All users have a position.
- **Data Owner position:** New Project and Edit Project have a Position field for the Data Owner (e.g. "CRM Department Head"), stored in `data_owner_stewards.position` (optional; the API also accepts it for the Lead Business Steward). It is shown under the owner's name in the project detail cards (Data Assets Catalog, and the project popups/cards on DSR, DPIA, AICK, BAPD, ROPA) and in the project PDF, and it fills the DSR sign-off. The Metadata and DQ headers (project info strip) and their exports show the Data Steward and Data Owner with name and email only (user decision 2026-09-27).
- **Project DQ Report** (`/dq/project/{projectId}`, button "Project Report" next to "Run All" on the Data Quality page): the latest run with results of every table in the project. The 10 KPI cards combine all tables (checks summed; Overall and metric scores averaged over all checks; Blank Attributes over all columns); the Score tab shows each table's own attribute scores with a link to its run; Rules and Findings list all tables with a Table column/label and table + dimension filters; Export (Excel/PDF) as on the run page, with a Table column. If a table's newest run failed or is still running, its previous run with results is used and a note says so; tables with no results are listed as not included. API: `GET /api/v1/dq/project/{project_id}/report`. The Data Quality page now keeps the selected project in the URL (`/dq?project=…`), so Back returns to it. The run page and the project report share `frontend/src/components/dq/DQReportParts.tsx`.
- DQ run page, Rules tab: **Export** button with Excel (.xlsx) and PDF, like the Metadata page. It exports the rules shown (all, or the selected dimension) with the page header: run info, project info strip, the run summary cards and the score-per-metric cards (with their explanations), then the 14 Rules columns. Built in the browser (`frontend/src/lib/dqExport.ts`): xlsx for Excel, a print window (A3 landscape) for PDF.
- New DQ Run, Generate step: each file shows its status, "columns checked" progress and a live countdown (≈ m:ss left), plus a total time left for the batch. The estimate comes from `/dq/{id}/status` (`columns_done` / `columns_total`, speed so far, and the files queued ahead, since the worker checks one file at a time). The header and final message now reflect failures ("All 3 runs failed", red box) instead of always saying "completed".
- Failed runs explain why: the worker stores a failure category (`dq_runs.error_category`, `backend/app/services/dq_failures.py`), and the Generate step shows its title, explanation, what to do and the technical detail. Categories: source file not found, file could not be read, no data, AI model not installed, AI service refused / not reachable / too slow / error, database busy, BigQuery read failed, unsupported source, unexpected. Only temporary problems (AI service down/slow/error, database busy) are retried automatically; before, every failure was retried twice.
- Files registered in Metadata but missing from the uploads folder are marked "File missing — re-upload in Metadata" at the Data step and cannot be selected; creating a run on such a file returns a clear 400.
- Re-run Check returns a clear 400 ("re-upload it in Metadata") when the source file is no longer in the uploads folder, instead of queuing a run that fails. The 7 existing DQ runs need their files re-uploaded first (`docs/open-items.md` item 13).
- **Source file retention follows the approved ROPA** (`backend/app/services/retention.py`): uploaded source files are kept until the project end date + 30 days while the project has no approved ROPA (draft, submitted, under review or rejected ROPAs do not count). Once a ROPA of the project is approved, they are kept until the end date + the ROPA **Retention Period** (e.g. "5 Years from Account Termination" → end date + 5 years; with several approved ROPAs the longest period applies). The period is read from the first "number + day/week/month/year" in the text (English or Indonesian, e.g. "18 Months", "5 tahun"); a text without a duration ("As required by law") is ignored, the 30-day default applies and the project page shows a warning. The daily `source_file_expiry_check` (07:00 WIB) recalculates the date every day, so approving a ROPA later extends it; the 7-day warning and deletion notifications state which rule applies. Only the raw uploaded files are deleted; metadata, DQ results and governance records stay. The Data Assets Catalog project page (and its PDF) shows **Uploaded Source Files Kept Until** with the rule; API `GET /api/v1/projects/{project_id}/source-file-retention`. The ROPA Retention Period field has a hint explaining this.
- **Business terms: abbreviations in UPPERCASE.** The automatic business term (FR-META-013, `expand_business_term()` in `backend/app/services/metadata_population.py`, also used by the metadata worker) keeps known Indonesian and English abbreviations as one word in capitals instead of "Nik" / "Amount Idr": e.g. `nik` → NIK, `amount_idr` → Amount IDR, `no_ktp` → Number KTP, `npwp_pelanggan` → NPWP Pelanggan, `bpjs_kesehatan_no` → BPJS Kesehatan Number, `ip_address` → IP Address. The list (`ACRONYMS`) covers identity/government/finance terms (NIK, KTP, KK, NPWP, SIM, NIP, BPJS, NIB, PPN, PPh, OJK, BI, BPS, KPR, KUR, RT/RW …), currencies (IDR, USD …) and business/technology terms (SKU, CRM, KPI, SLA, PIC, POS, ATM, API, IP, GPS, OTP, PII …); words that are also normal words (it, do, so, hr, ml) are left out. Expansions such as `cd` → Code and `id` → Identifier are unchanged. Existing records were updated where the term was still the automatic one (7 of 285: PRJ-2026-022 NIK and Amount IDR, PRJ-2026-001 IP Address, PRJ-2026-003 PII Flag ×3, PRJ-2026-019 GPS Tracking Identifier); manually edited terms were not touched.
- **Fix: "HTTP 504" while generating AI definitions.** Generate AI Definitions sends 5 attributes per request; with llama3.2 on CPU (up to 120 s each, Settings > AI Setup) one request can take several minutes, but nginx cut every API request at 120 s. `nginx/nginx.conf` now gives `/api/v1/metadata/regenerate*` 15 minutes (`proxy_read_timeout 900s`); other API calls keep 120 s.
- **Metadata grid: "more" on long text:** Business Definition (80 characters), Standard Format (40) and Sample (30) show the start of the text with a **more / less** toggle, the same `ExpandableText` as the DQ Rules tab (Business Rules, Reasoning); before, they were cut off at two lines or one line. The Table column wraps over several lines instead of being cut off with "…".
- **Rules table fits the screen:** the Rules tab (run page and Project Report) uses fixed column widths (`RULE_COLUMNS` in `frontend/src/components/dq/DQReportParts.tsx`) so all 14–15 columns, including Failed and Status, are visible without scrolling on a desktop screen; long text wraps in its cell (horizontal scroll only below 1100 px).
- **DQ progress page and no double start** (`/dq/progress/{projectId}`, `frontend/src/components/dq/RunProgress.tsx` shared with the New DQ Run Generate step). Before, the Generate step was the only place that showed a running batch; after leaving it there was no way back, and starting the batch again queued duplicate runs (happened on 2026-09-27: 5 duplicates of PRJ-2026-022 behind the first batch). Now:
  - The progress page lists the project's queued/running runs and those finished in the last 12 hours, with the same per-file rows (columns checked, countdown, failure explanation), a total **Time left** and links to each run and the Project Report. The Generate step says it is safe to leave the page.
  - The Data Quality page shows a banner "DQ running for this project · N files · ≈ m:ss left · View progress" while runs are queued or running, and **Run All Data / Run All** become **View Progress**.
  - **No double start:** `POST /dq` and `POST /dq/{id}/rerun` return **409** "A DQ run for '<file>' is already queued/running (version N)…" while that file has a queued or running run (pending runs older than 24 hours do not count). The New DQ Run Data step marks such files "Queued" / "Running now", does not select them, and links to View progress. The Re-run Check button now shows refused re-runs as a message (it failed silently before) and, when accepted, opens the progress page.
  - **Previous version stays visible during a re-run:** the Data Quality table shows, per table, the newest run **with results** (score with its version, e.g. "91.5% v1") and a badge for a newer run without results ("v2 queued", "v2 running", "v2 failed"); the score switches when the new version finishes. The Project Report already used the previous run with results. API: `GET /api/v1/dq/project/{project_id}/progress`; `tables-summary` gained `latest_run_version`, `newer_run_id/status/version`; `sources` gained `active_run_id/status`.
- **Generate AI Definitions shows progress and time left** (Metadata attributes page), like the DQ Generate step: a panel under the toolbar with "x / y definitions generated", model and batch size, elapsed time, a progress bar and **Time left ≈ m:ss** counting down every second. The first estimate is 25 s per definition for local AI (measured with llama3.2:3b on CPU: about 2 minutes per batch of 5) or 5 s for cloud; after each batch it uses the measured speed. Progress is counted from the server's answers (the whole project), so it is correct even when the page shows one table. The page must stay open (the browser sends the batches).
- **Error messages explain the HTTP code.** When a request fails without a readable message from the API, the page shows the code with a short cause and what to do, e.g. "HTTP 504 · Server took too long: the request ran past the time limit (e.g. AI generation on a slow CPU). Refresh to see what was already saved, then try again with fewer items." Covered: 400, 401, 403, 404, 408, 409, 413, 422, 429, 500, 502, 503, 504 (`HTTP_ERROR_HELP` in `frontend/src/lib/api.ts`); API messages (`detail`) are still shown as they are.
- **Metadata and DQ headers without Data Owner position:** the project info strip on the Metadata and Data Quality pages (and the Metadata/DQ exports) shows Data Steward and Data Owner with name and email only. The position stays in the Data Assets Catalog and is used for the DSR sign-off.
- **Fix: uploads failed with "Unexpected token '<' … is not valid JSON" after a container restart.** Nginx kept sending requests to the API's old IP address (static `upstream` blocks resolve `api`/`frontend` only once, when nginx starts; the `resolver` line did not change that), so every API call got nginx's HTML 502 page. `nginx/nginx.conf` now uses `proxy_pass $api_upstream` / `$frontend_upstream` variables with Docker DNS (`resolver 127.0.0.11 valid=10s`), so nginx follows new container IPs by itself; verified by recreating `ag_api` with a changed IP and uploading TEST01 through nginx without restarting it. The frontend now shows a readable message when the server returns a non-JSON error (`errorDetail()` in `frontend/src/lib/api.ts`, used by all API calls, the Metadata Excel upload and login): 502 "The server is not reachable … try again", 413 file too large (25 MB), 429 too many requests, 504 took too long; the login page no longer says "verify credentials" when the server is down.
- **Test data for teammates: `Dummy Data Source/`** (committed). One folder per test project with the fictitious source files and the step-by-step test guide, e.g. `Dummy Data Source/PRJ-2026-022/`: `TEST01_Customer_Master.xlsx` (200 rows, 11 columns), `TEST02_Transactions.xlsx` (600 × 9), `TEST03_Churn_Features.xlsx` (200 × 10), `TEST04_Header_Only.xlsx` (header only, for the "No data found" DQ case) and `TEST_GUIDE.md` (project form, Metadata, DSR, AICK, DPIA, ROPA/retention and DQ steps with expected results). All data is generated (no real people or companies; e-mails use `.example`). Use it to repeat the end-to-end test or to create a new test project. `backend/shared_uploads/` holds the same files as they were uploaded to PRJ-2026-022, so the committed database finds them automatically; `Dummy Data Source/` is the readable copy for people. `DQ Template (Local Only)/` is never committed (it contains a live bot token and client sample data; it is in `.gitignore`).
- **Uploaded files shared through Git** (`backend/shared_uploads/`, `backend/app/services/shared_uploads.py`): uploaded files live in the `uploads_data` volume, which is not committed, so a teammate who pulls the repo database would see the files as missing. For projects with fictitious test data only (never client data), `docker exec ag_api python scripts/share_project_uploads.py PRJ-2026-022` copies the project's files into `backend/shared_uploads/<project_id>/` for committing. On startup the API restores every file that is registered in `project_source_files` but missing from `/app/uploads`. Retention still applies: a file is restored only while its row exists, and the expiry job also deletes the shared copy (commit that deletion). Teammates load a new repo database by stopping the stack and running `docker volume rm datagov-v2_sqlite_data` (the volume is only seeded from `backend/datagov.db` when empty).

---

## Recent Updates (2026-09-25) — SQLite Runtime & Merged Dataset

### PostgreSQL removed — SQLite only
- The whole stack (API, Celery worker, Beat, CI, deploy script) runs on SQLite. Removed: the `db` service, Alembic (`backend/alembic/`, `alembic.ini`), `database/ag_db_dump.sql`, the `asyncpg` / `psycopg2-binary` / `alembic` dependencies and the PostgreSQL-only seed and SQL scripts.
- Models use generic SQLAlchemy types (`Uuid`, `JSON`) instead of the PostgreSQL dialect types. Stored data is unchanged.
- Celery worker tasks (`dq.py`, `metadata.py`, `scheduled.py`) and the maintenance scripts (`reapply_standard_format.py`, `backfill_standard_format.py`, `regenerate_all_definitions.py`) were rewritten from raw `psycopg2` SQL to SQLAlchemy sessions (`get_sync_session()` in `app/database.py`).
- New `sync_schema()` runs at startup: it adds model columns missing from an existing SQLite database (the gap that made v2 fail with `column roles.permissions does not exist`) and creates the `audit_logs` immutability triggers.
- Removed the external PostgreSQL/Supabase source connectors (Metadata "Postgres" option, `/dq/validate-postgres`, DQ `postgres` source). Import such data as Excel/CSV instead. Existing metadata records imported from PostgreSQL are kept and still labelled "Postgres".
- Fixed `source_file_expiry_check`, which queried a non-existent `project_roles` table and failed on every run.
- Added `export-sqlite.ps1` to snapshot the live SQLite database back into the repo.
- Added `scripts/fetch-ollama-model.sh` for downloading Ollama models over one resumable connection on slow networks (see Getting Started, step 4), and `.gitattributes` to keep `.sh` files in LF line endings.
- Documented the two environments (1. Development on SQLite, current; 2. Production on PostgreSQL, planned) in [Environments](#environments), `development.config.yml` and `docs/open-items.md`.

### Merged dataset
- The June 2026 baseline (previously the PostgreSQL dump) and the v2 SQLite test data were merged into one dataset in `backend/datagov.db`, `database/datagov.db` and `database/datagov_sqlite_dump.sql`. See `database/README.md` for counts and merge rules (for example, the June project `PRJ-2026-001` is now `PRJ-2026-019`, and DSR/DPIA tracking IDs were renumbered by creation date).

### Project ID rule
- Project IDs must follow `PRJ-YYYY-NNN` (`YYYY` = Project Year, `NNN` = 3-digit number from `001`). The ID is assigned by the system when a project is saved (next number for that year) and cannot be typed or edited in the UI; the API ignores any `project_code` sent by a client. Changing the Project Year assigns the next ID for the new year. The `Project` model rejects any other format.
- New endpoint `GET /api/v1/projects/next-code?year=YYYY` previews the next ID (shown on the New Project form).
- Existing IDs that broke the rule were renamed: `PRJ-2026-001-A` → `PRJ-2026-019`, `PRJ-000x` → `PRJ-2026-020`, `PRJ-002026-Astra-Infra` → `PRJ-2026-021`.

### Data Quality: project header and new Rules columns
- The project info strip (Project ID, Name, Year, Business Users, Line of Business, Data Steward, Data Owner) is a shared component (`components/details/ProjectInfoStrip.tsx`), shown on the Metadata attributes page and across the DQ menu: run detail (all tabs), overview after a project is selected, and the New DQ Run wizard from step 2.
- Rules tab adds the HSO Splash template columns **Data Type** (`dq_results.data_type`), **Version** (`dq_runs.version`, the DQ update number per project dataset) and **Remarks** (`dq_results.remarks`, automated notes from rule generation, `-` when none). Existing runs: version 1, remarks `-`, data type recovered from the saved AI answer where available.
- Fixed Re-run Check: it now keeps the source file, gets the next Version, and is actually queued to the worker (before, re-runs stayed `pending`). Runs without a source file return a clear 400 message.
- Removed **Model**, **Category** and **Raw Text** (not used in the real rules index): the Rules tab "Model" column, `dq_results.ai_model`, `dq_results.column_category` and `details.raw_text` are gone (columns dropped from the bundled database). The AI answer is still parsed for business rules, regex, complexity and reasoning, just not stored. When AI generation is unavailable, the rule-based fallback is now noted in Remarks instead of Model = "rule-based".

---

## Recent Updates (2026-06-04) — Project-Based DQ Reference Method

### DQ User Flow
- Data Quality is now project-first. The overview page asks the user to select a project and then shows the project's Metadata-imported source tables.
- The New DQ Run wizard no longer starts with source-type cards. Step 1 is project selection, Step 2 is project data selection, then Preview, Generate, Results, and Archive.
- All available project files are selected by default. The user can still deselect specific files before generation.
- Each selected file creates its own DQ run so failures and results remain isolated per dataset.

### Reference Method Integration
- Added `backend/app/services/reference_dq.py` to adapt the provided Existing Data Quality method into the application.
- Telegram notification and external BigQuery upload concerns from the reference folder are intentionally excluded from the app integration.
- The worker maps the reference output into existing `dq_runs`, `dq_results`, and `dq_findings` records; no new DQ schema migration is required.
- The DQ result detail page now exposes regex version, complexity, and reasoning from the reference output.

### Model Availability Caveat
- Superseded on 2026-09-27: DQ now runs on `llama3.2:3b` with the hybrid data-profile regex method (see DQ Reference Method Model Requirements above).
- If the configured model is missing from the Ollama endpoint, DQ generation can fail during Step 4 with an Ollama `/api/generate` 404.
- A larger model can still be used through `DQ_PRIMARY_MODEL`, `DQ_SECONDARY_MODEL`, and `DQ_OLLAMA_BASE_URL`.

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
- Superseded for the 2026-06-04 reference method integration: DQ now uses the DB AI base URL/key but defaulted model names to `qwen2.5-coder:32b` and `llama3.1:70b`. Superseded again on 2026-09-27: DQ uses the Settings > AI Setup model (`llama3.2:3b`) unless DQ env vars override it.

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
- Added `resolver 127.0.0.11 valid=30s ipv6=off` to `nginx.conf` to recover when `api` or `worker` containers are recreated with new IPs (this alone did not work: static `upstream` blocks ignore the resolver; fixed on 2026-09-27, see Recent Updates)

### Source File Persistence & Retention Policy
- **`project_source_files` table** tracks every Excel/CSV file imported per project: original filename, stored path, file size, `uploaded_at`, `uploaded_by`
- **`uploads_data` Docker named volume** mounted at `/app/uploads` on both `api` and `worker`; scoped to `/app/uploads/{project_id}/`; survives container restarts and redeployments
- **`proceed_metadata` endpoint** copies each temp file to the persistent volume after successful import and creates a `project_source_files` record; files are available for future re-runs without re-uploading
- **30-day post-project retention** — source files are automatically deleted 30 days after the project `end_date` (since 2026-09-27: `end_date` + the approved ROPA Retention Period when the project has an approved ROPA); all system-created records (metadata attributes, definitions, DSR, DPIA, AICK, ROPA, BAPD) are **never auto-deleted**
- **7-day advance warning** — `source_file_expiry_check` Celery Beat task runs daily at 07:00 WIB; sends in-app notification and email to the full project team (DGO, DM, PM, SME, Metadata Officer, DQ Officer, PIC Data Compliance, project creator) and all super admins
- **Automatic deletion** — on expiry day: physical files removed from `uploads_data` volume, `project_source_files` records deleted, deletion-confirmed notification sent to the same recipients
- GCP BigQuery imports have no physical files to clean up — their derived `metadata_records` stay permanently

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
- **Source Tables section** always shows **all documented tables for the project across all source types** (GCP and Excel together), driven by a dedicated query independent of the Source Configuration state
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
│   ├── datagov.db         # Bundled SQLite database (seeds the sqlite_data volume)
│   ├── scripts/           # Seed and utility scripts (backfill, regenerate, share_project_uploads)
│   ├── shared_uploads/    # Uploaded test files shared through Git (restored into uploads_data on startup)
│   └── tests/             # Unit and integration tests
├── frontend/
│   └── src/
│       ├── app/           # Next.js App Router pages
│       ├── components/    # Shared UI components
│       ├── lib/           # API client, utilities, PDF export
│       └── store/         # Auth state (Zustand)
├── nginx/                 # Nginx reverse proxy config
├── docs/                  # UAT checklist and open items
├── docker-compose.yml     # Defines: api, worker, beat, frontend, redis, nginx, ollama
└── .env.example
```

### Docker volumes

| Volume | Mount path | Purpose |
|--------|-----------|---------|
| `sqlite_data` | `/data` | Live SQLite database (`datagov.db`); seeded from `backend/datagov.db` on first start |
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

# nginx config changes only (container restarts/recreates need nothing)
docker exec ag_nginx nginx -t && docker exec ag_nginx nginx -s reload
```

> **Note:** Restarting or recreating `api`/`frontend` can give them a new IP address
> (`docker compose restart` does not always keep it). Nginx looks them up by name through
> Docker DNS on every request (cached 10 s, `proxy_pass` with variables in `nginx/nginx.conf`),
> so it follows the new IP without a restart.
>
> **"Unexpected token '<' … is not valid JSON"** in the browser (before 2026-09-27) or
> **"The server is not reachable"** (now) means nginx got no answer from the API (HTTP 502).
> Check `docker ps` (is `ag_api` healthy?) and `docker logs ag_nginx --tail 20`. If the log shows
> `connect() failed (111: Connection refused)` to an IP that is not the API's current IP
> (`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ag_api`), the
> running nginx still has the old config: `docker exec ag_nginx nginx -s reload`.

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
