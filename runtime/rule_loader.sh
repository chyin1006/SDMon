#!/usr/bin/env bash

set -u

RULES_DIR=""

usage() {
  cat <<'USAGE'
Usage:
  rule_loader.sh --rules-dir DIR

Loads rules_v2/*.conf and prints pipe-delimited rule records.
USAGE
}

die() {
  printf 'rule_loader: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rules-dir)
      shift
      [[ $# -gt 0 ]] || die "--rules-dir requires a directory"
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

[[ -n "$RULES_DIR" ]] || die "missing --rules-dir DIR"
[[ -d "$RULES_DIR" ]] || die "rules directory not found: $RULES_DIR"

found="false"

for rule_file in "$RULES_DIR"/*.conf; do
  [[ -f "$rule_file" ]] || continue
  found="true"
  (
    RULE_ID=""
    RULE_EVENT_CATEGORY=""
    RULE_PROCESS_NAME=""
    RULE_ACTION=""
    RULE_TARGET=""
    RULE_SEVERITY="info"
    RULE_CONFIDENCE="50"
    RULE_MESSAGE=""

    # shellcheck source=/dev/null
    . "$rule_file"

    [[ -n "$RULE_ID" ]] || exit 0
    printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
      "$RULE_ID" \
      "$RULE_EVENT_CATEGORY" \
      "$RULE_PROCESS_NAME" \
      "$RULE_ACTION" \
      "$RULE_TARGET" \
      "$RULE_SEVERITY" \
      "$RULE_CONFIDENCE" \
      "$RULE_MESSAGE"
  )
done

[[ "$found" == "true" ]] || die "no rule files found in: $RULES_DIR"
