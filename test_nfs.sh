#!/bin/bash
#
# Script to test mounting the nfs share directory from a Raspberry Pi.
#
# Usage:
#   chmod +x test_nfs.sh
#   sudo ./test_nfs.sh
#
# OR:
#   curl https://raw.githubusercontent.com/ychaker/pi-gitops/main/test_nfs.sh | bash
#
# Run this script directly on the Pi you wish to configure (preferably after first boot).

set -e

sudo mkdir -p /tmp/nfs-test
sudo mount -t nfs 192.168.1.158:/volume1/k8s-share /tmp/nfs-test
sudo touch /tmp/nfs-test/hello.txt
ls -la /tmp/nfs-test
sudo umount /tmp/nfs-test
