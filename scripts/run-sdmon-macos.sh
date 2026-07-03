#!/bin/sh

set -eu

REPO_ZIP_URL="https://github.com/chyin1006/SDMon/archive/refs/heads/main.zip"
REPO_GIT_URL="https://github.com/chyin1006/SDMon.git"
USE_GIT=0

print_usage() {
    cat <<'EOF'
SDMon macOS one-command runner

Usage:
  ./run-sdmon-macos.sh
  ./run-sdmon-macos.sh --git
  ./run-sdmon-macos.sh --help

Default mode downloads the GitHub ZIP archive and does not require Git.
The optional --git mode uses git clone if Git is already available.
EOF
}

info() {
    printf '%s\n' "$1"
}

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "$2"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --git)
            USE_GIT=1
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            fail "Unknown option: $1"
            ;;
    esac
    shift
done

if [ "$(uname -s)" != "Darwin" ]; then
    fail "This runner is intended for macOS."
fi

TIMESTAMP="$(date +%Y%m%d%H%M%S)"
RUN_ROOT="${TMPDIR:-/tmp}/sdmon-run-${TIMESTAMP}"
SDMON_DIR=""

info "==================================="
info "SDMon macOS Runner"
info "==================================="
info "Read-only local assessment. No upload, remediation, or system setting changes."
info ""

info "[1/6] Checking required tools..."
if [ "$USE_GIT" -eq 1 ]; then
    if ! command -v git >/dev/null 2>&1; then
        fail "Git is not available. On a fresh Mac, install Apple Command Line Tools with: xcode-select --install"
    fi
else
    require_command "curl" "curl is required for ZIP download mode."
    require_command "unzip" "unzip is required for ZIP download mode."
fi
info "Done."

info "[2/6] Creating temporary workspace..."
mkdir -p "$RUN_ROOT"
info "Workspace: $RUN_ROOT"

if [ "$USE_GIT" -eq 1 ]; then
    info "[3/6] Cloning SDMon with Git..."
    git clone --depth 1 "$REPO_GIT_URL" "$RUN_ROOT/SDMon"
    SDMON_DIR="$RUN_ROOT/SDMon"
else
    ZIP_FILE="$RUN_ROOT/sdmon-main.zip"
    info "[3/6] Downloading SDMon ZIP archive..."
    curl -fL "$REPO_ZIP_URL" -o "$ZIP_FILE"

    info "[4/6] Extracting SDMon..."
    unzip -q "$ZIP_FILE" -d "$RUN_ROOT"
    SDMON_ENTRY="$(find "$RUN_ROOT" -maxdepth 3 -type f -name "sdmon-v2.sh" -print | head -n 1)"
    if [ -z "$SDMON_ENTRY" ]; then
        fail "Could not find sdmon-v2.sh in the downloaded archive."
    fi
    SDMON_DIR="$(dirname "$SDMON_ENTRY")"
fi

if [ "$USE_GIT" -eq 1 ]; then
    info "[4/6] Locating SDMon entrypoint..."
    if [ ! -f "$SDMON_DIR/sdmon-v2.sh" ]; then
        fail "Could not find sdmon-v2.sh after git clone."
    fi
fi

info "[5/6] Preparing SDMon..."
chmod +x "$SDMON_DIR/sdmon-v2.sh"
info "SDMon path: $SDMON_DIR"

info "[6/6] Running SDMon..."
(
    cd "$SDMON_DIR"
    ./sdmon-v2.sh
)

OUTPUT_DIR="$SDMON_DIR/output"
REPORT_HTML="$OUTPUT_DIR/report.html"
info ""
info "==================================="
info "SDMon runner completed."
info "==================================="
info "Temporary SDMon copy:"
info "$SDMON_DIR"
info ""
info "Generated outputs:"
if [ -d "$OUTPUT_DIR" ]; then
    for output_file in report.html report.pdf report.zip report.json report.csv summary.txt timeline.json events.json; do
        if [ -f "$OUTPUT_DIR/$output_file" ]; then
            printf '  %s\n' "$OUTPUT_DIR/$output_file"
        fi
    done
else
    info "  No output directory found."
fi
info ""
if [ -f "$REPORT_HTML" ]; then
    info "Opening report..."
    if open "$REPORT_HTML" >/dev/null 2>&1; then
        info "Opened report:"
        info "$REPORT_HTML"
    else
        info "Could not automatically open report.html."
        info "Please open it manually:"
        info "$REPORT_HTML"
    fi
else
    info "WARNING: report.html was not found."
    if [ -d "$OUTPUT_DIR" ]; then
        info "Available output files:"
        find "$OUTPUT_DIR" -maxdepth 1 -type f -print | sort | sed 's/^/  /'
    else
        info "No output files are available."
    fi
fi
info ""
info "The temporary workspace is left in place for review."
