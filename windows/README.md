# SDMon Windows Beta 01

SDMon Windows Beta 01 is a PowerShell-native endpoint assessment workflow for Windows testing. It collects read-only endpoint signals, analyzes them locally, and generates local HTML, JSON, CSV, text, ZIP, events, and timeline outputs.

Windows Beta 01 is separate from the macOS RC1 workflow. The Windows machine is for real execution testing only; code changes should be made from the macOS Codex workflow.

## Read-Only Safety Model

The Windows scan is designed to be read-only.

It does not:

- Modify the registry.
- Change system settings.
- Stop, start, restart, enable, disable, or delete services.
- Enable, disable, or delete scheduled tasks.
- Delete files.
- Read browser cookies, history, saved credentials, or private profile data.
- Read credential file contents.
- Perform remediation.
- Install a background service.

If a check cannot be read, SDMon records `permission_denied`, `requires_admin`, or an informational warning and continues.

## Supported Command

Run from the repository root on a Windows test machine:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Output .\output -NoOpen
```

The `-NoOpen` option prevents automatic browser opening during automated tests.

## Smoke Test

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\tests\test_windows_smoke.ps1
```

## Output Files

The scan writes:

```text
output\
  report.html
  report.json
  report.csv
  summary.txt
  report.zip
  events.json
  timeline.json
```

The HTML report is summarized for human readability. It includes collector counts, focused findings, capped timeline rows, and sampled technical details.

The full raw event data remains available in `events.json` and `timeline.json`. Machine-readable report data remains available in `report.json`.

## Current Collectors

Windows Beta 01 currently includes read-only collectors for:

- System
- Security
- Startup
- Browser
- Process
- Network
- Services
- Scheduled Tasks
- Credential Metadata
- Event Log Basic Counts

## Permission Model

The basic scan does not require Administrator by default. Some endpoint information may be unavailable without elevated privileges. In those cases, SDMon should record a non-fatal warning and continue.

## Reporting Windows Test Results

When reporting Windows test results back to macOS Codex, include:

- Current Git branch and commit hash.
- Exact command executed.
- Smoke test result.
- Formal scan result.
- Security Score.
- Overall Risk.
- Events count.
- Matched Rules count.
- Generated output file list.
- Any terminal error text.
- Whether `report.html` opened successfully.

Do not publish real Windows reports because they may include real hostnames, usernames, local IPs, process names, services, scheduled tasks, and network connections.
