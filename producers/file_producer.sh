#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"

OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  file_producer.sh --output FILE

Emits one simulated file Normalized Event.
USAGE
}

die() {
  printf 'file_producer: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      shift
      [[ $# -gt 0 ]] || die "--output requires a file path"
      OUTPUT_FILE="$1"
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
[[ -x "$EVENT_WRITER" || -f "$EVENT_WRITER" ]] || die "missing event writer: $EVENT_WRITER"

ACTION="read"
PATH="/tmp/demo.txt"

bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
  EVENT_ID="evt-file-0001" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-06-29T00:00:00Z" \
  HOSTNAME="simulated-host" \
  USER_NAME="simulated-user" \
  PLATFORM="macos" \
  SENSOR_TYPE="file_producer" \
  PROFILE_ID="v2-alpha" \
  EVENT_CATEGORY="file" \
  EVENT_TYPE="file_access" \
  PROCESS_NAME="" \
  PID="" \
  ACTION="$ACTION" \
  TARGET="$PATH" \
  TARGET_TYPE="file" \
  SOURCE="file_producer" \
  CONFIDENCE="50" \
  TAGS="v2-alpha,simulated,file"
