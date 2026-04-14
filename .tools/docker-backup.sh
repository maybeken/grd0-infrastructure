#!/usr/bin/env bash
set -euo pipefail

# Usage: sync-volumes.sh [-n|--dry-run]
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
RCLONE_BASE_PATH=""   # optional base path on remote, e.g. "backups"; leave empty for none

# Configuration: Logging location
LOG_BASE_PATH="/var/log/remote-backup"

log() { printf '%s\n' "$*"; }

# Build remote target helper
remote_target() {
  local app="$1" vol="$2"
  if [[ -n "$RCLONE_BASE_PATH" ]]; then
    printf '%s:%s/%s/%s' "$RCLONE_REMOTE" "$RCLONE_BASE_PATH" "$app" "$vol"
  else
    printf '%s:%s/%s' "$RCLONE_REMOTE" "$app" "$vol"
  fi
}

# Bandwidth: 100 megabits/sec = 12.5M bytes/sec for rclone --bwlimit
BWLIMIT="12.5M"

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

    # rclone flags
    RCLONE_FLAGS=(
        "--bwlimit=$BWLIMIT"
        "--log-file=$LOGFILE"
        "--log-level=INFO"
        "--transfers=8"
        "--checkers=8"
        "--use-server-modtime"
    )

    if [ "$DRY_RUN" = true ]; then
        RCLONE_FLAGS+=("--dry-run")
    fi

    target="$(remote_target "$app_name" "$volume_name")"
    log "Syncing volume '$volume_identifier' -> $target (dry-run=$DRY_RUN)"

    docker run --rm \
      -v "$HOME/.config/rclone:/root/.config/rclone:ro" \
      -v "${volume_identifier}:/mnt/volume:ro" \
      -v "${LOG_BASE_PATH}:${LOG_BASE_PATH}" \
      rclone/rclone sync "${RCLONE_FLAGS[@]}" /mnt/volume "$target"
  else
    log "Skipping volume '$volume_identifier' (does not match app_<volume_name> pattern)"
  fi
done
