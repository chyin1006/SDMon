#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"

OUTPUT_FILE=""
PROFILE_ID="default"
LIMIT="0"

usage() {
  cat <<'USAGE'
Usage:
  network_sensor.sh --output FILE [--profile PROFILE_ID] [--limit N]

Collects current established TCP connections with lsof and writes network Normalized Events.
USAGE
}

die() {
  printf 'network_sensor: %s\n' "$1" >&2
  exit 1
}

is_number() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

write_network_event() {
  local event_id="$1"
  local action="$2"
  local process_name="$3"
  local pid="$4"
  local protocol="$5"
  local local_address="$6"
  local local_port="$7"
  local remote_address="$8"
  local remote_port="$9"
  local target="${10}"
  local event_type="${11:-network_connection}"
  local detail="${12:-protocol=$protocol;local=$local_address:$local_port;remote=$remote_address:$remote_port;action=$action}"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="" \
    PLATFORM="macos" \
    SENSOR_TYPE="network" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="network" \
    EVENT_TYPE="$event_type" \
    PROCESS_NAME="$process_name" \
    PID="$pid" \
    ACTION="$action" \
    TARGET="$target" \
    TARGET_TYPE="endpoint" \
    SOURCE="sensor" \
    CONFIDENCE="80" \
    TAGS="macos,network,sensor" \
    SERVICE_TYPE="" \
    PLIST_PATH="" \
    LABEL="" \
    PROTOCOL="$protocol" \
    LOCAL_ADDRESS="$local_address" \
    LOCAL_PORT="$local_port" \
    REMOTE_ADDRESS="$remote_address" \
    REMOTE_PORT="$remote_port" \
    DETAIL="$detail"
}

parse_endpoint() {
  local name_field="$1"
  local left right

  name_field="${name_field%% (*}"
  left="${name_field%%->*}"
  right="${name_field#*->}"

  if [[ "$name_field" != *"->"* ]]; then
    LOCAL_ADDRESS=""
    LOCAL_PORT=""
    REMOTE_ADDRESS=""
    REMOTE_PORT=""
    return 1
  fi

  LOCAL_PORT="${left##*:}"
  LOCAL_ADDRESS="${left%:*}"
  REMOTE_PORT="${right##*:}"
  REMOTE_ADDRESS="${right%:*}"
  return 0
}

is_suspicious_port() {
  case "$1" in
    4444|1337|31337|6667|6666|9001|12345)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_external_address() {
  case "$1" in
    ""|127.*|localhost|::1|0.0.0.0|10.*|192.168.*|169.254.*|172.16.*|172.17.*|172.18.*|172.19.*|172.20.*|172.21.*|172.22.*|172.23.*|172.24.*|172.25.*|172.26.*|172.27.*|172.28.*|172.29.*|172.30.*|172.31.*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      shift
      [[ $# -gt 0 ]] || die "--output requires a file path"
      OUTPUT_FILE="$1"
      ;;
    --profile)
      shift
      [[ $# -gt 0 ]] || die "--profile requires a value"
      PROFILE_ID="$1"
      ;;
    --limit)
      shift
      [[ $# -gt 0 ]] || die "--limit requires a number"
      LIMIT="$1"
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

[[ -n "$OUTPUT_FILE" ]] || die "missing --output FILE"
is_number "$LIMIT" || die "--limit must be a non-negative number"
[[ -f "$EVENT_WRITER" ]] || die "missing event writer: $EVENT_WRITER"

HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
count="0"
listen_count="0"
external_count="0"

if command -v lsof >/dev/null 2>&1; then
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue

    process_name="$(printf '%s\n' "$line" | awk '{print $1}')"
    pid="$(printf '%s\n' "$line" | awk '{print $2}')"
    protocol="$(printf '%s\n' "$line" | awk '{print $8}' | tr '[:upper:]' '[:lower:]')"
    name_field="$(printf '%s\n' "$line" | awk '{for (i=9; i<=NF; i++) { printf "%s%s", (i==9 ? "" : " "), $i }}')"

    count=$((count + 1))

    if [[ "$name_field" == *"(LISTEN)"* ]]; then
      endpoint="${name_field%% (*}"
      LOCAL_PORT="${endpoint##*:}"
      LOCAL_ADDRESS="${endpoint%:*}"
      REMOTE_ADDRESS=""
      REMOTE_PORT=""
      listen_count=$((listen_count + 1))
      write_network_event "network-listen-${count}" "listen" "$process_name" "$pid" "$protocol" \
        "$LOCAL_ADDRESS" "$LOCAL_PORT" "" "" "$LOCAL_ADDRESS:$LOCAL_PORT" "network_listen"
      if is_suspicious_port "$LOCAL_PORT"; then
        write_network_event "network-suspicious-listen-${count}" "suspicious_port" "$process_name" "$pid" "$protocol" \
          "$LOCAL_ADDRESS" "$LOCAL_PORT" "" "" "$LOCAL_ADDRESS:$LOCAL_PORT" "network_behavior" "listen_port=$LOCAL_PORT"
      fi
    elif parse_endpoint "$name_field"; then
      write_network_event "network-connection-${count}" "connection" "$process_name" "$pid" "$protocol" \
        "$LOCAL_ADDRESS" "$LOCAL_PORT" "$REMOTE_ADDRESS" "$REMOTE_PORT" "$REMOTE_ADDRESS:$REMOTE_PORT" "network_connection"
      if is_external_address "$REMOTE_ADDRESS"; then
        external_count=$((external_count + 1))
      fi
      if is_suspicious_port "$REMOTE_PORT"; then
        write_network_event "network-suspicious-connection-${count}" "suspicious_port" "$process_name" "$pid" "$protocol" \
          "$LOCAL_ADDRESS" "$LOCAL_PORT" "$REMOTE_ADDRESS" "$REMOTE_PORT" "$REMOTE_ADDRESS:$REMOTE_PORT" "network_behavior" "remote_port=$REMOTE_PORT"
      fi
    fi

    if [[ "$LIMIT" -gt 0 && "$count" -ge "$LIMIT" ]]; then
      break
    fi
  done <<EOF
$(lsof -nP -iTCP -iUDP 2>/dev/null | sed '1d')
EOF
fi

write_network_event "network-summary" "summary" "" "" "mixed" "" "" "" "" "network_summary" "network_summary" "connections=$count;listen=$listen_count;external=$external_count"

if [[ "$external_count" -ge 50 ]]; then
  write_network_event "network-large-external" "large_external_connections" "" "" "mixed" "" "" "" "" "large_external_connections" "network_behavior" "external_connections=$external_count"
fi

if [[ "$count" -eq 0 ]]; then
  write_network_event "network-0" "no_connection" "" "" "tcp" "" "" "" "" "no_connection"
fi
