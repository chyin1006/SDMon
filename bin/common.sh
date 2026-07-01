#!/usr/bin/env bash

# Shared helpers for SDMon V1.1. This file is sourced by the other scripts.

SDMON_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDMON_ROOT="$(cd "$SDMON_COMMON_DIR/.." && pwd)"
SDMON_CONFIG="$SDMON_ROOT/config.conf"

if [ ! -f "$SDMON_CONFIG" ]; then
  echo "Missing config: $SDMON_CONFIG" >&2
  exit 1
fi

. "$SDMON_CONFIG"

STATE_DIR="$OUTPUT_DIR/.state"
PID_FILE="$STATE_DIR/sdmon.pid"
CHILD_PIDS_FILE="$STATE_DIR/child_pids"
CURRENT_RUN_FILE="$STATE_DIR/current_run"

sdmon_mkdirs() {
  mkdir -p "$OUTPUT_DIR" "$STATE_DIR"
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

log_line() {
  printf "[%s] %s\n" "$(timestamp)" "$*"
}

die() {
  log_line "ERROR: $*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

ensure_command() {
  command_exists "$1" || die "Required macOS command not found: $1"
}

require_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  log_line "Requesting sudo for read-only tcpdump/lsof/fs_usage collection..."
  sudo -v || die "sudo authentication failed"
}

pid_is_running() {
  [ -n "${1:-}" ] && kill -0 "$1" >/dev/null 2>&1
}

active_monitor_pid() {
  if [ -f "$PID_FILE" ]; then
    sed -n '1p' "$PID_FILE"
  fi
}

monitor_is_running() {
  pid_is_running "$(active_monitor_pid)"
}

create_run_dir() {
  sdmon_mkdirs
  RUN_DIR="$OUTPUT_DIR/run_$(date "+%Y%m%d_%H%M%S")"
  mkdir -p "$RUN_DIR"
  printf "%s\n" "$RUN_DIR" > "$CURRENT_RUN_FILE"
  : > "$CHILD_PIDS_FILE"
  export RUN_DIR
}

current_run_dir() {
  if [ -f "$CURRENT_RUN_FILE" ]; then
    sed -n '1p' "$CURRENT_RUN_FILE"
  fi
}

save_monitor_pid() {
  sdmon_mkdirs
  printf "%s\n" "$1" > "$PID_FILE"
}

add_child_pid() {
  printf "%s %s\n" "$1" "$2" >> "$CHILD_PIDS_FILE"
}

clear_state() {
  rm -f "$PID_FILE" "$CHILD_PIDS_FILE" "$CURRENT_RUN_FILE"
}

route_interface_for_target() {
  if [ "${CAPTURE_INTERFACE:-auto}" != "auto" ]; then
    printf "%s\n" "$CAPTURE_INTERFACE"
    return 0
  fi

  route -n get "$TARGET_IP" 2>/dev/null | awk '/interface:/{print $2; exit}'
}

latest_run_dir() {
  find "$OUTPUT_DIR" -maxdepth 1 -type d -name 'run_*' 2>/dev/null | sort | tail -1
}

script_path() {
  printf "%s/bin/%s\n" "$SDMON_ROOT" "$1"
}
