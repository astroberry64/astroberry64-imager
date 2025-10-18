#!/bin/bash
#
# cleanup-image.sh
# Cleans up temporary files, logs, and caches from the image
# This script runs INSIDE the chroot environment
#

set -e

echo "=== Cleaning Up Image ==="

# Clean APT cache
echo "Cleaning APT cache..."
apt-get clean
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/cache/apt/archives/partial/*
rm -rf /var/lib/apt/lists/*

# Clean logs
echo "Cleaning logs..."
find /var/log -type f -name "*.log" -delete
find /var/log -type f -name "*.log.*" -delete
find /var/log -type f -name "*.gz" -delete
truncate -s 0 /var/log/lastlog 2>/dev/null || true
truncate -s 0 /var/log/wtmp 2>/dev/null || true
truncate -s 0 /var/log/btmp 2>/dev/null || true

# Clean temporary files
echo "Cleaning temporary files..."
rm -rf /tmp/*
rm -rf /var/tmp/*

# Clean user caches
echo "Cleaning user caches..."
rm -rf /home/*/.cache/* 2>/dev/null || true
rm -rf /root/.cache/* 2>/dev/null || true

# Clean bash history
rm -f /home/*/.bash_history 2>/dev/null || true
rm -f /root/.bash_history 2>/dev/null || true

# Clean SSH host keys (will be regenerated on first boot)
echo "Removing SSH host keys (will be regenerated on first boot)..."
rm -f /etc/ssh/ssh_host_*

# Clean machine ID (will be regenerated on first boot)
truncate -s 0 /etc/machine-id 2>/dev/null || true

# Clean systemd journal
echo "Cleaning systemd journal..."
journalctl --vacuum-time=1s 2>/dev/null || true
rm -rf /var/log/journal/* 2>/dev/null || true

# Zero out free space for better compression (optional, can be slow)
# Uncomment if you want maximum compression
# echo "Zeroing free space for better compression..."
# dd if=/dev/zero of=/zerofile bs=1M 2>/dev/null || true
# rm -f /zerofile

echo "✓ Cleanup complete"

# Show disk usage
echo ""
echo "Disk usage after cleanup:"
df -h / | tail -1
