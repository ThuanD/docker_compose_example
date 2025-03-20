# Jenkins with Docker Compose

A Jenkins setup with Docker Compose, following best practices for development and production deployments.

## Project Structure

```
.
├── .env                # Environment variables
├── compose.yaml        # Docker Compose configuration
└── README.md           # This documentation
```

## Prerequisites

- Docker and Docker Compose installed
- Minimum 2GB RAM allocated to Docker
- Ports 8080 and 50000 available on your host

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/ThuanD/docker_compose_example.git
cd jenkins
```

2. (Optional) Configure environment variables by editing the `.env` file

3. Start Jenkins:
```bash
docker compose up -d
```

4. Get the initial admin password:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

5. Access Jenkins via a browser and complete the setup:
   - Open http://localhost:8080
   - Enter the initial admin password
   - Install suggested plugins or choose custom plugins
   - Create the first admin user
   - Start using Jenkins!

## Configuration

### Environment Variables

Jenkins can be customized through environment variables in the `.env` file:

- `JENKINS_IMAGE`: Jenkins image (default: jenkins/jenkins:lts)
- `JENKINS_PORT`: Port for Jenkins web interface (default: 8080)
- `JENKINS_AGENT_PORT`: Port for Jenkins agents (default: 50000)
- `JENKINS_PREFIX`: URL prefix for Jenkins (default: /)
- `JENKINS_JAVA_OPTS`: JVM options for Jenkins (default: -Xms512m -Xmx1024m)

### Adding Plugins

To install plugins automatically when Jenkins starts up, create a plugins.txt file and mount it into the container:

1. Create a plugins.txt file with a list of plugins:
```
workflow-aggregator
git
docker-workflow
blueocean
```

2. Update compose.yaml to add a new volume:
```yaml
volumes:
  - ./plugins.txt:/usr/share/jenkins/ref/plugins.txt
```

## Configuring Jenkins as a Service

To set up Jenkins running behind a reverse proxy (like Nginx):

1. Update the `JENKINS_PREFIX` variable in `.env` to your desired path (e.g., `/jenkins`)

2. Configure Nginx to forward requests to Jenkins. Example:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /jenkins {
        proxy_pass http://jenkins:8080/jenkins;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Data Persistence

Jenkins data is stored in Docker volume:
- `jenkins_home`: Contains all Jenkins data, configuration, and state

## Backup and Restore

### Backup

To backup Jenkins data:

```bash
# Pause Jenkins before backup
docker compose stop

# Backup volume
docker run --rm -v jenkins_jenkins_home:/source -v $(pwd)/backup:/backup alpine sh -c "cd /source && tar czf /backup/jenkins_backup_$(date +%Y%m%d).tar.gz ."

# Restart Jenkins
docker compose start
```

### Restore

To restore Jenkins data from a backup:

```bash
# Stop Jenkins
docker compose down

# Remove current volume (careful!)
docker volume rm jenkins_jenkins_home

# Recreate volume
docker volume create jenkins_jenkins_home

# Restore from backup
docker run --rm -v jenkins_jenkins_home:/target -v $(pwd)/backup:/backup alpine sh -c "tar xzf /backup/jenkins_backup_YYYYMMDD.tar.gz -C /target"

# Restart Jenkins
docker compose up -d
```

## Troubleshooting

### Jenkins won't start

Check container logs:
```bash
docker compose logs jenkins
```

### Permission issues

If Jenkins has problems with permissions to /var/jenkins_home:
```bash
docker exec -it jenkins bash
chown -R jenkins:jenkins /var/jenkins_home
```

### Can't use Docker in pipelines

Make sure the jenkins user in the container has access to the Docker socket:
```bash
docker exec -it jenkins bash
usermod -aG docker jenkins
```

## Production Considerations

1. Security:
   - Use HTTPS by configuring a reverse proxy
   - Limit access to the Docker socket
   - Perform regular updates

2. Performance:
   - Increase resources for the Jenkins container in busy environments
   - Consider using Jenkins agents for distributed builds

3. Reliability:
   - Set up automated backups
   - Implement monitoring and alerting
