#!/usr/bin/env bash

set -u

SEVERITY=""

usage() {
  cat <<'USAGE'
Usage:
  risk_score.sh --severity LEVEL
USAGE
}

die() {
  printf 'risk_score: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --severity)
      shift
      [[ $# -gt 0 ]] || die "--severity requires a value"
      SEVERITY="$1"
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

case "$SEVERITY" in
  critical) printf '90\n' ;;
  high) printf '70\n' ;;
  medium) printf '40\n' ;;
  low) printf '10\n' ;;
  info|"") printf '0\n' ;;
  *) printf '0\n' ;;
esac
