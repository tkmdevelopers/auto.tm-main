#!/bin/sh
set -e

echo "[entrypoint] Starting container for alpha-motors backend"

if [ -z "$DATABASE_HOST" ]; then
  echo "[entrypoint] DATABASE_HOST not set" >&2
  exit 1
fi

DB_PORT=${DATABASE_PORT:-5432}
DB_USER=${DATABASE_USERNAME:-postgres}

echo "[entrypoint] Waiting for Postgres at $DATABASE_HOST:$DB_PORT ..."
for i in $(seq 1 60); do
  if pg_isready -h "$DATABASE_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; then
    echo "[entrypoint] Postgres is ready"
    break
  fi
  sleep 2
done

if ! pg_isready -h "$DATABASE_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; then
  echo "[entrypoint] Postgres not reachable after timeout" >&2
  exit 1
fi

CONFIG_FILE="/app/config/config.json"
echo "[entrypoint] Regenerating $CONFIG_FILE from environment (overwriting any existing)"
cat > "$CONFIG_FILE" <<JSON
{
  "development": {
    "username": "${DATABASE_USERNAME}",
    "password": "${DATABASE_PASSWORD}",
    "database": "${DATABASE}",
    "host": "${DATABASE_HOST}",
    "dialect": "postgres"
  },
  "production": {
    "username": "${DATABASE_USERNAME}",
    "password": "${DATABASE_PASSWORD}",
    "database": "${DATABASE}",
    "host": "${DATABASE_HOST}",
    "dialect": "postgres"
  }
}
JSON

echo "[entrypoint] Running migrations"
# Log critical env vars for debugging
echo "[entrypoint] ENV DATABASE_HOST=$DATABASE_HOST DATABASE_USERNAME=$DATABASE_USERNAME DATABASE=$DATABASE"
# Debug: list migrations and show first lines of add-reply and create-comments
ls -1 migrations || true
echo "[entrypoint] Head of add-reply migration:" && sed -n '1,15p' migrations/20251009120000-add-reply-to-comments.js || true
echo "[entrypoint] Head of create-comments migration:" && sed -n '1,15p' migrations/20251011130000-create-comments.js || true
# Ensure sequelize CLI available (after prune) by invoking via local node_modules or fallback to npx
if [ -f node_modules/.bin/sequelize-cli ]; then
  node_modules/.bin/sequelize-cli db:migrate || {
    echo "[entrypoint] Migrations failed" >&2; exit 1; }
else
  npx sequelize-cli db:migrate || {
    echo "[entrypoint] Migrations failed" >&2; exit 1; }
fi

echo "[entrypoint] Starting application"
echo "[entrypoint] Launching app with DATABASE_HOST=$DATABASE_HOST"
exec "$@"
