#!/bin/bash
# Proxmox Initial Setup Script
# Removes subscription nag and updates system

echo "=== Proxmox Setup Script ==="
echo "This script will:"
echo "1. Remove the subscription nag message"
echo "2. Configure community repositories"
echo "3. Update Proxmox to latest version"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# 1. Remove subscription nag
echo ""
echo "=== Removing subscription nag message ==="
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
sed -i.bak "s/data.status !== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
systemctl restart pveproxy.service
echo "✓ Subscription nag removed"

# 2. Configure repositories
echo ""
echo "=== Configuring repositories ==="
# Remove enterprise repository
rm -f /etc/apt/sources.list.d/pve-enterprise.list
echo "✓ Removed enterprise repository"

# Add no-subscription repository
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
echo "✓ Added community repository"

# 3. Update system
echo ""
echo "=== Updating system ==="
apt update
apt full-upgrade -y

# Check if reboot needed
echo ""
if [ -f /var/run/reboot-required ]; then
    echo "⚠️  REBOOT REQUIRED - Kernel was updated"
    echo "Please reboot your Proxmox server after this script completes"
else
    echo "✓ No reboot required"
fi

echo ""
echo "=== Setup complete! ==="
echo "You may need to clear your browser cache to see the changes."
