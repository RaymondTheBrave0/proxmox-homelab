#!/bin/bash

# Setup Samba share for Nextcloud data directory on Proxmox container 101

echo "Setting up Samba share for Nextcloud..."

# Install Samba in container 101
ssh root@192.168.1.10 "pct exec 101 -- apt-get update && apt-get install -y samba"

# Create a directory that will be bind-mounted to the Docker volume
ssh root@192.168.1.10 "pct exec 101 -- mkdir -p /mnt/nextcloud-share"

# Create Samba configuration
ssh root@192.168.1.10 "pct exec 101 -- bash -c 'cat >> /etc/samba/smb.conf << EOF

[nextcloud-data]
    path = /var/lib/docker/volumes/nextcloud_data/_data
    browseable = yes
    writable = yes
    valid users = root
    force user = www-data
    force group = www-data
    create mask = 0664
    directory mask = 0775
EOF'"

# Set Samba password for root
echo "Please enter a password for Samba access:"
ssh root@192.168.1.10 "pct exec 101 -- smbpasswd -a root"

# Restart Samba
ssh root@192.168.1.10 "pct exec 101 -- systemctl restart smbd"

echo "Samba share configured!"
echo "You can now access it from your Ubuntu machine at:"
echo "smb://192.168.1.49/nextcloud-data"
echo ""
echo "In your file manager (Thunar/Files), press Ctrl+L and enter:"
echo "smb://192.168.1.49/nextcloud-data"
echo ""
echo "Use username: root and the password you just set"
