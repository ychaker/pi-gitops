#!/bin/bash

# -----------------------------------------------------------------------------
# config_k3s.sh
#
# Fetches k3s kubeconfig from the main Raspberry Pi node, places it in ~/.kube/k3s/config,
# updates the server address to use the Pi's IP, sets KUBECONFIG, and verifies cluster access.
#
# Usage:
#   chmod +x config_k3s.sh
#   ./config_k3s.sh [PI_IP] [PI_USER]
#
#   - PI_IP    : (Optional) The IP address of your k3s server/master node (default: 192.168.1.71)
#   - PI_USER  : (Optional) The username for SSH (default: pi)
#
# Example:
#   ./config_k3s.sh 192.168.1.71 pi
#
# -----------------------------------------------------------------------------

set -e

# Parse arguments with defaults
PI_IP="${1:-192.168.1.71}"
PI_USER="${2:-pi}"

KUBE_DIR="$HOME/.kube/k3s"
KUBECONFIG_PATH="$KUBE_DIR/config"

echo "Creating kubeconfig directory at $KUBE_DIR"
mkdir -p "$KUBE_DIR"

# Function to securely copy the kubeconfig, handling root permissions:
copy_k3s_yaml() {
  # Try direct scp first
  if scp "$PI_USER@$PI_IP:/etc/rancher/k3s/k3s.yaml" "$KUBECONFIG_PATH" 2>/dev/null; then
    return 0
  fi

  # If direct scp fails (likely due to permissions), use sudo cat over ssh
  echo "Direct scp failed (likely permission denied). Attempting sudo cat over SSH..."
  ssh "$PI_USER@$PI_IP" "sudo cat /etc/rancher/k3s/k3s.yaml" > "$KUBECONFIG_PATH"
}

echo "Copying k3s.yaml from $PI_USER@$PI_IP..."
copy_k3s_yaml

# Detect the correct server IP and update the kubeconfig file
echo "Updating server address in kubeconfig to https://$PI_IP:6443"
# Use sed to replace the server line (handles both Mac and GNU sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i "" "s|server: https://.*:6443|server: https://$PI_IP:6443|" "$KUBECONFIG_PATH"
else
  sed -i "s|server: https://.*:6443|server: https://$PI_IP:6443|" "$KUBECONFIG_PATH"
fi

# Set permissions for security
chmod 600 "$KUBECONFIG_PATH"

echo "Exporting KUBECONFIG=$KUBECONFIG_PATH"
export KUBECONFIG="$KUBECONFIG_PATH"

# Test cluster connection, with helpful error message if kubectl is missing or fails
echo "Testing cluster access with 'kubectl get nodes'..."
if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed or not in PATH. Please install kubectl to proceed."
  exit 1
fi

if ! kubectl get nodes; then
  echo "ERROR: Unable to connect to your k3s cluster. Check network/firewall and that the server IP is correct in $KUBECONFIG_PATH."
  exit 2
fi

echo "Done! Your kubeconfig is set up for k3s at $PI_IP."
echo ""
echo "To use this config in new shells, run:"
echo "  export KUBECONFIG=$KUBECONFIG_PATH"

# Usage instructions
echo ""
echo "# Example usage:"
echo "#   ./config_k3s.sh 192.168.1.71 pi"
echo "#   export KUBECONFIG=$KUBECONFIG_PATH"
echo "#   kubectl get nodes"
