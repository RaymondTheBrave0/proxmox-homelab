#!/bin/bash

# Script to copy docx files from local posts directory to Nextcloud

SOURCE_DIR="/home/raymond/Documents/posts"
TEMP_DIR="/tmp/posts_upload_$(date +%s)"

echo "Copying DOCX files to Nextcloud..."

# Create temp directory
mkdir -p "$TEMP_DIR"

# Copy only docx files to temp directory
echo "Copying files to temporary directory..."
cp "$SOURCE_DIR"/*.docx "$TEMP_DIR/"

# Transfer to Proxmox host
echo "Transferring files to Proxmox host..."
scp -r "$TEMP_DIR" root@192.168.1.10:/tmp/

# Copy into container and then into Docker
echo "Moving files into Nextcloud container..."
TEMP_BASENAME=$(basename "$TEMP_DIR")

# Copy to container 101
ssh root@192.168.1.10 "pct push 101 /tmp/$TEMP_BASENAME -r /tmp/"

# Copy into Docker container
ssh root@192.168.1.10 "pct exec 101 -- docker cp /tmp/$TEMP_BASENAME/. nextcloud-app-1:/tmp/docx_upload/"

# Move files to Nextcloud data directory and set permissions
echo "Installing files in Nextcloud..."
ssh root@192.168.1.10 "pct exec 101 -- docker exec nextcloud-app-1 bash -c 'mkdir -p /var/www/html/data/raymond/files/posts && mv /tmp/docx_upload/*.docx /var/www/html/data/raymond/files/posts/ && chown -R www-data:www-data /var/www/html/data/raymond/files/posts'"

# Scan files in Nextcloud
echo "Scanning files in Nextcloud..."
ssh root@192.168.1.10 "pct exec 101 -- docker exec -u www-data nextcloud-app-1 php occ files:scan raymond"

# Cleanup
rm -rf "$TEMP_DIR"
ssh root@192.168.1.10 "rm -rf /tmp/$TEMP_BASENAME"

echo "Done! Files have been uploaded to Nextcloud in the 'posts' folder."
echo "You can access them at: http://192.168.1.50:8080"
echo "Or via: https://nextcloud.rtbsoftware.duckdns.org"
