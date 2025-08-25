#!/bin/bash

# MongoDB Backup Script
# This script creates a backup of the MongoDB database

set -e

# Configuration
MONGO_HOST=${MONGO_HOST:-mongodb}
MONGO_PORT=${MONGO_PORT:-27017}
MONGO_ROOT_USERNAME=${MONGO_ROOT_USERNAME:-admin}
MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD:-password}
BACKUP_DIR=${BACKUP_DIR:-/backups}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/mongodb_backup_$TIMESTAMP"

echo "Starting backup of MongoDB at $(date)"

# Create database backup using mongodump
mongodump --host "$MONGO_HOST:$MONGO_PORT" \
          --username "$MONGO_ROOT_USERNAME" \
          --password "$MONGO_ROOT_PASSWORD" \
          --authenticationDatabase admin \
          --out "$BACKUP_FILE" \
          --gzip

# Create a compressed archive
tar -czf "$BACKUP_FILE.tar.gz" -C "$BACKUP_DIR" "$(basename "$BACKUP_FILE")"
rm -rf "$BACKUP_FILE"

echo "Backup completed: $BACKUP_FILE.tar.gz"
echo "Backup size: $(du -h "$BACKUP_FILE.tar.gz" | cut -f1)"

# Clean up old backups (keep last 30 days)
find "$BACKUP_DIR" -name "mongodb_backup_*.tar.gz" -type f -mtime +30 -delete

# Count remaining backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "mongodb_backup_*.tar.gz" -type f | wc -l)
echo "Total backups retained: $BACKUP_COUNT"

# Create a latest backup symlink
ln -sf "$(basename "$BACKUP_FILE.tar.gz")" "$BACKUP_DIR/latest_backup.tar.gz"

echo "Backup script completed successfully at $(date)"