# Astroberry64 Image Builder

Automated scripts to build bootable SD card images for Astroberry64 - the 64-bit astronomy platform for Raspberry Pi 4/5.

## Overview

This repository contains scripts to:
- Download the latest Raspberry Pi OS Desktop (arm64)
- Customize it with Astroberry64 packages
- Remove unnecessary bloat (~648 MB saved)
- Create ready-to-flash SD card images with auto-expansion

## Features

- **Automated building** via GitHub Actions
- **Auto-expansion** on first boot (fills entire SD card)
- **Full astronomy stack** pre-installed (INDI, KStars, PHD2, drivers, etc.)
- **Pre-configured remote access** (noVNC web interface + RustDesk)
- **Optimized size** with unnecessary packages removed
- **Multiple distribution options** (GitHub Releases, Internet Archive)

## Quick Start (Manual Build)

### Prerequisites

```bash
sudo apt-get install -y kpartx qemu-user-static wget xz-utils
```

Optional (for shrinking):
```bash
# Install PiShrink
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin/
```

### Build Steps

```bash
# 1. Download base Raspberry Pi OS image
cd astroberry64-imager
./scripts/download-base-image.sh

# 2. Extract the image
xz -d -k 2025-*-raspios-trixie-arm64.img.xz

# 3. Customize the image (requires root)
sudo ./scripts/customize-image.sh \
  2025-01-11-raspios-trixie-arm64.img \
  astroberry64-lite.img

# 4. Shrink and compress (optional but recommended)
sudo pishrink.sh -z astroberry64-lite.img
```

The final image will be `astroberry64-lite.img.xz` (~1.8 GB compressed).

## Automated Builds (GitHub Actions)

### Triggers

- **Manual**: Workflow dispatch from Actions tab
- **Scheduled**: Daily at 3 AM UTC
- **Webhook**: When astroberry64 packages are updated

### Workflow

1. Downloads latest Raspberry Pi OS
2. Customizes with Astroberry64 packages
3. Removes bloat packages
4. Shrinks and compresses image
5. Generates SHA256 checksums
6. Uploads to:
   - GitHub Releases (if <2GB)
   - Internet Archive (all sizes)

## What's Included

### Pre-installed Software

- **Astronomy**: INDI drivers, KStars, PHD2, Astrometry.net, gpredict, ser-player
- **Remote Access**: noVNC (web-based), x11vnc, RustDesk support
- **Tools**: Image viewers, file managers, web browsers
- **Development**: Build tools, libraries for astronomy software compilation

### Removed Packages (~648 MB saved)

- Printing infrastructure (CUPS)
- RealVNC server (replaced with x11vnc)
- Educational tools (Thonny, Geany for end users)
- Localization files (except English)
- Unused WiFi firmware (Atheros, Realtek, MediaTek)
- Old wallpapers
- Modem Manager
- Game libraries

### Kept (Important!)

- **File sharing**: Samba (Windows), NFS (Linux/Mac) - for downloading astrophotos
- **Network**: Avahi (astroberry.local hostname)
- **Connectivity**: Bluetooth (astronomy devices), built-in WiFi firmware
- **Audio**: PulseAudio/PipeWire (RustDesk audio forwarding, software alerts)
- **Build tools**: For users who want to compile astronomy software

## Image Variants

### Lite (~1.8 GB compressed)
- All Astroberry64 software pre-installed
- No astrometry indexes or star catalogs
- Users download data files separately via `astro-fetch`
- **Recommended for most users**

### Standard (~7-10 GB compressed) - *Future*
- Includes essential astrometry indexes (2MASS, Tycho2)
- Includes ASTAP H18 + G17 indexes
- Includes GSC catalog
- Ready for offline plate solving

## Configuration

### Package Removal

Edit `config/packages-to-remove.txt` to customize which packages are removed.

**Warning**: Do NOT remove:
- `libflite1` or `pocketsphinx-en-us` (breaks gstreamer/ffmpeg)
- Samba/NFS packages (needed for file sharing)
- Audio system (needed for RustDesk)

### APT Repository

Edit `config/apt-sources.list` to change repository channel:
- `trixie-stable` - Production releases (default)
- `trixie-testing` - Latest automated builds

## First Boot

After flashing the image to an SD card:

1. **First boot**: System expands partition, resizes filesystem, reboots (~2 min)
2. **Second boot**: System is ready to use

Default credentials:
- Username: `astroberry`
- Password: `astrober`

Access methods:
- **Web browser**: `http://astroberry.local/desktop/` (noVNC)
- **RustDesk**: Install client, connect to `astroberry.local`
- **SSH**: `ssh astroberry@astroberry.local`

## File Structure

```
astroberry64-imager/
├── scripts/
│   ├── download-base-image.sh    # Downloads Raspberry Pi OS
│   ├── customize-image.sh         # Main customization orchestrator
│   ├── remove-packages.sh         # Removes bloat (runs in chroot)
│   ├── install-astroberry.sh      # Installs Astroberry64 (runs in chroot)
│   └── cleanup-image.sh           # Cleans logs/caches (runs in chroot)
├── config/
│   ├── packages-to-remove.txt     # List of packages to remove
│   └── apt-sources.list           # Astroberry64 APT repository
├── .github/workflows/
│   └── build-image.yml            # GitHub Actions workflow
└── README.md
```

## Troubleshooting

### "kpartx: command not found"
```bash
sudo apt-get install kpartx
```

### "qemu-aarch64-static: No such file or directory"
```bash
sudo apt-get install qemu-user-static
```

### Customization fails
Check:
- Running as root (`sudo`)
- Enough disk space (need ~10 GB free)
- Base image is not corrupted (verify SHA256)

### Image won't boot
- Ensure image was properly unmounted before flashing
- Try re-flashing with Raspberry Pi Imager
- Check SD card is not faulty

## Contributing

1. Test changes locally before submitting PR
2. Update `packages-to-remove.txt` carefully (test dependencies!)
3. Document any new configuration options

## License

GPL-3.0 (same as Astroberry Server)

## Credits

- Based on [Astroberry Server](https://github.com/rkaczorek/astroberry-server) by Radek Kaczorek
- Uses [PiShrink](https://github.com/Drewsif/PiShrink) for image compression
- Built on Raspberry Pi OS

## Links

- **Website**: https://astroberry64.github.io
- **APT Repository**: https://astroberry64.github.io/astroberry64-repo/
- **Bug Reports**: https://github.com/astroberry64/astroberry64-imager/issues
