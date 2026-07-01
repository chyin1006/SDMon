#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

stop_pid() {
  local name="$1"
  local pid="$2"
  local log="$3"

  if pid_is_running "$pid"; then
    log_line "Stopping SDMon $name PID $pid" | tee -a "$log"
    pkill -TERM -P "$pid" >/dev/null 2>&1 || true
    kill "$pid" >/dev/null 2>&1 || true
  fi
}

wait_for_pid_exit() {
  local pid="$1"
  local tries=0
  while pid_is_running "$pid" && [ "$tries" -lt 10 ]; do
    sleep 1
    tries=$((tries + 1))
  done
}

stop_recorded_children() {
  local log="$1"

  if [ ! -f "$CHILD_PIDS_FILE" ]; then
    return 0
  fi

  while read -r name pid; do
    [ -n "${pid:-}" ] || continue
    stop_pid "$name" "$pid" "$log"
  done < "$CHILD_PIDS_FILE"

  while read -r _ pid; do
    [ -n "${pid:-}" ] && wait_for_pid_exit "$pid"
  done < "$CHILD_PIDS_FILE"
}

make_zip() {
  local run_dir="$1"
  local parent
  local base
  parent="$(dirname "$run_dir")"
  base="$(basename "$run_dir")"

  if command_exists zip; then
    (cd "$parent" && zip -qry "$base.zip" "$base")
    log_line "Created package: $parent/$base.zip" | tee -a "$run_dir/monitor.log"
  else
    log_line "zip command not found; skipped package creation" | tee -a "$run_dir/monitor.log"
  fi
}

main() {
  sdmon_mkdirs

  local run_dir
  run_dir="$(current_run_dir)"
  [ -n "$run_dir" ] || die "No current SDMon run found"
  [ -d "$run_dir" ] || die "Run directory does not exist: $run_dir"

  local log="$run_dir/monitor.log"
  log_line "Stopping SDMon monitor" | tee -a "$log"

  stop_recorded_children "$log"

  local supervisor_pid
  supervisor_pid="$(active_monitor_pid)"
  if [ -n "$supervisor_pid" ]; then
    stop_pid "supervisor" "$supervisor_pid" "$log"
    wait_for_pid_exit "$supervisor_pid"
  fi

  bash "$(script_path summary.sh)" "$run_dir"
  bash "$(script_path findings.sh)" "$run_dir"
  make_zip "$run_dir"
  clear_state

  log_line "SDMon stopped. Reports: $run_dir/summary.txt and $run_dir/findings.txt"
}

main "$@"
