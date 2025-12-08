#!/bin/bash
# Output boot/efi space in fastfetch-friendly format

if mountpoint -q /boot/efi 2>/dev/null; then
    # df without -h shows sizes in 1K blocks
    df /boot/efi | tail -1 | awk '{
        used_1k = $3
        total_1k = $2
        total_gb = total_1k / 1024 / 1024
        percent = (used_1k / total_1k) * 100
        # Round up to 1% if > 0 but < 1%
        if (percent > 0 && percent < 1) percent = 1
        # Format based on size
        if (used_1k < 1024) {
            printf "%dK / %.1fG (%.0f%%)", used_1k, total_gb, percent
        } else if (used_1k < 1048576) {
            used_mb = used_1k / 1024
            printf "%.0fM / %.1fG (%.0f%%)", used_mb, total_gb, percent
        } else {
            used_gb = used_1k / 1024 / 1024
            printf "%.2fG / %.1fG (%.0f%%)", used_gb, total_gb, percent
        }
    }'
else
    echo "N/A"
fi
