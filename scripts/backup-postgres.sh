#!/bin/bash
set -euo pipefail

# Usage: ./backup-postgres.sh <project-name>
# Example: /opt/scripts/backup-postgres.sh perropaco-dev
# Cron:  0 3 * * * /opt/scripts/backup-postgres.sh perropaco-dev

PROJECT="${1:?Usage: backup-postgres.sh <project-name>}"
BACKUP_DIR="/opt/backups/${PROJECT}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${PROJECT}_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup for ${PROJECT}..."

docker exec "${PROJECT}-db" pg_dumpall -U postgres \
  | gzip > "$BACKUP_FILE"

FILESIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] Backup complete: ${BACKUP_FILE} (${FILESIZE})"

# Retain only last 7 backups
DELETED=$(ls -t "${BACKUP_DIR}"/*.sql.gz 2>/dev/null | tail -n +8)
if [ -n "$DELETED" ]; then
  echo "$DELETED" | xargs rm -f
  echo "[$(date)] Cleaned old backups"
fi

echo "[$(date)] Done"
