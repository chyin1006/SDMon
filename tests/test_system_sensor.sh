#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_system_sensor_test_$$"
OUTPUT_FILE="$TMP_DIR/events/system_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

bash -n "$REPO_ROOT/sensors/macos/system_sensor.sh"
bash -n "$REPO_ROOT/tests/test_system_sensor.sh"

bash "$REPO_ROOT/sensors/macos/system_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile"

[ -f "$OUTPUT_FILE" ] || {
  printf 'FAIL: system event output was not created\n' >&2
  exit 1
}

LINE_COUNT="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[ "$LINE_COUNT" -ge 1 ] || {
  printf 'FAIL: expected at least one system event\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"system"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing system category\n' >&2
  exit 1
}

grep -q '"ACTION":"system_info"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing system_info action\n' >&2
  exit 1
}

grep -q '"HOSTNAME":"[^"]' "$OUTPUT_FILE" || {
  printf 'FAIL: missing hostname\n' >&2
  exit 1
}

grep -q '"OS_VERSION":"[^"]' "$OUTPUT_FILE" || {
  printf 'FAIL: missing OS version\n' >&2
  exit 1
}

printf 'PASS\n'
