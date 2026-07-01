#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${1:-/tmp/sdmon-v2-alpha/events}"
PROFILE_ID="${SDMON_PROFILE_ID:-default}"
ALL_EVENTS_FILE="$OUTPUT_DIR/all_events.jsonl"
STATUS_FILE="$OUTPUT_DIR/sensor_status.jsonl"

json_escape() {
  value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\t'/\\t}
  value=${value//$'\r'/\\r}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

write_status() {
  sensor_name="$1"
  status_value="$2"
  exit_code="$3"
  message="$4"
  timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  printf '{"TIMESTAMP":"%s","SENSOR":"%s","STATUS":"%s","EXIT_CODE":"%s","MESSAGE":"%s"}\n' \
    "$(json_escape "$timestamp")" \
    "$(json_escape "$sensor_name")" \
    "$(json_escape "$status_value")" \
    "$(json_escape "$exit_code")" \
    "$(json_escape "$message")" >> "$STATUS_FILE"
}

run_sensor() {
  sensor_name="$1"
  sensor_limit="${2:-}"
  sensor_script="$SCRIPT_DIR/${sensor_name}_sensor.sh"

  if [ ! -f "$sensor_script" ]; then
    write_status "$sensor_name" "failed" "127" "sensor script not found"
    return 0
  fi

  error_log="$OUTPUT_DIR/${sensor_name}_sensor.err"
  if [ -n "$sensor_limit" ]; then
    bash "$sensor_script" --output "$ALL_EVENTS_FILE" --profile "$PROFILE_ID" --limit "$sensor_limit" 2>"$error_log"
  else
    bash "$sensor_script" --output "$ALL_EVENTS_FILE" --profile "$PROFILE_ID" 2>"$error_log"
  fi
  run_exit="$?"

  if [ "$run_exit" -eq 0 ]; then
    write_status "$sensor_name" "success" "0" "completed"
  else
    exit_code="$run_exit"
    message="$(sed -n '1p' "$error_log" 2>/dev/null || true)"
    [ -n "$message" ] || message="sensor failed"
    write_status "$sensor_name" "failed" "$exit_code" "$message"
  fi
}

mkdir -p "$OUTPUT_DIR" || {
  printf 'run_all_sensors: cannot create output directory: %s\n' "$OUTPUT_DIR" >&2
  exit 1
}

: > "$ALL_EVENTS_FILE"
: > "$STATUS_FILE"

run_sensor "process" "25"
run_sensor "file" "10"
run_sensor "launchd" "25"
run_sensor "ssh_authorized_keys"
run_sensor "network" "25"
run_sensor "system"
run_sensor "permission"
run_sensor "enterprise_security"
run_sensor "credential" "40"
