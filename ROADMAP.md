# SDMon Roadmap

## Current

`v2.0.0-rc1`

Status: macOS Public Preview.

RC1 is focused on macOS local security assessment reports:

- One-command scan.
- Read-only local collection.
- Local analysis.
- HTML, PDF, ZIP, JSON, CSV, and Summary outputs.
- Executive Summary, Top Findings, Recommendations, Timeline, and Technical Details.

`v2.1.0-beta.1`

Status: Windows Beta Preview.

Windows Beta adds read-only local endpoint assessment reports for Windows:

- One-command Windows runner.
- PowerShell-native local scan.
- HTML, ZIP, JSON, CSV, Summary, Events, and Timeline outputs.
- Read-only system, security, startup, browser, process, network, services, scheduled task, credential metadata, and event log count collection.

Windows support is Beta quality. It has been tested on Windows 11 Pro and Windows 11 Home, but still requires manual review and further QA / polish.

## Release Path

```text
macOS RC1 Public Preview
  |
Windows Beta Preview
  |
Beta
  |
Stable
```

## Beta Priorities

- Enterprise policy and allowlist support.
- Rule enablement and severity tuning.
- Historical Scan and Diff Scan.
- SQLite event store.
- Dashboard.
- Rule Manager.
- IOC and YARA support.
- MITRE ATT&CK mapping.
- Windows report polish and false-positive tuning.
- Linux sensor research.

## Stable Release Goals

- Clear configuration model.
- Lower false-positive rate.
- Stronger report customization.
- Repeatable enterprise deployment workflow.
- Documented compatibility and upgrade path.

## Legacy

V1.1 remains available as a legacy validation workflow. New development should focus on the V2 path.
