# Elasticsearch, Logstash, and Kibana (ELK) Stack

A complete ELK stack setup with Docker Compose, following best practices for development and production deployments.

## Project Structure

```
.
├── .env                  # Environment variables
├── compose.yaml          # Docker Compose configuration
├── logstash/
│   ├── pipeline/         # Logstash pipeline configurations
│   │   └── logstash-nginx.config  # Nginx logs pipeline config
│   └── nginx.log         # Example Nginx logs
└── README.md             # This documentation
```

## Prerequisites

- Docker and Docker Compose installed
- Minimum 4GB of RAM allocated to Docker
- Ports 9200, 5601, 5044, 9600, 5000 available on your host

## Quick Start

1. Clone this repository:

```bash
git clone https://github.com/ThuanD/docker_compose_example.git
cd elasticsearch-logstash-kibana
```

2. (Optional) Configure environment variables by editing the `.env` file

3. Start the ELK stack:
```bash
docker compose up -d
```

4. Verify services are running:

```bash
docker compose ps
```

## Accessing the Services

Once the stack is running, you can access:

- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601
- **Logstash API**: http://localhost:9600

## Configuration

### Environment Variables

The stack can be customized using environment variables in the `.env` file:

- `ES_IMAGE`: Elasticsearch image (default: elasticsearch:7.16.1)
- `ES_JAVA_OPTS`: Java options for Elasticsearch (default: -Xms512m -Xmx512m)
- `ES_SECURITY_ENABLED`: Enable X-Pack security (default: false)
- `LOGSTASH_IMAGE`: Logstash image (default: logstash:7.16.1)
- `LS_JAVA_OPTS`: Java options for Logstash (default: -Xms512m -Xmx512m)
- `KIBANA_IMAGE`: Kibana image (default: kibana:7.16.1)

See the `.env` file for the complete list of variables.

### Logstash Configuration

Logstash is configured to parse Nginx logs from the `logstash/nginx.log` file. The pipeline configuration in `logstash/pipeline/logstash-nginx.config` handles:

- Reading logs from file
- Parsing JSON format
- Performing GeoIP lookup on IP addresses
- Extracting user agent information
- Sending processed logs to Elasticsearch

## Scaling for Production

For production environments, consider the following adjustments:

1. Increase Java heap size for Elasticsearch and Logstash in `.env`
2. Enable X-Pack security by setting `ES_SECURITY_ENABLED=true`
3. Set strong passwords for Elasticsearch and Kibana users
4. Configure a proper backup strategy for your data
5. Use a reverse proxy for TLS termination

## Data Persistence

Data is persisted in Docker volumes:
- `elasticsearch_data`: Elasticsearch data
- `kibana_data`: Kibana data

## Troubleshooting

### Elasticsearch Fails to Start

If Elasticsearch fails to start, you might need to increase virtual memory limits:

```bash
# On the host machine
sudo sysctl -w vm.max_map_count=262144
```

To make this change permanent, add to `/etc/sysctl.conf`:

```
vm.max_map_count=262144
```

### Viewing Logs

```bash
# View logs from all services
docker compose logs

# View logs from a specific service
docker compose logs elasticsearch
docker compose logs logstash
docker compose logs kibana
```

## Clean Up

To stop and remove the containers, networks, and volumes:

```bash
# Remove containers and networks, keep volumes
docker compose down

# Remove everything including volumes
docker compose down -v
```

## Attribution

The example Nginx logs are copied from [Elastic examples repository](https://github.com/elastic/examples/blob/master/Common%20Data%20Formats/nginx_json_logs/nginx_json_logs).