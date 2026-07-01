#!/usr/bin/env bash

set -u

EVENT_JSON=""
RULE_RECORD=""

usage() {
  cat <<'USAGE'
Usage:
  rule_matcher.sh --event-json JSON --rule-record RECORD

Matches one Normalized Event JSON object against one rule record.
USAGE
}

die() {
  printf 'rule_matcher: %s\n' "$1" >&2
  exit 1
}

json_get() {
  local key="$1"
  local json="$2"
  printf '%s\n' "$json" | sed -n 's/.*"'"$key"'":"\([^"]*\)".*/\1/p'
}

matches_field() {
  local rule_value="$1"
  local event_value="$2"
  [[ -z "$rule_value" || "$rule_value" == "$event_value" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event-json)
      shift
      [[ $# -gt 0 ]] || die "--event-json requires JSON"
      EVENT_JSON="$1"
      ;;
    --rule-record)
      shift
      [[ $# -gt 0 ]] || die "--rule-record requires RECORD"
      RULE_RECORD="$1"
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

[[ -n "$EVENT_JSON" ]] || die "missing --event-json JSON"
[[ -n "$RULE_RECORD" ]] || die "missing --rule-record RECORD"

OLD_IFS="$IFS"
IFS='|'
set -- $RULE_RECORD
IFS="$OLD_IFS"

RULE_ID="${1:-}"
RULE_EVENT_CATEGORY="${2:-}"
RULE_PROCESS_NAME="${3:-}"
RULE_ACTION="${4:-}"
RULE_TARGET="${5:-}"
RULE_SEVERITY="${6:-info}"
RULE_CONFIDENCE="${7:-50}"
RULE_MESSAGE="${8:-}"

EVENT_CATEGORY="$(json_get "EVENT_CATEGORY" "$EVENT_JSON")"
PROCESS_NAME="$(json_get "PROCESS_NAME" "$EVENT_JSON")"
ACTION="$(json_get "ACTION" "$EVENT_JSON")"
TARGET="$(json_get "TARGET" "$EVENT_JSON")"

MATCH="false"

if matches_field "$RULE_EVENT_CATEGORY" "$EVENT_CATEGORY" &&
   matches_field "$RULE_PROCESS_NAME" "$PROCESS_NAME" &&
   matches_field "$RULE_ACTION" "$ACTION" &&
   matches_field "$RULE_TARGET" "$TARGET"; then
  MATCH="true"
fi

printf 'RULE_ID=%s\n' "$RULE_ID"
printf 'MATCH=%s\n' "$MATCH"
printf 'SEVERITY=%s\n' "$RULE_SEVERITY"
printf 'CONFIDENCE=%s\n' "$RULE_CONFIDENCE"
printf 'MESSAGE=%s\n' "$RULE_MESSAGE"
