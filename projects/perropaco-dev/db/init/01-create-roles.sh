#!/bin/sh
set -eu

# Runs automatically on first database initialization (fresh volume).
# Requires:
# - APP_DB_PASSWORD
# Optional:
# - APP_DB_USER (default: perropaco_app)

APP_DB_USER="${APP_DB_USER:-perropaco_app}"
APP_DB_PASSWORD="${APP_DB_PASSWORD:-}"
DB_NAME="${POSTGRES_DB:-}"

if [ -z "$APP_DB_PASSWORD" ]; then
  echo "ERROR: APP_DB_PASSWORD is required to create ${APP_DB_USER}"
  exit 1
fi

if [ -z "$DB_NAME" ]; then
  echo "ERROR: POSTGRES_DB is not set"
  exit 1
fi

echo "Creating app role and grants (${APP_DB_USER}) on ${DB_NAME}..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$DB_NAME" <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${APP_DB_USER}') THEN
    CREATE ROLE ${APP_DB_USER} LOGIN PASSWORD '${APP_DB_PASSWORD}';
  END IF;
END
\$\$;

GRANT CONNECT ON DATABASE ${DB_NAME} TO ${APP_DB_USER};
GRANT USAGE ON SCHEMA public TO ${APP_DB_USER};

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${APP_DB_USER};
SQL

echo "Done."
