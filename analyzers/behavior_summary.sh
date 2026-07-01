#!/usr/bin/env bash

set -u

RULE_RESULT=""

usage() {
  cat <<'USAGE'
Usage:
  behavior_summary.sh --rule-result JSON
USAGE
}

die() {
  printf 'behavior_summary: %s\n' "$1" >&2
  exit 1
}

json_get() {
  printf '%s\n' "$1" | sed -n 's/.*"'"$2"'":"\([^"]*\)".*/\1/p'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rule-result)
      shift
      [[ $# -gt 0 ]] || die "--rule-result requires JSON"
      RULE_RESULT="$1"
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

RULE_ID="$(json_get "$RULE_RESULT" "RULE_ID")"

case "$RULE_ID" in
  process*) printf 'Process matched suspicious rule.\n' ;;
  network*) printf 'Network matched suspicious rule.\n' ;;
  file*) printf 'File activity matched suspicious rule.\n' ;;
  *) printf 'Rule matched suspicious behavior.\n' ;;
esac
