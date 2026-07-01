#!/usr/bin/env bash

set -u

INPUT_FILE=""
OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  csv_reporter.sh --input FILE --output FILE
USAGE
}

die() {
  printf 'csv_reporter: %s\n' "$1" >&2
  exit 1
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

csv_escape() {
  printf '%s' "$1" | sed 's/"/""/g'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      shift
      [[ $# -gt 0 ]] || die "--input requires a file path"
      INPUT_FILE="$1"
      ;;
    --output)
      shift
      [[ $# -gt 0 ]] || die "--output requires a file path"
      OUTPUT_FILE="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
  shift
done

[[ -n "$INPUT_FILE" ]] || die "missing --input FILE"
[[ -n "$OUTPUT_FILE" ]] || die "missing --output FILE"
[[ -f "$INPUT_FILE" ]] || die "input file does not exist: $INPUT_FILE"

REPORT_JSON="$(sed -n '1p' "$INPUT_FILE")"

mkdir -p "$(dirname "$OUTPUT_FILE")" || die "failed to create output directory"
{
  printf 'SUMMARY_SHEET,SECURITY_SCORE,HOSTNAME,VERSION,RISK,SCAN_TIME,MATCHED_RULES,TOTAL_EVENTS,HEALTH_LEVEL,TOP_FINDINGS,RECOMMENDATIONS\n'
  printf '"Summary","%s","%s","%s","%s","%s","%s","%s","%s","%s","%s"\n' \
    "$(csv_escape "$(json_get "$REPORT_JSON" "SECURITY_SCORE")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "HOST_NAME")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "SDMON_VERSION")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "OVERALL_RISK")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "SCAN_TIME")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "RULES_MATCHED")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "TOTAL_EVENTS")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "HEALTH_LEVEL")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "TOP_FINDINGS_TEXT")")" \
    "$(csv_escape "$(json_get "$REPORT_JSON" "RECOMMENDATIONS_TEXT")")"
} > "$OUTPUT_FILE" || die "failed to write CSV report"
