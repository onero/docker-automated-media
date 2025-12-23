#!/bin/bash

# Internal Config
PYTHON_PATH="/usr/local/sma/venv/bin/python3"
SCRIPT_PATH="/usr/local/sma/manual.py"
LOG_FILE="./conversion_progress.log"

# Arguments
CONTAINER_NAME=$1
TARGET_DIR=$2
NTFY_TOPIC=$3  # Optional

if [ -z "$CONTAINER_NAME" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <container_name> \"<folder_path>\" [ntfy_topic]"
    echo "Example: $0 Sonarr \"/tv/Mr. Robot\" adamino"
    exit 1
fi

START_TIME=$(date +%s)

# Helper for Optional Notifications
send_ntfy() {
    if [ -n "$NTFY_TOPIC" ]; then
        curl -H "Title: $2" -H "Tags: movie_camera,white_check_mark" \
             -d "$1" "https://ntfy.sh/$NTFY_TOPIC" > /dev/null 2>&1
    fi
}

# Pre-flight count
FILE_COUNT=$(docker exec -i "$CONTAINER_NAME" find "$TARGET_DIR" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.ts" \) | wc -l)

# Header
{
    echo "----------------------------------------------------------"
    echo "🚀 STARTING: $(date)"
    echo "📦 CONTAINER: $CONTAINER_NAME"
    echo "📂 TARGET:    $TARGET_DIR"
    echo "📄 FILES:     $FILE_COUNT"
    echo "----------------------------------------------------------"
} >> "$LOG_FILE"

# Heartbeat Loop
(
    while true; do
        sleep 60
        ELAPSED=$(($(date +%s) - START_TIME))
        
        # Extract filename and status
        CURRENT_FILE=$(grep "Processing file" "$LOG_FILE" | tail -n 1 | sed 's/.*Processing file //')
        FF_STATUS="💤 Idle"
        docker exec -i "$CONTAINER_NAME" ps aux | grep -v grep | grep -q ffmpeg && FF_STATUS="🔨 Converting"

        printf "⏱️  [%02dh:%02dm:%02ds] [%s] ➡️  %s\n" $((ELAPSED/3600)) $((ELAPSED%3600/60)) $((ELAPSED%60)) "$FF_STATUS" "$(basename "${CURRENT_FILE:-Initializing...}")" >> "$LOG_FILE"
    done
) &
TIMER_PID=$!

# Main Execution
docker exec -i "$CONTAINER_NAME" "$PYTHON_PATH" "$SCRIPT_PATH" -i "$TARGET_DIR" -a >> "$LOG_FILE" 2>&1

# Cleanup
kill "$TIMER_PID" 2>/dev/null
TOTAL_SECONDS=$(($(date +%s) - START_TIME))
DURATION=$(printf "%02dh:%02dm:%02ds" $((TOTAL_SECONDS/3600)) $((TOTAL_SECONDS%3600/60)) $((TOTAL_SECONDS%60)))

# Summary & Notification
SUMMARY="✅ Finished: $(basename "$TARGET_DIR")\n📄 Files: $FILE_COUNT\n⏱️ Duration: $DURATION"
{
    echo "----------------------------------------------------------"
    echo -e "$SUMMARY"
    echo "----------------------------------------------------------"
} >> "$LOG_FILE"

send_ntfy "$(echo -e "$SUMMARY")" "SMA Conversion Complete"