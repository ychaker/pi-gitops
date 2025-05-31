#!/bin/bash
#
# Helper script to print your current default gateway (router) and DNS server(s)
# Works on Linux and macOS
#
# Usage:
#   chmod +x get_network_info.sh
#   ./get_network_info.sh
#

echo "=== Default Gateway (Router) ==="
if command -v ip &>/dev/null; then
  # Linux
  GATEWAY=$(ip route | awk '/default/ {print $3; exit}')
  echo "Gateway: $GATEWAY"
elif command -v route &>/dev/null; then
  # macOS
  GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway: / {print $2; exit}')
  echo "Gateway: $GATEWAY"
else
  echo "Could not determine gateway. Please check your OS."
fi

echo ""
echo "=== DNS Servers ==="
if [[ -f /etc/resolv.conf ]]; then
  # Both Linux and macOS typically use resolv.conf for DNS
  grep '^nameserver' /etc/resolv.conf | awk '{print $2}' | while read -r dns; do
    echo "DNS: $dns"
  done
else
  echo "Could not determine DNS servers. Please check your OS."
fi

echo ""
echo "Copy and paste these values when prompted by setup_pi.sh!"
