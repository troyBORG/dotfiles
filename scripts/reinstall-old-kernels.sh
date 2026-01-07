#!/bin/bash
# Reinstall old kernels after upgrade so they appear in GRUB
# Keeps the last 3 versions installed

REINSTALL_FILE="/tmp/kernels-to-reinstall.txt"

# Reinstall old kernels that were saved before removal
if [ -f "$REINSTALL_FILE" ]; then
    while IFS= read -r PKG_FILE; do
        if [ -f "$PKG_FILE" ]; then
            echo "Reinstalling old kernel: $(basename "$PKG_FILE")"
            # Reinstall as dependency so it stays installed
            pacman -U --noconfirm --asdeps "$PKG_FILE" 2>/dev/null || true
        fi
    done < "$REINSTALL_FILE"
    rm -f "$REINSTALL_FILE"
fi

# Clean up: Keep only last 3 versions of each kernel type
for BASE_NAME in linux-cachyos-lts linux-cachyos linux-cachyos-bore; do
    INSTALLED_VERSIONS=$(pacman -Q | grep "^${BASE_NAME} " | awk '{print $2}' | sort -V)
    COUNT=$(echo "$INSTALLED_VERSIONS" | wc -l)
    
    if [ "$COUNT" -gt 3 ]; then
        # Get versions to remove (all but last 3)
        TO_REMOVE=$(echo "$INSTALLED_VERSIONS" | head -n -3)
        
        for version in $TO_REMOVE; do
            echo "Removing old kernel: ${BASE_NAME} ${version} (keeping last 3)"
            pacman -R --noconfirm "${BASE_NAME}" 2>/dev/null || true
        done
    fi
done

# Update GRUB so old kernels appear in boot menu
# GRUB will automatically detect all vmlinuz-* files in /boot
if [ -f /usr/bin/grub-mkconfig ]; then
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
fi
