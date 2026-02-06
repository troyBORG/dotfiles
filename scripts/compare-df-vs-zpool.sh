#!/bin/bash
# Compare df (weird for ZFS pool roots) vs zpool (correct for ZFS).
# Run this to see why fastfetch needs both "disk" and "zpool" modules.
echo "=== df (what 'disk' module uses – wrong for ZFS pool roots) ==="
df -h /mnt/4tb / 2>/dev/null
echo ""
echo "=== zpool list (what 'zpool' module uses – correct for ZFS) ==="
zpool list -H -o name,size,alloc,free 2>/dev/null | awk '{printf "%-12s  total=%s  used=%s  free=%s\n", $1, $2, $3, $4}'
echo ""
echo "So: /mnt/4tb via df shows the root dataset's tiny REFER; zpool shows real pool usage."
