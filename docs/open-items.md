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
| 8 | PostgreSQL backup strategy | IT Infrastructure / DevOps | Before P6-013 | Minimum: daily WAL archiving to GCS + weekly base backup. Define RTO/RPO targets. |
| 9 | DQ reference method model availability | DevOps / Tech Lead | Before DQ production validation | Provide `qwen2.5-coder:32b` and `llama3.1:70b` through local Ollama or an Ollama-compatible cloud endpoint. Without these models, DQ file runs can fail at Generate with `/api/generate` 404. |

## Resolution Checklist

- [x] Item 1 resolved — Model is `llama3.2:3b`, DB-driven via Settings UI (2026-05-25)
- [ ] Item 2 resolved — Email credentials configured and tested
- [ ] Item 3 resolved — GCP SA JSON uploaded to production server
- [ ] Item 4 resolved — Hardware provisioned and verified
- [ ] Item 5 resolved — PII keyword list reviewed by DGO team
- [ ] Item 6 resolved — Access provisioning flow documented and implemented
- [ ] Item 7 resolved — Retention policy matrix seeded via API
- [ ] Item 8 resolved — Backup strategy implemented and tested
- [ ] Item 9 resolved — Required DQ reference models installed locally or configured through cloud/API and PRJ-001 test run completed successfully
