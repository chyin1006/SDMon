#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_reporter_test_$$"
EVENT_FILE="$TMP_DIR/events/process_events.jsonl"
RULE_RESULT_FILE="$TMP_DIR/rule_result.jsonl"
ANALYSIS_FILE="$TMP_DIR/analysis.json"
REPORT_DIR="$TMP_DIR/reports"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
export SDMON_NO_OPEN=1

bash -n "$REPO_ROOT"/reporters/*.sh
bash -n "$REPO_ROOT/tests/test_reporter.sh"

bash "$REPO_ROOT/producers/process_producer.sh" --output "$EVENT_FILE"
bash "$REPO_ROOT/runtime/rule_runtime.sh" --event-file "$EVENT_FILE" --rules-dir "$REPO_ROOT/rules_v2" > "$RULE_RESULT_FILE"
bash "$REPO_ROOT/analyzers/analyzer.sh" --input "$RULE_RESULT_FILE" --output "$ANALYSIS_FILE"
bash "$REPO_ROOT/reporters/reporter.sh" --input "$ANALYSIS_FILE" --output-dir "$REPORT_DIR"

[[ -f "$REPORT_DIR/report.json" ]] || {
  printf 'FAIL: report.json not generated\n' >&2
  exit 1
}

[[ -f "$REPORT_DIR/report.html" ]] || {
  printf 'FAIL: report.html not generated\n' >&2
  exit 1
}

[[ -f "$REPORT_DIR/report.csv" ]] || {
  printf 'FAIL: report.csv not generated\n' >&2
  exit 1
}

[[ -f "$REPORT_DIR/report.pdf" ]] || {
  printf 'FAIL: report.pdf not generated\n' >&2
  exit 1
}

[[ -f "$REPORT_DIR/report.zip" ]] || {
  printf 'FAIL: report.zip not generated\n' >&2
  exit 1
}

grep -q 'SDMon Security Assessment' "$REPORT_DIR/report.html" || {
  printf 'FAIL: report.html missing title\n' >&2
  exit 1
}

grep -q 'SUMMARY_SHEET' "$REPORT_DIR/report.csv" || {
  printf 'FAIL: report.csv missing summary header\n' >&2
  exit 1
}

grep -q 'Executive Summary' "$REPORT_DIR/report.html" || {
  printf 'FAIL: report.html missing executive summary\n' >&2
  exit 1
}

grep -q 'DEVICE_HEALTH' "$REPORT_DIR/report.json" || {
  printf 'FAIL: report.json missing DEVICE_HEALTH\n' >&2
  exit 1
}

grep -q 'SECURITY_SCORE' "$REPORT_DIR/report.json" || {
  printf 'FAIL: report.json missing SECURITY_SCORE\n' >&2
  exit 1
}

grep -q 'Credentials and Secrets' "$REPORT_DIR/report.html" || {
  printf 'FAIL: report.html missing credential section\n' >&2
  exit 1
}

if grep '{{' "$REPORT_DIR/report.html" >/dev/null 2>&1; then
  printf 'FAIL: report.html still contains template placeholders\n' >&2
  exit 1
fi

grep -q 'CREDENTIAL_EVENTS' "$REPORT_DIR/report.json" || {
  printf 'FAIL: report.json missing CREDENTIAL_EVENTS\n' >&2
  exit 1
}

grep -q 'TOP_FINDINGS_HTML' "$REPORT_DIR/report.json" || {
  printf 'FAIL: report.json missing TOP_FINDINGS_HTML\n' >&2
  exit 1
}

grep -q 'TOTAL_CHECKS' "$REPORT_DIR/report.json" || {
  printf 'FAIL: report.json missing TOTAL_CHECKS\n' >&2
  exit 1
}

printf 'PASS\n'
