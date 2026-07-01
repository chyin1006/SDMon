#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_process_sensor_test_$$"
OUTPUT_FILE="$TMP_DIR/events/process_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

bash -n "$REPO_ROOT/sensors/macos/process_sensor.sh"
bash -n "$REPO_ROOT/tests/test_process_sensor.sh"

bash "$REPO_ROOT/sensors/macos/process_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile" --limit 1

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: process event file not generated\n' >&2
  exit 1
}

line_count="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[[ "$line_count" -ge 1 ]] || {
  printf 'FAIL: no process event generated\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"process"' "$OUTPUT_FILE" || {
  printf 'FAIL: EVENT_CATEGORY=process not found\n' >&2
  exit 1
}

grep -q '"SOURCE":"sensor"' "$OUTPUT_FILE" || {
  printf 'FAIL: SOURCE=sensor not found\n' >&2
  exit 1
}

grep -q '"PROFILE_ID":"test-profile"' "$OUTPUT_FILE" || {
  printf 'FAIL: PROFILE_ID=test-profile not found\n' >&2
  exit 1
}

printf 'PASS\n'
