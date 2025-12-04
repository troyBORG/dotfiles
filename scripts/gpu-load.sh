#!/bin/bash
# Get GPU load for both NVIDIA and AMD GPUs

# Try NVIDIA first
if command -v nvidia-smi > /dev/null 2>&1; then
    load=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [ -n "$load" ]; then
        echo "GPU Load: ${load}%"
        exit 0
    fi
fi

# Try AMD (rocm-smi)
if command -v rocm-smi > /dev/null 2>&1; then
    load=$(rocm-smi --showuse --csv 2>/dev/null | grep -oP 'GPU use[^,]*,\K[0-9.]+' | head -1)
    if [ -n "$load" ]; then
        echo "GPU Load: ${load}%"
        exit 0
    fi
fi

# Try AMD via sysfs (alternative method for open-source drivers)
if [ -d /sys/class/drm ]; then
    for card in /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null; do
        if [ -f "$card" ]; then
            load=$(cat "$card" 2>/dev/null)
            if [ -n "$load" ]; then
                echo "GPU Load: ${load}%"
                exit 0
            fi
        fi
    done
fi

# If nothing found, exit with error (fastfetch will hide the module)
exit 1

