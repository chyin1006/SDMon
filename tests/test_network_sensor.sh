#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_network_sensor_test_$$"
OUTPUT_FILE="$TMP_DIR/events/network_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

bash -n "$REPO_ROOT/sensors/macos/network_sensor.sh"
bash -n "$REPO_ROOT/tests/test_network_sensor.sh"

bash "$REPO_ROOT/sensors/macos/network_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile" --limit 1

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: network event file not generated\n' >&2
  exit 1
}

line_count="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[[ "$line_count" -ge 1 ]] || {
  printf 'FAIL: no network event generated\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"network"' "$OUTPUT_FILE" || {
  printf 'FAIL: CATEGORY=network not found\n' >&2
  exit 1
}

grep -q '"ACTION":"[^"]' "$OUTPUT_FILE" || {
  printf 'FAIL: ACTION not found\n' >&2
  exit 1
}

grep -q '"HOSTNAME":"[^"]' "$OUTPUT_FILE" || {
  printf 'FAIL: HOSTNAME not found\n' >&2
  exit 1
}

printf 'PASS\n'
