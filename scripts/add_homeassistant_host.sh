#!/bin/bash
# Adds or updates homeassistant.local in /etc/hosts, pointing to the master node Traefik IP

# Set the Traefik IP (your master node)
INGRESS_IP="192.168.1.71"
DOMAIN="homeassistant.local"

# Remove any previous entry for the domain
sudo sed -i.bak "/[[:space:]]$DOMAIN$/d" /etc/hosts

# Add the new entry
echo "$INGRESS_IP $DOMAIN" | sudo tee -a /etc/hosts

echo "Added $DOMAIN -> $INGRESS_IP to /etc/hosts"
