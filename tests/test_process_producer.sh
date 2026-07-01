#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="${TMPDIR:-/tmp}/sdmon_process_producer_test_$$"
OUTPUT_FILE="$TMP_DIR/events/process_events.jsonl"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

bash -n "$REPO_ROOT"/producers/*.sh

bash "$REPO_ROOT/producers/process_producer.sh" --output "$OUTPUT_FILE"

[[ -f "$OUTPUT_FILE" ]] || {
  printf 'FAIL: event_writer did not create JSONL output\n' >&2
  exit 1
}

grep -q '"EVENT_CATEGORY":"process"' "$OUTPUT_FILE" || {
  printf 'FAIL: EVENT_CATEGORY=process not found\n' >&2
  exit 1
}

grep -q '"PROCESS_NAME":"test-process"' "$OUTPUT_FILE" || {
  printf 'FAIL: PROCESS_NAME=test-process not found\n' >&2
  exit 1
}

printf 'PASS\n'
