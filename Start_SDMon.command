#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

OUTPUT_BASE="$HOME/Downloads/2026-110"
STATE_DIR="$OUTPUT_BASE/.state"
START_LOG="$STATE_DIR/start.log"

mkdir -p "$STATE_DIR"

echo "Starting SDMon V1.1..."
echo "Output: $OUTPUT_BASE"
echo "Administrator authentication is needed for tcpdump, lsof, and fs_usage."

sudo -v || exit 1

nohup bash "$SCRIPT_DIR/bin/monitor.sh" >> "$START_LOG" 2>&1 &

echo "SDMon start requested."
echo "Use Stop_SDMon.command to stop monitoring and generate reports."
