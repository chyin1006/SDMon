#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"

OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  process_producer.sh --output FILE

Emits one simulated process Normalized Event.
USAGE
}

die() {
  printf 'process_producer: %s\n' "$1" >&2
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

PROCESS_NAME="test-process"
PID="1234"
ACTION="start"

bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
  EVENT_ID="evt-process-0001" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-06-29T00:00:00Z" \
  HOSTNAME="simulated-host" \
  USER_NAME="simulated-user" \
  PLATFORM="macos" \
  SENSOR_TYPE="process_producer" \
  PROFILE_ID="v2-alpha" \
  EVENT_CATEGORY="process" \
  EVENT_TYPE="process_state" \
  PROCESS_NAME="$PROCESS_NAME" \
  PID="$PID" \
  ACTION="$ACTION" \
  TARGET="$PROCESS_NAME" \
  TARGET_TYPE="process" \
  SOURCE="process_producer" \
  CONFIDENCE="50" \
  TAGS="v2-alpha,simulated,process"
