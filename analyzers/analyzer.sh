#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT_FILE=""
OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  analyzer.sh --input FILE [--output FILE]
USAGE
}

die() {
  printf 'analyzer: %s\n' "$1" >&2
  exit 1
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
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
[[ -f "$INPUT_FILE" ]] || die "input file does not exist: $INPUT_FILE"

RULE_RESULT="$(grep '"MATCH":"true"' "$INPUT_FILE" | sed -n '1p')"
[[ -n "$RULE_RESULT" ]] || die "no matching Rule Runtime result found"

RULE_ID="$(json_get "$RULE_RESULT" "RULE_ID")"
SEVERITY="$(json_get "$RULE_RESULT" "SEVERITY")"
RAW_CONFIDENCE="$(json_get "$RULE_RESULT" "CONFIDENCE")"

RISK_SCORE="$(bash "$SCRIPT_DIR/risk_score.sh" --severity "$SEVERITY")"
CONFIDENCE="$(bash "$SCRIPT_DIR/confidence.sh" --confidence "$RAW_CONFIDENCE")"
SUMMARY="$(bash "$SCRIPT_DIR/behavior_summary.sh" --rule-result "$RULE_RESULT")"
TIMELINE="$(bash "$SCRIPT_DIR/timeline_builder.sh" --rule-result "$RULE_RESULT")"

ANALYSIS_JSON="$(printf '{"RISK_SCORE":"%s","SEVERITY":"%s","CONFIDENCE":"%s","SUMMARY":"%s","TIMELINE":[%s],"MATCHED_RULE":"%s"}\n' \
  "$(json_escape "$RISK_SCORE")" \
  "$(json_escape "$SEVERITY")" \
  "$(json_escape "$CONFIDENCE")" \
  "$(json_escape "$SUMMARY")" \
  "$TIMELINE" \
  "$(json_escape "$RULE_ID")")"

if [[ -n "$OUTPUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")" || die "failed to create output directory"
  printf '%s' "$ANALYSIS_JSON" > "$OUTPUT_FILE" || die "failed to write output"
else
  printf '%s' "$ANALYSIS_JSON"
fi
