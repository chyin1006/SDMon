#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_enterprise_security_sensor_test_$$"
OUTPUT_FILE="$TMP_DIR/events/enterprise_security_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

bash -n "$REPO_ROOT/sensors/macos/enterprise_security_sensor.sh"
bash -n "$REPO_ROOT/tests/test_enterprise_security_sensor.sh"

bash "$REPO_ROOT/sensors/macos/enterprise_security_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile"

[ -f "$OUTPUT_FILE" ] || {
  printf 'FAIL: enterprise security event output was not created\n' >&2
  exit 1
}

line_count="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[ "$line_count" -ge 5 ] || {
  printf 'FAIL: expected enterprise security events\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"browser_extension"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing browser extension event\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"application_inventory"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing application inventory event\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"xprotect_status"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing XProtect status event\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"firewall_status"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing firewall status event\n' >&2
  exit 1
}

grep -Eq '"STATUS":"(ok|present|enabled|disabled|unknown|unsupported|permission_denied|review|missing)"' "$OUTPUT_FILE" || {
  printf 'FAIL: missing normalized status values\n' >&2
  exit 1
}

printf 'PASS\n'
