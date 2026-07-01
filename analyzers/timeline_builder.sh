#!/usr/bin/env bash

set -u

RULE_RESULT=""

usage() {
  cat <<'USAGE'
Usage:
  timeline_builder.sh --rule-result JSON
USAGE
}

die() {
  printf 'timeline_builder: %s\n' "$1" >&2
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
SEVERITY="$(json_get "$RULE_RESULT" "SEVERITY")"
MESSAGE="$(json_get "$RULE_RESULT" "MESSAGE")"

printf '{"RULE_ID":"%s","SEVERITY":"%s","MESSAGE":"%s"}\n' \
  "$(json_escape "$RULE_ID")" \
  "$(json_escape "$SEVERITY")" \
  "$(json_escape "$MESSAGE")"
