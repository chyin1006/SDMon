#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_macos_sensor_runner_test_$$"
OUTPUT_DIR="$TMP_DIR/events"
ALL_EVENTS_FILE="$OUTPUT_DIR/all_events.jsonl"
STATUS_FILE="$OUTPUT_DIR/sensor_status.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

bash -n "$REPO_ROOT/sensors/macos/run_all_sensors.sh"
bash -n "$REPO_ROOT/tests/test_macos_sensor_runner.sh"

bash "$REPO_ROOT/sensors/macos/run_all_sensors.sh" "$OUTPUT_DIR"

[ -f "$ALL_EVENTS_FILE" ] || {
  printf 'FAIL: all_events.jsonl was not created\n' >&2
  exit 1
}

[ -f "$STATUS_FILE" ] || {
  printf 'FAIL: sensor_status.jsonl was not created\n' >&2
  exit 1
}

grep -Eq '"EVENT_CATEGORY":"(process|system|permission)"' "$ALL_EVENTS_FILE" || {
  printf 'FAIL: expected process, system, or permission event\n' >&2
  exit 1
}

printf 'PASS\n'
