#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"

OUTPUT_FILE=""
PROFILE_ID="default"

usage() {
  printf 'Usage: %s --output FILE [--profile PROFILE_ID]\n' "$0" >&2
}

die() {
  printf 'ssh_authorized_keys_sensor: %s\n' "$1" >&2
  exit 1
}

file_mode() {
  if command -v stat >/dev/null 2>&1 && [ -e "$1" ]; then
    stat -f '%Lp' "$1" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

file_owner() {
  if command -v stat >/dev/null 2>&1 && [ -e "$1" ]; then
    stat -f '%Su' "$1" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

is_abnormal_mode() {
  case "$1" in
    600|640|644)
      return 1
      ;;
    unknown)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

json_detail() {
  printf 'path=%s;user=%s;key_type=%s;key_fingerprint_available=%s;status=%s;mode=%s;owner=%s' "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

write_key_event() {
  event_id="$1"
  key_path="$2"
  key_user="$3"
  key_type="$4"
  fingerprint_available="$5"
  status_value="$6"
  mode_value="${7:-unknown}"
  owner_value="${8:-unknown}"
  event_type="${9:-ssh_authorized_key}"
  action_value="${10:-$status_value}"
  detail_value="$(json_detail "$key_path" "$key_user" "$key_type" "$fingerprint_available" "$status_value" "$mode_value" "$owner_value")"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="ssh-authorized-key-$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="$key_user" \
    PLATFORM="macos" \
    SENSOR_TYPE="ssh_authorized_keys" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="security" \
    EVENT_TYPE="$event_type" \
    PROCESS_NAME="" \
    PID="" \
    ACTION="$action_value" \
    TARGET="$key_path" \
    TARGET_TYPE="ssh_authorized_keys" \
    SOURCE="sensor" \
    CONFIDENCE="80" \
    TAGS="macos,ssh,authorized_keys,sensor" \
    STATUS="$status_value" \
    DETAIL="$detail_value"
}

inspect_authorized_keys() {
  key_path="$1"
  key_user="$2"
  event_prefix="$3"

  if [ ! -e "$key_path" ]; then
    write_key_event "$event_prefix-1" "$key_path" "$key_user" "" "false" "not_found"
    return 0
  fi

  mode_value="$(file_mode "$key_path")"
  owner_value="$(file_owner "$key_path")"

  if [ ! -r "$key_path" ]; then
    write_key_event "$event_prefix-1" "$key_path" "$key_user" "" "false" "permission_denied" "$mode_value" "$owner_value"
    return 0
  fi

  if is_abnormal_mode "$mode_value"; then
    write_key_event "$event_prefix-permission" "$key_path" "$key_user" "" "false" "abnormal_permissions" "$mode_value" "$owner_value" "ssh_authorized_key_behavior" "ssh_authorized_keys_abnormal_permissions"
  fi

  count="0"
  while IFS= read -r line; do
    case "$line" in
      ''|\#*) continue ;;
    esac
    key_type="${line%% *}"
    case "$key_type" in
      ssh-rsa|ssh-ed25519|ecdsa-sha2-*|sk-ssh-*|sk-ecdsa-*) ;;
      *) key_type="unknown" ;;
    esac
    count=$((count + 1))
    write_key_event "$event_prefix-$count" "$key_path" "$key_user" "$key_type" "false" "present" "$mode_value" "$owner_value"
    if [ "$key_type" = "unknown" ]; then
      write_key_event "$event_prefix-unknown-$count" "$key_path" "$key_user" "$key_type" "false" "unknown_key" "$mode_value" "$owner_value" "ssh_authorized_key_behavior" "ssh_unknown_key"
    fi
  done < "$key_path"

  if [ "$count" -eq 0 ]; then
    write_key_event "$event_prefix-1" "$key_path" "$key_user" "" "false" "empty" "$mode_value" "$owner_value"
    write_key_event "$event_prefix-empty" "$key_path" "$key_user" "" "false" "empty" "$mode_value" "$owner_value" "ssh_authorized_key_behavior" "ssh_authorized_keys_empty"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      [ "$#" -ge 2 ] || die "--output requires a file path"
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --profile)
      [ "$#" -ge 2 ] || die "--profile requires a profile id"
      PROFILE_ID="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[ -n "$OUTPUT_FILE" ] || die "--output is required"
[ -f "$EVENT_WRITER" ] || die "event writer not found: $EVENT_WRITER"

EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
CURRENT_USER="$(whoami 2>/dev/null || printf 'unknown')"

inspect_authorized_keys "$HOME/.ssh/authorized_keys" "$CURRENT_USER" "user"
inspect_authorized_keys "/root/.ssh/authorized_keys" "root" "root"
