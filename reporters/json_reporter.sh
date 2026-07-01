#!/usr/bin/env bash

set -u

INPUT_FILE=""
OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  json_reporter.sh --input FILE --output FILE
USAGE
}

die() {
  printf 'json_reporter: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      shift
      [[ $# -gt 0 ]] || die "--input requires a file path"
      INPUT_FILE="$1"
      ;;
    --output)
      shift
      [[ $# -gt 0 ]] || die "--output requires a file path"
      OUTPUT_FILE="$1"
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

[[ -n "$INPUT_FILE" ]] || die "missing --input FILE"
[[ -n "$OUTPUT_FILE" ]] || die "missing --output FILE"
[[ -f "$INPUT_FILE" ]] || die "input file does not exist: $INPUT_FILE"

mkdir -p "$(dirname "$OUTPUT_FILE")" || die "failed to create output directory"
cp "$INPUT_FILE" "$OUTPUT_FILE" || die "failed to write JSON report"
