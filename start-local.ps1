# ──────────────────────────────────────────────────────────────────────────────
# AI Governance Tools — Local Startup Script (Windows PowerShell)
# Usage: Right-click → "Run with PowerShell"  OR  .\start-local.ps1
# ──────────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  AI Governance Tools — Local Startup" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Docker is running
try {
    docker info 2>&1 | Out-Null
    Write-Host "[1/5] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[1/5] ERROR: Docker Desktop is not running. Please start it first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 2. Build and start all containers
Write-Host ""
Write-Host "[2/5] Starting containers (this takes ~3-5 min on first run)..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: docker compose failed. Check the output above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[2/5] All containers started" -ForegroundColor Green

# 3. Wait for database to be ready
Write-Host ""
Write-Host "[3/5] Waiting for database to be ready..." -ForegroundColor Yellow
$retries = 0
do {
    Start-Sleep -Seconds 3
    $retries++
    $result = docker compose -f docker-compose.dev.yml exec -T db pg_isready -U ag_user -d ag_db 2>&1
} while ($result -notmatch "accepting connections" -and $retries -lt 20)

if ($retries -ge 20) {
    Write-Host "WARNING: Database may not be ready yet. Continuing anyway..." -ForegroundColor Yellow
} else {
    Write-Host "[3/5] Database ready" -ForegroundColor Green
}

# 4. Run database migrations
Write-Host ""
Write-Host "[4/5] Running database migrations..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml exec -T api alembic upgrade head
if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Migration may have already been applied or failed. Check logs." -ForegroundColor Yellow
} else {
    Write-Host "[4/5] Migrations applied" -ForegroundColor Green
}

# 5. Seed admin user
Write-Host ""
Write-Host "[5/5] Creating admin user..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml exec -T api python scripts/seed_admin.py
Write-Host "[5/5] Admin user ready" -ForegroundColor Green

# 6. Pull Ollama model in background
Write-Host ""
Write-Host "[Optional] Pulling Ollama LLM model in background (llama3:8b ~4GB)..." -ForegroundColor Yellow
Start-Job -ScriptBlock {
    docker exec ag_ollama_dev ollama pull llama3:8b
} | Out-Null
Write-Host "           Model pull started in background. AI definitions will work once complete." -ForegroundColor DarkYellow

# Done
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  Application is READY!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Frontend UI  : http://localhost:3000" -ForegroundColor Cyan
Write-Host "  API          : http://localhost:8000" -ForegroundColor Cyan
Write-Host "  API Docs     : http://localhost:8000/api/v1/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Login Email  : admin@governance.local" -ForegroundColor White
Write-Host "  Password     : Admin1234!" -ForegroundColor White
Write-Host ""
Write-Host "  Change the password after first login!" -ForegroundColor Yellow
Write-Host ""

# Open browser
Start-Process "http://localhost:3000"

Write-Host "Press Enter to exit this window (containers keep running)"
Read-Host
