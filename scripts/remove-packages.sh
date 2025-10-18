#!/bin/bash
#
# remove-packages.sh
# Removes unnecessary packages from the image
# This script runs INSIDE the chroot environment
#

set -e

echo "=== Removing Unnecessary Packages ==="

# Check if running in chroot
if [ ! -f /tmp/astroberry-setup/packages-to-remove.txt ]; then
    echo "ERROR: This script must be run from customize-image.sh"
    exit 1
fi

# Read packages list (filter out comments and empty lines)
PACKAGES=$(grep -v '^#' /tmp/astroberry-setup/packages-to-remove.txt | grep -v '^$' | tr '\n' ' ')

if [ -z "$PACKAGES" ]; then
    echo "WARNING: No packages to remove"
    exit 0
fi

echo "Packages to remove:"
echo "$PACKAGES" | tr ' ' '\n' | sed 's/^/  - /'
echo ""

# Remove packages (suppress apt interactive prompts)
export DEBIAN_FRONTEND=noninteractive
apt-get remove --purge -y $PACKAGES || {
    echo "WARNING: Some packages could not be removed (may not be installed)"
}

# Remove orphaned dependencies
echo "Removing orphaned dependencies..."
apt-get autoremove --purge -y

# Clean package cache
echo "Cleaning package cache..."
apt-get clean

echo "✓ Package removal complete"
