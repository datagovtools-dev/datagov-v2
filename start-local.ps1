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
    Write-Host "[1/3] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[1/3] ERROR: Docker Desktop is not running. Please start it first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# 2. Build and start all containers (SQLite database is seeded from backend/datagov.db on first run)
Write-Host ""
Write-Host "[2/3] Starting containers (this takes ~3-5 min on first run)..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: docker compose failed. Check the output above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[2/3] All containers started" -ForegroundColor Green

# 3. Wait for the API (it creates missing tables and the default users on startup)
Write-Host ""
Write-Host "[3/3] Waiting for the API to be ready..." -ForegroundColor Yellow
$retries = 0
do {
    Start-Sleep -Seconds 3
    $retries++
    $ok = $false
    try { $ok = (Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 3).StatusCode -eq 200 } catch {}
} while (-not $ok -and $retries -lt 40)

if ($ok) {
    Write-Host "[3/3] API ready" -ForegroundColor Green
} else {
    Write-Host "WARNING: API is not responding yet. Check: docker compose -f docker-compose.dev.yml logs api" -ForegroundColor Yellow
}

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
