#!/bin/bash

# DuckDNS updater script
# Update this with your actual DuckDNS token
DUCKDNS_TOKEN="YOUR_DUCKDNS_TOKEN_HERE"
DUCKDNS_DOMAIN="rtbsoftware"

# Get current public IP
PUBLIC_IP=$(curl -s https://api.ipify.org)

echo "Updating DuckDNS domain: ${DUCKDNS_DOMAIN}.duckdns.org"
echo "Public IP: ${PUBLIC_IP}"

# Update DuckDNS
RESPONSE=$(curl -s "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${PUBLIC_IP}")

if [ "${RESPONSE}" == "OK" ]; then
    echo "✓ DuckDNS updated successfully!"
else
    echo "✗ DuckDNS update failed: ${RESPONSE}"
fi
