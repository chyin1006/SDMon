#!/usr/bin/env bash

set -u

INPUT_HTML=""
OUTPUT_FILE=""

usage() {
  cat <<'USAGE'
Usage:
  pdf_reporter.sh --input-html FILE --output FILE
USAGE
}

die() {
  printf 'pdf_reporter: %s\n' "$1" >&2
  exit 1
}

chrome_binary() {
  for path in \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
  do
    if [ -x "$path" ]; then
      printf '%s' "$path"
      return 0
    fi
  done
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input-html)
      [ "$#" -ge 2 ] || die "--input-html requires a file path"
      INPUT_HTML="$2"
      shift 2
      ;;
    --output)
      [ "$#" -ge 2 ] || die "--output requires a file path"
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
done

[ -n "$INPUT_HTML" ] || die "missing --input-html FILE"
[ -f "$INPUT_HTML" ] || die "input html does not exist: $INPUT_HTML"
[ -n "$OUTPUT_FILE" ] || die "missing --output FILE"

CHROME_BIN="$(chrome_binary)" || die "no supported browser found for PDF export"
mkdir -p "$(dirname "$OUTPUT_FILE")" || die "failed to create output directory"

"$CHROME_BIN" \
  --headless=new \
  --disable-gpu \
  --no-first-run \
  --no-default-browser-check \
  --allow-file-access-from-files \
  --print-to-pdf="$OUTPUT_FILE" \
  "file://$INPUT_HTML" >/dev/null 2>&1 || die "failed to render PDF"

[ -f "$OUTPUT_FILE" ] || die "PDF was not generated"
