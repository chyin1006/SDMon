#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
. "$SCRIPT_DIR/event_schema.conf"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/event_types.conf"

usage() {
  cat <<'USAGE'
Usage:
  event_writer.sh --output FILE KEY=VALUE [KEY=VALUE ...]

Writes one SDMon V2 Normalized Event JSON object to FILE as JSONL.
USAGE
}

die() {
  printf 'event_writer: %s\n' "$1" >&2
  exit 1
}

is_known_field() {
  local candidate="$1"
  local field
  for field in $EVENT_FIELDS; do
    if [[ "$field" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

is_valid_category() {
  local candidate="$1"
  local category
  for category in $EVENT_CATEGORIES; do
    if [[ "$category" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
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

get_value() {
  local key="$1"
  local assignment
  for assignment in "${EVENT_ASSIGNMENTS[@]}"; do
    if [[ "$assignment" == "$key="* ]]; then
      printf '%s' "${assignment#*=}"
      return 0
    fi
  done
  return 0
}

OUTPUT_FILE=""
EVENT_ASSIGNMENTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      shift
      [[ $# -gt 0 ]] || die "--output requires a file path"
      OUTPUT_FILE="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *=*)
      key="${1%%=*}"
      [[ "$key" =~ ^[A-Z0-9_]+$ ]] || die "invalid field name: $key"
      is_known_field "$key" || die "unknown field: $key"
      EVENT_ASSIGNMENTS+=("$1")
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
  shift
done

[[ -n "$OUTPUT_FILE" ]] || die "missing --output FILE"

for required in $EVENT_REQUIRED_FIELDS; do
  value="$(get_value "$required")"
  [[ -n "$value" ]] || die "missing required field: $required"
done

category_value="$(get_value "EVENT_CATEGORY")"
is_valid_category "$category_value" || die "invalid EVENT_CATEGORY: $category_value"

output_dir="$(dirname "$OUTPUT_FILE")"
mkdir -p "$output_dir" || die "cannot create output directory: $output_dir"

json="{"
separator=""

for field in $EVENT_FIELDS; do
  value="$(get_value "$field")"
  escaped_value="$(json_escape "$value")"
  json="${json}${separator}\"${field}\":\"${escaped_value}\""
  separator=","
done

json="${json}}"
printf '%s\n' "$json" >> "$OUTPUT_FILE" || die "cannot write event: $OUTPUT_FILE"
