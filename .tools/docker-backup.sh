#!/usr/bin/env bash
set -euo pipefail

# Usage: docker-backup.sh [-n|--dry-run]
DRY_RUN=false

# parse args
while (( "$#" )); do
  case "$1" in
    -n|--dry-run) DRY_RUN=true; shift ;;
    -h|--help) printf "Usage: %s [-n|--dry-run]\n" "$0"; exit 0 ;;
    *) printf "Unknown arg: %s\n" "$1"; exit 2 ;;
  esac
done

# Configuration: change remote target if needed
RCLONE_REMOTE="docker-hetzner"

# Configuration: Logging location
LOG_BASE_PATH="/var/log/remote-backup"

log() { printf '%s\n' "$*"; }

# Bandwidth: 100 megabits/sec = 12.5M bytes/sec for rclone --bwlimit
BWLIMIT="12.5M"

# Temporary directory for archives
BACKUP_TMP_DIR="${BACKUP_TMP_DIR:-/tmp/docker-backups}"
mkdir -p "$BACKUP_TMP_DIR"

cleanup() {
  rm -rf "$BACKUP_TMP_DIR"/*
}
trap cleanup EXIT

# Iterate docker volumes named like app_<rest>, where app is the prefix before the first underscore
# and <rest> (volume_name) can contain additional underscores (e.g., airtrail_db_data).
docker volume ls --format '{{.Name}}' | while IFS= read -r volume_identifier; do
  [[ -z "$volume_identifier" ]] && continue

  # must contain at least one underscore, not start or end with underscore
  if [[ "$volume_identifier" =~ ^([^_]+)_(.+[^_])$ ]]; then
    app_name="${BASH_REMATCH[1]}"
    volume_name="${BASH_REMATCH[2]}"

    LOGDIR="$LOG_BASE_PATH/$app_name/docker"
    mkdir -p "$LOGDIR"
    TIMESTAMP="$(date +%F-%H%M%S)"
    LOGFILE="$LOGDIR/$TIMESTAMP-$volume_name.log"

    ARCHIVE_NAME="${volume_identifier}.tar.gz"
    ARCHIVE_PATH="$BACKUP_TMP_DIR/$ARCHIVE_NAME"

    # rclone flags
    RCLONE_FLAGS=(
      "--bwlimit=$BWLIMIT"
      "--log-file=$LOGFILE"
      "--log-level=INFO"
    )

    if [ "$DRY_RUN" = true ]; then
        RCLONE_FLAGS+=("--dry-run")
    fi

    log "Archiving and uploading volume '$volume_identifier' -> $app_name/$ARCHIVE_NAME (dry-run=$DRY_RUN)"

    if [ "$DRY_RUN" = false ]; then
      docker run --rm \
        -v "${volume_identifier}:/mnt/volume:ro" \
        -v "${BACKUP_TMP_DIR}:/mnt/backup:rw" \
        alpine:latest \
        tar -czf "/mnt/backup/$ARCHIVE_NAME" -C /mnt/volume .

      rclone copy "${RCLONE_FLAGS[@]}" "$ARCHIVE_PATH" "$RCLONE_REMOTE:$app_name/"

      rm -f "$ARCHIVE_PATH"
    else
      log "  [dry-run] Would create archive: $ARCHIVE_NAME"
      log "  [dry-run] Would upload to: $app_nam/"
    fi
  else
    log "Skipping volume '$volume_identifier' (does not match app_<volume_name> pattern)"
  fi
done
