#!/bin/bash
# Scheduled Tasks Verification — P6-014
# Verifies all 5 Celery Beat tasks are registered and firing correctly.
set -euo pipefail

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

echo "===== Celery Beat Scheduled Tasks Verification ====="

EXPECTED_TASKS=(
  "retention_eligibility_scan"
  "dsr_expiry_check"
  "cleanup_temp_files"
  "gcp_sa_key_purge"
  "source_file_expiry_check"
)

echo ""
echo "[1/3] Inspecting registered Beat schedule..."
SCHEDULE=$(docker compose -f "${COMPOSE_FILE}" exec -T beat \
  celery -A app.worker.celery_app inspect scheduled 2>/dev/null || echo "")

for task in "${EXPECTED_TASKS[@]}"; do
  if echo "${SCHEDULE}" | grep -q "${task}"; then
    echo "  ✓ ${task}"
  else
    echo "  ✗ ${task} NOT FOUND in schedule"
  fi
done

echo ""
echo "[2/3] Checking worker registered tasks..."
REGISTERED=$(docker compose -f "${COMPOSE_FILE}" exec -T worker \
  celery -A app.worker.celery_app inspect registered 2>/dev/null || echo "")

for task in "${EXPECTED_TASKS[@]}"; do
  if echo "${REGISTERED}" | grep -q "${task}"; then
    echo "  ✓ ${task} registered on worker"
  else
    echo "  ✗ ${task} NOT registered on worker"
  fi
done

echo ""
echo "[3/3] Checking Beat heartbeat..."
HEARTBEAT=$(docker compose -f "${COMPOSE_FILE}" exec -T beat \
  celery -A app.worker.celery_app inspect clock 2>/dev/null | grep -c "current" || echo "0")
if [[ "${HEARTBEAT}" -gt "0" ]]; then
  echo "  ✓ Beat clock running"
else
  echo "  ✗ Beat clock not detected — check logs: docker compose logs beat"
fi

echo ""
echo "===== Verification complete ====="
echo ""
echo "Expected schedule:"
echo "  retention_eligibility_scan : daily at 02:00 WIB (UTC+7)"
echo "  dsr_expiry_check           : daily at 08:00 WIB (UTC+7)"
echo "  cleanup_temp_files         : daily at 03:00 WIB (UTC+7)"
echo "  gcp_sa_key_purge           : every 30 minutes"
echo "  source_file_expiry_check   : daily at 07:00 WIB (UTC+7); deletes uploads at end date + 30 days,"
echo "                               or end date + the approved ROPA retention period"
