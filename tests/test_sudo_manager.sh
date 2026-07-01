#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SUDO_MANAGER="$REPO_ROOT/runtime/sudo_manager.sh"
TMP_DIR="${TMPDIR:-/tmp}/sdmon_sudo_manager_test_$$"

cleanup() {
  SDMON_SUDO_MODE=mock bash "$SUDO_MANAGER" release >/dev/null 2>&1 || true
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT
export SDMON_NO_OPEN=1
export SDMON_SUDO_MODE=mock
mkdir -p "$TMP_DIR"

bash -n "$SUDO_MANAGER"
bash -n "$REPO_ROOT/tests/test_sudo_manager.sh"

bash "$SUDO_MANAGER" acquire
bash "$SUDO_MANAGER" start-keepalive

status_value="$(bash "$SUDO_MANAGER" status)"
[ "$status_value" = "active" ] || {
  printf 'FAIL: sudo manager not active\n' >&2
  exit 1
}

run_value="$(bash "$SUDO_MANAGER" run printf 'mock-ok')"
[ "$run_value" = "mock-ok" ] || {
  printf 'FAIL: sudo manager run did not execute command\n' >&2
  exit 1
}

bash "$SUDO_MANAGER" release

status_after="$(bash "$SUDO_MANAGER" status)"
[ "$status_after" = "inactive" ] || {
  printf 'FAIL: sudo manager did not release\n' >&2
  exit 1
}

printf 'PASS\n'
