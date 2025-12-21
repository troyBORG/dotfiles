#!/bin/bash
#
# FFmpeg utility to split tall screenshots into chunks
# Automatically detects image dimensions and splits tall screenshots into
# manageable chunks for easier processing. Auto-calculates optimal chunk
# height to create ~12 chunks, with manual override option.
#
# Usage: ./crop_screenshot.sh image.png [chunk_height]

set -euo pipefail

INPUT_FILE="${1:-}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 image.png [chunk_height]"
    echo "  image.png      - Input image file"
    echo "  chunk_height   - Optional: Height of each chunk in pixels (auto-calculated if not provided)"
    exit 1
fi

# Extract base filename without extension for output prefix
BASE_NAME=$(basename "$INPUT_FILE" | sed 's/\.[^.]*$//')
OUTPUT_PREFIX="${BASE_NAME}_chunk"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Check if ffmpeg/ffprobe is available
if ! command -v ffprobe &> /dev/null; then
    echo "Error: ffprobe not found. Please install ffmpeg."
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg not found. Please install ffmpeg."
    exit 1
fi

# Auto-detect image dimensions
echo "Detecting image dimensions..."
DIMENSIONS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$INPUT_FILE" 2>/dev/null)
if [ -z "$DIMENSIONS" ]; then
    echo "Error: Could not detect image dimensions. Is this a valid image file?"
    exit 1
fi

WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
TOTAL_HEIGHT=$(echo "$DIMENSIONS" | cut -d'x' -f2)

echo "Detected dimensions: ${WIDTH}x${TOTAL_HEIGHT}"

# Auto-calculate chunk height if not provided
# Aim for approximately 12 chunks for tall images
if [ -z "${2:-}" ]; then
    # Calculate chunk height to create ~12 chunks
    TARGET_CHUNKS=12
    CHUNK_HEIGHT=$(( (TOTAL_HEIGHT + TARGET_CHUNKS - 1) / TARGET_CHUNKS ))
    # Round to nearest 500 for cleaner numbers
    CHUNK_HEIGHT=$(( ((CHUNK_HEIGHT + 250) / 500) * 500 ))
    # Minimum chunk height of 2000, maximum of 5000
    if [ $CHUNK_HEIGHT -lt 2000 ]; then
        CHUNK_HEIGHT=2000
    elif [ $CHUNK_HEIGHT -gt 5000 ]; then
        CHUNK_HEIGHT=5000
    fi
    echo "Auto-calculated chunk height: ${CHUNK_HEIGHT}px (targeting ~$TARGET_CHUNKS chunks)"
else
    CHUNK_HEIGHT="$2"
    # Validate chunk height is a positive number
    if ! [[ "$CHUNK_HEIGHT" =~ ^[0-9]+$ ]] || [ "$CHUNK_HEIGHT" -le 0 ]; then
        echo "Error: chunk_height must be a positive number."
        exit 1
    fi
fi

# Calculate number of chunks needed
NUM_CHUNKS=$(( (TOTAL_HEIGHT + CHUNK_HEIGHT - 1) / CHUNK_HEIGHT ))

echo "Cropping ${INPUT_FILE} into ${NUM_CHUNKS} chunks..."
echo "Each chunk will be ${WIDTH}x${CHUNK_HEIGHT} pixels (last chunk may be smaller)"

# Crop into chunks
for i in $(seq 0 $((NUM_CHUNKS - 1))); do
    Y_OFFSET=$((i * CHUNK_HEIGHT))
    
    # For the last chunk, use remaining height
    if [ $i -eq $((NUM_CHUNKS - 1)) ]; then
        REMAINING_HEIGHT=$((TOTAL_HEIGHT - Y_OFFSET))
        ffmpeg -i "$INPUT_FILE" -vf "crop=${WIDTH}:${REMAINING_HEIGHT}:0:${Y_OFFSET}" \
            "${OUTPUT_PREFIX}_$(printf "%02d" $((i + 1))).png" -y -loglevel error
        echo "Created chunk $((i + 1))/${NUM_CHUNKS} (${WIDTH}x${REMAINING_HEIGHT})"
    else
        ffmpeg -i "$INPUT_FILE" -vf "crop=${WIDTH}:${CHUNK_HEIGHT}:0:${Y_OFFSET}" \
            "${OUTPUT_PREFIX}_$(printf "%02d" $((i + 1))).png" -y -loglevel error
        echo "Created chunk $((i + 1))/${NUM_CHUNKS} (${WIDTH}x${CHUNK_HEIGHT})"
    fi
done

echo "Done! Created ${NUM_CHUNKS} chunks: ${OUTPUT_PREFIX}_01.png through ${OUTPUT_PREFIX}_$(printf "%02d" ${NUM_CHUNKS}).png"

