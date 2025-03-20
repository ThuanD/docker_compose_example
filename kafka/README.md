# Kafka and Zookeeper with Docker Compose

A simple way to set up Kafka, Zookeeper, and UI management with Docker Compose, following best practices.

## Project Structure

```
.
├── .env           # Environment variables
├── compose.yaml   # Docker Compose configuration
└── README.md      # Documentation
```

## System Requirements

- Docker and Docker Compose installed
- Minimum 2GB RAM allocated to Docker
- The following ports must be available on the host:
  - 2181 (Zookeeper)
  - 9092, 9093 (Kafka)
  - 8080 (Kafka UI)

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/ThuanD/docker_compose_example.git
cd kafka
```

2. (Optional) Configure environment variables by editing the `.env` file

3. Start the Kafka stack:
```bash
docker compose up -d
```

4. Check running services:
```bash
docker compose ps
```

## Accessing Services

When the stack is running, you can access:

- **Kafka UI**: http://localhost:8080
- **Kafka**: localhost:9092 (internal), localhost:9093 (external)
- **Zookeeper**: localhost:2181

## Using Kafka

### Create a topic
```bash
docker exec -it kafka kafka-topics.sh --create --topic my-topic --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
```

### List topics
```bash
docker exec -it kafka kafka-topics.sh --list --bootstrap-server localhost:9092
```

### Send messages
```bash
docker exec -it kafka kafka-console-producer.sh --broker-list localhost:9092 --topic my-topic
```

### Receive messages
```bash
docker exec -it kafka kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --from-beginning
```

## Configuration

### Environment Variables

The stack can be customized using environment variables in the `.env` file:

- `KAFKA_IMAGE`: Docker image for Kafka (default: wurstmeister/kafka:latest)
- `KAFKA_PORT`: Internal Kafka port (default: 9092)
- `KAFKA_EXTERNAL_PORT`: External Kafka port (default: 9093)
- `KAFKA_CREATE_TOPICS`: List of topics to create upon startup (default: "topic1:1:1,topic2:1:1")
- `ZOOKEEPER_IMAGE`: Docker image for Zookeeper (default: wurstmeister/zookeeper:latest)
- `ZOOKEEPER_PORT`: Zookeeper port (default: 2181)

See the `.env` file for a complete list of variables.

## Scaling for Production

For production environments, consider the following adjustments:

1. Increase the number of Kafka brokers to ensure high availability
2. Configure authentication and SSL/TLS encryption
3. Set up a Zookeeper cluster with 3 or 5 nodes
4. Optimize Kafka parameters such as `num.partitions`, `log.retention.hours`, `log.retention.bytes`
5. Use separately managed storage volumes for data

## Data Persistence

Data is stored in Docker volumes:
- `zookeeper_data`: Zookeeper data
- `zookeeper_logs`: Zookeeper logs
- `kafka_data`: Kafka data

## Troubleshooting

### View logs
```bash
# View logs from all services
docker logs

# View logs from a specific service
docker logs zookeeper
docker logs kafka
docker logs kafka-ui
```

### Kafka cannot connect to Zookeeper

If Kafka cannot connect to Zookeeper, check the Zookeeper logs and ensure it's running:

```bash
docker logs zookeeper
```

## Cleanup

To stop and remove containers, networks, and volumes:

```bash
# Remove containers and networks, keep volumes
docker compose down

# Remove everything including volumes
docker compose down -v
```