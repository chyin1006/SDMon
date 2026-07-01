#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"
SUDO_MANAGER="$REPO_ROOT/runtime/sudo_manager.sh"

OUTPUT_FILE=""
PROFILE_ID="default"
LIMIT="0"
TARGET_DIRS="/Library/LaunchAgents
/Library/LaunchDaemons
/System/Library/LaunchAgents
/System/Library/LaunchDaemons
$HOME/Library/LaunchAgents"

usage() {
  cat <<'USAGE'
Usage:
  launchd_sensor.sh --output FILE [--profile PROFILE_ID] [--path DIR] [--limit N]

Collects macOS LaunchAgent and LaunchDaemon plist observations and writes service Normalized Events.
USAGE
}

die() {
  printf 'launchd_sensor: %s\n' "$1" >&2
  exit 1
}

is_number() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

plist_label() {
  local plist_path="$1"
  local label

  if command -v defaults >/dev/null 2>&1; then
    if [[ -x "$SUDO_MANAGER" ]]; then
      label="$(bash "$SUDO_MANAGER" run defaults read "${plist_path%.plist}" Label 2>/dev/null || true)"
    else
      label="$(defaults read "${plist_path%.plist}" Label 2>/dev/null || true)"
    fi
    if [[ -n "$label" ]]; then
      printf '%s' "$label"
      return 0
    fi
  fi

  label="${plist_path##*/}"
  printf '%s' "${label%.plist}"
}

plist_value() {
  local plist_path="$1"
  local key="$2"
  local value

  if command -v defaults >/dev/null 2>&1; then
    if [[ -x "$SUDO_MANAGER" ]]; then
      value="$(bash "$SUDO_MANAGER" run defaults read "${plist_path%.plist}" "$key" 2>/dev/null || true)"
    else
      value="$(defaults read "${plist_path%.plist}" "$key" 2>/dev/null || true)"
    fi
    if [[ -n "$value" ]]; then
      printf '%s' "$value"
      return 0
    fi
  fi

  printf ''
}

path_owner() {
  local target_path="$1"
  if command -v stat >/dev/null 2>&1; then
    stat -f '%Su' "$target_path" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

path_writable() {
  local target_path="$1"
  if [[ -w "$target_path" ]]; then
    printf 'true'
  else
    printf 'false'
  fi
}

program_path_from_plist() {
  local program_value="$1"
  local arguments_value="$2"

  if [[ -n "$program_value" ]]; then
    printf '%s' "$program_value"
    return 0
  fi

  printf '%s\n' "$arguments_value" | awk '
    {
      gsub(/[",;]/, "")
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^\//) {
          print $i
          exit
        }
      }
    }
  '
}

is_expected_launchd_dir() {
  local plist_path="$1"
  case "$plist_path" in
    /Library/LaunchAgents/*|/Library/LaunchDaemons/*|/System/Library/LaunchAgents/*|/System/Library/LaunchDaemons/*|"$HOME"/Library/LaunchAgents/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

write_launchd_behavior() {
  local event_id="$1"
  local action="$2"
  local plist_path="$3"
  local label="$4"
  local target="$5"
  local detail="$6"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="" \
    PLATFORM="macos" \
    SENSOR_TYPE="launchd" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="service" \
    EVENT_TYPE="launchd_persistence" \
    PROCESS_NAME="$label" \
    PID="" \
    ACTION="$action" \
    TARGET="$target" \
    TARGET_TYPE="service" \
    SOURCE="sensor" \
    CONFIDENCE="80" \
    TAGS="macos,launchd,persistence,sensor" \
    SERVICE_TYPE="launchd" \
    PLIST_PATH="$plist_path" \
    LABEL="$label" \
    STATUS="$action" \
    DETAIL="$detail"
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
    --path)
      shift
      [[ $# -gt 0 ]] || die "--path requires a directory"
      TARGET_DIRS="$1"
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
command -v find >/dev/null 2>&1 || die "missing required macOS command: find"

HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
count="0"

printf '%s\n' "$TARGET_DIRS" | while IFS= read -r target_dir; do
  [[ -n "$target_dir" && -d "$target_dir" ]] || continue

  find "$target_dir" -maxdepth 1 -type f -name '*.plist' -print 2>/dev/null | while IFS= read -r plist_path; do
    [[ -n "$plist_path" ]] || continue

    label="$(plist_label "$plist_path")"
    program="$(plist_value "$plist_path" "Program")"
    program_arguments="$(plist_value "$plist_path" "ProgramArguments")"
    run_at_load="$(plist_value "$plist_path" "RunAtLoad")"
    keep_alive="$(plist_value "$plist_path" "KeepAlive")"
    owner="$(path_owner "$plist_path")"
    writable="$(path_writable "$plist_path")"
    program_path="$(program_path_from_plist "$program" "$program_arguments")"
    detail="path=$plist_path;label=$label;program=$program;program_path=$program_path;program_arguments=$program_arguments;run_at_load=$run_at_load;keep_alive=$keep_alive;owner=$owner;writable=$writable"
    count=$((count + 1))

    bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
      EVENT_ID="launchd-${count}" \
      EVENT_VERSION="1" \
      TIMESTAMP="$EVENT_TIME" \
      HOSTNAME="$HOSTNAME_VALUE" \
      USER_NAME="" \
      PLATFORM="macos" \
      SENSOR_TYPE="launchd" \
      PROFILE_ID="$PROFILE_ID" \
      EVENT_CATEGORY="service" \
      EVENT_TYPE="launchd" \
      PROCESS_NAME="$label" \
      PID="" \
      ACTION="found" \
      TARGET="$plist_path" \
      TARGET_TYPE="service" \
      SOURCE="sensor" \
      CONFIDENCE="80" \
      TAGS="macos,launchd,sensor" \
      SERVICE_TYPE="launchd" \
      PLIST_PATH="$plist_path" \
      LABEL="$label" \
      STATUS="found" \
      DETAIL="$detail"

    if ! is_expected_launchd_dir "$plist_path"; then
      write_launchd_behavior "launchd-abnormal-dir-${count}" "launchd_abnormal_directory" "$plist_path" "$label" "$plist_path" "$detail"
    fi

    if [[ "$writable" == "true" ]]; then
      write_launchd_behavior "launchd-user-writable-${count}" "launchd_user_writable" "$plist_path" "$label" "$plist_path" "$detail"
    fi

    if [[ -n "$program_path" && ! -e "$program_path" ]]; then
      write_launchd_behavior "launchd-program-missing-${count}" "launchd_program_missing" "$plist_path" "$label" "$program_path" "$detail"
    fi

    case "$program_path $program_arguments" in
      */tmp/*|*/private/tmp/*|*/var/tmp/*)
        write_launchd_behavior "launchd-tmp-execution-${count}" "launchd_tmp_execution" "$plist_path" "$label" "$program_path" "$detail"
        ;;
    esac

    case "$program_path $program_arguments" in
      */Downloads/*)
        write_launchd_behavior "launchd-downloads-execution-${count}" "launchd_downloads_execution" "$plist_path" "$label" "$program_path" "$detail"
        ;;
    esac

    case "$program_path $program_arguments" in
      */Desktop/*)
        write_launchd_behavior "launchd-desktop-execution-${count}" "launchd_desktop_execution" "$plist_path" "$label" "$program_path" "$detail"
        ;;
    esac

    if [[ "$LIMIT" -gt 0 && "$count" -ge "$LIMIT" ]]; then
      break 2
    fi
  done
done
