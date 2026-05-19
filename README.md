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
| **Projects** | Central project registry — create and manage data governance projects with team assignments (DGO, DM, SME, PIC) |
| **Data Sharing Request (DSR)** | End-to-end data sharing request lifecycle with serial 4-step approval workflow and client sign-off |
| **AI/ML Compliance Checklist (AICK)** | GEN AI usage assessment checklist linked to each DSR — 3-step serial approval with sign-off |
| **Data Protection Impact Assessment (DPIA)** | Auto-created from DSR; tracks residual risk, data categories, and 2-step governance approval |
| **Record of Processing Activities (ROPA)** | Document and track all data processing activities |
| **Data Extermination / BAPD** | Manage data disposal/extermination requests with evidence upload and approval |
| **Data Quality (DQ)** | Connect to GCP BigQuery, PostgreSQL, or Supabase and run automated data quality checks |
| **Metadata Management** | Auto-populate data dictionaries from GCP BigQuery, PostgreSQL, or Excel/CSV files; enrich with AI-generated business definitions via local LLM (Ollama) |

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
- **AI-generated metadata definitions** — bulk-generate business definitions for all data attributes using local Ollama LLM
- **Multi-source metadata ingestion** — GCP BigQuery, PostgreSQL/Supabase, Excel/CSV (multi-file, multi-sheet)
- **RBAC** — role-based access control enforced on both frontend and backend
- **PDF export** — export any DSR, AI Checklist, or DPIA to a formatted PDF
- **Audit trail** — all changes logged with user, timestamp, and action
- **Notification system** — in-app notifications for approval actions and status changes
- **Data Quality checks** — automated DQ profiling against BigQuery, PostgreSQL, or Supabase

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
