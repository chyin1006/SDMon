#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"

OUTPUT_FILE=""
PROFILE_ID="default"
LIMIT="0"
TARGET_DIRS="/Library/LaunchAgents
/Library/LaunchDaemons
/Applications
/System/Library/LaunchAgents
/System/Library/LaunchDaemons"
SENSITIVE_PATHS="$HOME/.ssh
$HOME/Library/Keychains
/etc/hosts
/etc/sudoers
/private/etc"

usage() {
  cat <<'USAGE'
Usage:
  file_sensor.sh --output FILE [--profile PROFILE_ID] [--path DIR] [--limit N]

Collects file inventory observations from selected macOS directories and writes file Normalized Events.
USAGE
}

die() {
  printf 'file_sensor: %s\n' "$1" >&2
  exit 1
}

is_number() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

write_file_event() {
  local event_id="$1"
  local event_type="$2"
  local action="$3"
  local file_path="$4"
  local target_type="$5"
  local detail="$6"
  local filename

  filename="${file_path##*/}"
  [[ -n "$filename" ]] || filename="$file_path"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="" \
    PLATFORM="macos" \
    SENSOR_TYPE="file" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="file" \
    EVENT_TYPE="$event_type" \
    PROCESS_NAME="$filename" \
    PID="" \
    ACTION="$action" \
    TARGET="$file_path" \
    TARGET_TYPE="$target_type" \
    SOURCE="sensor" \
    CONFIDENCE="80" \
    TAGS="macos,file,sensor" \
    DETAIL="$detail"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      shift
      [[ $# -gt 0 ]] || die "--output requires a file path"
      OUTPUT_FILE="$1"
      ;;
    --profile)
      shift
      [[ $# -gt 0 ]] || die "--profile requires a value"
      PROFILE_ID="$1"
      ;;
    --path)
      shift
      [[ $# -gt 0 ]] || die "--path requires a directory"
      TARGET_DIRS="$1"
      ;;
    --limit)
      shift
      [[ $# -gt 0 ]] || die "--limit requires a number"
      LIMIT="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
  shift
done

[[ -n "$OUTPUT_FILE" ]] || die "missing --output FILE"
is_number "$LIMIT" || die "--limit must be a non-negative number"
[[ -f "$EVENT_WRITER" ]] || die "missing event writer: $EVENT_WRITER"
command -v find >/dev/null 2>&1 || die "missing required macOS command: find"

HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
count="0"

printf '%s\n' "$TARGET_DIRS" | while IFS= read -r target_dir; do
  [[ -n "$target_dir" && -d "$target_dir" ]] || continue

  find "$target_dir" -maxdepth 1 -mindepth 1 -print 2>/dev/null | while IFS= read -r file_path; do
    [[ -n "$file_path" ]] || continue

    count=$((count + 1))
    write_file_event "file-${count}" "file_inventory" "found" "$file_path" "file" "path=$file_path;status=found"

    if [[ "$LIMIT" -gt 0 && "$count" -ge "$LIMIT" ]]; then
      break 2
    fi
  done
done

sensitive_count="0"
printf '%s\n' "$SENSITIVE_PATHS" | while IFS= read -r sensitive_path; do
  [[ -n "$sensitive_path" ]] || continue
  sensitive_count=$((sensitive_count + 1))

  if [[ ! -e "$sensitive_path" ]]; then
    write_file_event "sensitive-file-${sensitive_count}" "sensitive_file" "sensitive_file_not_found" "$sensitive_path" "sensitive_path" "path=$sensitive_path;status=not_found;sensitive=true"
  elif [[ ! -r "$sensitive_path" ]]; then
    write_file_event "sensitive-file-${sensitive_count}" "sensitive_file" "sensitive_file_permission_denied" "$sensitive_path" "sensitive_path" "path=$sensitive_path;status=permission_denied;sensitive=true"
  else
    write_file_event "sensitive-file-${sensitive_count}" "sensitive_file" "sensitive_file_observed" "$sensitive_path" "sensitive_path" "path=$sensitive_path;status=observed;sensitive=true"
  fi
done
