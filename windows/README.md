# SDMon Windows Endpoint Assessment

This directory contains the Windows Beta 01 skeleton for SDMon endpoint assessment.

The Windows implementation is PowerShell-native, read-only, and separate from the macOS RC1 implementation.

## Safety Model

The Windows basic scan does not:

- Require administrator permission.
- Modify the registry.
- Stop, start, restart, or modify services.
- Delete files.
- Change firewall, Defender, BitLocker, UAC, browser, or startup settings.
- Run as a background service.
- Perform remediation.

If a check cannot be read, SDMon records a permission warning and continues.

## Run

From the repository root on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1
```

Use a custom output directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Output .\output
```

Disable automatic report opening:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\sdmon-windows.ps1 -Output .\output -NoOpen
```

## Output

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

## Current Collectors

Phase 2 includes basic read-only collectors:

- System
- Security
- Startup
- Browser

Process, network, service, scheduled task, event log, and credential deep scanning are intentionally not implemented in this phase.

## Windows Testing

Run on a real Windows machine:

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\tests\test_windows_smoke.ps1
```

Send the full terminal output and generated file list back to macOS Codex for code changes.
