#!/bin/bash
#
# ZFS ARC Cache Analysis Script
# Shows what's likely cached in ZFS ARC and analyzes cache effectiveness
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Analyzes ZFS ARC cache to show what datasets are likely cached and cache effectiveness.

Options:
    --dataset DATASET    Check specific dataset (default: checks all datasets)
    --resonite          Only check Resonite datasets
    --brief             Brief output format
    -h, --help          Show this help message

Examples:
    $0
    $0 --resonite
    $0 --dataset zpcachyos/ROOT/cos/home/resonite-cache

EOF
}

check_dependencies() {
    if ! command -v arc_summary &> /dev/null; then
        echo -e "${RED}Error: arc_summary not found. Install zfs-utils package.${NC}"
        exit 1
    fi
    
    if ! command -v zfs &> /dev/null; then
        echo -e "${RED}Error: zfs not found.${NC}"
        exit 1
    fi
}

get_arc_data_size() {
    # Extract GiB value from "96.7 %   27.2 GiB" format (second number before GiB)
    arc_summary 2>/dev/null | grep "Data size:" | awk '{for(i=1;i<=NF;i++) if($i == "GiB") {print $(i-1); exit}}'
}

get_arc_total_size() {
    # Extract GiB value from "47.2 %   29.1 GiB" format (second number before GiB)
    arc_summary 2>/dev/null | grep "Current size:" | awk '{for(i=1;i<=NF;i++) if($i == "GiB") {print $(i-1); exit}}'
}

get_arc_hit_rate() {
    local hits misses total
    hits=$(cat /proc/spl/kstat/zfs/arcstats 2>/dev/null | awk '/^hits/ {print $3}')
    misses=$(cat /proc/spl/kstat/zfs/arcstats 2>/dev/null | awk '/^misses/ {print $3}')
    
    if [ -n "$hits" ] && [ -n "$misses" ] && [ $((hits + misses)) -gt 0 ]; then
        total=$((hits + misses))
        # Calculate percentage using awk (more portable than bc)
        awk -v h="$hits" -v t="$total" 'BEGIN {printf "%.2f", (h/t)*100}'
    else
        echo "0"
    fi
}

format_size() {
    local size_gb="$1"
    if [ -z "$size_gb" ] || [ "$size_gb" = "0" ] || [ "$size_gb" = "0.0" ]; then
        echo "N/A"
    else
        printf "%.1f GB" "$size_gb" 2>/dev/null || echo "${size_gb} GB"
    fi
}

check_dataset_cache_likelihood() {
    local dataset="$1"
    local arc_data_size="$2"
    
    local referenced
    referenced=$(zfs get -H -o value referenced "$dataset" 2>/dev/null)
    
    if [ -z "$referenced" ] || [ "$referenced" = "-" ]; then
        return 1
    fi
    
    # Convert to GB (handle different formats like "30.1G", "1.58G", etc)
    local size_gb
    if echo "$referenced" | grep -q "G"; then
        size_gb=$(echo "$referenced" | sed 's/G//')
    elif echo "$referenced" | grep -q "M"; then
        size_mb=$(echo "$referenced" | sed 's/M//')
        size_gb=$(awk -v m="$size_mb" 'BEGIN {printf "%.2f", m/1024}')
    elif echo "$referenced" | grep -q "T"; then
        size_tb=$(echo "$referenced" | sed 's/T//')
        size_gb=$(awk -v t="$size_tb" 'BEGIN {printf "%.2f", t*1024}')
    else
        # Assume bytes, convert to GB
        size_gb=$(awk -v b="$referenced" 'BEGIN {printf "%.2f", b/1024/1024/1024}')
    fi
    
    local percentage
    if [ -n "$arc_data_size" ] && [ -n "$size_gb" ] && [ "$(awk -v a="$arc_data_size" 'BEGIN {print (a > 0)}')" -eq 1 ]; then
        percentage=$(awk -v s="$size_gb" -v a="$arc_data_size" 'BEGIN {printf "%.1f", (s/a)*100}')
    else
        percentage="0"
    fi
    
    echo "$size_gb|$percentage"
}

show_arc_summary() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  ZFS ARC Cache Analysis                                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local arc_total arc_data hit_rate
    arc_total=$(get_arc_total_size)
    arc_data=$(get_arc_data_size)
    hit_rate=$(get_arc_hit_rate)
    
    echo -e "${CYAN}📊 ARC Cache Statistics:${NC}"
    echo "   Total ARC Size:    $(format_size "$arc_total")"
    echo "   Data Cache Size:   $(format_size "$arc_data")"
    echo "   Cache Hit Rate:    ${hit_rate}%"
    
    # Interpret hit rate
    if [ -n "$hit_rate" ] && [ "$(awk -v r="$hit_rate" 'BEGIN {print (r > 95)}')" -eq 1 ]; then
        echo -e "   Status:            ${GREEN}Excellent${NC} - Cache working very well"
    elif [ -n "$hit_rate" ] && [ "$(awk -v r="$hit_rate" 'BEGIN {print (r > 80)}')" -eq 1 ]; then
        echo -e "   Status:            ${GREEN}Good${NC} - Cache working well"
    elif [ -n "$hit_rate" ] && [ "$(awk -v r="$hit_rate" 'BEGIN {print (r > 50)}')" -eq 1 ]; then
        echo -e "   Status:            ${YELLOW}Fair${NC} - Cache could be better"
    else
        echo -e "   Status:            ${RED}Poor${NC} - Low cache efficiency"
    fi
    echo ""
}

analyze_datasets() {
    local dataset_filter="$1"
    local arc_data_size
    arc_data_size=$(get_arc_data_size)
    
    echo -e "${CYAN}📁 Dataset Cache Likelihood Analysis:${NC}"
    echo ""
    
    local datasets
    if [ "$dataset_filter" = "resonite" ]; then
        datasets=$(zfs list -H -o name | grep -i resonite)
    elif [ -n "$dataset_filter" ] && [ "$dataset_filter" != "all" ]; then
        datasets="$dataset_filter"
    else
        # Get all datasets, prioritize larger ones
        datasets=$(zfs list -H -o name | grep -v "^zpcachyos/ROOT/cos/root$" | head -20)
    fi
    
    if [ -z "$datasets" ]; then
        echo -e "${YELLOW}No datasets found matching filter.${NC}"
        return
    fi
    
    local found_something=false
    
    while IFS= read -r dataset; do
        local result
        result=$(check_dataset_cache_likelihood "$dataset" "$arc_data_size")
        
        if [ $? -eq 0 ]; then
            found_something=true
            local size_gb percentage
            size_gb=$(echo "$result" | cut -d'|' -f1)
            percentage=$(echo "$result" | cut -d'|' -f2)
            
            # Get dataset display name (shorten if needed)
            local display_name="${dataset#zpcachyos/ROOT/cos/home/}"
            display_name="${display_name#zpcachyos/ROOT/cos/}"
            
            printf "   %-40s " "$display_name"
            printf "%8s" "$(format_size "$size_gb")"
            
            if [ -n "$percentage" ] && [ "$(awk -v p="$percentage" 'BEGIN {print (p > 0)}')" -eq 1 ]; then
                if [ "$(awk -v p="$percentage" 'BEGIN {print (p > 80)}')" -eq 1 ]; then
                    printf "  ${GREEN}~%.0f%% of ARC${NC}\n" "$percentage"
                elif [ "$(awk -v p="$percentage" 'BEGIN {print (p > 50)}')" -eq 1 ]; then
                    printf "  ${YELLOW}~%.0f%% of ARC${NC}\n" "$percentage"
                elif [ "$(awk -v p="$percentage" 'BEGIN {print (p > 20)}')" -eq 1 ]; then
                    printf "  ~%.0f%% of ARC\n" "$percentage"
                else
                    printf "  <%.0f%% of ARC\n" "$percentage"
                fi
            else
                printf "  (dataset info)\n"
            fi
        fi
    done <<< "$datasets"
    
    if [ "$found_something" = false ]; then
        echo -e "${YELLOW}Could not analyze datasets.${NC}"
    fi
    
    echo ""
}

show_conclusion() {
    local arc_data_size
    arc_data_size=$(get_arc_data_size)
    
    echo -e "${CYAN}💡 Analysis Notes:${NC}"
    echo "   • ARC (Adaptive Replacement Cache) automatically caches frequently accessed files"
    echo "   • Larger datasets that match ARC size are likely heavily cached"
    echo "   • High hit rate (>95%) indicates effective caching"
    echo "   • If a dataset size ≈ ARC data size, it's very likely cached"
    echo ""
    echo -e "${CYAN}🔍 To see detailed ARC breakdown:${NC}"
    echo "   arc_summary"
    echo ""
}

# Main
DATASET_FILTER="all"
BRIEF=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dataset)
            DATASET_FILTER="$2"
            shift 2
            ;;
        --resonite)
            DATASET_FILTER="resonite"
            shift
            ;;
        --brief)
            BRIEF=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}\n"
            usage
            exit 1
            ;;
    esac
done

check_dependencies

if [ "$BRIEF" = true ]; then
    arc_total=$(get_arc_total_size)
    arc_data=$(get_arc_data_size)
    hit_rate=$(get_arc_hit_rate)
    echo "ARC: $(format_size "$arc_total") total, $(format_size "$arc_data") data, ${hit_rate}% hit rate"
else
    show_arc_summary
    analyze_datasets "$DATASET_FILTER"
    show_conclusion
fi

