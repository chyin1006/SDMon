# SDMon v2.1.0-beta.1 Release Notes

Version: `v2.1.0-beta.1`

Status: Pre-release

Platform: Windows Beta Preview

## Summary

SDMon `v2.1.0-beta.1` adds Windows Beta endpoint assessment support.

This release is read-only, local-first, and designed for evaluation. It extends SDMon beyond the macOS Public Preview while keeping Windows support clearly marked as Beta quality.

## Platform Status

| Platform | Status | Notes |
| --- | --- | --- |
| macOS | Public Preview | Available in `v2.0.0-rc1` and later. |
| Windows | Beta Preview | Available in `v2.1.0-beta.1` and later. |
| Linux | Planned | Not implemented yet. |

Windows Beta has been tested on Windows 11 Pro and Windows 11 Home. Additional QA, tuning, and report polish are still required.

## Windows Quick Start

Run from Windows PowerShell:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/chyin1006/SDMon/main/scripts/run-sdmon-windows.ps1" -OutFile ".\run-sdmon-windows.ps1"
powershell -ExecutionPolicy Bypass -File .\run-sdmon-windows.ps1
```

The runner downloads the SDMon main branch ZIP, extracts it to a temporary directory, runs the read-only Windows scan, opens `report.html` when possible, and prints generated report paths.

## Added

- Windows one-command runner.
- PowerShell-native Windows endpoint assessment workflow.
- Windows collectors for system, security, startup, browser, process, network, services, scheduled tasks, credential metadata, and event log counts.
- Local Windows report generation for HTML, JSON, CSV, Summary, ZIP, events, and timeline outputs.
- Windows smoke test for development validation.
- Anonymized Windows demo report assets.

## Safety Boundaries

The Windows Beta workflow does not:

- Modify the registry.
- Change system settings.
- Stop, start, restart, enable, disable, or delete services.
- Enable, disable, or delete scheduled tasks.
- Delete files.
- Read browser cookies, history, saved credentials, or private profile data.
- Read credential file contents.
- Upload reports or events.
- Perform remediation.
- Install a background service.

## Known Limitations

- Windows support is Beta quality.
- Manual review is required.
- False positives are expected.
- Browser extension names may show localization placeholders.
- Firewall, UAC, and BitLocker raw values need broader cross-version validation.
- Services, scheduled tasks, processes, and network events need more grouping and summarization.
- Windows report layout and wording need additional polish.

## Relationship to v2.0.0-rc1

`v2.0.0-rc1` remains the Latest release for macOS Public Preview.

`v2.1.0-beta.1` is a Pre-release that adds Windows Beta support.
