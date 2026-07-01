#!/usr/bin/env bash

set -u

CONFIDENCE=""

usage() {
  cat <<'USAGE'
Usage:
  confidence.sh --confidence VALUE
USAGE
}

die() {
  printf 'confidence: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --confidence)
      shift
      [[ $# -gt 0 ]] || die "--confidence requires a value"
      CONFIDENCE="$1"
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

case "$CONFIDENCE" in
  high|HIGH) printf 'HIGH\n' ;;
  medium|MEDIUM) printf 'MEDIUM\n' ;;
  low|LOW) printf 'LOW\n' ;;
  ''|*[!0-9]*) printf 'LOW\n' ;;
  *)
    if [[ "$CONFIDENCE" -ge 70 ]]; then
      printf 'HIGH\n'
    elif [[ "$CONFIDENCE" -ge 40 ]]; then
      printf 'MEDIUM\n'
    else
      printf 'LOW\n'
    fi
    ;;
esac
