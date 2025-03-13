# Redis Cluster Setup with Docker Compose

A Redis Cluster configuration using Docker Compose with best practices.

## Project Structure
```
.
├── .env                 # Environment variables
├── compose.yaml         # Docker Compose configuration
├── redis/
│   ├── redis.conf       # Redis configuration
│   └── nodes.conf       # Redis cluster nodes configuration
└── README.md            # Documentation
```

## Prerequisites

- Docker and Docker Compose installed
- Minimum 2GB RAM allocated to Docker
- Following ports must be available:
  - 6379-6381 (Redis ports)
  - 16379-16381 (Redis cluster ports)

## Installation

1. Clone repository:
```bash
git clone https://github.com/ThuanD/docker_compose_example.git
cd redis-cluster
```

2. Configure environment in `.env` file:
```bash
cp .env.example .env
# Edit values in .env as needed
```

3. Start Redis Cluster:
```bash
docker compose up -d
```

4. Initialize cluster:
```bash
docker exec redis-1 redis-cli --cluster create redis-1:6379 redis-2:6379 redis-3:6379 --cluster-replicas 0 --cluster-yes
```

## Status Check

1. Check container status:
```bash
docker compose ps
```

2. Check cluster status:
```bash
docker exec redis-1 redis-cli cluster info
```

3. Check cluster nodes:
```bash
docker exec redis-1 redis-cli cluster nodes
```

## Configuration

### Environment Variables

The `.env` file contains environment variables:
- `REDIS_IMAGE`: Redis image (default: redis:7.2-alpine)
- `REDIS_CONTAINER_PREFIX`: Prefix for container names
- `REDIS_PASSWORD`: Password for Redis authentication
- `REDIS_PORT_[1-3]`: Ports for Redis nodes
- `REDIS_CLUSTER_PORT_[1-3]`: Ports for cluster communication

### Redis Configuration

The `redis/redis.conf` file contains Redis configuration:
- Cluster mode enabled
- Node timeout: 5000ms
- Append-only file enabled
- Protected mode disabled

## Monitoring

You can monitor the Redis cluster using these commands:

```bash
# Memory usage
docker exec redis-1 redis-cli info memory

# Client connections
docker exec redis-1 redis-cli info clients

# Cluster state
docker exec redis-1 redis-cli cluster info
```

## Backup & Restore

### Backup
```bash
# Backup AOF files
docker compose exec redis-1 redis-cli BGSAVE
```

### Restore
```bash
# Stop containers
docker compose down

# Restore data from backup
cp backup/dump.rdb /path/to/redis/data/

# Restart containers
docker compose up -d
```

## Troubleshooting

### Common Issues

1. **Cluster initialization fails**:
   - Check network connectivity between nodes
   - Ensure ports are not conflicting
   - Check logs: `docker compose logs`

2. **Memory issues**:
   - Increase memory limits in compose.yaml
   - Monitor memory usage: `docker stats`

3. **Connection refused**:
   - Check firewall settings
   - Verify port mappings
   - Check Redis logs

## Maintenance

### Scaling

To add a new node to the cluster:

```bash
# Add new node
docker compose up -d redis-4

# Add node to cluster
docker exec redis-1 redis-cli --cluster add-node \
redis-4:6379 redis-1:6379
```

### Upgrading
```bash
# Pull new images
docker compose pull

# Rolling update
docker compose up -d --no-deps --build
```

## Security Features

- Passwords set through environment variables
- Network isolation implemented
- No-new-privileges security option enabled
- Read-only filesystem where possible
- Resource limits configured

## Best Practices Implemented

1. **Security**:
   - Password protection
   - Network isolation
   - Security options
   - Limited privileges

2. **Performance**:
   - Resource limits
   - Optimized configuration
   - Monitoring capabilities

3. **Reliability**:
   - Health checks
   - Automatic restarts
   - Backup/restore procedures

4. **Maintainability**:
   - Environment variables
   - Clear documentation
   - Modular configuration

## License

[MIT License](LICENSE)

---

**Note**: This is a production-ready setup following Docker Compose best practices. For development environments, you may want to adjust resource limits and security settings accordingly.
