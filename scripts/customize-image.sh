#!/bin/bash
#
# customize-image.sh
# Main script to customize Raspberry Pi OS image with Astroberry64 packages
#
# Usage: sudo ./customize-image.sh <input-image.img> <output-image.img>
#
# Requirements:
#   - Run as root (for mount/chroot operations)
#   - kpartx, qemu-user-static installed
#

set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

if [ $# -lt 2 ]; then
    echo "Usage: sudo $0 <input-image.img> <output-image.img>"
    echo ""
    echo "Example:"
    echo "  sudo $0 2025-01-11-raspios-trixie-arm64.img astroberry64-lite.img"
    exit 1
fi

INPUT_IMAGE="$1"
OUTPUT_IMAGE="$2"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

# Check dependencies
for cmd in kpartx qemu-aarch64-static; do
    if ! command -v $cmd &> /dev/null; then
        echo "ERROR: Required command '$cmd' not found"
        echo "Install with: apt-get install kpartx qemu-user-static"
        exit 1
    fi
done

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "ERROR: Input image not found: $INPUT_IMAGE"
    exit 1
fi

echo "=== Astroberry64 Image Customization ==="
echo "Input:  $INPUT_IMAGE"
echo "Output: $OUTPUT_IMAGE"
echo ""

# Copy input to output
echo "[1/10] Copying base image..."
cp "$INPUT_IMAGE" "$OUTPUT_IMAGE"
chmod 644 "$OUTPUT_IMAGE"

# Set up loop device
echo "[2/10] Setting up loop device..."
LOOP_DEV=$(losetup -fP --show "$OUTPUT_IMAGE")
echo "Loop device: $LOOP_DEV"

# Wait for partitions to appear
sleep 2

# Create mount points
MOUNT_ROOT="/mnt/astroberry-root"
mkdir -p "$MOUNT_ROOT"

# Cleanup function
cleanup() {
    echo ""
    echo "Cleaning up..."

    # Unmount everything
    if mountpoint -q "$MOUNT_ROOT/boot/firmware"; then
        umount "$MOUNT_ROOT/boot/firmware" 2>/dev/null || true
    fi

    for dir in proc sys dev/pts dev; do
        if mountpoint -q "$MOUNT_ROOT/$dir"; then
            umount -l "$MOUNT_ROOT/$dir" 2>/dev/null || true
        fi
    done

    if mountpoint -q "$MOUNT_ROOT"; then
        umount "$MOUNT_ROOT" 2>/dev/null || true
    fi

    # Remove loop device
    if [ -n "$LOOP_DEV" ]; then
        losetup -d "$LOOP_DEV" 2>/dev/null || true
    fi

    # Remove mount point
    rmdir "$MOUNT_ROOT" 2>/dev/null || true

    echo "Cleanup complete"
}

# Set trap for cleanup on exit/error
trap cleanup EXIT

# Mount partitions
echo "[3/10] Mounting partitions..."
mount "${LOOP_DEV}p2" "$MOUNT_ROOT"
mount "${LOOP_DEV}p1" "$MOUNT_ROOT/boot/firmware"

# Set up chroot environment
echo "[4/10] Setting up chroot environment..."
mount -t proc /proc "$MOUNT_ROOT/proc"
mount -t sysfs /sys "$MOUNT_ROOT/sys"
mount --rbind /dev "$MOUNT_ROOT/dev"
mount --rbind /dev/pts "$MOUNT_ROOT/dev/pts"

# Copy qemu-aarch64-static for chroot
cp /usr/bin/qemu-aarch64-static "$MOUNT_ROOT/usr/bin/"

# Copy scripts and config into image
echo "[5/10] Copying customization scripts..."
mkdir -p "$MOUNT_ROOT/tmp/astroberry-setup"
cp "$SCRIPT_DIR"/remove-packages.sh "$MOUNT_ROOT/tmp/astroberry-setup/"
cp "$SCRIPT_DIR"/install-astroberry.sh "$MOUNT_ROOT/tmp/astroberry-setup/"
cp "$SCRIPT_DIR"/cleanup-image.sh "$MOUNT_ROOT/tmp/astroberry-setup/"
cp "$CONFIG_DIR"/packages-to-remove.txt "$MOUNT_ROOT/tmp/astroberry-setup/"
cp "$CONFIG_DIR"/apt-sources.list "$MOUNT_ROOT/tmp/astroberry-setup/"
chmod +x "$MOUNT_ROOT/tmp/astroberry-setup"/*.sh

# Add astroberry64 repository
echo "[6/10] Adding Astroberry64 APT repository..."
cp "$CONFIG_DIR/apt-sources.list" "$MOUNT_ROOT/etc/apt/sources.list.d/astroberry64.list"

# Run customization in chroot
echo "[7/10] Removing unnecessary packages (this may take a while)..."
chroot "$MOUNT_ROOT" /bin/bash -c "cd /tmp/astroberry-setup && ./remove-packages.sh"

echo "[8/10] Installing Astroberry64 packages (this will take several minutes)..."
chroot "$MOUNT_ROOT" /bin/bash -c "cd /tmp/astroberry-setup && ./install-astroberry.sh"

echo "[9/10] Cleaning up image..."
chroot "$MOUNT_ROOT" /bin/bash -c "cd /tmp/astroberry-setup && ./cleanup-image.sh"

# Remove setup scripts
rm -rf "$MOUNT_ROOT/tmp/astroberry-setup"
rm -f "$MOUNT_ROOT/usr/bin/qemu-aarch64-static"

echo "[10/10] Shrinking filesystem to minimum size..."
# Unmount all filesystems before resize
umount "$MOUNT_ROOT/boot/firmware" 2>/dev/null || true
for dir in proc sys dev/pts dev; do
    umount -l "$MOUNT_ROOT/$dir" 2>/dev/null || true
done
umount "$MOUNT_ROOT" 2>/dev/null || true

# Check filesystem before shrinking
echo "Checking filesystem..."
e2fsck -fy "${LOOP_DEV}p2" || true

# Shrink filesystem to minimum size
echo "Shrinking filesystem to minimum..."
resize2fs -M "${LOOP_DEV}p2"

echo "Filesystem shrunk successfully"
echo ""
echo "Synchronizing..."
sync

# Cleanup will be called automatically by trap
echo ""
echo "=== Customization Complete ==="
echo "Output image: $OUTPUT_IMAGE"
echo "Size: $(du -h "$OUTPUT_IMAGE" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Shrink image: sudo pishrink.sh -z $OUTPUT_IMAGE"
echo "  2. Test on Raspberry Pi 4/5"
echo ""
