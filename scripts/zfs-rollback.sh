#!/bin/bash
#
# ZFS Pacman Snapshot Rollback Helper
# Helps you list, inspect, and rollback to pacman snapshots
#

set -euo pipefail

DATASET="zpcachyos/ROOT/cos/root"
SNAPSHOT_PREFIX="pacman-pre-"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    list                    List all pacman snapshots (default)
    latest                  Show the latest snapshot
    rollback [SNAPSHOT]     Rollback to a specific snapshot (or latest if not specified)
    info [SNAPSHOT]         Show detailed info about a snapshot
    cleanup [DAYS]          Delete snapshots older than N days (default: 30)
    help                    Show this help message

Examples:
    $0 list
    $0 latest
    $0 rollback
    $0 rollback zpcachyos/ROOT/cos/root@pacman-pre-20251208-031512-123456789
    $0 info
    $0 cleanup 7

WARNING: Rollback will destroy all changes made after the snapshot was taken!
EOF
}

list_snapshots() {
    echo -e "${BLUE}Available pacman snapshots:${NC}\n"
    zfs list -t snapshot -o name,creation,used,referenced -H "${DATASET}" | \
        grep "@${SNAPSHOT_PREFIX}" | \
        awk -F'\t' '{printf "%-60s %-20s %10s %10s\n", $1, $2, $3, $4}' | \
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                echo "$line"
            fi
        done
    
    local count=$(zfs list -t snapshot -H -o name "${DATASET}" | grep -c "@${SNAPSHOT_PREFIX}" || echo "0")
    echo -e "\n${GREEN}Total: $count snapshot(s)${NC}"
}

get_latest_snapshot() {
    zfs list -t snapshot -H -o name -S creation "${DATASET}" | \
        grep "@${SNAPSHOT_PREFIX}" | \
        head -n 1
}

show_latest() {
    local latest=$(get_latest_snapshot)
    if [[ -z "$latest" ]]; then
        echo -e "${RED}No pacman snapshots found!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Latest snapshot:${NC} $latest"
    echo ""
    zfs list -t snapshot -o name,creation,used,referenced,written "${latest}"
}

show_info() {
    local snapshot="${1:-}"
    
    if [[ -z "$snapshot" ]]; then
        snapshot=$(get_latest_snapshot)
        if [[ -z "$snapshot" ]]; then
            echo -e "${RED}No snapshots found!${NC}"
            exit 1
        fi
    fi
    
    # Validate snapshot name
    if ! zfs list -t snapshot -H -o name | grep -q "^${snapshot}$"; then
        echo -e "${RED}Error: Snapshot '$snapshot' does not exist!${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Snapshot Information:${NC}"
    echo -e "${GREEN}Name:${NC} $snapshot"
    echo ""
    zfs list -t snapshot -o name,creation,used,referenced,written,compressratio "${snapshot}"
    echo ""
    zfs get all "${snapshot}" | grep -E "(creation|used|referenced|written|compressratio)"
}

rollback_snapshot() {
    local snapshot="${1:-}"
    
    if [[ -z "$snapshot" ]]; then
        snapshot=$(get_latest_snapshot)
        if [[ -z "$snapshot" ]]; then
            echo -e "${RED}No snapshots found to rollback to!${NC}"
            exit 1
        fi
    fi
    
    # Validate snapshot name
    if ! zfs list -t snapshot -H -o name | grep -q "^${snapshot}$"; then
        echo -e "${RED}Error: Snapshot '$snapshot' does not exist!${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}WARNING: This will rollback to snapshot:${NC}"
    echo -e "${RED}$snapshot${NC}"
    echo ""
    echo -e "${YELLOW}All changes made after this snapshot will be PERMANENTLY LOST!${NC}"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${GREEN}Rollback cancelled.${NC}"
        exit 0
    fi
    
    echo -e "${BLUE}Rolling back...${NC}"
    
    # Check if we're in a bootable state
    if [[ -d "/boot/efi" ]]; then
        echo -e "${YELLOW}Note: This will rollback the ZFS dataset.${NC}"
        echo -e "${YELLOW}If you're rolling back due to a broken kernel, you may need to:${NC}"
        echo -e "${YELLOW}  1. Boot from a live USB${NC}"
        echo -e "${YELLOW}  2. Import the pool: zpool import -f zpcachyos${NC}"
        echo -e "${YELLOW}  3. Rollback: zfs rollback -r $snapshot${NC}"
        echo ""
        read -p "Continue with rollback? (type 'yes'): " confirm2
        if [[ "$confirm2" != "yes" ]]; then
            echo -e "${GREEN}Rollback cancelled.${NC}"
            exit 0
        fi
    fi
    
    # Perform the rollback
    if zfs rollback -r "${snapshot}"; then
        echo -e "${GREEN}✓ Rollback successful!${NC}"
        echo -e "${YELLOW}You may need to reboot for changes to take effect.${NC}"
    else
        echo -e "${RED}✗ Rollback failed!${NC}"
        exit 1
    fi
}

cleanup_snapshots() {
    local days="${1:-30}"
    local cutoff_date=$(date -d "${days} days ago" +%s 2>/dev/null || date -v-${days}d +%s 2>/dev/null || echo "")
    
    if [[ -z "$cutoff_date" ]]; then
        echo -e "${RED}Error: Could not calculate cutoff date.${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Finding snapshots older than $days days...${NC}\n"
    
    local to_delete=()
    while IFS= read -r snapshot; do
        if [[ -n "$snapshot" ]]; then
            local snap_date=$(zfs get -H -o value creation "$snapshot")
            local snap_timestamp=$(date -d "$snap_date" +%s 2>/dev/null || date -j -f "%a %b %d %H:%M %Y" "$snap_date" +%s 2>/dev/null || echo "")
            
            if [[ -n "$snap_timestamp" ]] && [[ "$snap_timestamp" -lt "$cutoff_date" ]]; then
                to_delete+=("$snapshot")
            fi
        fi
    done < <(zfs list -t snapshot -H -o name "${DATASET}" | grep "@${SNAPSHOT_PREFIX}")
    
    if [[ ${#to_delete[@]} -eq 0 ]]; then
        echo -e "${GREEN}No old snapshots to clean up.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Snapshots to delete:${NC}"
    for snap in "${to_delete[@]}"; do
        echo "  - $snap"
    done
    echo ""
    read -p "Delete these snapshots? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${GREEN}Cleanup cancelled.${NC}"
        exit 0
    fi
    
    local deleted=0
    for snap in "${to_delete[@]}"; do
        if zfs destroy "$snap"; then
            echo -e "${GREEN}✓ Deleted: $snap${NC}"
            ((deleted++))
        else
            echo -e "${RED}✗ Failed to delete: $snap${NC}"
        fi
    done
    
    echo -e "\n${GREEN}Deleted $deleted snapshot(s).${NC}"
}

# Main command handling
case "${1:-list}" in
    list)
        list_snapshots
        ;;
    latest)
        show_latest
        ;;
    rollback)
        rollback_snapshot "${2:-}"
        ;;
    info)
        show_info "${2:-}"
        ;;
    cleanup)
        cleanup_snapshots "${2:-30}"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}\n"
        usage
        exit 1
        ;;
esac
