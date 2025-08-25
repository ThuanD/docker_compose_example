# Docker Compose Stack Testing Guide

This repository contains comprehensive testing scripts for all Docker Compose tech stacks. The scripts will test each stack, identify issues, fix common problems, and perform complete cleanup.

## Quick Start

1. **Run setup script:**
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Test a simple stack:**
   ```bash
   ./test_single_stack.sh minio
   ```

3. **Test all stacks:**
   ```bash
   ./run_all_tests.sh
   ```

## Prerequisites

- Ubuntu/Linux system
- Docker installed and running
- Docker Compose installed
- curl and bc utilities

The setup script will check for these and provide installation instructions if needed.

## Testing Scripts

### 1. test_single_stack.sh
Tests an individual Docker Compose stack.

**Usage:**
```bash
./test_single_stack.sh <stack_name> [options]
```

**Options:**
- `--fix-configs`: Create missing configuration files automatically
- `--verbose`: Show detailed output including error logs

**Examples:**
```bash
# Test MinIO (simple stack)
./test_single_stack.sh minio

# Test PostgreSQL with config fixes and verbose output
./test_single_stack.sh postgresql --fix-configs --verbose

# Test Jenkins with config fixes
./test_single_stack.sh jenkins --fix-configs
```

### 2. run_all_tests.sh
Comprehensive testing script that tests all stacks systematically.

**Usage:**
```bash
./run_all_tests.sh
```

**Features:**
- Tests stacks in order of complexity (simple → complex)
- Automatically creates missing configuration files
- Generates detailed JSON reports
- Provides failure logs for debugging
- Performs comprehensive cleanup after testing
- Times each test and provides duration statistics

### 3. test_all_stacks.sh
Original comprehensive testing script with advanced features.

**Usage:**
```bash
./test_all_stacks.sh
```

## Available Stacks

### Simple Stacks (should work without additional config)
- `minio` - Object storage
- `wordpress` - WordPress with MySQL
- `keycloak` - Identity and access management
- `traefik` - Reverse proxy and load balancer

### Database Stacks
- `postgresql` - PostgreSQL with pgAdmin and backup
- `mysql` - MySQL with phpMyAdmin and backup
- `mongodb` - MongoDB with initialization scripts

### Message Queue Stacks
- `kafka` - Apache Kafka with Zookeeper and UI
- `rabbitmq` - RabbitMQ with management interface

### Monitoring Stacks
- `prometheus-grafana-versus` - Prometheus + Grafana monitoring
- `influxdb-grafana` - InfluxDB + Grafana time series
- `elasticsearch-logstash-kibana` - ELK stack for logging

### CI/CD Stacks
- `sonarqube` - Code quality analysis with PostgreSQL
- `jenkins` - CI/CD automation server

### Other Stacks
- `redis-cluster` - Redis cluster setup
- `certbot` - Nginx with SSL certificate automation

## Configuration Files

The testing scripts can automatically create missing configuration files when using the `--fix-configs` option. This includes:

- Database initialization scripts
- Web server configurations  
- Service-specific config files
- Health check endpoints
- Default user credentials

## Test Results

### Test Logs
All test execution logs are saved in the `test_logs/` directory:
- `test.log` - Main test execution log
- `comprehensive_report.json` - Detailed JSON report with results
- `<stack_name>_failure.log` - Individual stack failure logs

### Test Results Status
- **passed** - All services started successfully and are healthy
- **partial** - Some services are healthy, others may have issues
- **failed** - Services failed to start or are unhealthy
- **timeout** - Test exceeded the maximum time limit
- **skipped** - Stack directory not found or test was skipped

### Sample Report
```json
{
  "test_session": {
    "start_timestamp": "2024-01-20T10:00:00Z",
    "end_timestamp": "2024-01-20T10:45:00Z",
    "total_duration_seconds": 2700
  },
  "summary": {
    "total": 16,
    "passed": 12,
    "partial": 2,
    "failed": 2,
    "timeout": 0,
    "skipped": 0
  },
  "results": [
    {
      "stack_name": "postgresql",
      "status": "passed",
      "duration_seconds": 45
    }
  ]
}
```

## Cleanup

The testing scripts perform comprehensive cleanup:
- Stop all Docker containers
- Remove all containers, images, volumes, and networks
- Free up disk space
- Reset Docker environment to clean state

To skip cleanup (for debugging), you can manually stop the scripts with Ctrl+C.

## Troubleshooting

### Common Issues

1. **Docker daemon not running:**
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Permission denied:**
   ```bash
   sudo usermod -aG docker $USER
   # Log out and back in
   ```

3. **Port conflicts:**
   - Scripts will detect and report port conflicts
   - Stop conflicting services or change ports in compose files

4. **Low disk space:**
   - Ensure at least 10GB free space
   - Run `docker system prune -a --volumes` to clean up

5. **Missing dependencies:**
   - Run `./setup.sh` to check and install dependencies

### Debug Mode

For detailed debugging, run tests with verbose output:
```bash
./test_single_stack.sh <stack_name> --fix-configs --verbose
```

This will show:
- Detailed Docker Compose output
- Service startup logs
- Failure reasons
- Configuration file creation process

## Best Practices

1. **Start with simple stacks** to verify your environment
2. **Use --fix-configs** for complex stacks that need configuration files
3. **Check logs** in `test_logs/` directory for failed tests
4. **Run tests individually** first before running comprehensive tests
5. **Ensure sufficient resources** (CPU, memory, disk space)
6. **Clean environment** - stop other Docker containers before testing

## Support

If you encounter issues:
1. Check the prerequisites with `./setup.sh`
2. Review logs in `test_logs/` directory
3. Run individual stack tests with `--verbose` flag
4. Ensure Docker daemon is running and accessible
5. Verify sufficient system resources are available
