#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EVENT_WRITER="$REPO_ROOT/events/event_writer.sh"
SUDO_MANAGER="$REPO_ROOT/runtime/sudo_manager.sh"

OUTPUT_FILE=""
PROFILE_ID="default"
EVENT_COUNT=0

usage() {
  printf 'Usage: %s --output FILE [--profile PROFILE_ID]\n' "$0" >&2
}

die() {
  printf 'enterprise_security_sensor: %s\n' "$1" >&2
  exit 1
}

jsonish_detail() {
  value="$1"
  value=${value//$'\n'/ }
  value=${value//$'\r'/ }
  printf '%s' "$value"
}

privileged_run() {
  if [ -x "$SUDO_MANAGER" ]; then
    bash "$SUDO_MANAGER" run "$@" 2>&1 || true
  else
    "$@" 2>&1 || true
  fi
}

next_event_id() {
  EVENT_COUNT=$((EVENT_COUNT + 1))
  printf 'enterprise-%s' "$EVENT_COUNT"
}

write_event() {
  event_category="$1"
  event_type="$2"
  action="$3"
  target="$4"
  target_type="$5"
  status_value="$6"
  detail_value="$7"

  bash "$EVENT_WRITER" --output "$OUTPUT_FILE" \
    EVENT_ID="$(next_event_id)" \
    EVENT_VERSION="1" \
    TIMESTAMP="$EVENT_TIME" \
    HOSTNAME="$HOSTNAME_VALUE" \
    USER_NAME="$USER_NAME_VALUE" \
    PLATFORM="macos" \
    SENSOR_TYPE="enterprise_security" \
    PROFILE_ID="$PROFILE_ID" \
    EVENT_CATEGORY="$event_category" \
    EVENT_TYPE="$event_type" \
    PROCESS_NAME="" \
    PID="" \
    ACTION="$action" \
    TARGET="$target" \
    TARGET_TYPE="$target_type" \
    SOURCE="sensor" \
    CONFIDENCE="75" \
    TAGS="macos,enterprise,security,sensor" \
    STATUS="$status_value" \
    DETAIL="$(jsonish_detail "$detail_value")"
}

status_enabled_disabled_unknown() {
  raw_value="$1"
  case "$raw_value" in
    *enabled*|*On*|*on*|*active*|*yes*|*Yes*)
      printf 'enabled'
      ;;
    *disabled*|*Off*|*off*|*inactive*|*no*|*No*)
      printf 'disabled'
      ;;
    *permission*|*not\ permitted*|*Operation\ not\ permitted*)
      printf 'permission_denied'
      ;;
    *unsupported*|*not\ available*)
      printf 'unsupported'
      ;;
    *)
      printf 'unknown'
      ;;
  esac
}

detect_login_items() {
  login_output="$(osascript -e 'tell application "System Events" to get the name of every login item' 2>&1 || true)"
  if [ -z "$login_output" ]; then
    write_event "configuration" "login_items" "login_items_unknown" "login_items" "startup_item" "unknown" "Login Items could not be read."
  elif printf '%s\n' "$login_output" | grep -qi 'not.*authorized\|not.*permitted\|Can.t get'; then
    write_event "configuration" "login_items" "login_items_permission_denied" "login_items" "startup_item" "permission_denied" "$login_output"
  else
    count="$(printf '%s\n' "$login_output" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
    [ -n "$count" ] || count="0"
    write_event "configuration" "login_items" "login_items_summary" "login_items" "startup_item" "ok" "count=$count;items=$login_output"
  fi

  if command -v sfltool >/dev/null 2>&1; then
    write_event "configuration" "background_items" "background_items_protected" "background_items" "startup_item" "unknown" "Background item details are protected on modern macOS. SDMon skipped direct sfltool interrogation to preserve a single administrator authentication."
  else
    write_event "configuration" "background_items" "background_items_unsupported" "background_items" "startup_item" "unsupported" "sfltool is not available."
  fi
}

browser_dir_count() {
  base_dir="$1"
  if [ -d "$base_dir" ]; then
    find "$base_dir" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' '
  else
    printf '0'
  fi
}

detect_browser_extensions() {
  safari_dir="$HOME/Library/Safari/Extensions"
  chrome_dir="$HOME/Library/Application Support/Google/Chrome"
  edge_dir="$HOME/Library/Application Support/Microsoft Edge"

  safari_count="0"
  [ -d "$safari_dir" ] && safari_count="$(find "$safari_dir" -maxdepth 1 -type f -name '*.safariextz' 2>/dev/null | wc -l | tr -d ' ')"
  chrome_count="0"
  edge_count="0"

  if [ -d "$chrome_dir" ]; then
    chrome_count="$(find "$chrome_dir" -path '*/Extensions/*/*' -type d 2>/dev/null | wc -l | tr -d ' ')"
    if grep -R '"developer_mode"[[:space:]]*:[[:space:]]*true' "$chrome_dir"/*/Preferences >/dev/null 2>&1; then
      write_event "application" "browser_extension" "browser_developer_mode" "Google Chrome" "browser" "review" "Chrome developer mode appears enabled in a profile preference."
    fi
  fi

  if [ -d "$edge_dir" ]; then
    edge_count="$(find "$edge_dir" -path '*/Extensions/*/*' -type d 2>/dev/null | wc -l | tr -d ' ')"
    if grep -R '"developer_mode"[[:space:]]*:[[:space:]]*true' "$edge_dir"/*/Preferences >/dev/null 2>&1; then
      write_event "application" "browser_extension" "browser_developer_mode" "Microsoft Edge" "browser" "review" "Edge developer mode appears enabled in a profile preference."
    fi
  fi

  total_count="$((safari_count + chrome_count + edge_count))"
  write_event "application" "browser_extension" "browser_extension_summary" "browser_extensions" "browser" "ok" "total=$total_count;safari=$safari_count;chrome=$chrome_count;edge=$edge_count"

  for manifest in "$chrome_dir"/*/Extensions/*/*/manifest.json "$edge_dir"/*/Extensions/*/*/manifest.json; do
    [ -f "$manifest" ] || continue
    if grep -E '"externally_connectable"|"nativeMessaging"|"management"|"debugger"' "$manifest" >/dev/null 2>&1; then
      write_event "application" "browser_extension" "browser_extension_suspicious" "$manifest" "browser_extension" "review" "Manifest contains sensitive extension capability."
    fi
  done
}

signature_status() {
  app_path="$1"
  codesign_output="$(codesign -dv --verbose=4 "$app_path" 2>&1 || true)"

  if printf '%s\n' "$codesign_output" | grep -qi 'code object is not signed'; then
    printf 'unsigned'
  elif printf '%s\n' "$codesign_output" | grep -qi 'Authority='; then
    printf 'signed'
  elif printf '%s\n' "$codesign_output" | grep -qi 'permission'; then
    printf 'permission_denied'
  else
    printf 'unknown'
  fi
}

detect_applications() {
  app_count="0"
  unsigned_count="0"
  unknown_count="0"

  for app_root in "/Applications" "$HOME/Applications"; do
    [ -d "$app_root" ] || continue
    while IFS= read -r app_path; do
      [ -n "$app_path" ] || continue
      app_count=$((app_count + 1))
      status_value="$(signature_status "$app_path")"
      case "$status_value" in
        unsigned)
          unsigned_count=$((unsigned_count + 1))
          write_event "application" "application_inventory" "application_unsigned" "$app_path" "application" "review" "signature=unsigned;path=$app_path"
          ;;
        unknown|permission_denied)
          unknown_count=$((unknown_count + 1))
          write_event "application" "application_inventory" "application_unknown_developer" "$app_path" "application" "$status_value" "signature=$status_value;path=$app_path"
          ;;
      esac
    done <<EOF
$(find "$app_root" -maxdepth 1 -type d -name '*.app' 2>/dev/null | head -15)
EOF
  done

  write_event "application" "application_inventory" "application_inventory_summary" "applications" "application" "ok" "count=$app_count;unsigned=$unsigned_count;unknown=$unknown_count"
}

detect_gatekeeper() {
  raw="$(privileged_run spctl --status)"
  [ -n "$raw" ] || raw="unknown"
  status_value="$(status_enabled_disabled_unknown "$raw")"
  write_event "security" "gatekeeper_status" "gatekeeper_$status_value" "gatekeeper" "macos_security_status" "$status_value" "$raw"
}

detect_xprotect() {
  plist="/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"
  alt_plist="/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"
  [ -f "$plist" ] || plist="$alt_plist"

  if [ -f "$plist" ]; then
    version="$(privileged_run defaults read "${plist%.plist}" CFBundleShortVersionString)"
    [ -n "$version" ] || version="$(privileged_run defaults read "${plist%.plist}" CFBundleVersion)"
    [ -n "$version" ] || version="unknown"
    updated="$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%S%z' "$plist" 2>/dev/null || printf 'unknown')"
    write_event "security" "xprotect_status" "xprotect_present" "xprotect" "macos_security_status" "present" "version=$version;updated=$updated;path=$plist"
  else
    write_event "security" "xprotect_status" "xprotect_missing" "xprotect" "macos_security_status" "missing" "XProtect bundle was not found."
  fi
}

detect_mrt() {
  mrt_path="/Library/Apple/System/Library/CoreServices/MRT.app"
  [ -d "$mrt_path" ] || mrt_path="/System/Library/CoreServices/MRT.app"

  if [ -d "$mrt_path" ]; then
    version="$(privileged_run defaults read "$mrt_path/Contents/Info" CFBundleShortVersionString)"
    [ -n "$version" ] || version="$(privileged_run defaults read "$mrt_path/Contents/Info" CFBundleVersion)"
    [ -n "$version" ] || version="unknown"
    write_event "security" "mrt_status" "mrt_present" "mrt" "macos_security_status" "present" "version=$version;path=$mrt_path"
  else
    write_event "security" "mrt_status" "mrt_missing" "mrt" "macos_security_status" "missing" "Apple MRT was not found."
  fi
}

detect_filevault() {
  raw="$(privileged_run fdesetup status)"
  [ -n "$raw" ] || raw="unknown"
  status_value="$(status_enabled_disabled_unknown "$raw")"
  write_event "security" "filevault_status" "filevault_$status_value" "filevault" "macos_security_status" "$status_value" "$raw"

  prk_raw="$(privileged_run fdesetup haspersonalrecoverykey)"
  prk_status="$(status_enabled_disabled_unknown "$prk_raw")"
  write_event "security" "filevault_recovery_key" "filevault_recovery_key_$prk_status" "filevault_recovery_key" "macos_security_status" "$prk_status" "$prk_raw"

  defer_raw="$(privileged_run fdesetup showdeferralinfo)"
  if printf '%s\n' "$defer_raw" | grep -qi 'not.*enabled\|No deferred enablement'; then
    defer_status="disabled"
  elif [ -n "$defer_raw" ]; then
    defer_status="unknown"
  else
    defer_status="unknown"
  fi
  write_event "security" "filevault_user_control" "filevault_user_control_$defer_status" "filevault_user_control" "macos_security_status" "$defer_status" "$defer_raw"
}

detect_sip() {
  raw="$(privileged_run csrutil status)"
  [ -n "$raw" ] || raw="unknown"
  status_value="$(status_enabled_disabled_unknown "$raw")"
  write_event "security" "sip_status" "sip_$status_value" "sip" "macos_security_status" "$status_value" "$raw"

  if printf '%s\n' "$raw" | grep -qi 'Configuration:'; then
    printf '%s\n' "$raw" | sed -n '/Configuration:/,$p' | while IFS= read -r item; do
      case "$item" in
        *enabled*|*disabled*)
          item_status="$(status_enabled_disabled_unknown "$item")"
          write_event "security" "sip_protection_item" "sip_protection_$item_status" "sip_protection" "macos_security_status" "$item_status" "$item"
          ;;
      esac
    done
  fi
}

detect_sharing_and_firewall() {
  fw_raw="$(privileged_run /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate)"
  fw_status="$(status_enabled_disabled_unknown "$fw_raw")"
  write_event "security" "firewall_status" "firewall_$fw_status" "application_firewall" "macos_security_status" "$fw_status" "$fw_raw"

  stealth_raw="$(privileged_run /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode)"
  stealth_status="$(status_enabled_disabled_unknown "$stealth_raw")"
  write_event "security" "firewall_stealth_mode" "stealth_mode_$stealth_status" "stealth_mode" "macos_security_status" "$stealth_status" "$stealth_raw"

  for service in "Remote Login:ssh" "Remote Management:ard" "Screen Sharing:vnc" "AirDrop:airdrop"; do
    service_name="${service%%:*}"
    service_key="${service#*:}"
    raw="$(privileged_run systemsetup -get${service_name// /})"
    if [ -z "$raw" ] || printf '%s\n' "$raw" | grep -qi 'requires Full Disk Access\|not available\|unrecognized'; then
      raw="$(privileged_run /usr/bin/defaults read /Library/Preferences/com.apple.sharing.firewall)"
    fi
    status_value="$(status_enabled_disabled_unknown "$raw")"
    write_event "configuration" "sharing_service" "${service_key}_$status_value" "$service_name" "sharing_service" "$status_value" "$raw"
  done
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
USER_NAME_VALUE="$(whoami 2>/dev/null || printf 'unknown')"

detect_login_items
detect_browser_extensions
detect_applications
detect_gatekeeper
detect_xprotect
detect_mrt
detect_filevault
detect_sip
detect_sharing_and_firewall
