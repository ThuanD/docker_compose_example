# SonarQube and SonarScanner Docker Setup

This repository contains everything you need to set up SonarQube with PostgreSQL and run code analysis with SonarScanner.

## Table of Contents

- [Prerequisites](#prerequisites)
- [SonarQube Setup](#sonarqube-setup)
  - [Configuration](#configuration)
  - [Starting SonarQube](#starting-sonarqube)
  - [Accessing SonarQube](#accessing-sonarqube)
- [SonarScanner Setup](#sonarscanner-setup)
  - [Running Analysis](#running-analysis)
  - [Configuration Options](#configuration-options)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

## Prerequisites

- Docker and Docker Compose installed
- Minimum 4GB of RAM allocated to Docker
- Port 9000 available on your host machine

## SonarQube Setup

### Configuration

1. Clone this repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Configure your environment by editing the `.env` file:
```
# SonarQube Configuration
SONAR_JDBC_URL=jdbc:postgresql://sonar_db:5432/sonar
SONAR_JDBC_USERNAME=sonar
SONAR_JDBC_PASSWORD=sonar
SONAR_PORT=9000

# PostgreSQL Configuration
POSTGRES_USER=sonar
POSTGRES_PASSWORD=sonar
POSTGRES_DB=sonar
```

> **Important**: For production use, make sure to change default passwords!

### Starting SonarQube

To start the SonarQube server along with PostgreSQL database:

```bash
docker compose up -d
```

This command will:
- Pull the required images if not present
- Create and configure all necessary volumes
- Start PostgreSQL with health check monitoring
- Start SonarQube after PostgreSQL is available
- Make SonarQube accessible on port 9000 (or your configured port)

To check service status:

```bash
docker compose ps
```

### Accessing SonarQube

Once started, SonarQube will be available at:

```
http://localhost:9000
```

Default credentials:
- Username: `admin`
- Password: `admin`

You'll be prompted to change the default password on first login.

## SonarScanner Setup

SonarScanner is the command-line tool to analyze your code. You can run it using Docker without installing it locally.

### Running Analysis

1. Generate a token in SonarQube:
   - Log in to SonarQube
   - Go to My Account > Security > Generate Token
   - Create and copy your token

2. Run the scanner:

```bash
# Set your variables
SONAR_HOST_URL=http://localhost:9000
SONAR_TOKEN=your_generated_token
PROJECT_BASEDIR=/path/to/your/project

# Run the scanner
docker run --rm \
  -e SONAR_HOST_URL="${SONAR_HOST_URL}" \
  -e SONAR_TOKEN="${SONAR_TOKEN}" \
  -v "${PROJECT_BASEDIR}:/usr/src" \
  sonarsource/sonar-scanner-cli
```

You can also create a shell script `scan.sh` to make this process easier:

```bash
#!/bin/bash
# scan.sh
SONAR_HOST_URL=http://localhost:9000
SONAR_TOKEN=your_token
PROJECT_BASEDIR=$(pwd)

docker run --rm \
  -e SONAR_HOST_URL="${SONAR_HOST_URL}" \
  -e SONAR_TOKEN="${SONAR_TOKEN}" \
  -v "${PROJECT_BASEDIR}:/usr/src" \
  sonarsource/sonar-scanner-cli $@
```

> **Note**: Make the script executable with `chmod +x scan.sh`

### Configuration Options

Create a `sonar-project.properties` file in your project root for custom scanner configuration:

```properties
# Required metadata
sonar.projectKey=my_project
sonar.projectName=My Project
sonar.projectVersion=1.0

# Path to source directories
sonar.sources=.
sonar.tests=tests

# Encoding of the source files
sonar.sourceEncoding=UTF-8

# Language
sonar.language=python

# Exclude files or directories
sonar.exclusions=**/node_modules/**,**/*.spec.ts
```

## Troubleshooting

### Elasticsearch Issues
If SonarQube fails to start, you might need to increase the virtual memory mapping limit:

```bash
# On your host machine
sudo sysctl -w vm.max_map_count=262144
```

To make this permanent, add the following to `/etc/sysctl.conf`:
```
vm.max_map_count=262144
```

### Container Logs
View logs with:

```bash
docker compose logs -f sonarqube
docker compose logs -f sonar_db
```

## Maintenance

### Backup Volumes

```bash
docker run --rm \
  -v sonarqube_data:/source/data \
  -v sonarqube_extensions:/source/extensions \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/sonarqube-backup-$(date +%Y%m%d).tar.gz /source
```

### Stopping SonarQube

```bash
docker compose down
```

To remove volumes (will delete all data):

```bash
docker compose down -v
```