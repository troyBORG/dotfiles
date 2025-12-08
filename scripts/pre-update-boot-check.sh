#!/bin/bash
#
# Pre-update boot space check
# Run before pacman updates to prevent /boot/efi from filling up
# This hook will ABORT the update if /boot/efi is too full
#

set -euo pipefail

BOOT_EFI="/boot/efi"
MIN_FREE_GB=2  # Minimum 2GB free required
MIN_FREE_PERCENT=25  # Or at least 25% free

# Check if /boot/efi exists and is mounted
if ! mountpoint -q "$BOOT_EFI" 2>/dev/null; then
    # /boot/efi not mounted, skip check
    exit 0
fi

# Get space info
read -r total_kb used_kb avail_kb percent < <(df "$BOOT_EFI" | tail -1 | awk '{print $2, $3, $4, $5}')
total_gb=$((total_kb / 1024 / 1024))
avail_gb=$((avail_kb / 1024 / 1024))
used_percent=$(echo "$percent" | sed 's/%//')

# Check if we have enough free space
if [[ $avail_gb -lt $MIN_FREE_GB ]] || [[ $used_percent -gt $((100 - MIN_FREE_PERCENT)) ]]; then
    echo "ERROR: /boot/efi has insufficient free space for kernel update!" >&2
    echo "  Current: ${avail_gb}GB free (${percent} used)" >&2
    echo "  Required: At least ${MIN_FREE_GB}GB free OR less than $((100 - MIN_FREE_PERCENT))% used" >&2
    echo "" >&2
    echo "Please free up space in /boot/efi before updating:" >&2
    echo "  1. Remove old kernels: sudo pacman -Rns <old-kernel-package>" >&2
    echo "  2. Check space: df -h /boot/efi" >&2
    echo "  3. Check what's using space: sudo du -sh /boot/efi/*" >&2
    exit 1
fi

# All good
exit 0
