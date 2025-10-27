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

echo "[entrypoint] Running migrations (offline safe)"
echo "[entrypoint] ENV DATABASE_HOST=$DATABASE_HOST DATABASE_USERNAME=$DATABASE_USERNAME DATABASE=$DATABASE"
ls -1 migrations | head -n 20 || true

if [ ! -f node_modules/.bin/sequelize-cli ]; then
  echo "[entrypoint] sequelize-cli missing in node_modules (expected offline install)." >&2
  echo "[entrypoint] Aborting migrations." >&2
  exit 1
fi

if ! node_modules/.bin/sequelize-cli db:migrate; then
  echo "[entrypoint] sequelize-cli db:migrate failed" >&2
  exit 1
fi

echo "[entrypoint] Starting application"
echo "[entrypoint] Launching app with DATABASE_HOST=$DATABASE_HOST"
exec "$@"
