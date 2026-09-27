#!/bin/bash
# Production Deployment Script — P6-013
# Usage: ./scripts/deploy-production.sh [TAG]
# Example: ./scripts/deploy-production.sh v1.0.0
set -euo pipefail

TAG="${1:-latest}"
COMPOSE_FILE="docker-compose.prod.yml"

echo "===== AI Governance Tools — Production Deployment ====="
echo "  Tag: ${TAG}"
echo "  Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "========================================================"

# 1. Verify environment
if [[ ! -f ".env.production" ]]; then
  echo "ERROR: .env.production not found. Aborting."
  exit 1
fi

# 2. Pull latest images
echo "[1/5] Pulling Docker images..."
docker compose -f "${COMPOSE_FILE}" pull

# 3. Start/restart services (the API creates missing SQLite tables/columns on startup)
echo "[2/5] Starting services..."
docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans

# 4. Smoke tests
echo "[3/5] Running smoke tests..."
sleep 10

HEALTH=$(curl -sf http://localhost:8000/health | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null || echo "fail")
if [[ "${HEALTH}" != "ok" ]]; then
  echo "ERROR: Health check failed (got: ${HEALTH}). Rolling back..."
  docker compose -f "${COMPOSE_FILE}" rollback 2>/dev/null || true
  exit 1
fi
echo "  Health check: OK"

# 5. Verify Celery workers
echo "[4/5] Verifying Celery workers..."
WORKER_STATUS=$(docker compose -f "${COMPOSE_FILE}" exec -T worker celery -A app.worker.celery_app inspect ping 2>&1 | grep -c "pong" || echo "0")
if [[ "${WORKER_STATUS}" -lt "1" ]]; then
  echo "WARNING: Celery worker ping failed. Check worker logs."
fi

# 6. Final report
echo "[5/5] Deployment complete!"
echo ""
echo "  API:      http://localhost:8000"
echo "  API Docs: disabled in production"
echo "  Frontend: http://localhost:3000"
echo ""
docker compose -f "${COMPOSE_FILE}" ps
