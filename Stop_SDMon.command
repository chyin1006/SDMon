#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Stopping SDMon V1.1..."
bash "$SCRIPT_DIR/bin/stop.sh"
echo "Done."
