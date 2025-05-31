#!/bin/bash
# Adds or updates .local ingress domains in /etc/hosts for all media/network apps.
# It manages a dedicated "Home Cluster" section, replacing any previous version.
# Usage: sudo ./scripts/add_ingress_hosts.sh

# Set the Traefik IP (usually your master node or any node where Traefik LoadBalancer is exposed)
INGRESS_IP="192.168.1.71"

# List of all .local ingress hostnames you want mapped
SERVICES=(
  "homeassistant.local"
  "lidarr.local"
  "pihole.local"
  "prowlarr.local"
  "radarr.local"
  "traefik.local"
  "unifi.local"
)

# Section delimiters for /etc/hosts
SECTION_START="### Home Cluster"
SECTION_END="### End of Home Cluster"

# Generate new section content
NEW_SECTION="\n$SECTION_START\n###################\n"
for DOMAIN in "${SERVICES[@]}"; do
  NEW_SECTION+="\n$INGRESS_IP $DOMAIN"
done
NEW_SECTION+="\n\n$SECTION_END\n###################\n"

# Read /etc/hosts and remove any previous Home Cluster section
# Use awk for robust multi-line section removal
TEMP_HOSTS=$(mktemp)
awk -v start="$SECTION_START" -v end="$SECTION_END" '
  BEGIN {in_section=0}
  $0 ~ start {in_section=1; next}
  $0 ~ end {in_section=0; next}
  !in_section {print}
' /etc/hosts > "$TEMP_HOSTS"

# Append the new section (with blank lines before and after)
echo -e "$NEW_SECTION" >> "$TEMP_HOSTS"

# Replace /etc/hosts with the updated version (backup first)
sudo cp /etc/hosts /etc/hosts.bak
sudo mv "$TEMP_HOSTS" /etc/hosts

echo "Updated /etc/hosts with Home Cluster ingress domains:"
echo -e "$NEW_SECTION"
