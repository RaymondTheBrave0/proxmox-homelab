#!/bin/bash

# Script to update /etc/hosts with homelab domains

echo "Updating /etc/hosts with homelab domains..."

# Backup current hosts file
sudo cp /etc/hosts /etc/hosts.backup-$(date +%Y%m%d-%H%M%S)

# Remove old entry
sudo sed -i '/nextcloud.local/d' /etc/hosts

# Add new entries
cat << EOF | sudo tee -a /etc/hosts

# Local Proxmox homelab services
192.168.1.49 npm.rtbsoftware.duckdns.org
192.168.1.50 nextcloud.rtbsoftware.duckdns.org
192.168.1.10 proxmox.rtbsoftware.duckdns.org
EOF

echo "✓ Hosts file updated successfully!"
echo ""
echo "You can now access your services at:"
echo "  • https://npm.rtbsoftware.duckdns.org (Nginx Proxy Manager)"
echo "  • https://nextcloud.rtbsoftware.duckdns.org (Nextcloud)"
echo "  • https://proxmox.rtbsoftware.duckdns.org:8006 (Proxmox)"
