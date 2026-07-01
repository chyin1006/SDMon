#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_event_writer_test_$$"
OUTPUT_FILE="$TMP_DIR/events/process_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

bash -n "$REPO_ROOT/events/event_writer.sh"
bash -n "$REPO_ROOT/tests/test_event_writer.sh"

bash "$REPO_ROOT/events/event_writer.sh" --output "$OUTPUT_FILE" \
  EVENT_ID="evt-test-0001" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-06-29T10:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="test-user" \
  PLATFORM="macos" \
  SENSOR_TYPE="process" \
  PROFILE_ID="test-profile" \
  EVENT_CATEGORY="process" \
  EVENT_TYPE="process_state" \
  PROCESS_NAME="test-process" \
  PID="1234" \
  ACTION="running" \
  TARGET="test-process" \
  TARGET_TYPE="process" \
  SOURCE="test_event_writer" \
  CONFIDENCE="90" \
  TAGS="test,process"

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: output file was not created\n' >&2
  exit 1
}

grep -q '"EVENT_ID":"evt-test-0001"' "$OUTPUT_FILE" || {
  printf 'FAIL: EVENT_ID not found\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"process"' "$OUTPUT_FILE" || {
  printf 'FAIL: EVENT_CATEGORY not found\n' >&2
  exit 1
}

grep -q '"PROCESS_NAME":"test-process"' "$OUTPUT_FILE" || {
  printf 'FAIL: PROCESS_NAME not found\n' >&2
  exit 1
}

printf 'PASS\n'
