#!/usr/bin/env bash
# =============================================================================
# deploy-update.sh — Safely update the Alpha Motors backend on an air-gapped server
#
# This script:
#   1. Pre-flight — verifies Docker is running and compose file exists
#   2. Backup    — dumps the Postgres database before touching anything
#   3. Load      — loads the new Docker image, records the old image for rollback
#   4. Update    — recreates the API container with the new image
#   5. Verify    — polls the health-check endpoint
#   6. Seed      — (optional) seeds currencies, brands, and/or demo posts
#   7. Rollback  — if verify fails, restores the previous image and restarts
#
# Usage:
#   ./deploy-update.sh <image-tarball> [--seed] [--seed-posts]
#
# Flags:
#   --seed        Seed base data (currencies + brands/models) after update
#   --seed-posts  Seed ~300 demo posts with images (implies --seed)
#
# Examples:
#   ./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz
#   ./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz --seed
#   ./deploy-update.sh alpha-motors-backend-0.2.0.tar.gz --seed-posts
#
# The script expects to find docker-compose.prod.yml and .env in the
# working directory (or the directory containing this script).
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${WORK_DIR:-$SCRIPT_DIR}"
COMPOSE_FILE="${WORK_DIR}/docker-compose.prod.yml"
ENV_FILE="${WORK_DIR}/.env"
API_CONTAINER="alpha_backend"
DB_CONTAINER="auto_tm_postgres"
IMAGE_NAME="alpha-motors-backend"
HEALTH_URL="http://localhost:3080/api-docs"
HEALTH_TIMEOUT=90   # seconds
HEALTH_INTERVAL=3   # seconds

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log()  { echo "[deploy] $*"; }
warn() { echo "[deploy:warn] $*" >&2; }
fail() { echo "[deploy:error] $*" >&2; exit 1; }

check_command() {
  command -v "$1" &>/dev/null || fail "$1 is not installed"
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

SEED_BASE=false
SEED_POSTS=false

if [ $# -lt 1 ]; then
  echo "Usage: $0 <image-tarball> [--seed] [--seed-posts]"
  echo ""
  echo "Example: $0 alpha-motors-backend-0.2.0.tar.gz --seed"
  exit 1
fi

TAR_PATH="$1"
shift

# Parse optional flags
for arg in "$@"; do
  case "$arg" in
    --seed)       SEED_BASE=true ;;
    --seed-posts) SEED_BASE=true; SEED_POSTS=true ;;
    *)            warn "Unknown flag: $arg" ;;
  esac
done

# Resolve relative path
if [[ "$TAR_PATH" != /* ]]; then
  TAR_PATH="${WORK_DIR}/${TAR_PATH}"
fi

[ -f "$TAR_PATH" ] || fail "Image tarball not found: ${TAR_PATH}"

echo ""
echo "============================================="
echo "  Alpha Motors — Deploy Update"
echo "============================================="
echo "  Tarball:  ${TAR_PATH}"
echo "  Compose:  ${COMPOSE_FILE}"
echo "  Seed:     base=${SEED_BASE}, posts=${SEED_POSTS}"
echo "  Time:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================="
echo ""

# =====================================================================
# Phase 1 — Pre-flight checks
# =====================================================================

log "Phase 1: Pre-flight checks"

check_command docker
check_command curl

docker info &>/dev/null || fail "Docker daemon is not running"

[ -f "$COMPOSE_FILE" ] || fail "Compose file not found: ${COMPOSE_FILE}"
[ -f "$ENV_FILE" ]     || fail ".env file not found: ${ENV_FILE}. Copy .env.example to .env and configure it."

# Record the currently running image (for rollback)
OLD_IMAGE=""
if docker ps --format '{{.Image}}' --filter "name=${API_CONTAINER}" | grep -q .; then
  OLD_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$API_CONTAINER" 2>/dev/null || true)
  log "  Current image: ${OLD_IMAGE:-none}"
else
  log "  No running API container found (first deployment?)"
fi

# Check that Postgres is running
if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  warn "  Postgres container '${DB_CONTAINER}' is not running."
  warn "  Starting Postgres first..."
  docker compose -f "$COMPOSE_FILE" up db -d
  # Wait for Postgres readiness
  log "  Waiting for Postgres..."
  for i in $(seq 1 30); do
    if docker exec "$DB_CONTAINER" pg_isready -U auto_tm &>/dev/null; then
      break
    fi
    sleep 2
  done
  docker exec "$DB_CONTAINER" pg_isready -U auto_tm &>/dev/null || fail "Postgres failed to start"
fi

log "  Pre-flight passed"

# =====================================================================
# Phase 2 — Database backup
# =====================================================================

log ""
log "Phase 2: Database backup"

BACKUP_DIR="${WORK_DIR}/backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/auto_tm_backup_${TIMESTAMP}.dump"

log "  Dumping database to ${BACKUP_FILE}..."
if docker exec "$DB_CONTAINER" pg_dump -U auto_tm -d auto_tm -F c -Z 9 > "$BACKUP_FILE"; then
  BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  log "  Backup complete (${BACKUP_SIZE})"
else
  warn "  Database backup failed! Proceeding anyway (database might be empty on first deploy)."
  BACKUP_FILE=""
fi

# =====================================================================
# Phase 3 — Load new image
# =====================================================================

log ""
log "Phase 3: Loading new Docker image"

log "  Loading from ${TAR_PATH}..."
if [[ "$TAR_PATH" == *.gz ]]; then
  gunzip -c "$TAR_PATH" | docker load
else
  docker load -i "$TAR_PATH"
fi

# Determine the new version from loaded tags
NEW_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${IMAGE_NAME}:" | grep -v ":latest" | head -1)
log "  Loaded: ${NEW_IMAGE:-${IMAGE_NAME}:latest}"

# =====================================================================
# Phase 4 — Update (recreate API container)
# =====================================================================

log ""
log "Phase 4: Updating API container"

# Stop old container if running
if docker ps --format '{{.Names}}' | grep -q "^${API_CONTAINER}$"; then
  log "  Stopping current API container..."
  docker compose -f "$COMPOSE_FILE" stop api
fi

# Start with new image — compose will use :latest (which the build script tagged)
log "  Starting API with new image..."
docker compose -f "$COMPOSE_FILE" up -d api

log "  Container started. Waiting for health check..."

# =====================================================================
# Phase 5 — Health verification
# =====================================================================

log ""
log "Phase 5: Health verification"

HEALTHY=false
DEADLINE=$((SECONDS + HEALTH_TIMEOUT))

while [ $SECONDS -lt $DEADLINE ]; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ]; then
    HEALTHY=true
    break
  fi
  printf "."
  sleep "$HEALTH_INTERVAL"
done
echo ""

if ! $HEALTHY; then
  # Jump to rollback (Phase 7 below)
  :
else
  log "  API is healthy (HTTP ${HTTP_CODE})"

  # =====================================================================
  # Phase 6 — Seeding (optional, only when flags are passed)
  # =====================================================================

  if $SEED_BASE; then
    log ""
    log "Phase 6: Seeding database"

    log "  Seeding currencies + brands/models..."
    if docker exec "$API_CONTAINER" node scripts/seed-all.js; then
      log "  Base seed complete"
    else
      warn "  Base seed failed (non-fatal)"
    fi

    if $SEED_POSTS; then
      log "  Seeding ~300 demo posts with images (this takes a few minutes)..."
      if docker exec "$API_CONTAINER" node scripts/seed-demo-posts-api.js; then
        log "  Demo posts seed complete"
      else
        warn "  Demo posts seed failed (non-fatal)"
      fi
    fi
  fi

  echo ""
  echo "============================================="
  echo "  Update successful!"
  echo "============================================="
  echo "  Previous: ${OLD_IMAGE:-none}"
  echo "  Current:  ${NEW_IMAGE:-${IMAGE_NAME}:latest}"
  echo "  Backup:   ${BACKUP_FILE:-skipped}"
  echo "  Seeded:   base=${SEED_BASE}, posts=${SEED_POSTS}"
  echo "  Time:     $(date '+%Y-%m-%d %H:%M:%S')"
  echo "============================================="
  echo ""
  echo "  Verify with:  docker logs ${API_CONTAINER} --tail 50"
  echo "  API docs:     ${HEALTH_URL}"
  echo ""
  exit 0
fi

# =====================================================================
# Phase 7 — Rollback (only reached if health check failed)
# =====================================================================

warn ""
warn "Phase 7: ROLLBACK — API failed health check after ${HEALTH_TIMEOUT}s"
warn ""

# Show recent logs for debugging
warn "  Recent API logs:"
docker logs "$API_CONTAINER" --tail 30 2>&1 | while IFS= read -r line; do
  warn "    $line"
done

# Stop the broken container
docker compose -f "$COMPOSE_FILE" stop api

if [ -n "$OLD_IMAGE" ]; then
  warn ""
  warn "  Restoring previous image: ${OLD_IMAGE}"
  # Re-tag the old image as :latest so compose picks it up
  docker tag "$OLD_IMAGE" "${IMAGE_NAME}:latest"
  docker compose -f "$COMPOSE_FILE" up -d api

  warn "  Previous version restarted."
  warn ""
  warn "  If the issue was a bad migration, you may need to restore the DB backup:"
  warn "    docker exec -i ${DB_CONTAINER} pg_restore -U auto_tm -d auto_tm --clean < ${BACKUP_FILE}"
else
  warn "  No previous image to rollback to (first deployment)."
  warn "  Fix the issue and re-run the deploy script."
fi

warn ""
warn "============================================="
warn "  UPDATE FAILED — rolled back"
warn "============================================="
warn "  Failed image:  ${NEW_IMAGE:-${IMAGE_NAME}:latest}"
warn "  Restored:      ${OLD_IMAGE:-none}"
warn "  DB backup:     ${BACKUP_FILE:-none}"
warn "============================================="

exit 1
