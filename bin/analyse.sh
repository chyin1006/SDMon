#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

main() {
  sdmon_mkdirs

  local run_dir="${1:-}"
  if [ -z "$run_dir" ]; then
    run_dir="$(current_run_dir)"
  fi
  if [ -z "$run_dir" ]; then
    run_dir="$(latest_run_dir)"
  fi

  [ -n "$run_dir" ] || die "No SDMon run directory found under $OUTPUT_DIR"
  [ -d "$run_dir" ] || die "Run directory not found: $run_dir"

  bash "$(script_path summary.sh)" "$run_dir"
  bash "$(script_path findings.sh)" "$run_dir"
  log_line "Analysis complete for $run_dir"
}

main "$@"
