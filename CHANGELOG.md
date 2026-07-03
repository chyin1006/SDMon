# Changelog

All notable changes to SDMon are documented in this file.

## Unreleased

- Linux support, policy tuning, report polish, and stable release hardening remain future work.

## v2.1.0-beta.1

Status: Pre-release.

### Added

- Windows Beta endpoint assessment support.
- Windows one-command runner through `scripts/run-sdmon-windows.ps1`.
- PowerShell-native Windows local assessment workflow.
- Windows output package: HTML, ZIP, JSON, CSV, Summary, Events, and Timeline.
- Read-only Windows collectors for system, security, startup, browser, process, network, services, scheduled tasks, credential metadata, and event log counts.
- Windows smoke test and anonymized Windows demo report assets.

### Safety

- Windows Beta is read-only.
- No registry modification.
- No system setting changes.
- No service or scheduled task stop/start/delete actions.
- No credential content reading.
- No data upload.

### Notes

- Windows support is Beta quality.
- Tested on Windows 11 Pro and Windows 11 Home.
- Manual review and additional QA / polish are still required.

## v2.0.0-rc1

Status: Public Preview.

### Added

- One-command workflow through `./sdmon-v2.sh`.
- Local read-only macOS assessment.
- Unified administrator privilege flow.
- HTML, PDF, ZIP, JSON, CSV, and Summary reports.
- Executive Summary with Security Score, Overall Risk, and risk distribution.
- Top Findings, Recommendations, Timeline, Download, and Technical Details sections.
- Local Rule Engine and Reporter pipeline.
- macOS-oriented checks for system, persistence, network, browser, credential, sensitive file, firewall, FileVault, and related endpoint signals.

### Improved

- Report presentation for enterprise IT and security review.
- PDF print layout for compact executive summary pages.
- Score and risk consistency.
- Home path display using `~/...` in management-facing report sections.
- Chinese-friendly report wording while keeping repository documentation in English.

### Safety

- No data upload.
- No automatic remediation.
- No target agent modification.
- No system setting modification.
- V1.1 remains available as a legacy workflow.

## V2 Alpha Preview

- Introduced the initial V2 event, rule, analyzer, reporter, sensor, and CLI pipeline.

## V1.1 Legacy

- Introduced the original Bash-only macOS validation workflow.
