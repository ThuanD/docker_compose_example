#!/bin/bash

# MySQL Backup Script
# Creates a gzipped dump of the target MySQL database

set -euo pipefail

MYSQL_HOST=${MYSQL_HOST:-mysql}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_DATABASE=${MYSQL_DATABASE:-mydatabase}
MYSQL_USER=${MYSQL_USER:-myuser}
MYSQL_PASSWORD=${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}
BACKUP_DIR=${BACKUP_DIR:-/backups}

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/mysql_backup_${TIMESTAMP}.sql.gz"

echo "Starting MySQL backup of '$MYSQL_DATABASE' at $(date)"

mysqldump \
    --host="$MYSQL_HOST" \
    --port="$MYSQL_PORT" \
    --user="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --no-tablespaces \
    --default-character-set=utf8mb4 \
    "$MYSQL_DATABASE" | gzip -9 > "$BACKUP_FILE"

echo "Backup completed: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
