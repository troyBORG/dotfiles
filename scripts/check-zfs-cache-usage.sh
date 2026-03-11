#!/bin/bash
#
# ZFS cache-dataset usage and ARC tuning
# - Reports how much each cache-like dataset uses (referenced, used, snapshots)
# - Suggests primarycache=metadata so ARC keeps hot data instead of bulk caches
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Reports ZFS cache-dataset usage (referenced, used, snapshots) and suggests
primarycache tuning so ARC is used for frequently-accessed data, not bulk caches.

Options:
    --suggest          Print suggested zfs set commands (no changes made)
    --all-datasets     Include all datasets under home/ROOT, not just *cache*
    -h, --help          Show this help

What primarycache=metadata does:
  - ARC caches only metadata (dirs, inodes) for that dataset → fast ls/find
  - File contents are read from disk when needed → ARC stays free for hot data
  - ARC already keeps "most frequently/recently used" data; this keeps bulk
    caches from filling it so your actual hot data (e.g. resonite-data, code)
    stays cached.

EOF
}

# Datasets we consider "cache-like" (name contains cache, or known cache dirs)
CACHE_PATTERNS='cache|varcache|yay-cache|downloads'

get_cache_datasets() {
    local all="${1:-false}"
    if [ "$all" = true ]; then
        zfs list -H -o name | grep -E '/(home|ROOT/cos)/' | grep -v '^zpcachyos/ROOT/cos/root$'
    else
        zfs list -H -o name | grep -E "($CACHE_PATTERNS)"
    fi
}

format_bytes() {
    local v="$1"
    if [ -z "$v" ] || [ "$v" = "-" ]; then
        echo "  -"
        return
    fi
    # ZFS reports like 17.3G, 81.4G, 274M
    if echo "$v" | grep -qE '^[0-9.]+[KMGTPE]?$'; then
        echo "$v"
    else
        echo "$v"
    fi
}

report_usage() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ZFS cache-dataset usage (zpool space)                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local datasets
    datasets=$(get_cache_datasets "$ALL_DATASETS")
    if [ -z "$datasets" ]; then
        echo -e "${YELLOW}No cache-like datasets found.${NC}"
        return
    fi

    echo -e "${CYAN}📁 Cache-style datasets: REFER (live data) / USED (with snapshots) / primarycache${NC}"
    echo ""

    local total_refer=0
    local total_used=0
    while IFS= read -r ds; do
        local refer used usedbysnap primarycache
        refer=$(zfs get -H -o value referenced "$ds" 2>/dev/null)
        used=$(zfs get -H -o value used "$ds" 2>/dev/null)
        usedbysnap=$(zfs get -H -o value usedbysnapshots "$ds" 2>/dev/null || echo "-")
        primarycache=$(zfs get -H -o value primarycache "$ds" 2>/dev/null)

        local short="${ds#zpcachyos/ROOT/cos/}"
        short="${short#zpcachyos/}"
        printf "   %-35s  REFER: %8s   USED: %8s   snapshots: %8s   primarycache=%s\n" \
            "$short" "$refer" "$used" "$usedbysnap" "$primarycache"
    done <<< "$datasets"

    echo ""
    echo -e "${CYAN}💡 REFER = current live data size. USED = REFER + space used by snapshots.${NC}"
    echo ""
}

# Skip suggesting for very small datasets (e.g. 96K empty-ish)
is_small_refer() {
    local refer="$1"
    case "$refer" in
        *K|*kB) return 0 ;;  # skip
        [0-9]*M) return 0 ;;  # skip a few hundred MB or less for suggest
        *) return 1 ;;        # include G, T, or large M
    esac
}

suggest_tuning() {
    echo -e "${CYAN}Suggested primarycache=metadata for bulk caches (so ARC keeps hot data):${NC}"
    echo "   Run only if you want ARC to stop caching file contents for these datasets."
    echo "   Metadata (dirs, inodes) is still cached → ls/find stay fast; file reads hit disk."
    echo "   (resonite-cache already has primarycache=metadata)"
    echo ""

    local datasets
    datasets=$(get_cache_datasets false)
    while IFS= read -r ds; do
        local primarycache refer
        primarycache=$(zfs get -H -o value primarycache "$ds" 2>/dev/null)
        refer=$(zfs get -H -o value referenced "$ds" 2>/dev/null)
        if [ "$primarycache" = "all" ] && ! is_small_refer "$refer"; then
            printf "   sudo zfs set primarycache=metadata %s\n" "$ds"
        fi
    done <<< "$datasets"
    echo ""
}

# Main
ALL_DATASETS=false
SUGGEST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all-datasets) ALL_DATASETS=true; shift ;;
        --suggest)      SUGGEST=true; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)             echo -e "${RED}Unknown option: $1${NC}"; usage; exit 1 ;;
    esac
done

if ! command -v zfs &>/dev/null; then
    echo -e "${RED}Error: zfs not found.${NC}"
    exit 1
fi

report_usage

if [ "$SUGGEST" = true ]; then
    suggest_tuning
fi

echo -e "${CYAN}🔍 Full ARC breakdown:${NC} zarcsummary  (or arc_summary)"
echo -e "${CYAN}   ARC + dataset likelihood:${NC} $(dirname "$0")/check-arc-cache.sh"
echo ""
