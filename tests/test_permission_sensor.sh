#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_permission_sensor_test_$$"
OUTPUT_FILE="$TMP_DIR/events/permission_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

bash -n "$REPO_ROOT/sensors/macos/permission_sensor.sh"
bash -n "$REPO_ROOT/tests/test_permission_sensor.sh"

bash "$REPO_ROOT/sensors/macos/permission_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile"

[ -f "$OUTPUT_FILE" ] || {
  printf 'FAIL: permission event output was not created\n' >&2
  exit 1
}

LINE_COUNT="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[ "$LINE_COUNT" -ge 1 ] || {
  printf 'FAIL: expected at least one permission event\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"permission"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing permission category\n' >&2
  exit 1
}

grep -q '"ACTION":"permission_check"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing permission_check action\n' >&2
  exit 1
}

grep -q '"PERMISSION_TYPE":"[^"]' "$OUTPUT_FILE" || {
  printf 'FAIL: missing permission type\n' >&2
  exit 1
}

grep -q '"STATUS":"[^"]' "$OUTPUT_FILE" || {
  printf 'FAIL: missing status\n' >&2
  exit 1
}

printf 'PASS\n'
