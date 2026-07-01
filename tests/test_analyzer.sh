#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_analyzer_test_$$"
EVENT_FILE="$TMP_DIR/events/process_events.jsonl"
RULE_RESULT_FILE="$TMP_DIR/rule_result.jsonl"
ANALYSIS_FILE="$TMP_DIR/analysis.json"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

bash -n "$REPO_ROOT"/analyzers/*.sh
bash -n "$REPO_ROOT/tests/test_analyzer.sh"

bash "$REPO_ROOT/producers/process_producer.sh" --output "$EVENT_FILE"
bash "$REPO_ROOT/runtime/rule_runtime.sh" --event-file "$EVENT_FILE" --rules-dir "$REPO_ROOT/rules_v2" > "$RULE_RESULT_FILE"
bash "$REPO_ROOT/analyzers/analyzer.sh" --input "$RULE_RESULT_FILE" --output "$ANALYSIS_FILE"

grep -q '"SUMMARY":"' "$ANALYSIS_FILE" || {
  printf 'FAIL: SUMMARY not found\n' >&2
  exit 1
}

grep -q '"TIMELINE":' "$ANALYSIS_FILE" || {
  printf 'FAIL: TIMELINE not found\n' >&2
  exit 1
}

grep -q '"RISK_SCORE":"' "$ANALYSIS_FILE" || {
  printf 'FAIL: RISK_SCORE not found\n' >&2
  exit 1
}

grep -q '"CONFIDENCE":"' "$ANALYSIS_FILE" || {
  printf 'FAIL: CONFIDENCE not found\n' >&2
  exit 1
}

printf 'PASS\n'
