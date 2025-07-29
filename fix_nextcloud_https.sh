#!/bin/bash

echo "Configuring Nextcloud for HTTPS proxy..."

# Add proper proxy configuration
ssh root@192.168.1.10 "pct exec 101 -- docker exec nextcloud-app-1 php -r \"
\\\$configFile = '/var/www/html/config/config.php';
\\\$config = include \\\$configFile;

// Set protocol to HTTPS since we're behind SSL proxy
\\\$config['overwriteprotocol'] = 'https';

// Ensure trusted proxies includes your Nginx Proxy Manager
if (!isset(\\\$config['trusted_proxies']) || !is_array(\\\$config['trusted_proxies'])) {
    \\\$config['trusted_proxies'] = array();
}
if (!in_array('192.168.1.49', \\\$config['trusted_proxies'])) {
    \\\$config['trusted_proxies'][] = '192.168.1.49';
}

// Add trusted domains
if (!in_array('nextcloud.rtbsoftware.duckdns.org', \\\$config['trusted_domains'])) {
    \\\$config['trusted_domains'][] = 'nextcloud.rtbsoftware.duckdns.org';
}

// Write config back
file_put_contents(\\\$configFile, '<?php' . PHP_EOL . '\\\$CONFIG = ' . var_export(\\\$config, true) . ';' . PHP_EOL);
\""

echo "Configuration updated. Your setup is now:"
echo "  - Public access: https://nextcloud.rtbsoftware.duckdns.org (HTTPS via proxy)"
echo "  - Direct access: http://192.168.1.50:8080 (HTTP internal)"
echo ""
echo "This is secure because:"
echo "  - External traffic uses HTTPS"
echo "  - Internal traffic (proxy to Nextcloud) is on your private LAN"
echo "  - SSL certificates are managed by Nginx Proxy Manager"
