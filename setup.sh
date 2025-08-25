#!/bin/bash

# Setup script for Docker Compose Stack Testing
# Makes all scripts executable and provides usage instructions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Docker Compose Stack Testing Setup"
echo "=================================="
echo ""

# Make scripts executable
echo "Making scripts executable..."
chmod +x "${SCRIPT_DIR}/test_all_stacks.sh"
chmod +x "${SCRIPT_DIR}/test_single_stack.sh"
chmod +x "${SCRIPT_DIR}/run_all_tests.sh"
chmod +x "${SCRIPT_DIR}/health_checks.sh"

echo "✓ Scripts made executable"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

missing_deps=()

if ! command -v docker &> /dev/null; then
    missing_deps+=("docker")
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    missing_deps+=("docker-compose")
fi

if ! command -v curl &> /dev/null; then
    missing_deps+=("curl")
fi

if ! command -v bc &> /dev/null; then
    missing_deps+=("bc")
fi

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "⚠ Missing dependencies: ${missing_deps[*]}"
    echo ""
    echo "To install missing dependencies on Ubuntu:"
    echo "sudo apt-get update"
    for dep in "${missing_deps[@]}"; do
        case $dep in
            "docker")
                echo "# Install Docker:"
                echo "curl -fsSL https://get.docker.com -o get-docker.sh"
                echo "sudo sh get-docker.sh"
                echo "sudo usermod -aG docker \$USER"
                ;;
            "docker-compose")
                echo "# Install Docker Compose:"
                echo "sudo apt-get install docker-compose-plugin"
                ;;
            "curl")
                echo "sudo apt-get install curl"
                ;;
            "bc")
                echo "sudo apt-get install bc"
                ;;
        esac
    done
    echo ""
    echo "After installation, log out and back in, then run this setup script again."
else
    echo "✓ All prerequisites are installed"
fi

# Check Docker daemon
if docker info &> /dev/null; then
    echo "✓ Docker daemon is running"
else
    echo "⚠ Docker daemon is not running"
    echo "Start it with: sudo systemctl start docker"
    echo "Enable auto-start: sudo systemctl enable docker"
fi

echo ""
echo "Available Testing Scripts:"
echo "========================="
echo ""

echo "1. Test a single stack:"
echo "   ./test_single_stack.sh <stack_name> [--fix-configs] [--verbose]"
echo ""
echo "   Examples:"
echo "   ./test_single_stack.sh minio"
echo "   ./test_single_stack.sh postgresql --fix-configs --verbose"
echo ""

echo "2. Test all stacks comprehensively:"
echo "   ./run_all_tests.sh"
echo ""
echo "   This will:"
echo "   - Test all stacks in order of complexity"
echo "   - Create missing configuration files"
echo "   - Generate detailed reports"
echo "   - Perform comprehensive cleanup"
echo ""

echo "3. Test with the original comprehensive script:"
echo "   ./test_all_stacks.sh"
echo ""

echo "Available Stacks:"
echo "================"
echo ""

if [ -d "${SCRIPT_DIR}" ]; then
    echo "Simple stacks (should work without additional config):"
    for stack in "minio" "wordpress" "keycloak" "traefik"; do
        if [ -d "${SCRIPT_DIR}/${stack}" ]; then
            echo "  - ${stack}"
        fi
    done
    echo ""
    
    echo "Database stacks:"
    for stack in "postgresql" "mysql" "mongodb"; do
        if [ -d "${SCRIPT_DIR}/${stack}" ]; then
            echo "  - ${stack}"
        fi
    done
    echo ""
    
    echo "Message queue stacks:"
    for stack in "kafka" "rabbitmq"; do
        if [ -d "${SCRIPT_DIR}/${stack}" ]; then
            echo "  - ${stack}"
        fi
    done
    echo ""
    
    echo "Other stacks:"
    for stack in "redis-cluster" "prometheus-grafana-versus" "influxdb-grafana" "elasticsearch-logstash-kibana" "sonarqube" "jenkins" "certbot"; do
        if [ -d "${SCRIPT_DIR}/${stack}" ]; then
            echo "  - ${stack}"
        fi
    done
fi

echo ""
echo "Quick Start:"
echo "==========="
echo ""
echo "1. Test a simple stack first:"
echo "   ./test_single_stack.sh minio"
echo ""
echo "2. Test a database stack with config creation:"
echo "   ./test_single_stack.sh postgresql --fix-configs --verbose"
echo ""
echo "3. Run comprehensive testing:"
echo "   ./run_all_tests.sh"
echo ""
echo "4. Check results:"
echo "   cat test_logs/comprehensive_report.json"
echo ""

echo "Notes:"
echo "======"
echo "- The --fix-configs option creates missing configuration files"
echo "- Test logs are saved in the test_logs/ directory"
echo "- Each test cleans up after itself by default"
echo "- Failed tests will show logs to help with debugging"
echo "- All Docker resources will be cleaned up after testing"
echo ""

echo "Setup completed! You can now run the testing scripts."