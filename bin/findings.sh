#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/common.sh"

expand_path_pattern() {
  local pattern="$1"
  eval "printf '%s\n' $pattern"
}

write_sensitive_path_inventory() {
  local output="$1"
  local rules="$SDMON_ROOT/rules/sensitive_paths.conf"

  printf "\nSensitive path inventory\n" >> "$output"
  if [ ! -f "$rules" ]; then
    printf "%s\n" "- Missing rules file: $rules" >> "$output"
    return
  fi

  while IFS='|' read -r label pattern; do
    [ -n "${label:-}" ] || continue
    [ "${label#\#}" = "$label" ] || continue

    local found="no"
    local expanded
    expanded="$(expand_path_pattern "$pattern")"

    while IFS= read -r path; do
      [ -n "$path" ] || continue
      if [ -e "$path" ]; then
        printf "%s\n" "- FOUND: $label -> $path" >> "$output"
        found="yes"
      fi
    done <<EOF
$expanded
EOF

    if [ "$found" = "no" ]; then
      printf "%s\n" "- not found: $label -> $pattern" >> "$output"
    fi
  done < "$rules"
}

append_log_matches() {
  local title="$1"
  local file="$2"
  local pattern="$3"
  local output="$4"

  printf "\n%s\n" "$title" >> "$output"
  if [ -f "$file" ] && grep -E "$pattern" "$file" >/dev/null 2>&1; then
    grep -E "$pattern" "$file" | tail -40 >> "$output"
  else
    printf "%s\n" "- No matches found." >> "$output"
  fi
}

main() {
  local run_dir="${1:-$(current_run_dir)}"
  [ -n "$run_dir" ] || die "No run directory supplied"
  [ -d "$run_dir" ] || die "Run directory not found: $run_dir"

  local output="$run_dir/findings.txt"
  {
    printf "SDMon V1.1 Findings\n"
    printf "Generated: %s\n" "$(timestamp)"
    printf "Run directory: %s\n" "$run_dir"
  } > "$output"

  append_log_matches "Target process observations" "$run_dir/process.log" "$PROCESS_1|$PROCESS_2" "$output"
  append_log_matches "Target network observations" "$run_dir/network.log" "$PROCESS_1|$PROCESS_2|$TARGET_IP|:$TARGET_PORT" "$output"
  append_log_matches "Launchctl observations" "$run_dir/launchctl.log" "state =|pid =|program =|path =|last exit code|could not find|No such|service" "$output"
  append_log_matches "Sensitive fs_usage observations" "$run_dir/fs_usage.log" "Chrome|History|Login Data|Safari|\\.ssh|Keychain|Documents|Desktop|Downloads|WeChat|Foxmail|Photos\\.sqlite" "$output"

  write_sensitive_path_inventory "$output"
  log_line "Wrote $output"
}

main "$@"
