# Open Items Resolution — P6-011

## Status: Pending DGO/Tech Lead resolution before production deployment

| # | Item | Owner | Required By | Notes |
|---|------|-------|-------------|-------|
| 1 | ~~Ollama model selection (llama3:8b vs mistral:7b)~~ | ~~DevOps / Tech Lead~~ | ~~Before P5 go-live~~ | **RESOLVED 2026-05-25** — Model is now `llama3.2:3b`, DB-driven via Settings > AI Setup. No env var required. Both API and Celery worker read from `ai_provider_configs`. |
| 2 | Email service credentials (SendGrid API key or SMTP) | IT Infrastructure | Before P2 go-live | Set `SENDGRID_API_KEY` or `SMTP_HOST/USER/PASSWORD` in `.env.production`. |
| 3 | GCP IAM setup (service account for BigQuery + GCS) | DevOps / GCP Admin | Before P4 go-live | SA needs `bigquery.dataViewer`, `bigquery.jobUser`, `storage.objectAdmin`. |
| 4 | Server hardware specs for production | IT Infrastructure | Before P6-013 | Minimum: 8 CPU, 32 GB RAM, 500 GB SSD, NVIDIA GPU for Ollama (optional). |
| 5 | PII keyword list — Indonesian additions | DGO / Compliance | Before P5 go-live | Current list in `backend/app/worker/tasks/metadata.py:_PII_KEYWORDS`. Add domain-specific terms. |
| 6 | DSR access provisioning scope | DGO / Data Owner | Before P2 go-live | Define what "access granted" means per dataset type (BigQuery permissions, S3 policy, etc.). |
| 7 | Retention policy matrix | DGO / Legal / Compliance | Before P3 go-live | Seed data in `POST /api/v1/bapd/retention-policies/seed`. Review and update for each dataset type. |
| 8 | Database backup strategy | IT Infrastructure / DevOps | Before P6-013 | Development (SQLite): snapshot with `export-sqlite.ps1` (SQLite backup API, never a plain file copy while running). Production (PostgreSQL, item 10): Cloud SQL automated backups with point-in-time recovery and a tested restore. Define RTO/RPO targets. |
| 9 | ~~DQ reference method model availability~~ | ~~DevOps / Tech Lead~~ | ~~Before DQ production validation~~ | **RESOLVED 2026-09-27** — DQ runs on `llama3.2:3b` (the Metadata model) with the data-profile regex, data facts and repair pass; `qwen2.5-coder:32b` / `llama3.1:70b` are no longer needed. Benchmark and end-to-end results: `docs/data-quality-reference-method.md`. |
| 10 | Production database: move from SQLite to PostgreSQL | Tech Lead / DevOps | Before production go-live | Development runs 100% on SQLite (one writer at a time). Production is planned on PostgreSQL (Cloud SQL recommended). Change list and open decisions: README "Environments > 2. Production". |
| 11 | Failing AI generation tests block CI | Tech Lead / Backend | Before relying on the CI test gate | 3 tests in `backend/tests/unit/test_ai_generation.py` fail (prompt wording "data governance expert" vs current prompt, and cloud API-key checks now reaching Ollama). They also fail on commit `d6ed1e2`, so the GitHub Actions test step fails. Update the tests or the code to match the intended behaviour. The earlier CI steps also fail already on `d6ed1e2`. Measured on 2026-09-27 with the exact CI commands in the api container: `cd backend && ruff check app/` 51 issues on `d6ed1e2`, 49 now; `mypy app/ --ignore-missing-imports` 56 errors on `d6ed1e2`, 49 now (earlier notes said 567/33, counted with other options). The frontend lint step (`npm run lint` = `next lint`) cannot run in CI because the repo has no ESLint config: `next lint` stops at an interactive "How would you like to configure ESLint?" question (also on `d6ed1e2`); add `frontend/.eslintrc.json` (`{"extends": "next/core-web-vitals"}`) and fix what it reports. `npm run type-check` (tsc) passes. Decide whether to fix them or relax the rules in `pyproject.toml`. |
| 12 | Review AI definitions for records with wrong source fields | DGO / Data Stewards | Before publishing the data dictionary | Generated definitions follow the stored `data_type`, sample and format. Example: `customer_profiles.email` in PRJ-2026-001 is stored as `TIMESTAMP`, so its definition describes a date. Correct such fields, then regenerate. |
| 13 | Re-upload source files of the existing DQ runs | DGO / Data Stewards | Before re-running old DQ runs with `llama3.2:3b` | The 7 DQ runs in the database (PRJ-2026-002: 3 files, PRJ-2026-019: 4 files) and all 17 `project_source_files` point to files that are not in the local uploads volume (the uploads were not part of the repo). Re-run returns HTTP 400 "source file missing", the New DQ Run Data step marks them "File missing — re-upload in Metadata", and runs that already failed show "Source file not found". The same applies to PRJ-2026-003 (3 files, test runs on 2026-09-27 failed for this reason). Re-upload the files in Metadata, then start a new DQ run. Originals are in `AI Governance Tools - Option 3 Requirement/`. Since 2026-09-27, files of shared test projects can be committed in `backend/shared_uploads/` (`scripts/share_project_uploads.py`) and are restored on API start, so this does not recur for them; use it only for fictitious test data. |

## Resolution Checklist

- [x] Item 1 resolved — Model is `llama3.2:3b`, DB-driven via Settings UI (2026-05-25)
- [ ] Item 2 resolved — Email credentials configured and tested
- [ ] Item 3 resolved — GCP SA JSON uploaded to production server
- [ ] Item 4 resolved — Hardware provisioned and verified
- [ ] Item 5 resolved — PII keyword list reviewed by DGO team
- [ ] Item 6 resolved — Access provisioning flow documented and implemented
- [ ] Item 7 resolved — Retention policy matrix seeded via API
- [ ] Item 8 resolved — Backup strategy implemented and tested
- [x] Item 9 resolved — DQ runs on `llama3.2:3b`; end-to-end test run completed successfully (2026-09-27)
- [ ] Item 10 resolved — Production running on PostgreSQL with migrations, backups and CI checks in place
- [ ] Item 11 resolved — All backend tests pass and the CI test step is green
- [ ] Item 12 resolved — AI definitions reviewed after correcting wrong source fields
- [ ] Item 13 resolved — Source files re-uploaded and DQ re-run for PRJ-2026-002 and PRJ-2026-019
