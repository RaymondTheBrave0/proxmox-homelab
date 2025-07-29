#!/bin/bash
# Run these commands inside the container

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh

# Install docker-compose
apt install -y docker-compose

# Create directory
mkdir -p /opt/nextcloud
cd /opt/nextcloud

# Create the docker-compose.yml file
# (You'll need to copy the content from nextcloud-docker-compose.yml)

echo "Now copy the docker-compose.yml content to /opt/nextcloud/docker-compose.yml"
echo "Then run: docker-compose up -d"
