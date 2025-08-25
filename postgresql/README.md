# PostgreSQL with PgAdmin Docker Setup

This directory contains a comprehensive PostgreSQL setup with PgAdmin web interface and automated backup functionality.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Services](#services)
- [Database Management](#database-management)
- [Backup and Restore](#backup-and-restore)
- [Performance Tuning](#performance-tuning)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Windows-Specific Notes](#windows-specific-notes)

## Prerequisites

- Docker and Docker Compose installed
- Minimum 2GB of RAM allocated to Docker
- Ports 5432 and 8080 available on your host machine

## Quick Start

1. **Clone and navigate to the directory:**
```bash
git clone <repository-url>
cd postgresql
```

2. **Configure environment variables:**
```bash
# Windows Command Prompt
copy .env.example .env

# Windows PowerShell
Copy-Item .env.example .env

# Git Bash
cp .env.example .env
```

3. **Edit the `.env` file with your preferred settings:**
```bash
# Use any text editor
notepad .env
```

4. **Start the services:**
```bash
docker compose up -d
```

5. **Access PgAdmin:**
   - Open http://localhost:8080
   - Login with credentials from your `.env` file

## Configuration

### Environment Variables

Edit the `.env` file to customize your setup:

```env
# Database Configuration
POSTGRES_DB=mydatabase          # Database name
POSTGRES_USER=myuser           # Database user
POSTGRES_PASSWORD=mypassword   # Database password (CHANGE THIS!)
POSTGRES_PORT=5432             # Database port

# PgAdmin Configuration
PGADMIN_EMAIL=admin@example.com    # PgAdmin login email
PGADMIN_PASSWORD=admin             # PgAdmin password (CHANGE THIS!)
PGADMIN_PORT=8080                 # PgAdmin web port

# Backup Configuration
BACKUP_SCHEDULE=0 2 * * *         # Daily backup at 2 AM
```

> **Security Warning:** Always change default passwords in production!

### PostgreSQL Configuration

The PostgreSQL configuration file is located at `config/postgresql.conf`. Key settings include:

- Memory allocation
- Connection limits
- Logging configuration
- Performance tuning parameters

## Services

This setup includes three services:

### 1. PostgreSQL Database
- **Container:** `postgresql`
- **Port:** 5432 (configurable)
- **Data:** Persisted in named volume `postgres_data`
- **Logs:** Available in `./logs` directory

### 2. PgAdmin Web Interface
- **Container:** `pgadmin`
- **Port:** 8080 (configurable)
- **Access:** http://localhost:8080
- **Purpose:** Web-based PostgreSQL administration

### 3. Automated Backup Service
- **Container:** `postgres-backup`
- **Schedule:** Configurable via cron expression
- **Location:** `./backups` directory
- **Format:** SQL dump files with timestamp

## Database Management

### Connecting to PostgreSQL

**Using Docker Compose:**
```bash
docker compose exec postgresql psql -U myuser -d mydatabase
```

**Using external client:**
```bash
psql -h localhost -p 5432 -U myuser -d mydatabase
```

**Connection parameters:**
- Host: `localhost`
- Port: `5432` (or your configured port)
- Database: Your `POSTGRES_DB` value
- Username: Your `POSTGRES_USER` value
- Password: Your `POSTGRES_PASSWORD` value

### Initial Database Setup

Place SQL scripts in the `init/` directory to run them automatically when the database starts for the first time:

```sql
-- Example: init/01-create-tables.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Using PgAdmin

1. **Access PgAdmin:** http://localhost:8080
2. **Login:** Use credentials from `.env` file
3. **Add Server:**
   - Right-click "Servers" → "Create" → "Server"
   - **General Tab:**
     - Name: `Local PostgreSQL`
   - **Connection Tab:**
     - Host: `postgresql`
     - Port: `5432`
     - Database: Your database name
     - Username: Your username
     - Password: Your password

## Backup and Restore

### Automated Backups

Backups are automatically created according to the schedule in your `.env` file. Files are saved to `./backups/` with timestamps.

### Manual Backup

```bash
# Create a backup
docker compose exec postgresql pg_dump -U myuser mydatabase > backup_$(date +%Y%m%d_%H%M%S).sql

# Or using the backup script
docker compose exec postgres-backup /scripts/backup.sh
```

### Restore from Backup

```bash
# Restore from a backup file
docker compose exec -T postgresql psql -U myuser -d mydatabase < your_backup_file.sql

# Or copy file to container and restore
docker compose cp your_backup_file.sql postgresql:/tmp/
docker compose exec postgresql psql -U myuser -d mydatabase -f /tmp/your_backup_file.sql
```

## Performance Tuning

### PostgreSQL Configuration

Edit `config/postgresql.conf` for performance tuning:

```conf
# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# Connection settings
max_connections = 100

# Checkpoint settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB

# Query planner
random_page_cost = 1.1
effective_io_concurrency = 200
```

### Monitoring

**View active connections:**
```sql
SELECT * FROM pg_stat_activity;
```

**Check database size:**
```sql
SELECT 
    datname as database_name,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;
```

**View table sizes:**
```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Security

### Best Practices

1. **Change default passwords** in `.env` file
2. **Use strong passwords** with mixed characters
3. **Limit network exposure** - database is on internal network
4. **Regular backups** are configured automatically
5. **Update images** regularly for security patches

### Network Security

- PostgreSQL runs on an internal network
- Only PgAdmin is exposed to external network
- Use environment variables for sensitive data

### User Management

```sql
-- Create a new user
CREATE USER newuser WITH ENCRYPTED PASSWORD 'strongpassword';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO newuser;

-- Create read-only user
CREATE USER readonly WITH ENCRYPTED PASSWORD 'readonlypass';
GRANT CONNECT ON DATABASE mydatabase TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
```

## Troubleshooting

### Common Issues

**PostgreSQL won't start:**
```bash
# Check logs
docker compose logs postgresql

# Check if port is available
netstat -an | findstr :5432
```

**Can't connect to database:**
```bash
# Test connection
docker compose exec postgresql pg_isready -U myuser

# Check if service is healthy
docker compose ps
```

**PgAdmin connection issues:**
```bash
# Ensure PostgreSQL is healthy first
docker compose exec postgresql pg_isready

# Check PgAdmin logs
docker compose logs pgadmin
```

**Backup script not working:**
```bash
# Check backup container logs
docker compose logs postgres-backup

# Test backup script manually
docker compose exec postgres-backup /scripts/backup.sh
```

### Data Recovery

**Reset PostgreSQL data:**
```bash
# Stop services
docker compose down

# Remove data volume (WARNING: This deletes all data!)
docker volume rm postgresql_postgres_data

# Start fresh
docker compose up -d
```

## Windows-Specific Notes

### File Paths
- Use forward slashes in volume mounts
- Ensure Docker Desktop has access to the project directory
- Configure line endings: `git config core.autocrlf true`

### PowerShell Commands
```powershell
# View services
docker compose ps

# Follow logs
docker compose logs -f postgresql

# Execute SQL
docker compose exec postgresql psql -U myuser -d mydatabase -c "SELECT version();"
```

### Performance on Windows
- Consider using WSL 2 for better performance
- Allocate sufficient memory to Docker Desktop
- Store data in Docker volumes rather than bind mounts for better performance

## Maintenance

### Regular Tasks

**Update PostgreSQL:**
```bash
# Pull latest images
docker compose pull

# Recreate containers
docker compose up -d --force-recreate
```

**Clean up old backups:**
```bash
# Keep only last 30 days of backups (Windows)
forfiles /p backups /s /m *.sql /d -30 /c "cmd /c del @path"
```

**Vacuum database:**
```sql
VACUUM ANALYZE;
```

### Health Checks

All services include health checks. Monitor them with:
```bash
docker compose ps
```

Healthy services show `(healthy)` status.

---

For more information, refer to the [official PostgreSQL documentation](https://www.postgresql.org/docs/) and [PgAdmin documentation](https://www.pgadmin.org/docs/).