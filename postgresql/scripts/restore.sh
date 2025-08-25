#!/bin/bash

# PostgreSQL Restore Script
# This script restores a PostgreSQL database from a backup file

set -e

# Configuration
POSTGRES_HOST=${POSTGRES_HOST:-postgresql}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_DB=${POSTGRES_DB:-mydatabase}
POSTGRES_USER=${POSTGRES_USER:-myuser}
BACKUP_DIR=${BACKUP_DIR:-/backups}

# Function to show usage
usage() {
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 postgres_backup_20231201_120000.sql.gz"
    echo "Available backups:"
    ls -la "$BACKUP_DIR"/postgres_backup_*.sql.gz 2>/dev/null || echo "No backups found"
    exit 1
}

# Check if backup file is provided
if [ $# -eq 0 ]; then
    usage
fi

BACKUP_FILE="$1"

# If backup file doesn't have full path, assume it's in backup directory
if [[ "$BACKUP_FILE" != /* ]]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found"
    usage
fi

echo "Starting restore from backup: $BACKUP_FILE"
echo "Target database: $POSTGRES_DB on $POSTGRES_HOST:$POSTGRES_PORT"
echo "Warning: This will replace all data in the database!"
echo ""

# Ask for confirmation in interactive mode
if [ -t 0 ]; then
    read -p "Are you sure you want to continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled"
        exit 1
    fi
fi

echo "Starting restore at $(date)"

# Determine if file is compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing and restoring..."
    gunzip -c "$BACKUP_FILE" | psql -h "$POSTGRES_HOST" \
                                    -p "$POSTGRES_PORT" \
                                    -U "$POSTGRES_USER" \
                                    -d postgres \
                                    --quiet
else
    echo "Restoring uncompressed backup..."
    psql -h "$POSTGRES_HOST" \
         -p "$POSTGRES_PORT" \
         -U "$POSTGRES_USER" \
         -d postgres \
         --quiet \
         -f "$BACKUP_FILE"
fi

echo "Restore completed successfully at $(date)"
echo "Database '$POSTGRES_DB' has been restored from: $BACKUP_FILE"

# Verify the restore
echo "Verifying restore..."
TABLE_COUNT=$(psql -h "$POSTGRES_HOST" \
                   -p "$POSTGRES_PORT" \
                   -U "$POSTGRES_USER" \
                   -d "$POSTGRES_DB" \
                   -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');")

echo "Tables restored: $(echo $TABLE_COUNT | tr -d ' ')"
echo "Restore verification completed"