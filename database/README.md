# Database & Dataset

AI Governance Tools uses **SQLite**. This directory holds the bundled dataset.

| File | Format | Used by |
|------|--------|---------|
| `datagov.db` | SQLite database (same file as `backend/datagov.db`) | Seeds the `sqlite_data` Docker volume; native run |
| `datagov_sqlite_dump.sql` | SQL text dump of `datagov.db` | Reviewing changes, rebuilding `datagov.db` |

## Restore & Usage

- **Docker:** on the first `docker compose up`, `backend/datagov.db` is copied into the `sqlite_data` volume (`/data/datagov.db`). After that the volume is the live database.
- **Save the live database into the repo:** run `.\export-sqlite.ps1` from the project root. It writes `backend/datagov.db`, `database/datagov.db` and `database/datagov_sqlite_dump.sql` from one consistent snapshot.
- **Start again from the repo file:** stop the stack, then `docker volume rm datagov-v2_sqlite_data`.
- **Rebuild the file from the SQL dump:**
  ```bash
  # In backend directory
  sqlite3 datagov.db < ../database/datagov_sqlite_dump.sql
  ```

## Contents

| Table | Records | Notes |
|-------|---------|-------|
| `users` | 113 | Admin + team users; passwords bcrypt-hashed |
| `roles` | 11 | Application roles (incl. `requester`); `permissions` empty, so built-in defaults apply |
| `user_project_roles` | 17 | User to role / project assignments |
| `projects` | 10 | See project list below |
| `data_owner_stewards` | 18 | Data Steward + Data Owner per project |
| `data_sharing_requests` | 8 | DSR-2026-0001 to DSR-2026-0006 |
| `dsr_approvals` | 32 | 4-step serial approval records per DSR |
| `data_sharing_agreements` | 0 | DSA attachments linked to DSRs |
| `ai_compliance_checklists` | 8 | Auto-created from DSRs; 3-step serial approval |
| `ai_checklist_approvals` | 24 | Approval step records per AICK |
| `dpia_records` | 8 | DPIA-2026-0001 to DPIA-2026-0006; 2-step approval |
| `dpia_approvals` | 16 | Approval step records per DPIA |
| `ropa_records` | 5 | Record of Processing Activities (PRJ-2026-020) |
| `bapd_records` | 6 | Data extermination/disposal requests |
| `bapd_approvals` | 12 | Dual-approval step records per BAPD |
| `retention_policies` | 8 | Built-in retention policy types |
| `dq_runs` | 11 | Data Quality run jobs; `source_file_id` links to `project_source_files` |
| `dq_results` | 372 | Column-level DQ metrics per run; stores data_type, business_rules, regex_pattern, regex_version, remarks per row |
| `dq_findings` | 98 | Flagged issues from DQ runs |
| `dq_gcp_archives` | 0 | Approved DQ results archived to BigQuery |
| `metadata_records` | 285 | Includes standard_format and distinct_values |
| `project_source_files` | 21 | Excel/CSV upload tracking; stored path + retention metadata |
| `ai_provider_configs` | 1 | AI/LLM settings (local Ollama, `llama3.2:3b`); no API key stored |
| `notifications` | 27 | In-app notification messages |
| `notification_preferences` | 0 | Per-user notification opt-in/opt-out settings |
| `audit_logs` | 2804 | Full activity history across all modules; rows cannot be updated or deleted (SQLite triggers) |

## Projects & Metadata Records

Project IDs follow `PRJ-<Project Year>-<3-digit number>` and are assigned by the system (see the Project ID rule below).

| Project | Attributes | Tables | Source |
|---------|-----------:|-------:|--------|
| PRJ-2026-001 - AI-Powered Customer Analytics Platform (Telco Nusantara Group) | 27 | 4 | BigQuery, legacy "Postgres" import |
| PRJ-2026-002 - Smart Credit Risk Analytics Platform | 33 | 3 | Excel |
| PRJ-2026-003 - Enterprise Data Governance Implementation | 33 | 3 | Excel |
| PRJ-2026-004 - Customer 360 Analytics and Personalization Platform | 40 | 4 | Excel |
| PRJ-2026-018 - Enterprise Data Integration Platform Implementation | 27 | 3 | Excel |
| PRJ-2026-019 - AI-Powered Customer Analytics Platform (PT Maju Bersama Digital) | 93 | 4 | Excel |
| PRJ-2026-020 - DIDX | 0 | 0 | - |
| PRJ-2026-021 - A-Infra | 0 | 0 | - |

### Project ID rule (2026-09-25)

- Format `PRJ-YYYY-NNN`: `YYYY` is the Project Year, `NNN` a 3-digit number from `001`. Anything else is rejected by the `Project` model.
- New projects get the next number for their year (highest used number + 1, e.g. `PRJ-2026-022`); users cannot type or edit the ID. Changing a project's year assigns the next ID for the new year.
- Three older IDs that broke the rule were renamed (recorded in `audit_logs`): `PRJ-2026-001-A` → `PRJ-2026-019`, `PRJ-000x` → `PRJ-2026-020`, `PRJ-002026-Astra-Infra` → `PRJ-2026-021`.

Two PRJ-2026-001 tables have `source_type = 'postgresql'` from before the PostgreSQL connector was removed. The records are kept as documentation; to refresh them, export the source tables to Excel/CSV and import them again.

## Merge History (2026-09-25)

This dataset combines two sources that had diverged:

- **June 2026 baseline** (2026-06-02): 113 users, 5 projects, metadata and DQ data.
- **v2 test data** (`datagov.db` from commit `d6ed1e2`, created 2026-08-30): new projects PRJ-000x and PRJ-002026-Astra-Infra (now PRJ-2026-020 and PRJ-2026-021), BAPD dual-approval, ROPA and retention-policy records.

Merge rules:
- Users in both sources (the 8 trial accounts) kept the v2 record; June records that referenced them were re-linked.
- Roles were matched by name; `requester` existed only in the June data and was added.
- `PRJ-2026-001` existed in both as different projects. The v2 project (Telco Nusantara Group) kept the code; the June project (PT Maju Bersama Digital) became `PRJ-2026-001-A` (later `PRJ-2026-019`) with all its DSR, DPIA, DQ, metadata and source-file records.
- DSR and DPIA tracking IDs were renumbered by creation date (June records 0001-0004, v2 records 0005-0006), including references in checklists, notifications and audit-log text.
- June audit-log entries were renumbered after the v2 entries.

## Key Field Notes

- IDs are stored as 32-character hex strings (no dashes), booleans as 0/1, JSON columns as text.
- `metadata_records.standard_format` - populated automatically from multi-signal column analysis during import: Boolean, Category, Phone, Date, Email, Integer, Decimal, ID/Code, Free text
- `metadata_records.distinct_values` - stored for Category/Boolean columns and any column with <= 25 unique values
- `metadata_records.is_primary_key` - heuristic: all non-null values in the import sample are unique
- `metadata_records.is_nullable` - heuristic: any null or blank value present in the import sample
- `ai_provider_configs` - single row; UI-editable via Settings > AI Setup; read by the metadata and DQ Celery workers
- `dq_results.check_type` - dimension name: `completeness` | `consistency` | `uniqueness` | `latency`
- `dq_results.actual_value` - index score as string (0.00-100.00); use `CAST(actual_value AS REAL)` for queries
- `dq_results.business_rules` - AI-generated or rule-based business rule text per column per dimension
- `dq_results.regex_pattern` - AI-generated regex (Consistency only); stripped of `r'...'` wrapper, stored as raw `^...$` pattern
- `dq_results.regex_version` - `New Version` or `Old Version`
- `dq_results.details` JSON - stores AI/rule evaluation metadata, including complexity and reasoning from the reference DQ method (the raw AI answer is not stored)
- Removed 2026-09-25 (not used in the real rules index): `dq_results.ai_model` (Model), `dq_results.column_category` (Category) and `details.raw_text` (Raw Text)
- `project_source_files.stored_path` - files live at `/app/uploads/{project_id}/{uuid}_{filename}` on the `uploads_data` volume; the physical files are not part of this dataset, except the files of shared test projects in `backend/shared_uploads/` (restored into the volume on API startup)
- Retention of those files: project `end_date` + 30 days, or `end_date` + the `retention_period` of the project's approved ROPA (`backend/app/services/retention.py`)
- `dq_runs.source_file_id` - nullable reference to `project_source_files.id`; set by the "From Project Files" flow
- `dq_runs.version` - DQ update number for a dataset within a project: 1 for the first run, +1 per re-run (template column "Version"). Existing runs were set to 1
- `dq_runs.columns_total`, `dq_runs.columns_done` - progress of a run (columns analysed so far), used for the Generate step progress bar and time estimate. Added 2026-09-27 by `sync_schema()`; empty for older runs
- `data_owner_stewards.position` - job title of the Data Owner / Lead Business Steward (e.g. "CRM Department Head"), optional. Added 2026-09-27 by `sync_schema()`; empty for existing owners
- `dq_runs.empty_attributes` - JSON list of attributes whose values are all empty (blank, null, spaces, 'NULL', 'N/A', ...), shown in the Blank Attributes card; every check on such an attribute has status `no_data`. Added 2026-09-27; empty for older runs
- `dq_runs.error_category`, `dq_runs.error_message` - why a run failed (category key from `backend/app/services/dq_failures.py` and the technical detail). Added 2026-09-27; empty for older runs (the status endpoint then checks whether the source file is missing)
- `dq_results.data_type` - pandas dtype of the column (e.g. `object`, `int64`, `float64`; template column "Data Type"). For runs before 2026-09-25 it was recovered from the then-saved AI answer where available (136 of 299 rules); otherwise empty
- `dq_results.remarks` - automated notes written while the rules are generated (invalid or missing AI regex, scientific-notation or timestamp regex fallback, second-model recheck and its outcome, skipped large datasets, latest date for Latency); `-` when there is nothing to note
- `roles.permissions` - JSON list of custom permissions per role; empty means the built-in defaults in `app/core/rbac.py` apply

## Notes

- Refreshed on 2026-09-25 from the merged dataset with `export-sqlite.ps1`.
- Refreshed again on 2026-09-27 to add the new `dq_runs` columns (`columns_total`, `columns_done`, `error_category`, `error_message`, `empty_attributes`). Three failed PRJ-2026-003 test runs from that day (source files missing) were left out of the snapshot; their `audit_logs` entries stay, because audit rows cannot be deleted.
- When the data changes, commit `backend/datagov.db`, `database/datagov.db` and `database/datagov_sqlite_dump.sql` together and update the counts in this README in the same commit.
- Refreshed again on 2026-09-27 for `data_owner_stewards.position`.
- **Latest refresh (2026-09-27, evening):** the test project **PRJ-2026-022** "Retail Customer Churn Prediction" (fictitious data) is now part of the dataset with everything linked to it: owners (with Data Owner position), 32 metadata attributes with AI definitions (tables TEST01–TEST04; TEST04 is header-only on purpose), DSR-2026-0007 with its AICK, DPIA with governance activities, approvals, and 4 DQ runs (TEST01 94.2%, TEST02 91.7%, TEST03 93.5%, TEST04 failed "No data found" as expected). Its uploaded files are in `backend/shared_uploads/<project_id>/` (restored into the uploads volume on API start); the readable copies and the test guide are in `Dummy Data Source/PRJ-2026-022/`. `metadata_records.business_term` now keeps abbreviations in UPPERCASE where the term was still the automatic one (PRJ-2026-001 "IP Address", PRJ-2026-003 "PII Flag" ×3, PRJ-2026-019 "GPS Tracking Identifier", PRJ-2026-022 "NIK", "Amount IDR"). The three failed PRJ-2026-003 runs are still left out. The next new 2026 project gets `PRJ-2026-023`.
- **Refresh 2026-09-29:** adds the sample project **PRJ-2026-023** "Credit Card Fraud Detection" (fictitious, entered in the UI from `Dummy Data Source/PRJ-2026-023/PRJ-2026-023_Filling_Guide.pdf`): project, team, Data Steward and Data Owner, DSR-2026-0008 with its AICK and approval steps, and the project's DPIA draft. No Metadata or uploaded files yet. The next new 2026 project gets `PRJ-2026-024`.
- To load this dataset on a machine that already ran the stack: stop it, `docker volume rm datagov-v2_sqlite_data`, start again (the volume is only seeded from `backend/datagov.db` when empty).
- Do not export failed DQ test runs or test projects into the baseline unless those records are intentionally part of it (remove them from the snapshot, following the foreign keys, not from the live database).
