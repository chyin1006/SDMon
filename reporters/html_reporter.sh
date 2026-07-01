#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_FILE=""
OUTPUT_FILE=""
TEMPLATE_FILE="$REPO_ROOT/templates/report.html"

usage() {
  cat <<'USAGE'
Usage:
  html_reporter.sh --input FILE --output FILE [--template FILE]
USAGE
}

die() {
  printf 'html_reporter: %s\n' "$1" >&2
  exit 1
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

json_unescape() {
  printf '%s\n' "$1" | awk '
    {
      gsub(/\\\\/, "\034")
      gsub(/\\"/, "\"")
      gsub(/\\t/, "\t")
      gsub(/\\r/, "")
      gsub(/\\n/, "\n")
      gsub(/\034/, "\\")
      printf "%s", $0
    }
  '
}

replace_token() {
  awk -v token="$1" -v value="$2" '
    {
      line = $0
      output = ""
      while ((pos = index(line, token)) > 0) {
        output = output substr(line, 1, pos - 1) value
        line = substr(line, pos + length(token))
      }
      print output line
    }
  '
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      [ "$#" -ge 2 ] || die "--input requires a file path"
      INPUT_FILE="$2"
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || die "--output requires a file path"
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --template)
      [ "$#" -ge 2 ] || die "--template requires a file path"
      TEMPLATE_FILE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
done

[ -n "$INPUT_FILE" ] || die "missing --input FILE"
[ -f "$INPUT_FILE" ] || die "input file does not exist: $INPUT_FILE"
[ -n "$OUTPUT_FILE" ] || die "missing --output FILE"
[ -f "$TEMPLATE_FILE" ] || die "template file does not exist: $TEMPLATE_FILE"

REPORT_JSON="$(sed -n '1p' "$INPUT_FILE")"
mkdir -p "$(dirname "$OUTPUT_FILE")" || die "failed to create output directory"

cp "$TEMPLATE_FILE" "$OUTPUT_FILE" || die "failed to seed output html"

for field in \
  TITLE SCAN_STATUS HOST_NAME CURRENT_USER SYSTEM_VERSION OS_VERSION CPU MEMORY SCAN_TIME ELAPSED_TIME SDMON_VERSION \
  SECURITY_SCORE OVERALL_HEALTH HEALTH_CLASS OVERALL_RISK TOTAL_EVENTS RULES_MATCHED AI_TOOLS CREDENTIAL_FINDINGS \
  PERSISTENCE_FINDINGS NETWORK_FINDINGS SENSITIVE_FILE_FINDINGS BROWSER_FINDINGS SUMMARY TOP_FINDINGS_HTML \
  RECOMMENDATIONS_HTML SCORE_REASONS_HTML INFO_RISK LOW_RISK MEDIUM_RISK HIGH_RISK RISK_DISTRIBUTION_INFO \
  RISK_DISTRIBUTION_LOW RISK_DISTRIBUTION_MEDIUM RISK_DISTRIBUTION_HIGH CREDENTIAL_SUMMARY CREDENTIAL_ITEMS_HTML \
  TIMELINE_NOTE TIMELINE_HTML PROCESS_EVENTS NETWORK_EVENTS LAUNCHD_EVENTS SSH_KEY_EVENTS SENSITIVE_FILE_EVENTS \
  CREDENTIAL_EVENTS RULES_LOADED RULES_EVALUATED TOTAL_CHECKS PASSED_CHECKS WARNING_CHECKS CRITICAL_CHECKS
do
  value="$(json_unescape "$(json_get "$REPORT_JSON" "$field")")"
  tmp_file="${OUTPUT_FILE}.tmp"
  replace_token "{{${field}}}" "$value" < "$OUTPUT_FILE" > "$tmp_file" || die "failed replacing ${field}"
  mv "$tmp_file" "$OUTPUT_FILE"
done

if grep '{{[A-Z_][A-Z_]*}}' "$OUTPUT_FILE" >/dev/null 2>&1; then
  die "unreplaced template token found in output html"
fi
