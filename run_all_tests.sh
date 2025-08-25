#!/bin/bash

# Comprehensive Docker Compose Stack Testing Script for Ubuntu
# Tests all stacks systematically and provides detailed reporting

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/test_logs"
REPORT_FILE="${LOG_DIR}/comprehensive_report.json"
TEST_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Configuration
FIX_CONFIGS=true
CLEANUP_AFTER_EACH=true
SHOW_LOGS_ON_FAILURE=true
TEST_TIMEOUT=300  # 5 minutes per stack

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results
declare -A TEST_RESULTS
declare -A TEST_DURATIONS
declare -A SERVICE_COUNTS

# Stack categories
SIMPLE_STACKS=("minio" "wordpress" "keycloak" "traefik")
DATABASE_STACKS=("postgresql" "mysql" "mongodb")
MESSAGE_QUEUE_STACKS=("kafka" "rabbitmq")
MONITORING_STACKS=("prometheus-grafana-versus" "influxdb-grafana")
CICD_STACKS=("sonarqube" "jenkins")
OTHER_STACKS=("redis-cluster" "elasticsearch-logstash-kibana" "certbot")

# Initialize logging
init_logging() {
    mkdir -p "${LOG_DIR}"
    echo "=== Docker Compose Comprehensive Testing Started at ${TEST_TIMESTAMP} ===" > "${LOG_DIR}/test.log"
    
    # Initialize JSON report
    cat > "${REPORT_FILE}" << EOF
{
  "test_session": {
    "timestamp": "${TEST_TIMESTAMP}",
    "configuration": {
      "fix_configs": ${FIX_CONFIGS},
      "cleanup_after_each": ${CLEANUP_AFTER_EACH},
      "test_timeout": ${TEST_TIMEOUT}
    }
  },
  "results": [],
  "summary": {
    "total": 0,
    "passed": 0,
    "partial": 0,
    "failed": 0,
    "skipped": 0
  }
}
EOF
}

# Logging functions
log() {
    echo -e "$(date '+%H:%M:%S') - $1" | tee -a "${LOG_DIR}/test.log"
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

log_section() {
    echo ""
    log "${CYAN}[SECTION]${NC} $1"
    echo "$(printf '=%.0s' {1..50})"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing_deps+=("docker-compose")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found - JSON report formatting will be basic"
        log_info "Install jq with: sudo apt-get install jq"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "docker")
                    log_info "  - Install Docker: https://docs.docker.com/engine/install/ubuntu/"
                    ;;
                "docker-compose")
                    log_info "  - Install Docker Compose: https://docs.docker.com/compose/install/"
                    ;;
                "curl")
                    log_info "  - Install curl: sudo apt-get install curl"
                    ;;
            esac
        done
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        log_info "Start Docker with: sudo systemctl start docker"
        exit 1
    fi
    
    # Check available disk space
    local available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "${available_space}" -lt 10485760 ]; then  # Less than 10GB
        log_warning "Low disk space available: $(df -h / | awk 'NR==2 {print $4}')"
    fi
    
    log_success "Prerequisites check passed"
}

# Test individual stack with timeout
test_stack_with_timeout() {
    local stack_name=$1
    local timeout=${2:-$TEST_TIMEOUT}
    
    # Check if test_single_stack.sh exists and is executable
    if [ ! -f "${SCRIPT_DIR}/test_single_stack.sh" ]; then
        log_error "test_single_stack.sh not found at ${SCRIPT_DIR}/test_single_stack.sh"
        return 1
    fi
    
    if [ ! -x "${SCRIPT_DIR}/test_single_stack.sh" ]; then
        log_warning "Making test_single_stack.sh executable"
        chmod +x "${SCRIPT_DIR}/test_single_stack.sh"
    fi
    
    # Run with timeout and capture both stdout and stderr
    local temp_log="${LOG_DIR}/${stack_name}_test.log"
    
    log_info "Running test for ${stack_name} with ${timeout}s timeout..."
    
    if timeout "${timeout}" bash -c "'${SCRIPT_DIR}/test_single_stack.sh' '${stack_name}' --fix-configs 2>&1" > "${temp_log}"; then
        log_info "${stack_name} test output logged to ${temp_log}"
        return 0
    else
        local exit_code=$?
        log_error "${stack_name} test failed with exit code ${exit_code}"
        
        # Show last few lines of the log for debugging
        if [ -f "${temp_log}" ]; then
            log_error "Last 10 lines of ${stack_name} test output:"
            tail -n 10 "${temp_log}" | while read line; do
                log_error "  ${line}"
            done
        fi
        
        return ${exit_code}
    fi
}

# Test stack category
test_stack_category() {
    local category_name=$1
    local stack_array_name=$2
    
    log_section "Testing ${category_name}"
    
    local -n stacks=$stack_array_name
    local category_passed=0
    local category_total=0
    
    # Debug: Show which stacks we're about to test
    log_info "Stacks in ${category_name}: ${stacks[*]}"
    
    for stack in "${stacks[@]}"; do
        if [ ! -d "${SCRIPT_DIR}/${stack}" ]; then
            log_warning "Stack ${stack} directory not found at ${SCRIPT_DIR}/${stack}, skipping..."
            TEST_RESULTS["${stack}"]="skipped"
            continue
        fi
        
        category_total=$((category_total + 1))
        log_info "Testing ${stack}..."
        local start_time=$(date +%s)
        
        # Add debug info
        log_info "Stack directory: ${SCRIPT_DIR}/${stack}"
        
        # Check if compose file exists
        local compose_files=("${SCRIPT_DIR}/${stack}/compose.yaml" "${SCRIPT_DIR}/${stack}/docker-compose.yml" "${SCRIPT_DIR}/${stack}/docker-compose.yaml")
        local compose_found=false
        for compose_file in "${compose_files[@]}"; do
            if [ -f "${compose_file}" ]; then
                log_info "Found compose file: $(basename "${compose_file}")"
                compose_found=true
                break
            fi
        done
        
        if [ "${compose_found}" = false ]; then
            log_error "No compose file found in ${SCRIPT_DIR}/${stack}"
            TEST_RESULTS["${stack}"]="failed"
            continue
        fi
        
        if test_stack_with_timeout "${stack}"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            TEST_RESULTS["${stack}"]="passed"
            TEST_DURATIONS["${stack}"]=${duration}
            category_passed=$((category_passed + 1))
            
            log_success "${stack} test passed in ${duration}s"
        else
            local exit_code=$?
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            TEST_DURATIONS["${stack}"]=${duration}
            
            if [ ${exit_code} -eq 124 ]; then
                TEST_RESULTS["${stack}"]="timeout"
                log_error "${stack} test timed out after ${duration}s"
            else
                TEST_RESULTS["${stack}"]="failed"
                log_error "${stack} test failed in ${duration}s"
            fi
            
            # Show recent logs if requested
            if [ "${SHOW_LOGS_ON_FAILURE}" = "true" ]; then
                local stack_log="${LOG_DIR}/${stack}_failure.log"
                cd "${SCRIPT_DIR}/${stack}"
                docker compose logs --tail=20 > "${stack_log}" 2>&1 || true
                log_info "Failure logs saved to ${stack_log}"
            fi
        fi
        
        # Cleanup if requested
        if [ "${CLEANUP_AFTER_EACH}" = "true" ]; then
            cd "${SCRIPT_DIR}/${stack}"
            docker compose down -v --remove-orphans &>/dev/null || true
        fi
        
        echo ""
    done
    
    log_info "${category_name} Results: ${category_passed}/${category_total} passed"
}

# Generate comprehensive report
generate_report() {
    log_info "Generating comprehensive test report..."
    
    local end_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local total_duration=0
    local total_tests=0
    local passed_tests=0
    local partial_tests=0
    local failed_tests=0
    local skipped_tests=0
    local timeout_tests=0
    
    # Calculate statistics
    for stack in "${!TEST_RESULTS[@]}"; do
        total_tests = $((total_tests + 1))
        total_duration=$((total_duration + ${TEST_DURATIONS[$stack]:-0}))
        
        case "${TEST_RESULTS[$stack]}" in
            "passed") passed_tests=$((passed_tests + 1)) ;;
            "partial") partial_tests=$((partial_tests + 1)) ;;
            "failed") failed_tests=$((failed_tests + 1)) ;;
            "timeout") timeout_tests=$((timeout_tests + 1)) ;;
            "skipped") skipped_tests=$((skipped_tests + 1)) ;;
        esac
    done
    
    # Create detailed JSON report
    local results_json=""
    local first=true
    
    for stack in $(printf '%s\n' "${!TEST_RESULTS[@]}" | sort); do
        if [ "$first" = false ]; then
            results_json+=","
        fi
        first=false
        
        local duration=${TEST_DURATIONS[$stack]:-0}
        local status=${TEST_RESULTS[$stack]:-"unknown"}
        
        results_json+=$(cat << EOF

    {
      "stack_name": "${stack}",
      "status": "${status}",
      "duration_seconds": ${duration},
      "test_timestamp": "${TEST_TIMESTAMP}"
    }
EOF
        )
    done
    
    # Create final report
    cat > "${REPORT_FILE}" << EOF
{
  "test_session": {
    "start_timestamp": "${TEST_TIMESTAMP}",
    "end_timestamp": "${end_timestamp}",
    "total_duration_seconds": ${total_duration},
    "configuration": {
      "fix_configs": ${FIX_CONFIGS},
      "cleanup_after_each": ${CLEANUP_AFTER_EACH},
      "test_timeout": ${TEST_TIMEOUT}
    }
  },
  "summary": {
    "total": ${total_tests},
    "passed": ${passed_tests},
    "partial": ${partial_tests},
    "failed": ${failed_tests},
    "timeout": ${timeout_tests},
    "skipped": ${skipped_tests}
  },
  "results": [${results_json}
  ]
}
EOF
    
    log_success "Report generated: ${REPORT_FILE}"
}

# Print final summary
print_summary() {
    echo ""
    log_section "FINAL TEST SUMMARY"
    
    local total=0
    local passed=0
    local partial=0
    local failed=0
    local timeout=0
    local skipped=0
    
    for result in "${TEST_RESULTS[@]}"; do
        total=$((total + 1))
        case "${result}" in
            "passed") passed=$((passed + 1)) ;;
            "partial") partial=$((partial + 1)) ;;
            "failed") failed=$((failed + 1)) ;;
            "timeout") timeout=$((timeout + 1)) ;;
            "skipped") skipped=$((skipped + 1)) ;;
        esac
    done
    
    local total_duration=0
    for duration in "${TEST_DURATIONS[@]}"; do
        total_duration=$((total_duration + duration))
    done
    
    echo "Total Tests: ${total}"
    echo -e "${GREEN}Passed: ${passed}${NC}"
    echo -e "${YELLOW}Partial: ${partial}${NC}"
    echo -e "${RED}Failed: ${failed}${NC}"
    echo -e "${RED}Timeout: ${timeout}${NC}"
    echo -e "${BLUE}Skipped: ${skipped}${NC}"
    echo "Total Duration: ${total_duration}s ($((total_duration/60))m $((total_duration%60))s)"
    
    echo ""
    echo "Detailed Results:"
    echo "=================="
    
    for stack in $(printf '%s\n' "${!TEST_RESULTS[@]}" | sort); do
        local status=${TEST_RESULTS[$stack]}
        local duration=${TEST_DURATIONS[$stack]:-0}
        
        local color=$NC
        case "${status}" in
            "passed") color=$GREEN ;;
            "partial") color=$YELLOW ;;
            "failed"|"timeout") color=$RED ;;
            "skipped") color=$BLUE ;;
        esac
        
        printf "%-25s %s%-10s%s (%3ds)\n" "${stack}" "${color}" "${status}" "${NC}" "${duration}"
    done
    
    echo ""
    log_info "Full logs available at: ${LOG_DIR}/test.log"
    log_info "JSON report available at: ${REPORT_FILE}"
    
    if [ ${failed} -gt 0 ] || [ ${timeout} -gt 0 ]; then
        echo ""
        log_warning "Some tests failed. Check individual stack logs in ${LOG_DIR}/ for details."
        return 1
    fi
    
    return 0
}

# Comprehensive cleanup
comprehensive_cleanup() {
    log_section "COMPREHENSIVE CLEANUP"
    
    log_info "Stopping all running containers..."
    local containers=$(docker ps -q)
    if [ -n "${containers}" ]; then
        docker stop ${containers} || true
    fi
    
    log_info "Removing all containers..."
    docker container prune -f || true
    
    log_info "Removing unused images..."
    docker image prune -a -f || true
    
    log_info "Removing unused volumes..."
    docker volume prune -f || true
    
    log_info "Removing unused networks..."
    docker network prune -f || true
    
    log_info "Performing system cleanup..."
    docker system prune -a --volumes -f || true
    
    # Check final disk usage
    local disk_usage=$(docker system df --format "table {{.Size}}" 2>/dev/null | tail -n +2 | head -1 || echo "0B")
    log_success "Cleanup completed. Docker disk usage: ${disk_usage}"
}

# Main execution
main() {
    echo "Docker Compose Comprehensive Stack Testing"
    echo "==========================================="
    echo ""
    
    # Debug information
    log_info "Script directory: ${SCRIPT_DIR}"
    log_info "Current working directory: $(pwd)"
    log_info "Script path: ${BASH_SOURCE[0]}"
    
    init_logging
    check_prerequisites
    
    # Verify we can find stack directories
    log_info "Checking for stack directories..."
    local found_stacks=0
    local all_stacks=("${SIMPLE_STACKS[@]}" "${DATABASE_STACKS[@]}" "${MESSAGE_QUEUE_STACKS[@]}" "${MONITORING_STACKS[@]}" "${CICD_STACKS[@]}" "${OTHER_STACKS[@]}")

    log_info "SIMPLE_STACKS count: ${#SIMPLE_STACKS[@]}"
    log_info "DATABASE_STACKS count: ${#DATABASE_STACKS[@]}"
    log_info "All stacks count: ${#all_stacks[@]}"

    log_info "SIMPLE_STACKS: ${SIMPLE_STACKS[*]}"
    log_info "DATABASE_STACKS: ${DATABASE_STACKS[*]}"
    
    for stack in "${all_stacks[@]}"; do
        log_info "Processing stack: '$stack'"
        log_info "Checking path: '${SCRIPT_DIR}/${stack}'"
        if [ -d "${SCRIPT_DIR}/${stack}" ]; then
            found_stacks=$((found_stacks + 1))
            log_info "Found stack: ${stack}"
        else
            log_warning "Stack directory not found: ${SCRIPT_DIR}/${stack}"
        fi
    done
    
    if [ ${found_stacks} -eq 0 ]; then
        log_error "No stack directories found! Please check that you're running this script from the correct directory."
        log_info "Expected to find directories like: ${all_stacks[*]:0:5}..."
        exit 1
    fi
    
    log_success "Found ${found_stacks} stack directories"
    
    # Test all stack categories
    test_stack_category "Simple Stacks" SIMPLE_STACKS
    test_stack_category "Database Stacks" DATABASE_STACKS  
    test_stack_category "Message Queue Stacks" MESSAGE_QUEUE_STACKS
    test_stack_category "Monitoring Stacks" MONITORING_STACKS
    test_stack_category "CI/CD Stacks" CICD_STACKS
    test_stack_category "Other Stacks" OTHER_STACKS
    
    generate_report
    print_summary
    
    local summary_result=$?
    
    comprehensive_cleanup
    
    if [ ${summary_result} -eq 0 ]; then
        log_success "All tests completed successfully!"
    else
        log_warning "Some tests failed - check the report for details"
    fi
    
    exit ${summary_result}
}

# Handle script interruption
trap 'log_warning "Script interrupted. Performing cleanup..."; comprehensive_cleanup; exit 130' INT TERM

# Check for required scripts
if [ ! -f "${SCRIPT_DIR}/test_single_stack.sh" ]; then
    log_error "Required script test_single_stack.sh not found at ${SCRIPT_DIR}/test_single_stack.sh"
    log_info "Please ensure test_single_stack.sh exists in the same directory as this script"
    exit 1
fi

# Make test_single_stack.sh executable
chmod +x "${SCRIPT_DIR}/test_single_stack.sh"

# Test that test_single_stack.sh runs (without arguments to show usage)
log_info "Verifying test_single_stack.sh is working..."
if ! "${SCRIPT_DIR}/test_single_stack.sh" --help &>/dev/null && ! "${SCRIPT_DIR}/test_single_stack.sh" &>/dev/null; then
    log_warning "test_single_stack.sh may have issues - proceeding anyway"
else
    log_success "test_single_stack.sh appears to be working"
fi

# Run main function
main "$@"