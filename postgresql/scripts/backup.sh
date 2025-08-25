#!/bin/bash

# PostgreSQL Backup Script
# This script creates a backup of the PostgreSQL database

set -e

# Configuration
POSTGRES_HOST=${POSTGRES_HOST:-postgresql}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-mydatabase}
POSTGRES_USER=${POSTGRES_USER:-myuser}
BACKUP_DIR=${BACKUP_DIR:-/backups}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/postgres_backup_$TIMESTAMP.sql"

echo "Starting backup of database '$POSTGRES_DB' at $(date)"

# Create database backup
pg_dump -h "$POSTGRES_HOST" \
        -p "$POSTGRES_PORT" \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DB" \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --format=plain \
        --no-password \
        > "$BACKUP_FILE"

# Compress the backup
gzip "$BACKUP_FILE"
BACKUP_FILE="$BACKUP_FILE.gz"

echo "Backup completed: $BACKUP_FILE"
echo "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"

# Clean up old backups (keep last 30 days)
find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" -type f -mtime +30 -delete

# Count remaining backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "postgres_backup_*.sql.gz" -type f | wc -l)
echo "Total backups retained: $BACKUP_COUNT"

# Create a latest backup symlink
ln -sf "$(basename "$BACKUP_FILE")" "$BACKUP_DIR/latest_backup.sql.gz"

echo "Backup script completed successfully at $(date)"