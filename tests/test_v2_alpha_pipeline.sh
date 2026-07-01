#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_v2_alpha_pipeline_test_$$"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT
export SDMON_NO_OPEN=1
export SDMON_SUDO_MODE=mock

bash -n "$REPO_ROOT/v2_alpha.sh"
bash -n "$REPO_ROOT/tests/test_v2_alpha_pipeline.sh"

bash "$REPO_ROOT/v2_alpha.sh" "$TMP_DIR"

[ -f "$TMP_DIR/events/all_events.jsonl" ] || {
  printf 'FAIL: events/all_events.jsonl was not created\n' >&2
  exit 1
}

[ -f "$TMP_DIR/events/sensor_status.jsonl" ] || {
  printf 'FAIL: events/sensor_status.jsonl was not created\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.json" ] || {
  printf 'FAIL: reports/report.json was not created\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.html" ] || {
  printf 'FAIL: reports/report.html was not created\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.csv" ] || {
  printf 'FAIL: reports/report.csv was not created\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.pdf" ] || {
  printf 'FAIL: reports/report.pdf was not created\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.zip" ] || {
  printf 'FAIL: reports/report.zip was not created\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"launchd"' "$TMP_DIR/events/all_events.jsonl" || {
  printf 'FAIL: launchd event was not collected\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"ssh_authorized_key"' "$TMP_DIR/events/all_events.jsonl" || {
  printf 'FAIL: SSH authorized_keys event was not collected\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"gatekeeper_status"' "$TMP_DIR/events/all_events.jsonl" || {
  printf 'FAIL: Gatekeeper status event was not collected\n' >&2
  exit 1
}

grep -q 'SSH_KEY_EVENTS' "$TMP_DIR/reports/report.json" || {
  printf 'FAIL: report JSON missing SSH_KEY_EVENTS\n' >&2
  exit 1
}

grep -q 'MACOS_SECURITY_EVENTS' "$TMP_DIR/reports/report.json" || {
  printf 'FAIL: report JSON missing MACOS_SECURITY_EVENTS\n' >&2
  exit 1
}

grep -q 'SENSITIVE_FILE_EVENTS' "$TMP_DIR/reports/report.json" || {
  printf 'FAIL: report JSON missing SENSITIVE_FILE_EVENTS\n' >&2
  exit 1
}

grep -q 'CREDENTIAL_EVENTS' "$TMP_DIR/reports/report.json" || {
  printf 'FAIL: report JSON missing CREDENTIAL_EVENTS\n' >&2
  exit 1
}

grep -q 'DEVICE_HEALTH' "$TMP_DIR/reports/report.json" || {
  printf 'FAIL: report JSON missing DEVICE_HEALTH\n' >&2
  exit 1
}

grep -q 'SECURITY_SCORE' "$TMP_DIR/reports/report.json" || {
  printf 'FAIL: report JSON missing SECURITY_SCORE\n' >&2
  exit 1
}

grep -q '"SENSOR":"enterprise_security".*"STATUS":"success"' "$TMP_DIR/events/sensor_status.jsonl" || {
  printf 'FAIL: enterprise_security sensor did not run successfully\n' >&2
  exit 1
}

grep -q '"SENSOR":"credential".*"STATUS":"success"' "$TMP_DIR/events/sensor_status.jsonl" || {
  printf 'FAIL: credential sensor did not run successfully\n' >&2
  exit 1
}

printf 'PASS\n'
