# Boot Failure Analysis & Prevention

## What Happened (Past Failure)

### The Failure Chain

1. **Root Cause**: `/boot/efi` partition (2GB) filled up during a kernel update
2. **Immediate Effect**: Kernel modules couldn't be built/installed properly
3. **Module Corruption**: Incomplete/corrupted modules caused "Exec format error"
4. **Cascade Failure**: 
   - `modprobe fat` failed → couldn't load FAT filesystem module
   - `modprobe ufat` failed → couldn't read `/boot/efi` (FAT32)
   - `boot.mount` failed → system couldn't mount `/boot`
   - System entered emergency mode

### Evidence from Screenshots

- `systemctl --failed` showed: `boot.mount loaded failed failed /boot`
- `modprobe fat` error: `Exec format error`
- Multiple kernel versions present: `6.12.59` running, but `6.12.60` and `6.18.0` modules installed
- `/boot/efi` was 2GB (now increased to 8GB)

## Current Protections

### 1. Larger Boot Partition
- **Before**: 2GB `/boot/efi` partition
- **Now**: 8GB `/boot/efi` partition (4x larger)
- **Status**: Currently 680K used / 8.0G (1% usage) ✅

### 2. ZFS Snapshots Before Updates
- **Hook**: `/etc/pacman.d/hooks/zfs-snapshot.hook`
- **Action**: Creates snapshot before EVERY pacman transaction
- **Recovery**: Can rollback to pre-update state if something breaks
- **Script**: `~/dotfiles/scripts/zfs-rollback.sh` for management

### 3. Boot Space Monitoring
- **Script**: `~/dotfiles/scripts/check-boot-space.sh`
- **Shows**: Space usage, largest files, installed kernels
- **Warnings**: Alerts at 60% (warning) and 80% (critical)

### 4. Pre-Update Boot Space Check (NEW)
- **Script**: `~/dotfiles/scripts/pre-update-boot-check.sh`
- **Hook**: `99-check-boot-space.hook` (install to `/etc/pacman.d/hooks/`)
- **Action**: ABORTS kernel updates if `/boot/efi` has < 2GB free OR > 75% used
- **Prevents**: Updates from starting if space is insufficient

### 5. Automatic Snapshot Cleanup
- **Service**: `zfs-snapshot-cleanup.service` + `.timer`
- **Action**: Weekly cleanup of snapshots older than 30 days
- **Prevents**: Snapshots from accumulating indefinitely

## Installation

### Install Pre-Update Boot Check Hook

```bash
sudo cp ~/dotfiles/scripts/99-check-boot-space.hook /etc/pacman.d/hooks/
```

This will automatically check `/boot/efi` space before any kernel update and abort if insufficient.

### Verify Protections

```bash
# Check current boot space
~/dotfiles/scripts/check-boot-space.sh

# Test pre-update check
~/dotfiles/scripts/pre-update-boot-check.sh

# List ZFS snapshots
~/dotfiles/scripts/zfs-rollback.sh list
```

## How ZFS Boot Works

1. **UEFI firmware** loads GRUB from `/boot/efi/EFI/...` (EFI partition)
2. **GRUB has ZFS support** built-in (zfs.mod, zfscrypt.mod modules)
3. **GRUB reads** `/boot/vmlinuz-*` and `/boot/initramfs-*.img` from ZFS `/boot/`
4. **Kernel boots** with initramfs (which has ZFS support via mkinitcpio hooks)
5. **Initramfs mounts** ZFS root filesystem
6. **System continues** booting from ZFS

**Key Point**: `/boot/` is on ZFS (included in snapshots), but `/boot/efi` is a separate FAT32 partition (not on ZFS, needs space monitoring).

## Best Practices

1. **Check space before major updates**: `df -h /boot/efi`
2. **Keep at least 2-3GB free** in `/boot/efi` for kernel updates
3. **Remove old kernels** if space gets tight: `sudo pacman -Rns <old-kernel>`
4. **Monitor regularly**: Run `check-boot-space.sh` periodically
5. **Use snapshots**: Always have a rollback point before updates

## Recovery Plan

If boot fails again:

1. **Boot from live USB**
2. **Import ZFS pool**: `zpool import -f zpcachyos`
3. **List snapshots**: `zfs list -t snapshot | grep pacman-pre`
4. **Rollback**: `zfs rollback -r zpcachyos/ROOT/cos/root@<snapshot-name>`
5. **Reboot**

Or use the rollback script from live environment if accessible.
