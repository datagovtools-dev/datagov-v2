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
| `users` | Admin + team users | Passwords are bcrypt-hashed |
| `projects` | PRJ-2026-001 to PRJ-2026-003 | UAT projects |
| `data_sharing_requests` | DSR-2026-0001, DSR-2026-0002 | With full checklist JSON |
| `ai_compliance_checklists` | 2 records | Linked to DSRs, includes sign-off |
| `ai_checklist_approvals` | 3 rows | Approval step stubs |
| `dpia_records` | 2 records | Auto-created from DSRs |
| `dpia_approvals` | 2 rows | Approval step stubs |
| `dsr_approvals` | 4 rows | Approval steps for DSR-2026-0001/0002 |
| `metadata_records` | 120 rows | PRJ-001 Excel metadata with AI definitions |
| `audit_logs` | ~939 rows | Full activity history |

## Notes

- Run `alembic upgrade head` before restoring if starting from a fresh database
- This dump uses `--no-owner --no-acl` so it restores cleanly under any PostgreSQL user
- Generated: 2026-05-19
