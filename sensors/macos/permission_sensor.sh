#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"
SUDO_MANAGER="$REPO_ROOT/runtime/sudo_manager.sh"

OUTPUT_FILE=""
PROFILE_ID="default"

usage() {
  printf 'Usage: %s --output FILE [--profile PROFILE_ID]\n' "$0" >&2
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
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

HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
EVENT_COUNT=0

write_permission_event() {
  permission_type="$1"
  status_value="$2"
  detail_value="$3"

  EVENT_COUNT=$((EVENT_COUNT + 1))

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="permission-${EVENT_COUNT}" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="" \
    PLATFORM="macos" \
    SENSOR_TYPE="permission" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="permission" \
    EVENT_TYPE="permission_check" \
    PROCESS_NAME="" \
    PID="" \
    ACTION="permission_check" \
    TARGET="$permission_type" \
    TARGET_TYPE="permission" \
    SOURCE="sensor" \
    CONFIDENCE="70" \
    TAGS="macos,permission,sensor" \
    SERVICE_TYPE="" \
    PLIST_PATH="" \
    LABEL="" \
    PROTOCOL="" \
    LOCAL_ADDRESS="" \
    LOCAL_PORT="" \
    REMOTE_ADDRESS="" \
    REMOTE_PORT="" \
    COMPUTER_NAME="" \
    OS_NAME="" \
    OS_VERSION="" \
    OS_BUILD="" \
    KERNEL="" \
    ARCH="" \
    PERMISSION_TYPE="$permission_type" \
    STATUS="$status_value" \
    DETAIL="$detail_value"
}

check_tcc_path() {
  permission_type="$1"
  tcc_path="$2"

  if [ -e "$tcc_path" ]; then
    write_permission_event "$permission_type" "present" "$tcc_path"
  else
    write_permission_event "$permission_type" "missing" "$tcc_path"
  fi
}

write_permission_event "full_disk_access" "unknown" "macOS Full Disk Access is controlled by TCC and cannot be safely inferred without user-approved access."

check_tcc_path "system_tcc_database" "/Library/Application Support/com.apple.TCC/TCC.db"
check_tcc_path "user_tcc_database" "$HOME/Library/Application Support/com.apple.TCC/TCC.db"

if command -v profiles >/dev/null 2>&1; then
  write_permission_event "profiles_command" "available" "profiles command is available"

  if [ -x "$SUDO_MANAGER" ]; then
    profiles_output="$(bash "$SUDO_MANAGER" run profiles list -type configuration 2>/dev/null || true)"
  else
    profiles_output="$(profiles list -type configuration 2>/dev/null || true)"
  fi
  if [ -n "$profiles_output" ]; then
    write_permission_event "pppc_mdm_profiles" "present" "configuration profiles were returned by profiles command"
  else
    write_permission_event "pppc_mdm_profiles" "unknown" "profiles command returned no readable configuration profile details"
  fi
else
  write_permission_event "profiles_command" "unknown" "profiles command is not available"
  write_permission_event "pppc_mdm_profiles" "unknown" "profiles command is not available"
fi
