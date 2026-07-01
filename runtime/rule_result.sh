#!/usr/bin/env bash

set -u

RULE_ID=""
MATCH="false"
SEVERITY="info"
CONFIDENCE="0"
MESSAGE=""

usage() {
  cat <<'USAGE'
Usage:
  rule_result.sh --rule-id ID --match true|false --severity LEVEL --confidence N --message TEXT

Prints one Rule Result JSON object.
USAGE
}

die() {
  printf 'rule_result: %s\n' "$1" >&2
  exit 1
}

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\t'/\\t}
  value=${value//$'\r'/\\r}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rule-id)
      shift
      [[ $# -gt 0 ]] || die "--rule-id requires ID"
      RULE_ID="$1"
      ;;
    --match)
      shift
      [[ $# -gt 0 ]] || die "--match requires true or false"
      MATCH="$1"
      ;;
    --severity)
      shift
      [[ $# -gt 0 ]] || die "--severity requires LEVEL"
      SEVERITY="$1"
      ;;
    --confidence)
      shift
      [[ $# -gt 0 ]] || die "--confidence requires N"
      CONFIDENCE="$1"
      ;;
    --message)
      shift
      [[ $# -gt 0 ]] || die "--message requires TEXT"
      MESSAGE="$1"
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

[[ -n "$RULE_ID" ]] || die "missing --rule-id ID"

printf '{"RULE_ID":"%s","MATCH":"%s","SEVERITY":"%s","CONFIDENCE":"%s","MESSAGE":"%s"}\n' \
  "$(json_escape "$RULE_ID")" \
  "$(json_escape "$MATCH")" \
  "$(json_escape "$SEVERITY")" \
  "$(json_escape "$CONFIDENCE")" \
  "$(json_escape "$MESSAGE")"
