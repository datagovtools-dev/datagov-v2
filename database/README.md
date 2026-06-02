# Database Dump

`ag_db_dump.sql` is a PostgreSQL dump of the AI Governance Tools database, refreshed from the `datagov-tools` Supabase project.

## Restore

```bash
# From inside the project folder (with Docker running):
docker exec -i ag_db psql -U ag_user -d ag_db < database/ag_db_dump.sql
```

## Contents

| Table | Records | Notes |
|-------|---------|-------|
| `users` | 113 | Admin + team users; passwords bcrypt-hashed |
| `roles` | 11 | Application roles |
| `user_project_roles` | 9 | Many-to-many user to project role assignments |
| `projects` | 5 | PRJ-2026-001, 002, 003, 004, 018 |
| `data_owner_stewards` | 10 | Data Steward + Data Owner per project |
| `data_sharing_requests` | 4 | DSR workflow records |
| `dsr_approvals` | 16 | 4-step serial approval records per DSR |
| `data_sharing_agreements` | 0 | DSA attachments linked to DSRs |
| `ai_compliance_checklists` | 4 | Auto-created from DSRs; 3-step serial approval |
| `ai_checklist_approvals` | 12 | Approval step records per AICK |
| `dpia_records` | 4 | Auto-created from DSRs; 2-step approval |
| `dpia_approvals` | 8 | Approval step records per DPIA |
| `ropa_records` | 0 | Record of Processing Activities |
| `bapd_records` | 0 | Data extermination/disposal requests |
| `bapd_approvals` | 0 | Dual-approval step records per BAPD |
| `retention_policies` | 0 | Retention policy records |
| `dq_runs` | 7 | Data Quality run jobs per project/source; `source_file_id` FK links to `project_source_files` |
| `dq_results` | 299 | Column-level DQ metrics per run; stores business_rules, regex_pattern, ai_model, regex_version per row |
| `dq_findings` | 92 | Flagged issues from DQ runs |
| `dq_gcp_archives` | 0 | Approved DQ results archived to BigQuery |
| `metadata_records` | 226 | 5 projects; includes standard_format and distinct_values |
| `project_source_files` | 17 | Excel/CSV upload tracking; stored path + retention metadata |
| `ai_provider_configs` | 1 | AI/LLM settings (provider, model, base URL, API key, batch size) |
| `notifications` | 0 | In-app notification messages |
| `notification_preferences` | 0 | Per-user notification opt-in/opt-out settings |
| `audit_logs` | 2102 | Full activity history across all modules |
| `alembic_version` | 1 | Alembic migration state |

## Metadata Records Breakdown

| Project | Attributes | Tables | Source |
|---------|-----------:|-------:|--------|
| PRJ-2026-001 - AI-Powered Customer Analytics Platform | 93 | 4 | Excel |
| PRJ-2026-002 - Smart Credit Risk Analytics Platform | 33 | 3 | Excel |
| PRJ-2026-003 - Enterprise Data Governance Implementation | 33 | 3 | Excel |
| PRJ-2026-004 - Customer 360 Analytics and Personalization Platform | 40 | 4 | Excel |
| PRJ-2026-018 - Enterprise Data Integration Platform Implementation | 27 | 3 | Excel |

## Key Field Notes

- `metadata_records.standard_format` - populated automatically from multi-signal column analysis during import: Boolean, Category, Phone, Date, Email, Integer, Decimal, ID/Code, Free text
- `metadata_records.distinct_values` - stored for Category/Boolean columns and any column with <= 25 unique values
- `metadata_records.is_primary_key` - heuristic: all non-null values in the import sample are unique
- `metadata_records.is_nullable` - heuristic: any null or blank value present in the import sample
- `ai_provider_configs` - single row; UI-editable via Settings > AI Setup; read by both FastAPI metadata Celery worker and DQ Celery worker
- `dq_results.check_type` - dimension name: `completeness` | `consistency` | `uniqueness` | `latency`
- `dq_results.actual_value` - index score as string (0.00-100.00); use `CAST(actual_value AS NUMERIC)` for queries
- `dq_results.business_rules` - AI-generated or rule-based business rule text per column per dimension
- `dq_results.regex_pattern` - AI-generated regex (Consistency only); stripped of `r'...'` wrapper, stored as raw `^...$` pattern
- `dq_results.ai_model` - model name used or `rule-based` if Ollama was unavailable
- `dq_results.regex_version` - `New Version` or `Old Version`
- `dq_results.column_category` - reserved field for future automated category classification
- `dq_results.details` JSONB - stores AI/rule evaluation metadata
- `project_source_files.stored_path` - files live at `/app/uploads/{project_id}/{uuid}_{filename}` on the `uploads_data` volume
- `dq_runs.source_file_id` - nullable FK to `project_source_files.id`; set by the "From Project Files" flow; migration `b6c7d8e9f0a1`

## Notes

- Run `alembic upgrade head` before restoring if starting from a fresh database
- This dump uses `--no-owner --no-acl` so it restores cleanly under any PostgreSQL user
- Refreshed from local Docker database container `ag_db` on 2026-06-02
- Verified current Supabase/Alembic head: `b6c7d8e9f0a1`
