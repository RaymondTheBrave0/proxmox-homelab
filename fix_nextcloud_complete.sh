#!/bin/bash

echo "Completely fixing Nextcloud configuration..."

# Update config with all necessary domains
ssh root@192.168.1.10 "pct exec 101 -- docker exec nextcloud-app-1 bash -c \"
# Backup current config
cp /var/www/html/config/config.php /var/www/html/config/config.php.bak

# Use occ to add trusted domains
php occ config:system:set trusted_domains 0 --value='192.168.1.50:8080'
php occ config:system:set trusted_domains 1 --value='nextcloud.rtbsoftware.duckdns.org'
php occ config:system:set trusted_domains 2 --value='nextcloud.local'
php occ config:system:set trusted_domains 3 --value='192.168.1.50'

# Set overwrite settings
php occ config:system:set overwritehost --value='nextcloud.rtbsoftware.duckdns.org'
php occ config:system:set overwriteprotocol --value='https'
php occ config:system:set overwrite.cli.url --value='https://nextcloud.rtbsoftware.duckdns.org'

# Add trusted proxy
php occ config:system:set trusted_proxies 0 --value='192.168.1.49'

# Clear all caches
php occ cache:clear
php occ maintenance:repair
\""

echo "Restarting Nextcloud..."
ssh root@192.168.1.10 "pct exec 101 -- docker restart nextcloud-app-1"

echo "Waiting for Nextcloud to start..."
sleep 15

echo "Testing direct access..."
if curl -s -I http://192.168.1.50:8080 2>/dev/null | grep -q "302 Found"; then
    LOCATION=$(curl -s -I http://192.168.1.50:8080 2>/dev/null | grep "Location:" | cut -d' ' -f2)
    echo "Nextcloud redirects to: $LOCATION"
fi

echo ""
echo "Configuration complete! Try accessing:"
echo "1. https://nextcloud.rtbsoftware.duckdns.org"
echo "2. Clear your browser cache/cookies or try incognito mode"
echo "3. If still redirecting to nextcloud.local, we may need to reset the installation"
