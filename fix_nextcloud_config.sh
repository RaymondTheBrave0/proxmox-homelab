#!/bin/bash

echo "Fixing Nextcloud configuration..."

# Update the config.php to allow access from multiple domains
ssh root@192.168.1.10 "pct exec 101 -- docker exec nextcloud-app-1 bash -c \"
cd /var/www/html/config
cp config.php config.php.backup

# Use PHP to modify the config properly
php -r \\\"
\\\$config = include 'config.php';
\\\$config['trusted_domains'] = array(
    '192.168.1.50:8080',
    'nextcloud.local',
    'nextcloud.rtbsoftware.duckdns.org',
    '192.168.1.50'
);
unset(\\\$config['overwritehost']);
unset(\\\$config['overwriteprotocol']);
unset(\\\$config['overwritewebroot']);
\\\$config['overwrite.cli.url'] = 'http://192.168.1.50:8080';
file_put_contents('config.php', '<?php\n\\\$CONFIG = ' . var_export(\\\$config, true) . ';\n');
\\\"
\""

echo "Configuration updated. Restarting Nextcloud container..."
ssh root@192.168.1.10 "pct exec 101 -- docker restart nextcloud-app-1"

echo "Waiting for Nextcloud to start..."
sleep 10

echo "Testing access..."
if curl -s -I http://192.168.1.50:8080 | grep -q "200 OK\|302 Found"; then
    echo "✓ Nextcloud is accessible!"
    echo ""
    echo "You can now access Nextcloud at:"
    echo "  - http://192.168.1.50:8080"
    echo "  - https://nextcloud.rtbsoftware.duckdns.org (through your proxy)"
    echo ""
    echo "For WebDAV access in file manager, use:"
    echo "  - dav://192.168.1.50:8080/remote.php/dav/files/raymond/"
else
    echo "✗ There might still be an issue. Please check the logs."
fi
