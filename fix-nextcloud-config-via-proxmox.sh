#!/bin/bash

# Fix Nextcloud configuration via Proxmox
# This script updates Nextcloud configuration to fix domain redirect issues

echo "Fixing Nextcloud configuration via Proxmox..."

# First, update the config.php file
echo "Updating Nextcloud config.php..."

ssh root@192.168.1.10 << 'EOF'
# Create a script to update the config inside the container
pct exec 101 -- bash -c "cat > /tmp/fix_nextcloud_config.sh << 'SCRIPT'
#!/bin/bash

# Update config.php using Docker
docker exec nextcloud-app-1 bash -c \"
# Create PHP script to update config
cat > /tmp/update_config.php << 'PHP'
<?php
\\\$configfile = '/var/www/html/config/config.php';
require \\\$configfile;

// Remove nextcloud.local from trusted domains
\\\$new_trusted_domains = array();
foreach(\\\$CONFIG['trusted_domains'] as \\\$domain) {
    if(\\\$domain !== 'nextcloud.local') {
        \\\$new_trusted_domains[] = \\\$domain;
    }
}

// Ensure our domain is in trusted domains
if(!in_array('nextcloud.rtbsoftware.duckdns.org', \\\$new_trusted_domains)) {
    \\\$new_trusted_domains[] = 'nextcloud.rtbsoftware.duckdns.org';
}

// Update configuration
\\\$CONFIG['trusted_domains'] = array_values(\\\$new_trusted_domains);
\\\$CONFIG['overwritehost'] = 'nextcloud.rtbsoftware.duckdns.org';
\\\$CONFIG['overwriteprotocol'] = 'https';
\\\$CONFIG['overwrite.cli.url'] = 'https://nextcloud.rtbsoftware.duckdns.org';
\\\$CONFIG['trusted_proxies'] = array('192.168.1.49');
\\\$CONFIG['forwarded_for_headers'] = array('HTTP_X_FORWARDED_FOR');

// Write the configuration
\\\$content = '<?php' . PHP_EOL . '\\\$CONFIG = ' . var_export(\\\$CONFIG, true) . ';' . PHP_EOL;
file_put_contents(\\\$configfile, \\\$content);

echo 'Config updated successfully';
PHP

# Run the PHP script
php /tmp/update_config.php

# Clean up
rm /tmp/update_config.php
\"

# Now use occ commands to ensure settings are applied
echo 'Applying settings with occ...'
docker exec -u www-data nextcloud-app-1 php occ config:system:set trusted_domains 0 --value='nextcloud.rtbsoftware.duckdns.org'
docker exec -u www-data nextcloud-app-1 php occ config:system:set overwritehost --value='nextcloud.rtbsoftware.duckdns.org'
docker exec -u www-data nextcloud-app-1 php occ config:system:set overwriteprotocol --value='https'
docker exec -u www-data nextcloud-app-1 php occ config:system:set overwrite.cli.url --value='https://nextcloud.rtbsoftware.duckdns.org'
docker exec -u www-data nextcloud-app-1 php occ config:system:set trusted_proxies 0 --value='192.168.1.49'

# Clear caches
echo 'Clearing caches...'
docker exec -u www-data nextcloud-app-1 php occ cache:clear

# Restart containers
echo 'Restarting Nextcloud containers...'
cd /root/nextcloud && docker-compose restart

echo 'Waiting for services to be ready...'
sleep 15

echo 'Configuration fix completed!'
SCRIPT"

# Execute the fix script
pct exec 101 -- bash /tmp/fix_nextcloud_config.sh

# Clean up
pct exec 101 -- rm /tmp/fix_nextcloud_config.sh

EOF

echo ""
echo "Configuration has been updated!"
echo ""
echo "Please verify:"
echo "1. Your /etc/hosts file has: 192.168.1.49    nextcloud.rtbsoftware.duckdns.org"
echo "2. In Nginx Proxy Manager (192.168.1.49), the proxy host settings:"
echo "   - Domain: nextcloud.rtbsoftware.duckdns.org"
echo "   - Scheme: http (NOT https)"
echo "   - Forward Hostname/IP: 192.168.1.50"
echo "   - Forward Port: 8080"
echo "   - SSL Certificate: Let's Encrypt enabled"
echo ""
echo "The password 'Tiger1234' you provided is your Nextcloud user password."
echo "The database uses 'nextcloud' as both username and password."
echo ""
echo "Try accessing: https://nextcloud.rtbsoftware.duckdns.org"
echo "Login with: rtbsoftware@proton.me / Tiger1234"
