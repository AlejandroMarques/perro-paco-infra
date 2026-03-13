#!/bin/bash
set -euo pipefail

# Usage: ./restore-postgres.sh <project-name> <backup-file>
# Example: /opt/scripts/restore-postgres.sh perropaco-dev /opt/backups/perropaco-dev/perropaco-dev_20260101_030000.sql.gz

PROJECT="${1:?Usage: restore-postgres.sh <project-name> <backup-file>}"
BACKUP_FILE="${2:?Usage: restore-postgres.sh <project-name> <backup-file>}"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo "[$(date)] Restoring ${PROJECT} from ${BACKUP_FILE}..."
echo "WARNING: This will overwrite the current database. Press Ctrl+C to abort."
sleep 5

gunzip -c "$BACKUP_FILE" | docker exec -i "${PROJECT}-db" psql -U postgres

echo "[$(date)] Restore complete"
