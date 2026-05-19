# AI Governance Tools — Stop local containers
Write-Host "Stopping AI Governance Tools containers..." -ForegroundColor Yellow
docker compose -f docker-compose.dev.yml down
Write-Host "All containers stopped." -ForegroundColor Green
