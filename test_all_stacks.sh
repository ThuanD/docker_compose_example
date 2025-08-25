#!/bin/bash

# Docker Compose Tech Stack Testing and Cleanup Script
# This script systematically tests all Docker Compose tech stacks,
# identifies and fixes issues, and performs comprehensive cleanup

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/test_logs"
REPORT_FILE="${LOG_DIR}/test_report.json"
TEST_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HEALTH_CHECK_SCRIPT="${SCRIPT_DIR}/health_checks.sh"
FIX_CONFIGS=${FIX_CONFIGS:-true}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
declare -A TEST_RESULTS
declare -A TEST_DURATIONS
declare -A SERVICE_STATUS
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Tech stacks to test with their priorities
declare -A TECH_STACKS=(
    ["postgresql"]="high"
    ["mongodb"]="high"
    ["mysql"]="high"
    ["kafka"]="high"
    ["rabbitmq"]="high"
    ["redis-cluster"]="medium"
    ["minio"]="medium"
    ["prometheus-grafana-versus"]="medium"
    ["influxdb-grafana"]="medium"
    ["elasticsearch-logstash-kibana"]="medium"
    ["sonarqube"]="high"
    ["jenkins"]="high"
    ["wordpress"]="medium"
    ["certbot"]="medium"
    ["traefik"]="low"
    ["keycloak"]="low"
)

# Simple stacks that should work without additional config
SIMPLE_STACKS=("minio" "wordpress" "keycloak" "traefik")

# Complex stacks that need configuration fixes
COMPLEX_STACKS=("postgresql" "mysql" "mongodb" "kafka" "rabbitmq" "redis-cluster" "sonarqube" "jenkins" "elasticsearch-logstash-kibana" "prometheus-grafana-versus" "influxdb-grafana" "certbot")

# Initialize logging
init_logging() {
    mkdir -p "${LOG_DIR}"
    echo "=== Docker Compose Tech Stack Testing Started at ${TEST_TIMESTAMP} ===" > "${LOG_DIR}/test.log"
    
    # Initialize JSON report
    cat > "${REPORT_FILE}" << EOF
{
  "test_session": {
    "timestamp": "${TEST_TIMESTAMP}",
    "total_stacks": ${#TECH_STACKS[@]},
    "summary": {
      "passed": 0,
      "failed": 0,
      "skipped": 0
    }
  },
  "results": [],
  "cleanup": {}
}
EOF
}

# Logging functions
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_DIR}/test.log"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed or not available"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Wait for service to be healthy
wait_for_service() {
    local service_name=$1
    local max_attempts=${2:-30}
    local sleep_interval=${3:-10}
    
    log_info "Waiting for service ${service_name} to be healthy..."
    
    for ((i=1; i<=max_attempts; i++)); do
        if docker compose ps --services --filter "status=running" | grep -q "^${service_name}$"; then
            local health_status=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep "^${service_name}" | awk '{print $2}')
            if [[ "${health_status}" == *"healthy"* ]] || [[ "${health_status}" == *"Up"* ]]; then
                log_success "Service ${service_name} is healthy"
                return 0
            fi
        fi
        
        log_info "Attempt ${i}/${max_attempts}: Service ${service_name} not ready yet, waiting ${sleep_interval}s..."
        sleep ${sleep_interval}
    done
    
    log_error "Service ${service_name} failed to become healthy after ${max_attempts} attempts"
    return 1
}

# Wait for multiple services
wait_for_services() {
    local services=("$@")
    local failed_services=()
    
    for service in "${services[@]}"; do
        if ! wait_for_service "${service}"; then
            failed_services+=("${service}")
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "Failed services: ${failed_services[*]}"
        return 1
    fi
    
    return 0
}

# Generic health check function
check_service_health() {
    local service_name=$1
    local check_type=$2
    local endpoint=${3:-""}
    
    case "${check_type}" in
        "http")
            if curl -f -s --max-time 10 "${endpoint}" > /dev/null 2>&1; then
                return 0
            fi
            ;;
        "tcp")
            local host=$(echo "${endpoint}" | cut -d':' -f1)
            local port=$(echo "${endpoint}" | cut -d':' -f2)
            if timeout 10 bash -c "</dev/tcp/${host}/${port}"; then
                return 0
            fi
            ;;
        "docker")
            local health_status=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep "^${service_name}" | awk '{print $2}')
            if [[ "${health_status}" == *"healthy"* ]] || [[ "${health_status}" == *"Up"* ]]; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Create missing configuration files and directories
create_missing_configs() {
    local stack_name=$1
    local stack_path=$2
    
    log_info "Creating missing configurations for ${stack_name}..."
    
    case "${stack_name}" in
        "postgresql")
            # Create required directories
            mkdir -p "${stack_path}"/{init,config,logs,pgadmin,scripts,backups}
            
            # Create minimal postgresql.conf
            if [ ! -f "${stack_path}/config/postgresql.conf" ]; then
                echo "# Minimal PostgreSQL configuration" > "${stack_path}/config/postgresql.conf"
            fi
            
            # Create pgAdmin servers.json
            if [ ! -f "${stack_path}/pgadmin/servers.json" ]; then
                cat > "${stack_path}/pgadmin/servers.json" << 'EOF'
{
  "Servers": {
    "1": {
      "Name": "PostgreSQL",
      "Group": "Servers",
      "Host": "postgresql",
      "Port": 5432,
      "MaintenanceDB": "mydatabase",
      "Username": "myuser",
      "SSLMode": "prefer"
    }
  }
}
EOF
            fi
            ;;
        "mysql")
            mkdir -p "${stack_path}"/{init,config,logs,backups,scripts,phpmyadmin}
            
            if [ ! -f "${stack_path}/config/my.cnf" ]; then
                cat > "${stack_path}/config/my.cnf" << 'EOF'
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
EOF
            fi
            ;;
        "mongodb")
            mkdir -p "${stack_path}"/{init,scripts}
            
            if [ ! -f "${stack_path}/init/01-init-database.js" ]; then
                echo "// MongoDB initialization script" > "${stack_path}/init/01-init-database.js"
            fi
            ;;
        "rabbitmq")
            mkdir -p "${stack_path}/config"
            
            if [ ! -f "${stack_path}/config/rabbitmq.conf" ]; then
                echo "# RabbitMQ configuration" > "${stack_path}/config/rabbitmq.conf"
            fi
            
            if [ ! -f "${stack_path}/config/definitions.json" ]; then
                cat > "${stack_path}/config/definitions.json" << 'EOF'
{
  "rabbit_version": "3.12.0",
  "users": [],
  "vhosts": [],
  "permissions": [],
  "exchanges": [],
  "queues": [],
  "bindings": []
}
EOF
            fi
            ;;
        "redis-cluster")
            mkdir -p "${stack_path}/redis"
            
            if [ ! -f "${stack_path}/redis/redis.conf" ]; then
                cat > "${stack_path}/redis/redis.conf" << 'EOF'
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
appendonly yes
EOF
            fi
            ;;
        "prometheus-grafana-versus")
            mkdir -p "${stack_path}"/{prometheus,prometheus-grafana/grafana,versus/config}
            
            if [ ! -f "${stack_path}/prometheus/prometheus.yml" ]; then
                cat > "${stack_path}/prometheus/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
            fi
            ;;
        "certbot")
            mkdir -p "${stack_path}"/{nginx,static}
            
            if [ ! -f "${stack_path}/nginx/nginx.conf" ]; then
                cat > "${stack_path}/nginx/nginx.conf" << 'EOF'
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
    }
}
EOF
            fi
            
            if [ ! -f "${stack_path}/static/index.html" ]; then
                echo "<html><body><h1>Nginx Test Page</h1></body></html>" > "${stack_path}/static/index.html"
            fi
            ;;
    esac
}

# Auto-fix common issues
auto_fix_issues() {
    local stack_name=$1
    local stack_path=$2
    
    log_info "Attempting to auto-fix issues for ${stack_name}..."
    
    # Create missing configurations if enabled
    if [ "${FIX_CONFIGS}" = "true" ]; then
        create_missing_configs "${stack_name}" "${stack_path}"
    fi
    
    # Check for port conflicts
    local conflicting_ports=$(docker compose config --services 2>/dev/null | xargs -I {} docker compose port {} 2>/dev/null | grep -o ':[0-9]*' | sort | uniq -c | awk '$1 > 1 {print $2}' | tr -d ':' || true)
    
    if [ -n "${conflicting_ports}" ]; then
        log_warning "Port conflicts detected: ${conflicting_ports}"
    fi
    
    # Check for resource issues
    local available_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    if [ "${available_memory}" -lt 2000000000 ]; then  # Less than 2GB
        log_warning "Low memory detected, may cause issues with resource-intensive stacks"
    fi
    
    # Try to pull images if they failed
    log_info "Attempting to pull images..."
    docker compose pull --ignore-pull-failures || true
    
    return 0
}

# Test individual tech stack
test_tech_stack() {
    local stack_name=$1
    local stack_path="${SCRIPT_DIR}/${stack_name}"
    
    if [ ! -d "${stack_path}" ]; then
        log_error "Stack directory ${stack_path} does not exist"
        TEST_RESULTS["${stack_name}"]="skipped"
        ((SKIPPED_TESTS++))
        return 1
    fi
    
    log_info "Testing tech stack: ${stack_name}"
    local start_time=$(date +%s)
    
    cd "${stack_path}"
    
    # Check if compose file exists
    local compose_file=""
    if [ -f "compose.yaml" ]; then
        compose_file="compose.yaml"
    elif [ -f "docker-compose.yml" ]; then
        compose_file="docker-compose.yml"
    elif [ -f "docker-compose.yaml" ]; then
        compose_file="docker-compose.yaml"
    else
        log_error "No compose file found in ${stack_path}"
        TEST_RESULTS["${stack_name}"]="failed"
        ((FAILED_TESTS++))
        return 1
    fi
    
    # Cleanup any existing containers for this stack
    log_info "Cleaning up existing containers for ${stack_name}..."
    docker compose down -v --remove-orphans 2>/dev/null || true
    
    # Start services
    log_info "Starting services for ${stack_name}..."
    if ! docker compose up -d --build; then
        log_error "Failed to start services for ${stack_name}"
        auto_fix_issues "${stack_name}" "${stack_path}"
        
        # Retry once after auto-fix
        log_info "Retrying startup for ${stack_name}..."
        if ! docker compose up -d --build; then
            log_error "Failed to start services for ${stack_name} even after auto-fix"
            TEST_RESULTS["${stack_name}"]="failed"
            ((FAILED_TESTS++))
            docker compose logs --tail=20 || true
            docker compose down -v --remove-orphans 2>/dev/null || true
            return 1
        fi
    fi
    
    # Get list of services
    local services=($(docker compose ps --services 2>/dev/null || echo ""))
    if [ ${#services[@]} -eq 0 ]; then
        log_error "No services found for ${stack_name}"
        TEST_RESULTS["${stack_name}"]="failed"
        ((FAILED_TESTS++))
        docker compose down -v --remove-orphans 2>/dev/null || true
        return 1
    fi
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready: ${services[*]}"
    sleep 15  # Initial wait for services to start
    
    # Use health checks if available
    if [ -f "${HEALTH_CHECK_SCRIPT}" ]; then
        source "${HEALTH_CHECK_SCRIPT}"
    fi
    
    # Check service health
    local healthy_services=0
    for service in "${services[@]}"; do
        if check_service_health "${service}" "docker"; then
            log_success "Service ${service} is healthy"
            SERVICE_STATUS["${stack_name}_${service}"]="healthy"
            ((healthy_services++))
        else
            log_warning "Service ${service} is not healthy"
            SERVICE_STATUS["${stack_name}_${service}"]="unhealthy"
        fi
    done
    
    # Determine test result
    if [ ${healthy_services} -eq ${#services[@]} ]; then
        log_success "All services for ${stack_name} are healthy"
        TEST_RESULTS["${stack_name}"]="passed"
        ((PASSED_TESTS++))
    elif [ ${healthy_services} -gt 0 ]; then
        log_warning "Some services for ${stack_name} are healthy (${healthy_services}/${#services[@]})"
        TEST_RESULTS["${stack_name}"]="partial"
        ((PASSED_TESTS++))
    else
        log_error "No services for ${stack_name} are healthy"
        TEST_RESULTS["${stack_name}"]="failed"
        ((FAILED_TESTS++))
        # Show logs for debugging
        docker compose logs --tail=50 || true
    fi
    
    # Cleanup this stack
    log_info "Cleaning up ${stack_name}..."
    docker compose down -v --remove-orphans 2>/dev/null || true
    
    local end_time=$(date +%s)
    TEST_DURATIONS["${stack_name}"]=$((end_time - start_time))
    
    cd "${SCRIPT_DIR}"
    return 0
}

# Run tests for all tech stacks
run_all_tests() {
    log_info "Starting tests for all tech stacks..."
    
    # Test high priority stacks first
    for stack_name in "${!TECH_STACKS[@]}"; do
        if [ "${TECH_STACKS[$stack_name]}" = "high" ]; then
            ((TOTAL_TESTS++))
            test_tech_stack "${stack_name}"
        fi
    done
    
    # Test medium priority stacks
    for stack_name in "${!TECH_STACKS[@]}"; do
        if [ "${TECH_STACKS[$stack_name]}" = "medium" ]; then
            ((TOTAL_TESTS++))
            test_tech_stack "${stack_name}"
        fi
    done
    
    # Test low priority stacks
    for stack_name in "${!TECH_STACKS[@]}"; do
        if [ "${TECH_STACKS[$stack_name]}" = "low" ]; then
            ((TOTAL_TESTS++))
            test_tech_stack "${stack_name}"
        fi
    done
}

# Comprehensive cleanup
comprehensive_cleanup() {
    log_info "Starting comprehensive cleanup..."
    
    # Stop all running containers
    log_info "Stopping all Docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    # Remove all containers
    log_info "Removing all Docker containers..."
    local containers_removed=$(docker container ls -aq | wc -l)
    docker container prune -f || true
    
    # Remove all images (except base images)
    log_info "Removing unused Docker images..."
    local images_before=$(docker images -q | wc -l)
    docker image prune -a -f || true
    local images_after=$(docker images -q | wc -l)
    local images_removed=$((images_before - images_after))
    
    # Remove all volumes
    log_info "Removing all Docker volumes..."
    local volumes_removed=$(docker volume ls -q | wc -l)
    docker volume prune -f || true
    
    # Remove all networks (except default ones)
    log_info "Removing unused Docker networks..."
    docker network prune -f || true
    
    # System prune for any remaining artifacts
    log_info "Performing system-wide Docker cleanup..."
    docker system prune -a --volumes -f || true
    
    # Get disk space freed
    local disk_usage_after=$(docker system df --format "table {{.Size}}" | tail -n +2 | head -1 || echo "0B")
    
    log_success "Cleanup completed!"
    log_info "Containers removed: ${containers_removed}"
    log_info "Images removed: ${images_removed}"
    log_info "Volumes removed: ${volumes_removed}"
    log_info "Current Docker disk usage: ${disk_usage_after}"
    
    # Update cleanup info in report
    local cleanup_info="{\"containers_removed\": ${containers_removed}, \"images_removed\": ${images_removed}, \"volumes_removed\": ${volumes_removed}, \"disk_usage_after\": \"${disk_usage_after}\"}"
    echo "${cleanup_info}" > "${LOG_DIR}/cleanup_info.json"
}

# Generate final report
generate_report() {
    log_info "Generating final test report..."
    
    local end_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local total_duration=0
    
    # Calculate total duration
    for stack in "${!TEST_DURATIONS[@]}"; do
        total_duration=$((total_duration + TEST_DURATIONS[$stack]))
    done
    
    # Create detailed report
    cat > "${REPORT_FILE}" << EOF
{
  "test_session": {
    "timestamp": "${TEST_TIMESTAMP}",
    "end_timestamp": "${end_timestamp}",
    "total_duration": "${total_duration}s",
    "total_stacks": ${TOTAL_TESTS},
    "summary": {
      "passed": ${PASSED_TESTS},
      "failed": ${FAILED_TESTS},
      "skipped": ${SKIPPED_TESTS}
    }
  },
  "results": [
EOF

    local first=true
    for stack in "${!TEST_RESULTS[@]}"; do
        if [ "$first" = false ]; then
            echo "," >> "${REPORT_FILE}"
        fi
        first=false
        
        local duration=${TEST_DURATIONS[$stack]:-0}
        cat >> "${REPORT_FILE}" << EOF
    {
      "stack_name": "${stack}",
      "status": "${TEST_RESULTS[$stack]}",
      "duration": "${duration}s",
      "priority": "${TECH_STACKS[$stack]:-unknown}"
    }
EOF
    done
    
    # Add cleanup info if available
    local cleanup_info="{}"
    if [ -f "${LOG_DIR}/cleanup_info.json" ]; then
        cleanup_info=$(cat "${LOG_DIR}/cleanup_info.json")
    fi
    
    cat >> "${REPORT_FILE}" << EOF
  ],
  "cleanup": ${cleanup_info}
}
EOF

    log_success "Test report generated: ${REPORT_FILE}"
}

# Print summary
print_summary() {
    echo
    log_info "=== TEST SUMMARY ==="
    log_info "Total stacks tested: ${TOTAL_TESTS}"
    log_success "Passed: ${PASSED_TESTS}"
    log_error "Failed: ${FAILED_TESTS}"
    log_warning "Skipped: ${SKIPPED_TESTS}"
    echo
    
    if [ ${FAILED_TESTS} -gt 0 ]; then
        log_warning "Failed stacks:"
        for stack in "${!TEST_RESULTS[@]}"; do
            if [ "${TEST_RESULTS[$stack]}" = "failed" ]; then
                log_error "  - ${stack}"
            fi
        done
    fi
    
    log_info "Detailed report available at: ${REPORT_FILE}"
    log_info "Full logs available at: ${LOG_DIR}/test.log"
}

# Main execution
main() {
    echo "Docker Compose Tech Stack Testing Script"
    echo "========================================"
    
    init_logging
    check_prerequisites
    run_all_tests
    comprehensive_cleanup
    generate_report
    print_summary
    
    log_success "All testing and cleanup completed!"
}

# Run main function
main "$@"