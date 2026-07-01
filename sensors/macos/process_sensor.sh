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
  process_sensor.sh --output FILE [--profile PROFILE_ID] [--limit N]

Collects current macOS process table entries and writes process Normalized Events.
USAGE
}

die() {
  printf 'process_sensor: %s\n' "$1" >&2
  exit 1
}

is_number() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

write_process_event() {
  event_id="$1"
  event_type="$2"
  action="$3"
  pid="$4"
  ppid="$5"
  user_name="$6"
  process_name="$7"
  process_path="$8"
  command_line="$9"
  detail="pid=$pid;ppid=$ppid;path=$process_path;command_line=$command_line"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="$user_name" \
    PLATFORM="macos" \
    SENSOR_TYPE="process" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="process" \
    EVENT_TYPE="$event_type" \
    PROCESS_NAME="$process_name" \
    PID="$pid" \
    ACTION="$action" \
    TARGET="$process_path" \
    TARGET_TYPE="process" \
    SOURCE="sensor" \
    CONFIDENCE="80" \
    TAGS="macos,process,sensor" \
    DETAIL="$detail"
}

emit_process_behavior() {
  pid="$1"
  ppid="$2"
  user_name="$3"
  process_name="$4"
  process_path="$5"
  command_line="$6"
  event_prefix="$7"

  case "$process_path" in
    /tmp/*|/private/tmp/*|/var/tmp/*|/private/var/tmp/*)
      write_process_event "$event_prefix-tmp-execution" "process_behavior" "tmp_execution" "$pid" "$ppid" "$user_name" "$process_name" "$process_path" "$command_line"
      ;;
  esac

  case "$process_path" in
    "$HOME/Downloads"/*|*/Downloads/*)
      write_process_event "$event_prefix-downloads-execution" "process_behavior" "downloads_execution" "$pid" "$ppid" "$user_name" "$process_name" "$process_path" "$command_line"
      ;;
    "$HOME/Desktop"/*|*/Desktop/*)
      write_process_event "$event_prefix-desktop-execution" "process_behavior" "desktop_execution" "$pid" "$ppid" "$user_name" "$process_name" "$process_path" "$command_line"
      ;;
  esac

  case "$process_path" in
    */.*/*|*/.*)
      write_process_event "$event_prefix-hidden-path-execution" "process_behavior" "hidden_path_execution" "$pid" "$ppid" "$user_name" "$process_name" "$process_path" "$command_line"
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
command -v ps >/dev/null 2>&1 || die "missing required macOS command: ps"

HOSTNAME_VALUE="$(hostname 2>/dev/null || printf 'unknown')"
EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
count="0"

ps -axo pid=,ppid=,user=,comm=,args= | while IFS= read -r raw_line; do
  set -- $raw_line
  pid="${1:-}"
  ppid="${2:-}"
  user_name="${3:-}"
  process_path="${raw_line#"$pid"}"
  process_path="${process_path#"${process_path%%[![:space:]]*}"}"
  process_path="${process_path#"$ppid"}"
  process_path="${process_path#"${process_path%%[![:space:]]*}"}"
  process_path="${process_path#"$user_name"}"
  process_path="${process_path#"${process_path%%[![:space:]]*}"}"
  process_path="${process_path%% *}"
  command_line="$(printf '%s\n' "$raw_line" | awk '{for (i=5; i<=NF; i++) { printf "%s%s", (i==5 ? "" : " "), $i }}')"

  [[ -n "$pid" && -n "$process_path" ]] || continue

  process_name="${process_path##*/}"
  [[ -n "$process_name" ]] || process_name="$process_path"

  count=$((count + 1))
  write_process_event "process-${pid}-${count}" "process_state" "running" "$pid" "$ppid" "$user_name" "$process_name" "$process_path" "$command_line"
  emit_process_behavior "$pid" "$ppid" "$user_name" "$process_name" "$process_path" "$command_line" "process-${pid}-${count}"

  if [[ "$LIMIT" -gt 0 && "$count" -ge "$LIMIT" ]]; then
    break
  fi
done
