#!/bin/bash
#
# Raspberry Pi initial setup script
# Automates setting hostname, static IP, enabling SSH, updating OS.
#
# Usage:
#   chmod +x setup_pi.sh
#   sudo ./setup_pi.sh
#
# Run this script directly on the Pi you wish to configure (preferably after first boot).

set -e

# --- Locale Fix: Regenerate and set locales if missing ---
if ! locale | grep -q 'en_US.utf8'; then
  echo "Locale en_US.UTF-8 not found. Generating locale..."
  sudo sed -i '/^# *en_US.UTF-8 UTF-8/s/^# *//' /etc/locale.gen   # Uncomment the en_US.UTF-8 locale line
  sudo locale-gen
  sudo update-locale LANG=en_US.UTF-8
  echo "Locale generated and set to en_US.UTF-8."
fi

# Prompt for Pi number to set unique hostname
read -rp "Enter Pi number (e.g., 1 for pi1): " PI_NUM
NEW_HOSTNAME="pi${PI_NUM}"

# Set hostname
echo "Setting hostname to ${NEW_HOSTNAME}..."
echo "${NEW_HOSTNAME}" | sudo tee /etc/hostname
sudo sed -i "s/127.0.1.1.*/127.0.1.1\t${NEW_HOSTNAME}/" /etc/hosts

# Optionally set static IP
read -rp "Do you want to set a static IP? [y/N]: " SET_STATIC
if [[ "$SET_STATIC" =~ ^[Yy]$ ]]; then
  # Suggest a default IP based on the PI_NUM entered earlier
  DEFAULT_STATIC_IP="192.168.1.7${PI_NUM}/24"
  DEFAULT_GATEWAY="192.168.1.1"
  DEFAULT_DNS="192.168.1.1"

  read -rp "Enter static IP [${DEFAULT_STATIC_IP}]: " STATIC_IP
  STATIC_IP=${STATIC_IP:-$DEFAULT_STATIC_IP}

  read -rp "Enter gateway/router IP [${DEFAULT_GATEWAY}]: " GATEWAY
  GATEWAY=${GATEWAY:-$DEFAULT_GATEWAY}

  read -rp "Enter DNS servers [${DEFAULT_DNS}]: " DNS
  DNS=${DNS:-$DEFAULT_DNS}

  echo "Configuring static IP..."
  sudo bash -c "cat >> /etc/dhcpcd.conf" <<EOF

interface eth0
  static ip_address=${STATIC_IP}
  static routers=${GATEWAY}
  static domain_name_servers=${DNS}
EOF
fi

# Enable SSH
echo "Enabling SSH..."
sudo systemctl enable ssh
sudo systemctl start ssh

# Update and upgrade system
echo "Updating system (this may take a while)..."
sudo apt update && sudo apt upgrade -y

# --- NFS Client Test Section ---
echo "Checking for NFS client utilities..."
if ! dpkg -l | grep -qw nfs-common; then
  echo "Installing nfs-common for NFS support..."
  sudo apt install -y nfs-common
fi

read -rp "Do you want to test a connection to your NAS NFS share now? [y/N]: " TEST_NFS
if [[ "$TEST_NFS" =~ ^[Yy]$ ]]; then
  # Provide default NAS IP and path, prompt user with default in brackets
  read -rp "Enter NAS IP address [192.168.1.158]: " NAS_IP
  NAS_IP=${NAS_IP:-192.168.1.158}

  read -rp "Enter NFS export path [/volume1/k8s-share]: " NAS_PATH
  NAS_PATH=${NAS_PATH:-/volume1/k8s-share}

  sudo mkdir -p /mnt/nas-test
  echo "Attempting to mount NFS share at ${NAS_IP}:${NAS_PATH} ..."
  if sudo mount -t nfs "${NAS_IP}:${NAS_PATH}" /mnt/nas-test; then
    echo "NFS mount successful! Listing contents of /mnt/nas-test:"
    ls -al /mnt/nas-test
    sudo umount /mnt/nas-test
    echo "Unmounted test mount."
  else
    echo "NFS mount failed. Check your NAS settings and NFS permissions."
  fi
  sudo rmdir /mnt/nas-test
fi

echo "Setup complete! Please reboot to apply hostname and network changes."
read -rp "Reboot now? [Y/n]: " REBOOT_NOW
if [[ ! "$REBOOT_NOW" =~ ^[Nn]$ ]]; then
  sudo reboot
else
  echo "Remember to manually reboot later."
fi
