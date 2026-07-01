#!/usr/bin/env bash

set -u

STATE_DIR="${TMPDIR:-/tmp}/sdmon-v2-sudo-${UID}"
KEEPALIVE_PID_FILE="$STATE_DIR/keepalive.pid"
SESSION_FILE="$STATE_DIR/session"
MODE_FILE="$STATE_DIR/mode"

usage() {
  cat <<'USAGE'
Usage:
  sudo_manager.sh acquire
  sudo_manager.sh ensure
  sudo_manager.sh status
  sudo_manager.sh run COMMAND [ARGS...]
  sudo_manager.sh start-keepalive
  sudo_manager.sh stop-keepalive
  sudo_manager.sh release
USAGE
}

state_mkdir() {
  mkdir -p "$STATE_DIR"
}

mode_value() {
  if [ -f "$MODE_FILE" ]; then
    sed -n '1p' "$MODE_FILE"
  else
    printf '%s' "${SDMON_SUDO_MODE:-system}"
  fi
}

write_mode() {
  state_mkdir
  printf '%s\n' "$1" > "$MODE_FILE"
}

mark_active() {
  state_mkdir
  : > "$SESSION_FILE"
}

is_active() {
  if [ "${SDMON_SUDO_MODE:-system}" = "mock" ]; then
    [ -f "$SESSION_FILE" ]
    return "$?"
  fi

  if [ -f "$SESSION_FILE" ] && sudo -n true >/dev/null 2>&1; then
    return 0
  fi

  if [ ! -f "$SESSION_FILE" ]; then
    return 1
  fi

  sudo -n true >/dev/null 2>&1
}

acquire_system() {
  attempts="0"
  while [ "$attempts" -lt 3 ]; do
    if sudo -v; then
      write_mode "system"
      mark_active
      return 0
    fi
    attempts=$((attempts + 1))
  done
  return 1
}

acquire_mock() {
  write_mode "mock"
  mark_active
}

start_keepalive() {
  state_mkdir
  if [ -f "$KEEPALIVE_PID_FILE" ]; then
    existing_pid="$(sed -n '1p' "$KEEPALIVE_PID_FILE" 2>/dev/null || true)"
    if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$KEEPALIVE_PID_FILE"
  fi

  current_mode="$(mode_value)"
  if [ "$current_mode" = "mock" ]; then
    (
      while :; do
        sleep 60
      done
    ) >/dev/null 2>&1 &
  else
    (
      while :; do
        sleep 60
        sudo -n true >/dev/null 2>&1 || exit 0
      done
    ) >/dev/null 2>&1 &
  fi
  printf '%s\n' "$!" > "$KEEPALIVE_PID_FILE"
}

stop_keepalive() {
  if [ -f "$KEEPALIVE_PID_FILE" ]; then
    keepalive_pid="$(sed -n '1p' "$KEEPALIVE_PID_FILE" 2>/dev/null || true)"
    if [ -n "$keepalive_pid" ]; then
      kill "$keepalive_pid" 2>/dev/null || true
      wait "$keepalive_pid" 2>/dev/null || true
    fi
    rm -f "$KEEPALIVE_PID_FILE"
  fi
}

release_all() {
  current_mode="$(mode_value)"
  stop_keepalive
  if [ "$current_mode" != "mock" ]; then
    sudo -k >/dev/null 2>&1 || true
    sudo -K >/dev/null 2>&1 || true
  fi
  rm -f "$SESSION_FILE" "$MODE_FILE"
  rmdir "$STATE_DIR" 2>/dev/null || true
}

run_command() {
  [ "$#" -gt 0 ] || exit 1
  current_mode="$(mode_value)"

  if [ "$current_mode" = "mock" ]; then
    "$@"
    return "$?"
  fi

  if is_active; then
    sudo -n "$@"
    return "$?"
  fi

  "$@"
}

COMMAND="${1:-}"
[ -n "$COMMAND" ] || {
  usage >&2
  exit 1
}
shift || true

case "$COMMAND" in
  acquire)
    if [ "${SDMON_SUDO_MODE:-system}" = "mock" ]; then
      acquire_mock
    else
      acquire_system || exit 1
    fi
    ;;
  ensure)
    if ! is_active; then
      if [ "${SDMON_SUDO_MODE:-system}" = "mock" ]; then
        acquire_mock
      else
        acquire_system || exit 1
      fi
    fi
    ;;
  status)
    if is_active; then
      printf 'active\n'
    else
      printf 'inactive\n'
    fi
    ;;
  run)
    run_command "$@"
    ;;
  start-keepalive)
    start_keepalive
    ;;
  stop-keepalive)
    stop_keepalive
    ;;
  release)
    release_all
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
