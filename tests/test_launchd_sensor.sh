#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_launchd_sensor_test_$$"
TARGET_DIR="$TMP_DIR/LaunchDaemons"
OUTPUT_FILE="$TMP_DIR/events/launchd_events.jsonl"
PLIST_FILE="$TARGET_DIR/com.example.demo.plist"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
export SDMON_NO_OPEN=1

mkdir -p "$TARGET_DIR"
cat > "$PLIST_FILE" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.example.demo</string>
  <key>Program</key>
  <string>/usr/bin/true</string>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST

bash -n "$REPO_ROOT/sensors/macos/launchd_sensor.sh"
bash -n "$REPO_ROOT/tests/test_launchd_sensor.sh"

bash "$REPO_ROOT/sensors/macos/launchd_sensor.sh" --output "$OUTPUT_FILE" --profile "test-profile" --path "$TARGET_DIR" --limit 1

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: launchd event file not generated\n' >&2
  exit 1
}

line_count="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
[[ "$line_count" -ge 1 ]] || {
  printf 'FAIL: no launchd event generated\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"service"' "$OUTPUT_FILE" || {
  printf 'FAIL: CATEGORY=service not found\n' >&2
  exit 1
}

grep -q '"SERVICE_TYPE":"launchd"' "$OUTPUT_FILE" || {
  printf 'FAIL: SERVICE_TYPE=launchd not found\n' >&2
  exit 1
}

grep -q '"EVENT_TYPE":"launchd"' "$OUTPUT_FILE" || {
  printf 'FAIL: EVENT_TYPE=launchd not found\n' >&2
  exit 1
}

grep -q '"ACTION":"found"' "$OUTPUT_FILE" || {
  printf 'FAIL: ACTION=found not found\n' >&2
  exit 1
}

grep -q '"PLIST_PATH":".*/com.example.demo.plist"' "$OUTPUT_FILE" || {
  printf 'FAIL: PLIST_PATH not found\n' >&2
  exit 1
}

grep -q 'program=/usr/bin/true' "$OUTPUT_FILE" || {
  printf 'FAIL: launchd program detail not found\n' >&2
  exit 1
}

grep -q 'writable=' "$OUTPUT_FILE" || {
  printf 'FAIL: launchd writable detail not found\n' >&2
  exit 1
}

grep -q '"ACTION":"launchd_abnormal_directory"' "$OUTPUT_FILE" || {
  printf 'FAIL: launchd abnormal directory behavior not found\n' >&2
  exit 1
}

printf 'PASS\n'
