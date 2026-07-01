#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"

OUTPUT_FILE=""
PROFILE_ID="default"
SCAN_ROOT=""
LIMIT="${SDMON_CREDENTIAL_LIMIT:-80}"

usage() {
  printf 'Usage: %s --output FILE [--profile PROFILE_ID] [--scan-root DIR] [--limit N]\n' "$0" >&2
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
    --scan-root)
      [ "$#" -ge 2 ] || die "--scan-root requires a directory"
      SCAN_ROOT="$2"
      shift 2
      ;;
    --limit)
      [ "$#" -ge 2 ] || die "--limit requires a number"
      LIMIT="$2"
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
USER_NAME_VALUE="$(whoami 2>/dev/null || printf 'unknown')"
EVENT_TIME="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
EVENT_COUNT=0
MATCH_COUNT=0
SCAN_ROOT="${SCAN_ROOT:-$PWD}"
SEEN_PATHS="|"

is_number() {
  case "$1" in
    ''|*[!0-9]*)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

is_number "$LIMIT" || LIMIT="80"

json_safe() {
  value="$1"
  value=${value//$'\n'/ }
  value=${value//$'\r'/ }
  printf '%s' "$value"
}

path_seen() {
  case "$SEEN_PATHS" in
    *"|$1|"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

remember_path() {
  SEEN_PATHS="${SEEN_PATHS}$1|"
}

stat_field() {
  format="$1"
  target_path="$2"
  stat -f "$format" "$target_path" 2>/dev/null || true
}

is_world_readable() {
  case "$1" in
    *4|*5|*6|*7)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_group_writable() {
  case "$1" in
    ?2?|?3?|?6?|?7?)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_abnormal_directory() {
  target_path="$1"
  case "$target_path" in
    /tmp/*|/private/tmp/*|/var/tmp/*|/private/var/tmp/*|"$HOME"/Downloads/*|"$HOME"/Desktop/*|"$HOME"/Documents/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_sensitive_credential_type() {
  case "$1" in
    "SSH Private Key"|"AWS Credentials"|"Azure Credentials"|"GCP Credentials"|"Docker Login"|"Kube Config"|"Git Credential Store"|"Environment Secret File"|"Generic Token File"|"OpenAI API Key Config"|"Gemini API Key Config"|"Claude API Key Config"|"HuggingFace Token Config"|"Slack Token Config"|"Discord Token Config"|"Bearer Token Config"|"JWT Token Config"|"PGP Key")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

detect_credential_type() {
  target_path="$1"
  base_name="$(basename "$target_path")"

  case "$target_path" in
    "$HOME"/.aws/credentials|"$HOME"/.aws/config)
      printf 'AWS Credentials'
      ;;
    "$HOME"/.azure/*)
      printf 'Azure Credentials'
      ;;
    "$HOME"/.config/gcloud/*|*application_default_credentials.json)
      printf 'GCP Credentials'
      ;;
    "$HOME"/.docker/config.json)
      printf 'Docker Login'
      ;;
    "$HOME"/.kube/config)
      printf 'Kube Config'
      ;;
    "$HOME"/.git-credentials)
      printf 'Git Credential Store'
      ;;
    "$HOME"/.npmrc)
      printf 'Token Configuration'
      ;;
    "$HOME"/.netrc)
      printf 'Credential File'
      ;;
    "$HOME"/.pypirc)
      printf 'Credential File'
      ;;
    *)
      case "$base_name" in
        id_rsa|id_ed25519)
          printf 'SSH Private Key'
          ;;
        authorized_keys)
          printf 'SSH Authorized Keys'
          ;;
        known_hosts)
          printf 'SSH Known Hosts'
          ;;
        .env|.env.local|.env.production|.env.development|.env.test)
          printf 'Environment Secret File'
          ;;
        credentials|credentials.json)
          printf 'Credential File'
          ;;
        token.json)
          printf 'Generic Token File'
          ;;
        config.json)
          printf 'Configuration File'
          ;;
        *.asc|*.gpg|*.pgp)
          printf 'PGP Key'
          ;;
        *)
          case "$target_path" in
            *openai*|*OPENAI*)
              printf 'OpenAI API Key Config'
              ;;
            *gemini*|*GEMINI*)
              printf 'Gemini API Key Config'
              ;;
            *claude*|*anthropic*|*CLAUDE*|*ANTHROPIC*)
              printf 'Claude API Key Config'
              ;;
            *huggingface*|*HUGGINGFACE*)
              printf 'HuggingFace Token Config'
              ;;
            *slack*|*SLACK*)
              printf 'Slack Token Config'
              ;;
            *discord*|*DISCORD*)
              printf 'Discord Token Config'
              ;;
            *bearer*|*BEARER*)
              printf 'Bearer Token Config'
              ;;
            *jwt*|*JWT*)
              printf 'JWT Token Config'
              ;;
            *)
              printf 'Credential Candidate'
              ;;
          esac
          ;;
      esac
      ;;
  esac
}

git_tracked_status() {
  target_path="$1"
  parent_dir="$(dirname "$target_path")"
  repo_root="$(git -C "$parent_dir" rev-parse --show-toplevel 2>/dev/null || true)"

  if [ -z "$repo_root" ]; then
    printf 'false'
    return 0
  fi

  rel_path="${target_path#$repo_root/}"
  if git -C "$repo_root" ls-files --error-unmatch "$rel_path" >/dev/null 2>&1; then
    printf 'true'
  else
    printf 'false'
  fi
}

write_event() {
  event_id="$1"
  action_value="$2"
  credential_type="$3"
  target_path="$4"
  status_value="$5"
  risk_value="$6"
  detail_value="$7"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$event_id" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="$USER_NAME_VALUE" \
    PLATFORM="macos" \
    SENSOR_TYPE="credential" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="security" \
    EVENT_TYPE="credential_detected" \
    PROCESS_NAME="$credential_type" \
    PID="" \
    ACTION="$action_value" \
    TARGET="$target_path" \
    TARGET_TYPE="credential" \
    SOURCE="sensor" \
    CONFIDENCE="75" \
    TAGS="macos,credential,secret,metadata" \
    STATUS="$status_value" \
    DETAIL="$detail_value;risk=$risk_value"
}

record_target() {
  target_path="$1"

  [ -e "$target_path" ] || return 0
  path_seen "$target_path" && return 0
  [ "$MATCH_COUNT" -lt "$LIMIT" ] || return 0
  remember_path "$target_path"

  MATCH_COUNT=$((MATCH_COUNT + 1))
  EVENT_COUNT=$((EVENT_COUNT + 1))

  credential_type="$(detect_credential_type "$target_path")"
  permission_symbolic="$(stat_field '%Sp' "$target_path")"
  permission_octal="$(stat_field '%OLp' "$target_path")"
  owner_value="$(stat_field '%Su' "$target_path")"
  size_value="$(stat_field '%z' "$target_path")"

  if [ -z "$permission_symbolic" ] || [ -z "$permission_octal" ]; then
    detail_value="credential_type=$(json_safe "$credential_type");permission=unknown;owner=$(json_safe "${owner_value:-unknown}");size=$(json_safe "${size_value:-unknown}");status=permission_denied;reason=metadata_unavailable;git_tracked=false;world_readable=unknown;group_writable=unknown;abnormal_directory=unknown"
    write_event "credential-$EVENT_COUNT" "credential_detected" "$credential_type" "$target_path" "permission_denied" "medium" "$detail_value"
    return 0
  fi

  last_three="${permission_octal: -3}"
  world_readable="false"
  group_writable="false"
  abnormal_directory="false"
  git_tracked="$(git_tracked_status "$target_path")"
  status_value="present"
  risk_value="info"
  action_value="credential_detected"
  reason_value="metadata_only_review"

  if is_world_readable "$last_three"; then
    world_readable="true"
  fi

  if is_group_writable "$last_three"; then
    group_writable="true"
  fi

  if is_abnormal_directory "$target_path"; then
    abnormal_directory="true"
  fi

  if [ "$world_readable" = "true" ] || [ "$group_writable" = "true" ] || [ "$git_tracked" = "true" ] || [ "$abnormal_directory" = "true" ]; then
    status_value="review"
    risk_value="medium"
    action_value="credential_permission_unsafe"
    reason_value="permission_or_location_review"
  elif is_sensitive_credential_type "$credential_type"; then
    risk_value="low"
    reason_value="sensitive_credential_present_with_safe_metadata"
  fi

  if is_sensitive_credential_type "$credential_type" && { [ "$world_readable" = "true" ] || [ "$group_writable" = "true" ] || [ "$git_tracked" = "true" ]; }; then
    risk_value="high"
    action_value="credential_sensitive_permission_unsafe"
    reason_value="sensitive_credential_with_unsafe_metadata"
  fi

  detail_value="credential_type=$(json_safe "$credential_type");permission=$(json_safe "$permission_symbolic")/$permission_octal;owner=$(json_safe "${owner_value:-unknown}");size=$(json_safe "${size_value:-0}");status=$status_value;reason=$reason_value;git_tracked=$git_tracked;world_readable=$world_readable;group_writable=$group_writable;abnormal_directory=$abnormal_directory"

  write_event "credential-$EVENT_COUNT" "$action_value" "$credential_type" "$target_path" "$status_value" "$risk_value" "$detail_value"
}

scan_root_for_names() {
  root_path="$1"
  max_depth="$2"
  shift 2

  [ -d "$root_path" ] || return 0

  while IFS= read -r target_path; do
    [ "$MATCH_COUNT" -lt "$LIMIT" ] || break
    record_target "$target_path"
  done < <(find "$root_path" -maxdepth "$max_depth" -type f \( "$@" \) 2>/dev/null)
}

record_target "$HOME/.npmrc"
record_target "$HOME/.netrc"
record_target "$HOME/.pypirc"
record_target "$HOME/.git-credentials"

scan_root_for_names "$HOME/.ssh" 2 -name id_rsa -o -name id_ed25519 -o -name known_hosts -o -name authorized_keys -o -name config
scan_root_for_names "$HOME/.aws" 2 -name credentials -o -name config
scan_root_for_names "$HOME/.azure" 3 -name credentials -o -name config -o -name token.json -o -name credentials.json
scan_root_for_names "$HOME/.config/gcloud" 3 -name credentials -o -name credentials.json -o -name config.json -o -name token.json -o -name application_default_credentials.json
scan_root_for_names "$HOME/.config" 3 -name .env -o -name .env.local -o -name .env.production -o -name .env.development -o -name .env.test -o -name config.json -o -name credentials -o -name credentials.json -o -name token.json
scan_root_for_names "$HOME/.kube" 2 -name config -o -name credentials -o -name credentials.json
scan_root_for_names "$HOME/.docker" 2 -name config.json
scan_root_for_names "$HOME/Library/Application Support" 4 -name .env -o -name .env.local -o -name .env.production -o -name credentials -o -name credentials.json -o -name token.json -o -name config.json
scan_root_for_names "$SCAN_ROOT" 4 -name .env -o -name .env.local -o -name .env.production -o -name .env.development -o -name .env.test -o -name config.json -o -name credentials -o -name credentials.json -o -name token.json -o -name id_rsa -o -name id_ed25519 -o -name known_hosts -o -name authorized_keys -o -name config

exit 0
