# Compose Sample
## Prometheus & Grafana

A monitoring stack with Prometheus and Grafana using Docker Compose with best practices.

## Project structure

```
.
├── .env                   # Environment variables
├── compose.yaml           # Main Docker Compose configuration
├── grafana
│   └── datasource.yml     # Grafana datasource configuration
├── prometheus
│   └── prometheus.yml     # Prometheus configuration
└── README.md              # This documentation
```

## Overview

[_compose.yaml_](compose.yaml)
```yaml
services:
  prometheus:
    image: ${PROMETHEUS_IMAGE:-prom/prometheus:latest}
    container_name: ${PROMETHEUS_CONTAINER_NAME:-prometheus}
    # Additional configurations...
    ports:
      - ${PROMETHEUS_PORT:-9090}:9090
    
  grafana:
    image: ${GRAFANA_IMAGE:-grafana/grafana:latest}
    container_name: ${GRAFANA_CONTAINER_NAME:-grafana}
    # Additional configurations...
    ports:
      - ${GRAFANA_PORT:-3000}:3000
```

The compose file defines a monitoring stack with two services:
- `prometheus`: Collects and stores metrics in a time series database
- `grafana`: Visualizes the metrics collected by Prometheus

When deploying the stack, Docker Compose maps the default ports for each service to the equivalent ports on the host to make it easier to access the web interfaces.

**Note**: Make sure the ports 9090 and 3000 on the host are not already in use.

## Deploy with Docker Compose

```bash
# Start services in detached mode
$ docker compose up -d

Creating network "prometheus-grafana_default" with the default driver
Creating volume "prometheus-grafana_prom_data" with default driver
...
Creating grafana    ... done
Creating prometheus ... done
Attaching to prometheus, grafana
```

## Expected Result

Listing containers must show two containers running and the port mapping as below:

```bash
$ docker ps
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS                    PORTS                    NAMES
abc123def456   prom/prometheus       "/bin/prometheus --c…"   20 seconds ago   Up 19 seconds (healthy)   0.0.0.0:9090->9090/tcp   prometheus
789xyz123abc   grafana/grafana       "/run.sh"                20 seconds ago   Up 19 seconds (healthy)   0.0.0.0:3000->3000/tcp   grafana
```

## Accessing the Web Interfaces

### Grafana
- Navigate to `http://localhost:3000` in your web browser
- Use the login credentials specified in the .env file (default: admin/grafana)
- Grafana is pre-configured with Prometheus as the default datasource

![Grafana Dashboard](https://grafana.com/static/assets/img/blog/7.0/explore_prometheus_split.gif)

### Prometheus
- Navigate to `http://localhost:9090` in your web browser to access the Prometheus web interface
- You can use the Prometheus interface to query metrics and check the status of scrape targets

## Configuration Files

### .env
Contains environment variables for customizing the stack:
- PROMETHEUS_IMAGE: Image for Prometheus (default: prom/prometheus:latest)
- PROMETHEUS_PORT: Host port for Prometheus (default: 9090)
- GRAFANA_IMAGE: Image for Grafana (default: grafana/grafana:latest)
- GRAFANA_PORT: Host port for Grafana (default: 3000)
- GRAFANA_ADMIN_USER: Grafana admin username (default: admin)
- GRAFANA_ADMIN_PASSWORD: Grafana admin password (default: grafana)

### prometheus/prometheus.yml
The main Prometheus configuration file that defines:
- Global settings (scrape intervals, evaluation intervals)
- Alerting rules
- Scrape configurations defining what to monitor

### grafana/datasource.yml
Preconfigures Grafana with Prometheus as the default data source.

## Adding More Monitoring Targets

To monitor additional services, add them to the `prometheus.yml` file under `scrape_configs`:

```yaml
scrape_configs:
  # Existing configs...
  
  - job_name: 'new-service'
    static_configs:
      - targets: ['new-service:8080']
```

## Clean Up

Stop and remove the containers, networks, and volumes:

```bash
# Remove everything including volumes
$ docker compose down -v
```

## Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Query Language (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/)