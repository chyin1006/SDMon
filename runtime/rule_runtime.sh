#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

EVENT_FILE=""
RULES_DIR="$REPO_ROOT/rules_v2"

usage() {
  cat <<'USAGE'
Usage:
  rule_runtime.sh --event-file FILE [--rules-dir DIR]

Runs Rule Loader, Rule Matcher, and Rule Result for event JSONL input.
USAGE
}

die() {
  printf 'rule_runtime: %s\n' "$1" >&2
  exit 1
}

json_get() {
  local key="$1"
  local json="$2"
  printf '%s\n' "$json" | sed -n 's/.*"'"$key"'":"\([^"]*\)".*/\1/p'
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

matches_field() {
  local rule_value="$1"
  local event_value="$2"
  [[ -z "$rule_value" || "$rule_value" == "$event_value" ]]
}

emit_rule_result() {
  local rule_id="$1"
  local severity="$2"
  local confidence="$3"
  local message="$4"

  printf '{"RULE_ID":"%s","MATCH":"true","SEVERITY":"%s","CONFIDENCE":"%s","MESSAGE":"%s"}\n' \
    "$(json_escape "$rule_id")" \
    "$(json_escape "$severity")" \
    "$(json_escape "$confidence")" \
    "$(json_escape "$message")"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --event-file)
      shift
      [[ $# -gt 0 ]] || die "--event-file requires FILE"
      EVENT_FILE="$1"
      ;;
    --rules-dir)
      shift
      [[ $# -gt 0 ]] || die "--rules-dir requires DIR"
      RULES_DIR="$1"
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

[[ -n "$EVENT_FILE" ]] || die "missing --event-file FILE"
[[ -f "$EVENT_FILE" ]] || die "event file not found: $EVENT_FILE"

rules="$(bash "$SCRIPT_DIR/rule_loader.sh" --rules-dir "$RULES_DIR")"

while IFS= read -r event_json; do
  [[ -n "$event_json" ]] || continue
  EVENT_CATEGORY="$(json_get "EVENT_CATEGORY" "$event_json")"
  PROCESS_NAME="$(json_get "PROCESS_NAME" "$event_json")"
  ACTION="$(json_get "ACTION" "$event_json")"
  TARGET="$(json_get "TARGET" "$event_json")"

  while IFS= read -r rule_record; do
    [[ -n "$rule_record" ]] || continue
    OLD_IFS="$IFS"
    IFS='|'
    set -- $rule_record
    IFS="$OLD_IFS"

    RULE_ID="${1:-}"
    RULE_EVENT_CATEGORY="${2:-}"
    RULE_PROCESS_NAME="${3:-}"
    RULE_ACTION="${4:-}"
    RULE_TARGET="${5:-}"
    RULE_SEVERITY="${6:-info}"
    RULE_CONFIDENCE="${7:-50}"
    RULE_MESSAGE="${8:-}"

    if matches_field "$RULE_EVENT_CATEGORY" "$EVENT_CATEGORY" &&
       matches_field "$RULE_PROCESS_NAME" "$PROCESS_NAME" &&
       matches_field "$RULE_ACTION" "$ACTION" &&
       matches_field "$RULE_TARGET" "$TARGET"; then
      emit_rule_result "$RULE_ID" "$RULE_SEVERITY" "$RULE_CONFIDENCE" "$RULE_MESSAGE"
    fi
  done <<EOF
$rules
EOF
done < "$EVENT_FILE"
