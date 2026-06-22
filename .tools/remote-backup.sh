#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $0 <source-path> <remote-destination>" >&2
  exit 2
fi

SRC="$1"
DST="$2"

# Derive last directory name from source path
# (handles trailing slash)
SRC_BASENAME="$(basename "${SRC%/}")"

LOGDIR="/var/log/remote-backup/$SRC_BASENAME"
mkdir -p "$LOGDIR"
TIMESTAMP="$(date +%F-%H%M%S)"
LOGFILE="$LOGDIR/$TIMESTAMP.log"

# Time budget for entire job (from 10:00 start until 17:00) -> 7 hours
TOTAL_TIMEOUT="7h"

# Bandwidth: 100 megabits/sec = 12.5M bytes/sec for rclone --bwlimit
BWLIMIT="12.5M"

RCLONE_OPTS=(
  "--bwlimit=$BWLIMIT"
  "--log-file=$LOGFILE"
  "--log-level=INFO"
  "--transfers=8"
  "--checkers=8"
  "--use-server-modtime"
)

echo "Starting rclone sync from '$SRC' to '$DST' at $(date)" >> "$LOGFILE"
timeout --preserve-status "$TOTAL_TIMEOUT" rclone sync "$SRC" "$DST" "${RCLONE_OPTS[@]}"
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "rclone completed successfully at $(date)" >> "$LOGFILE"
elif [ $EXIT_CODE -eq 124 ]; then
  echo "rclone killed by timeout ($TOTAL_TIMEOUT) at $(date)" >> "$LOGFILE"
else
  echo "rclone exited with code $EXIT_CODE at $(date)" >> "$LOGFILE"
fi

exit $EXIT_CODE