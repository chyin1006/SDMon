#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_rule_runtime_test_$$"
EVENT_FILE="$TMP_DIR/events/process_events.jsonl"
RESULT_FILE="$TMP_DIR/rule_result.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
export SDMON_NO_OPEN=1

bash -n "$REPO_ROOT"/runtime/*.sh
bash -n "$REPO_ROOT/tests/test_rule_runtime.sh"

bash "$REPO_ROOT/producers/process_producer.sh" --output "$EVENT_FILE"
bash "$REPO_ROOT/events/event_writer.sh" --output "$EVENT_FILE" \
  EVENT_ID="test-launchd-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-01-01T00:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="" \
  PLATFORM="macos" \
  SENSOR_TYPE="launchd" \
  PROFILE_ID="test" \
  EVENT_CATEGORY="service" \
  EVENT_TYPE="launchd" \
  PROCESS_NAME="com.example.demo" \
  PID="" \
  ACTION="found" \
  TARGET="/tmp/com.example.demo.plist" \
  TARGET_TYPE="service" \
  SOURCE="test" \
  CONFIDENCE="80" \
  TAGS="test"
bash "$REPO_ROOT/events/event_writer.sh" --output "$EVENT_FILE" \
  EVENT_ID="test-security-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-01-01T00:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="" \
  PLATFORM="macos" \
  SENSOR_TYPE="system" \
  PROFILE_ID="test" \
  EVENT_CATEGORY="security" \
  EVENT_TYPE="gatekeeper_status" \
  PROCESS_NAME="" \
  PID="" \
  ACTION="disabled" \
  TARGET="gatekeeper" \
  TARGET_TYPE="macos_security_status" \
  SOURCE="test" \
  CONFIDENCE="80" \
  TAGS="test" \
  STATUS="disabled" \
  DETAIL="status=disabled"
bash "$REPO_ROOT/events/event_writer.sh" --output "$EVENT_FILE" \
  EVENT_ID="test-persistence-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-01-01T00:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="" \
  PLATFORM="macos" \
  SENSOR_TYPE="launchd" \
  PROFILE_ID="test" \
  EVENT_CATEGORY="service" \
  EVENT_TYPE="launchd_persistence" \
  PROCESS_NAME="com.example.tmp" \
  PID="" \
  ACTION="launchd_tmp_execution" \
  TARGET="/tmp/demo" \
  TARGET_TYPE="service" \
  SOURCE="test" \
  CONFIDENCE="80" \
  TAGS="test"
bash "$REPO_ROOT/events/event_writer.sh" --output "$EVENT_FILE" \
  EVENT_ID="test-network-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-01-01T00:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="" \
  PLATFORM="macos" \
  SENSOR_TYPE="network" \
  PROFILE_ID="test" \
  EVENT_CATEGORY="network" \
  EVENT_TYPE="network_behavior" \
  PROCESS_NAME="demo" \
  PID="123" \
  ACTION="suspicious_port" \
  TARGET="1.2.3.4:4444" \
  TARGET_TYPE="endpoint" \
  SOURCE="test" \
  CONFIDENCE="80" \
  TAGS="test"
bash "$REPO_ROOT/events/event_writer.sh" --output "$EVENT_FILE" \
  EVENT_ID="test-process-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-01-01T00:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="test" \
  PLATFORM="macos" \
  SENSOR_TYPE="process" \
  PROFILE_ID="test" \
  EVENT_CATEGORY="process" \
  EVENT_TYPE="process_behavior" \
  PROCESS_NAME="demo" \
  PID="456" \
  ACTION="tmp_execution" \
  TARGET="/tmp/demo" \
  TARGET_TYPE="process" \
  SOURCE="test" \
  CONFIDENCE="80" \
  TAGS="test"
bash "$REPO_ROOT/events/event_writer.sh" --output "$EVENT_FILE" \
  EVENT_ID="test-credential-1" \
  EVENT_VERSION="1" \
  TIMESTAMP="2026-01-01T00:00:00Z" \
  HOSTNAME="test-host" \
  USER_NAME="test" \
  PLATFORM="macos" \
  SENSOR_TYPE="credential" \
  PROFILE_ID="test" \
  EVENT_CATEGORY="security" \
  EVENT_TYPE="credential_detected" \
  PROCESS_NAME="SSH Private Key" \
  PID="" \
  ACTION="credential_sensitive_permission_unsafe" \
  TARGET="/tmp/id_rsa" \
  TARGET_TYPE="credential" \
  SOURCE="test" \
  CONFIDENCE="85" \
  TAGS="test" \
  STATUS="review" \
  DETAIL="credential_type=SSH Private Key;permission=-rw-r--r--/644;owner=test;size=4;status=review;reason=sensitive_credential_with_unsafe_metadata;git_tracked=false;world_readable=true;group_writable=false;abnormal_directory=true;risk=high"
bash "$REPO_ROOT/runtime/rule_runtime.sh" --event-file "$EVENT_FILE" --rules-dir "$REPO_ROOT/rules_v2" > "$RESULT_FILE"

grep -q '"MATCH":"true"' "$RESULT_FILE" || {
  printf 'FAIL: MATCH=true not found\n' >&2
  exit 1
}

grep -q '"RULE_ID":"process_demo"' "$RESULT_FILE" || {
  printf 'FAIL: RULE_ID not found\n' >&2
  exit 1
}

grep -q '"SEVERITY":"medium"' "$RESULT_FILE" || {
  printf 'FAIL: SEVERITY not found\n' >&2
  exit 1
}

grep -q '"MESSAGE":"Demo process event matched."' "$RESULT_FILE" || {
  printf 'FAIL: MESSAGE not found\n' >&2
  exit 1
}

grep -q '"RULE_ID":"launchd_demo"' "$RESULT_FILE" || {
  printf 'FAIL: launchd_demo rule not matched\n' >&2
  exit 1
}

grep -q '"RULE_ID":"macos_security_demo"' "$RESULT_FILE" || {
  printf 'FAIL: macos_security_demo rule not matched\n' >&2
  exit 1
}

grep -q '"RULE_ID":"persistence_tmp_execution"' "$RESULT_FILE" || {
  printf 'FAIL: persistence_tmp_execution rule not matched\n' >&2
  exit 1
}

grep -q '"RULE_ID":"network_suspicious_port"' "$RESULT_FILE" || {
  printf 'FAIL: network_suspicious_port rule not matched\n' >&2
  exit 1
}

grep -q '"RULE_ID":"process_tmp_execution"' "$RESULT_FILE" || {
  printf 'FAIL: process_tmp_execution rule not matched\n' >&2
  exit 1
}

grep -q '"RULE_ID":"credential_risk"' "$RESULT_FILE" || {
  printf 'FAIL: credential_risk rule not matched\n' >&2
  exit 1
}

printf 'PASS\n'
