# ──────────────────────────────────────────────────────────────────────────────
# AI Governance Tools — Native Startup (No Docker Required)
# Runs backend on http://localhost:8000  |  frontend on http://localhost:3000
# ──────────────────────────────────────────────────────────────────────────────

$ROOT     = $PSScriptRoot
$BACKEND  = "$ROOT\backend"
$FRONTEND = "$ROOT\frontend"
$ENV_FILE = "$ROOT\.env.local"

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "  AI Governance Tools -- Starting (No Docker)" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Load .env.local into current session
if (Test-Path $ENV_FILE) {
    Get-Content $ENV_FILE | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
            $name  = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"')
            [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    Write-Host "[OK] Loaded .env.local" -ForegroundColor Green
} else {
    Write-Host "[ERROR] .env.local not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check DATABASE_URL is filled in
$dbUrl = [System.Environment]::GetEnvironmentVariable("DATABASE_URL", "Process")
if ($dbUrl -like "*YOUR-PASSWORD*" -or $dbUrl -like "*XXXX*") {
    Write-Host ""
    Write-Host "[ERROR] Replace [YOUR-PASSWORD] in .env.local with your Supabase password first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "[OK] Database URL configured" -ForegroundColor Green

# ── Write temp batch files (avoids PowerShell quoting issues with spaces in paths) ──

$backendPs1 = "$env:TEMP\ag_backend.ps1"
$frontendBat = "$env:TEMP\ag_frontend.bat"

# Backend: use a PowerShell script so % characters in passwords are preserved
@"
`$envFile = "$ENV_FILE"
Get-Content `$envFile | ForEach-Object {
    if (`$_ -match '^\s*([^#=][^=]*)=(.+)`$') {
        `$n = `$matches[1].Trim(); `$v = `$matches[2].Trim().Trim('"')
        [System.Environment]::SetEnvironmentVariable(`$n, `$v, "Process")
    }
}
`$env:PYTHONPATH = "$BACKEND"
Set-Location "$BACKEND"
Write-Host "Backend starting on http://localhost:8000" -ForegroundColor Cyan
py -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
Read-Host "Press Enter to close"
"@ | Set-Content -Path $backendPs1 -Encoding UTF8

# Frontend batch (no % in values, safe to use cmd)
$envLines = Get-Content $ENV_FILE | Where-Object { $_ -match '^\s*([^#][^=]+)=(.+)$' } | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
        "SET $($matches[1].Trim())=$($matches[2].Trim().Trim('"'))"
    }
}
$envBlock = $envLines -join "`r`n"
@"
@echo off
title AI Governance -- Frontend (port 3000)
$envBlock
cd /d "$FRONTEND"
echo Starting Next.js frontend...
npm run dev
pause
"@ | Set-Content -Path $frontendBat -Encoding ASCII

# Run migrations
Write-Host ""
Write-Host "[1/3] Running database migrations..." -ForegroundColor Yellow
$env:PYTHONPATH = $BACKEND
Set-Location $BACKEND
py -m alembic upgrade head
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Migration may already be applied -- continuing." -ForegroundColor Yellow
} else {
    Write-Host "[OK] Migrations applied" -ForegroundColor Green
}

# Seed admin user
Write-Host ""
Write-Host "[2/3] Creating admin user..." -ForegroundColor Yellow
py scripts/seed_admin.py
Write-Host "[OK] Admin user ready" -ForegroundColor Green

# Launch backend and frontend in separate windows
Write-Host ""
Write-Host "[3/3] Launching backend and frontend..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $backendPs1
Start-Sleep -Seconds 4
Start-Process cmd -ArgumentList "/k", $frontendBat
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "  Application is starting!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Frontend : http://localhost:3000" -ForegroundColor Cyan
Write-Host "  API Docs : http://localhost:8000/api/v1/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Email    : admin@governance.local" -ForegroundColor White
Write-Host "  Password : Admin1234!" -ForegroundColor White
Write-Host ""

Start-Process "http://localhost:3000"
Read-Host "Press Enter to close this window (servers keep running in their own windows)"
