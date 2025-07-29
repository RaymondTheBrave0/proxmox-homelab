#!/bin/bash

# Nextcloud Container Replacement Script for Proxmox
# This script will help you replace the existing Nextcloud container with a fresh one

set -e

echo "=== Nextcloud Container Replacement Script ==="
echo "This script will guide you through replacing your Nextcloud container"
echo ""

# Configuration variables
CONTAINER_ID="100"  # Using the same ID as your current Nextcloud
CONTAINER_NAME="nextcloud"  # Keeping the same name
CONTAINER_IP="192.168.1.50"  # Keeping the same IP
CONTAINER_GATEWAY="192.168.1.1"
CONTAINER_MEMORY="4096"  # 4GB RAM
CONTAINER_DISK="32"  # 32GB disk
CONTAINER_CORES="4"
DOMAIN="nextcloud.rtbsoftware.duckdns.org"
PROXY_IP="192.168.1.49"

echo "Configuration:"
echo "  Container ID: $CONTAINER_ID"
echo "  Container Name: $CONTAINER_NAME"
echo "  Container IP: $CONTAINER_IP"
echo "  Domain: $DOMAIN"
echo "  Proxy IP: $PROXY_IP"
echo ""
echo "WARNING: This will replace your existing Nextcloud container!"
echo "Press Enter to continue or Ctrl+C to cancel..."
read

# Create docker-compose file with correct configuration from the start
cat > nextcloud-docker-compose.yml << EOF
version: '3.8'

services:
  nextcloud:
    image: nextcloud:latest
    container_name: nextcloud
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      # Critical: Set the correct domain from the start
      - NEXTCLOUD_TRUSTED_DOMAINS=${DOMAIN} ${CONTAINER_IP} localhost
      - TRUSTED_PROXIES=${PROXY_IP}
      - OVERWRITEPROTOCOL=https
      - OVERWRITEHOST=${DOMAIN}
      - OVERWRITECLIURL=https://${DOMAIN}
      - OVERWRITEWEBROOT=/
      # Database settings
      - MYSQL_HOST=nextcloud-db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud_secure_password
      # Admin account
      - NEXTCLOUD_ADMIN_USER=raymond
      - NEXTCLOUD_ADMIN_PASSWORD=changeme123  # CHANGE THIS!
    volumes:
      - nextcloud_data:/var/www/html
      - nextcloud_config:/var/www/html/config
      - nextcloud_custom_apps:/var/www/html/custom_apps
      - nextcloud_themes:/var/www/html/themes
    depends_on:
      - db
    networks:
      - nextcloud-net

  db:
    image: mariadb:10
    container_name: nextcloud-db
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=root_secure_password
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=nextcloud_secure_password
    volumes:
      - nextcloud_db:/var/lib/mysql
    networks:
      - nextcloud-net

volumes:
  nextcloud_data:
  nextcloud_config:
  nextcloud_custom_apps:
  nextcloud_themes:
  nextcloud_db:

networks:
  nextcloud-net:
    driver: bridge
EOF

echo "Docker Compose file created: nextcloud-docker-compose.yml"
echo ""
echo "=== Steps to Execute on Proxmox ==="
echo ""
echo "1. SSH into your Proxmox host:"
echo "   ssh raymond@192.168.1.10"
echo ""
echo "2. OPTIONAL - Backup existing data (if you want to preserve it):"
echo "   # Create backup directory"
echo "   mkdir -p /root/nextcloud-backup"
echo "   "
echo "   # Enter the container"
echo "   pct enter $CONTAINER_ID"
echo "   "
echo "   # Inside container, create backup"
echo "   cd /"
echo "   tar -czf /tmp/nextcloud-data-backup.tar.gz /var/www/html/data 2>/dev/null || true"
echo "   exit"
echo "   "
echo "   # Copy backup from container"
echo "   pct pull $CONTAINER_ID /tmp/nextcloud-data-backup.tar.gz /root/nextcloud-backup/data-backup.tar.gz"
echo ""
echo "3. Stop and destroy the existing container:"
echo "   pct stop $CONTAINER_ID"
echo "   pct destroy $CONTAINER_ID"
echo ""
echo "4. Create new container with same settings:"
echo "   pct create $CONTAINER_ID /var/lib/vz/template/cache/debian-12-standard_12.2-1_amd64.tar.zst \\"
echo "     --hostname $CONTAINER_NAME \\"
echo "     --memory $CONTAINER_MEMORY \\"
echo "     --cores $CONTAINER_CORES \\"
echo "     --rootfs local-lvm:$CONTAINER_DISK \\"
echo "     --net0 name=eth0,bridge=vmbr0,ip=$CONTAINER_IP/24,gw=$CONTAINER_GATEWAY \\"
echo "     --features nesting=1 \\"
echo "     --unprivileged 1 \\"
echo "     --start 1"
echo ""
echo "5. Enter the new container:"
echo "   pct enter $CONTAINER_ID"
echo ""
echo "6. Inside the container, set up Docker and Nextcloud:"
cat > setup-inside-container.sh << 'INNERSCRIPT'
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
INNERSCRIPT

echo ""
echo "7. After Nextcloud is running, update Nginx Proxy Manager:"
echo "   - Go to http://$PROXY_IP:81"
echo "   - Edit the proxy host for $DOMAIN"
echo "   - Ensure these settings:"
echo "     * Scheme: http (NOT https)"
echo "     * Forward Hostname/IP: $CONTAINER_IP"
echo "     * Forward Port: 80"
echo "     * Cache Assets: OFF"
echo "     * Block Common Exploits: ON"
echo "     * Websockets Support: ON"
echo "   - In SSL tab:"
echo "     * Force SSL: ON"
echo "     * HTTP/2 Support: ON"
echo ""
echo "=== Important Notes ==="
echo "- The admin password in docker-compose.yml is set to 'changeme123' - CHANGE THIS!"
echo "- Database passwords should also be changed for production use"
echo "- This setup ensures the domain is correctly configured from the start"
echo "- No more redirects to 'nextcloud.local'!"
echo ""
echo "Ready to proceed!"
