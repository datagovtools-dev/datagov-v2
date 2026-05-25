# Database Dump

`ag_db_dump.sql` is a full PostgreSQL dump of the AI Governance Tools database including schema, seed data, and UAT records.

## Restore

```bash
# From inside the project folder (with Docker running):
docker exec -i ag_db psql -U ag_user -d ag_db < database/ag_db_dump.sql
```

## Contents

| Table | Records | Notes |
|-------|---------|-------|
| `users` | 113 | Admin + team users; passwords bcrypt-hashed |
| `roles` | 5 | super_admin, admin, compliance_officer, dpo, viewer |
| `user_project_roles` | — | Many-to-many: user ↔ project role assignments |
| `projects` | 5 | PRJ-2026-001, 002, 003, 004, 018 |
| `data_owner_stewards` | 8 | Data Steward + Data Owner per project (free-text name + email) |
| `data_sharing_requests` | 4 | DSR-2026-0001 to 0004; includes full checklist JSON |
| `dsr_approvals` | — | 4-step serial approval records per DSR |
| `data_sharing_agreements` | — | DSA attachments linked to DSRs |
| `ai_compliance_checklists` | 3 | Auto-created from DSRs; 3-step serial approval |
| `ai_checklist_approvals` | — | Approval step records per AICK |
| `dpia_records` | 4 | Auto-created from DSRs; 2-step approval |
| `dpia_approvals` | — | Approval step records per DPIA |
| `ropa_records` | — | Record of Processing Activities |
| `bapd_records` | — | Data extermination/disposal requests |
| `bapd_approvals` | — | Dual-approval step records per BAPD |
| `retention_policies` | 8 | Built-in retention policy types (seeded) |
| `dq_runs` | — | Data Quality run jobs per project/source |
| `dq_results` | — | Column-level DQ metrics per run |
| `dq_findings` | — | Flagged issues from DQ runs |
| `dq_gcp_archives` | — | Approved DQ results archived to BigQuery |
| `metadata_records` | 226 | 5 projects — includes standard_format and distinct_values |
| `project_source_files` | 21 | Excel/CSV upload tracking; stored path + retention metadata |
| `ai_provider_configs` | 1 | AI/LLM settings (provider, model, base URL, API key, batch size) |
| `notifications` | — | In-app notification messages |
| `notification_preferences` | — | Per-user notification opt-in/opt-out settings |
| `audit_logs` | 1719 | Full activity history across all modules |
| `alembic_version` | — | Alembic migration state (system table) |

## Metadata Records Breakdown

| Project | Attributes | Tables | Source |
|---------|-----------|--------|--------|
| PRJ-2026-001 — AI-Powered Customer Analytics Platform | 93 | 4 | Excel (4 files) |
| PRJ-2026-002 — Smart Credit Risk Analytics Platform | 33 | 3 | Excel (3 files) |
| PRJ-2026-003 — Enterprise Data Governance Implementation | 33 | 3 | Excel (3 files) |
| PRJ-2026-004 — Customer 360 Analytics and Personalization Platform | 40 | 4 | Excel (4 files) |
| PRJ-2026-018 — Enterprise Data Integration Platform Implementation | 27 | 3 | Excel (3 files) |

## Key Field Notes

- `metadata_records.standard_format` — populated automatically from multi-signal column analysis during import: Boolean (specific label per data values), Category (column-name hints + cardinality thresholds), Phone (separator required), Date, Email, Integer, Decimal, ID/Code, Free text
- `metadata_records.distinct_values` — stored for all Category/Boolean columns AND any column with ≤ 25 unique values; enables the UI combobox to suggest values when a column is reclassified to Category
- `metadata_records.is_primary_key` — heuristic: all non-null values in the import sample are unique
- `metadata_records.is_nullable` — heuristic: any null or blank value present in the import sample
- `ai_provider_configs` — single row; UI-editable via Settings > AI Setup; read by both FastAPI and Celery worker
- `project_source_files.stored_path` — files live at `/app/uploads/{project_id}/{uuid}_{filename}` on the `uploads_data` volume; auto-deleted 30 days after project `end_date`

## Notes

- Run `alembic upgrade head` before restoring if starting from a fresh database
- This dump uses `--no-owner --no-acl` so it restores cleanly under any PostgreSQL user
- Generated: 2026-05-25
