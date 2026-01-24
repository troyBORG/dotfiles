#!/bin/bash
#
# Apply zfs-auto-snapshot retention policy overrides
# This updates the retention settings to match a conservative desktop policy
#
# Usage: $0 [MONTHLY] [DAILY] [WEEKLY]
#   MONTHLY: Number of monthly snapshots to keep (default: 3)
#   DAILY: Number of daily snapshots to keep (default: 14)
#   WEEKLY: Number of weekly snapshots to keep (default: 4)
#
# Examples:
#   $0              # Use defaults: monthly=3, daily=14, weekly=4
#   $0 6            # monthly=6, daily=14, weekly=4
#   $0 4 7          # monthly=4, daily=7, weekly=4
#   $0 6 14 8       # monthly=6, daily=14, weekly=8
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONTHLY_KEEP="${1:-3}"
DAILY_KEEP="${2:-14}"
WEEKLY_KEEP="${3:-4}"

# Validate that all values are positive integers
validate_number() {
    local val="$1"
    local name="$2"
    if ! [[ "$val" =~ ^[0-9]+$ ]] || [[ "$val" -lt 1 ]]; then
        echo "Error: $name must be a positive integer (got: $val)" >&2
        exit 1
    fi
}

validate_number "$MONTHLY_KEEP" "Monthly retention"
validate_number "$DAILY_KEEP" "Daily retention"
validate_number "$WEEKLY_KEEP" "Weekly retention"

echo "Applying zfs-auto-snapshot retention policy overrides..."
echo "  hourly: 24 (unchanged)"
echo "  daily: $DAILY_KEEP (changed from 31)"
echo "  weekly: $WEEKLY_KEEP (changed from 8)"
echo "  monthly: $MONTHLY_KEEP (changed from 12)"
echo ""

# Create drop-in directories
sudo mkdir -p /etc/systemd/system/zfs-auto-snapshot-daily.service.d
sudo mkdir -p /etc/systemd/system/zfs-auto-snapshot-weekly.service.d
sudo mkdir -p /etc/systemd/system/zfs-auto-snapshot-monthly.service.d

# Generate override files dynamically
sudo tee /etc/systemd/system/zfs-auto-snapshot-daily.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/bin/zfs-auto-snapshot --skip-scrub --prefix=znap --label=daily --keep=$DAILY_KEEP //
EOF

sudo tee /etc/systemd/system/zfs-auto-snapshot-weekly.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/bin/zfs-auto-snapshot --skip-scrub --prefix=znap --label=weekly --keep=$WEEKLY_KEEP //
EOF

sudo tee /etc/systemd/system/zfs-auto-snapshot-monthly.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/bin/zfs-auto-snapshot --skip-scrub --prefix=znap --label=monthly --keep=$MONTHLY_KEEP //
EOF

# Reload systemd
sudo systemctl daemon-reload

echo ""
echo "✓ Override files installed"
echo ""
echo "New retention policy:"
echo "  hourly: 24 snapshots (1 day)"
echo "  daily: $DAILY_KEEP snapshots ($DAILY_KEEP day$( [[ $DAILY_KEEP -eq 1 ]] || echo s))"
echo "  weekly: $WEEKLY_KEEP snapshots ($WEEKLY_KEEP week$( [[ $WEEKLY_KEEP -eq 1 ]] || echo s))"
echo "  monthly: $MONTHLY_KEEP snapshots ($MONTHLY_KEEP month$( [[ $MONTHLY_KEEP -eq 1 ]] || echo s))"
echo ""
echo "The new settings will take effect on the next scheduled snapshot run."
echo "To verify, check: systemctl cat zfs-auto-snapshot-daily.service"
