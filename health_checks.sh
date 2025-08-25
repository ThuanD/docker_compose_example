#!/bin/bash

# Service-specific health check functions
# This script provides detailed health checks for different types of services

# Database health checks
check_postgresql_health() {
    local container_name=${1:-"postgresql-db-1"}
    
    # Check if container is running
    if ! docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
        return 1
    fi
    
    # Test database connection
    if docker exec "${container_name}" pg_isready -U postgres 2>/dev/null; then
        echo "PostgreSQL: Database connection OK"
        
        # Test basic query
        if docker exec "${container_name}" psql -U postgres -c "SELECT 1;" 2>/dev/null >/dev/null; then
            echo "PostgreSQL: Query execution OK"
            return 0
        fi
    fi
    
    return 1
}

check_mysql_health() {
    local container_name=${1:-"mysql-db-1"}
    
    if ! docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
        return 1
    fi
    
    # Test MySQL connection
    if docker exec "${container_name}" mysqladmin ping -h localhost 2>/dev/null | grep -q "mysqld is alive"; then
        echo "MySQL: Database connection OK"
        return 0
    fi
    
    return 1
}

check_mongodb_health() {
    local container_name=${1:-"mongodb-db-1"}
    
    if ! docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
        return 1
    fi
    
    # Test MongoDB connection
    if docker exec "${container_name}" mongo --eval "db.adminCommand('ismaster')" 2>/dev/null | grep -q "ismaster.*true"; then
        echo "MongoDB: Database connection OK"
        return 0
    fi
    
    return 1
}

# Message queue health checks
check_kafka_health() {
    local container_name=${1:-"kafka-kafka-1"}
    
    if ! docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
        return 1
    fi
    
    # Check if Kafka is responding
    if docker exec "${container_name}" kafka-broker-api-versions --bootstrap-server localhost:9092 2>/dev/null | grep -q "kafka"; then
        echo "Kafka: Broker API OK"
        return 0
    fi
    
    return 1
}

check_rabbitmq_health() {
    local container_name=${1:-"rabbitmq-rabbitmq-1"}
    
    if ! docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
        return 1
    fi
    
    # Check RabbitMQ status
    if docker exec "${container_name}" rabbitmqctl status 2>/dev/null | grep -q "Status of node"; then
        echo "RabbitMQ: Node status OK"
        return 0
    fi
    
    return 1
}

# Cache and storage health checks
check_redis_health() {
    local container_name=${1:-"redis-cluster-redis-1"}
    
    if ! docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
        return 1
    fi
    
    # Test Redis ping
    if docker exec "${container_name}" redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo "Redis: Ping OK"
        return 0
    fi
    
    return 1
}

check_minio_health() {
    local port=${1:-"9000"}
    
    # Check MinIO API endpoint
    if curl -f -s --max-time 10 "http://localhost:${port}/minio/health/live" >/dev/null 2>&1; then
        echo "MinIO: Health endpoint OK"
        return 0
    fi
    
    return 1
}

# Web UI health checks
check_web_ui() {
    local url=$1
    local service_name=$2
    
    if curl -f -s --max-time 10 "${url}" >/dev/null 2>&1; then
        echo "${service_name}: Web UI accessible"
        return 0
    elif curl -s --max-time 10 "${url}" 2>/dev/null | grep -qi "html\|login\|dashboard"; then
        echo "${service_name}: Web UI responding (may require login)"
        return 0
    fi
    
    return 1
}

# Monitoring service health checks
check_prometheus_health() {
    local port=${1:-"9090"}
    
    if check_web_ui "http://localhost:${port}/-/healthy" "Prometheus"; then
        return 0
    fi
    
    # Fallback to main page
    if check_web_ui "http://localhost:${port}" "Prometheus"; then
        return 0
    fi
    
    return 1
}

check_grafana_health() {
    local port=${1:-"3000"}
    
    if check_web_ui "http://localhost:${port}/api/health" "Grafana"; then
        return 0
    fi
    
    # Fallback to main page
    if check_web_ui "http://localhost:${port}" "Grafana"; then
        return 0
    fi
    
    return 1
}

check_kibana_health() {
    local port=${1:-"5601"}
    
    if check_web_ui "http://localhost:${port}/api/status" "Kibana"; then
        return 0
    fi
    
    # Fallback to main page
    if check_web_ui "http://localhost:${port}" "Kibana"; then
        return 0
    fi
    
    return 1
}

# CI/CD service health checks
check_jenkins_health() {
    local port=${1:-"8080"}
    
    if check_web_ui "http://localhost:${port}/login" "Jenkins"; then
        return 0
    fi
    
    return 1
}

check_sonarqube_health() {
    local port=${1:-"9000"}
    
    if check_web_ui "http://localhost:${port}/api/system/status" "SonarQube"; then
        return 0
    fi
    
    # Fallback to main page
    if check_web_ui "http://localhost:${port}" "SonarQube"; then
        return 0
    fi
    
    return 1
}

# Infrastructure service health checks
check_traefik_health() {
    local port=${1:-"8080"}
    
    if check_web_ui "http://localhost:${port}/dashboard/" "Traefik"; then
        return 0
    fi
    
    return 1
}

check_keycloak_health() {
    local port=${1:-"8080"}
    
    if check_web_ui "http://localhost:${port}/auth" "Keycloak"; then
        return 0
    fi
    
    return 1
}

# Enhanced service health checks based on actual compose configurations
check_postgresql_stack_health() {
    echo "Checking PostgreSQL stack health..."
    
    # Check PostgreSQL service
    local pg_result=0
    if docker exec postgresql pg_isready -U myuser -d mydatabase 2>/dev/null; then
        echo "✓ PostgreSQL: Database connection OK"
    else
        echo "✗ PostgreSQL: Database connection failed"
        pg_result=1
    fi
    
    # Check pgAdmin service
    local pgadmin_result=0
    if check_web_ui "http://localhost:8080" "pgAdmin"; then
        echo "✓ pgAdmin: Web UI accessible"
    else
        echo "✗ pgAdmin: Web UI not accessible"
        pgadmin_result=1
    fi
    
    return $((pg_result + pgadmin_result))
}

check_sonarqube_stack_health() {
    echo "Checking SonarQube stack health..."
    
    # Check database first
    local db_result=0
    if docker exec sonar_db pg_isready -U sonar -d sonar 2>/dev/null; then
        echo "✓ SonarQube DB: Database connection OK"
    else
        echo "✗ SonarQube DB: Database connection failed"
        db_result=1
    fi
    
    # Check SonarQube API
    local sonar_result=0
    if check_web_ui "http://localhost:9000/api/system/status" "SonarQube API"; then
        echo "✓ SonarQube: API responding"
    elif check_web_ui "http://localhost:9000" "SonarQube"; then
        echo "✓ SonarQube: Web UI accessible"
    else
        echo "✗ SonarQube: Service not accessible"
        sonar_result=1
    fi
    
    return $((db_result + sonar_result))
}

check_kafka_stack_health() {
    echo "Checking Kafka stack health..."
    
    # Check Zookeeper
    local zk_result=0
    if docker exec zookeeper sh -c "echo stat | nc localhost 2181" 2>/dev/null | grep -q "Mode:"; then
        echo "✓ Zookeeper: Service responding"
    else
        echo "✗ Zookeeper: Service not responding"
        zk_result=1
    fi
    
    # Check Kafka broker
    local kafka_result=0
    if docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null >/dev/null; then
        echo "✓ Kafka: Broker responding"
    else
        echo "✗ Kafka: Broker not responding"
        kafka_result=1
    fi
    
    # Check Kafka UI
    local ui_result=0
    if check_web_ui "http://localhost:8080" "Kafka UI"; then
        echo "✓ Kafka UI: Web interface accessible"
    else
        echo "✗ Kafka UI: Web interface not accessible"
        ui_result=1
    fi
    
    return $((zk_result + kafka_result + ui_result))
}

check_mongodb_stack_health() {
    echo "Checking MongoDB stack health..."
    
    # Check MongoDB connection and basic operation
    if docker exec mongodb mongosh --eval "db.adminCommand('ping')" 2>/dev/null | grep -q "ok.*1"; then
        echo "✓ MongoDB: Database connection and ping OK"
        return 0
    else
        echo "✗ MongoDB: Database connection failed"
        return 1
    fi
}

check_redis_cluster_stack_health() {
    echo "Checking Redis Cluster stack health..."
    
    local failed_nodes=0
    for i in {1..6}; do
        container_name="redis-cluster-redis-${i}-1"
        if docker ps --format "table {{.Names}}" | grep -q "${container_name}"; then
            if docker exec "${container_name}" redis-cli ping 2>/dev/null | grep -q "PONG"; then
                echo "✓ Redis Node ${i}: Responding"
            else
                echo "✗ Redis Node ${i}: Not responding"
                ((failed_nodes++))
            fi
        else
            echo "✗ Redis Node ${i}: Container not running"
            ((failed_nodes++))
        fi
    done
    
    if [ ${failed_nodes} -eq 0 ]; then
        echo "✓ All Redis cluster nodes are healthy"
        return 0
    else
        echo "✗ ${failed_nodes} Redis nodes failed"
        return 1
    fi
}

# Generic health check dispatcher
check_stack_health() {
    local stack_name=$1
    
    case "${stack_name}" in
        "postgresql")
            check_postgresql_stack_health
            ;;
        "mysql")
            check_mysql_health
            ;;
        "mongodb")
            check_mongodb_stack_health
            ;;
        "kafka")
            check_kafka_stack_health
            ;;
        "rabbitmq")
            check_rabbitmq_health && check_web_ui "http://localhost:15672" "RabbitMQ Management"
            ;;
        "redis-cluster")
            check_redis_cluster_stack_health
            ;;
        "minio")
            check_minio_health && check_web_ui "http://localhost:9001" "MinIO Console"
            ;;
        "prometheus-grafana-versus")
            check_prometheus_health && check_grafana_health
            ;;
        "influxdb-grafana")
            check_grafana_health 3000 && check_web_ui "http://localhost:8086" "InfluxDB"
            ;;
        "elasticsearch-logstash-kibana")
            check_kibana_health && check_web_ui "http://localhost:9200" "Elasticsearch"
            ;;
        "jenkins")
            check_jenkins_health
            ;;
        "sonarqube")
            check_sonarqube_stack_health
            ;;
        "wordpress")
            check_web_ui "http://localhost:80" "WordPress"
            ;;
        "certbot")
            check_web_ui "http://localhost:80" "Nginx"
            ;;
        "traefik")
            check_traefik_health
            ;;
        "keycloak")
            check_keycloak_health
            ;;
        *)
            echo "No specific health check available for ${stack_name}"
            return 1
            ;;
    esac
}

# Port mapping for different stacks (based on compose files)
get_stack_ports() {
    local stack_name=$1
    
    case "${stack_name}" in
        "postgresql") echo "5432:postgresql 8080:pgadmin" ;;
        "mysql") echo "3306:mysql" ;;
        "mongodb") echo "27017:mongodb" ;;
        "kafka") echo "9092:kafka 2181:zookeeper 8080:kafka-ui" ;;
        "rabbitmq") echo "5672:rabbitmq 15672:management" ;;
        "redis-cluster") echo "7001:redis-1 7002:redis-2 7003:redis-3 7004:redis-4 7005:redis-5 7006:redis-6" ;;
        "minio") echo "9000:api 9001:console" ;;
        "sonarqube") echo "9000:sonarqube" ;;
        "jenkins") echo "8080:jenkins 50000:agent" ;;
        "elasticsearch-logstash-kibana") echo "9200:elasticsearch 5601:kibana 5044:logstash" ;;
        "prometheus-grafana-versus") echo "9090:prometheus 3000:grafana" ;;
        "influxdb-grafana") echo "8086:influxdb 3000:grafana" ;;
        "wordpress") echo "80:wordpress 3306:mysql" ;;
        "certbot") echo "80:nginx 443:nginx-ssl" ;;
        "traefik") echo "80:traefik 8080:dashboard" ;;
        "keycloak") echo "8080:keycloak" ;;
        *) echo "" ;;
    esac
}

# Check if required ports are available
check_port_availability() {
    local stack_name=$1
    local ports=$(get_stack_ports "${stack_name}")
    local unavailable_ports=()
    
    for port_mapping in ${ports}; do
        local port=$(echo "${port_mapping}" | cut -d':' -f1)
        if netstat -tuln 2>/dev/null | grep -q ":${port} " || lsof -i :${port} 2>/dev/null | grep -q LISTEN; then
            unavailable_ports+=("${port}")
        fi
    done
    
    if [ ${#unavailable_ports[@]} -gt 0 ]; then
        echo "⚠ Warning: Ports in use: ${unavailable_ports[*]}"
        return 1
    fi
    
    return 0
}

# Main function for standalone execution
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <stack_name> [--check-ports]"
        echo "Available stacks: postgresql, mysql, mongodb, kafka, rabbitmq, redis-cluster, minio, prometheus-grafana-versus, influxdb-grafana, elasticsearch-logstash-kibana, jenkins, sonarqube, wordpress, certbot, traefik, keycloak"
        exit 1
    fi
    
    if [ "$2" == "--check-ports" ]; then
        check_port_availability "$1"
    else
        check_stack_health "$1"
    fi
fi