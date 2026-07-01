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

value_or_default() {
  default_value="$1"
  shift
  value="$("$@" 2>/dev/null || true)"
  if [ -n "$value" ]; then
    printf '%s' "$value"
  else
    printf '%s' "$default_value"
  fi
}

normalize_security_status() {
  raw_value="$1"
  case "$raw_value" in
    *enabled*|*"assessments enabled"*|*"System Integrity Protection status: enabled"*|*"FileVault is On."*)
      printf 'enabled'
      ;;
    *disabled*|*"assessments disabled"*|*"System Integrity Protection status: disabled"*|*"FileVault is Off."*)
      printf 'disabled'
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}

privileged_run() {
  if [ -x "$SUDO_MANAGER" ]; then
    bash "$SUDO_MANAGER" run "$@" 2>&1 || true
  else
    "$@" 2>&1 || true
  fi
}

write_security_event() {
  event_id="$1"
  event_type="$2"
  target_name="$3"
  raw_output="$4"
  status_value="$5"
  detail_value="status=$status_value;raw_output=$raw_output"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="$USER_NAME_VALUE" \
    PLATFORM="macos" \
    SENSOR_TYPE="system" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="security" \
    EVENT_TYPE="$event_type" \
    PROCESS_NAME="" \
    PID="" \
    ACTION="$status_value" \
    TARGET="$target_name" \
    TARGET_TYPE="macos_security_status" \
    SOURCE="sensor" \
    CONFIDENCE="85" \
    TAGS="macos,security,status,sensor" \
    STATUS="$status_value" \
    DETAIL="$detail_value"
}

EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
HOSTNAME_VALUE="$(value_or_default "unknown" hostname)"
COMPUTER_NAME_VALUE="$(value_or_default "$HOSTNAME_VALUE" scutil --get ComputerName)"
USER_NAME_VALUE="$(value_or_default "unknown" whoami)"
OS_NAME_VALUE="$(value_or_default "macOS" sw_vers -productName)"
OS_VERSION_VALUE="$(value_or_default "unknown" sw_vers -productVersion)"
OS_BUILD_VALUE="$(value_or_default "unknown" sw_vers -buildVersion)"
KERNEL_VALUE="$(value_or_default "unknown" uname -sr)"
ARCH_VALUE="$(value_or_default "unknown" uname -m)"

bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
  EVENT_ID="system-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="$EVENT_TIME" \
  HOSTNAME="$HOSTNAME_VALUE" \
  USER_NAME="$USER_NAME_VALUE" \
  PLATFORM="macos" \
  SENSOR_TYPE="system" \
  PROFILE_ID="$PROFILE_ID" \
  EVENT_CATEGORY="system" \
  EVENT_TYPE="system_info" \
  PROCESS_NAME="" \
  PID="" \
  ACTION="system_info" \
  TARGET="$HOSTNAME_VALUE" \
  TARGET_TYPE="host" \
  SOURCE="sensor" \
  CONFIDENCE="90" \
  TAGS="macos,system,sensor" \
  SERVICE_TYPE="" \
  PLIST_PATH="" \
  LABEL="" \
  PROTOCOL="" \
  LOCAL_ADDRESS="" \
  LOCAL_PORT="" \
  REMOTE_ADDRESS="" \
  REMOTE_PORT="" \
  COMPUTER_NAME="$COMPUTER_NAME_VALUE" \
  OS_NAME="$OS_NAME_VALUE" \
  OS_VERSION="$OS_VERSION_VALUE" \
  OS_BUILD="$OS_BUILD_VALUE" \
  KERNEL="$KERNEL_VALUE" \
  ARCH="$ARCH_VALUE"

GATEKEEPER_RAW="$(privileged_run spctl --status)"
[ -n "$GATEKEEPER_RAW" ] || GATEKEEPER_RAW="unknown"
GATEKEEPER_STATUS="$(normalize_security_status "$GATEKEEPER_RAW")"
write_security_event "security-gatekeeper-1" "gatekeeper_status" "gatekeeper" "$GATEKEEPER_RAW" "$GATEKEEPER_STATUS"

SIP_RAW="$(privileged_run csrutil status)"
[ -n "$SIP_RAW" ] || SIP_RAW="unknown"
SIP_STATUS="$(normalize_security_status "$SIP_RAW")"
write_security_event "security-sip-1" "sip_status" "sip" "$SIP_RAW" "$SIP_STATUS"

FILEVAULT_RAW="$(privileged_run fdesetup status)"
[ -n "$FILEVAULT_RAW" ] || FILEVAULT_RAW="unknown"
FILEVAULT_STATUS="$(normalize_security_status "$FILEVAULT_RAW")"
write_security_event "security-filevault-1" "filevault_status" "filevault" "$FILEVAULT_RAW" "$FILEVAULT_STATUS"
