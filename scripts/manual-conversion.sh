#!/bin/bash

# Configuration
PYTHON_PATH="/usr/local/sma/venv/bin/python3"
SCRIPT_PATH="/usr/local/sma/manual.py"
LOG_FILE="./conversion_progress.log"

CONTAINER_NAME=$1
TARGET_DIR=$2

if [ -z "$CONTAINER_NAME" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <container_name> \"<folder_path>\""
    exit 1
fi

START_TIME=$(date +%s)

# Count total files before starting
FILE_COUNT=$(docker exec -i "$CONTAINER_NAME" find "$TARGET_DIR" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.ts" \) | wc -l)

# Header
{
    echo "----------------------------------------------------------"
    echo "🚀 STARTING: $(date)"
    echo "📦 CONTAINER: $CONTAINER_NAME"
    echo "📂 TARGET:    $TARGET_DIR"
    echo "📄 TOTAL FILES TO PROCESS: $FILE_COUNT"
    echo "----------------------------------------------------------"
} >> "$LOG_FILE"

# Advanced Heartbeat Timer
(
    while true; do
        sleep 60
        CURRENT_TIME=$(date +%s)
        ELAPSED=$((CURRENT_TIME - START_TIME))
        
        # Get the last file SMA mentioned it was processing
        CURRENT_FILE=$(grep "Processing file" "$LOG_FILE" | tail -n 1 | sed 's/.*Processing file //')
        [ -z "$CURRENT_FILE" ] && CURRENT_FILE="Initializing..."

        # Check if ffmpeg is currently active in the container
        FF_STATUS="💤 Idle"
        docker exec -i "$CONTAINER_NAME" ps aux | grep -v grep | grep -q ffmpeg && FF_STATUS="🔨 Converting"

        printf "⏱️  [%02dh:%02dm:%02ds] [%s] ➡️  %s\n" $((ELAPSED/3600)) $((ELAPSED%3600/60)) $((ELAPSED%60)) "$FF_STATUS" "$(basename "$CURRENT_FILE")" >> "$LOG_FILE"
    done
) &
TIMER_PID=$!

# Execute SMA
docker exec -i "$CONTAINER_NAME" "$PYTHON_PATH" "$SCRIPT_PATH" -i "$TARGET_DIR" -a >> "$LOG_FILE" 2>&1

# Cleanup Timer
kill "$TIMER_PID" 2>/dev/null

# Footer
END_TIME=$(date +%s)
TOTAL_SECONDS=$((END_TIME - START_TIME))
{
    echo "----------------------------------------------------------"
    echo "✅ FINISHED: $(date)"
    echo "📄 TOTAL FILES PROCESSED: $FILE_COUNT"
    printf "⏱️  TOTAL DURATION: %02dh:%02dm:%02ds\n" $((TOTAL_SECONDS/3600)) $((TOTAL_SECONDS%3600/60)) $((TOTAL_SECONDS%60))
    echo "----------------------------------------------------------"
} >> "$LOG_FILE"