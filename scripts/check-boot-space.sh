#!/bin/bash
#
# Check /boot and /boot/efi space usage
# Helps prevent running out of space during kernel updates
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Boot Partition Space Usage ===${NC}\n"

# Check /boot/efi (usually the EFI partition)
if mountpoint -q /boot/efi 2>/dev/null; then
    echo -e "${GREEN}/boot/efi (EFI Partition):${NC}"
    df -h /boot/efi | tail -1 | awk '{printf "  Size: %s, Used: %s, Available: %s, Use: %s\n", $2, $3, $4, $5}'
    
    # Check if usage is high
    usage=$(df /boot/efi | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt 80 ]]; then
        echo -e "  ${RED}⚠ WARNING: /boot/efi is ${usage}% full!${NC}"
    elif [[ $usage -gt 60 ]]; then
        echo -e "  ${YELLOW}⚠ /boot/efi is ${usage}% full - consider cleanup${NC}"
    else
        echo -e "  ${GREEN}✓ Space looks good${NC}"
    fi
    echo ""
fi

# Check /boot (if it's a separate partition)
if mountpoint -q /boot 2>/dev/null && [[ "$(df /boot | tail -1 | awk '{print $1}')" != "$(df / | tail -1 | awk '{print $1}')" ]]; then
    echo -e "${GREEN}/boot (Boot Partition):${NC}"
    df -h /boot | tail -1 | awk '{printf "  Size: %s, Used: %s, Available: %s, Use: %s\n", $2, $3, $4, $5}'
    
    usage=$(df /boot | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt 80 ]]; then
        echo -e "  ${RED}⚠ WARNING: /boot is ${usage}% full!${NC}"
    elif [[ $usage -gt 60 ]]; then
        echo -e "  ${YELLOW}⚠ /boot is ${usage}% full - consider cleanup${NC}"
    else
        echo -e "  ${GREEN}✓ Space looks good${NC}"
    fi
    echo ""
fi

# Show largest files in /boot
echo -e "${BLUE}Largest files in /boot:${NC}"
du -h /boot/* 2>/dev/null | sort -h | tail -5 | while read size file; do
    echo -e "  ${size}\t${file}"
done
echo ""

# Count kernel packages
echo -e "${BLUE}Installed kernel packages:${NC}"
pacman -Q | grep -E '^linux[^-]|^linux-' | grep -v 'headers' | while read pkg ver; do
    echo -e "  ${pkg} ${ver}"
done
echo ""

# Show kernel files in /boot
echo -e "${BLUE}Kernel files in /boot:${NC}"
ls -lh /boot/vmlinuz-* 2>/dev/null | awk '{printf "  %s %s %s\n", $5, $6, $7, $9}'
echo ""

# Show initramfs files
echo -e "${BLUE}Initramfs images in /boot:${NC}"
ls -lh /boot/initramfs-*.img 2>/dev/null | awk '{printf "  %s %s %s\n", $5, $6, $7, $9}'
echo ""

# Recommendations
echo -e "${BLUE}Recommendations:${NC}"
echo -e "  • Keep at least 2-3GB free in /boot/efi for kernel updates"
echo -e "  • Old kernels are automatically removed by pacman, but you can manually remove with:"
echo -e "    ${YELLOW}sudo pacman -Rns <old-kernel-package>${NC}"
echo -e "  • Check space before major updates: ${YELLOW}df -h /boot/efi${NC}"
