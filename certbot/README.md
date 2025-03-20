# Certbot with Nginx

A setup for Certbot and Nginx to automate SSL/TLS certificate management with Let's Encrypt.

## Project Structure

```
.
├── certbot/
│   ├── conf/             # Let's Encrypt certificates directory
│   └── www/              # Webroot for ACME verification
├── nginx/                # Nginx configuration
│   ├── conf.d/           # Site configurations
│   │   └── default.conf  # Default configuration
│   └── nginx.conf        # Main Nginx configuration
├── static/               # Static website content
├── .env                  # Environment variables
├── compose.yaml          # Docker Compose configuration
├── init-letsencrypt.sh   # Certificate initialization script
├── README.md             # This documentation
└── setup.sh              # Initial setup script
```

## Requirements

- Docker and Docker Compose installed
- Domain name pointed to your server's public IP
- Ports 80 and 443 open and forwarded to your server

## Quick Start

1. Clone this repository:
```bash
git clone https://github.com/ThuanD/docker_compose_example.git
cd certbot
```

2. Run the setup script and follow the prompts:
```bash
./setup.sh
````
The setup script will:
- Ask for your domain and email
- Ask if you want to use staging environment
- Update configuration files automatically
- Run init-letsencrypt.sh to obtain certificates


3. Run init-letsencrypt.sh to obtain certificates:

```bash
./init-letsencrypt.sh
```

4. Host mapping (develop only)
```bash
sudo tee -a /etc/hosts <<< '127.0.0.1 domain-name-you-entered'
sudo tee -a /etc/hosts <<< '127.0.0.1 www.domain-name-you-entered'
```

5. Your SSL certificates are now set up and Nginx is running with HTTPS!

## Testing the Setup

1. Check if services are running:

```bash
docker compose ps
```

2. Test HTTPS:
- Visit https://yourdomain.com
- You should see the test page over a secure connection
- If you are building for development, you can proceed despite browser security warnings

3. Check certificate status:
```bash
docker compose run --rm certbot certificates
```

4. Start Certbot for automatic renewal:
```bash
docker compose up -d certbot
```

## Custom Configuration

### Environment Variables

The stack can be customized using environment variables in the `.env` file:

- `NGINX_IMAGE`: Docker image for Nginx (default: nginx:alpine)
- `NGINX_HTTP_PORT`: HTTP port (default: 80)
- `NGINX_HTTPS_PORT`: HTTPS port (default: 443)
- `CERTBOT_IMAGE`: Docker image for Certbot (default: certbot/certbot:latest)
- `CERTBOT_RENEW_INTERVAL`: Time between certificate renewal attempts (default: 12h)

### Adding a New Domain

To add a new domain:

1. Add a new site configuration in nginx/conf.d/
2. Obtain certificate for the new domain:
```bash
docker compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot \
    --email your-email@test.example --agree-tos --no-eff-email \
    -d newdomain.com -d www.newdomain.com
```
3. Restart Nginx:
```bash
docker compose restart nginx
```

## Certificate Renewal

Certificates will be automatically renewed by the Certbot container. 
The renewal process checks if any certificates need renewing and handles them appropriately.

### Manual Certificate Renewal

To manually renew certificates:

```bash
docker compose run --rm certbot renew
```

### Force Certificate Renewal

To force renewal of a certificate regardless of expiration date:

```bash
docker compose run --rm certbot renew --force-renewal -d test.example
```

### Checking Certificate Expiration

To check when your certificates expire:

```bash
docker compose run --rm certbot certificates
```

## Data Persistence

Certbot certificates and configuration files are stored in the certbot/conf directory on the host.

## Troubleshooting

### Checking Logs

```bash
# Nginx logs
docker compose logs nginx

# Certbot logs
docker compose logs certbot
```

### Let's Encrypt Rate Limits

Let's Encrypt has rate limits. To avoid hitting limits during testing, use the staging environment:

```bash
docker compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot \
    --staging --email your-email@test.example --agree-tos --no-eff-email \
    -d test.example -d www.test.example
```

After configuration works with staging certificates, delete the staging certificates and get production ones:

```bash
docker compose run --rm certbot delete --cert-name test.example
# Then run the certificate command again without the --staging flag
```

### Common Issues

1. Certificate not found: Make sure the domain in the nginx config matches exactly with the certificate domain
2. Permission denied: Check that the volumes are mounted correctly and have proper permissions
3. Connection refused: Ensure ports 80 and 443 are open in your firewall

## Security

The Nginx configuration includes good security practices:
- Only uses TLSv1.2 and TLSv1.3
- Strong cipher suite
- Server tokens disabled
- HTTP to HTTPS redirection

## Additional Considerations

1. Firewall: Make sure to only allow ports 80 and 443 in your firewall
2. WWW Redirection: Configuration already includes redirect from www to non-www (or vice versa if needed)
3. HTTP/2: Nginx is configured to use HTTP/2 for HTTPS connections
4. Security Headers: Consider adding security headers like HSTS, CSP, X-Content-Type-Options, etc.