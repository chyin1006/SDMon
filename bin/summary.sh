#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

count_lines() {
  if [ -f "$1" ]; then
    wc -l < "$1" | tr -d ' '
  else
    printf "0"
  fi
}

file_size() {
  if [ -f "$1" ]; then
    ls -lh "$1" | awk '{print $5}'
  else
    printf "missing"
  fi
}

write_matching_tail() {
  local file="$1"
  local pattern="$2"
  local fallback="$3"

  if [ -f "$file" ] && grep -E "$pattern" "$file" >/dev/null 2>&1; then
    grep -E "$pattern" "$file" | tail -20
  else
    printf "%s\n" "$fallback"
  fi
}

main() {
  local run_dir="${1:-$(current_run_dir)}"
  [ -n "$run_dir" ] || die "No run directory supplied"
  [ -d "$run_dir" ] || die "Run directory not found: $run_dir"

  local summary="$run_dir/summary.txt"
  {
    printf "SDMon V1.1 Summary\n"
    printf "Generated: %s\n" "$(timestamp)"
    printf "Run directory: %s\n" "$run_dir"
    printf "\n"
    printf "Targets\n"
    printf "%s\n" "- Processes: $PROCESS_1, $PROCESS_2"
    printf "%s\n" "- Paths: $TARGET_PATH_1, $TARGET_PATH_2"
    printf "%s\n" "- Launch labels: $LAUNCH_LABEL_1, $LAUNCH_LABEL_2"
    printf "%s\n" "- Server: $TARGET_IP:$TARGET_PORT"
    printf "\n"
    printf "Collected files\n"
    printf "%s\n" "- traffic.pcap: $(file_size "$run_dir/traffic.pcap")"
    printf "%s\n" "- tcpdump.log lines: $(count_lines "$run_dir/tcpdump.log")"
    printf "%s\n" "- process.log lines: $(count_lines "$run_dir/process.log")"
    printf "%s\n" "- network.log lines: $(count_lines "$run_dir/network.log")"
    printf "%s\n" "- launchctl.log lines: $(count_lines "$run_dir/launchctl.log")"
    printf "%s\n" "- fs_usage.log lines: $(count_lines "$run_dir/fs_usage.log")"
    printf "\n"
    printf "Recent process evidence\n"
    write_matching_tail "$run_dir/process.log" "$PROCESS_1|$PROCESS_2" "No target process rows found."
    printf "\n"
    printf "Recent network evidence\n"
    write_matching_tail "$run_dir/network.log" "$PROCESS_1|$PROCESS_2|$TARGET_IP|:$TARGET_PORT" "No target network rows found."
  } > "$summary"

  log_line "Wrote $summary"
}

main "$@"
