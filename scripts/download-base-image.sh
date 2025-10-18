#!/bin/bash
#
# download-base-image.sh
# Downloads the latest Raspberry Pi OS Desktop (arm64) image
#
# Usage: ./download-base-image.sh [output-dir]
#

set -e

OUTPUT_DIR="${1:-.}"
BASE_URL="https://downloads.raspberrypi.org/raspios_arm64/images/"

echo "=== Astroberry64 Image Builder - Base Image Download ==="
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "[1/4] Fetching latest Raspberry Pi OS Desktop (arm64) version..."
# Get the latest image directory
LATEST_DIR=$(curl -s "$BASE_URL" | grep -oP 'raspios_arm64-[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -V | tail -1)

if [ -z "$LATEST_DIR" ]; then
    echo "ERROR: Could not find latest Raspberry Pi OS version"
    exit 1
fi

echo "Found: $LATEST_DIR"
IMAGE_URL="${BASE_URL}${LATEST_DIR}/"

# Get the .xz filename
echo "[2/4] Fetching image filename..."
IMAGE_FILE=$(curl -s "$IMAGE_URL" | grep -oP '[0-9]{4}-[0-9]{2}-[0-9]{2}-raspios-trixie-arm64\.img\.xz' | head -1)

if [ -z "$IMAGE_FILE" ]; then
    echo "ERROR: Could not find image file"
    exit 1
fi

FULL_URL="${IMAGE_URL}${IMAGE_FILE}"
echo "Image: $IMAGE_FILE"

# Check if already downloaded
if [ -f "$IMAGE_FILE" ]; then
    echo ""
    echo "Image already downloaded: $IMAGE_FILE"
    echo "Delete it to re-download or use existing file."
    echo ""
    echo "Image location: $(pwd)/$IMAGE_FILE"
    exit 0
fi

# Download the image
echo "[3/4] Downloading image (~1.3 GB)..."
echo "URL: $FULL_URL"
echo ""

wget -c "$FULL_URL" -O "$IMAGE_FILE" || {
    echo "ERROR: Download failed"
    exit 1
}

# Download SHA256 checksum
echo ""
echo "[4/4] Downloading SHA256 checksum..."
CHECKSUM_FILE="${IMAGE_FILE}.sha256"
wget -q "${FULL_URL}.sha256" -O "$CHECKSUM_FILE" || {
    echo "WARNING: Could not download checksum file"
}

# Verify checksum if available
if [ -f "$CHECKSUM_FILE" ]; then
    echo "Verifying checksum..."
    if sha256sum -c "$CHECKSUM_FILE"; then
        echo "✓ Checksum verified successfully"
    else
        echo "✗ Checksum verification FAILED!"
        exit 1
    fi
fi

echo ""
echo "=== Download Complete ==="
echo "Image file: $(pwd)/$IMAGE_FILE"
echo "Size: $(du -h "$IMAGE_FILE" | cut -f1)"
echo ""
echo "Next step: Extract the image"
echo "  xz -d -k $IMAGE_FILE"
echo ""
