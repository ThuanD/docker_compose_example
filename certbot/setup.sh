#!/bin/bash

# Prompt for configuration
read -p "Enter your domain (without www): " domain
read -p "Enter your email: " email
read -p "Enter your environment (develop/staging/production): " env

# Validate inputs
if [ -z "$domain" ] || [ -z "$email" ] || [ -z "$env" ]; then
    echo "Error: All fields are required"
    exit 1
fi

# Validate email format
if ! echo "$email" | grep -E "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$" > /dev/null; then
    echo "Error: Invalid email format"
    exit 1
fi

# Validate environment
if [[ ! "$env" =~ ^(develop|staging|production)$ ]]; then
    echo "Error: Environment must be either 'develop', 'staging', or 'production'"
    exit 1
fi

# Generate configuration files from templates
echo "Generating configuration files from templates..."

# Generate Nginx config
sed "s/test.example/$domain/g" nginx/conf.d/default.conf.template > nginx/conf.d/default.conf

# Generate init-letsencrypt.sh
sed -e "s/email=your-email@test.example/$email/g" \
    -e "s/test.example/$domain/g" \
    -e "s/env=develop/env=$env/g" \
    init-letsencrypt.sh.template > init-letsencrypt.sh

# Make init script executable
chmod +x init-letsencrypt.sh

echo "==================================="
echo "Configuration updated successfully!"
echo "Environment: $env"
echo "Domain: $domain (www.$domain)"
echo "Email: $email"
echo ""
echo "You can now run: ./init-letsencrypt.sh" 