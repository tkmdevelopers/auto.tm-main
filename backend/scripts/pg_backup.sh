#!/usr/bin/env bash
# Simple Postgres backup script for offline server
# Usage: chmod +x scripts/pg_backup.sh && ./scripts/pg_backup.sh
# Run from repo root or backend dir; creates compressed custom-format dumps with retention.

set -euo pipefail

# Configurable vars (override via env or edit here)
DB_CONTAINER=${DB_CONTAINER:-auto_tm_postgres}
DB_NAME=${DB_NAME:-auto_tm}
DB_USER=${DB_USER:-auto_tm}
BACKUP_DIR=${BACKUP_DIR:-/var/lib/alpha/backups}
RETENTION_DAYS=${RETENTION_DAYS:-7}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${DB_NAME}_backup_${TIMESTAMP}.dump"

mkdir -p "$BACKUP_DIR"

echo "[backup] Dumping $DB_NAME from container $DB_CONTAINER to $BACKUP_DIR/$FILENAME"
if docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
  docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -Z 9 >"$BACKUP_DIR/$FILENAME"
else
  echo "[error] Container $DB_CONTAINER not running" >&2
  exit 1
fi

echo "[backup] Backup created: $BACKUP_DIR/$FILENAME"

echo "[backup] Pruning backups older than $RETENTION_DAYS days"
find "$BACKUP_DIR" -type f -name "${DB_NAME}_backup_*.dump" -mtime +"$RETENTION_DAYS" -print -delete || true

echo "[backup] Done"
