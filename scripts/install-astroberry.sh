#!/bin/bash
#
# install-astroberry.sh
# Installs Astroberry64 packages
# This script runs INSIDE the chroot environment
#

set -e

echo "=== Installing Astroberry64 Packages ==="

# Check if running in chroot
if [ ! -f /etc/apt/sources.list.d/astroberry64.list ]; then
    echo "ERROR: Astroberry64 repository not configured"
    exit 1
fi

# Update package lists
echo "Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update

# Install astroberry64-server-full
echo "Installing astroberry64-server-full..."
echo "This will take several minutes..."
apt-get install -y --no-install-recommends astroberry64-server-full || {
    echo "ERROR: Failed to install astroberry64-server-full"
    exit 1
}

# Verify installation
if dpkg -l | grep -q astroberry64-server-full; then
    echo "✓ Astroberry64 installation complete"
    dpkg -l | grep astroberry64
else
    echo "ERROR: Installation verification failed"
    exit 1
fi
