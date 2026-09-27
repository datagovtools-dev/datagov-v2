# ──────────────────────────────────────────────────────────────────────────────
# AI Governance Tools — Export the live SQLite database (docker-compose.sqlite.yml)
# Copies a consistent snapshot of the running database back into the repo:
#   backend/datagov.db, database/datagov.db, database/datagov_sqlite_dump.sql
# Usage: .\export-sqlite.ps1
# ──────────────────────────────────────────────────────────────────────────────

$ROOT = $PSScriptRoot

# 1. Online backup inside the api container (includes WAL contents, safe while running);
#    the snapshot is switched back to rollback-journal mode so the repo file is a plain single-file DB
docker exec ag_api python -c "import sqlite3; s = sqlite3.connect('/data/datagov.db'); d = sqlite3.connect('/tmp/datagov_export.db'); s.backup(d); d.execute('PRAGMA journal_mode=DELETE'); d.close(); s.close()"
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: backup failed. Is the SQLite stack running (ag_api)?" -ForegroundColor Red
    exit 1
}

# 2. Copy the snapshot into the repo
docker cp ag_api:/tmp/datagov_export.db "$ROOT\backend\datagov.db"
Copy-Item "$ROOT\backend\datagov.db" "$ROOT\database\datagov.db" -Force

# 3. Regenerate the SQL dump from the snapshot
docker exec ag_api python -c "import sqlite3, io; c = sqlite3.connect('/tmp/datagov_export.db'); f = io.open('/tmp/datagov_sqlite_dump.sql', 'w', encoding='utf-8', newline='\n'); [f.write(l + '\n') for l in c.iterdump()]; f.close()"
docker cp ag_api:/tmp/datagov_sqlite_dump.sql "$ROOT\database\datagov_sqlite_dump.sql"
docker exec ag_api rm -f /tmp/datagov_export.db /tmp/datagov_sqlite_dump.sql

Write-Host "Exported live SQLite database to backend/datagov.db, database/datagov.db and database/datagov_sqlite_dump.sql" -ForegroundColor Green
