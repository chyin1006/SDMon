#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_credential_sensor_test_$$"
HOME_DIR="$TMP_DIR/home"
SCAN_ROOT="$TMP_DIR/work"
OUTPUT_FILE="$TMP_DIR/events/credential_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT
export SDMON_NO_OPEN=1

mkdir -p "$HOME_DIR/.ssh" "$HOME_DIR/.aws" "$SCAN_ROOT"
printf 'demo\n' > "$HOME_DIR/.ssh/id_rsa"
printf 'demo\n' > "$HOME_DIR/.aws/credentials"
printf 'demo=1\n' > "$SCAN_ROOT/.env"
chmod 0644 "$HOME_DIR/.ssh/id_rsa"
chmod 0600 "$HOME_DIR/.aws/credentials"
chmod 0644 "$SCAN_ROOT/.env"

bash -n "$REPO_ROOT/sensors/macos/credential_sensor.sh"
bash -n "$REPO_ROOT/tests/test_credential_sensor.sh"

HOME="$HOME_DIR" bash "$REPO_ROOT/sensors/macos/credential_sensor.sh" \
  --output "$OUTPUT_FILE" \
  --scan-root "$SCAN_ROOT" \
  --profile test

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: credential events file not created\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"credential_detected"' "$OUTPUT_FILE" || {
  printf 'FAIL: credential_detected event missing\n' >&2
  exit 1
}

grep -q 'SSH Private Key' "$OUTPUT_FILE" || {
  printf 'FAIL: SSH Private Key metadata missing\n' >&2
  exit 1
}

grep -q '"STATUS":"review"\|"STATUS":"present"' "$OUTPUT_FILE" || {
  printf 'FAIL: credential status missing\n' >&2
  exit 1
}

grep -q 'credential_sensitive_permission_unsafe\|credential_permission_unsafe\|credential_detected' "$OUTPUT_FILE" || {
  printf 'FAIL: credential action missing\n' >&2
  exit 1
}

printf 'PASS\n'
