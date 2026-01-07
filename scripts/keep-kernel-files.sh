#!/bin/bash
# Keep old kernel files in /boot so they appear in GRUB (Ubuntu-style)
# This preserves vmlinuz and initramfs even after package removal

KERNEL_PKG="$1"

if [ -n "$KERNEL_PKG" ]; then
    # Get installed version before removal
    INSTALLED_VERSION=$(pacman -Q "$KERNEL_PKG" 2>/dev/null | awk '{print $2}')
    BASE_NAME=$(echo "$KERNEL_PKG" | sed 's/-[0-9].*//')
    
    if [ -n "$INSTALLED_VERSION" ]; then
        # Rename kernel files with version suffix so they persist after package removal
        # This mimics Ubuntu's approach where each version has unique filenames
        
        # Rename vmlinuz (GRUB will detect any /boot/vmlinuz-* file)
        if [ -f "/boot/vmlinuz-${BASE_NAME}" ]; then
            mv "/boot/vmlinuz-${BASE_NAME}" "/boot/vmlinuz-${BASE_NAME}-${INSTALLED_VERSION}" 2>/dev/null && \
            echo "Renamed: vmlinuz-${BASE_NAME} -> vmlinuz-${BASE_NAME}-${INSTALLED_VERSION}"
        fi
        
        # Rename initramfs (GRUB looks for initrd.img-${version} or initrd-${version}.img)
        if [ -f "/boot/initramfs-${BASE_NAME}.img" ]; then
            # Use initrd.img- format that GRUB expects
            mv "/boot/initramfs-${BASE_NAME}.img" "/boot/initrd.img-${BASE_NAME}-${INSTALLED_VERSION}" 2>/dev/null && \
            echo "Renamed: initramfs-${BASE_NAME}.img -> initrd.img-${BASE_NAME}-${INSTALLED_VERSION}"
        fi
        
        # Keep only last 3 versions of kernel files
        ls -t /boot/vmlinuz-${BASE_NAME}-* 2>/dev/null | tail -n +4 | xargs -r rm -f
        ls -t /boot/initrd.img-${BASE_NAME}-* 2>/dev/null | tail -n +4 | xargs -r rm -f
        # Also clean up any old initramfs- format files
        ls -t /boot/initramfs-${BASE_NAME}-*.img 2>/dev/null | tail -n +4 | xargs -r rm -f
        
        echo "Preserved kernel files for ${BASE_NAME} ${INSTALLED_VERSION} in /boot"
    fi
fi
