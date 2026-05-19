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
echo "[1/6] Pulling Docker images..."
docker compose -f "${COMPOSE_FILE}" pull

# 3. Run database migrations
echo "[2/6] Running Alembic migrations..."
docker compose -f "${COMPOSE_FILE}" run --rm api alembic upgrade head

# 4. Start/restart services
echo "[3/6] Starting services..."
docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans

# 5. Smoke tests
echo "[4/6] Running smoke tests..."
sleep 10

HEALTH=$(curl -sf http://localhost:8000/health | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))" 2>/dev/null || echo "fail")
if [[ "${HEALTH}" != "ok" ]]; then
  echo "ERROR: Health check failed (got: ${HEALTH}). Rolling back..."
  docker compose -f "${COMPOSE_FILE}" rollback 2>/dev/null || true
  exit 1
fi
echo "  Health check: OK"

# 6. Verify Celery workers
echo "[5/6] Verifying Celery workers..."
WORKER_STATUS=$(docker compose -f "${COMPOSE_FILE}" exec -T worker celery -A app.worker.celery_app inspect ping 2>&1 | grep -c "pong" || echo "0")
if [[ "${WORKER_STATUS}" -lt "1" ]]; then
  echo "WARNING: Celery worker ping failed. Check worker logs."
fi

# 7. Final report
echo "[6/6] Deployment complete!"
echo ""
echo "  API:      http://localhost:8000"
echo "  API Docs: disabled in production"
echo "  Frontend: http://localhost:3000"
echo ""
docker compose -f "${COMPOSE_FILE}" ps
