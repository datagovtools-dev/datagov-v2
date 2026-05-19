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
| `projects` | 4 | PRJ-2026-001, 002, 003, 018 |
| `data_owner_stewards` | 8 | Data Steward (lead_business_steward) + Data Owner per project |
| `data_sharing_requests` | 3 | DSR-2026-0001 to 0003; with full checklist JSON |
| `ai_compliance_checklists` | 3 | Linked to DSRs, includes sign-off |
| `ai_checklist_approvals` | — | Approval step stubs |
| `dpia_records` | 3 | Auto-created from DSRs |
| `dpia_approvals` | — | Approval step stubs |
| `dsr_approvals` | — | Approval steps |
| `metadata_records` | 186 | 4 projects: PRJ-001 (93), PRJ-002 (33), PRJ-003 (33), PRJ-018 (27) — includes standard_format values |
| `audit_logs` | 1120 | Full activity history |

## Metadata Records Breakdown

| Project | Attributes | Source |
|---------|-----------|--------|
| PRJ-2026-001 — AI-Powered Customer Analytics Platform | 93 | Excel (4 tables) |
| PRJ-2026-002 — Smart Credit Risk Analytics Platform | 33 | Excel |
| PRJ-2026-003 — Enterprise Data Governance Implementation | 33 | Excel |
| PRJ-2026-018 — Enterprise Data Integration Platform Implementation | 27 | Excel (3 files) |

## Notes

- Run `alembic upgrade head` before restoring if starting from a fresh database
- This dump uses `--no-owner --no-acl` so it restores cleanly under any PostgreSQL user
- `data_owner_stewards` table: Data Steward and Data Owner assigned to each project (name + email)
- `metadata_records.standard_format`: populated automatically from column value analysis during import
- Generated: 2026-05-19 (post Metadata UI overhaul)
