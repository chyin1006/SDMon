#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_v2_cli_test_$$"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT
export SDMON_SUDO_MODE=mock

bash -n "$REPO_ROOT/sdmon-v2.sh"
bash -n "$REPO_ROOT/tests/test_sdmon_v2_cli.sh"

bash "$REPO_ROOT/sdmon-v2.sh" version | grep -q 'SDMon V2 RC1' || {
  printf 'FAIL: version output mismatch\n' >&2
  exit 1
}

bash "$REPO_ROOT/sdmon-v2.sh" help | grep -q 'Usage:' || {
  printf 'FAIL: help output missing usage\n' >&2
  exit 1
}

bash "$REPO_ROOT/sdmon-v2.sh" run --output "$TMP_DIR"

[ -f "$TMP_DIR/reports/report.json" ] || {
  printf 'FAIL: run did not generate reports/report.json\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.pdf" ] || {
  printf 'FAIL: run did not generate reports/report.pdf\n' >&2
  exit 1
}

[ -f "$TMP_DIR/reports/report.zip" ] || {
  printf 'FAIL: run did not generate reports/report.zip\n' >&2
  exit 1
}

if bash "$REPO_ROOT/sdmon-v2.sh" unknown >/dev/null 2>&1; then
  printf 'FAIL: unknown command returned success\n' >&2
  exit 1
fi

printf 'PASS\n'
