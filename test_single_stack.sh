#!/bin/bash

# Simple Docker Compose Stack Tester for Ubuntu
# Usage: ./test_single_stack.sh <stack_name> [--fix-configs] [--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME=""
FIX_CONFIGS=false
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix-configs)
            FIX_CONFIGS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            STACK_NAME="$1"
            shift
            ;;
    esac
done

# Available stacks
AVAILABLE_STACKS=(
    "postgresql" "mysql" "mongodb" "kafka" "rabbitmq" 
    "redis-cluster" "minio" "prometheus-grafana-versus" 
    "influxdb-grafana" "elasticsearch-logstash-kibana" 
    "sonarqube" "jenkins" "wordpress" "certbot" "traefik" "keycloak"
)

# Logging functions
log() {
    echo -e "$(date '+%H:%M:%S') - $1"
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

# Show usage
show_usage() {
    echo "Usage: ./test_single_stack.sh <stack_name> [options]"
    echo ""
    echo "Options:"
    echo "  --fix-configs    Create missing configuration files"
    echo "  --verbose        Show detailed output"
    echo ""
    echo "Available stacks:"
    printf '%s\n' "${AVAILABLE_STACKS[@]}" | column -c 80
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
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create missing configurations
create_configs() {
    local stack_path=$1
    local stack_name=$2
    
    log_info "Creating missing configurations for ${stack_name}..."
    
    case "${stack_name}" in
        "postgresql")
            mkdir -p "${stack_path}"/{init,config,logs,pgadmin,scripts,backups}
            
            if [ ! -f "${stack_path}/config/postgresql.conf" ]; then
                echo "# Minimal PostgreSQL configuration
log_statement = 'all'
log_directory = '/var/log/postgresql'
log_filename = 'postgresql.log'
logging_collector = on" > "${stack_path}/config/postgresql.conf"
                log_info "Created postgresql.conf"
            fi
            
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
                log_info "Created servers.json for pgAdmin"
            fi
            ;;
        "mysql")
            mkdir -p "${stack_path}"/{init,config,logs,backups,scripts,phpmyadmin}
            
            if [ ! -f "${stack_path}/config/my.cnf" ]; then
                cat > "${stack_path}/config/my.cnf" << 'EOF'
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-authentication-plugin=mysql_native_password
EOF
                log_info "Created my.cnf"
            fi
            ;;
        "mongodb")
            mkdir -p "${stack_path}"/{init,scripts}
            
            if [ ! -f "${stack_path}/init/01-init-database.js" ]; then
                cat > "${stack_path}/init/01-init-database.js" << 'EOF'
// MongoDB initialization script
db = db.getSiblingDB('mydatabase');
db.createUser({
  user: 'myuser',
  pwd: 'mypassword',
  roles: ['readWrite']
});
EOF
                log_info "Created MongoDB init script"
            fi
            ;;
        "rabbitmq")
            mkdir -p "${stack_path}/config"
            
            if [ ! -f "${stack_path}/config/rabbitmq.conf" ]; then
                echo "# RabbitMQ configuration
management.tcp.port = 15672
listeners.tcp.default = 5672" > "${stack_path}/config/rabbitmq.conf"
                log_info "Created rabbitmq.conf"
            fi
            
            if [ ! -f "${stack_path}/config/definitions.json" ]; then
                cat > "${stack_path}/config/definitions.json" << 'EOF'
{
  "rabbit_version": "3.12.0",
  "users": [],
  "vhosts": [{"name": "/"}],
  "permissions": [],
  "exchanges": [],
  "queues": [],
  "bindings": []
}
EOF
                log_info "Created definitions.json"
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
                log_info "Created redis.conf"
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
                log_info "Created prometheus.yml"
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
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF
                log_info "Created nginx.conf"
            fi
            
            if [ ! -f "${stack_path}/static/index.html" ]; then
                cat > "${stack_path}/static/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Nginx Test Page</title>
</head>
<body>
    <h1>Nginx is working!</h1>
    <p>This is a test page for the Docker Compose stack.</p>
</body>
</html>
EOF
                log_info "Created index.html"
            fi
            
            if [ ! -f "${stack_path}/static/health.html" ]; then
                echo "OK" > "${stack_path}/static/health.html"
                log_info "Created health.html"
            fi
            ;;
    esac
}

# Test stack health
test_stack_health() {
    local stack_name=$1
    
    log_info "Checking health of services..."
    
    local services=($(docker compose ps --services 2>/dev/null || echo ""))
    if [ ${#services[@]} -eq 0 ]; then
        log_error "No services found"
        return 1
    fi
    
    local healthy_services=0
    local total_services=${#services[@]}
    local running_services=0
    
    for service in "${services[@]}"; do
        # Get the full status line for the service
        local status_line=$(docker compose ps --format "table {{.Service}}\t{{.Status}}\t{{.State}}" | grep "^${service}" || echo "")
        local health_status=$(echo "${status_line}" | awk '{print $2}' || echo "")
        local service_state=$(echo "${status_line}" | awk '{print $3}' || echo "")
        
        log_info "Service ${service}: Status='${health_status}', State='${service_state}'"
        
        # Check if service is in a good state
        if [[ "${health_status}" == *"healthy"* ]] || [[ "${health_status}" == *"Up"* ]] || [[ "${service_state}" == *"running"* ]]; then
            log_success "Service ${service} is healthy/running"
            ((healthy_services++))
            ((running_services++))
        elif [[ "${service_state}" == *"exited"* ]] && [[ "${health_status}" == *"0"* ]]; then
            # Some services (like init containers) exit successfully
            log_success "Service ${service} completed successfully"
            ((healthy_services++))
        else
            log_warning "Service ${service} status: ${health_status}, state: ${service_state}"
            
            # Show container logs for failed services
            log_info "Checking logs for ${service}:"
            docker compose logs --tail=5 "${service}" || true
        fi
    done
    
    log_info "Health check result: ${healthy_services}/${total_services} services healthy (${running_services} running)"
    
    # Consider test successful if at least 80% of services are healthy/successful
    local success_threshold=$((total_services * 80 / 100))
    if [ ${success_threshold} -eq 0 ]; then
        success_threshold=1
    fi
    
    if [ ${healthy_services} -ge ${success_threshold} ]; then
        if [ ${healthy_services} -eq ${total_services} ]; then
            return 0  # All healthy
        else
            return 2  # Mostly healthy
        fi
    else
        return 1  # Not enough healthy
    fi
}

# Test individual stack
test_stack() {
    local stack_name=$1
    local stack_path="${SCRIPT_DIR}/${stack_name}"
    
    if [ ! -d "${stack_path}" ]; then
        log_error "Stack directory ${stack_path} does not exist"
        return 1
    fi
    
    log_info "Testing tech stack: ${stack_name}"
    local start_time=$(date +%s)
    
    cd "${stack_path}"
    
    # Check for compose file
    local compose_file=""
    if [ -f "compose.yaml" ]; then
        compose_file="compose.yaml"
    elif [ -f "docker-compose.yml" ]; then
        compose_file="docker-compose.yml"
    elif [ -f "docker-compose.yaml" ]; then
        compose_file="docker-compose.yaml"
    else
        log_error "No compose file found in ${stack_path}"
        return 1
    fi
    
    log_info "Using compose file: ${compose_file}"
    
    # Create configs if requested
    if [ "${FIX_CONFIGS}" = "true" ]; then
        create_configs "${stack_path}" "${stack_name}"
    fi
    
    # Cleanup any existing containers
    log_info "Cleaning up existing containers..."
    docker compose down -v --remove-orphans &>/dev/null || true
    
    # Start services
    log_info "Starting services..."
    if [ "${VERBOSE}" = "true" ]; then
        docker compose up -d --build
    else
        docker compose up -d --build &>/dev/null
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Failed to start services"
        if [ "${VERBOSE}" = "true" ]; then
            docker compose logs --tail=20
        fi
        docker compose down -v --remove-orphans &>/dev/null || true
        return 1
    fi
    
    # Wait for services to start
    log_info "Waiting for services to initialize..."
    sleep 15
    
    # Test health
    test_stack_health "${stack_name}"
    local health_result=$?
    
    # Show logs if not healthy and verbose
    if [ ${health_result} -ne 0 ] && [ "${VERBOSE}" = "true" ]; then
        log_info "Showing service logs:"
        docker compose logs --tail=10
    fi
    
    # Cleanup
    log_info "Cleaning up..."
    docker compose down -v --remove-orphans &>/dev/null || true
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    case ${health_result} in
        0)
            log_success "Test completed successfully in ${duration}s - All services healthy"
            return 0
            ;;
        2)
            log_success "Test completed successfully in ${duration}s - Most services healthy (partial success)"
            return 0
            ;;
        *)
            log_error "Test failed in ${duration}s - Insufficient healthy services"
            return 1
            ;;
    esac
}

# Main execution
main() {
    if [ -z "${STACK_NAME}" ]; then
        show_usage
        exit 1
    fi
    
    # Check if stack is available
    if [[ ! " ${AVAILABLE_STACKS[@]} " =~ " ${STACK_NAME} " ]]; then
        log_error "Stack '${STACK_NAME}' is not available"
        echo ""
        show_usage
        exit 1
    fi
    
    echo "Docker Compose Stack Tester"
    echo "=========================="
    echo ""
    
    check_prerequisites
    
    # Call test_stack and capture its exit code
    if test_stack "${STACK_NAME}"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"