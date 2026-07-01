#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_file_sensor_test_$$"
TARGET_DIR="$TMP_DIR/target"
OUTPUT_FILE="$TMP_DIR/events/file_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TARGET_DIR"
printf 'demo\n' > "$TARGET_DIR/demo.txt"

bash -n "$REPO_ROOT/sensors/macos/file_sensor.sh"
bash -n "$REPO_ROOT/tests/test_file_sensor.sh"

bash "$REPO_ROOT/sensors/macos/file_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile" --path "$TARGET_DIR" --limit 1

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: file event file not generated\n' >&2
  exit 1
}

line_count="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[[ "$line_count" -ge 1 ]] || {
  printf 'FAIL: no file event generated\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"file"' "$OUTPUT_FILE" || {
  printf 'FAIL: EVENT_CATEGORY=file not found\n' >&2
  exit 1
}

grep -q '"TARGET":".*/demo.txt"' "$OUTPUT_FILE" || {
  printf 'FAIL: PATH/TARGET demo.txt not found\n' >&2
  exit 1
}

grep -q '"PROCESS_NAME":"demo.txt"' "$OUTPUT_FILE" || {
  printf 'FAIL: FILENAME mapping not found\n' >&2
  exit 1
}

grep -q '"SOURCE":"sensor"' "$OUTPUT_FILE" || {
  printf 'FAIL: SOURCE=sensor not found\n' >&2
  exit 1
}

printf 'PASS\n'
