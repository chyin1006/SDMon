#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_TEXT="SDMon V2 RC1"
SUDO_MANAGER="$SCRIPT_DIR/runtime/sudo_manager.sh"

usage() {
  cat <<'USAGE'
Usage:
  ./sdmon-v2.sh
  ./sdmon-v2.sh run [--output DIR] [--no-open]
  ./sdmon-v2.sh version
  ./sdmon-v2.sh help
USAGE
}

die() {
  printf 'sdmon-v2: %s\n' "$1" >&2
  exit 1
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

is_temp_path() {
  path_value="$1"
  tmp_root="${TMPDIR:-/tmp}"
  case "$path_value" in
    /tmp/*|/private/tmp/*|/var/folders/*|/private/var/folders/*|"$tmp_root"/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

maybe_open_report() {
  report_path="$1"
  output_was_explicit="$2"
  no_open="$3"

  [ "$no_open" -eq 0 ] || return 0
  [ "${SDMON_NO_OPEN:-0}" != "1" ] || return 0
  [ -z "${CI:-}" ] || return 0
  [ "$output_was_explicit" -eq 0 ] || return 0
  is_temp_path "$report_path" && return 0

  if [ ! -f "$report_path" ]; then
    error_exit "Auto Open HTML Report" "output/report.html was not created" "Check the scan output above and rerun ./sdmon-v2.sh."
  fi

  if ! command -v open >/dev/null 2>&1; then
    error_exit "Auto Open HTML Report" "macOS open command was not found" "Open output/report.html manually."
  fi

  open "$report_path" || error_exit "Auto Open HTML Report" "failed to open output/report.html" "Open output/report.html manually."
  return 10
}

release_privilege() {
  if [ -f "$SUDO_MANAGER" ]; then
    bash "$SUDO_MANAGER" release >/dev/null 2>&1 || true
  fi
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

print_banner() {
  printf '===================================\n'
  printf 'SDMon Security Scan\n'
  printf '===================================\n\n'
}

print_privilege_intro() {
  printf '部分安全检查需要管理员权限。\n'
  printf '请输入一次管理员密码。\n'
  printf '本次扫描期间不会再次询问。\n\n'
  printf '=====================================\n\n'
}

print_summary() {
  report_json_path="$1"
  html_path="$2"
  pdf_path="$3"
  json_path="$4"
  csv_path="$5"
  summary_path="$6"
  zip_path="$7"
  browser_opened="$8"

  if [ ! -f "$report_json_path" ]; then
    error_exit "Summary" "report.json was not created" "Check the scan output above and rerun ./sdmon-v2.sh."
  fi

  report_json="$(sed -n '1p' "$report_json_path")"
  security_score="$(json_get "$report_json" "SECURITY_SCORE")"
  risk="$(json_get "$report_json" "OVERALL_RISK")"
  rules_matched="$(json_get "$report_json" "RULES_MATCHED")"
  scan_time="$(json_get "$report_json" "SCAN_TIME")"

  printf '===================================\n\n'
  printf 'Security Score : %s\n' "${security_score:-0}"
  printf 'Overall Risk   : %s\n' "${risk:-Unknown}"
  printf 'Matched Rules  : %s\n' "${rules_matched:-0}"
  printf 'Scan Time      : %s\n\n' "${scan_time:-unknown}"
  printf 'Reports\n\n'
  printf 'HTML    : %s\n' "$html_path"
  printf 'PDF     : %s\n' "$pdf_path"
  printf 'CSV     : %s\n' "$csv_path"
  printf 'JSON    : %s\n' "$json_path"
  printf 'Summary : %s\n' "$summary_path"
  printf 'ZIP     : %s\n\n' "$zip_path"
  if [ "$browser_opened" -eq 1 ]; then
    printf 'Opening report...\n'
    printf 'Done\n'
  else
    printf 'Opening report...\n'
    printf 'Skipped\n'
  fi
  printf '===================================\n'
}

COMMAND="${1:-run}"
if [ "$#" -gt 0 ]; then
  shift
fi

case "$COMMAND" in
  run)
    OUTPUT_DIR=""
    OUTPUT_WAS_EXPLICIT=0
    NO_OPEN=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --output)
          [ "$#" -ge 2 ] || die "--output requires a directory"
          OUTPUT_DIR="$2"
          OUTPUT_WAS_EXPLICIT=1
          shift 2
          ;;
        --no-open)
          NO_OPEN=1
          shift
          ;;
        --help|-h)
          usage
          exit 0
          ;;
        *)
          die "unknown run argument: $1"
          ;;
      esac
    done

    print_banner
    print_privilege_intro
    printf 'Checking administrator privilege...\n'
    if ! bash "$SUDO_MANAGER" acquire; then
      printf 'Administrator privilege required.\n'
      printf 'Scan cancelled.\n' >&2
      exit 1
    fi
    printf 'Administrator privilege acquired.\n'
    bash "$SUDO_MANAGER" start-keepalive || error_exit "Administrator Privilege" "failed to start sudo keepalive" "Retry the scan from an interactive terminal."

    if [ -n "$OUTPUT_DIR" ]; then
      SDMON_POLISHED_OUTPUT=1 SDMON_SUDO_EXTERNAL=1 bash "$SCRIPT_DIR/v2_alpha.sh" "$OUTPUT_DIR" || {
        release_privilege
        exit 1
      }
      REPORT_BASE="$OUTPUT_DIR"
      SUMMARY_HTML="$OUTPUT_DIR/report.html"
      SUMMARY_PDF="$OUTPUT_DIR/report.pdf"
      SUMMARY_JSON="$OUTPUT_DIR/report.json"
      SUMMARY_CSV="$OUTPUT_DIR/report.csv"
      SUMMARY_TXT="$OUTPUT_DIR/summary.txt"
      SUMMARY_ZIP="$OUTPUT_DIR/report.zip"
    else
      SDMON_POLISHED_OUTPUT=1 SDMON_SUDO_EXTERNAL=1 bash "$SCRIPT_DIR/v2_alpha.sh" || {
        release_privilege
        exit 1
      }
      REPORT_BASE="$SCRIPT_DIR/output"
      SUMMARY_HTML="output/report.html"
      SUMMARY_PDF="output/report.pdf"
      SUMMARY_JSON="output/report.json"
      SUMMARY_CSV="output/report.csv"
      SUMMARY_TXT="output/summary.txt"
      SUMMARY_ZIP="output/report.zip"
    fi

    OPENED_BROWSER=0
    if maybe_open_report "$SCRIPT_DIR/output/report.html" "$OUTPUT_WAS_EXPLICIT" "$NO_OPEN"; then
      OPENED_BROWSER=0
    else
      open_status="$?"
      if [ "$open_status" -eq 10 ]; then
        OPENED_BROWSER=1
      else
        release_privilege
        exit "$open_status"
      fi
    fi
    print_summary "$REPORT_BASE/report.json" "$SUMMARY_HTML" "$SUMMARY_PDF" "$SUMMARY_JSON" "$SUMMARY_CSV" "$SUMMARY_TXT" "$SUMMARY_ZIP" "$OPENED_BROWSER"
    release_privilege
    printf 'Administrator privilege released.\n'
    ;;
  version)
    [ "$#" -eq 0 ] || die "version does not accept arguments"
    printf '%s\n' "$VERSION_TEXT"
    ;;
  help|--help|-h)
    [ "$#" -eq 0 ] || die "help does not accept arguments"
    usage
    ;;
  *)
    die "unknown command: $COMMAND"
    ;;
esac
