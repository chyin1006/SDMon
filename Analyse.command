#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Analysing SDMon logs..."
bash "$SCRIPT_DIR/bin/analyse.sh" "$@"
echo "Done."
