#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${1:-$SCRIPT_DIR/output}"
START_TIME="$(date +%s)"
SUDO_MANAGER="$SCRIPT_DIR/runtime/sudo_manager.sh"
PRIVILEGE_EXTERNAL="${SDMON_SUDO_EXTERNAL:-0}"
PRIVILEGE_MANAGED="0"

EVENTS_DIR="$RUN_DIR/events"
RUNTIME_DIR="$RUN_DIR/runtime"
ANALYSIS_DIR="$RUN_DIR/analysis"
REPORTS_DIR="$RUN_DIR/reports"

EVENT_FILE="$EVENTS_DIR/all_events.jsonl"
SENSOR_STATUS_FILE="$EVENTS_DIR/sensor_status.jsonl"
RULE_RESULT_FILE="$RUNTIME_DIR/rule_results.jsonl"
ANALYSIS_FILE="$ANALYSIS_DIR/analysis.json"
FINAL_HTML="$RUN_DIR/report.html"
FINAL_PDF="$RUN_DIR/report.pdf"
FINAL_JSON="$RUN_DIR/report.json"
FINAL_CSV="$RUN_DIR/report.csv"
FINAL_ZIP="$RUN_DIR/report.zip"
SUMMARY_FILE="$RUN_DIR/summary.txt"
TIMELINE_FILE="$RUN_DIR/timeline.json"
EVENTS_JSON_FILE="$RUN_DIR/events.json"
CURRENT_STEP="startup"
POLISHED_OUTPUT="${SDMON_POLISHED_OUTPUT:-0}"
POLISHED_STEP_OPEN="0"

cleanup_privilege() {
  if [ "$PRIVILEGE_MANAGED" = "1" ] && [ -f "$SUDO_MANAGER" ]; then
    bash "$SUDO_MANAGER" release >/dev/null 2>&1 || true
  fi
}

trap cleanup_privilege EXIT

progress() {
  percent="$1"
  message="$2"

  if [ "$POLISHED_OUTPUT" = "1" ]; then
    case "$message" in
      "System") step_label="[1/8] System" ;;
      "Persistence") step_label="[2/8] Persistence" ;;
      "Network") step_label="[3/8] Network" ;;
      "Browser") step_label="[4/8] Browser" ;;
      "AI Agent") step_label="[5/8] AI Agent" ;;
      "Credential") step_label="[6/8] Credential" ;;
      "Rule Engine") step_label="[7/8] Rule Engine" ;;
      "Report") step_label="[8/8] Report" ;;
      "Completed.")
        if [ "$POLISHED_STEP_OPEN" = "1" ]; then
          printf '✔ Done\n\n'
          POLISHED_STEP_OPEN="0"
        fi
        return 0
        ;;
      *)
        return 0
        ;;
    esac

    if [ "$POLISHED_STEP_OPEN" = "1" ]; then
      printf '✔ Done\n\n'
    fi
    printf '%s\n' "$step_label"
    POLISHED_STEP_OPEN="1"
    return 0
  fi

  printf '[%3s%% ] %s\n' "$percent" "$message"
}

error_exit() {
  step="$1"
  reason="$2"
  suggestion="$3"
  {
    printf 'ERROR\n'
    printf 'Step: %s\n' "$step"
    printf 'Reason: %s\n' "$reason"
    printf 'Suggestion: %s\n' "$suggestion"
  } >&2
  exit 1
}

run_stage() {
  stage_name="$1"
  suggestion="$2"
  shift
  shift

  CURRENT_STEP="$stage_name"
  "$@" || error_exit "$stage_name" "command failed: $*" "$suggestion"
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

count_matches() {
  pattern="$1"
  file="$2"
  if [ -f "$file" ]; then
    count="$(grep -c "$pattern" "$file" 2>/dev/null || true)"
    [ -n "$count" ] || count="0"
    printf '%s\n' "$count"
  else
    printf '0\n'
  fi
}

count_rule_matches() {
  if [ -f "$RULE_RESULT_FILE" ]; then
    grep '"MATCH":"true"' "$RULE_RESULT_FILE" 2>/dev/null | grep -v '"RULE_ID":"no_rule_match"' | wc -l | tr -d ' '
  else
    printf '0'
  fi
}

count_risk_matches() {
  severity="$1"
  if [ -f "$RULE_RESULT_FILE" ]; then
    count="$(grep '"MATCH":"true"' "$RULE_RESULT_FILE" 2>/dev/null | grep -v '"RULE_ID":"no_rule_match"' | grep -c "\"SEVERITY\":\"$severity\"" 2>/dev/null || true)"
    [ -n "$count" ] || count="0"
    printf '%s' "$count"
  else
    printf '0'
  fi
}

write_summary_files() {
  analysis_json="$(sed -n '1p' "$ANALYSIS_FILE" 2>/dev/null || true)"
  cp "$REPORTS_DIR/summary.txt" "$SUMMARY_FILE" || error_exit "Saving output" "failed to write summary.txt" "Check output directory permissions."
  cp "$EVENT_FILE" "$EVENTS_JSON_FILE" || error_exit "Saving output" "failed to write events.json" "Check output directory permissions."
  printf '%s\n' "$analysis_json" | sed -n 's/.*"TIMELINE":\[\(.*\)\],"MATCHED_RULE".*/[\1]/p' > "$TIMELINE_FILE" || error_exit "Saving output" "failed to write timeline.json" "Check output directory permissions."
}

print_final_status() {
  end_time="$(date +%s)"
  elapsed="$((end_time - START_TIME))s"
  events_count="$(count_matches '^{' "$EVENT_FILE")"
  rules_count="$(count_rule_matches)"
  high_count="$(count_risk_matches "high")"
  medium_count="$(count_risk_matches "medium")"
  low_count="$(count_risk_matches "low")"

  printf '\n'
  printf 'Scan completed.\n'
  printf 'Events: %s\n' "$events_count"
  printf 'Rules matched: %s\n' "$rules_count"
  printf 'High Risk: %s\n' "$high_count"
  printf 'Medium Risk: %s\n' "$medium_count"
  printf 'Low Risk: %s\n' "$low_count"
  printf 'Output:\n'
  printf '%s\n' "$FINAL_HTML"
  printf '%s\n' "$FINAL_PDF"
  printf '%s\n' "$FINAL_JSON"
  printf '%s\n' "$FINAL_CSV"
  printf '%s\n' "$FINAL_ZIP"
  printf 'Elapsed Time: %s\n' "$elapsed"
}

progress "5" "System"
command -v bash >/dev/null 2>&1 || error_exit "Environment Check" "bash was not found" "Run SDMon on macOS with Bash available."
command -v sed >/dev/null 2>&1 || error_exit "Environment Check" "sed was not found" "Run SDMon on macOS with built-in command line tools available."

if [ "$PRIVILEGE_EXTERNAL" != "1" ] && [ -f "$SUDO_MANAGER" ]; then
  CURRENT_STEP="Administrator Privilege"
  bash "$SUDO_MANAGER" ensure || error_exit "Administrator Privilege" "administrator privilege required" "Run the scan from an interactive terminal and approve the single sudo request."
  bash "$SUDO_MANAGER" start-keepalive || error_exit "Administrator Privilege" "failed to start sudo keepalive" "Retry the scan from an interactive terminal."
  PRIVILEGE_MANAGED="1"
fi

progress "15" "Persistence"
if [ ! -w "$(dirname "$RUN_DIR")" ]; then
  error_exit "Permission Check" "output parent directory is not writable: $(dirname "$RUN_DIR")" "Choose a writable output directory with --output."
fi

progress "25" "Network"
mkdir -p "$EVENTS_DIR" "$RUNTIME_DIR" "$ANALYSIS_DIR" "$REPORTS_DIR" || error_exit "Environment Check" "failed to create output directories" "Check output directory permissions."

progress "35" "Browser"
progress "45" "AI Agent"
progress "55" "Credential"
run_stage "Sensor Collection" "Review sensor_status.jsonl and confirm macOS built-in tools are available." bash "$SCRIPT_DIR/sensors/macos/run_all_sensors.sh" "$EVENTS_DIR"

[ -f "$EVENT_FILE" ] || error_exit "Event Generation" "missing sensor output: $EVENT_FILE" "Review sensor output directory and rerun the scan."
[ -f "$SENSOR_STATUS_FILE" ] || error_exit "Event Generation" "missing sensor status: $SENSOR_STATUS_FILE" "Review sensor runner output and rerun the scan."

progress "70" "Rule Engine"
bash "$SCRIPT_DIR/runtime/rule_runtime.sh" --event-file "$EVENT_FILE" > "$RULE_RESULT_FILE" || error_exit "Rule Runtime" "rule runtime failed" "Check rules_v2/*.conf and event JSONL input."

if [ ! -s "$RULE_RESULT_FILE" ]; then
  printf '{"RULE_ID":"no_rule_match","MATCH":"true","SEVERITY":"info","CONFIDENCE":"50","MESSAGE":"No V2 alpha demo rule matched collected events."}\n' > "$RULE_RESULT_FILE" || error_exit "Rule Runtime" "failed to write default rule result" "Check output directory permissions."
fi

run_stage "Analyzer" "Check runtime rule results and rerun the scan." bash "$SCRIPT_DIR/analyzers/analyzer.sh" --input "$RULE_RESULT_FILE" --output "$ANALYSIS_FILE"

progress "85" "Report"
REPORT_ELAPSED_TIME="$(($(date +%s) - START_TIME))s"
run_stage "Reporter" "Check analyzer output and report template files." bash "$SCRIPT_DIR/reporters/reporter.sh" \
  --input "$ANALYSIS_FILE" \
  --output-dir "$REPORTS_DIR" \
  --events-file "$EVENT_FILE" \
  --rule-results-file "$RULE_RESULT_FILE" \
  --sensor-status-file "$SENSOR_STATUS_FILE" \
  --rules-dir "$SCRIPT_DIR/rules_v2" \
  --elapsed-time "$REPORT_ELAPSED_TIME"

[ -f "$REPORTS_DIR/report.json" ] || error_exit "Reporter" "missing report.json" "Check reporter output and rerun the scan."
[ -f "$REPORTS_DIR/report.html" ] || error_exit "Reporter" "missing report.html" "Check reporter output and rerun the scan."
[ -f "$REPORTS_DIR/report.pdf" ] || error_exit "Reporter" "missing report.pdf" "Check reporter output and rerun the scan."
[ -f "$REPORTS_DIR/report.csv" ] || error_exit "Reporter" "missing report.csv" "Check reporter output and rerun the scan."
[ -f "$REPORTS_DIR/report.zip" ] || error_exit "Reporter" "missing report.zip" "Check reporter output and rerun the scan."
[ -f "$REPORTS_DIR/summary.txt" ] || error_exit "Reporter" "missing summary.txt" "Check reporter output and rerun the scan."

progress "95" "Saving output..."
cp "$REPORTS_DIR/report.html" "$FINAL_HTML" || error_exit "Saving output" "failed to write report.html" "Check output directory permissions."
cp "$REPORTS_DIR/report.pdf" "$FINAL_PDF" || error_exit "Saving output" "failed to write report.pdf" "Check output directory permissions."
cp "$REPORTS_DIR/report.json" "$FINAL_JSON" || error_exit "Saving output" "failed to write report.json" "Check output directory permissions."
cp "$REPORTS_DIR/report.csv" "$FINAL_CSV" || error_exit "Saving output" "failed to write report.csv" "Check output directory permissions."
cp "$REPORTS_DIR/report.zip" "$FINAL_ZIP" || error_exit "Saving output" "failed to write report.zip" "Check output directory permissions."
write_summary_files

progress "100" "Completed."
if [ "$POLISHED_OUTPUT" != "1" ]; then
  print_final_status
fi
